DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2764_redesign_client_metric_conversion_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_cnt_remove_fk PLS_INTEGER;
  lv_cnt_new_client_guid PLS_INTEGER;
  lv_cnt_new_metric_col PLS_INTEGER;
  lv_cnt_new_metric_fk PLS_INTEGER;
  lv_cnt_removed_column PLS_INTEGER;

	
    
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2764_redesign_client_metric_conversion_ut01');
  
  logger_pkg.info('Checking for table modification on CLIENT_METRIC_CONVERSION');

    SELECT COUNT(*)
	INTO lv_cnt_remove_fk
    FROM USER_CONSTRAINTS A, USER_CONS_COLUMNS B 
    WHERE A.TABLE_NAME = B.TABLE_NAME AND B.TABLE_NAME = 'CLIENT_METRIC_CONVERSION' 
    AND B.COLUMN_NAME = 'CLIENT_METRIC_COEFFICIENT_GUID'
    AND A.CONSTRAINT_TYPE = 'R'
    AND A.CONSTRAINT_NAME = B.CONSTRAINT_NAME;
    
    
    SELECT COUNT(*)
	INTO lv_cnt_new_client_guid
	FROM user_tab_columns
    WHERE table_name = 'CLIENT_METRIC_CONVERSION'
	AND column_name = 'CLIENT_GUID'
    AND data_type = 'RAW'
    AND data_length = 16
	AND nullable = 'N';	
    
    SELECT COUNT(*)
	INTO lv_cnt_new_metric_col
	FROM user_tab_columns
    WHERE table_name = 'CLIENT_METRIC_CONVERSION'
    AND column_name = 'METRIC_ID'
    AND data_type = 'NUMBER'
    AND data_length = '22'
	AND nullable = 'N';	
	
    SELECT COUNT(*)
    INTO lv_cnt_new_metric_fk
    FROM USER_CONSTRAINTS A, USER_CONS_COLUMNS B 
    WHERE A.TABLE_NAME = B.TABLE_NAME AND B.TABLE_NAME = 'CLIENT_METRIC_CONVERSION' 
    AND B.COLUMN_NAME = 'METRIC_ID'
    AND A.CONSTRAINT_TYPE = 'R'
    AND A.CONSTRAINT_NAME = B.CONSTRAINT_NAME;
    
    SELECT COUNT(*)
	INTO lv_cnt_removed_column
	FROM user_tab_columns
    WHERE table_name = 'CLIENT_METRIC_CONVERSION'
	AND column_name = 'CLIENT_METRIC_COEFFICIENT_GUID';	

  IF (lv_cnt_remove_fk <> 0     OR 	
      lv_cnt_new_client_guid <> 1 OR
	  lv_cnt_new_metric_col <> 1 OR
	  lv_cnt_new_metric_fk <> 1 OR
	  lv_cnt_removed_column <> 0 )THEN
    lv_msg := 'msvc-2764_redesign_client_metric_conversion_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-2764_redesign_client_metric_conversion_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/


