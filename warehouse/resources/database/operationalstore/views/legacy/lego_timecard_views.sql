CREATE OR REPLACE FORCE VIEW lego_timecard_vw 
AS
SELECT lt.timecard_entry_id,
       lt.timecard_id, 
       lt.buyer_org_id, 
       lt.supplier_org_id, 
       lt.contractor_person_id, 
       lt.hiring_mgr_person_id,
       lt.candidate_id, 
       lt.wk_date, 
       lt.week_ending_date, 
       lt.timecard_number, 
       lt.timecard_type, 
       lt.cac1_identifier, 
       lt.cac2_identifier, 
       lt.job_id, 
       lt.assignment_continuity_id, 
       lt.assignment_edition_id, 
       lt.timecard_approval_workflow_id, 
       lt.te_udf_collection_id, 
       lt.t_udf_collection_id,
       lt.reg_hours, 
       lt.ot_hours, 
       lt.dt_hours, 
       lt.custom_hours, 
       lt.total_hours_day, 
       lt.total_change_to_hours_day, 
       lt.timecard_state_id, 
       lt.timecard_state, 
       lt.rate_trmt_id, 
       lt.rate_type_desc, 
       lt.hours_per_day, 
       lt.is_break, 
       lt.tc_buyer_approved_date,
       lt.tc_buyer_rejected_date, 
       lt.tc_created_date, 
       lt.tc_saved_date, 
       lt.tc_adjusted_date, 
       lt.tc_rerated_date, 
       lt.tc_approve_req_retract_date, 
       lt.tc_submit_approval_date, 
       lt.tc_archived_date, 
       lt.tc_sar_approved_date, 
       lt.tc_sar_rejected_date, 
       lt.reg_bill_rate,
       ROUND(lt.reg_bill_rate * NVL(cc.conversion_rate, 1), 2)                AS reg_bill_rate_cc,
       lt.ot_bill_rate, 
       ROUND(lt.ot_bill_rate * NVL(cc.conversion_rate, 1), 2)                 AS ot_bill_rate_cc,
       lt.dt_bill_rate, 
       ROUND(lt.dt_bill_rate * NVL(cc.conversion_rate, 1), 2)                 AS dt_bill_rate_cc,
       lt.custom_bill_rate,
       ROUND(lt.custom_bill_rate * NVL(cc.conversion_rate, 1), 2)             AS custom_bill_rate_cc,
       lt.adj_reg_bill_rate, 
       ROUND(lt.adj_reg_bill_rate * NVL(cc.conversion_rate, 1), 2)            AS adj_reg_bill_rate_cc,
       lt.adj_ot_bill_rate, 
       ROUND(lt.adj_ot_bill_rate * NVL(cc.conversion_rate, 1), 2)             AS adj_ot_bill_rate_cc,
       lt.adj_dt_bill_rate, 
       ROUND(lt.adj_dt_bill_rate * NVL(cc.conversion_rate, 1), 2)             AS adj_dt_bill_rate_cc,
       lt.adj_custom_bill_rate, 
       ROUND(lt.adj_custom_bill_rate * NVL(cc.conversion_rate, 1), 2)         AS adj_custom_bill_rate_cc,
       lt.rate_trmt_reg_bill_rate, 
       ROUND(lt.rate_trmt_reg_bill_rate * NVL(cc.conversion_rate, 1), 2)      AS rate_trmt_reg_bill_rate_cc,
       lt.rate_trmt_ot_bill_rate, 
       ROUND(lt.rate_trmt_ot_bill_rate * NVL(cc.conversion_rate, 1), 2)       AS rate_trmt_ot_bill_rate_cc,
       lt.rate_trmt_dt_bill_rate, 
       ROUND(lt.rate_trmt_dt_bill_rate * NVL(cc.conversion_rate, 1), 2)       AS rate_trmt_dt_bill_rate_cc,
       lt.rate_trmt_cust_bill_rate, 
       ROUND(lt.rate_trmt_cust_bill_rate * NVL(cc.conversion_rate, 1), 2)     AS rate_trmt_cust_bill_rate_cc,
       lt.rate_trmt_adj_reg_bill_rate, 
       ROUND(lt.rate_trmt_adj_reg_bill_rate * NVL(cc.conversion_rate, 1), 2)  AS rate_trmt_adj_reg_bill_rate_cc,
       lt.rate_trmt_adj_ot_bill_rate, 
       ROUND(lt.rate_trmt_adj_ot_bill_rate * NVL(cc.conversion_rate, 1), 2)   AS rate_trmt_adj_ot_bill_rate_cc,
       lt.rate_trmt_adj_dt_bill_rate, 
       ROUND(lt.rate_trmt_adj_dt_bill_rate * NVL(cc.conversion_rate, 1), 2)   AS rate_trmt_adj_dt_bill_rate_cc,
       lt.rate_trmt_adj_cust_bill_rate, 
       ROUND(lt.rate_trmt_adj_cust_bill_rate * NVL(cc.conversion_rate, 1), 2) AS rate_trmt_adj_cust_bill_rte_cc,
       lt.contractor_spend, 
       ROUND(lt.contractor_spend * NVL(cc.conversion_rate, 1), 2)             AS contractor_spend_cc,
       lt.cont_spend_amount_adj, 
       ROUND(lt.cont_spend_amount_adj * NVL(cc.conversion_rate, 1), 2)        AS cont_spend_amount_adj_cc,
       CASE 
         WHEN invoiced_amount IS NULL THEN NVL(lt.cont_spend_amount_adj, 0) 
         ELSE 0 
       END                                                                    AS accrual_amount,
       CASE 
         WHEN invoiced_amount IS NULL 
           THEN NVL(ROUND(lt.cont_spend_amount_adj * NVL(cc.conversion_rate, 1), 2), 0)  --cont_spend_amount_adj_cc
         ELSE 0 
       END                                                                    AS accrual_amount_cc,
       NVL(lt.invoiced_amount, 0)                                             AS invoiced_amount,    --buyer_adjusted_amount
       NVL(ROUND(lt.invoiced_amount * NVL(cc.conversion_rate, 1), 2), 0)      AS invoiced_amount_cc, --buyer_adjusted_amount_cc         
       lt.cac1_guid,
       lt.cac2_guid,
       lt.cac1_start_date,
       lt.cac1_end_date,
       lt.cac2_start_date,
       lt.cac2_end_date,
       lt.timecard_currency_id,
       lt.timecard_currency, 
       NVL(cc.converted_currency_id, lt.timecard_currency_id)  AS to_timecard_currency_id,
       NVL(cc.converted_currency_code, lt.timecard_currency)   AS to_timecard_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6)                    AS conversion_rate
  FROM lego_timecard_syn lt,
       lego_currency_conv_rates_vw cc     
 WHERE lt.timecard_currency_id = cc.original_currency_id(+) 
   AND lt.week_ending_date >= ADD_MONTHS(TRUNC(SYSDATE),-(SELECT NVL(MIN(number_value), 24)
                                                            FROM lego_parameter
                                                           WHERE parameter_name = 'months_in_refresh')) 
/


COMMENT ON COLUMN lego_timecard_vw.buyer_org_id                            IS 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/

COMMENT ON COLUMN lego_timecard_vw.supplier_org_id                         IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'
/

COMMENT ON COLUMN lego_timecard_vw.contractor_person_id                    IS 'Contractor ID FK to LEGO_PERSON_CONTRACTOR_VW'
/

COMMENT ON COLUMN lego_timecard_vw.hiring_mgr_person_id                    IS 'Hiring manager ID FK to LEGO_PERSON_HIRING_MGR_VW'
/

COMMENT ON COLUMN lego_timecard_vw.accrual_amount                          IS 'Buyer Adjusted Amount before being invoiced'     
/

COMMENT ON COLUMN lego_timecard_vw.accrual_amount_cc                       IS 'Buyer Adjusted Amount before being invoiced converted currency'     
/

COMMENT ON COLUMN lego_timecard_vw.invoiced_amount                         IS 'Invoiced Amount - buyer_adjusted_amount on lego_invoice_detail'     
/

COMMENT ON COLUMN lego_timecard_vw.invoiced_amount_cc                      IS 'Invoiced Amount - buyer_adjusted_amount on lego_invoice_detail converted currency'     
/
