CREATE OR REPLACE FORCE VIEW lego_project_agreement_vw 
AS 
SELECT pa.buyer_org_id,
       pa.supplier_org_id,
       pa.project_agreement_id,
       pa.project_id,
       pa.pa_name,
       pa.project_agreement_version_id,
       pa.org_sub_classification,
       pa.current_phase_id,
       NVL(pa_phase_jcl.constant_description, pa.current_phase) AS current_phase,
       pa.pa_status_id,
       NVL(pa_state_jcl.constant_description, pa.pa_status) AS pa_status,       
       pa.pa_start_date,
       pa.pa_end_date,
       pa.customer_mgr_person_id,
       pa.timecard_approver_person_id,
       pa.org_proj_agmt_mgr_person_id,
       pa.supplier_project_mgr_person_id,
       pa.pa_approver_person_id,
       pa.approval_process_spec_name,
       pa.pa_cac_collection1_id,
       pa.pa_cac_collection2_id,
       pa.source_project_rfx_response_id,
       pa.pa_udf_collection_id,
       pa.pa_assigned_cams,
       pa.total_assignment_cnt,  
       pa.pa_remaining_budget,
       ROUND(pa.pa_remaining_budget * NVL(cc.conversion_rate, 1), 2) AS pa_remaining_budget_cc,
       pa.pa_payment_requests,
       pa.pa_total_amount_req_todate,
       ROUND(pa.pa_total_amount_req_todate * NVL(cc.conversion_rate, 1), 2) AS pa_total_amount_req_todate_cc,
       pa.pa_total_estimated_cost,
       ROUND(pa.pa_total_estimated_cost * NVL(cc.conversion_rate, 1), 2) AS pa_total_estimated_cost_cc,
       pa.pa_total_amount,
       ROUND(pa.pa_total_amount * NVL(cc.conversion_rate, 1), 2) AS pa_total_amount_cc,
       pa.pr_total_budget,
       ROUND(pa.pr_total_budget * NVL(cc.conversion_rate, 1), 2) AS pr_total_budget_cc,
       pa.pr_total_expenditure,
       ROUND(pa.pr_total_expenditure * NVL(cc.conversion_rate, 1), 2) AS pr_total_expenditure_cc,
       pa.pr_remaining_budget,
       ROUND(pa.pr_remaining_budget * NVL(cc.conversion_rate, 1), 2) AS pr_remaining_budget_cc,
       pa.pa_currency_id,
       pa.pa_currency,
       NVL(cc.converted_currency_id, pa.pa_currency_id) AS to_pa_currency_id,
       NVL(cc.converted_currency_code, pa.pa_currency)  AS to_pa_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6)             AS conversion_rate
  FROM lego_project_agreement pa,
       lego_currency_conv_rates_vw cc,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'PAVersionState'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) pa_state_jcl,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'PROJECT_AGREEMENT_PHASE'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) pa_phase_jcl
 WHERE pa.pa_currency_id   = cc.original_currency_id(+)
   AND pa.pa_status_id     = pa_state_jcl.constant_value(+)
   AND pa.current_phase_id = pa_phase_jcl.constant_value(+)
/

---------------------------------------------------------

CREATE OR REPLACE FORCE VIEW LEGO_PROJECT_AGREE_CAC_VW AS
SELECT project_agreement_id,
       cac_collection_id,
       cac_id,
       buyer_org_id,
       cac_kind,
       cac_start_date,
       cac_end_date,
       cac1_segment_1_value,
       cac1_segment_2_value,
       cac1_segment_3_value,
       cac1_segment_4_value,
       cac1_segment_5_value,
       cac1_segment_1_desc,
       cac1_segment_2_desc,
       cac1_segment_3_desc,
       cac1_segment_4_desc,
       cac1_segment_5_desc,
       cac2_segment_1_value,
       cac2_segment_2_value,
       cac2_segment_3_value,
       cac2_segment_4_value,
       cac2_segment_5_value,
       cac2_segment_1_desc,
       cac2_segment_2_desc,
       cac2_segment_3_desc,
       cac2_segment_4_desc,
       cac2_segment_5_desc
FROM (
SELECT lpc.project_agreement_id,
       lpc.cac_collection_id,
       lpc.cac_id,
       lpc.buyer_org_id,
       lpc.cac_kind,
       lpc.cac_start_date,
       lpc.cac_end_date,
       lc.cac_segment_1_value   AS cac1_segment_1_value,
       lc.cac_segment_2_value   AS cac1_segment_2_value,
       lc.cac_segment_3_value   AS cac1_segment_3_value,
       lc.cac_segment_4_value   AS cac1_segment_4_value,
       lc.cac_segment_5_value   AS cac1_segment_5_value,
       lc.cac_segment_1_desc    AS cac1_segment_1_desc,
       lc.cac_segment_2_desc    AS cac1_segment_2_desc,
       lc.cac_segment_3_desc    AS cac1_segment_3_desc,
       lc.cac_segment_4_desc    AS cac1_segment_4_desc,
       lc.cac_segment_5_desc    AS cac1_segment_5_desc,
       NULL                     AS cac2_segment_1_value,
       NULL                     AS cac2_segment_2_value,
       NULL                     AS cac2_segment_3_value,
       NULL                     AS cac2_segment_4_value,
       NULL                     AS cac2_segment_5_value,
       NULL                     AS cac2_segment_1_desc,
       NULL                     AS cac2_segment_2_desc,
       NULL                     AS cac2_segment_3_desc,
       NULL                     AS cac2_segment_4_desc,
       NULL                     AS cac2_segment_5_desc
 FROM lego_pa_cac lpc, lego_cac lc
WHERE lpc.cac_guid = lc.cac_guid
  AND cac_kind = 1
UNION ALL
SELECT lpc.project_agreement_id,
       lpc.cac_collection_id,
       lpc.cac_id,
       lpc.buyer_org_id,
       lpc.cac_kind,
       lpc.cac_start_date,
       lpc.cac_end_date,
       NULL                     AS cac1_segment_1_value,
       NULL                     AS cac1_segment_2_value,
       NULL                     AS cac1_segment_3_value,
       NULL                     AS cac1_segment_4_value,
       NULL                     AS cac1_segment_5_value,
       NULL                     AS cac1_segment_1_desc,
       NULL                     AS cac1_segment_2_desc,
       NULL                     AS cac1_segment_3_desc,
       NULL                     AS cac1_segment_4_desc,
       NULL                     AS cac1_segment_5_desc,
       lc.cac_segment_1_value   AS cac2_segment_1_value,
       lc.cac_segment_2_value   AS cac2_segment_2_value,
       lc.cac_segment_3_value   AS cac2_segment_3_value,
       lc.cac_segment_4_value   AS cac2_segment_4_value,
       lc.cac_segment_5_value   AS cac2_segment_5_value,
       lc.cac_segment_1_desc    AS cac2_segment_1_desc,
       lc.cac_segment_2_desc    AS cac2_segment_2_desc,
       lc.cac_segment_3_desc    AS cac2_segment_3_desc,
       lc.cac_segment_4_desc    AS cac2_segment_4_desc,
       lc.cac_segment_5_desc    AS cac2_segment_5_desc
 FROM lego_pa_cac lpc, lego_cac lc
WHERE lpc.cac_guid = lc.cac_guid
  AND lpc.cac_kind = 2)
/




  
