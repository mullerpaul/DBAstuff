DECLARE
    lv_source     processing_log.source%TYPE := 'msvc-2896_metric_range_grade_conv_ut02.sql';
    lv_msg                 VARCHAR2(255);
    lc_dummy_client_guid   CONSTANT RAW(16) := hextoraw('ABCD000000000000000000000000ABCD');
    lr_session_guid  RAW(16) :=  SYS_GUID;
    lr_request_guid  RAW(16) :=  SYS_GUID;
	lv_rangescore_a CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
	lv_rangescore_b CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
	lv_rangescore_c CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
	lv_rangescore_d CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
	lv_rangescore_f CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
    
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2896_metric_range_grade_conv_ut02');
  
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
        
-- call SET here
        
        client_metric_settings_util.set_client_metric_score(lc_dummy_client_guid,
															12,
															'datanauts',
															lr_session_guid,
															90,
															85,
															80,
															75,
															70);
            
-- SQL stetment here
        
    WITH pivot_data
    AS (SELECT client_guid, metric_id, range_grade, range_score 
          FROM client_metric_conversion
         WHERE client_guid = lc_dummy_client_guid
           AND metric_id = 12
           AND termination_date IS NULL)  --only current rows
	SELECT 
        a_range_score AS a_score,
        b_range_score AS b_score,
        c_range_score AS c_score,
        d_range_score AS d_score,
        f_range_score AS f_score
		INTO
		lv_rangescore_a,
		lv_rangescore_b,
		lv_rangescore_c,
		lv_rangescore_d,
		lv_rangescore_f
  FROM pivot_data
		PIVOT 
		(MAX(range_score) AS range_score
			FOR  range_grade IN ('A' AS a,
								 'B' AS b,
                                 'C' AS c,
                                 'D' AS d,
                                 'F' AS f));         

-- remove data

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
	
    IF(  
		lv_rangescore_a <> 90 OR
		lv_rangescore_b <> 85 OR
		lv_rangescore_c <> 80 OR
		lv_rangescore_d <> 75 OR
		lv_rangescore_f <> 70 )
    THEN
    lv_msg := 'msvc-2896_metric_range_grade_conv_ut02 FAILED.';
    logger_pkg.info(lv_msg);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-2896_metric_range_grade_conv_ut02 PASSED.';
  logger_pkg.info(lv_msg);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/