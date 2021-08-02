DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2896_metric_range_grade_conv_ut01.sql';
  lv_msg        VARCHAR2(255);
  lr_login_con_guid   RAW(16);
  lr_score_con_guid   RAW(16);
  lv_obj_cnt_ccc PLS_INTEGER;
  lv_obj_cnt_cmc PLS_INTEGER;
  lv_obj_cnt_cmco PLS_INTEGER;
  
  
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2896_metric_range_grade_conv_ut01');
  
  logger_pkg.info('Revoking update, delete, insert grants to supplier_scorecard_user test');

    SELECT COUNT(*)
	INTO lv_obj_cnt_ccc
    FROM user_tab_privs
    WHERE table_name = 'CLIENT_CATEGORY_COEFFICIENT'
        AND grantee = 'SUPPLIER_SCORECARD_USER'
        AND privilege in ('UPDATE','INSERT','DELETE');
        
    SELECT COUNT(*)
	INTO lv_obj_cnt_cmc
    FROM user_tab_privs
    WHERE table_name = 'CLIENT_METRIC_COEFFICIENT'
        AND grantee = 'SUPPLIER_SCORECARD_USER'
        AND privilege in ('UPDATE','INSERT','DELETE');
        
    SELECT COUNT(*)
	INTO lv_obj_cnt_cmco
    FROM user_tab_privs
    WHERE table_name = 'CLIENT_METRIC_CONVERSION'
        AND grantee = 'SUPPLIER_SCORECARD_USER'
        AND privilege in ('UPDATE','INSERT','DELETE');       
        
  
  IF (  
		lv_obj_cnt_ccc <> 0 OR
		lv_obj_cnt_cmc <> 0 OR
		lv_obj_cnt_cmco <> 0
  
			) THEN
    lv_msg := 'msvc-2896_metric_range_grade_conv_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-2896_metric_range_grade_conv_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

