DECLARE
  le_sequence_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_sequence_not_exist, -02289);
  
BEGIN
  /* This script will drop the sequence for the METRIC table.
     If it doesn't exist, this does nothing. 
     We are dropping the sequence for these reasons:
       The metric IDs are hardcoded in the SQL, so we have hardcoded them in the migration scripts as well
       Because of that, the sequence is already out of sync with the table data.  */

  EXECUTE IMMEDIATE ('drop sequence METRIC_SEQ');

EXCEPTION
  WHEN le_sequence_not_exist THEN
    NULL;

END;
/

