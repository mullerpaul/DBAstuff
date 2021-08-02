CREATE OR REPLACE FORCE VIEW lego_request_to_buy_vw
AS
SELECT r.buyer_org_id,
       r.rtb_id,
       NVL(current_phase.constant_description, r.current_phase_jcl_en_us) AS current_phase,
       r.rtb_edition_id,
       r.rtb_cac_collection1_id,
       r.rtb_cac_collection2_id,
       r.rtb_udf_collection_id,
       r.rtb_start_date,
       r.rtb_end_date,
       r.rtb_miscellaneous_terms,
       r.rtb_project_agreement_id,
       r.rtb_project_number,
       r.rtb_purchase_order,
       r.rtb_active_flag,
       r.rtb_description,
       r.rtb_mgr_id,
       r.rtb_title,
       r.rtb_template,
       r.rtb_status,
       r.rtb_total_budget,
       ROUND(r.rtb_total_budget * NVL(cc.conversion_rate, 1), 2) AS rtb_total_budget_cc,
       r.rtb_currency_id,
       r.rtb_currency_code                                       AS rtb_currency,
       NVL(cc.converted_currency_id, r.rtb_currency_id)          AS to_rtb_currency_id,
       NVL(cc.converted_currency_code, r.rtb_currency_code)      AS to_rtb_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6)                      AS conversion_rate
  FROM lego_request_to_buy r,
       lego_currency_conv_rates_vw cc,
         (SELECT constant_value, constant_description
            FROM lego_java_constant_lookup
           WHERE constant_type    = 'REQUEST_TO_BUY_PHASE'
             AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) current_phase       
 WHERE r.rtb_currency_id  = cc.original_currency_id(+) 
   AND r.current_phase_id = current_phase.constant_value(+)     
/
     
---------------------------

CREATE OR REPLACE FORCE VIEW LEGO_REQUEST_TO_BUY_CAC_VW AS
SELECT lpc.rtb_id,
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
 FROM lego_request_to_buy_cac lpc, lego_cac lc
WHERE lpc.cac_guid = lc.cac_guid
  AND cac_kind = 1
UNION ALL
SELECT lpc.rtb_id,
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
 FROM lego_request_to_buy_cac lpc, lego_cac lc
WHERE lpc.cac_guid = lc.cac_guid
  AND lpc.cac_kind = 2
/



