DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-3864_check_data_in_supp_rel_dup_ut01.sql';
  lv_msg        VARCHAR2(255);
  lv_data_cnt   PLS_INTEGER;
   
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-3864_check_data_in_supp_rel_dup_ut01.sql');
  
  logger_pkg.info('Checking for Load Package Datatest Is Valid...');


	
SELECT COUNT(*) 
	INTO lv_data_cnt
	FROM SUPPLIER_SCORECARD.SUPPLIER_RELEASE_DUPLICATES;


  IF lv_data_cnt <> 0 THEN
    lv_msg := 'msvc-3864_check_data_in_supp_rel_dup_ut01.sql FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-3864_check_data_in_supp_rel_dup_ut01.sql PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

