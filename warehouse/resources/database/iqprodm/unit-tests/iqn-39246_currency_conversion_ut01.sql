DECLARE
  lv_source          processing_log.source%TYPE := 'iqn-39246_currency_conversion.sql';
  lv_msg             VARCHAR2(255);
  lv_sequence_cnt    PLS_INTEGER;
  lv_sched_cnt       PLS_INTEGER;
  lv_prog_cnt        PLS_INTEGER;
  lv_job_cnt         PLS_INTEGER;
  lv_privs_tab_cnt   PLS_INTEGER;
  lv_table1          CONSTANT VARCHAR2(30) := 'DM_CURRENCY_CONVERSION_RATES';
  lv_table2          CONSTANT VARCHAR2(30) := 'DM_CURRENCY_DIM';
  lv_schema          CONSTANT VARCHAR2(30) := 'IQPRODM';
 
BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(lv_source);
  logger_pkg.set_code_location('IQN-39246 unit tests');
  
  logger_pkg.info('Checking number of sequences...');

  SELECT COUNT(*)
    INTO lv_sequence_cnt
    FROM user_sequences 
   WHERE sequence_name IN ('DM_CURRENCY_DIM_SEQ','CURR_CONV_DIM_SEQ');
   
  SELECT COUNT(*)
    INTO lv_sched_cnt
    FROM user_scheduler_schedules 
   WHERE schedule_name = 'DM_SCHED_SATURDAY_6AM_JOBS';
   
  SELECT COUNT(*)
    INTO lv_prog_cnt
    FROM user_scheduler_programs 
   WHERE program_name = 'DM_PG_CURR_RATE_PROCESS';
   
  SELECT COUNT(*)
    INTO lv_job_cnt
    FROM user_scheduler_jobs 
   WHERE job_name = 'DM_CURRENCY_RATE_JOBS'
     AND enabled = 'FALSE';

  SELECT COUNT(*)
    INTO lv_privs_tab_cnt
    FROM user_tab_privs
   WHERE table_name IN (lv_table1,lv_table2)
     AND grantee IN ('OPS','READONLY','OPERATIONALSTORE')
     AND grantor = lv_schema
     AND privilege = 'SELECT';
   
  IF lv_sequence_cnt <> 2 OR lv_sched_cnt <> 1 OR lv_prog_cnt <> 1 OR lv_job_cnt <> 1 OR lv_privs_tab_cnt <> 6 THEN
    lv_msg := 'At least one of the iqn-39246 scripts has FAILED.';
    logger_pkg.info(lv_msg, TRUE);
    raise_application_error(-20001, lv_msg);
	
  END IF;
  
  lv_msg := 'All of the iqn-39246 scripts have PASSED.';
  logger_pkg.info(lv_msg,TRUE);
  logger_pkg.unset_source(lv_source); 

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, SQLERRM, TRUE);
    logger_pkg.unset_source(lv_source);
    RAISE;
END;
/
