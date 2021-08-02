/*******************************************************************************
SCRIPT NAME         lego_assign_managed_cac.sql
 
LEGO OBJECT NAME    LEGO_ASSIGN_MANAGED_CAC
 
***************************MODIFICATION HISTORY ********************************

Ticket     Author           Description
IQN-40225  Paul Muller      Initial version - copied from lego_row_security package
 
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assign_managed_cac.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSIGN_MANAGED_CAC'; 

  v_clob CLOB :=
      q'{SELECT mc.user_id, ctk.assignment_continuity_id
           FROM assignment_cac_map_iqp ctk,
                managed_cac_iqp mc
          WHERE mc.cac_value_id = ctk.cac_value_id}';

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

