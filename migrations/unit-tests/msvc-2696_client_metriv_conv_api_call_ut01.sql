DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2696_client_metriv_conv_api_call_ut01.sql';
  lv_msg        VARCHAR2(255);
  lr_login_con_guid   RAW(16);
  lr_score_con_guid   RAW(16);
  lv_max_value  CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_ab_breakp CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_bc_breakp CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_cd_breakp CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_df_breakp CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_min_value CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_max_value_o  CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_ab_breakp_o CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_bc_breakp_o CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_cd_breakp_o CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_df_breakp_o CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
  lv_min_value_o CLIENT_METRIC_CONVERSION.LESS_THAN%TYPE;
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2696_client_metriv_conv_api_call_ut01');
  
  logger_pkg.info('Get data from CLIENT_METRIC_CONVERSION table...');

  SELECT LOG_IN_CLIENT_GUID, SCORE_CONFIG_OWNER_GUID
  INTO lr_login_con_guid, lr_score_con_guid
  FROM CLIENT_VISIBILITY_LIST
  WHERE rownum = 1;
   
    WITH pivot_data
    AS (SELECT client_guid, metric_id, range_grade, greater_than_or_equal, less_than 
          FROM client_metric_conversion
         WHERE client_guid = lr_score_con_guid
           AND metric_id = 12
           AND termination_date IS NULL)  --only current rows
	SELECT 
       CASE WHEN a_upper_breakpoint > b_upper_breakpoint THEN a_upper_breakpoint ELSE a_lower_breakpoint END AS max_value,
       CASE WHEN a_lower_breakpoint > b_lower_breakpoint THEN a_lower_breakpoint ELSE b_lower_breakpoint END AS ab_breakpoint,
       CASE WHEN b_lower_breakpoint > c_lower_breakpoint THEN b_lower_breakpoint ELSE c_lower_breakpoint END AS bc_breakpoint,
       CASE WHEN c_lower_breakpoint > d_lower_breakpoint THEN c_lower_breakpoint ELSE d_lower_breakpoint END AS cd_breakpoint,
       CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN d_lower_breakpoint ELSE f_lower_breakpoint END AS df_breakpoint,
       CASE WHEN d_lower_breakpoint > f_lower_breakpoint THEN f_lower_breakpoint ELSE f_upper_breakpoint END AS min_value
       INTO lv_max_value, lv_ab_breakp, lv_bc_breakp, lv_cd_breakp, lv_df_breakp, lv_min_value
  FROM pivot_data
		PIVOT 
		(MAX(greater_than_or_equal) AS lower_breakpoint,
        MAX(less_than) AS upper_breakpoint
			FOR  range_grade IN ('A' AS a,
								 'B' AS b,
                                 'C' AS c,
                                 'D' AS d,
                                 'F' AS f));
  

  CLIENT_METRIC_SETTINGS_UTIL.GET_CLIENT_METRIC_CONVERSION( lr_login_con_guid,
															 12,
															 lv_max_value_o,
															 lv_ab_breakp_o,
															 lv_bc_breakp_o,
															 lv_cd_breakp_o,
															 lv_df_breakp_o,
															 lv_min_value_o  
															 );
  
  IF (lv_max_value <> lv_max_value_o OR
	  lv_ab_breakp <> lv_ab_breakp_o OR
	  lv_bc_breakp <> lv_bc_breakp_o OR
	  lv_cd_breakp <> lv_cd_breakp_o OR
	  lv_df_breakp <> lv_df_breakp_o OR
	  lv_min_value <> lv_min_value_o ) THEN
    lv_msg := 'msvc-2696_client_metriv_conv_api_call_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-2696_client_metriv_conv_api_call_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

