-- We are no longer going to use this job to start lego refreshes automatically.
-- Each consumer of lego data will now call their own refresh procedure to have
-- the data refreshed on demand.
DECLARE 
  le_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_not_exist, -27475);

BEGIN
  dbms_scheduler.drop_job('LEGO_REFRESH_KICKOFF');

EXCEPTION
  WHEN le_not_exist
    THEN NULL;

END;
/

