DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_MONTHLY_ASSIGNMENT_LIST';
  lv_syn_name    lego_refresh.synonym_name%TYPE := 'MONTHLY_ASSIGNMENT_LIST_IQP';

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
     synonym_name,
     refresh_procedure_name)
  VALUES
    (lv_object_name,
     'USPROD',
     'PROC TOGGLE',
     'TWICE DAILY',
     11,
     2,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name,
     'lego_dashboard_refresh.load_monthly_assignment_list');

  COMMIT;

END;
/
