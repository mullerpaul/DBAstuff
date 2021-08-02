DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_FINANCE_REVENUE';
  
BEGIN

  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     storage_clause,
     refresh_procedure_name)
  VALUES
    (lv_object_name,
     'USPROD',
     'PROCEDURE ONLY',
     'EVERY FOUR HOURS',
     22,
     2,
     'NOLOGGING',
     'finance_revenue_maint.main');

  COMMIT;
END;
/