DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_MATCH_STATS_BY_JOB';
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
     8,
     5,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);


  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS buyer_org_id, 
                                0 AS job_id, 
                                0 AS suppliers_available_to_submit,
                                0 AS suppliers_submitted,
                                0 AS candidates_submitted,
                                0 AS hiring_mgr_interested,
                                0 AS hiring_mgr_declined,
                                0 AS hiring_mgr_not_interested,   
                                0 AS candidates_offered_position,
                                0 AS candidates_failed_screening,
                                0 AS candidates_passed_screening,                                
                                0 AS candidates_declined,
                                0 AS candidates_not_interested,
                                0 AS scheduled_phone_interviews,
                                0 AS scheduled_inperson_interviews,
                                0 AS scheduled_virtual_interviews,
                                0 AS canceled_phone_interviews,
                                0 AS canceled_inperson_interviews,
                                0 AS canceled_virtual_interviews,                                
                                0 AS avg_bill_rate,       
                                0 AS med_bill_rate
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
     8,
     5,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);
     
 COMMIT; 

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS buyer_org_id, 
                                0 AS job_id, 
                                0 AS suppliers_available_to_submit,
                                0 AS suppliers_submitted,
                                0 AS candidates_submitted,
                                0 AS hiring_mgr_interested,
                                0 AS hiring_mgr_declined,
                                0 AS hiring_mgr_not_interested,   
                                0 AS candidates_offered_position,
                                0 AS candidates_failed_screening,
                                0 AS candidates_passed_screening,                                
                                0 AS candidates_declined,
                                0 AS candidates_not_interested,
                                0 AS scheduled_phone_interviews,
                                0 AS scheduled_inperson_interviews,
                                0 AS scheduled_virtual_interviews,
                                0 AS canceled_phone_interviews,
                                0 AS canceled_inperson_interviews,
                                0 AS canceled_virtual_interviews,                                
                                0 AS avg_bill_rate,       
                                0 AS med_bill_rate
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  

END;
/