/*******************************************************************************
SCRIPT NAME         lego_address.sql 
 
LEGO OBJECT NAME    LEGO_ADDRESS
SOURCE NAME         USPROD
 
CREATED             2/10/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_address.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ADDRESS'; 
  v_refresh_sql      CLOB;  
  

BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  v_refresh_sql := 'SELECT address_guid,
                           country_id,
                           country,
                           country_code,
                           state,
                           city,
                           postal_code,
                           place_id,
                           standard_place_desc,
                           line1,
                           line2,
                           line3,
                           line4,
                           county
                      FROM lego_address@db_link_name';
  
  UPDATE lego_refresh
     SET refresh_sql = v_refresh_sql
   WHERE object_name = v_lego_object_name;  
  
  COMMIT;
    
  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name|| ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/

