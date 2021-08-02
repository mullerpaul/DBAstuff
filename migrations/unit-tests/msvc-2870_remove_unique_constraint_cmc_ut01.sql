DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2870_remove_unique_constraint_cmc_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_cnt_remove_fk PLS_INTEGER;
	
    
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2870_remove_unique_constraint_cmc_ut01');
  
  logger_pkg.info('Checking for table modification on CLIENT_METRIC_COEFFICIENT');

	SELECT COUNT(*)
	INTO lv_cnt_remove_fk
    FROM USER_CONSTRAINTS A, USER_CONS_COLUMNS B 
    WHERE A.TABLE_NAME = B.TABLE_NAME AND B.TABLE_NAME = 'CLIENT_METRIC_COEFFICIENT' 
    AND B.COLUMN_NAME in ('METRIC_ID', 'CLIENT_GUID')
    AND A.CONSTRAINT_TYPE = 'U'
    AND A.CONSTRAINT_NAME = B.CONSTRAINT_NAME;
    

  IF lv_cnt_remove_fk <> 0    THEN
    lv_msg := 'msvc-2870_remove_unique_constraint_cmc_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-2870_remove_unique_constraint_cmc_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/


