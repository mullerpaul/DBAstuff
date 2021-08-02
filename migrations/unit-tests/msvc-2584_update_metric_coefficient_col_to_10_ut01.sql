DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2584_update_metric_coefficient_col_to_10_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_check_not_updated_data   PLS_INTEGER;
    
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2584_update_metric_coefficient_col_to_10_ut01');
  
  logger_pkg.info('Checking update on metric_coefficient column...');
	
	SELECT COUNT(*) 
	INTO lv_check_not_updated_data
	FROM CLIENT_METRIC_COEFFICIENT
	WHERE METRIC_COEFFICIENT <> '10'; 
	
  IF lv_check_not_updated_data <> 0 THEN
    lv_msg := 'msvc-2584_update_metric_coefficient_col_to_10_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
  END IF;
  
  lv_msg := 'msvc-2584_update_metric_coefficient_col_to_10_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/


