DECLARE
  lv_object_name      lego_refresh.object_name%TYPE := 'LEGO_CONVERGENCE_SEARCH';
  lv_refresh_schedule lego_refresh.refresh_schedule%TYPE;
  lv_refresh_time     lego_refresh.refresh_on_or_after_time%TYPE;
  
BEGIN
  /* Get the refresh schedule and time from a related lego in the same environment.
     This way, in envs where we don't run legos, the new lego is also unscheduled; but it
     will be scheduled in envs. with legos running.  */
  BEGIN
    /* This lookup by PK can only return 1 or 0 rows */
    SELECT refresh_schedule, refresh_on_or_after_time
      INTO lv_refresh_schedule, lv_refresh_time
      FROM lego_refresh
     WHERE object_name = 'LEGO_MATCH'
       AND source_name = 'USPROD';

  EXCEPTION
    WHEN no_data_found THEN 
      lv_refresh_schedule := 'DAILY';
      lv_refresh_time     := NULL;
  END;  

  /* Now insert row. */
  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     refresh_on_or_after_time,
     refresh_procedure_name)
  VALUES
    (lv_object_name,
     'USPROD',
     'PROCEDURE ONLY',
     lv_refresh_schedule,
     8,
     4,
     lv_refresh_time, 
     'lego_convergence_search.load_convergence_search');

  COMMIT;
END;
/


