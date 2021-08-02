DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-3257_ssc_convert_date_on_metrics_ut01.sql';
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
  lv_score_a_old CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_score_b_old CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_score_c_old CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_score_d_old CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_score_f_old CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_score_a_new CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_score_b_new CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_score_c_new CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_score_d_new CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_score_f_new CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  li_get_date TIMESTAMP;
  
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-3257_ssc_convert_date_on_metrics_ut01');
  
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

        

		li_get_date := TO_DATE(TRUNC(systimestamp));
		
		client_metric_settings_util.SET_ALL_METRIC_CONVERSION(lc_dummy_client_guid,
																25,
																'datanauts',
																lr_session_guid,
																55,
																45,
																35,
																25,
																15,
																2.0,
																3.0,
																4.0,
																5.0
																);
		
		
		client_metric_settings_util.get_client_metric_conversion (lc_dummy_client_guid,
																25,
                                                                li_get_date,
															    lv_max_value_old,
															    lv_ab_breakp_old,
															    lv_bc_breakp_old,
															    lv_cd_breakp_old,
															    lv_df_breakp_old,
															    lv_min_value_old);
    
        client_metric_settings_util.get_client_metric_score (lc_dummy_client_guid,
                                                            25,
                                                            li_get_date,
                                                            lv_score_a_old,
                                                            lv_score_b_old,
                                                            lv_score_c_old,
                                                            lv_score_d_old,
                                                            lv_score_f_old
                                                            );
		
		
		
		
		

        
		client_metric_settings_util.SET_ALL_METRIC_CONVERSION(lc_dummy_client_guid,
																25,
																'datanauts',
																lr_session_guid,
																60,
																50,
																40,
																30,
																20,
																2.5,
																3.5,
																4.5,
																5.5);
        
		client_metric_settings_util.get_client_metric_conversion (lc_dummy_client_guid,
																25,
                                                                li_get_date,
															    lv_max_value_new,
															    lv_ab_breakp_new,
															    lv_bc_breakp_new,
															    lv_cd_breakp_new,
															    lv_df_breakp_new,
															    lv_min_value_new
															    );
		
        client_metric_settings_util.get_client_metric_score (lc_dummy_client_guid,
                                                                25,
                                                                li_get_date,
                                                                lv_score_a_new,
                                                                lv_score_b_new,
                                                                lv_score_c_new,
                                                                lv_score_d_new,
                                                                lv_score_f_new
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

	DELETE FROM supplier_scorecard_comments
	WHERE client_guid = lc_dummy_client_guid;

    COMMIT;
   
		   
  IF 
	lv_max_value_old <> 0 OR
	lv_ab_breakp_old <> 2 OR
	lv_bc_breakp_old <> 3 OR
	lv_cd_breakp_old <> 4 OR
	lv_df_breakp_old <> 5 OR
	lv_min_value_old <> 10000 OR
	lv_max_value_new <> 0 OR
	lv_ab_breakp_new <> 2.5 OR
	lv_bc_breakp_new <> 3.5 OR
	lv_cd_breakp_new <> 4.5 OR
	lv_df_breakp_new <> 5.5 OR
	lv_min_value_new <> 10000 OR
    lv_score_a_old <> 55 OR
    lv_score_b_old <> 45 OR
    lv_score_c_old <> 35 OR
    lv_score_d_old <> 25 OR
    lv_score_f_old <> 15 OR
	lv_score_a_new <> 60 OR
    lv_score_b_new <> 50 OR
    lv_score_c_new <> 40 OR
    lv_score_d_new <> 30 OR
    lv_score_f_new <> 20
	
  THEN
    lv_msg := 'msvc-3257_ssc_convert_date_on_metrics_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-3257_ssc_convert_date_on_metrics_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

