/*******************************************************************************
SCRIPT NAME         lego_all_orgs_calendar.sql 
 
LEGO OBJECT NAME    LEGO_ALL_ORGS_CALENDAR
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************


                                  
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_all_orgs_calendar.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ALL_ORGS_CALENDAR'; 

  v_clob CLOB :=            
                q'{SELECT b.buyer_org_id, NVL(calendar_id,1) AS calendar_id 
                     FROM lego_org_calendar c, 
                          lego_buyer_org_vw b 
                    WHERE b.buyer_org_id = c.buyer_org_id(+)
                    ORDER BY buyer_org_id}';          
         

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

