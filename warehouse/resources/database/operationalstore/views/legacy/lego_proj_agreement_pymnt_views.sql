CREATE OR REPLACE FORCE VIEW lego_proj_agreement_payment_vw 
AS
SELECT lpap.buyer_org_id, 
       lpap.supplier_org_id, 
       lpap.project_agreement_id, 
       lpap.project_agreement_version_id, 
       lpap.payment_milestone_id, 
       lpap.title,
       lpap.estimated_start_date, 
       lpap.estimated_end_date,
       lpap.allow_multiple_paym_req, 
       lpap.is_billable,
       lpap.phase_number,  
       lpap.phase_description, 
       lpap.expense_type_desc,
       lpap.rate_table_edition_id, 
       lpap.rate_table_name,
       lpap.rate_table_type,
       lpap.rate_table_rate,
       ROUND(lpap.rate_table_rate * NVL(cc.conversion_rate, 1), 2) AS rate_table_rate_cc,
       lpap.adjustable_rate,
       ROUND(lpap.adjustable_rate * NVL(cc.conversion_rate, 1), 2) AS adjustable_rate_cc,
       lpap.resource_phase_desc,
       lpap.resource_phase_number,
       lpap.is_rate_table_res_rate_neg,
       lpap.number_of_resources,
       lpap.shift_label,
       lpap.resource_est_units,
       lpap.payment_amount,
       ROUND(lpap.payment_amount * NVL(cc.conversion_rate, 1), 2) AS payment_amount_cc,
       lpap.supplier_reimbursement_amount,
       ROUND(lpap.supplier_reimbursement_amount * NVL(cc.conversion_rate, 1), 2) AS supplier_reimburse_amount_cc,
       lpap.management_fee,
       ROUND(lpap.management_fee * NVL(cc.conversion_rate, 1), 2) AS management_fee_cc,
       lpap.contracted_fee,
       ROUND(lpap.contracted_fee * NVL(cc.conversion_rate, 1), 2) AS contracted_fee_cc,
       lpap.comments,
       lpap.payment_request_type,
       lpap.currency_id,
       lpap.currency,
       NVL(cc.converted_currency_id, lpap.currency_id) AS to_pap_currency_id,
       NVL(cc.converted_currency_code, lpap.currency)  AS to_pap_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6)            AS conversion_rate   
  FROM lego_proj_agreement_pymnt lpap,
       lego_currency_conv_rates_vw cc
 WHERE lpap.currency_id = cc.original_currency_id(+)
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.buyer_org_id                  IS 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.supplier_org_id               IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.project_agreement_id          IS 'Project Agreement ID FK to LEGO_PROJECT_AGREEMENT_VW'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.project_agreement_version_id  IS 'Project Agreement Version ID FK to LEGO_PROJECT_AGREEMENT_VW'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.payment_milestone_id          IS 'Payment_Milestone ID - for Milestones only - FK to PROJECT_PAYMENT_MILESTONE'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.title                         IS 'Project Payment Milestone or Resource Position title'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.estimated_start_date          IS 'Start Date of Milestone/Resource/Rate Table/Ad-hoc Expense'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.estimated_end_date            IS 'End Date of Milestone/Resource/Rate Table/Ad-hoc Expense'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.allow_multiple_paym_req       IS 'For Payment Milestones only'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.is_billable                   IS 'Is this a billable event?'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.phase_number                  IS 'Phase number for Ad-hoc Expenses'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.phase_description             IS 'Phase Description for Ad-hoc Expenses'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.expense_type_desc             IS 'Type of the Expense'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.rate_table_edition_id         IS 'FK to RATE_TABLE_EDITION'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.rate_table_name               IS 'Name of the Rate Table'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.rate_table_type               IS 'Type of Rate Table'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.rate_table_rate               IS 'Rate Table Rate'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.rate_table_rate_cc            IS 'Rate Table Rate converted currency'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.adjustable_rate               IS 'For Resource Rate Tables - adjustable rate'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.adjustable_rate_cc            IS 'For Resource Rate Tables - adjustable rate converted currency'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.resource_phase_desc           IS 'Resource Rate Table Phase Description'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.resource_phase_number         IS 'Resource Rate Table Phase Number'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.is_rate_table_res_rate_neg    IS 'For Resource Rate Table only'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.number_of_resources           IS 'For Resource Rate Table only'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.shift_label                   IS 'For Resource Rate Table only'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.resource_est_units            IS 'For Resource Rate Table only'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.payment_amount                IS 'Milestone or Ad-hoc amount'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.payment_amount_cc             IS 'Milestone or Ad-hoc amount converted currency'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.supplier_reimbursement_amount IS 'Milestone Supplier Reimbursement Amount'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.supplier_reimburse_amount_cc  IS 'Milestone Supplier Reimbursement Amount converted currency'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.management_fee                IS 'Payment amount minus the management fee'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.management_fee_cc             IS 'Payment amount minus the management fee converted currency'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.contracted_fee                IS 'Payment amount plus the contracted_fee'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.contracted_fee_cc             IS 'Payment amount plus the contracted_fee converted currency'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.comments                      IS 'Payment Comments'
/

COMMENT ON COLUMN lego_proj_agreement_payment_vw.payment_request_type          IS 'Payment Request Type: Milestone Payment Request,Ad-Hoc Payment Request,Resource Rate Table Payment Request,Rate Table Payment Request'
/

