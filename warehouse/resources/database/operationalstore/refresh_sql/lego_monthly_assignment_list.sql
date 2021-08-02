/*******************************************************************************
SCRIPT NAME         lego_monthly_assignment_list.sql
 
LEGO OBJECT NAME    LEGO_MONTHLY_ASSIGNMENT_LIST
 
***************************MODIFICATION HISTORY ********************************

05/23/2018 - Paul Muller    - IQN-40327 - Initial version. SQL taken from LEGO_DASHBOARD_REFRESH
10/29/2018 - Paul Muller    - IQN-41588 - Changes to use "minimal" assignment legos.

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_monthly_assignment_list.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MONTHLY_ASSIGNMENT_LIST'; 

  v_clob CLOB :=
      q'{  WITH month_list  -- list of months from Jan of previous year to now.  between 13 and 24 rows.
    AS (SELECT trunc(add_months(sysdate, -1 * (LEVEL-1)), 'MM')     AS month_start,
               trunc(add_months(sysdate, -1 * (LEVEL-1) + 1), 'MM') AS month_end
          FROM dual
       CONNECT BY LEVEL <= 1 + months_between(TRUNC(SYSDATE, 'MM'), TRUNC(add_months(SYSDATE, -12), 'YY'))),
       assignment_list
    AS (SELECT assignment_continuity_id, buyer_org_id, assignment_start_dt, assignment_actual_end_dt
          FROM minimal_assignment_ea_ta_iqp
         WHERE assignment_state_id <> 6  -- get rid of this? or not?  possible also add filter on ever_been_active
           AND assignment_actual_end_dt >= TRUNC(add_months(SYSDATE, -12), 'YYYY') -- ended or will end AFTER Jan-01 the previous year.
           AND assignment_start_dt < TRUNC(add_months(SYSDATE, 1), 'MONTH')       -- started or will start before the beginning of next month
         UNION ALL
        SELECT assignment_continuity_id, buyer_org_id, assignment_start_dt, assignment_actual_end_dt
          FROM minimal_assignment_wo_iqp
         WHERE assignment_state_id <> 6  -- get rid of this? or not?  possible also add filter on ever_been_active
           AND assignment_actual_end_dt >= TRUNC(add_months(SYSDATE, -12), 'YYYY') -- ended or will end AFTER Jan-01 the previous year.
           AND assignment_start_dt < TRUNC(add_months(SYSDATE, 1), 'MONTH'))       -- started or will start before the beginning of next month           
SELECT a.assignment_continuity_id, a.buyer_org_id, m.month_start 
  FROM month_list m,
       assignment_list a
 WHERE m.month_start <= a.assignment_actual_end_dt
   AND m.month_end > a.assignment_start_dt}';

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

