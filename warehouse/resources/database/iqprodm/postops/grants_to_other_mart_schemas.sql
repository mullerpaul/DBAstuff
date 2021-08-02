-- I'm currently leaning towards handling intra-schema grants with a simple "dumb" 
-- script with a list of grants.  No loops or anything fancy here.  

-- This script should be either "runAlways", or "runOnChange".

-- This strategy puts the onus on us developers to keep this up to date when we 
-- add new or remove old objects.  I know thats a lot of work thats easy to forget, 
-- and it can break the migration when we do forget!  Hopefully the fact that a mistake
-- makes this script fail bady will make us keep this up-to-date.
-- Thats why there is no error handling here and liquibase will stop if this fails.  


-- Organizing this list by grantee.  If that proves to not be the best way, then re-org!

--grants to OPS schema
GRANT SELECT ON databasechangelog TO ops
/
GRANT SELECT ON databasechangeloglock TO ops
/
GRANT SELECT ON processing_log TO ops
/
GRANT SELECT ON dm_atom_assign_xref TO ops
/
GRANT SELECT ON dm_atom_job_title_cat TO ops
/
GRANT SELECT ON dm_atom_place TO ops
/
GRANT SELECT ON dm_cmsa TO ops
/
GRANT SELECT ON dm_headcount_fact_v TO ops
/
GRANT SELECT ON dm_invoiced_spend_lv TO ops
/
GRANT SELECT ON dm_invoice_fact_v TO ops
/
GRANT SELECT ON dm_rate_event_master TO ops
/
GRANT SELECT ON dm_rate_summary_lv TO ops
/
GRANT SELECT ON dm_supplier_score_card_lv TO ops
/
GRANT SELECT ON dm_buyers TO ops
/
GRANT SELECT ON dm_countries TO ops
/
GRANT SELECT ON dm_cube_jobs TO ops
/
GRANT SELECT ON dm_cube_jobs_log TO ops
/
GRANT SELECT ON dm_cube_objects TO ops
/
GRANT SELECT ON dm_currency_conversion_rates TO ops
/
GRANT SELECT ON dm_currency_dim TO ops
/
GRANT SELECT ON dm_data_source TO ops
/
GRANT SELECT ON dm_date_dim TO ops
/
GRANT SELECT ON dm_date_dim_stag TO ops
/
GRANT SELECT ON dm_date_load_log TO ops
/
GRANT SELECT ON dm_delete_reason_codes TO ops
/
GRANT SELECT ON dm_error_log TO ops
/
GRANT SELECT ON dm_fo_title_map TO ops
/
GRANT SELECT ON dm_fo_title_map_q TO ops
/
GRANT SELECT ON dm_job_category TO ops
/
GRANT SELECT ON dm_job_levels TO ops
/
GRANT SELECT ON dm_job_title_levels TO ops
/
GRANT SELECT ON dm_job_titles TO ops
/
GRANT SELECT ON dm_jobs TO ops
/
GRANT SELECT ON dm_load_log TO ops
/
GRANT SELECT ON dm_msg_log TO ops
/
GRANT SELECT ON dm_occupational_sectors TO ops
/
GRANT SELECT ON dm_organization_dim TO ops
/
GRANT SELECT ON dm_person_dim TO ops
/
GRANT SELECT ON dm_person_tmp TO ops
/
GRANT SELECT ON dm_places TO ops
/
GRANT SELECT ON dm_rate_event_q TO ops
/
GRANT SELECT ON dm_rate_event_r TO ops
/
GRANT SELECT ON dm_rate_event_regular_q TO ops
/
GRANT SELECT ON dm_rate_event_stats TO ops
/
GRANT SELECT ON dm_rate_event_t TO ops
/
GRANT SELECT ON dm_rate_event_wachovia_q TO ops
/
GRANT SELECT ON dm_region_place_map TO ops
/
GRANT SELECT ON dm_region_types TO ops
/
GRANT SELECT ON dm_regions TO ops
/
GRANT SELECT ON dm_sector_region_adjustment TO ops
/
GRANT SELECT ON dm_sector_region_title_weights TO ops
/
GRANT SELECT ON dm_proximity_index TO ops
/
GRANT SELECT ON dm_suppliers TO ops
/
GRANT SELECT ON dm_timecard_rate_events TO ops
/
GRANT SELECT ON dm_timecard_rate_events_q TO ops
/
GRANT SELECT ON dm_timecard_rate_events_t TO ops
/
GRANT SELECT ON dm_title_buyer_weights TO ops
/
GRANT SELECT ON dm_transform_codes TO ops
/
GRANT SELECT ON fo_buyers_map TO ops
/
GRANT SELECT ON fo_suppliers_map TO ops
/
GRANT SELECT ON fo_timecard_rate_events_tmp TO ops
/
GRANT SELECT, INSERT, DELETE ON t_review_benchmarks TO ops  -- INSERT and DELETE to maintain data before loading into iqnlabs_benchmarks table
/
GRANT SELECT, INSERT, UPDATE ON iqnlabs_benchmarks TO ops  -- INSERT for loads, UPDATE to terminate data (via end_date col)
/


--procedures
GRANT DEBUG, EXECUTE ON compile_objects TO ops
/
GRANT DEBUG, EXECUTE ON dim_daily_process TO ops
/
GRANT DEBUG, EXECUTE ON dim_weekly_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_rate_events_proc TO ops
/
GRANT DEBUG, EXECUTE ON dw_saturday_process TO ops
/
GRANT DEBUG, EXECUTE ON hc_fact_daily_process TO ops
/
GRANT DEBUG, EXECUTE ON invoice_fact_daily_process TO ops
/
GRANT DEBUG, EXECUTE ON inv_hc_fact_daily_process TO ops
/
GRANT DEBUG, EXECUTE ON tt_fill_fact_daily_process TO ops
/
GRANT DEBUG, EXECUTE ON upd_cube_dim_load_status TO ops
/

--packages
GRANT DEBUG, EXECUTE ON dm_assignment_dim_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_botimecard_rate_event TO ops
/
GRANT DEBUG, EXECUTE ON dm_buyer_supp_agmt_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_cube_utils TO ops
/
GRANT DEBUG, EXECUTE ON dm_currency_conversion_data TO ops
/
GRANT DEBUG, EXECUTE ON dm_expenditure_dim_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_fotimecard_rate_event TO ops
/
GRANT DEBUG, EXECUTE ON dm_fo_metric_graph TO ops
/
GRANT DEBUG, EXECUTE ON dm_geo TO ops
/
GRANT DEBUG, EXECUTE ON dm_geographic_rate_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_headcount_fact_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_index TO ops
/
GRANT DEBUG, EXECUTE ON dm_job_dim_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_org_dim TO ops
/
GRANT DEBUG, EXECUTE ON dm_person_dim_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_populate_spend_summary TO ops
/
GRANT DEBUG, EXECUTE ON dm_project_agreement_dim_prcs TO ops
/
GRANT DEBUG, EXECUTE ON dm_ratecard_dim_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_rate_event TO ops
/
GRANT DEBUG, EXECUTE ON dm_supp_metrics TO ops
/
GRANT DEBUG, EXECUTE ON dm_tt_fill_fact_process TO ops
/
GRANT DEBUG, EXECUTE ON dm_utils TO ops
/
GRANT DEBUG, EXECUTE ON dm_util_log TO ops
/
GRANT DEBUG, EXECUTE ON dm_worker_dim_process TO ops
/

--grants to WAREHOUSE schema

--grants to OPERATIONALSTORE schema
GRANT SELECT ON dm_atom_assign_xref TO operationalstore
/
GRANT SELECT ON dm_atom_job_title_cat TO operationalstore
/
GRANT SELECT ON dm_atom_place TO operationalstore
/
GRANT SELECT ON dm_currency_conversion_rates TO operationalstore
/
GRANT SELECT ON dm_currency_dim TO operationalstore
/
GRANT SELECT ON dm_buyers TO operationalstore
/

-- grants to READONLY
GRANT SELECT ON databasechangelog TO READONLY
/
GRANT SELECT ON databasechangeloglock TO readonly
/
GRANT SELECT ON processing_log TO READONLY
/
GRANT SELECT ON dm_buyers TO readonly
/
GRANT SELECT ON dm_countries TO readonly
/
GRANT SELECT ON dm_cmsa TO readonly
/
GRANT SELECT ON dm_cube_jobs TO readonly
/
GRANT SELECT ON dm_cube_jobs_log TO readonly
/
GRANT SELECT ON dm_cube_objects TO readonly
/
GRANT SELECT ON dm_currency_conversion_rates TO readonly
/
GRANT SELECT ON dm_currency_dim TO readonly
/
GRANT SELECT ON dm_data_source TO readonly
/
GRANT SELECT ON dm_date_dim TO readonly
/
GRANT SELECT ON dm_date_dim_stag TO readonly
/
GRANT SELECT ON dm_date_load_log TO readonly
/
GRANT SELECT ON dm_delete_reason_codes TO readonly
/
GRANT SELECT ON dm_error_log TO readonly
/
GRANT SELECT ON dm_fo_title_map TO readonly
/
GRANT SELECT ON dm_fo_title_map_q TO readonly
/
GRANT SELECT ON dm_job_category TO readonly
/
GRANT SELECT ON dm_job_levels TO readonly
/
GRANT SELECT ON dm_job_title_levels TO readonly
/
GRANT SELECT ON dm_job_titles TO readonly
/
GRANT SELECT ON dm_jobs TO readonly
/
GRANT SELECT ON dm_load_log TO readonly
/
GRANT SELECT ON dm_msg_log TO readonly
/
GRANT SELECT ON dm_occupational_sectors TO readonly
/
GRANT SELECT ON dm_organization_dim TO readonly
/
GRANT SELECT ON dm_person_dim TO readonly
/
GRANT SELECT ON dm_person_tmp TO readonly
/
GRANT SELECT ON dm_places TO readonly
/
GRANT SELECT ON dm_rate_event_master TO readonly
/
GRANT SELECT ON dm_rate_event_q TO readonly
/
GRANT SELECT ON dm_rate_event_r TO readonly
/
GRANT SELECT ON dm_rate_event_regular_q TO readonly
/
GRANT SELECT ON dm_rate_event_stats TO readonly
/
GRANT SELECT ON dm_rate_event_t TO readonly
/
GRANT SELECT ON dm_rate_event_wachovia_q TO readonly
/
GRANT SELECT ON dm_region_place_map TO readonly
/
GRANT SELECT ON dm_region_types TO readonly
/
GRANT SELECT ON dm_regions TO readonly
/
GRANT SELECT ON dm_sector_region_adjustment TO readonly
/
GRANT SELECT ON dm_sector_region_title_weights TO readonly
/
GRANT SELECT ON dm_proximity_index TO readonly
/
GRANT SELECT ON dm_suppliers TO readonly
/
GRANT SELECT ON dm_timecard_rate_events TO readonly
/
GRANT SELECT ON dm_timecard_rate_events_q TO readonly
/
GRANT SELECT ON dm_timecard_rate_events_t TO readonly
/
GRANT SELECT ON dm_title_buyer_weights TO readonly
/
GRANT SELECT ON dm_transform_codes TO readonly
/
GRANT SELECT ON fo_buyers_map TO readonly
/
GRANT SELECT ON fo_suppliers_map TO readonly
/
GRANT SELECT ON fo_timecard_rate_events_tmp TO readonly
/
GRANT SELECT ON dm_atom_assign_xref TO readonly
/
GRANT SELECT ON dm_atom_job_title_cat TO readonly
/
GRANT SELECT ON dm_atom_place TO readonly
/
GRANT SELECT ON dm_headcount_fact_v TO readonly
/
GRANT SELECT ON dm_invoiced_spend_lv TO readonly
/
GRANT SELECT ON dm_invoice_fact_v TO readonly
/
GRANT SELECT ON dm_rate_summary_lv TO readonly
/
GRANT SELECT ON dm_supplier_score_card_lv TO readonly
/
GRANT SELECT ON iqnlabs_benchmarks TO readonly, ops
/
GRANT SELECT ON t_review_benchmarks TO readonly, ops
/
GRANT SELECT ON dm_std_sub_category TO readonly, ops
/
GRANT SELECT ON dm_std_occupation to readonly, ops
/
GRANT SELECT ON dm_occupation_hierarchy to readonly, ops
/
GRANT SELECT ON dm_job_occupation_hierarchy_v to readonly, ops
/
GRANT SELECT ON dm_occupation_hierarchy_v to readonly, ops
/
GRANT SELECT ON rate_and_ttf_benchmarks to readonly, ops
/
GRANT SELECT ON dm_cmsa_place_xref to readonly, ops
/
GRANT SELECT ON rate_and_ttf_benchmarks_v to readonly, ops
/

GRANT SELECT ON dm_currency_conversion_rates TO finance WITH GRANT OPTION
/
GRANT SELECT ON dm_currency_conversion_rates TO finance_user
/
