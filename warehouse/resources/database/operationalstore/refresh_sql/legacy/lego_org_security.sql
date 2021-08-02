/*******************************************************************************
SCRIPT NAME         lego_org_security.sql 
 
LEGO OBJECT NAME    LEGO_ORG_SECURITY
 
CREATED             04/27/2016
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_org_security.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ORG_SECURITY'; 

  v_clob CLOB :=
   q'{SELECT ancestor_bus_org_fk   AS login_org_id,
       descendant_bus_org_fk AS available_org_id
  FROM bus_org_lineage@db_link_name AS OF SCN source_db_SCN
 ORDER BY ancestor_bus_org_fk}';

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

