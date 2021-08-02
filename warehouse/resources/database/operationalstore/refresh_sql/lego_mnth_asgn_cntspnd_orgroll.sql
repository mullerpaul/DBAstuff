/*******************************************************************************
SCRIPT NAME         lego_mnth_asgn_cntspnd_orgroll.sql
 
LEGO OBJECT NAME    LEGO_MNTH_ASGN_CNTSPND_ORGROLL
 
***************************MODIFICATION HISTORY ********************************

05/23/2018 - Paul Muller    - IQN-40327 - Initial version. SQL taken from LEGO_DASHBOARD_REFRESH
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_mnth_asgn_cntspnd_orgroll.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MNTH_ASGN_CNTSPND_ORGROLL'; 

  v_clob CLOB :=
    q'{WITH recent_dashboard_users
    AS (SELECT DISTINCT login_user_id
          FROM appint.dashboard_api_calls
         WHERE call_time_utc >= add_months(SYSDATE, -2) --arbitrary cutoff
           AND login_user_id IS NOT NULL)
SELECT s.login_user_id, s.login_org_id, d.month_start,
       COUNT(*) AS monthly_assignment_count,
       SUM(d.invoiced_spend_per_month) AS monthly_invoiced_buyer_spend
  FROM mnth_assgn_list_spend_det_iqp d,
       person_available_org s,
       recent_dashboard_users r
 WHERE s.available_org_id = d.buyer_org_id
   AND s.login_user_id = r.login_user_id  -- limits users in table to keep it a reasonable size
 GROUP BY s.login_user_id, s.login_org_id, d.month_start}';

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

