DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_SOW_MS_INVDET_RATE_TABLES';
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
     20,
     3,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);


  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS milestone_invoice_id,
                                0 AS milestone_invoice_detail_id,
                                0 AS service_id,
                                0 AS fixed_proj_resource_desc_id,
                                0 AS res_rate_table_edition_id,
                                0 AS resource_service_rate_id,
                                'abc' AS resource_detail_type,
                                0 AS timecard_id,
                                0 AS standard_service_rate_id,
                                0 AS distribution_line_number,
                                sysdate AS deliverable_start_date,
                                sysdate AS deliverable_end_date,  
                                0 AS allocation_percentage,  
                                0 AS supplier_reimbursement_amt,
                                0 AS supplier_fee,
                                0 AS buyer_adjusted_amt,
                                0 AS buyer_fee,
                                0 AS negotiable_rate,
                                0 AS quantity,
                                0 AS payment_request_amount,       
                                0 AS cac_one_id,
                                0 AS cac_two_id,      
                                'abc' AS currency
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
     20,
     3,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);
     
 COMMIT; 

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS milestone_invoice_id,
                                0 AS milestone_invoice_detail_id,
                                0 AS service_id,
                                0 AS fixed_proj_resource_desc_id,
                                0 AS res_rate_table_edition_id,
                                0 AS resource_service_rate_id,
                                'abc' AS resource_detail_type,
                                0 AS timecard_id,
                                0 AS standard_service_rate_id,
                                0 AS distribution_line_number,
                                sysdate AS deliverable_start_date,
                                sysdate AS deliverable_end_date,  
                                0 AS allocation_percentage,  
                                0 AS supplier_reimbursement_amt,
                                0 AS supplier_fee,
                                0 AS buyer_adjusted_amt,
                                0 AS buyer_fee,
                                0 AS negotiable_rate,
                                0 AS quantity,
                                0 AS payment_request_amount,       
                                0 AS cac_one_id,
                                0 AS cac_two_id,      
                                'abc' AS currency
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  

END;
/