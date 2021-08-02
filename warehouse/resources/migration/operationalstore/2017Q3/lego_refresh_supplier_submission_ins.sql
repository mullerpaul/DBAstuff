DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_SUPPLIER_SUBMISSION';
  
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
     'WEEKLY',
     8,
     10,
     'NOLOGGING',
     'lego_supplier_scorecard.load_supplier_submission');

  COMMIT;
END;
/