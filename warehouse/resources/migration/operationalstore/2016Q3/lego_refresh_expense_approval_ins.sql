DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_EXPENSE_APPROVAL';
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
     synonym_name)
  VALUES
    (lv_object_name,
     'USPROD',
     'SQL TOGGLE',
     'TWICE DAILY',
     14,
     1,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);


  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS expense_report_id,
                                0 AS approver_person_id,                 
                                SYSDATE AS created_date, 
                                SYSDATE AS saved_date, 
                                SYSDATE AS submit_approval_date, 
                                SYSDATE AS buyer_approved_date, 
                                SYSDATE AS buyer_rejected_date, 
                                SYSDATE AS retracted_date, 
                                SYSDATE AS sar_approved_date, 
                                SYSDATE AS sar_rejected_date                                
                           FROM dual WHERE 1=0}';                           

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';
  
  
  lv_syn_name := REPLACE(lv_object_name, 'LEGO_') || '_WF';
  
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
     'TWICE DAILY',
     14,
     1,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);
     
 COMMIT; 

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS expense_report_id,
                                0 AS approver_person_id,                 
                                SYSDATE AS created_date, 
                                SYSDATE AS saved_date, 
                                SYSDATE AS submit_approval_date, 
                                SYSDATE AS buyer_approved_date, 
                                SYSDATE AS buyer_rejected_date, 
                                SYSDATE AS retracted_date, 
                                SYSDATE AS sar_approved_date, 
                                SYSDATE AS sar_rejected_date                                
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  

END;
/