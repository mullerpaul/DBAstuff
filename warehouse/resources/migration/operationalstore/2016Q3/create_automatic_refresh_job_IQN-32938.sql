DECLARE
  lv_timezone_offset VARCHAR2(10);
  le_job_already_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_job_already_exists, -27477);

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('migration script for IQN-32938 create automatic refresh job');
  logger_pkg.info('Creating dbms_scheduler job which can kick off lego refreshes automatically.');

  /* Find the timezone of the database and use it for the job start time. */
  lv_timezone_offset := DBTIMEZONE;

  /* I'm not 100% sure this is correct; but it might not matter.  We seem to want the legos
    to run at 6am and 6pm of the timezone local to the database.  In US, with Mountian 
    time, that works out to 8am east coast time and 5pm west cost time - just outside 
    of normal business hours in North America.  I wonder if that works out in Europe with 
    a 6 oclock in Germany start time?  In any case, the start time of the job matters little,
    as it runs every two hours.  The legos will refresh based on the time in 
    LEGO_REFRESH.refresh_on_or_after_time, which we can change!   */

  BEGIN
    dbms_scheduler.create_job(job_name   => 'LEGO_REFRESH_KICKOFF',
                              job_type   => 'PLSQL_BLOCK',
                              job_action => 'BEGIN lego_refresh_mgr_pkg.refresh; END;',
                              /* Start time of 6am on the same day this runs.  use DB timezone (which is UTC in most or all cases) */
                              start_date => to_timestamp_tz(lv_timezone_offset || ' ' ||
                                                            to_char(trunc(SYSDATE) + 6 / 24, 'YYYY-Mon-DD hh24:mi'),
                                                            'TZH:TZM YYYY-Mon-DD hh24:mi'),
                              /* repeat every 4 hours.  Use "byhours" instead of using "freq" so we don't get weird things at DST changeovers */
                              repeat_interval => 'freq=daily; byhour=2,6,10,14,18,22',
                              /* create it disabled.  We can enable later if needed. */
                              enabled  => FALSE,
                              comments => 'Master refresh job for LEGOs');
  
    logger_pkg.info('Creating dbms_scheduler job which can kick off lego refreshes automatically - complete', TRUE);
    
  EXCEPTION
    WHEN le_job_already_exists THEN
      /* If the job already exists - enabled or disabled - then we just log a message and exit. */
      logger_pkg.warn(pi_message => 'kickoff job already exists - exiting.');
    
  END;

  logger_pkg.unset_source('migration script for IQN-32938 create automatic refresh job');

END;
/
