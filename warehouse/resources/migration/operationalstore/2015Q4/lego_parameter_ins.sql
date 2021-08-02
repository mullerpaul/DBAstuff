INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('inv_det_reprocess_max_cnt', 6, NULL, NULL, q'{number of times to attempt to reprocess a record in LEGO_INVOICE_DETAIL_ERROR}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('polling_interval', 30, NULL, NULL, q'{number of seconds to sleep between polls.}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('refresh_timeout_interval', 14400, NULL, NULL, q'{number of seconds of queueing before a refresh times out.}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('release_timeout_interval', 18000, NULL, NULL, 
        q'{number of seconds of queueing before release times out.  Should be longer than the refresh timeout.}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('start_second_pass_timeout_interval', 18600, NULL, NULL, 
        q'{number of seconds of queueing before 2nd pass wait times out.  Should be longer than the release timeout.}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('start_init_load_timeout_interval', 172800, NULL, NULL, q'{number of seconds of queueing before an initial load times out.}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('logging_level', NULL, q'{INFO}', NULL, 
        q'{The minimum logging level.  Acceptable values are {DEBUG|INFO|WARN|ERROR}. Messages below this level will not be logged.}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('lego_tenure_debugging_flag', NULL, q'{ON}', NULL, 
        q'{The TENURE refresh creates a number of intermediate tables.  If this parameter is ON, the tables are NOT dropped after the refresh.  This can aid in debugging.  Any other value means the tables are dropped.}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('months_in_refresh', 26, NULL, NULL, q'{Data deemed to be more than this number of months old will not be stored in legos.}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('lego_refresh_stats_flag', NULL, q'{Y}', NULL, 
        q'{This flag tells the lego refresh stats procedure in lego_refresh_mgr_pkg whether or not to run the stat report. Default is N - no}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('lego_refresh_stats_stddev_multiplier', 3, NULL, NULL, 
        q'{This value is multiplied by the standar deviation value in the lego refresh stats procedure in lego_refresh_mgr_pkg. Default is 3}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('lego_refresh_stats_lookback_days', 7, NULL, NULL, q'{This value determines how many days we look back for errors and standard deviation. Default is 7}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('lego_sc_num_quarters', 7, NULL, NULL, 
        q'{Used by Supplier Scorecard to determine how many quarters to build out.  7 is for 2 years to match our 2 year limitation we have imposed on other Legos.  The number should correspond to whatever limitation we have imposed on our Legos.}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('ResIQ_JT_WEIGHT', 10, NULL, NULL, q'{Resource IQ Scoring Weight for Job Title Match}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('ResIQ_JD_WEIGHT', 9, NULL, NULL, q'{Resource IQ Scoring Weight for Job Description Match}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('ResIQ_JL_WEIGHT', 2, NULL, NULL, q'{Resource IQ Scoring Weight for Job Level Match}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('ResIQ_JS_WEIGHT', 9, NULL, NULL, q'{Resource IQ Scoring Weight for Job Skills Match}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('inv_det_num_threads', 6, NULL, NULL, q'{number of threads or instances spawned during initial load of LEGO_INVOICE_DETAIL}')
/
INSERT INTO lego_parameter (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES ('lego_refresh_governor_cnt', 5, NULL, NULL, 
        q'{The governor (g_job_governor_cnt) is activated by having a value greater than 0, otherwise, the refreshes will run wide-open.  If the value is greater than zero than that is the max number of refreshes that will run at the same time.}')
/

COMMIT
/
