DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_UPCOMING_ENDS_DETAIL';
  lv_syn_name    lego_refresh.synonym_name%TYPE := REPLACE(lv_object_name, 'LEGO_') || '_IQP';

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
     'lego_dashboard_refresh.load_upcoming_ends_detail');

  COMMIT;

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS assignment_continuity_id, 
                                0 AS bus_org_id, 
                                'abc' AS buyer_org_name, 
                                'abc' AS supplier_org_name, 
                                'abc' AS hiring_manager_name, 
                                SYSDATE AS assignment_start_dt, 
                                SYSDATE AS assignment_end_dt, 
                                'abc' AS job_category, 
                                0 AS days_until_assignment_end
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';

END;
/
