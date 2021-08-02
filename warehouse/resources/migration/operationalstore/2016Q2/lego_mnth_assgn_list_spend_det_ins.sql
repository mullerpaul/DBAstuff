DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_MNTH_ASSGN_LIST_SPEND_DET';
  lv_syn_name    lego_refresh.synonym_name%TYPE := 'MNTH_ASSGN_LIST_SPEND_DET_IQP';

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
     3,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name,
     'lego_dashboard_refresh.month_assgn_list_spend_detail');

  COMMIT;

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                  q'{ as SELECT 1 AS assignment_continuity_id, 1 AS buyer_org_id, 
                                SYSDATE AS month_start, 0 AS invoiced_spend_per_month
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';

END;
/
