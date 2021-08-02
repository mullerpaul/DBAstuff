DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2582_client_category_coefficient.sql';
  lv_msg        VARCHAR2(255);
  lv_object_cnt   PLS_INTEGER;
  lv_privs_tab_cnt   PLS_INTEGER;
  lv_column_cnt   PLS_INTEGER;
  
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('MSVC-2582 Unit Test');
  
  logger_pkg.info('Checking for new table and grants...');

  SELECT COUNT(*)
    INTO lv_object_cnt
    FROM user_tables
    WHERE table_name = 'CLIENT_CATEGORY_COEFFICIENT';

  SELECT COUNT(*)
    INTO lv_column_cnt
    FROM user_tab_columns
    WHERE table_name = 'CLIENT_CATEGORY_COEFFICIENT';

  SELECT COUNT(*)
    INTO lv_privs_tab_cnt
    FROM user_tab_privs
   WHERE table_name = 'CLIENT_CATEGORY_COEFFICIENT'
     and grantee IN ('OPS','READONLY','SUPPLIER_SCORECARD_USER');

  IF lv_object_cnt <> 1 or lv_column_cnt <> 8 or lv_privs_tab_cnt <> 6 THEN
    lv_msg := 'msvc-2582 unit test FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-2582 unit test PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

