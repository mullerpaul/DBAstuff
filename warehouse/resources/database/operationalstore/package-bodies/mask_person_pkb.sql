CREATE OR REPLACE PACKAGE BODY mask_person
AS
/******************************************************************************
 * Name: mask_person
 * Desc: This package contains code to mask person data in accordance with 
 *       GDPR/Erasure (EMEA) or for PII masking.  Right now it includes masking 
 *       attributes from the following tables (attributes are listed below in 
 *       their respective procedures):
 *       
 *       LEGO_INVOICED_EXPD_DETAIL
 *       LEGO_INVD_EXPD_DATE_RU
 * 
 *       Only these tables are include since they are insert only tables.  All
 *       others are drop and create so they will be refreshed once FO masking
 *       takes place.
 *
 *       The public entry point for ERASURE ONLY is a function called, 
 *       process_erasure_request, that accepts a person_id.
 *       The mask type will be hard-code as either ERASURE or PII and will determine 
 *       the masking values applied for each attribute to be masked.
 *
 *       There needs to be a separate call in the specification for this to be used
 *       for PII masking, which is not currently included or in scope right now.
 *
 *       Lots of logging here because Legoland can present issues that are often hard
 *       to predict.
 *
 * Author        Date        Version   History
 * -----------------------------------------------------------------
 * jpullifrone   03/06/2018  Initial   IQN-39342
 *
 ******************************************************************************/


       
   gc_source              CONSTANT VARCHAR2(30) := 'MASK_PERSON';
   gv_error_stack         VARCHAR2(1000); 
   --The value below is misleading (sorry), but this prevents us from deleting Wells Fargo data. 
   gc_source_name         VARCHAR2(30) := 'USPROD';
  
   -- Errors
   e_invd_expd_detail     EXCEPTION;
   e_invd_expd_date_ru    EXCEPTION;
   e_invalid_mask_type    EXCEPTION;
   e_invalid_person       EXCEPTION;
   e_no_orgs_found        EXCEPTION;

   PRAGMA EXCEPTION_INIT (e_invd_expd_detail,    -20003);
   PRAGMA EXCEPTION_INIT (e_invd_expd_date_ru,   -20004);
   PRAGMA EXCEPTION_INIT (e_invalid_mask_type,   -20005);
   PRAGMA EXCEPTION_INIT (e_invalid_person,      -20006);
   PRAGMA EXCEPTION_INIT (e_no_orgs_found,       -20007);

   gc_date_mask_erasure         CONSTANT VARCHAR2(20) := NULL; 
   gc_fed_id_mask_erasure       CONSTANT VARCHAR2(20) := NULL;
   gc_email_mask_erasure        CONSTANT VARCHAR2(20) := NULL;
   gc_number_mask_erasure       CONSTANT NUMBER       := NULL;
   gc_string_mask_erasure       CONSTANT VARCHAR2(20) := NULL;
   gc_string_mask_erasure_req   CONSTANT VARCHAR2(20) := 'Erased';  

   gc_date_mask_pii     CONSTANT VARCHAR2(20) := '1900-01-01';
   gc_fed_id_mask_pii   CONSTANT VARCHAR2(20) := '102';
   gc_email_mask_pii    CONSTANT VARCHAR2(20) := 'nobody@iqn.com';
   gc_number_mask_pii   CONSTANT NUMBER       := 0;
   gc_string_mask_pii   CONSTANT VARCHAR2(20) := '**********';   

   gv_date_mask          VARCHAR2(20);
   gv_fed_id_mask        VARCHAR2(20);
   gv_email_mask         VARCHAR2(20);
   gv_number_mask        NUMBER;
   gv_string_mask        VARCHAR2(20);   
   gv_string_req_mask    VARCHAR2(20);   

   --Collection type and global variable to hold all of the buyer org IDs associated with
   --the person or candidate to be masked.
   TYPE t_buyerOrg IS TABLE OF lego_invoiced_expd_detail.buyer_org_id%TYPE INDEX BY PLS_INTEGER;
   gcv_buyerOrgID t_buyerOrg;
       
    -- Make sure that the incoming person id exists in the database
   FUNCTION is_valid_person (pi_person_id IN NUMBER)
     RETURN BOOLEAN
   IS
   
     lv_source          VARCHAR2(61) := gc_source || '.is_valid_person';
     po_is_valid_person BOOLEAN := TRUE;
     lv_count           NUMBER := 0;
     
   BEGIN
     logger_pkg.set_source(lv_source);
     logger_pkg.info('Check if valid person');
     SELECT COUNT(1)
       INTO lv_count
       FROM person_iqp
      WHERE person_id = pi_person_id;

     IF lv_count = 0 
     THEN
       po_is_valid_person := FALSE;              
       RAISE e_invalid_person;
     END IF;
     
     logger_pkg.info('Completed check if valid person',TRUE);
     logger_pkg.unset_source(lv_source);
     
     RETURN po_is_valid_person;
   
   EXCEPTION
     WHEN e_invalid_person THEN 
       logger_pkg.error('Input is not a valid person id = ' || pi_person_id,TRUE);      
       logger_pkg.unset_source(lv_source);
       RAISE;     
     WHEN OTHERS THEN
       logger_pkg.error('Failed check if valid person',TRUE);
       logger_pkg.unset_source(lv_source);
       RAISE;
   
   END is_valid_person;

   -- Set the variables that will be used as the replacment value based on data type and mask type
   PROCEDURE setup_mask_variables (pi_mask_type IN VARCHAR2)
   IS
   
   lv_source       VARCHAR2(61) := gc_source || '.setup_mask_variables';
  
   BEGIN
     logger_pkg.set_source(lv_source);
     logger_pkg.info('Check mask type');
     CASE (pi_mask_type)
         WHEN 'ERASURE' THEN
             gv_date_mask       := gc_date_mask_erasure;
             gv_fed_id_mask     := gc_fed_id_mask_erasure;
             gv_email_mask      := gc_email_mask_erasure;
             gv_number_mask     := gc_number_mask_erasure;
             gv_string_mask     := gc_string_mask_erasure;
             gv_string_req_mask := gc_string_mask_erasure_req;
         WHEN 'PII' THEN
             gv_date_mask   := gc_date_mask_pii;
             gv_fed_id_mask := gc_fed_id_mask_pii;
             gv_email_mask  := gc_email_mask_pii;
             gv_number_mask := gc_number_mask_pii;
             gv_string_mask := gc_string_mask_pii;
         ELSE              
             RAISE e_invalid_mask_type;
     END CASE;

     logger_pkg.info('Completed check mask type',TRUE);
     logger_pkg.unset_source(lv_source); 
     
  EXCEPTION 
    WHEN e_invalid_mask_type THEN
      logger_pkg.error('Mask type must be ERASURE or PII',TRUE);
      logger_pkg.unset_source(lv_source);
      RAISE;
    WHEN OTHERS THEN
      logger_pkg.error('Failed setup mask variables',TRUE);
      logger_pkg.unset_source(lv_source);
      RAISE;
  END setup_mask_variables;


  FUNCTION get_buyer_org (pi_person_id    IN NUMBER,
                          pi_candidate_id IN NUMBER) RETURN PLS_INTEGER
  /* Get all of the buyer orgs associated with this candidate_id or person_id.  These
     will be used when we update the two data tables because the tables are large
     and partitioned by buyer org id, thus making the update much fast.    
  */
  IS
  
  lv_source       VARCHAR2(61) := gc_source || '.get_buyer_org';
  
  BEGIN
  
    logger_pkg.set_source(lv_source);
    logger_pkg.info('Get Buyer Orgs');
    
    IF pi_candidate_id IS NOT NULL THEN
    
      SELECT DISTINCT buyer_org_id
        BULK COLLECT INTO gcv_buyerOrgID
        FROM lego_invoiced_expd_detail 
       WHERE source_name  = gc_source_name
         AND candidate_id = pi_candidate_id;
      
    ELSE
    
      SELECT buyer_org_id
        BULK COLLECT INTO gcv_buyerOrgID
        FROM (SELECT buyer_org_id
                FROM lego_invoiced_expd_detail
               WHERE source_name  = gc_source_name
                 AND (hiring_mgr_person_id = pi_person_id OR sar_person_id = pi_person_id)
              UNION
              SELECT buyer_org_id 
                FROM lego_invd_expd_date_ru
               WHERE expenditure_approver_pid = pi_person_id);
    END IF;
    
    logger_pkg.info('Completed getting buyer orgs.  Number of orgs = '||gcv_buyerOrgID.COUNT,TRUE);
    logger_pkg.unset_source(lv_source);

    RETURN gcv_buyerOrgID.COUNT;
         
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.error('Failed to get buyer orgs',TRUE);
      logger_pkg.unset_source(lv_source);
      RAISE;
  END get_buyer_org;


  PROCEDURE mask_invd_expd_detail(pi_person_id    IN NUMBER,
                                  pi_candidate_id IN NUMBER)
  /* Update LEGO_INVOICED_EXPD_DETAIL table data associated with person_id or candidate id
     
       The following attributes will be masked from LEGO_INVOICED_EXPD_DETAIL depending on the 
       type of person, which is likely to be a Resource but could be a Hiring Mgr or CAM or 
       other person type:
         1. CANDIDATE_NAME - if Resource
         2. HIRING_MGR_NAME
         3. SAR_NAME
  
  */
  IS
  
  lv_source       VARCHAR2(61) := gc_source || '.mask_invd_expd_detail';
  
  BEGIN
    logger_pkg.set_source(lv_source);
        
    FOR i IN gcv_buyerOrgID.FIRST .. gcv_buyerOrgID.LAST LOOP
    
      IF pi_candidate_id IS NOT NULL THEN
        
        logger_pkg.info('Updating LEGO_INVOICED_EXPD_DETAIL table based on candidate Id = '||pi_candidate_id||' and buyer org Id = '||gcv_buyerOrgID(i));
      
        UPDATE lego_invoiced_expd_detail 
           SET candidate_name = gv_string_mask
         WHERE candidate_id   = pi_candidate_id
           AND source_name    = gc_source_name
           AND buyer_org_id   = gcv_buyerOrgID(i);

        logger_pkg.info('Rows updated in LEGO_INVOICED_EXPD_DETAIL table based on candidate Id = '||pi_candidate_id||' and buyer org Id = '||gcv_buyerOrgID(i)||': '|| SQL%ROWCOUNT,TRUE);            
         
      ELSIF pi_candidate_id IS NULL AND pi_person_id IS NOT NULL THEN 
    
        logger_pkg.info('Updating LEGO_INVOICED_EXPD_DETAIL table based on hiring mgr person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i));
      
        UPDATE lego_invoiced_expd_detail 
           SET hiring_mgr_name      = gv_string_mask
         WHERE hiring_mgr_person_id = pi_person_id
           AND source_name          = gc_source_name
           AND buyer_org_id         = gcv_buyerOrgID(i);

        logger_pkg.info('Rows updated in LEGO_INVOICED_EXPD_DETAIL table based on hiring mgr person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i)||': '|| SQL%ROWCOUNT,TRUE);  
      
        logger_pkg.info('Updating LEGO_INVOICED_EXPD_DETAIL table based on SAR person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i));
      
        UPDATE lego_invoiced_expd_detail 
           SET sar_name      = gv_string_mask
         WHERE sar_person_id = pi_person_id
           AND source_name   = gc_source_name
           AND buyer_org_id  = gcv_buyerOrgID(i);

        logger_pkg.info('Rows updated in LEGO_INVOICED_EXPD_DETAIL table based on SAR person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i)||': '|| SQL%ROWCOUNT,TRUE);
      
      ELSE
    
        logger_pkg.info('No rows updated on LEGO_INVOICED_EXPD_DETAIL');
        logger_pkg.info('No rows updated on LEGO_INVOICED_EXPD_DETAIL',TRUE);
    
      END IF;
    
    END LOOP;
    
    logger_pkg.unset_source(lv_source);
    
  EXCEPTION
    WHEN OTHERS THEN
       logger_pkg.error('Unhandled exception in mask_invd_expd_detail',TRUE);
       logger_pkg.unset_source(lv_source);
       RAISE e_invd_expd_detail;
  END mask_invd_expd_detail;
 
  PROCEDURE mask_invd_expd_date_ru(pi_person_id    IN  NUMBER,
                                   pi_candidate_id IN  NUMBER)
  /* Update LEGO_INVD_EXPD_DATE_RU table data associated with person_id
  
     The following attributes will be masked from LEGO_INVD_EXPD_DATE_RU depending on the 
     type of person, which is likely to be a Resource but could be a Hiring Mgr or CAM or 
     other person type:
       1. CONTRACTOR_NAME - if Resource
       2. JOB_TITLE - if Resource
       3. JOB_CATEGORY - if Resource
       4. PROJECT_AGREEMENT_NAME - if Resource
       2. HIRING_MGR_NAME
       3. EXPENDITURE_APPROVER (name)
  
  */                                   
  IS
  
  lv_source       VARCHAR2(61) := gc_source || '.mask_invd_expd_date_ru';
  
  BEGIN
    logger_pkg.set_source(lv_source);
    
    FOR i IN gcv_buyerOrgID.FIRST .. gcv_buyerOrgID.LAST LOOP
    
      IF pi_candidate_id IS NOT NULL THEN
    
        logger_pkg.info('Updating LEGO_INVD_EXPD_DATE_RU table based on contractor person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i));
    
        UPDATE lego_invd_expd_date_ru 
           SET contractor_name        = gv_string_mask,
               job_title              = gv_string_mask,
               job_category           = gv_string_mask,
               project_agreement_name = gv_string_mask
         WHERE contractor_person_id   = pi_person_id
           AND source_name            = gc_source_name
           AND buyer_org_id           = gcv_buyerOrgID(i);

        logger_pkg.info('Rows updated in LEGO_INVD_EXPD_DATE_RU table based on contractor person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i)||': '|| SQL%ROWCOUNT,TRUE);            
    
      ELSIF pi_candidate_id IS NULL AND pi_person_id IS NOT NULL THEN 
    
        logger_pkg.info('Updating LEGO_INVD_EXPD_DATE_RU table based on hiring mgr person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i));
    
        UPDATE lego_invd_expd_date_ru 
           SET hiring_mgr_name      = gv_string_mask
         WHERE hiring_mgr_person_id = pi_person_id
           AND source_name          = gc_source_name
           AND buyer_org_id         = gcv_buyerOrgID(i);

        logger_pkg.info('Rows updated in LEGO_INVD_EXPD_DATE_RU table based on hiring mgr person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i)||': '|| SQL%ROWCOUNT,TRUE);   
      
        logger_pkg.info('Updating LEGO_INVD_EXPD_DATE_RU table based on expenditure approver person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i));
      
        UPDATE lego_invd_expd_date_ru 
           SET expenditure_approver     = gv_string_mask
         WHERE expenditure_approver_pid = pi_person_id
           AND source_name              = gc_source_name
           AND buyer_org_id             = gcv_buyerOrgID(i);

        logger_pkg.info('Rows updated in LEGO_INVD_EXPD_DATE_RU table based on expenditure approver person Id = '||pi_person_id||' and buyer org Id = '||gcv_buyerOrgID(i)||': '|| SQL%ROWCOUNT,TRUE);        
    
      ELSE
    
        logger_pkg.info('No rows updated on LEGO_INVD_EXPD_DATE_RU'); 
        logger_pkg.info('No rows updated on LEGO_INVD_EXPD_DATE_RU',TRUE);
    
      END IF;
      
    END LOOP;
    
    logger_pkg.unset_source(lv_source);
    
  EXCEPTION
    WHEN OTHERS THEN
       logger_pkg.error('Unhandled exception in mask_invd_expd_date_ru',TRUE);
       logger_pkg.unset_source(lv_source);
       RAISE e_invd_expd_date_ru;
  END mask_invd_expd_date_ru;

   --
   -- PUBLIC PROCEDURES
   --
  PROCEDURE process_erasure_request (pi_person_to_erase IN  NUMBER,
                                     po_status          OUT VARCHAR2)
     
   IS

     lc_mask_type    VARCHAR2(20) := 'ERASURE';
     lv_candidate_id NUMBER;
     lv_source       VARCHAR2(61) := gc_source || '.process_erasure_request';
     lv_call_status  BOOLEAN;
     

   BEGIN
     logger_pkg.instantiate_logger;
     logger_pkg.set_level('INFO');
     logger_pkg.set_source(lv_source);
     logger_pkg.info('Begin Process Erasure Request for person ID = '||TO_CHAR(pi_person_to_erase));
     lv_call_status := NULL;
     po_status := 'SUCCESS';
     
     setup_mask_variables(lc_mask_type);

     lv_call_status := is_valid_person(pi_person_to_erase);

     --Candidate Id dependent methods (does not look at Wells Fargo people)
     SELECT candidate_id
       INTO lv_candidate_id
       FROM person_iqp
      WHERE person_id = pi_person_to_erase;
      
     --get all of the buyer org IDs associated with this candidate or person 
     IF get_buyer_org(pi_person_to_erase, lv_candidate_id) = 0 THEN
       RAISE e_no_orgs_found;
     END IF;
     
     mask_invd_expd_detail(pi_person_to_erase, lv_candidate_id);
     
     mask_invd_expd_date_ru(pi_person_to_erase, lv_candidate_id);
     
     COMMIT;
     logger_pkg.info('Completed mask_person with person_id = ' || TO_CHAR(pi_person_to_erase),TRUE);
     logger_pkg.unset_source (lv_source);
   
   EXCEPTION

   WHEN e_invalid_mask_type THEN
     ROLLBACK;
      gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('Invalid mask type exception ' || gv_error_stack, TRUE);
      logger_pkg.unset_source(lv_source);
      po_status := 'INVALID_MASK_TYPE';

   WHEN e_invalid_person THEN
      gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('Invalid person exception ' || gv_error_stack, TRUE);
      logger_pkg.unset_source(lv_source);
      po_status := 'INVALID_PERSON_ID';
     
   WHEN e_no_orgs_found THEN
      gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('No orgs found for this person exception ' || gv_error_stack, TRUE);
      logger_pkg.unset_source(lv_source);
      po_status := 'NO_ORGS_FOUND';

   WHEN e_invd_expd_detail THEN
      ROLLBACK;
      gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('ROLLBACK', SQLCODE, 'LEGO_INVOICED_EXPD_DETAIL table mask failed: ' || gv_error_stack, TRUE);
      logger_pkg.unset_source(lv_source); 
      po_status := 'LEGO_INVOICED_EXPD_DETAIL_FAILED';

   WHEN e_invd_expd_date_ru THEN
     ROLLBACK;
     gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
     logger_pkg.fatal('ROLLBACK', SQLCODE, 'LEGO_INVD_EXPD_DATE_RU_FAILED table mask failed: ' || gv_error_stack, TRUE);
     logger_pkg.unset_source(lv_source);      
     po_status := 'LEGO_INVD_EXPD_DATE_RU_FAILED';
     
   WHEN OTHERS THEN
     ROLLBACK;
     gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
     logger_pkg.fatal('ROLLBACK', SQLCODE, 'process_erasure_request exception: ' || gv_error_stack, TRUE);
     logger_pkg.unset_source(lv_source);
     po_status := 'UNKNOWN_ERROR';
   END process_erasure_request;


END mask_person;
/