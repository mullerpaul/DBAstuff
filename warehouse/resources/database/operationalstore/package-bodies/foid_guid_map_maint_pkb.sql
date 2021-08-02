CREATE OR REPLACE PACKAGE BODY foid_guid_map_maint AS

  gc_curr_schema             CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');
  gc_source                  CONSTANT VARCHAR2(30) := 'FOID_GUID_MAP_MAINT';
  gv_error_stack             VARCHAR2(1000);  
  
  PROCEDURE load_job_foid_guid_map (pi_object_name IN lego_refresh.object_name%TYPE,
                                    pi_source      IN lego_refresh.source_name%TYPE) AS
  
  lv_source            VARCHAR2(61) := gc_source || '.load_job_foid_guid_map';
  lv_etl_load_date     DATE := SYSDATE;

  BEGIN

    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('load_job_foid_guid_map');  

    logger_pkg.debug('insert into job_foid_guid_map new job IDs');
    
    INSERT INTO job_foid_guid_map (job_id, job_guid, etl_load_date)
      SELECT j1.job_id, SYS_GUID() AS job_guid, lv_etl_load_date      
        FROM job@fo_iqp j1
       WHERE NOT EXISTS (SELECT j2.job_id
                           FROM job_foid_guid_map j2
                          WHERE j1.job_id = j2.job_id);  
                          
    COMMIT;                          
    logger_pkg.debug('insert into job_foid_guid_map new job IDs - complete. '||SQL%ROWCOUNT||' records inserted.', TRUE);
    logger_pkg.unset_source(lv_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_error_stack := SQLERRM || CHR(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('When others exception occurred during execution of '||lv_source||' - '||SQLERRM,TRUE);
      logger_pkg.unset_source(lv_source);
     
  END load_job_foid_guid_map;


  PROCEDURE load_job_opp_foid_guid_map (pi_object_name IN lego_refresh.object_name%TYPE,
                                        pi_source      IN lego_refresh.source_name%TYPE) AS

  lv_source            VARCHAR2(61) := gc_source || '.load_job_opp_foid_guid_map';
  lv_etl_load_date     DATE := SYSDATE;

  BEGIN

    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('load_job_opp_foid_guid_map');  

    logger_pkg.debug('insert into job_opp_foid_guid_map new job IDs');
    
    INSERT INTO job_opp_foid_guid_map (job_opportunity_id, job_opportunity_guid, etl_load_date)
      SELECT j1.job_opportunity_id, SYS_GUID() AS job_opportunity_guid, lv_etl_load_date      
        FROM job_opportunity@fo_iqp j1
       WHERE NOT EXISTS (SELECT j2.job_opportunity_id
                           FROM job_opp_foid_guid_map j2
                          WHERE j1.job_opportunity_id = j2.job_opportunity_id);  
                          
    COMMIT;                          
    logger_pkg.debug('insert into job_opp_foid_guid_map new job opportunity IDs - complete. '||SQL%ROWCOUNT||' records inserted.', TRUE);
    logger_pkg.unset_source(lv_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_error_stack := SQLERRM || CHR(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('When others exception occurred during execution of '||lv_source||' - '||SQLERRM,TRUE);
      logger_pkg.unset_source(lv_source);

  END load_job_opp_foid_guid_map;
      
  PROCEDURE load_match_foid_guid_map (pi_object_name IN lego_refresh.object_name%TYPE,
                                      pi_source      IN lego_refresh.source_name%TYPE) AS
  
  lv_source            VARCHAR2(61) := gc_source || '.load_match_foid_guid_map';
  lv_etl_load_date     DATE := SYSDATE;

  BEGIN

    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('load_match_foid_guid_map');  

    logger_pkg.debug('insert into match_foid_guid_map new job IDs');
    
    INSERT INTO match_foid_guid_map (match_id, match_guid, etl_load_date)
      SELECT j1.match_id, SYS_GUID() AS match_guid, lv_etl_load_date      
        FROM match@fo_iqp j1
       WHERE NOT EXISTS (SELECT j2.match_id
                           FROM match_foid_guid_map j2
                          WHERE j1.match_id = j2.match_id);  
                          
    COMMIT;                          
    logger_pkg.debug('insert into match_foid_guid_map new match IDs - complete. '||SQL%ROWCOUNT||' records inserted.', TRUE);
    logger_pkg.unset_source(lv_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_error_stack := SQLERRM || CHR(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('When others exception occurred during execution of '||lv_source||' - '||SQLERRM,TRUE);
      logger_pkg.unset_source(lv_source);  
  
  END load_match_foid_guid_map;

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_source(gc_source);
  logger_pkg.set_level('DEBUG');  
  
END foid_guid_map_maint;
/