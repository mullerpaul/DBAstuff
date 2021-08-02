DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-1915 unit test';
  lv_msg        VARCHAR2(255);
  lv_total_login_guids      NUMBER;
  lv_configured_login_guids NUMBER;
   
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('Check for client copies of metric scoring info');
  
  logger_pkg.info('Checking ...');

    WITH client_settings
      AS (SELECT coef.client_guid, 
                 COUNT(DISTINCT coef.metric_id) AS metric_settings_count, COUNT(*) AS metric_ranges_count
            FROM client_metric_coefficient coef, client_metric_conversion conv 
           WHERE conv.client_metric_coefficient_guid = coef.client_metric_coefficient_guid 
           GROUP BY coef.client_guid),
         distinct_log_in_guids
      AS (SELECT DISTINCT log_in_client_guid
            FROM client_visibility_list)   
  SELECT COUNT(*) AS total_log_in_guids, 
         COUNT(client_guid) AS log_in_guids_with_metrc_config
    INTO lv_total_login_guids, lv_configured_login_guids
    FROM distinct_log_in_guids dg, 
         client_settings cs
   WHERE dg.log_in_client_guid = cs.client_guid(+);

  IF lv_total_login_guids <> lv_configured_login_guids THEN
    lv_msg := 'Script msvc-1915_copy_defaults FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'Script msvc-1915_copy_defaults PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

