DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-3159_ssc_comments_table_ut02.sql';
  lv_msg        VARCHAR2(255);
  lc_dummy_client_guid   CONSTANT RAW(16) := hextoraw('ABCD000000000000000000000000ABCD');
  lr_session_guid  RAW(16) :=  SYS_GUID;
  lr_request_guid  RAW(16) :=  SYS_GUID;
  lv_comment_out  SUPPLIER_SCORECARD_COMMENTS.COMMENTS%TYPE;
  lv_comment_out2 SUPPLIER_SCORECARD_COMMENTS.COMMENTS%TYPE;

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-3159_ssc_comments_table_ut02');
  
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

	 
		client_metric_settings_util.SET_CLIENT_METRIC_CONVERSION(lc_dummy_client_guid,
																	25,
																	'datanauts',
																	lr_session_guid,
																	20,
																	30,
																	40,
																	50,
																	'This is a test for a comment column');

        client_metric_settings_util.get_supplier_scorecard_comment (lc_dummy_client_guid,lv_comment_out);

        
        client_metric_settings_util.SET_CLIENT_METRIC_CONVERSION(lc_dummy_client_guid,
																	25,
																	'datanauts',
																	lr_session_guid,
																	60,
																	70,
																	80,
																	90,
																	'This is a test for a comment2 column');
                                                                    
        client_metric_settings_util.get_supplier_scorecard_comment (lc_dummy_client_guid,lv_comment_out2);
        
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
	lv_comment_out <> 'This is a test for a comment column' OR
    lv_comment_out2 <> 'This is a test for a comment2 column'
  THEN
    lv_msg := 'msvc-3159_ssc_comments_table_ut02 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);

  END IF;
  
  lv_msg := 'msvc-3159_ssc_comments_table_ut02 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

