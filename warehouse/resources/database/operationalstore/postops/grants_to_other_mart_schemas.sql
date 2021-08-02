-- I'm currently leaning towards handling intra-schema grants with a simple "dumb" 
-- script with a list of grants.  No loops or anything fancy here.  

-- This script should be either "runAlways", or "runOnChange".

-- This strategy puts the onus on us developers to keep this up to date when we 
-- add new or remove old objects.  I know thats a lot of work thats easy to forget, 
-- and it can break the migration when we do forget!  Hopefully the fact that a mistake
-- makes this script fail bady will make us keep this up-to-date.
-- Thats why there is no error handling here and liquibase will stop if this fails.  


-- Organizing this list by grantee.  If that proves to not be the best way, then re-org!

--grants to APPINT schema
GRANT SELECT ON lego_upcoming_ends_org_roll_vw TO appint
/
GRANT SELECT ON lego_upcoming_ends_row_roll_vw TO appint
/
---
GRANT SELECT ON lego_req_by_status_org_roll_vw TO appint
/
GRANT SELECT ON lego_req_by_status_row_roll_vw TO appint
/
---
GRANT SELECT ON lego_mnthasgncntspnd_orgrll_vw TO appint
/
GRANT SELECT ON lego_mnthasgncntspnd_rowrll_vw TO appint
/
---
GRANT SELECT ON assgn_loc_cmsa_atom_orgroll_vw TO appint
/
GRANT SELECT ON assgn_loc_st_atom_orgroll_vw TO appint
/
GRANT SELECT ON assgn_loc_st_atom_rowroll_vw TO appint
/
GRANT SELECT ON assgn_loc_cmsa_atom_rowroll_vw TO appint
/
--
GRANT SELECT ON lego_refresh_history TO appint
/
GRANT SELECT ON lego_refresh_run_history TO appint
/

--grants to OPS schema
GRANT SELECT ON databasechangelog TO ops
/
GRANT SELECT ON databasechangeloglock TO ops
/

GRANT SELECT, UPDATE ON lego_parameter TO ops
/
GRANT SELECT, UPDATE ON lego_refresh TO ops
/
GRANT SELECT ON lego_refresh_run_history TO ops
/
GRANT SELECT, UPDATE ON lego_refresh_history TO ops
/
GRANT SELECT ON lego_refresh_dependency TO ops
/
GRANT SELECT, UPDATE, DELETE, INSERT ON lego_refresh_index TO ops
/
GRANT SELECT, UPDATE ON lego_source TO ops
/
GRANT SELECT ON finance_org_currency TO ops
/
GRANT SELECT ON finance_revenue TO ops
/
GRANT SELECT, UPDATE, DELETE, INSERT ON finance_load_tracker TO ops
/
GRANT SELECT, UPDATE, DELETE, INSERT ON lego_invoice_approved TO ops
/
GRANT SELECT, UPDATE, DELETE, INSERT ON lego_object TO ops
/
GRANT SELECT ON lego_timecard_extr_tracker TO ops
/
GRANT SELECT ON lego_timecard_event TO ops
/
GRANT SELECT ON lego_timecard_entry TO ops
/
GRANT SELECT ON lego_buyers_by_ent_inv_gtt TO ops
/
GRANT SELECT ON lego_part_by_enterprise_gtt TO ops
/
GRANT SELECT ON lego_part_by_ent_buyer_org_gtt TO ops
/
GRANT SELECT ON lego_invoiced_expd_detail TO ops
/
GRANT SELECT ON lego_invd_expd_date_ru TO ops
/
GRANT SELECT ON buyer_invd_assign_spnd_mon_mv TO ops
/
GRANT SELECT ON processing_log TO ops
/
GRANT SELECT ON job_foid_guid_map TO ops
/
GRANT SELECT ON job_opp_foid_guid_map TO ops
/
GRANT SELECT ON match_foid_guid_map TO ops
/
GRANT SELECT on dts_by_month to ops
/

GRANT SELECT ON assgn_loc_cmsa_atom_orgroll_vw TO ops
/
GRANT SELECT ON assgn_loc_cmsa_atom_rowroll_vw TO ops
/
GRANT SELECT ON assgn_loc_st_atom_orgroll_vw TO ops
/
GRANT SELECT ON assgn_loc_st_atom_rowroll_vw TO ops
/
GRANT SELECT ON lego_mnthasgncntspnd_orgrll_vw TO ops
/
GRANT SELECT ON lego_mnthasgncntspnd_rowrll_vw TO ops
/
GRANT SELECT ON lego_req_by_status_org_roll_vw TO ops
/
GRANT SELECT ON lego_req_by_status_row_roll_vw TO ops
/
GRANT SELECT ON lego_upcoming_ends_org_roll_vw TO ops
/
GRANT SELECT ON lego_upcoming_ends_row_roll_vw TO ops
/
GRANT SELECT ON address_vw TO ops
/
GRANT SELECT on lego_all_assignment_types_vw to ops
/
GRANT SELECT on lego_assign_24_mo_trend_vw to ops
/
GRANT SELECT on lego_assign_month_trend_vw to ops
/
GRANT SELECT on sf_candidate_vw to ops
/
GRANT SELECT on invoiced_expd_date_ru_vw to ops, ssis_user
/
GRANT SELECT on all_assign_types_vw to ops, ssis_user
/
GRANT SELECT on job_vw to ops, ssis_user
/

-- packages
GRANT DEBUG, EXECUTE ON lego_refresh_mgr_pkg TO ops
/
GRANT DEBUG, EXECUTE ON lego_supplier_scorecard TO ops
/
GRANT DEBUG, EXECUTE ON lego_tools TO ops
/
GRANT DEBUG, EXECUTE ON lego_validate TO ops
/
GRANT DEBUG, EXECUTE ON logger_pkg TO ops
/
GRANT DEBUG, EXECUTE ON lego_invoice TO ops
/
GRANT DEBUG, EXECUTE ON finance_revenue_maint TO ops
/
GRANT DEBUG, EXECUTE ON lego_date_trend to ops
/
GRANT DEBUG, EXECUTE ON lego_refresh_supp_scorecard TO ops
/
GRANT EXECUTE ON lego_refresh_supp_scorecard TO supplier_scorecard, supplier_scorecard_user
/
GRANT DEBUG, EXECUTE ON lego_refresh_conv_search TO ops
/
GRANT EXECUTE ON lego_refresh_conv_search TO convergence_search, convergence_search_user
/
GRANT DEBUG, EXECUTE ON lego_refresh_dashboards TO ops
/
GRANT EXECUTE ON lego_refresh_dashboards TO appint, appint_user
/
GRANT DEBUG, EXECUTE ON lego_refresh_smartview TO ops
/
--GRANT EXECUTE ON lego_refresh_smartview TO ????  What user would this be? 
--/
GRANT DEBUG, EXECUTE ON lego_refresh_invoice_data TO ops
/
--GRANT EXECUTE ON lego_refresh_invoice_data TO ????  What user would this be? 
--/

-- types
GRANT EXECUTE ON lego_group_list_type TO ops
/

--grants to WAREHOUSE schema

-- grants to IQPRODM schema
GRANT SELECT ON lego_invoiced_expd_detail TO iqprodm
/
GRANT SELECT ON lego_invd_expd_date_ru TO iqprodm WITH GRANT OPTION
/

-- grants to READONLY schema
GRANT SELECT ON databasechangelog TO readonly
/
GRANT SELECT ON databasechangeloglock TO readonly
/
GRANT SELECT ON lego_parameter TO readonly
/
GRANT SELECT ON lego_refresh TO readonly
/
GRANT SELECT ON lego_refresh_dependency TO readonly
/
GRANT SELECT ON lego_refresh_run_history TO readonly
/
GRANT SELECT ON lego_refresh_history TO readonly
/
GRANT SELECT ON lego_refresh_index TO readonly
/
GRANT SELECT ON lego_source TO readonly
/
GRANT SELECT ON processing_log TO readonly
/
GRANT SELECT ON lego_timecard_extr_tracker TO readonly
/
GRANT SELECT ON lego_timecard_event TO readonly
/
GRANT SELECT ON lego_timecard_entry TO readonly
/
GRANT SELECT ON lego_invoice_approved TO readonly
/
GRANT SELECT ON lego_object TO readonly
/
GRANT SELECT ON lego_invoiced_expd_detail TO readonly
/
GRANT SELECT ON lego_invd_expd_date_ru TO readonly
/
GRANT SELECT ON finance_org_currency TO readonly
/
GRANT SELECT ON finance_revenue TO readonly
/
GRANT SELECT ON finance_load_tracker TO readonly
/
GRANT SELECT ON job_foid_guid_map TO readonly
/
GRANT SELECT ON job_opp_foid_guid_map TO readonly
/
GRANT SELECT ON match_foid_guid_map TO readonly
/
GRANT SELECT ON assgn_loc_cmsa_atom_orgroll_vw TO readonly
/
GRANT SELECT ON assgn_loc_cmsa_atom_rowroll_vw TO readonly
/
GRANT SELECT ON assgn_loc_st_atom_orgroll_vw TO readonly
/
GRANT SELECT ON assgn_loc_st_atom_rowroll_vw TO readonly
/
GRANT SELECT ON lego_mnthasgncntspnd_orgrll_vw TO readonly
/
GRANT SELECT ON lego_mnthasgncntspnd_rowrll_vw TO readonly
/
GRANT SELECT ON lego_req_by_status_org_roll_vw TO readonly
/
GRANT SELECT ON lego_req_by_status_row_roll_vw TO readonly
/
GRANT SELECT ON lego_upcoming_ends_org_roll_vw TO readonly
/
GRANT SELECT ON lego_upcoming_ends_row_roll_vw TO readonly
/
GRANT SELECT ON buyer_invd_assign_spnd_mon_mv TO readonly
/
GRANT SELECT ON address_vw TO readonly
/
GRANT SELECT ON finance_org_currency TO finance WITH GRANT OPTION
/
GRANT SELECT ON finance_revenue TO finance WITH GRANT OPTION
/
GRANT SELECT ON finance_org_currency TO finance_user
/
GRANT SELECT ON finance_revenue TO finance_user
/
GRANT SELECT on dts_by_month to readonly
/
GRANT EXECUTE on lego_date_trend to  readonly
/
GRANT SELECT on lego_all_assignment_types_vw to readonly
/
GRANT SELECT on lego_assign_24_mo_trend_vw to readonly
/
GRANT SELECT on lego_assign_month_trend_vw to readonly
/
GRANT SELECT on sf_candidate_vw to readonly
/
GRANT SELECT ON invoiced_expd_date_ru_vw to readonly
/
-- grants to Finance

GRANT SELECT on dts_by_month to finance
/
GRANT EXECUTE on lego_date_trend to  finance
/
GRANT SELECT on lego_all_assignment_types_vw to finance
/
GRANT SELECT on lego_assign_24_mo_trend_vw to finance
/
GRANT SELECT on lego_assign_month_trend_vw to  finance
/
GRANT SELECT on sf_candidate_vw to  finance
/
GRANT SELECT ON invoiced_expd_date_ru_vw to finance
/

-- grants to Finance_user 

GRANT SELECT on dts_by_month to finance_user 
/
GRANT EXECUTE on lego_date_trend to  finance_user
/
GRANT SELECT on lego_all_assignment_types_vw  to finance_user
/
GRANT SELECT on lego_assign_24_mo_trend_vw to finance_user
/
GRANT SELECT on lego_assign_month_trend_vw to  finance_user
/
GRANT SELECT on sf_candidate_vw to  finance_user
/
GRANT SELECT ON invoiced_expd_date_ru_vw to finance_user
/
-- grants to appint_user
GRANT EXECUTE ON mask_person TO appint_user
/