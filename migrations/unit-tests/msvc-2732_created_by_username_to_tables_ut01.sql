DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2732_created_by_username_to_tables_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_rowcount_categoryusers  PLS_INTEGER;
  lv_rowcount_coefficientusers   PLS_INTEGER;
  lv_rowcount_conversionusers   PLS_INTEGER;
  
  
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2732_created_by_username_to_tables_ut01');
  
  logger_pkg.info('Checking for added username audit columns');

    SELECT COUNT(*)
	INTO lv_rowcount_categoryusers
    FROM user_tab_columns
    WHERE table_name = 'CLIENT_CATEGORY_COEFFICIENT'
	AND column_name = 'CREATED_BY_USERNAME'
    AND data_type = 'VARCHAR2'
    AND data_length IN (100,400)
    AND nullable = 'Y';	
    
    SELECT COUNT(*)
	INTO lv_rowcount_coefficientusers
    FROM user_tab_columns
    WHERE table_name = 'CLIENT_METRIC_COEFFICIENT'
	AND column_name = 'CREATED_BY_USERNAME'
    AND data_type = 'VARCHAR2'
    AND data_length IN (100,400)
    AND nullable = 'Y';	
    
    SELECT COUNT(*)
	INTO lv_rowcount_conversionusers
    FROM user_tab_columns
    WHERE table_name = 'CLIENT_METRIC_CONVERSION'
	AND column_name = 'CREATED_BY_USERNAME'
    AND data_type = 'VARCHAR2'
    AND data_length IN (100,400)
    AND nullable = 'Y';	
    

  IF (lv_rowcount_categoryusers <> 1 OR
     lv_rowcount_coefficientusers <> 1 OR
	 lv_rowcount_conversionusers <> 1)	THEN
    lv_msg := 'msvc-2732_created_by_username_to_tables_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-2732_created_by_username_to_tables_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/


