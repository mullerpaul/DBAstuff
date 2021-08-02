DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-3159_ssc_comments_table_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_object_cnt   PLS_INTEGER;
  lv_column_cnt   PLS_INTEGER;
  lv_col_client_guid PLS_INTEGER;
  lv_col_txn_date PLS_INTEGER;
  lv_col_cbusername PLS_INTEGER;
  lv_col_comments PLS_INTEGER;
  
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-3159_ssc_comments_table_ut01');
  
  logger_pkg.info('Checking for new table...');

	SELECT COUNT(*)
    INTO lv_object_cnt
    FROM user_tables
    WHERE table_name = 'SUPPLIER_SCORECARD_COMMENTS';

	SELECT COUNT(*)
    INTO lv_column_cnt
    FROM user_tab_columns
    WHERE table_name = 'SUPPLIER_SCORECARD_COMMENTS';

	SELECT COUNT(*)
	INTO lv_col_client_guid
    FROM user_tab_columns
    WHERE table_name = 'SUPPLIER_SCORECARD_COMMENTS'
	AND column_name = 'CLIENT_GUID'
    AND data_type = 'RAW'
    AND data_length = 16
    AND nullable = 'N';	

    SELECT COUNT(*)
	INTO lv_col_txn_date
    FROM user_tab_columns
    WHERE table_name = 'SUPPLIER_SCORECARD_COMMENTS'
	AND column_name = 'LAST_TXN_DATE'
    AND data_type = 'DATE'
    AND nullable = 'Y';	

    SELECT COUNT(*)
	INTO lv_col_cbusername
    FROM user_tab_columns
    WHERE table_name = 'SUPPLIER_SCORECARD_COMMENTS'
	AND column_name = 'CREATED_BY_USERNAME'
    AND data_type = 'VARCHAR2'
    AND data_length IN (100,400)
    AND nullable = 'Y';	
    
    SELECT COUNT(*)
	INTO lv_col_comments
    FROM user_tab_columns
    WHERE table_name = 'SUPPLIER_SCORECARD_COMMENTS'
	AND column_name = 'COMMENTS'
    AND data_type = 'VARCHAR2'
    AND nullable = 'Y';	  


  IF lv_object_cnt <> 1 OR 
	 lv_column_cnt <> 4 OR
	 lv_col_client_guid <> 1 OR
	 lv_col_txn_date <> 1 OR
	 lv_col_cbusername <> 1 OR
	 lv_col_comments <> 1 THEN
    lv_msg := 'msvc-3159_ssc_comments_table_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-3159_ssc_comments_table_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

