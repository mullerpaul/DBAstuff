DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2892_add_asof_input_on_get_api_ccc_ut01.sql';
  lv_msg        VARCHAR2(255);
  lc_dummy_client_guid   CONSTANT RAW(16) := hextoraw('ABCD000000000000000000000000ABCD');
  lr_session_guid  RAW(16) :=  SYS_GUID;
  lr_request_guid  RAW(16) :=  SYS_GUID;
  lv_cat_coeff_old CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE;
  lv_cat_coeff_new CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE;
  lv_cat_coeff_oldr CLIENT_CATEGORY_COEFFICIENT.CATEGORY_COEFFICIENT%TYPE;
  li_get_datetime_old TIMESTAMP;
  li_get_datetime_new TIMESTAMP;

  
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2892_add_asof_input_on_get_api_ccc_ut01');
  
  -- setup DUMMY CLIENT here   
    INSERT INTO client_visibility_list ( 
		log_in_client_guid, 
		visible_client_guid,
		score_config_owner_guid ) 
    VALUES ( 
		lc_dummy_client_guid,
        lc_dummy_client_guid,
        lc_dummy_client_guid );

    	client_metric_settings_util.copy_defaults_to_client (lc_dummy_client_guid,
                                                             lr_session_guid,
                                                             lr_request_guid);			
		
     COMMIT; 
	  
 -- get the existing data here       
        
    li_get_datetime_old := systimestamp;      
    client_metric_settings_util.get_client_catgry_coefficient (lc_dummy_client_guid,
                                                                 'cost',
                                                                 li_get_datetime_old,
                                                                 lv_cat_coeff_old);
    
    
                                                                 
   
                                                             
-- call SET here      
    client_metric_settings_util.set_client_catgry_coefficient(lc_dummy_client_guid,
                                                              'cost',
                                                               5,
                                                              'datanauts',
                                                               sys_guid); 


    

    li_get_datetime_new := systimestamp + 3; 
    DBMS_OUTPUT.PUT_LINE('li_get_datetime_new: ' || li_get_datetime_new);
-- get the latest data here    
    client_metric_settings_util.get_client_catgry_coefficient (lc_dummy_client_guid,
                                                                 'cost',
                                                                 li_get_datetime_new,
                                                                 lv_cat_coeff_new);
   
-- get the previous as of date data.    
    client_metric_settings_util.get_client_catgry_coefficient (lc_dummy_client_guid,
                                                                 'cost',
                                                                 li_get_datetime_old,
                                                                 lv_cat_coeff_oldr);

													 
-- delete data

    DELETE FROM client_visibility_list 
	WHERE log_in_client_guid = lc_dummy_client_guid;

    DELETE FROM client_category_coefficient 
	WHERE client_guid = lc_dummy_client_guid;

    DELETE FROM client_metric_coefficient 
	WHERE client_guid = lc_dummy_client_guid;

    DELETE FROM client_metric_conversion
    WHERE client_guid = lc_dummy_client_guid;

    DELETE FROM transaction_log 
	WHERE bus_org_guid = lc_dummy_client_guid;


    COMMIT;
	
  IF (lv_cat_coeff_old <> lv_cat_coeff_oldr OR
      lv_cat_coeff_new <> 5  
	  ) THEN
    lv_msg := 'msvc-2892_add_asof_input_on_get_api_ccc_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
  END IF;
  
  lv_msg := 'msvc-2892_add_asof_input_on_get_api_ccc_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 


EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/


