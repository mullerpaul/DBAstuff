DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2751_make_category_coefficient_FK_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_row_count_FKcheck  PLS_INTEGER;

  
  
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2751_make_category_coefficient_FK_ut01');
  
  logger_pkg.info('Checking for FK on category coefficient table');

    SELECT COUNT(*)
	INTO lv_row_count_FKcheck
    FROM USER_CONSTRAINTS A, USER_CONS_COLUMNS B 
    WHERE A.TABLE_NAME = B.TABLE_NAME AND B.TABLE_NAME = 'CLIENT_CATEGORY_COEFFICIENT' 
    AND B.COLUMN_NAME = 'LAST_TXN_GUID'
    AND A.CONSTRAINT_TYPE = 'R'
    AND A.CONSTRAINT_NAME = B.CONSTRAINT_NAME;

  IF lv_row_count_FKcheck <> 1     	THEN
    lv_msg := 'msvc-2751_make_category_coefficient_FK_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-2751_make_category_coefficient_FK_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/


