DECLARE
  lv_source     processing_log.source%TYPE := 'msvc-2896_metric_range_grade_conv_ut01.sql';
  lv_msg        VARCHAR2(255);
  lr_login_con_guid   RAW(16);
  lr_score_con_guid   RAW(16);
  lv_rangescore_a CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_rangescore_b CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_rangescore_c CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_rangescore_d CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_rangescore_f CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_rangescore_ao CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_rangescore_bo CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_rangescore_co CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_rangescore_do CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  lv_rangescore_fo CLIENT_METRIC_CONVERSION.RANGE_SCORE%TYPE;
  
  
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('msvc-2896_metric_range_grade_conv_ut01');
  
  logger_pkg.info('Get range_score from CLIENT_METRIC_CONVERSION table...');

  SELECT LOG_IN_CLIENT_GUID, SCORE_CONFIG_OWNER_GUID
  INTO lr_login_con_guid, lr_score_con_guid
  FROM CLIENT_VISIBILITY_LIST
  WHERE rownum = 1;
   
    WITH pivot_data
    AS (SELECT client_guid, metric_id, range_grade, range_score 
          FROM client_metric_conversion
         WHERE client_guid = lr_score_con_guid
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
  

  CLIENT_METRIC_SETTINGS_UTIL.GET_CLIENT_METRIC_SCORE( lr_login_con_guid,
													  12,
													  lv_rangescore_ao,
											          lv_rangescore_bo,
											          lv_rangescore_co,
											          lv_rangescore_do,
											          lv_rangescore_fo
											   );
  
  IF (lv_rangescore_a <> lv_rangescore_ao OR
	  lv_rangescore_b <> lv_rangescore_bo OR
	  lv_rangescore_c <> lv_rangescore_co OR
	  lv_rangescore_d <> lv_rangescore_do OR
	  lv_rangescore_f <> lv_rangescore_fo     ) THEN
    lv_msg := 'msvc-2896_metric_range_grade_conv_ut01 FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'msvc-2896_metric_range_grade_conv_ut01 PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);    
    RAISE;
END;
/

