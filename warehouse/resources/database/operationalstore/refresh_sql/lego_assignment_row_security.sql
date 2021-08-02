/*******************************************************************************
SCRIPT NAME         lego_assignment_row_security.sql
 
LEGO OBJECT NAME    LEGO_ASSIGNMENT_ROW_SECURITY
 
***************************MODIFICATION HISTORY ********************************

Ticket     Author           Description
IQN-40225  Paul Muller      Initial version - copied from lego_row_security package
 
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assignment_row_security.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSIGNMENT_ROW_SECURITY'; 

  /* May want to experiment with replacing UNION ALL & DISTINCT with just a UNION.  */
  v_clob CLOB :=
      q'{SELECT DISTINCT login_user_id, assignment_id
           FROM (SELECT lmp.manager_person_id AS login_user_id, 
                        lsa.assignment_id
                   FROM managed_person_iqp lmp,
                        assignment_slots_iqp lsa
                  WHERE lmp.employee_person_id = lsa.user_id
                  UNION ALL
                 SELECT amc.user_id AS login_user_id, 
                        amc.assignment_continuity_id AS assignment_id
                   FROM assign_managed_cac_iqp amc)}';

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

