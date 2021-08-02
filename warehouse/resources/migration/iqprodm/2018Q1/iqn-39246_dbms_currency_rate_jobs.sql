--create job to refresh DM_CURRENCY_CONVERSION_RATES table.
DECLARE
 le_already_exists EXCEPTION;
 PRAGMA exception_init (le_already_exists, -27477);
 
BEGIN
  DBMS_SCHEDULER.CREATE_JOB(job_name      => 'DM_CURRENCY_RATE_JOBS',
                            program_name  => 'DM_PG_CURR_RATE_PROCESS',
                            schedule_name => 'DM_SCHED_SATURDAY_6AM_JOBS',
                            enabled       => FALSE);
EXCEPTION
  WHEN le_already_exists THEN 
    NULL;
  WHEN OTHERS THEN
    RAISE;
END;
/
