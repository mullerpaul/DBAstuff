/* Clean-up script for IQN-32537 to remove 1st/2nd pass logic
   and wait for release concept. 
   
   1. Remove release and 2nd pass dbms_scheduler programs.
   2. Drop the ck04 constraint on lego_refresh_group in order
      to drop the run_in_first_pass column since the constraint
      was a 2-column check constraint.
   3. Drop release and 1st/2nd pass-related columns.
   4. Remove release and 1st/2nd pass-related parameters from lego_parameter. */

DECLARE
  e_program_does_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT (e_program_does_not_exist, -27476);
BEGIN
  BEGIN
    dbms_scheduler.drop_program('LEGO_REFRESH_RELEASE_PROGRAM');
  EXCEPTION
    WHEN e_program_does_not_exist
      THEN NULL;    --suppress "program does not exist" error
  END;
  BEGIN
    dbms_scheduler.drop_program('LEGO_REFRESH_2PASS_PROGRAM');
  EXCEPTION
    WHEN e_program_does_not_exist
      THEN NULL;    --suppress "program does not exist" error
  END;  
END;
/

ALTER TABLE lego_refresh_group DROP CONSTRAINT lego_refresh_group_ck04
/
ALTER TABLE lego_refresh_history DROP COLUMN release_time
/
ALTER TABLE lego_refresh_group DROP COLUMN run_in_first_pass
/
ALTER TABLE lego_refresh_group DROP COLUMN allow_partial_release
/
ALTER TABLE lego_refresh DROP COLUMN waiting_for_release
/
ALTER TABLE lego_refresh DROP COLUMN release_sql
/

DELETE FROM lego_parameter
 WHERE parameter_name IN ('release_timeout_interval','start_second_pass_timeout_interval')
/
COMMIT
/