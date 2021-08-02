DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_REQ_BY_STATUS_DETAIL';
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
     8,
     2,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name,
     'lego_dashboard_refresh.load_req_by_status_detail');

  COMMIT;

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS job_id, 
                                0 AS buyer_org_id,
                                'abc' AS buyer_org_name,
                                'abc' AS hiring_manager_name, 
                                'abc' AS jc_description, 
                                'abc' AS job_state, 
                                0 AS positions_total, 
                                SYSDATE AS job_created_date
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';

END;
/
