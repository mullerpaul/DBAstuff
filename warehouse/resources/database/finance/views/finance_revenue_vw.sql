CREATE OR REPLACE FORCE VIEW finance_revenue_vw AS
  WITH base_set AS (
  SELECT fr.invoiceable_expenditure_txn_id,
         fr.trans_create_date, 
         fr.trans_last_update_date,
         bo.enterprise_bus_org_id AS buyer_enterprise_bus_org_id,
         bo.enterprise_name AS buyer_enterprise_name,
         fr.buyer_org_id,
         bo.bus_org_name AS buyer_name,      
         fr.supplier_org_id,
         so.bus_org_name AS supplier_name,       
         fr.assignment_continuity_id, 
         CASE WHEN fr.assignment_continuity_id IS NOT NULL THEN fr.assignment_continuity_id            
              WHEN fr.milestone_invoice_id     IS NOT NULL THEN fr.milestone_invoice_id
         END AS work_order_id,               
         fr.expenditure_date, 
         fr.week_ending_date,
         inv.invoice_date, 
         inv.invoice_create_date, 
         inv.approved_date AS invoice_appr_date, 
         fr.invoice_number, 
         fr.spend, 
         fr.currency, 
         CASE WHEN fr.timecard_id          IS NOT NULL THEN 'Time'
              WHEN fr.assignment_bonus_id  IS NOT NULL THEN 'Assignment Bonus'
              WHEN fr.payment_request_id   IS NOT NULL THEN 'Payment Requests'
              WHEN fr.milestone_invoice_id IS NOT NULL THEN 'Milestones'
              ELSE NULL
         END AS expense_category,         
         CASE
           WHEN (fr.timecard_id IS NOT NULL) THEN DECODE (fr.rate_identifier_id, 1, 'ST',
                                                                                 2, 'OT',
                                                                                 3, 'DT',
                                                                                    'CS')
           WHEN (fr.payment_request_id   IS NOT NULL) THEN 'Payment Request'
           WHEN (fr.assignment_bonus_id  IS NOT NULL) THEN 'Assignment Bonus'
           WHEN (fr.milestone_invoice_id IS NOT NULL) THEN 'Milestone'
         ELSE NULL
         END AS expenditure_type,        
         fr.iqn_management_fee, 
         fr.expenditure_approval_date, 
         CASE WHEN (fr.timecard_id IS NOT NULL AND fr.rate_identifier_id = 1) THEN fr.buyer_adjusted_bill_rate END    AS reg_bill_rate,
         CASE WHEN (fr.timecard_id IS NOT NULL AND fr.rate_identifier_id = 1) THEN fr.supplier_reimbursement_rate END AS reg_reimbursement_rate,   
         fr.accounting_code, 
         fr.project_agreement_id, 
         cc.cac_segment_3_value AS classification,                         
         NVL(curcon.conversion_rate,1) AS conversion_rate, 
         ROUND(fr.spend * NVL(curcon.conversion_rate,1),2) AS exch_spend, 
         ROUND(fr.iqn_management_fee * NVL(curcon.conversion_rate,1),2) AS exch_iqn_management_fee
    FROM operationalstore.finance_revenue fr,
         (SELECT foc.buyer_org_id, foc.from_currency, ccr.conversion_rate, ccr.conversion_date 
            FROM operationalstore.finance_org_currency foc,
                 iqprodm.dm_currency_conversion_rates ccr
           WHERE foc.from_currency   = ccr.from_currency_code
             AND foc.to_currency     = ccr.to_currency_code) curcon,
         operationalstore.cac_current_iqp cc,
         operationalstore.bus_org_iqp bo,
         operationalstore.bus_org_iqp so,
         operationalstore.invoice_iqp inv
   WHERE 1=1
     AND fr.buyer_org_id     = curcon.buyer_org_id(+)
     AND fr.currency         = curcon.from_currency(+)           
     AND fr.expenditure_date = curcon.conversion_date(+)
     AND fr.cac1_guid        = cc.cac_guid(+)
     AND fr.buyer_org_id     = bo.bus_org_id
     AND fr.supplier_org_id  = so.bus_org_id
     AND fr.invoice_number   = inv.invoice_number(+) ),
  calc_accrual AS (
  SELECT invoiceable_expenditure_txn_id,
         trans_create_date, 
         trans_last_update_date,
         buyer_enterprise_bus_org_id,
         buyer_enterprise_name,
         buyer_org_id,
         buyer_name,         
         supplier_org_id,
         supplier_name,      
         assignment_continuity_id, 
         work_order_id,
         expenditure_date, 
         week_ending_date,
         invoice_date, 
         invoice_create_date, 
         invoice_appr_date, 
         invoice_number, 
         spend, 
         currency,  
         expense_category,       
         expenditure_type,
         iqn_management_fee, 
         expenditure_approval_date,
         reg_bill_rate,
         reg_reimbursement_rate,
         CASE WHEN reg_bill_rate != 0 THEN ROUND(((reg_bill_rate -  reg_reimbursement_rate)/(reg_bill_rate)) * 100,4) ELSE 0 END fee_pct,
         CASE WHEN invoice_date IS NOT NULL 
                THEN 0 
              ELSE ROUND( exch_spend * (CASE WHEN reg_bill_rate != 0 
                                               THEN ROUND(((reg_bill_rate -  reg_reimbursement_rate)/(reg_bill_rate)) ,4) 
                                                 ELSE 0
                                        END) ,2)
         END accrued_fee,             
         accounting_code, 
         project_agreement_id, 
         classification,
         conversion_rate,
         exch_spend,
         exch_iqn_management_fee
    FROM base_set)  

  SELECT invoiceable_expenditure_txn_id,
         trans_create_date, 
         trans_last_update_date,
         buyer_enterprise_bus_org_id,
         buyer_enterprise_name,
         buyer_org_id,
         buyer_name,         
         supplier_org_id,
         supplier_name,      
         assignment_continuity_id, 
         work_order_id,
         expenditure_date, 
         week_ending_date,
         invoice_date, 
         invoice_create_date, 
         invoice_appr_date, 
         invoice_number, 
         spend, 
         currency,  
         expense_category,       
         expenditure_type,
         iqn_management_fee, 
         expenditure_approval_date,
         reg_bill_rate,
         reg_reimbursement_rate,
         fee_pct,
         accrued_fee,             
         accounting_code, 
         project_agreement_id, 
         classification,
         conversion_rate,
         CASE WHEN accrued_fee = 0 THEN exch_iqn_management_fee ELSE accrued_fee END AS revenue,
         exch_spend,
         exch_iqn_management_fee   
    FROM calc_accrual
/    
         
    