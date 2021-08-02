DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_REQ_BY_STATUS_ORG_ROLLUP';
  lv_syn_name    lego_refresh.synonym_name%TYPE := 'REQ_BY_STATUS_ORG_ROLL_IQP';

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
     3,
     '(login_org_id, current_phase, jc_description, requisition_count, ' ||   --IOT info in storage clause
     'CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_org_id, current_phase, jc_description)) ' || 
     'ORGANIZATION INDEX COMPRESS 1 NOLOGGING',
     lv_syn_name || '1',   --28 chars max for IOT legos
     lv_syn_name || '2',
     lv_syn_name,
     'lego_dashboard_refresh.load_req_by_status_org_rollup');

  COMMIT;

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                  q'{ as SELECT 0 AS login_org_id, 'abd' AS current_phase, 'abc' AS jc_description, 0 AS requisition_count
                           FROM dual WHERE 1=0 }';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';

END;
/
