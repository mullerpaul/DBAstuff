DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_EXPD_DETAIL';
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
     11,
     12,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);


  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS buyer_org_id, 
                                0 AS supplier_org_id, 
                                0 AS invoiceable_expenditure_txn_id,
                                0 AS invoiceable_expenditure_id,
                                0 AS invoiceable_exp_owner_id,
                                0 AS buyer_management_fees_id,
                                0 AS supplier_management_fees_id,
                                0 AS total_management_fees_id,   
                                0 AS candidate_id,
                                0 AS assignment_continuity_id,
								0 AS timecard_id, 
								0 AS timecard_entry_id,
								0 AS time_expenditure_id,
                                0 AS payment_request_id,
								0 AS payment_request_invdtl_id,
                                0 AS assignment_bonus_id,
								0 AS project_agreement_id,
                                0 AS milestone_invoice_id,
								0 AS milestone_invoice_detail_id,                                
                                0 AS expense_report_id,
                                0 AS expense_report_line_item_id,                                                                   
								0 AS rate_unit_id,
                                0 AS rate_identifier_id,								
								'abc' AS expenditure_number,
								0 AS invoice_id,
                                SYSDATE AS expenditure_date,
								SYSDATE AS week_ending_date,								
                                SYSDATE AS ieo_create_date,       
                                SYSDATE AS iet_create_date,
                                SYSDATE AS ieo_submittal_date,
                                SYSDATE AS ieo_last_update_date,
                                SYSDATE AS iet_last_update_date,
                                SYSDATE AS iet_expenditure_approval_date,
                                0 AS quantity,
                                0 AS base_pay_rate,
                                0 AS base_bill_rate,
                                0 AS buyer_adjusted_bill_rate,
                                0 AS supplier_reimbursement_rate,
                                0 AS payment_amount,
                                0 AS bill_amount,
                                0 AS buyer_adjusted_amount,
                                0 AS supplier_reimbursement_amount,
                                0 AS currency_unit_id,
                                'abc' AS accounting_code,
                                0 AS cac1_id,	
                                0 AS cac2_id,		
                                0 AS has_uninvoiced_txns								
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
     11,
     12,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);
     
 COMMIT; 

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS buyer_org_id, 
                                0 AS supplier_org_id, 
                                0 AS invoiceable_expenditure_txn_id,
                                0 AS invoiceable_expenditure_id,
                                0 AS invoiceable_exp_owner_id,
                                0 AS buyer_management_fees_id,
                                0 AS supplier_management_fees_id,
                                0 AS total_management_fees_id,   
                                0 AS candidate_id,
                                0 AS assignment_continuity_id,
								0 AS timecard_id, 
								0 AS timecard_entry_id,
								0 AS time_expenditure_id,
                                0 AS payment_request_id,
								0 AS payment_request_invdtl_id,
                                0 AS assignment_bonus_id,
								0 AS project_agreement_id,
                                0 AS milestone_invoice_id,
								0 AS milestone_invoice_detail_id,                                
                                0 AS expense_report_id,
                                0 AS expense_report_line_item_id,                                                                   
								0 AS rate_unit_id,
                                0 AS rate_identifier_id,								
								'abc' AS expenditure_number,
								0 AS invoice_id,
                                SYSDATE AS expenditure_date,
								SYSDATE AS week_ending_date,								
                                SYSDATE AS ieo_create_date,       
                                SYSDATE AS iet_create_date,
                                SYSDATE AS ieo_submittal_date,
                                SYSDATE AS ieo_last_update_date,
                                SYSDATE AS iet_last_update_date,
                                SYSDATE AS iet_expenditure_approval_date,
                                0 AS quantity,
                                0 AS base_pay_rate,
                                0 AS base_bill_rate,
                                0 AS buyer_adjusted_bill_rate,
                                0 AS supplier_reimbursement_rate,
                                0 AS payment_amount,
                                0 AS bill_amount,
                                0 AS buyer_adjusted_amount,
                                0 AS supplier_reimbursement_amount,
                                0 AS currency_unit_id,
                                'abc' AS accounting_code,
                                0 AS cac1_id,	
                                0 AS cac2_id,		
                                0 AS has_uninvoiced_txns								
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  

END;
/