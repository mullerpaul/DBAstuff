DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2892_add_asof_input_on_get_api_cmco_ut03.sql';
  lv_msg        VARCHAR2(255);
  lc_dummy_client_guid   CONSTANT RAW(16) := hextoraw('ABCD000000000000000000000000ABCD');
  lr_session_guid  RAW(16) :=  SYS_GUID;
  lr_request_guid  RAW(16) :=  SYS_GUID;
  lv_max_value_old CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_ab_breakp_old CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_bc_breakp_old CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_cd_breakp_old CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_df_breakp_old CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_min_value_old CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_max_value_new CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_ab_breakp_new CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_bc_breakp_new CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_cd_breakp_new CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_df_breakp_new CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_min_value_new CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_max_value_oldr CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_ab_breakp_oldr CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_bc_breakp_oldr CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_cd_breakp_oldr CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_df_breakp_oldr CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_min_value_oldr CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  li_get_datetime_old TIMESTAMP;
  li_get_datetime_new TIMESTAMP;
  
  
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2892_add_asof_input_on_get_api_cmco_ut03');
  
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
    client_metric_settings_util.get_client_metric_conversion (lc_dummy_client_guid,
                                                               12,
                                                               li_get_datetime_old,
															   lv_max_value_old,
															   lv_ab_breakp_old,
															   lv_bc_breakp_old,
															   lv_cd_breakp_old,
															   lv_df_breakp_old,
															   lv_min_value_old
															  );
-- call SET here      
    client_metric_settings_util.set_client_metric_conversion(lc_dummy_client_guid,
                                                             12,
                                                             'datanauts',
															 lr_session_guid,
															 3,
                                                             5,
                                                             7,
                                                             11);
															   
                                                               
    li_get_datetime_new := ( systimestamp + 3);                                                
-- get the latest data here    
    client_metric_settings_util.get_client_metric_conversion (lc_dummy_client_guid,
                                                               12,
                                                               li_get_datetime_new,
															   lv_max_value_new,
															   lv_ab_breakp_new,
															   lv_bc_breakp_new,
															   lv_cd_breakp_new,
															   lv_df_breakp_new,
															   lv_min_value_new															
															  );

-- get the previous as of date data.    
    client_metric_settings_util.get_client_metric_conversion (lc_dummy_client_guid,
                                                               12,
                                                               li_get_datetime_old,
															   lv_max_value_oldr,
															   lv_ab_breakp_oldr,
															   lv_bc_breakp_oldr,
															   lv_cd_breakp_oldr,
															   lv_df_breakp_oldr,
															   lv_min_value_oldr															   
															  );

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
	
  IF (lv_max_value_old <> lv_max_value_oldr OR
	  lv_ab_breakp_old <> lv_ab_breakp_oldr OR
	  lv_bc_breakp_old <> lv_bc_breakp_oldr OR
	  lv_cd_breakp_old <> lv_cd_breakp_oldr OR
	  lv_df_breakp_old <> lv_df_breakp_oldr OR
	  lv_min_value_old <> lv_min_value_oldr OR
	  lv_max_value_new <> lv_max_value_old OR
	  lv_ab_breakp_new <> 3 OR
	  lv_bc_breakp_new <> 5 OR
	  lv_cd_breakp_new <> 7 OR
	  lv_df_breakp_new <> 11 	  
	  ) THEN
    lv_msg := 'msvc-2892_add_asof_input_on_get_api_cmco_ut03 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
  END IF;
  
  lv_msg := 'msvc-2892_add_asof_input_on_get_api_cmco_ut03 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 


EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/


