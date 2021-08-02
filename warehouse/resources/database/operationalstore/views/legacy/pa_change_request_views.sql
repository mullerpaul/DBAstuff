/*******************************************************************************
SCRIPT NAME         pa_change_request_views.sql 
 
LEGO OBJECT NAME    LEGO_PA_CHANGE_REQUEST
 
CREATED             8/20/2013
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

04/24/2014 - J.Pullifrone - IQN-15402 - added localization of pa_status_desc and deliverable_type_desc - Release 12.1
   
*******************************************************************************/ 
CREATE OR REPLACE FORCE VIEW lego_pa_change_request_vw
AS
SELECT p.buyer_org_id,
       p.supplier_org_id,
       p.pa_project_title      AS project_title,
       p.po_id                 AS project_id,
       p.project_agreement_id,
       p.pa_project_identifier AS project_internal_identifier,
       p.pa_name,
       p.project_agreement_version_id,
       p.cac_collection1_id,
       p.cac_collection2_id,
       p.pa_status,
       NVL(pa_status.constant_description, p.pa_status_desc) AS pa_status_desc,
       p.deliverable_type,
       NVL(deliv_type.constant_description, p.deliverable_type_desc) AS deliverable_type_desc,
       p.pa_description_prev,
       p.pa_description,
       p.pa_description_change,
       p.pa_apprval_status,
       p.pa_approval_workflow_prev,
       p.pa_approval_workflow,
       p.pa_approval_workflow_change,
       p.pa_start_dt_prev      AS pa_start_date_prev,
       p.pa_start_dt           AS pa_start_date,
       p.pa_start_dt_change    AS pa_start_date_change,
       p.pa_end_dt_prev        AS pa_end_date_prev,
       p.pa_end_dt             AS pa_end_date,
       p.pa_end_dt_change      AS pa_end_date_change,
       p.curr_conv_eff_date_prev,
       p.curr_conv_eff_date,
       p.curr_conv_eff_date_change,
       p.pa_project_mgr_person_id,
       p.pa_ttl_estimated_costs_prev,
       ROUND(p.pa_ttl_estimated_costs_prev * NVL(cc.conversion_rate, 1), 2) AS pa_ttl_estimated_costs_prev_cc,
       p.pa_ttl_estimated_costs,
       ROUND(p.pa_ttl_estimated_costs * NVL(cc.conversion_rate, 1), 2) AS pa_ttl_estimated_costs_cc,
       p.pa_ttl_estimated_costs_change,
       p.pa_total_amt_req_todate_prev AS pa_ttl_amt_req_todate_prev,
       ROUND(p.pa_total_amt_req_todate_prev * NVL(cc.conversion_rate, 1), 2) AS pa_ttl_amt_req_todate_prev_cc,
       p.pa_total_amt_req_todate AS pa_ttl_amt_req_todate,
       ROUND(p.pa_total_amt_req_todate * NVL(cc.conversion_rate, 1), 2) AS pa_ttl_amt_req_todate_cc,
       p.pa_total_amt_req_todate_change AS pa_ttl_amt_req_todate_change,
       p.pa_remaining_budget_prev,
       ROUND(p.pa_remaining_budget_prev * NVL(cc.conversion_rate, 1), 2) AS pa_remaining_budget_prev_cc,
       p.pa_remaining_budget,
       ROUND(p.pa_remaining_budget * NVL(cc.conversion_rate, 1), 2) AS pa_remaining_budget_cc,
       p.pa_remaining_budget_change,
       p.pa_paymt_requests_prev,
       p.pa_paymt_requests,
       p.pa_paymt_requests_change,
       p.pa_milestone_title_prev,
       p.pa_milestone_title,
       p.pa_milestone_title_change,
       p.pa_estimated_start_dt_prev,
       p.pa_estimated_start_dt,
       p.pa_estimated_start_dt_change,
       p.pa_estimated_end_dt_prev,
       p.pa_estimated_end_dt,
       p.pa_estimated_end_dt_change,
       p.pa_milestone_comments_prev,
       p.pa_milestone_comments,
       p.pa_milestone_comments_change,
       p.pa_milestone_billable_prev,
       p.pa_milestone_billable,
       p.pa_milestone_billable_change,
       p.pa_milestone_amt_prev,
       ROUND(p.pa_milestone_amt_prev * NVL(cc.conversion_rate, 1), 2) AS pa_milestone_amt_prev_cc,
       p.pa_milestone_amt,
       ROUND(p.pa_milestone_amt * NVL(cc.conversion_rate, 1), 2) AS pa_milestone_amt_cc,
       p.pa_milestone_amt_change,
       p.pa_pr_amount_prev,
       ROUND(p.pa_pr_amount_prev * NVL(cc.conversion_rate, 1), 2) AS pa_pr_amount_prev_cc,
       p.pa_pr_amount,
       ROUND(p.pa_pr_amount * NVL(cc.conversion_rate, 1), 2) AS pa_pr_amount_cc,
       p.pa_pr_amount_change,
       p.milestone_version_id,
       p.pa_version_number,
       p.pa_est_labor_cost_prev,
       ROUND(p.pa_est_labor_cost_prev * NVL(cc.conversion_rate, 1), 2) AS pa_est_labor_cost_prev_cc,
       p.pa_est_labor_cost,
       ROUND(p.pa_est_labor_cost * NVL(cc.conversion_rate, 1), 2) AS pa_est_labor_cost_cc,
       p.pa_est_labor_cost_change,
       p.rate_table_edition_id,
       p.pa_std_rate_table_name,
       p.pa_std_description,
       p.pa_std_rate_table_type,
       p.create_date,
       p.effective_date,
       --p.pa_currency_id_prev,   --we dont have any pa_currency_change = Y, so I am not doing this compare
       p.pa_currency_id,
       --p.pa_currency_id_change, --we dont have any pa_currency_change = Y, so I am not doing this compare 
       --p.pa_currency_prev,      --we dont have any pa_currency_change = Y, so I am not doing this compare
       p.pa_currency, 
       --p.pa_currency_change,    --we dont have any pa_currency_change = Y, so I am not doing this compare
       NVL(cc.converted_currency_id, p.pa_currency_id) AS to_pa_currency_id,
       NVL(cc.converted_currency_code, p.pa_currency)  AS to_pa_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6) AS conversion_rate 
  FROM lego_pa_change_request p,
       lego_currency_conv_rates_vw cc,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'DELIVERABLE_TYPE'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) deliv_type,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'PAVersionState'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) pa_status           
 WHERE p.pa_currency_id    = cc.original_currency_id(+)
   AND p.deliverable_type  = deliv_type.constant_value(+) 
   AND p.pa_status         = pa_status.constant_value(+)      
/


