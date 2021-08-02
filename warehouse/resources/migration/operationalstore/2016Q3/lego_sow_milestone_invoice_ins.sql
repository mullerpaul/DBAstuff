DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_SOW_MILESTONE_INVOICE';
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
     2,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);


  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS buyer_org_id, 
                                0 AS supplier_org_id, 
                                0 AS project_id,
                                0 AS project_agreement_id,
                                0 AS project_agreement_version_id,
                                0 AS milestone_invoice_id,
                                0 AS mi_udf_collection_id,
                                0 AS fixed_payment_milestone_id,   
                                0 AS ad_hoc_payment_type_id,
                                0 AS rate_table_edition_id,
                                0 AS mi_approval_wrkfl_id,
                                SYSDATE AS invoice_date,       
                                SYSDATE AS deliverable_start_date,
                                SYSDATE AS deliverable_end_date,
                                SYSDATE AS submitted_date,
                                SYSDATE AS supplier_submission_date,
                                SYSDATE AS supplier_reference_number,
                                SYSDATE AS supplier_ref_flag,
                                0 AS project_number_id,
                                'abc' AS purchase_order,
                                0 AS milestone_number,
                                'abc' AS milestone_invoice_description,
                                'abc' AS milestone_invoice_comments,
                                0 AS milestone_expenditure_id,
                                0 AS milestone_state_id,
                                'abc' AS res_payment_request_type,
                                0 AS supplier_ref_amt1,
                                0 AS supplier_ref_amt2,
                                0 AS currency_conversion_id,
                                0 AS currency_id,
                                0 AS apply_vat,
                                0 AS is_subject_to_sales_tax,
                                0 AS taxable_place_id,
                                0 AS tax_rule_edition_id,
                                0 AS is_reversed,
                                0 AS reversed_milestone_invoice_id,
                                0 AS is_archived,
                                0 AS is_discount_exempt,
                                0 AS proj_agrmt_place_fk,
                                0 AS vat_override_percentage,
                                'abc' AS sow_spend_category,
                                'abc' AS sow_spend_type
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
     2,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);
     
 COMMIT; 

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS buyer_org_id, 
                                0 AS supplier_org_id, 
                                0 AS project_id,
                                0 AS project_agreement_id,
                                0 AS project_agreement_version_id,
                                0 AS milestone_invoice_id,
                                0 AS mi_udf_collection_id,
                                0 AS fixed_payment_milestone_id,   
                                0 AS ad_hoc_payment_type_id,
                                0 AS rate_table_edition_id,
                                0 AS mi_approval_wrkfl_id,
                                SYSDATE AS invoice_date,       
                                SYSDATE AS deliverable_start_date,
                                SYSDATE AS deliverable_end_date,
                                SYSDATE AS submitted_date,
                                SYSDATE AS supplier_submission_date,
                                SYSDATE AS supplier_reference_number,
                                SYSDATE AS supplier_ref_flag,
                                0 AS project_number_id,
                                'abc' AS purchase_order,
                                0 AS milestone_number,
                                'abc' AS milestone_invoice_description,
                                'abc' AS milestone_invoice_comments,
                                0 AS milestone_expenditure_id,
                                0 AS milestone_state_id,
                                'abc' AS res_payment_request_type,
                                0 AS supplier_ref_amt1,
                                0 AS supplier_ref_amt2,
                                0 AS currency_conversion_id,
                                0 AS currency_id,
                                0 AS apply_vat,
                                0 AS is_subject_to_sales_tax,
                                0 AS taxable_place_id,
                                0 AS tax_rule_edition_id,
                                0 AS is_reversed,
                                0 AS reversed_milestone_invoice_id,
                                0 AS is_archived,
                                0 AS is_discount_exempt,
                                0 AS proj_agrmt_place_fk,
                                0 AS vat_override_percentage,
                                'abc' AS sow_spend_category,
                                'abc' AS sow_spend_type
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  

END;
/