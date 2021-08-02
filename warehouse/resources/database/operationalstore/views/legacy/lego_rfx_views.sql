CREATE OR REPLACE FORCE VIEW lego_rfx_vw 
AS 
SELECT r.lego_rfx_id,
        r.buyer_org_id,
        r.project_rfx_id,
        r.project_rfx_version_id,
        r.supplier_org_id,
        r.x_division,
        r.x_mgr_person_id,
        r.project_id,
        r.current_phase_id,
        NVL(cp_jcl.constant_description, r.current_phase) AS current_phase,  
        r.x_request_title,
        r.x_project_component_title,
        r.cac_collection1_id,
        r.cac_collection2_id,
        r.udf_collection_id,
        r.x_decision_by_date,
        r.x_estimated_start_date,
        r.x_estimated_end_date,
        r.x_estimated_req_budget, --x_currency
        ROUND(r.x_estimated_req_budget * NVL(cc1.conversion_rate, 1), 2) AS x_estimated_req_budget_cc,
        r.x_invoice_detail,
        r.x_payment_request_options,
        r.x_request_type,
        r.x_responses_due_date,
        r.x_response_evaluator,
        r.x_status,
        r.x_status_id,
        r.x_title,
        r.x_description,
        r.x_approval_workflow,
        r.x_assigned_cams,
        r.evaluation_dtl,
        r.evaluation_rating_avg,
        r.pm_hlist,
        r.po_outline,
        r.response_id,
        r.rej_reason_codes,
        r.resp_bid_type_id,
        NVL(bid_type_jcl.constant_description, r.resp_bid_type) AS resp_bid_type,
        r.resp_billable_event_id,
        NVL(bill_event_jcl.constant_description, r.resp_billable_event) AS resp_billable_event,
        r.resp_billable_resource_cnt,
        r.resp_non_billable_resource_cnt,
        r.resp_deliverable_cost, --resp_currency
        ROUND(r.resp_deliverable_cost * NVL(cc2.conversion_rate, 1), 2) AS resp_deliverable_cost_cc,        
        r.resp_start_date,
        r.resp_end_date,
        r.resp_total_estimated_costs, --resp_currency
        ROUND(r.resp_total_estimated_costs * NVL(cc2.conversion_rate, 1), 2) AS resp_total_estimated_costs_cc,        
        r.resp_expense_costs, --resp_currency
        ROUND(r.resp_expense_costs * NVL(cc2.conversion_rate, 1), 2) AS resp_expense_costs_cc,                
        r.resp_labor_costs, --resp_currency
        ROUND(r.resp_labor_costs * NVL(cc2.conversion_rate, 1), 2)   AS resp_labor_costs_cc,                
        r.resp_resource_comments,
        r.resp_resource_start_date,
        r.resp_resource_end_date,
        r.resp_resource_title,
        r.resp_submission_date,
        r.resp_supp_prj_mgr_person_id,
        r.resp_title,
        r.single_source_supplier,
        r.single_source_reason_cds,
        r.payment_milestone_id,
        r.resp_x_mi_estimated_start_date,
        r.resp_x_mi_estimated_end_date,
        r.resp_x_mi_title,
        r.resp_x_mi_amount,--resp_currency
        ROUND(r.resp_x_mi_amount * NVL(cc2.conversion_rate, 1), 2)   AS resp_x_mi_amount_cc,                
        r.x_selected_suppliers,
        r.x_currency_id,
        r.x_currency,
        r.resp_currency_id,
        r.resp_currency,
        NVL(cc1.converted_currency_id, r.x_currency_id)    AS to_x_currency_id,
        NVL(cc1.converted_currency_code, r.x_currency)     AS to_x_currency,
        ROUND(NVL(cc1.conversion_rate, 1), 6)              AS x_conversion_rate,
        NVL(cc2.converted_currency_id, r.resp_currency_id) AS to_resp_currency_id,
        NVL(cc2.converted_currency_code, r.resp_currency)  AS to_resp_currency,
        ROUND(NVL(cc2.conversion_rate, 1), 6)              AS resp_conversion_rate
  FROM lego_rfx r,
       lego_currency_conv_rates_vw cc1,
       lego_currency_conv_rates_vw cc2,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'PROJECT_RFX_PHASE'
           AND locale_fk = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) cp_jcl,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'RELOCATION_ASS'
           AND constant_value IN (1,2)
           AND locale_fk = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) bill_event_jcl,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'RFxBidType'
           AND locale_fk = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) bid_type_jcl
 WHERE r.x_currency_id          = cc1.original_currency_id(+)
   AND r.resp_currency_id       = cc2.original_currency_id(+)
   AND r.current_phase_id       = cp_jcl.constant_value(+)
   AND r.resp_bid_type_id       = bid_type_jcl.constant_value(+)
   AND r.resp_billable_event_id = bill_event_jcl.constant_value(+)
 ORDER BY lego_rfx_id
/


-----------------------------------

CREATE OR REPLACE FORCE VIEW LEGO_RFX_CAC_VW AS
SELECT lego_rfx_id,
       cac_collection_id,
       cac_id,
       buyer_org_id,
       cac_kind,
       cac_start_date,
       cac_end_date,
       cac_approver_person_id,
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
 SELECT lrc.lego_rfx_id,
       lrc.cac_collection_id,
       lrc.cac_id,
       lrc.buyer_org_id,
       lrc.cac_kind,
       lrc.cac_start_date,
       lrc.cac_end_date,
       lrc.cac_approver_person_id,  
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
 FROM lego_rfx_cac lrc, lego_cac lc
WHERE lrc.cac_guid = lc.cac_guid
  AND lrc.cac_kind = 1
UNION ALL
SELECT lrc.lego_rfx_id,
       lrc.cac_collection_id,
       lrc.cac_id,
       lrc.buyer_org_id,
       lrc.cac_kind,
       lrc.cac_start_date,
       lrc.cac_end_date,
       lrc.cac_approver_person_id,
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
 FROM lego_rfx_cac lrc, lego_cac lc
WHERE lrc.cac_guid = lc.cac_guid
  AND lrc.cac_kind = 2)
/

comment on column LEGO_RFX_CAC_VW.LEGO_RFX_ID is 'This is a artificial Primary Key used for joining with LEGO_RFX_VW'
/

comment on column LEGO_RFX_CAC_VW.BUYER_ORG_ID is 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/

