/*******************************************************************************
SCRIPT NAME         lego_assignment_payment_request_views.sql 
 
LEGO OBJECT NAME    LEGO_ASSIGN_PAYMENT_REQUEST
 
CREATED             8/8/2013
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

04/15/2014 - J.Pullifrone - IQN-15810 - If state is Rejected, pr_approval_date should be NULL - Release 12.0.3.
04/24/2014 - E.Clark      - IQN-15826 - Removed joins to LEGO_CAC as they will now be joined in Jasper - Release 12.1.0
04/24/2014 - P.Muller     - IQN-16184 - Simplified syntax to remove multiple in-line views - Release 12.1.0
06/19/2014 - J.Pullifrone - IQN-15827 - Adding CAC values and descriptions.  They are now baked into base tables.  Release 12.1.1 
07/16/2014 - J.Pullifrone - IQN-18927 - Removing DECODE for pr_approved_date in view.  Now doing it with CASE in refresh_sql.  Release 12.1.2 
08/22/2014 - J.Pullifrone - IQN-18776 - removed invoice_id - not needed because base table now has invoiced_amount - Release 12.2.0 
*******************************************************************************/ 
CREATE OR REPLACE FORCE VIEW lego_assign_payment_request_vw 
AS
SELECT lapr.buyer_org_id,
       lapr.supplier_org_id,
       lapr.assignment_continuity_id,
       lapr.contractor_person_id,
       lapr.payment_request_invdtl_id,
       lapr.payment_request_id,
       lapr.expenditure_item_date,
       lapr.pr_approved_date,
       lapr.payment_request_date,
       lapr.payment_request_amount                                                   AS payment_request_amt,
       ROUND(lapr.payment_request_amount * NVL(cc.conversion_rate, 1), 2)            AS payment_request_amt_cc,
       lapr.buyer_adjusted_amount                                                    AS buyer_adjusted_amt,
       ROUND(lapr.buyer_adjusted_amount * NVL(cc.conversion_rate, 1), 2)             AS buyer_adjusted_amt_cc,
       CASE 
         WHEN lapr.invoiced_amount IS NULL THEN NVL(lapr.buyer_adjusted_amount, 0) 
         ELSE 0 
       END                                                                           AS accrual_amt,
       CASE 
         WHEN lapr.invoiced_amount IS NULL 
           THEN NVL(ROUND(lapr.buyer_adjusted_amount * NVL(cc.conversion_rate, 1), 2) ,0) -- same calc as buyer_adjusted_amt_cc column
         ELSE 0 
       END                                                                           AS accrual_amt_cc,
       NVL(lapr.invoiced_amount, 0)                                                  AS invoiced_amt,
       NVL(ROUND(lapr.invoiced_amount * NVL(cc.conversion_rate, 1), 2), 0)           AS invoiced_amt_cc,  
       lapr.supplier_reimbursement_amount                                            AS supplier_reimbursement_amt,
       ROUND(lapr.supplier_reimbursement_amount * NVL(cc.conversion_rate, 1), 2)     AS supplier_reimbursement_amt_cc, 
       lapr.hiring_mgr_person_id,
       lapr.payment_type,
       lapr.comments,
       lapr.cac1_guid,
       lapr.cac1_identifier,
       lapr.cac1_start_date,
       lapr.cac1_end_date,       
       lapr.cac1_segment_1_value,
       lapr.cac1_segment_2_value,
       lapr.cac1_segment_3_value,
       lapr.cac1_segment_4_value,
       lapr.cac1_segment_5_value,
       lapr.cac1_segment_1_desc,
       lapr.cac1_segment_2_desc,
       lapr.cac1_segment_3_desc,
       lapr.cac1_segment_4_desc,
       lapr.cac1_segment_5_desc,
       lapr.cac2_segment_1_value,
       lapr.cac2_segment_2_value,
       lapr.cac2_segment_3_value,
       lapr.cac2_segment_4_value,
       lapr.cac2_segment_5_value,
       lapr.cac2_segment_1_desc,
       lapr.cac2_segment_2_desc,
       lapr.cac2_segment_3_desc,
       lapr.cac2_segment_4_desc,
       lapr.cac2_segment_5_desc,
       lapr.cac2_guid,
       lapr.cac2_identifier,
       lapr.cac2_start_date,
       lapr.cac2_end_date,
       lapr.supplier_ref_number,
       lapr.supplier_ref_date,
       lapr.supplier_ref_flag,
       lapr.payment_request_state,
       lapr.create_date,
       lapr.currency_id                                     AS currency_id,
       lapr.currency_code                                   AS currency,
       NVL(cc.converted_currency_id, lapr.currency_id)      AS to_apr_currency_id,
       NVL(cc.converted_currency_code, lapr.currency_code)  AS to_apr_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6)                 AS conversion_rate 
  FROM lego_assign_payment_request lapr,
       lego_currency_conv_rates_vw cc
 WHERE lapr.currency_id = cc.original_currency_id(+)
/

COMMENT ON COLUMN lego_assign_payment_request_vw.buyer_org_id                     IS 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/

COMMENT ON COLUMN lego_assign_payment_request_vw.supplier_org_id                  IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.assignment_continuity_id         IS 'Assignment ID FK to LEGO_ASSIGNMENT_VW'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.contractor_person_id             IS 'Person ID FK to LEGO_PERSON_CONTRACTOR_VW'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.payment_request_id               IS 'Unique ID for Assignment Payment Request'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.payment_request_date             IS 'Date Payment Request was created'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.payment_request_amt              IS 'Payment Request Amount'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.buyer_adjusted_amt               IS 'Payment Request Amount plus contracted fee'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.accrual_amt                      IS 'Buyer Adjusted Amount before being invoiced'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.accrual_amt_cc                   IS 'Buyer Adjusted Amount before being invoiced converted currency'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.invoiced_amt                     IS 'Invoiced Amount - buyer_adjusted_amount on lego_invoice_detail'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.invoiced_amt_cc                  IS 'Invoiced Amount - buyer_adjusted_amount on lego_invoice_detail converted currency'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.supplier_reimbursement_amt       IS 'Payment Request Amount minus the management fee'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.expenditure_item_date            IS 'Date of the expenditure'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.hiring_mgr_person_id             IS 'Person ID for Hiring Mgr FK to LEGO_PERSON_HIRING_MGR_VW'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.payment_type                     IS 'Payment Request Type'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.comments                         IS 'Payment Request Comments'     
/

COMMENT ON COLUMN lego_assign_payment_request_vw.cac1_start_date                  IS 'CAC1 start date'
/

COMMENT ON COLUMN lego_assign_payment_request_vw.cac1_end_date                    IS 'CAC1 end date'
/

COMMENT ON COLUMN lego_assign_payment_request_vw.cac2_start_date                  IS 'CAC2 start date'
/

COMMENT ON COLUMN lego_assign_payment_request_vw.cac2_end_date                    IS 'CAC2 end date'
/

COMMENT ON COLUMN lego_assign_payment_request_vw.supplier_ref_number              IS 'Supplier reference number'
/

COMMENT ON COLUMN lego_assign_payment_request_vw.supplier_ref_date                IS 'Supplier reference date'
/

COMMENT ON COLUMN lego_assign_payment_request_vw.supplier_ref_flag                IS 'Supplier reference flag y/n'
/

COMMENT ON COLUMN lego_assign_payment_request_vw.payment_request_state            IS 'Payment Request State'
/

COMMENT ON COLUMN lego_assign_payment_request_vw.currency                         IS 'Currency Description'
/   
        
         
         

