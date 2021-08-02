DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-3967_check_beeline_data_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_data_cnt1   PLS_INTEGER;
  lv_data_cnt2   PLS_INTEGER;
  
   
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-3967_check_beeline_data_ut01.sql');
  
  logger_pkg.info('Checking Data routine...');


	
	SELECT COUNT(*) 
	INTO lv_data_cnt1
	FROM SUPPLIER_RELEASE  PARTITION (p_beeline_vms);
	
	
	SELECT COUNT(*) 
	INTO lv_data_cnt2
	FROM SUPPLIER_SUBMISSION  PARTITION (p_beeline_vms);



  IF lv_data_cnt1 <> 0 OR
	 lv_data_cnt2 <> 0  
  THEN
    lv_msg := 'msvc-3967_check_beeline_data_ut01.sql FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-3967_check_beeline_data_ut01.sql PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

