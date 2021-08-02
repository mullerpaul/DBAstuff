DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_MNTH_ASGN_CNTSPND_ROWROLL';
  lv_syn_name    lego_refresh.synonym_name%TYPE := 'MNT_ASGN_CNTSPND_ROWRLL_IQP';  --27 max for IOT

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
     4,
--     'NOLOGGING',
     '(login_user_id, month_start, monthly_assignment_count, monthly_invoiced_buyer_spend, ' ||     --IOT info in storage clause
     'CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_user_id, month_start)) ' || 
     'ORGANIZATION INDEX COMPRESS 1 NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name,
     'lego_dashboard_refresh.month_asgn_cnt_spnd_row_rollup');

  COMMIT;

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                  q'{ as SELECT 1 AS login_user_id, SYSDATE AS month_start, 
                                0 AS monthly_assignment_count, 0 AS monthly_invoiced_buyer_spend
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';

END;
/


