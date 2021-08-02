DECLARE
  le_table_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_table_not_exist, -00942);
  
BEGIN
  /* We need to reload all beeline data due to a data issue. MSVC-1344.
     We could do a DELETE based on legacy_souce_vms, but that is SLOW.
     We tried just truncating both data tables (Beeline and IQN data),
     but that was not possible due to the reference partitioning.
     So that leaves us with dropping and recreating the tables.  This
     allows us an opportunity to repartition anyway.

     The error handling to catch table or view does not exist is totally 
     unneeded; but I copied this from the 2017Q2 directory. */

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

