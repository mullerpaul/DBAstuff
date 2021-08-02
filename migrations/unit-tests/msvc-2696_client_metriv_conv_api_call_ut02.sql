DECLARE
    lv_source     processing_log.source%TYPE := 'msvc-2696_client_metriv_conv_api_call_ut02.sql';
    lv_msg                 VARCHAR2(255);
    lc_dummy_client_guid   CONSTANT RAW(16) := hextoraw('ABCD000000000000000000000000ABCD');
    lr_session_guid  RAW(16) :=  SYS_GUID;
    lr_request_guid  RAW(16) :=  SYS_GUID;
    lv_max_value1 NUMBER; 
    lv_ab_breakp1 NUMBER; 
    lv_bc_breakp1 NUMBER; 
    lv_cd_breakp1 NUMBER; 
    lv_df_breakp1 NUMBER;  
    lv_min_value1 NUMBER; 
    lv_max_value2 NUMBER; 
    lv_ab_breakp2 NUMBER; 
    lv_bc_breakp2 NUMBER; 
    lv_cd_breakp2 NUMBER; 
    lv_df_breakp2 NUMBER; 
    lv_min_value2 NUMBER;
    
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2696_client_metriv_conv_api_call_ut02');
  
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
        
        client_metric_settings_util.set_client_metric_conversion(lc_dummy_client_guid,
                                                                 12,
                                                                 sysdate,
                                                                 'datanauts',
                                                                 lr_session_guid,
                                                                 3,
                                                                 5,
                                                                 7,
                                                                 11);
                                                                 
          client_metric_settings_util.set_client_metric_conversion(lc_dummy_client_guid,
                                                                 17,
                                                                 sysdate,
                                                                 'datanauts',
                                                                 lr_session_guid,
                                                                 6,
                                                                 5,
                                                                 4,
                                                                 2);                                                               

            
-- SQL stetment here
        
    WITH pivot_data
    AS (SELECT client_guid, metric_id, range_grade, greater_than_or_equal, less_than 
          FROM client_metric_conversion
         WHERE client_guid = lc_dummy_client_guid
           AND metric_id = 12
           AND termination_date IS NULL)  --only current rows
	SELECT 
       CASE WHEN a_upper_breakpoint > b_upper_breakpoint THEN a_upper_breakpoint ELSE a_lower_breakpoint END AS max_value,
       CASE WHEN a_lower_breakpoint > b_lower_breakpoint THEN a_lower_breakpoint ELSE b_lower_breakpoint END AS ab_breakpoint,
       CASE WHEN b_lower_breakpoint > c_lower_breakpoint THEN b_lower_breakpoint ELSE c_lower_breakpoint END AS bc_breakpoint,
       CASE WHEN c_lower_breakpoint > d_lower_breakpoint THEN c_lower_breakpoint ELSE d_lower_breakpoint END AS cd_breakpoint,
       CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN d_lower_breakpoint ELSE f_lower_breakpoint END AS df_breakpoint,
       CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN f_lower_breakpoint ELSE f_upper_breakpoint END AS min_value
       INTO lv_max_value1, 
            lv_ab_breakp1, 
            lv_bc_breakp1, 
            lv_cd_breakp1, 
            lv_df_breakp1, 
            lv_min_value1
  FROM pivot_data
		PIVOT 
		(MAX(greater_than_or_equal) AS lower_breakpoint,
        MAX(less_than) AS upper_breakpoint
			FOR  range_grade IN ('A' AS a,
								 'B' AS b,
                                 'C' AS c,
                                 'D' AS d,
                                 'F' AS f));        
        
    WITH pivot_data
    AS (SELECT client_guid, metric_id, range_grade, greater_than_or_equal, less_than 
          FROM client_metric_conversion
         WHERE client_guid = lc_dummy_client_guid
           AND metric_id = 17
           AND termination_date IS NULL)  --only current rows
	SELECT 
       CASE WHEN a_upper_breakpoint > b_upper_breakpoint THEN a_upper_breakpoint ELSE a_lower_breakpoint END AS max_value,
       CASE WHEN a_lower_breakpoint > b_lower_breakpoint THEN a_lower_breakpoint ELSE b_lower_breakpoint END AS ab_breakpoint,
       CASE WHEN b_lower_breakpoint > c_lower_breakpoint THEN b_lower_breakpoint ELSE c_lower_breakpoint END AS bc_breakpoint,
       CASE WHEN c_lower_breakpoint > d_lower_breakpoint THEN c_lower_breakpoint ELSE d_lower_breakpoint END AS cd_breakpoint,
       CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN d_lower_breakpoint ELSE f_lower_breakpoint END AS df_breakpoint,
       CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN f_lower_breakpoint ELSE f_upper_breakpoint END AS min_value
       INTO lv_max_value2, 
            lv_ab_breakp2, 
            lv_bc_breakp2, 
            lv_cd_breakp2, 
            lv_df_breakp2, 
            lv_min_value2
  FROM pivot_data
		PIVOT 
		(MAX(greater_than_or_equal) AS lower_breakpoint,
        MAX(less_than) AS upper_breakpoint
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
    lv_max_value1 <> 0 OR 
    lv_ab_breakp1 <> 3 OR 
    lv_bc_breakp1 <> 5 OR 
    lv_cd_breakp1 <> 7 OR 
    lv_df_breakp1 <> 11 OR 
    lv_min_value1 <> 10000 OR
    lv_max_value2 <> 10000 OR 
    lv_ab_breakp2 <> 6 OR 
    lv_bc_breakp2 <> 5 OR 
    lv_cd_breakp2 <> 4 OR 
    lv_df_breakp2 <> 2 OR 
    lv_min_value2 <> 0)
    THEN
    lv_msg := 'msvc-2696_client_metriv_conv_api_call_ut02 FAILED.';
    logger_pkg.info(lv_msg);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-2696_client_metriv_conv_api_call_ut02 PASSED.';
  logger_pkg.info(lv_msg);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/