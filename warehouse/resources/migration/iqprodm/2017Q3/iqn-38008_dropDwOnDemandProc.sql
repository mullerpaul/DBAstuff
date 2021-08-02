DECLARE
  le_proc_not_exist EXCEPTION;
  PRAGMA exception_init (le_proc_not_exist, -04043);

BEGIN
  /* packages */
  BEGIN
    EXECUTE IMMEDIATE('drop procedure dw_on_demand_process');
  EXCEPTION WHEN le_proc_not_exist
    THEN NULL;
  END;
END;
/