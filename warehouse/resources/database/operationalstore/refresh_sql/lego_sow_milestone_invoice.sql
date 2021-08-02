/*******************************************************************************
SCRIPT NAME         lego_sow_milestone_invoice.sql 
 
LEGO OBJECT NAME    LEGO_SOW_MILESTONE_INVOICE
 
CREATED             7/07/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

JIRA STORY          IQN-33328

***************************MODIFICATION HISTORY ********************************
08/08/2016 - jpullifrone  - IQN-33780 - add logic for approvals to get approver_person_id and approved date 
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_sow_milestone_invoice.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_SOW_MILESTONE_INVOICE'; 

  v_clob CLOB :=
q'{ SELECT pa.buyer_org_id                   AS buyer_org_id,
       pa.supplier_org_id                    AS supplier_org_id,
       pa.project_id                         AS project_id,
       pa.project_agreement_id               AS project_agreement_id,
       pa.project_agreement_version_id       AS project_agreement_version_id,
       mi.identifier                         AS milestone_invoice_id,
       mi.udf_collection_fk                  AS mi_udf_collection_id,
       mi.fixed_payment_milestone_fk         AS fixed_payment_milestone_id,       
       mi.ad_hoc_payment_type_fk             AS ad_hoc_payment_type_id,
       mi.rate_table_edition_fk              AS rate_table_edition_id,
       mi.milestn_invc_apprvl_wrkfl_fk       AS mi_approval_wrkfl_id,
       mi.invoice_date                       AS invoice_date,       
       mi.start_date                         AS deliverable_start_date,
       mi.end_date                           AS deliverable_end_date,
       mi.create_date                        AS submitted_date,
       mi.supplier_submission_date           AS supplier_submission_date,
       apprv.approved_date                   AS approved_date,
       apprv.approver_person_id              AS approver_person_id,
       mi.supplier_ref_number                AS supplier_reference_number,
       mi.supplier_ref_flag                  AS supplier_ref_flag,
       mi.project_number_fk                  AS project_number_id,
       mi.purchase_order                     AS purchase_order,
       mi.milestone_number                   AS milestone_number,
       mi.title                              AS milestone_invoice_description,
       mi.comments                           AS milestone_invoice_comments,
       mi.expenditure_fk                     AS milestone_expenditure_id,
       mi.state_code                         AS milestone_state_id,
       mi.res_payment_request_type           AS res_payment_request_type,
       mi.supplier_ref_amt1                  AS supplier_ref_amt1,
       mi.supplier_ref_amt2                  AS supplier_ref_amt2,
       mi.currency_conversion_fk             AS currency_conversion_id,
       mi.currency_fk                        AS currency_id,
       mi.apply_vat                          AS apply_vat,
       mi.is_subject_to_sales_tax            AS is_subject_to_sales_tax,
       mi.taxable_place_fk                   AS taxable_place_id,
       mi.tax_rule_edition_fk                AS tax_rule_edition_id,
       mi.is_reversed                        AS is_reversed,
       mi.reversed_milestone_invoice_fk      AS reversed_milestone_invoice_id,
       mi.is_archived                        AS is_archived,
       mi.is_discount_exempt                 AS is_discount_exempt,
       mi.proj_agrmt_place_fk                AS proj_agrmt_place_fk,
       mi.vat_override_percentage            AS vat_override_percentage,
       CASE
         WHEN fixed_payment_milestone_fk IS NULL THEN 'Services (Time and Materials)'
         ELSE 'Services (Fixed Price)'
       END sow_spend_category,        
       CASE
         WHEN fixed_payment_milestone_fk IS NULL THEN
           CASE
             WHEN res_payment_request_type IS NOT NULL THEN 'Resource Rate Table Payment Requests'
             WHEN (rate_table_edition_fk IS NOT NULL and res_payment_request_type IS NULL) THEN 'Rate Table Payment Requests'
             ELSE 'Ad-hoc Payment Requests'
           END
         ELSE 'Fixed Price Payment Requests'
       END sow_spend_type       
  FROM milestone_invoice@db_link_name AS OF SCN source_db_SCN mi,
       project_agreement_sourceNameShort pa,
       (SELECT milestone_invoice_id, approver_person_id, approved_date
          FROM (SELECT apa.approvable_id AS milestone_invoice_id, fw.never_null_person_fk AS approver_person_id, DECODE(apa.state_code, 3, apa.completed_date, NULL) AS approved_date,
                       RANK() OVER (PARTITION BY apa.approvable_id ORDER BY t.approver_task_id DESC) rk
                  FROM approval_process@db_link_name AS OF SCN source_db_SCN apa, 
                       approver_task@db_link_name    AS OF SCN source_db_SCN t, 
                       firm_worker@db_link_name      AS OF SCN source_db_SCN fw
                 WHERE apa.approval_process_id = t.approval_process_fk
                   AND t.actual_approver_fk    = fw.firm_worker_id
                   AND apa.active_process = 1
                   AND apa.approvable_type_fk = 8) 
         WHERE rk = 1) apprv
 WHERE pa.project_agreement_id = mi.project_agreement_fk
   AND mi.identifier = apprv.milestone_invoice_id(+)}';

BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  UPDATE lego_refresh
     SET refresh_sql = v_clob
   WHERE object_name = v_lego_object_name;  
  
  COMMIT;
    
  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/

