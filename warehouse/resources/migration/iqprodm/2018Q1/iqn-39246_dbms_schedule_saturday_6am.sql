--create schedule for Saturdays at 6am to mirror that which runs in IQPRODM in US db.
DECLARE
 le_already_exists EXCEPTION;
 PRAGMA exception_init (le_already_exists, -27477);
BEGIN
  DBMS_SCHEDULER.CREATE_SCHEDULE(schedule_name   => 'DM_SCHED_SATURDAY_6AM_JOBS',
                                 start_date      => TRUNC(SYSDATE)+6/24,
                                 repeat_interval => 'FREQ=WEEKLY; BYDAY=SAT; BYHOUR=6;',
                                 comments        => 'Run at 6am on Saturday');
EXCEPTION
  WHEN le_already_exists THEN 
    NULL;
  WHEN OTHERS THEN
    RAISE;
END;
/ 