DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2694_client_metric_settings_api_call_ut01.sql';
  lv_msg        VARCHAR2(255);
  lr_login_con_guid   RAW(16);
  lr_score_con_guid   RAW(16);
  lv_cat_coefficient CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE;
  lv_cat_coeff_ccc PLS_INTEGER;
   
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2694_client_metric_settings_api_call_ut01');
  
  logger_pkg.info('Get data from CLIENT_CATEGORY_COEFFICIENT table...');

  SELECT LOG_IN_CLIENT_GUID, SCORE_CONFIG_OWNER_GUID
  INTO lr_login_con_guid, lr_score_con_guid
  FROM CLIENT_VISIBILITY_LIST
  WHERE rownum = 1;
   
  SELECT CATEGORY_COEFFICIENT
  INTO lv_cat_coeff_ccc
  FROM CLIENT_CATEGORY_COEFFICIENT
  WHERE CLIENT_GUID = lr_score_con_guid
	AND TERMINATION_DATE is NULL
	AND METRIC_CATEGORY = 'candidate quality';
  

  CLIENT_METRIC_SETTINGS_UTIL.GET_CLIENT_CATGRY_COEFFICIENT( lr_login_con_guid,
															 'candidate quality',
															 lv_cat_coefficient);
  
  IF (lv_cat_coefficient <>  lv_cat_coeff_ccc) THEN
    lv_msg := 'msvc-2694_client_metric_settings_api_call_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-2694_client_metric_settings_api_call_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

