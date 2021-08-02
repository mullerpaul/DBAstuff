/*******************************************************************************
SCRIPT NAME         lego_upcoming_ends_detail.sql
 
LEGO OBJECT NAME    LEGO_UPCOMING_ENDS_DETAIL
 
***************************MODIFICATION HISTORY ********************************

05/23/2018 - Paul Muller    - IQN-40327 - Initial version. SQL taken from LEGO_DASHBOARD_REFRESH
10/29/2018 - Paul Muller    - IQN-41588 - Changes to use "minimal" assignment legos.

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_upcoming_ends_detail.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_UPCOMING_ENDS_DETAIL'; 

  v_clob CLOB :=
      q'{SELECT assignment_continuity_id, bo.bus_org_id, bo.bus_org_name AS buyer_org_name, 
       so.bus_org_name AS supplier_org_name, hmp.display_name AS hiring_manager_name, 
       assignment_start_dt, assignment_end_dt, job_category, days_until_assignment_end
  FROM (SELECT assignment_continuity_id, buyer_org_id, supplier_org_id,
               hiring_mgr_person_id, assignment_start_dt, assignment_end_dt, 
               NVL(jc_description, 'Undefined') AS job_category,  --does NOT use localized or custom names like lego_assignment_vw
               TRUNC(assignment_end_dt) - TRUNC(SYSDATE) AS days_until_assignment_end
          FROM minimal_assignment_ea_ta_iqp
         WHERE assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
           AND current_phase_type_id IN (4, 5)   -- working, offboarding - do we need this?
           AND assignment_end_dt BETWEEN TRUNC(SYSDATE-10) AND TRUNC(SYSDATE+30)
         UNION ALL
        SELECT assignment_continuity_id, buyer_org_id, supplier_org_id,
               hiring_mgr_person_id, assignment_start_dt, assignment_end_dt, 
               NVL(jc_description, 'Undefined') AS job_category,
               TRUNC(assignment_end_dt) - TRUNC(SYSDATE) AS days_until_assignment_end
          FROM minimal_assignment_wo_iqp
         WHERE assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
           AND current_phase_type_id IN (4, 5)   -- working, offboarding - do we need this?
           AND assignment_end_dt BETWEEN TRUNC(SYSDATE-10) AND TRUNC(SYSDATE+30)) a, 
       bus_org_iqp bo,
       bus_org_iqp so,
       person_iqp hmp
 WHERE a.buyer_org_id = bo.bus_org_id
   AND a.supplier_org_id = so.bus_org_id
   AND a.hiring_mgr_person_id = hmp.person_id(+)}';

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

