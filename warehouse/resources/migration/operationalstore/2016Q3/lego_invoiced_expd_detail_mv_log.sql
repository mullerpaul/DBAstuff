/*******************************************************************************
SCRIPT NAME         lego_invoiced_expd_detail_mv_log.sql 
 
BASE OBJECT NAME    LEGO_INVOICED_EXPD_DETAIL
 
CREATED             9/19/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

STORY               IQN-34663

DESCRIPTION         This materialized view log was created to provide for aggregated 
                    views of invoiced spend data that can be accomplished with 
                    FAST REFRESH MVs.
                    
Here are the configurations for the MV:
Use ROWID if no PK is defined on the base table, which it is not.
Specify WITH SEQUENCE if the table is expected to have a mix of inserts/direct-loads, deletes, and updates.  It is not.
The normal and only operation on the base table (LEGO_INVOICED_EXPD_DETAIL) is INSERT INTO.  If an UPDATE or DELETE were
to take place, it would be due to a data issue and would need to be handled with a manual script.  If that happens,
you must then perform a Complete MV Refresh along with whatever manual script is doing an UPDATE or DELETE.  
In other words, UPDATE and DELETE operations will not be picked up during the normal FAST REFRESH of this MV.
You must specify all columns that will be selected from and used as filters in the MV.
You must use INCLUDING NEW VALUES in order to do FAST REFRESH.
If you truncate the MV Log of the base table or drop and recreate, it will force a Complete Refresh.

*******************************************************************************/  

CREATE MATERIALIZED VIEW LOG ON lego_invoiced_expd_detail 
WITH ROWID
(buyer_org_id,
supplier_org_id,
invoice_id,
invoice_header_id,
invoice_detail_id,
invoice_date,
invoice_create_date,
expenditure_item_id,
expenditure_number,
expenditure_date,
week_ending_date,
assignment_continuity_id,
timecard_id,
timecard_entry_id,
assignment_bonus_id,
payment_request_id,
payment_request_invdtl_id,
expense_report_id,
expense_report_line_item_id,
direct_hire_agmt_id,
project_agreement_id,
milestone_invoice_id,
milestone_invoice_detail_id,
candidate_id,
candidate_name,
hiring_mgr_person_id,
hiring_mgr_name,
sar_person_id,
sar_name,
org_sub_classification,
customer_supplier_internal_id,
accounting_code,
buyer_resource_id,
ap_invoice_number,
is_vat_applied_on_fee,
is_vat_applied_on_base,
buyer_fee,
supplier_fee,
flexrate_mgmt_fee_amount,
buyer_fee_calc_percent,
supplier_fee_calc_percent,
flexrate_type,
invoice_transaction_type,
expense_type_name,
payment_type_name,
invalidating_event_desc_id,
reversed_expenditure_txn_id,
invoiceable_mgmt_fee_txn_id,
custom_expenditure_type_id,
custom_expenditure_type_desc,
partial_rate_percent,
flexrate_exp_type_name,
service_id,
service_identifier,
service_exp_type_desc,
service_exp_type_id,
purchase_order,
supplier_reference_num,
debit_credit_indicator,
project_number,
buyer_bus_org_bill_to_addr_id,
buyer_taxable_country_id,
buyer_bus_org_tax_id,
supplier_bus_org_tax_id,
supplier_taxable_country_id,
is_iqn_mgmt_fee_payee,
is_for_backoffice_reversal,
cac1_segment1_value,
cac1_segment2_value,
cac1_segment3_value,
cac1_segment4_value,
cac1_segment5_value,
cac2_segment1_value,
cac2_segment2_value,
cac2_segment3_value,
cac2_segment4_value,
cac2_segment5_value,
cac1_oid,
cac2_oid,
rate_unit_id,
rate_identifier_id,
rate_identifier_name,
base_bill_rate,
base_pay_rate,
buyer_adjusted_bill_rate,
supplier_reimbursement_rate,
flexrate_buyer_rate,
flexrate_supplier_rate,
quantity,
payment_amount,
markup_amount,
bill_amount,
buyer_adjusted_amount,
supplier_reimbursement_amount,
flexrate_buyer_base_amount,
flexrate_buyer_amount,
flexrate_supplier_base_amount,
flexrate_supplier_amount,
flexrate_mgmt_fee_base_amount,
curr_conv_info_id,
currency,
owning_buyer_org_id,
buyer_enterprise_bus_org_id,
source_name,
load_date)
INCLUDING NEW VALUES
/

