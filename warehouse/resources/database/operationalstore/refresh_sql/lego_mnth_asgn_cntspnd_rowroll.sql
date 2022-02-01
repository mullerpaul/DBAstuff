/*******************************************************************************
SCRIPT NAME         lego_mnth_asgn_cntspnd_rowroll.sql
 
LEGO OBJECT NAME    LEGO_MNTH_ASGN_CNTSPND_ROWROLL
 
***************************MODIFICATION HISTORY ********************************

05/23/2018 - Paul Muller    - IQN-40327 - Initial version. SQL taken from LEGO_DASHBOARD_REFRESH
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_mnth_asgn_cntspnd_rowroll.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MNTH_ASGN_CNTSPND_ROWROLL'; 

  v_clob CLOB :=
    q'{SELECT r.login_user_id, o.login_org_id, d.month_start,
       COUNT(*) AS monthly_assignment_count,
       SUM(d.invoiced_spend_per_month) AS monthly_invoiced_buyer_spend
  FROM mnth_assgn_list_spend_det_iqp d,
       assignment_row_security_iqp r,
       person_available_org o
 WHERE d.assignment_continuity_id = r.assignment_id
   AND d.buyer_org_id = o.available_org_id
   AND r.login_user_id = o.login_user_id
 GROUP BY r.login_user_id, o.login_org_id, d.month_start}';

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
