DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2695_client_metric_coeff_api_call_ut01.sql';
  lv_msg        VARCHAR2(255);
  lr_login_con_guid   RAW(16);
  lr_score_con_guid   RAW(16);
  lv_metric_coeff CLIENT_METRIC_COEFFICIENT.METRIC_COEFFICIENT%TYPE;
  lv_metric_coeff_cmc PLS_INTEGER;
   
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2695_client_metric_coeff_api_call_ut01');
  
  logger_pkg.info('Get data from CLIENT_METRIC_COEFFICIENT table...');

  SELECT LOG_IN_CLIENT_GUID, SCORE_CONFIG_OWNER_GUID
  INTO lr_login_con_guid, lr_score_con_guid
  FROM CLIENT_VISIBILITY_LIST
  WHERE rownum = 1;
   
  SELECT METRIC_COEFFICIENT
  INTO lv_metric_coeff_cmc
  FROM CLIENT_METRIC_COEFFICIENT
  WHERE CLIENT_GUID = lr_score_con_guid
   AND TERMINATION_DATE IS NULL
   AND METRIC_ID = 12;
  

  CLIENT_METRIC_SETTINGS_UTIL.get_client_metric_coefficient( lr_login_con_guid,
															 12,
															 lv_metric_coeff);
  
  IF (lv_metric_coeff <> lv_metric_coeff_cmc) THEN
    lv_msg := 'msvc-2695_client_metric_coeff_api_call_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-2695_client_metric_coeff_api_call_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

