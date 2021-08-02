/*******************************************************************************
SCRIPT NAME         lego_secure_inv_assgnmt.sql 
 
LEGO OBJECT NAME    LEGO_SECURE_INV_ASSGNMT
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

 
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_secure_inv_assgnmt.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_SECURE_INV_ASSGNMT'; 

  v_clob CLOB :=
      q'{SELECT lsa.user_id, lsa.assignment_id 
          FROM lego_secure_assignment_vw lsa
         UNION ALL
        SELECT DISTINCT person_fk AS user_id, -1 AS assignment_id
          FROM iq_user}';

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

