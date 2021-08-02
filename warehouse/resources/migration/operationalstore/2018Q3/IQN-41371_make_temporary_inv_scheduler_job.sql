ALTER SESSION SET time_zone = dbtimezone
/

DECLARE
    /* Get the current date and time in the session timezone */
    lv_start_date TIMESTAMP WITH TIME ZONE := CURRENT_TIMESTAMP;

    /* Create a random whole number between 5 and 50 to use as the minute of the start time.
       We do this to try to avoid CPU spikes on the DB server caused by the jobs starting at 
       the same time in many databases on the same server. 
       So within a single database, these four jobs will all start at the same number of minutes 
       past the hour (in different hours); but it should be a different number of minute than other 
       databases on the same server (or any server).  */
    lv_byminute   NUMBER := 5 + FLOOR(45 * dbms_random.value);

    PROCEDURE make_job (
        pi_name      IN VARCHAR2,
        pi_action    IN VARCHAR2,
        pi_hour      IN NUMBER,
        pi_minute    IN NUMBER,
        pi_comment   IN VARCHAR
    ) IS
        le_job_already_exists EXCEPTION;
        PRAGMA exception_init ( le_job_already_exists,-27477 );
        lv_repeat VARCHAR2(40);

    BEGIN
        lv_repeat := 'freq=daily; byhour='
                       || TO_CHAR(pi_hour)
                       || '; byminute='
                       || TO_CHAR(pi_minute);

        dbms_scheduler.create_job(
            job_name          => pi_name,
            job_type          => 'PLSQL_BLOCK',
            job_action        => pi_action,
            start_date        => lv_start_date,
            repeat_interval   => lv_repeat,
            enabled           => false,  --create jobs disabled.  We will manually enable them per-environment where needed.
            comments          => pi_comment
        );

        logger_pkg.info('Created ' 
                         || pi_name 
                         || ' repeat clause: '
                         || lv_repeat);
    EXCEPTION
        WHEN le_job_already_exists THEN
            /* If the job already exists - enabled or disabled - then just log a message and exit. */
            logger_pkg.warn(pi_message   => 'kickoff job already exists - exiting.');
    END;

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('IQN-41371 create refresh job');
  logger_pkg.info('Creating dbms_scheduler job to kick off lego refreshes for invoice data automatically.');

  --------
  make_job('TEMP_REFRESH_INVOICE_LEGOS','BEGIN lego_refresh_invoice_data.start_refresh_run(240); END;', 8, lv_byminute, 'refresh invoice legos on a schedule.'); 

  --------
  logger_pkg.unset_source('IQN-41371 create refresh job');

END;
/
