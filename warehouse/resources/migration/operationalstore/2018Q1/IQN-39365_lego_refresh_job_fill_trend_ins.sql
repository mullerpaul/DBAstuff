DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_JOB_FILL_TREND';
  
BEGIN

  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name)
  VALUES
    (lv_object_name,
     'USPROD',
     'SQL TOGGLE',
     'WEEKLY',
     8,
     4,
     'NOLOGGING',
     'JOB_FILL_TREND_IQP1',
     'JOB_FILL_TREND_IQP2',
     'JOB_FILL_TREND_IQP');

  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name)
  VALUES
    (lv_object_name,
     'WFPROD',
     'SQL TOGGLE',
     'WEEKLY',
     8,
     4,
     'NOLOGGING',
     'JOB_FILL_TREND_WF1',
     'JOB_FILL_TREND_WF2',
     'JOB_FILL_TREND_WF');

  COMMIT;
END;
/
