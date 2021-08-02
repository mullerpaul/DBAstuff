DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2776_change_load_procedure_client_vis_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_cnt_chk_null   PLS_INTEGER;
  lv_cnt_alt_col_cvl PLS_INTEGER;
  lv_cnt_alt_col_cvlgtt PLS_INTEGER;
  
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2776_change_load_procedure_client_vis_ut01');
  logger_pkg.info('Checking for CLIENT_VISIBILITY_LIST tables data load...');

    SELECT COUNT(*)
	INTO lv_cnt_chk_null
	FROM CLIENT_VISIBILITY_LIST
    WHERE SCORE_CONFIG_OWNER_GUID IS NULL OR
	      LOG_IN_CLIENT_GUID IS NULL OR
	      VISIBLE_CLIENT_GUID IS NULL;
	
	
	SELECT COUNT(*)
	INTO lv_cnt_alt_col_cvl
	FROM user_tab_columns
    WHERE table_name = 'CLIENT_VISIBILITY_LIST'
	AND column_name = 'SCORE_CONFIG_OWNER_GUID'
    AND data_type = 'RAW'
    AND data_length = 16
	AND nullable = 'N';	
	
	SELECT COUNT(*)
	INTO lv_cnt_alt_col_cvlgtt
	FROM user_tab_columns
    WHERE table_name = 'CLIENT_VISIBILITY_LIST_GTT'
	AND column_name = 'SCORE_CONFIG_OWNER_GUID'
    AND data_type = 'RAW'
    AND data_length = 16
	AND nullable = 'N';	
	
   IF (lv_cnt_chk_null <> 0 OR 
	   lv_cnt_alt_col_cvl <> 1 OR
	   lv_cnt_alt_col_cvlgtt <> 1) THEN
    lv_msg := 'msvc-2776_change_load_procedure_client_vis_ut01.sql FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-2776_change_load_procedure_client_vis_ut01.sql PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

