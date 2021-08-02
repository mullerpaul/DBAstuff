/*******************************************************************************
SCRIPT NAME         lego_expense_views.sql 
 
LEGO OBJECT NAME    LEGO_EXPENSE
 
CREATED             1/30/2013
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

08/20/2014 - J.Pullifrone - IQN-18776 - removed invoice_id and added invoiced_amount - Release 12.2.0   

*******************************************************************************/ 
CREATE OR REPLACE FORCE VIEW lego_expense_vw 
AS
SELECT expense_report_line_item_id,
       expense_report_id,
       buyer_org_id,
       supplier_org_id,
       hiring_mgr_person_id,
       contractor_person_id,
       job_id,
       assignment_continuity_id,
       cac1_identifier,
       cac2_identifier,
       creator_person_id,
       candidate_id,
       project_agreement_id,
       approval_workflow_id,
       erli_udf_collection_id,
       er_udf_collection_id,
       expense_report_number,
       expense_status_id,
       expense_status,
       expense_expenditure_date,
       week_ending_date,
       num_units,
       per_unit_amount,
       ROUND(per_unit_amount * NVL(cc.conversion_rate, 1), 2)                    AS per_unit_amount_cc,
       expense_amount,
       ROUND(expense_amount * NVL(cc.conversion_rate, 1), 2)                     AS expense_amount_cc,
       CASE WHEN invoiced_amount IS NULL THEN NVL(expense_amount, 0) ELSE 0 END  AS accrual_amount,
       CASE 
         WHEN invoiced_amount IS NULL THEN NVL(ROUND(expense_amount * NVL(cc.conversion_rate, 1), 2), 0)   -- expense_amount_cc calc
         ELSE 0 
       END                                                                       AS accrual_amount_cc,
       NVL(invoiced_amount, 0)                                                   AS invoiced_amount,
       NVL(ROUND(invoiced_amount * NVL(cc.conversion_rate, 1), 2), 0)            AS invoiced_amount_cc, -- expense_amount_cc calc   
       expense_type,
       expense_purpose,
       expense_justification, 
       er_created_date,
       er_saved_date,
       er_submit_approval_date,
       er_buyer_approved_date,
       er_buyer_rejected_date,
       er_retracted_date,
       er_sar_approved_date,
       er_sar_rejected_date,
       cac1_guid,
       cac2_guid,
       cac1_start_date,
       cac1_end_date,
       cac2_start_date,
       cac2_end_date,
       expense_currency_id,
       expense_currency,
       NVL(cc.converted_currency_id, expense_currency_id) AS to_expense_currency_id,
       NVL(cc.converted_currency_code, expense_currency)  AS to_expense_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6)               AS conversion_rate
  FROM (SELECT le.expense_report_line_item_id,
               le.expense_report_id,
               le.buyer_org_id,
               le.supplier_org_id,
               le.hiring_mgr_person_id,
               le.contractor_person_id,
               le.job_id,
               le.assignment_continuity_id,
               le.cac1_identifier,
               le.cac2_identifier,
               le.cac1_guid,
               le.cac2_guid,
               le.creator_person_id,
               le.candidate_id,
               le.project_agreement_id,
               le.approval_workflow_id,
               le.erli_udf_collection_id,
               le.er_udf_collection_id,
               le.expense_report_number,
               le.expense_status_id,
               le.expense_status,
               le.expense_expenditure_date,
               le.week_ending_date,
               CASE 
                 WHEN le.num_units = le.expense_amount THEN 1
                 ELSE le.num_units
               END AS num_units,
               CASE 
                 WHEN le.num_units = le.expense_amount THEN le.num_units
                 ELSE le.per_unit_amount
               END AS per_unit_amount,
               le.expense_amount,
               le.invoiced_amount,
               le.expense_type,
               le.expense_purpose,
               le.expense_justification,
               le.expense_currency_id,
               le.expense_currency,
               le.er_created_date,
               le.er_saved_date,
               le.er_submit_approval_date,
               le.er_buyer_approved_date,
               le.er_buyer_rejected_date,
               le.er_retracted_date,
               le.er_sar_approved_date,
               le.er_sar_rejected_date,
               le.cac1_start_date,
               le.cac1_end_date,
               le.cac2_start_date,
               le.cac2_end_date
          FROM lego_expense le) e,
       lego_currency_conv_rates_vw cc
 WHERE e.expense_currency_id = cc.original_currency_id(+)
/

