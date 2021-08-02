DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2014_unit_test_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_object_cnt   PLS_INTEGER;
  lv_privs_tab_cnt   PLS_INTEGER;
  lv_column_cnt   PLS_INTEGER;
  lv_utility_cnt  PLS_INTEGER;
  
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('MSVC-2014 Unit Test');
  
  logger_pkg.info('Checking for supplier release duplicates...');

  SELECT COUNT(*)
    INTO lv_object_cnt
    FROM user_tab_columns
    WHERE table_name = 'SUPPLIER_RELEASE_DUPLICATES';
	
  SELECT COUNT(*)
    INTO lv_column_cnt
    FROM user_tab_columns
    WHERE table_name = 'SUPPLIER_RELEASE_DUPLICATES'
	AND column_name = 'INSERT_DATE';
	
  SELECT COUNT(*)
    INTO lv_privs_tab_cnt
    FROM user_tab_privs
    WHERE grantee IN ('OPS','READONLY')
	AND owner = 'SUPPLIER_SCORECARD'
	AND table_name = 'SUPPLIER_RELEASE_DUPLICATES'
    AND grantor = 'SUPPLIER_SCORECARD'
    AND privilege = 'SELECT';
	
  SELECT COUNT(*)
    INTO lv_utility_cnt
    FROM user_objects
    WHERE object_name = 'SUPPLIER_DATA_UTILITY'
	AND object_type = 'PACKAGE BODY'
	AND status = 'VALID';
	
   IF lv_object_cnt <> 20 or lv_column_cnt <> 1 or lv_privs_tab_cnt <> 2 or lv_utility_cnt <> 1 THEN
    lv_msg := 'Script msvc-2014_unit_test.sql FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'Script msvc-2014_unit_test.sql PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

