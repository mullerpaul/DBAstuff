/*******************************************************************************
SCRIPT NAME         lego_assgn_loc_st_atom_rr.sql
 
LEGO OBJECT NAME    LEGO_ASSGN_LOC_ST_ATOM_RR
 
***************************MODIFICATION HISTORY ********************************

05/23/2018 - Paul Muller    - IQN-40327 - Initial version. SQL taken from LEGO_DASHBOARD_REFRESH
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assgn_loc_st_atom_rr.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSGN_LOC_ST_ATOM_RR'; 

  v_clob CLOB :=
    q'{SELECT r.login_user_id, o.login_org_id, aad.cmsa_primary_state_code,
       COUNT(*) AS effective_assgn_count
  FROM assgn_atom_detail_iqp aad,
       assignment_row_security_iqp r,
       person_available_org o
 WHERE aad.assignment_continuity_id = r.assignment_id
   AND aad.buyer_org_id = o.available_org_id
   AND r.login_user_id = o.login_user_id
   AND aad.assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
   AND aad.current_phase_type_id IN (4, 5)   -- working, offboarding
 GROUP BY r.login_user_id, o.login_org_id, aad.cmsa_primary_state_code}';

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

