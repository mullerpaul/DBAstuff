/*******************************************************************************
SCRIPT NAME         lego_payment_request_views.sql 
 
LEGO OBJECT NAME    LEGO_PAYMENT_REQUEST
 
CREATED             1/30/2013
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

08/22/2014 - J.Pullifrone - IQN-18776 - removed invoice_id and added invoiced_amount - Release 12.2.0   

*******************************************************************************/ 
CREATE OR REPLACE FORCE VIEW lego_payment_request_vw 
AS
SELECT lpr.buyer_org_id,
       lpr.supplier_org_id,
       lpr.project_id,
       lpr.project_agreement_id,
       lpr.milestone_invoice_id,
       lpr.milestone_invoice_detail_id,
       lpr.contractor_person_id,
       lpr.timecard_id,
       lpr.milestone_invoice_description,
       lpr.adhoc_payment_type,
       lpr.deliverable_start_date,
       lpr.deliverable_end_date,
       lpr.submitted_date,
       lpr.mi_approved_date,
       lpr.mi_udf_collection_id,
       lpr.mid_udf_collection_id,
       lpr.billable_event_id,
       NVL(be_jcl.constant_description, lpr.billable_event)                       AS billable_event,
       lpr.payment_amount,
       ROUND(lpr.payment_amount * NVL(cc.conversion_rate, 1), 2)                  AS payment_amount_cc,
       lpr.supplier_reimbursement_amount,
       ROUND(lpr.supplier_reimbursement_amount * NVL(cc.conversion_rate, 1), 2)   AS supplier_reimburse_amount_cc,
       lpr.buyer_adjusted_amount,
       ROUND(lpr.buyer_adjusted_amount * NVL(cc.conversion_rate, 1), 2)           AS buyer_adjusted_amount_cc,
       CASE 
         WHEN lpr.invoiced_amount IS NULL THEN NVL(lpr.buyer_adjusted_amount, 0) 
         ELSE 0 
       END                                                                        AS accrual_amount,
       CASE 
         WHEN lpr.invoiced_amount IS NULL 
           THEN NVL(ROUND(lpr.buyer_adjusted_amount * NVL(cc.conversion_rate, 1), 2), 0)  --buyer_adjusted_amount_cc
         ELSE 0 
       END                                                                        AS accrual_amount_cc,
       NVL(lpr.invoiced_amount, 0)                                                AS invoiced_amount,
       NVL(ROUND(lpr.invoiced_amount * NVL(cc.conversion_rate, 1), 2), 0)         AS invoiced_amount_cc, --buyer_adjusted_amount_cc                                                                               
       lpr.management_fee,
       ROUND(lpr.management_fee * NVL(cc.conversion_rate, 1), 2)                  AS management_fee_cc,
       lpr.contracted_fee,
       ROUND(lpr.contracted_fee * NVL(cc.conversion_rate, 1), 2)                  AS contracted_fee_cc,
       lpr.rate_table_rate,
       ROUND(lpr.rate_table_rate * NVL(cc.conversion_rate, 1), 2)                 AS rate_table_rate_cc,
       lpr.rate_table_name,
       lpr.service_name,
       lpr.rate_table_edition_id,
       lpr.project_resource_request,
       lpr.cac1_guid,
       lpr.cac2_guid,
       lpr.cac1_start_date,
       lpr.cac1_end_date,
       lpr.cac2_start_date,
       lpr.cac2_end_date,
       lpr.reject_reason,
       lpr.invoice_comments,
       lpr.payment_request_status_id,
       NVL(status_jcl.constant_description, lpr.payment_request_status)           AS payment_request_status,
       lpr.payment_request_type,
       lpr.currency_id                                AS currency_id,
       lpr.currency                                   AS currency,
       NVL(cc.converted_currency_id, lpr.currency_id) AS to_pr_currency_id,
       NVL(cc.converted_currency_code, lpr.currency)  AS to_pr_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6)           AS conversion_rate
  FROM lego_payment_request lpr,
       lego_currency_conv_rates_vw cc,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'MilestoneStatus'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) status_jcl,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'RELOCATION_ASS'
           AND constant_value IN (1,2)
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) be_jcl
 WHERE lpr.currency_id               = cc.original_currency_id(+) 
   AND lpr.payment_request_status_id = status_jcl.constant_value(+)
   AND lpr.billable_event_id         = be_jcl.constant_value(+)
/


COMMENT ON COLUMN lego_payment_request_vw.buyer_org_id                     IS 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/

COMMENT ON COLUMN lego_payment_request_vw.supplier_org_id                  IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'
/

COMMENT ON COLUMN lego_payment_request_vw.project_id                       IS 'Project ID FK to LEGO_PROJECT_VW'
/

COMMENT ON COLUMN lego_payment_request_vw.project_agreement_id             IS 'Project Agreement ID FK to LEGO_PROJECT_AGREEMENT_VW'
/

COMMENT ON COLUMN lego_payment_request_vw.milestone_invoice_id             IS 'Milestone ID - one for each milestone invoice'
/

COMMENT ON COLUMN lego_payment_request_vw.milestone_invoice_detail_id      IS 'Lowest level of detail - the detail lines for each Milestone ID'
/

COMMENT ON COLUMN lego_payment_request_vw.milestone_invoice_description    IS 'Description for Milestone Payment Requests only'
/

COMMENT ON COLUMN lego_payment_request_vw.adhoc_payment_type               IS 'Payment Type for Ad-hoc Payment Requests only'
/

COMMENT ON COLUMN lego_payment_request_vw.deliverable_start_date           IS 'Milestone Invoice start date'
/

COMMENT ON COLUMN lego_payment_request_vw.deliverable_end_date             IS 'Milestone Invoice end date'
/

COMMENT ON COLUMN lego_payment_request_vw.submitted_date                   IS 'Milestone Invoice create date'
/

COMMENT ON COLUMN lego_payment_request_vw.mi_udf_collection_id             IS 'UDF Collection ID for Milestone Invoice'
/

COMMENT ON COLUMN lego_payment_request_vw.mid_udf_collection_id            IS 'UDF Collection ID for Milestone Invoice Detail'
/

COMMENT ON COLUMN lego_payment_request_vw.currency                         IS 'Currency Description'
/

COMMENT ON COLUMN lego_payment_request_vw.billable_event                   IS 'Is this a billable event?'
/

COMMENT ON COLUMN lego_payment_request_vw.payment_amount                   IS 'Invoice payment amount'
/

COMMENT ON COLUMN lego_payment_request_vw.payment_amount_cc                IS 'Invoice payment amount converted currency'
/

COMMENT ON COLUMN lego_payment_request_vw.supplier_reimbursement_amount    IS 'Invoice payment amount minus the management fee'
/

COMMENT ON COLUMN lego_payment_request_vw.supplier_reimburse_amount_cc     IS 'Invoice payment amount minus the management fee converted currency'
/

COMMENT ON COLUMN lego_payment_request_vw.buyer_adjusted_amount            IS 'Invoice payment amount plus the contracted_fee'
/

COMMENT ON COLUMN lego_payment_request_vw.buyer_adjusted_amount_cc         IS 'Invoice payment amount plus the contracted_fee converted currency'
/

COMMENT ON COLUMN lego_payment_request_vw.accrual_amount                   IS 'Buyer Adjusted Amount before being invoiced'     
/

COMMENT ON COLUMN lego_payment_request_vw.accrual_amount_cc                IS 'Buyer Adjusted Amount before being invoiced converted currency'     
/

COMMENT ON COLUMN lego_payment_request_vw.invoiced_amount                  IS 'Invoiced Amount - buyer_adjusted_amount on lego_invoice_detail'     
/

COMMENT ON COLUMN lego_payment_request_vw.invoiced_amount_cc               IS 'Invoiced Amount - buyer_adjusted_amount on lego_invoice_detail converted currency'     
/

COMMENT ON COLUMN lego_payment_request_vw.management_fee                   IS 'IQN fee on the invoice amount'
/

COMMENT ON COLUMN lego_payment_request_vw.management_fee_cc                IS 'IQN fee on the invoice amount converted currency'
/

COMMENT ON COLUMN lego_payment_request_vw.contracted_fee                   IS 'Contracted fee on the invoice amount'
/

COMMENT ON COLUMN lego_payment_request_vw.contracted_fee_cc                IS 'Contracted fee on the invoice amount converted currency'
/

COMMENT ON COLUMN lego_payment_request_vw.rate_table_rate                  IS 'Rate Table rate'
/

COMMENT ON COLUMN lego_payment_request_vw.rate_table_rate_cc               IS 'Rate Table rate converted currency'
/

COMMENT ON COLUMN lego_payment_request_vw.rate_table_name                  IS 'Rate Table name'
/

COMMENT ON COLUMN lego_payment_request_vw.service_name                     IS 'Service Name for Rate Table Paymenet Requests only'
/

COMMENT ON COLUMN lego_payment_request_vw.rate_table_edition_id            IS 'Rate Table Edition ID for Rate Table Payment Request and Project Timecards/Consultants Payment Request'
/

COMMENT ON COLUMN lego_payment_request_vw.project_resource_request         IS 'Used for Resource Rate Table Payment Request type - concatenation of Phase, Line, Rate Table Name, Position Title, Resource Start/End Date, Currency'
/

COMMENT ON COLUMN lego_payment_request_vw.contractor_person_id             IS 'Person ID of the Contractor - FK on LEGO_PERSON_VW - used for Project Timecards/Consultants Payment Request only'
/

COMMENT ON COLUMN lego_payment_request_vw.timecard_id                      IS 'Timecard ID of the payment request - FK on LEGO_TIMECARD_VW - used for Project Timecards/Consultants Payment Request only'
/

COMMENT ON COLUMN lego_payment_request_vw.cac1_start_date                  IS 'CAC1 start date'
/

COMMENT ON COLUMN lego_payment_request_vw.cac1_end_date                    IS 'CAC1 end date'
/

COMMENT ON COLUMN lego_payment_request_vw.cac2_start_date                  IS 'CAC2 start date'
/

COMMENT ON COLUMN lego_payment_request_vw.cac2_end_date                    IS 'CAC2 end date'
/

COMMENT ON COLUMN lego_payment_request_vw.reject_reason                    IS 'Reasons why the payment request was rejected'
/

COMMENT ON COLUMN lego_payment_request_vw.invoice_comments                 IS 'Milestone Invoice comments'
/

COMMENT ON COLUMN lego_payment_request_vw.payment_request_type             IS 'Payment Request Type: Milestone Payment Request,Ad-Hoc Payment Request,Resource Rate Table Payment Request,Rate Table Payment Request,Project Timecards/Consultants Payment Request'
/

COMMENT ON COLUMN lego_payment_request_vw.to_pr_currency_id                IS 'Payment Request TO currency id'
/

COMMENT ON COLUMN lego_payment_request_vw.to_pr_currency                   IS 'Payment Request TO currency code'
/

COMMENT ON COLUMN lego_payment_request_vw.conversion_rate                  IS 'Currency Conversion Rate'
/


