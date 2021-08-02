/*******************************************************************************
SCRIPT NAME         lego_req_by_status_detail.sql
 
LEGO OBJECT NAME    LEGO_REQ_BY_STATUS_DETAIL
 
***************************MODIFICATION HISTORY ********************************

05/23/2018 - Paul Muller    - IQN-40327 - Initial version. SQL taken from LEGO_DASHBOARD_REFRESH
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_req_by_status_detail.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_REQ_BY_STATUS_DETAIL'; 

  v_clob CLOB :=
    q'{SELECT job_id, buyer_org_id,
              bo.bus_org_name AS buyer_org_name,
              hmp.display_name AS hiring_manager_name, 
              jc_description, job_state, job_created_date, 
              CAST(cp_jcl.constant_description AS VARCHAR2(20)) AS current_phase   --needed since JCL is defined as varchar2(4000) and that long length messes up IOTs
         FROM bus_org_iqp bo,
              person_iqp hmp,
              java_constant_lookup_iqp cp_jcl, 
              (SELECT job_id, buyer_org_id, hiring_mgr_person_id, jc_description, 
                      job_state, job_created_date, phase_type_id 
                 FROM job_iqp
                WHERE phase_type_id NOT IN (6, 7)  -- completed, archived
                  AND job_state_id <> 3  -- closed
                  AND template_availability IS NULL) a  -- exclude job templates 
        WHERE a.buyer_org_id = bo.bus_org_id 
          AND a.hiring_mgr_person_id = hmp.person_id
          AND a.phase_type_id = cp_jcl.constant_value
          AND cp_jcl.constant_type = 'JOB_PHASE'
          AND cp_jcl.locale_fk = 'EN_US'}';

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

