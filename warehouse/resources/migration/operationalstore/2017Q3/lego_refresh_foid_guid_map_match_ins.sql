DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_MATCH_FOID_GUID_MAP';
  
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
     'DAILY',
     8,
     8,
     'NOLOGGING',
     'foid_guid_map_maint.load_match_foid_guid_map');

  COMMIT;
END;
/