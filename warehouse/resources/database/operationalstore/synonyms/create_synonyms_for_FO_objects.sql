--- we will eventually need different sets of synonyms for different sources!!
--- the US prod synonyms will need different names than the EMAE prod synonyms.
--- Perhaps we'll store them in different files?

--- for now, just create "standard name" synonyms which point to US prod (IQP)

CREATE OR REPLACE SYNONYM address FOR iqprod.address@fo_us_production
/
CREATE OR REPLACE SYNONYM asgmt_edition_position_asgmt_x FOR iqprod.asgmt_edition_position_asgmt_x@fo_us_production
/
CREATE OR REPLACE SYNONYM assignment_continuity FOR iqprod.assignment_continuity@fo_us_production
/
CREATE OR REPLACE SYNONYM assignment_edition FOR iqprod.assignment_edition@fo_us_production
/
CREATE OR REPLACE SYNONYM assignment_line_detail FOR iqprod.assignment_line_detail@fo_us_production
/
CREATE OR REPLACE SYNONYM bo_spend_data_by_cat FOR iqprod.bo_spend_data_by_cat@fo_us_production
/
CREATE OR REPLACE SYNONYM bus_org_lineage FOR iqprod.bus_org_lineage@fo_us_production
/
CREATE OR REPLACE SYNONYM business_organization FOR iqprod.business_organization@fo_us_production
/
CREATE OR REPLACE SYNONYM buyer_firm FOR iqprod.buyer_firm@fo_us_production
/
CREATE OR REPLACE SYNONYM candidate FOR iqprod.candidate@fo_us_production
/
CREATE OR REPLACE SYNONYM contract FOR iqprod.contract@fo_us_production
/
CREATE OR REPLACE SYNONYM contract_term FOR iqprod.contract_term@fo_us_production
/
CREATE OR REPLACE SYNONYM contract_version FOR iqprod.contract_version@fo_us_production
/
CREATE OR REPLACE SYNONYM currency_unit FOR iqprod.currency_unit@fo_us_production
/
CREATE OR REPLACE SYNONYM custom_event_reason FOR iqprod.custom_event_reason@fo_us_production
/
CREATE OR REPLACE SYNONYM event_desc_event_reason_x FOR iqprod.event_desc_event_reason_x@fo_us_production
/
CREATE OR REPLACE SYNONYM event_description FOR iqprod.event_description@fo_us_production
/
CREATE OR REPLACE SYNONYM event_reason FOR iqprod.event_reason@fo_us_production
/
CREATE OR REPLACE SYNONYM fee_expense_term FOR iqprod.fee_expense_term@fo_us_production
/
CREATE OR REPLACE SYNONYM firm_role FOR iqprod.firm_role@fo_us_production
/
CREATE OR REPLACE SYNONYM firm_worker FOR iqprod.firm_worker@fo_us_production
/
CREATE OR REPLACE SYNONYM fo_spend_data FOR iqprod.fo_spend_data@fo_us_production
/
CREATE OR REPLACE SYNONYM invoice_line_item FOR iqprod.invoice_line_item@fo_us_production
/
CREATE OR REPLACE SYNONYM iq_firm FOR iqprod.iq_firm@fo_us_production
/
CREATE OR REPLACE SYNONYM job_category FOR iqprod.job_category@fo_us_production
/
CREATE OR REPLACE SYNONYM localizable_text_entry FOR iqprod.localizable_text_entry@fo_us_production
/
CREATE OR REPLACE SYNONYM offer FOR iqprod.offer@fo_us_production
/
CREATE OR REPLACE SYNONYM other_event_reason FOR iqprod.other_event_reason@fo_us_production
/
CREATE OR REPLACE SYNONYM performance_term FOR iqprod.performance_term@fo_us_production
/
CREATE OR REPLACE SYNONYM position_assignment FOR iqprod.position_assignment@fo_us_production
/
CREATE OR REPLACE SYNONYM procurement_wkfl_edition FOR iqprod.procurement_wkfl_edition@fo_us_production
/
CREATE OR REPLACE SYNONYM rate_category_rate FOR iqprod.rate_category_rate@fo_us_production
/
CREATE OR REPLACE SYNONYM rate_set FOR iqprod.rate_set@fo_us_production
/
CREATE OR REPLACE SYNONYM supply_firm FOR iqprod.supply_firm@fo_us_production
/
CREATE OR REPLACE SYNONYM work_order FOR iqprod.work_order@fo_us_production
/
CREATE OR REPLACE SYNONYM work_order_event_description FOR iqprod.work_order_event_description@fo_us_production
/
CREATE OR REPLACE SYNONYM work_order_summary FOR iqprod.work_order_summary@fo_us_production
/
CREATE OR REPLACE SYNONYM work_order_version FOR iqprod.work_order_version@fo_us_production
/
CREATE OR REPLACE SYNONYM worker_continuity FOR iqprod.worker_continuity@fo_us_production
/
CREATE OR REPLACE SYNONYM worker_edition FOR iqprod.worker_edition@fo_us_production
/
--- iqprodr objects
CREATE OR REPLACE SYNONYM java_constant_lookup FOR iqprodr.java_constant_lookup@fo_us_production
/
--- iqprodd objects
CREATE OR REPLACE SYNONYM lego_contact_address FOR iqprodd.lego_contact_address@fo_us_production
/
CREATE OR REPLACE SYNONYM lego_address FOR iqprodd.lego_address@fo_us_production
/


