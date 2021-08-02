DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2691_audit_table_client_metric_coefficient_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_row_count_effective_date  PLS_INTEGER;
  lv_row_count_termination_date   PLS_INTEGER;
  
  
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2691_audit_table_client_metric_coefficient_ut01');
  
  logger_pkg.info('Checking for audit tables');

    SELECT COUNT(*)
	INTO lv_row_count_effective_date
    FROM user_tab_columns
    WHERE table_name = 'CLIENT_METRIC_COEFFICIENT'
	AND column_name = 'EFFECTIVE_DATE'
    AND data_type = 'DATE'
    AND nullable = 'N';	
    
    SELECT COUNT(*)
	INTO lv_row_count_termination_date
    FROM user_tab_columns
    WHERE table_name = 'CLIENT_METRIC_COEFFICIENT'
	AND column_name = 'TERMINATION_DATE'
    AND data_type = 'DATE'
    AND nullable = 'Y';	

  IF (lv_row_count_effective_date <> 1 OR
     lv_row_count_termination_date <> 1 )	THEN
    lv_msg := 'msvc-2691_audit_table_client_metric_coefficient_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-2691_audit_table_client_metric_coefficient_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/


