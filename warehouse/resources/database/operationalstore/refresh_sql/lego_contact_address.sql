/*******************************************************************************
SCRIPT NAME         lego_contact_address.sql 
 
LEGO OBJECT NAME    LEGO_CONTACT_ADDRESS
SOURCE NAME         USPROD
 
CREATED             2/10/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_contact_address.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_CONTACT_ADDRESS'; 
  v_refresh_sql      CLOB;  
  

BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  v_refresh_sql := 'WITH pivot_data AS (
                    SELECT buyer_org_id AS bus_org_id, 
                           address_type, 
                           contact_info_id, 
                           address_guid
                      FROM lego_contact_address@db_link_name )         
                    SELECT *
                      FROM pivot_data
                     PIVOT (MAX(address_guid) 
                       FOR address_type IN (''Notice'' AS notice_address_guid,
                                            ''Headquarter'' AS hq_address_guid,
                                            ''Payment''     AS payment_address_guid,
                                            ''Primary''     AS primary_address_guid,
                                            ''Home''        AS home_address_guid,
                                            ''Work''        AS work_address_guid))'; 
  
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

