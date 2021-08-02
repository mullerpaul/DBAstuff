DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-1666_create_client_visibility_list_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_object_cnt   PLS_INTEGER;
  lv_privs_tab_cnt   PLS_INTEGER;
  lv_column_cnt   PLS_INTEGER;
  
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('Check for Table');
  
  logger_pkg.info('Checking for table...');

  SELECT COUNT(*)
    INTO lv_object_cnt
    FROM user_objects
    WHERE object_name = 'CLIENT_VISIBILITY_LIST_GTT'
	AND object_type = 'TABLE'
	AND temporary = 'Y';
	
  SELECT COUNT(*)
    INTO lv_privs_tab_cnt
    FROM user_tab_privs
    WHERE grantee IN ('OPS','READONLY','OPERATIONALSTORE','SSIS_USER')
	AND owner = 'SUPPLIER_SCORECARD'
	AND table_name = 'CLIENT_VISIBILITY_LIST_GTT'
    AND grantor = 'SUPPLIER_SCORECARD'
    AND privilege = 'SELECT';
	
  SELECT COUNT(*)
    INTO lv_column_cnt
    FROM user_tab_columns
    WHERE table_name = 'LOAD_HISTORY'
	AND column_name = 'MERGED_ROWS_VISIBILITY_TABLE'
	AND data_type = 'NUMBER';

  IF lv_object_cnt <> 1 or lv_privs_tab_cnt <> 4 or lv_column_cnt <> 1 THEN
    lv_msg := 'Script msvc-1666_create_client_visibility_list_gtt.sql FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'Script msvc-1666_create_client_visibility_list_gtt.sql PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

