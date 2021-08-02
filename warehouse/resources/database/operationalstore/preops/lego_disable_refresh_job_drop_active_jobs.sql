DECLARE
  le_job_not_running EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_job_not_running, -27366);
  le_job_is_running EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_job_is_running, -27478);

  le_job_does_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_job_does_not_exist, -27476);
  le_not_a_job EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_not_a_job, -27475);
  
  v_source               VARCHAR2(64) := 'lego_disable_refresh_job_drop_active_jobs.sql';
  v_refresh_job_name     VARCHAR2(30) := 'LEGO_REFRESH_KICKOFF';
  v_num pls_integer;

BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source(v_source);
  
     
  logger_pkg.set_code_location('Disable Main Refresh Job to prevent new jobs from starting');
  BEGIN
    logger_pkg.info('Disabling DBMS_SCHEDULER job, '|| v_refresh_job_name); 
    dbms_scheduler.disable(v_refresh_job_name);
    logger_pkg.info('Sucessfully disabled DBMS_SCHEDULER job, '|| v_refresh_job_name, TRUE);
  EXCEPTION
    WHEN le_job_is_running     THEN
      logger_pkg.info('DBMS_SCHEDULER job, '|| v_refresh_job_name ||', is running', TRUE);
    WHEN le_job_does_not_exist THEN 
      logger_pkg.info('DBMS_SCHEDULER job, '|| v_refresh_job_name ||', does not exist', TRUE);
    WHEN OTHERS THEN
      logger_pkg.fatal(NULL, SQLCODE, 'Error disabling DBMS_SCHEDULER job, '|| v_refresh_job_name ||' - ' || SQLERRM, TRUE);
      logger_pkg.unset_source(v_source);
      RAISE;      
  END;
  
  logger_pkg.set_code_location('Drop Scheduled, Retries that are scheduled, and Running Object Refresh Jobs');
  /* You must drop the scheduled jobs first so they don't start after you drop the running jobs */
  FOR i IN ( SELECT job_name, state, DECODE(state, 'SCHEDULED', 0,'RETRY SCHEDULED', 1, 'RUNNING',2,3) AS priority 
               FROM user_scheduler_jobs
              WHERE job_name      LIKE 'LEGO%'
                AND schedule_type = 'ONCE' 
              ORDER BY priority ) 
  LOOP

    BEGIN      
      logger_pkg.info('Dropping DBMS_SCHEDULER job, ' || i.job_name||' in state '||i.state);    
      dbms_scheduler.drop_job(job_name => i.job_name, force => TRUE);
      logger_pkg.info('Sucessfully dropped DBMS_SCHEDULER job, ' || i.job_name||' in state '||i.state, TRUE);
    EXCEPTION
      WHEN le_not_a_job          THEN 
        logger_pkg.info('DBMS_SCHEDULER job, ' || i.job_name || ' is not a job', TRUE);
      WHEN le_job_does_not_exist THEN 
        logger_pkg.info('DBMS_SCHEDULER job, ' || i.job_name || ' does not exist', TRUE);  
      WHEN OTHERS THEN
        logger_pkg.fatal(NULL, SQLCODE, 'Error dropping DBMS_SCHEDULER jobs - ' || SQLERRM, TRUE);
        logger_pkg.unset_source(v_source);
        RAISE;            
    END;

  END LOOP;

  logger_pkg.unset_source(v_source);
  
  
END;
/
