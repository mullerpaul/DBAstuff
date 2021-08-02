DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-1622_supplier_release_gtt_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_object_cnt   PLS_INTEGER;
   
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('Check for Table');
  
  logger_pkg.info('Checking for Supplier Release Table...');

  SELECT COUNT(*)
    INTO lv_object_cnt
    FROM user_tab_columns
    WHERE TABLE_NAME in ('SUPPLIER_RELEASE','SUPPLIER_RELEASE_GTT')
	AND COLUMN_NAME = 'DATABASE_NAME';


  IF lv_object_cnt <> 2 THEN
    lv_msg := 'Script msvc-1622_supplier_release_gtt.sql FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'Script msvc-1622_supplier_release_gtt.sql PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

