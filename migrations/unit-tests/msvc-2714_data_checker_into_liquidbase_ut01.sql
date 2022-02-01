DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2714_data_checker_into_liquidbase_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_object_cnt   PLS_INTEGER;
   
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2714_data_checker_into_liquidbase_ut01');
  
  logger_pkg.info('Checking for Load Package Datatest Is Valid...');

  SELECT COUNT(*)
    INTO lv_object_cnt
    FROM user_objects
    WHERE object_name = 'DATA_TEST'
	AND object_type = 'PACKAGE BODY'
	AND status = 'VALID';


  IF lv_object_cnt <> 1 THEN
    lv_msg := 'Script msvc-2714_data_checker_into_liquidbase_ut01.sql FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'Script msvc-2714_data_checker_into_liquidbase_ut01.sql PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/
