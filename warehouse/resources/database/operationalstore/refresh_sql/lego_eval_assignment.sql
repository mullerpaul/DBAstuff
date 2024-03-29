



/*******************************************************************************
SCRIPT NAME         lego_eval_assignment.sql 
 
LEGO OBJECT NAME    LEGO_EVAL_ASSIGNMENT
 
CREATED             3/24/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************
--Negative = 0
--Positive = 1

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_eval_assignment.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_EVAL_ASSIGNMENT'; 

  v_clob CLOB :=
q'{
SELECT buyer_org_id, 
       supplier_org_id, 
       assignment_continuity_id,        
       CASE 
         WHEN SUM(number_of_negative_evals) > 0 THEN 'Negative'
         WHEN SUM(number_of_negative_evals) = 0 AND SUM(number_of_positive_evals) > 0 THEN 'Positive'        
         ELSE NULL
       END AS overall_evaluation  
  FROM (
  --Assignment (WO and EA)- Complex Evaluation (unlimited dynamic questions)
SELECT buyer_org_id,
       supplier_org_id,
       assignment_continuity_id,
       COUNT(CASE WHEN overall_rating = 0 THEN overall_rating ELSE NULL END) number_of_negative_evals,
       COUNT(CASE WHEN overall_rating = 1 THEN overall_rating ELSE NULL END) number_of_positive_evals
  FROM (       
        SELECT DISTINCT
               bfr.business_org_fk AS buyer_org_id,
               sfr.business_org_fk AS supplier_org_id,
               ac.assignment_continuity_id,
               evalu.overall_rating  
          FROM firm_role@db_link_name AS OF SCN source_db_SCN  bfr,
               firm_role@db_link_name AS OF SCN source_db_SCN  sfr,
               assignment_continuity@db_link_name AS OF SCN source_db_SCN ac,
               evaluation_process@db_link_name AS OF SCN source_db_SCN  ep,
               evaluation@db_link_name AS OF SCN source_db_SCN evalu
         WHERE sfr.firm_id                   = ac.owning_supply_firm_fk     
           AND bfr.firm_id                   = ac.owning_buyer_firm_fk     
           AND ep.evaluation_process_id      = evalu.evaluation_process_fk
           AND ac.assignment_continuity_id   = ep.evaluatable_fk
           AND evalu.overall_rating IS NOT NULL)
 GROUP BY buyer_org_id,
          supplier_org_id,
          assignment_continuity_id
UNION ALL 
SELECT buyer_org_id,
       supplier_org_id,
       assignment_continuity_id,
       CASE WHEN number_of_negative_evals > 0 THEN 1 ELSE 0 END number_of_negative_evals,
       CASE WHEN number_of_negative_evals = 0 AND number_of_positive_evals > 0 THEN 1 ELSE 0 END number_of_positive_evals     
  FROM (
        --Assignment (EA) - Simple Evaluation (3 static questions) 
        SELECT DISTINCT
               bfr.business_org_fk AS buyer_org_id,
               sfr.business_org_fk AS supplier_org_id,
               ac.assignment_continuity_id,
               COUNT(CASE WHEN aea.assign_eval_answer = 'false' THEN aea.assign_eval_answer ELSE NULL END) number_of_negative_evals,
               COUNT(CASE WHEN aea.assign_eval_answer = 'true'  THEN aea.assign_eval_answer ELSE NULL END) number_of_positive_evals         
          FROM firm_role@db_link_name AS OF SCN source_db_SCN  bfr,
               firm_role@db_link_name AS OF SCN source_db_SCN  sfr,
               assignment_continuity@db_link_name AS OF SCN source_db_SCN ac,
               assignment_evaluation@db_link_name AS OF SCN source_db_SCN  aeval,
               assignment_evaluation_answer@db_link_name AS OF SCN source_db_SCN aea
         WHERE sfr.firm_id                   = ac.owning_supply_firm_fk     
           AND bfr.firm_id                   = ac.owning_buyer_firm_fk 
           AND ac.work_order_fk IS NULL
           AND ac.assignment_continuity_id   = aeval.assignment_evaluation_id
           AND aea.assignment_eval_fk        = aeval.assignment_evaluation_id
           AND aea.assign_eval_answer IS NOT NULL
         GROUP BY bfr.business_org_fk,
                  sfr.business_org_fk,
                  ac.assignment_continuity_id
        UNION ALL
        --Assignment (WO) - Simple Evaluation (3 static questions) 
        SELECT DISTINCT 
               bfr.business_org_fk AS buyer_org_id,
               sfr.business_org_fk AS supplier_org_id,
               ac.assignment_continuity_id,
               COUNT(CASE WHEN aea.assign_eval_answer = 'false' THEN aea.assign_eval_answer ELSE NULL END) number_of_negative_evals,
               COUNT(CASE WHEN aea.assign_eval_answer = 'true'  THEN aea.assign_eval_answer ELSE NULL END) number_of_positive_evals       
          FROM firm_role@db_link_name AS OF SCN source_db_SCN  bfr,
               firm_role@db_link_name AS OF SCN source_db_SCN  sfr,
               assignment_continuity@db_link_name AS OF SCN source_db_SCN ac,
               assignment_edition@db_link_name AS OF SCN source_db_SCN ae,
               assignment_evaluation@db_link_name AS OF SCN source_db_SCN  aeval,
               assignment_evaluation_answer@db_link_name AS OF SCN source_db_SCN aea
         WHERE sfr.firm_id                   = ac.owning_supply_firm_fk     
           AND bfr.firm_id                   = ac.owning_buyer_firm_fk 
           AND ac.current_edition_fk         = ae.assignment_edition_id
           AND ac.assignment_continuity_id   = ae.assignment_continuity_fk           
           AND ac.work_order_fk              IS NOT NULL           
           AND ae.evaluation_fk              = aeval.assignment_evaluation_id
           AND aea.assignment_eval_fk        = aeval.assignment_evaluation_id
           AND aea.assign_eval_answer        IS NOT NULL
         GROUP BY bfr.business_org_fk,
                  sfr.business_org_fk,
                  ac.assignment_continuity_id)                  
       )
GROUP BY buyer_org_id, 
         supplier_org_id, 
         assignment_continuity_id}';


BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
   
  UPDATE lego_refresh
     SET refresh_sql = v_clob
   WHERE object_name = v_lego_object_name;  
  
  COMMIT;
    
  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/
