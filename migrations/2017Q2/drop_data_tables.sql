DECLARE
  le_table_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_table_not_exist, -00942);
  
BEGIN
  /* This script will drop the two load perm tables if they exist.
     If they don't exist, this does nothing.
     We need this branching logic so our deploy will work in databases
     where the tables already have been deployed AND in new installs 
     which are built from scratch.  
     Hopefully, the need for this kind of thing will be reduced in the future! */

  BEGIN
    EXECUTE IMMEDIATE ('drop table supplier_submission');
  EXCEPTION
    WHEN le_table_not_exist THEN
      NULL;
  END;

  BEGIN
    EXECUTE IMMEDIATE ('drop table supplier_release');
  EXCEPTION
    WHEN le_table_not_exist THEN
      NULL;
  END;

END;
/

