/*******************************************************************************
SCRIPT NAME         lego_req_by_status_org_rollup.sql
 
LEGO OBJECT NAME    LEGO_REQ_BY_STATUS_ORG_ROLLUP
 
***************************MODIFICATION HISTORY ********************************

05/23/2018 - Paul Muller    - IQN-40327 - Initial version. SQL taken from LEGO_DASHBOARD_REFRESH
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_req_by_status_org_rollup.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_REQ_BY_STATUS_ORG_ROLLUP'; 

  v_clob CLOB :=
    q'{SELECT s.login_user_id, s.login_org_id, d.current_phase, d.jc_description,
              COUNT(*) AS requisition_count
         FROM req_by_status_detail_iqp d,
              person_available_org s
        WHERE s.available_org_id = d.buyer_org_id
        GROUP BY s.login_user_id, s.login_org_id, d.current_phase, d.jc_description}';

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

