DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2889_remove_effective_date_on_set_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_check_term_date   PLS_INTEGER;
    
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2889_remove_effective_date_on_set_ut01');
  
  logger_pkg.info('Checking update on effective date exist as parameters...');
	
	SELECT COUNT(*) 
	INTO lv_check_term_date
    FROM user_arguments 
	WHERE package_name = 'CLIENT_METRIC_SETTINGS_UTIL'
	and object_name like 'SET%'
	and argument_name = 'PI_EFFECTIVE_DATE';
	
  IF lv_check_term_date <> 0 THEN
    lv_msg := 'msvc-2889_remove_effective_date_on_set_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
  END IF;
  
  lv_msg := 'msvc-2889_remove_effective_date_on_set_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/


