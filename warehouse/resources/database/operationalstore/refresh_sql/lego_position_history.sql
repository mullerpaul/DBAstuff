/*******************************************************************************
SCRIPT NAME         lego_position_history.sql
 
LEGO OBJECT NAME    LEGO_POSITION_HISTORY
 
CREATED             11/09/2016
 
ORIGINAL AUTHOR     Joe Pullifrone & Paul Muller

***************************MODIFICATION HISTORY ********************************

11/09/2016 - IQN-35614  Initial version.  Created for use by TTF lego
05/04/2017 - IQN-37567  Renamed this from LEGO_POSITION_TIME_TO_FILL to LEGO_POSITION_HISTORY.

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_position_history.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_POSITION_HISTORY';

  v_clob CLOB :=            
   q'{SELECT pp.job_fk            AS job_id,
       pp.position_pool_id,
       p.position_id,
       pttfh.position_history_id,
       ps.type              AS position_state,
       pttfh.date_available,
       pttfh.date_offer_accepted,
       p.date_eliminated,
       p.date_abandoned
  FROM position_pool@db_link_name AS OF SCN source_db_SCN pp,
       position@db_link_name AS OF SCN source_db_SCN p,
       position_time_to_fill_history@db_link_name AS OF SCN source_db_SCN pttfh,
       position_state@db_link_name AS OF SCN source_db_SCN ps     
 WHERE pp.position_pool_id = p.position_pool_fk
   AND p.position_id       = pttfh.position_fk(+) 
   AND p.position_state_fk = ps.value}';        

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

