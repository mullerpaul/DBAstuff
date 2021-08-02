DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2585_modify_dataload_precategory_ut01.sql';
  lv_msg        VARCHAR2(255);
  lr_client_guid   RAW(16) := hextoraw('ABCD000000000000000000000000ABCD');
  lr_session_guid  RAW(16) :=  sys_guid;
  lr_request_guid  RAW(16) :=  sys_guid;
  lv_metric_data PLS_INTEGER;
  lv_check_newclient_ccc   PLS_INTEGER;
  lv_check_newclient_cmc   PLS_INTEGER;
  lv_check_mtrx_data_ccc  PLS_INTEGER;
  lv_check_mtrx_data_cmc  PLS_INTEGER;
  lv_check_newclient_cmco  PLS_INTEGER;
    
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2585_modify_dataload_precategory_ut01');
  
  logger_pkg.info('Checking on data load for new clients...');

	client_metric_settings_util.copy_defaults_to_client (lr_client_guid,
                                                           lr_session_guid,
                                                           lr_request_guid);														   
  
	
	SELECT COUNT(*) 
	INTO lv_metric_data
	FROM METRIC;
	
	SELECT COUNT(*)
	INTO lv_check_newclient_ccc
	FROM CLIENT_CATEGORY_COEFFICIENT
	WHERE CLIENT_GUID = lr_client_guid;


	SELECT COUNT(*)
	INTO lv_check_newclient_cmc
	FROM CLIENT_METRIC_COEFFICIENT
	WHERE CLIENT_GUID = lr_client_guid;

	SELECT COUNT(*) 
	INTO lv_check_mtrx_data_cmc
	FROM CLIENT_METRIC_COEFFICIENT
	WHERE METRIC_COEFFICIENT <> 10
	AND CLIENT_GUID = lr_client_guid; 

	SELECT COUNT(*) 
	INTO lv_check_mtrx_data_ccc
	FROM CLIENT_CATEGORY_COEFFICIENT
	WHERE CATEGORY_COEFFICIENT <> 10
	AND CLIENT_GUID = lr_client_guid; 	
	
	
	SELECT COUNT(con.client_metric_conversion_guid)
	INTO lv_check_newclient_cmco
	FROM CLIENT_METRIC_COEFFICIENT COE,
    CLIENT_METRIC_CONVERSION con
	WHERE COE.CLIENT_METRIC_COEFFICIENT_GUID = con.CLIENT_METRIC_COEFFICIENT_GUID
	AND COE.CLIENT_GUID = lr_client_guid; 
	
	
	
	ROLLBACK;
	
  IF (lv_check_newclient_ccc <> 3 OR
	  lv_check_newclient_cmc <> lv_metric_data OR
	  lv_check_mtrx_data_cmc <> 0 OR
	  lv_check_mtrx_data_ccc <> 0 OR
	  lv_check_newclient_cmco <> (5 * lv_metric_data)
	  )  THEN
    lv_msg := 'msvc-2585_modify_dataload_precategory_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-2585_modify_dataload_precategory_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 
	
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/
