DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-1915_supp_data_and_excln_vw_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_object_cnt      PLS_INTEGER;
  lv_column_cnt_new  PLS_INTEGER;
  lv_column_cnt_old  PLS_INTEGER;
 
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('Check for Table');
  
  logger_pkg.info('Checking supp_data_and_exclusions_vw...');

  SELECT COUNT(*)
    INTO lv_object_cnt
    FROM user_objects
   WHERE object_name = 'SUPP_DATA_AND_EXCLUSIONS_VW';

  SELECT COUNT(*)
    INTO lv_column_cnt_new
    FROM user_tab_columns
   WHERE table_name = 'SUPP_DATA_AND_EXCLUSIONS_VW'
     AND column_name in ('LOG_IN_CLIENT_GUID','VISIBLE_CLIENT_GUID');

  SELECT COUNT(*)
    INTO lv_column_cnt_old
    FROM user_tab_columns
   WHERE table_name = 'SUPP_DATA_AND_EXCLUSIONS_VW'
     AND column_name = 'CLIENT_GUID';

  IF (lv_object_cnt     <> 1 OR 
      lv_column_cnt_new <> 2 OR 
      lv_column_cnt_old <> 0) THEN

    lv_msg := 'Script msvc-1915_supp_data_and_excln_vw.sql FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'Script msvc-1915_supp_data_and_excln_vw.sql PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

