databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "IQIntelligence team", id: "lego_person.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_person.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_managed_cac.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_managed_cac.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_managed_person.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_managed_person.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_assignment_slots.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assignment_slots.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_job_slots.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_slots.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_bus_org.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_bus_org.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_java_constant_lookup.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_java_constant_lookup.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_job_opportunity.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_opportunity.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_job_supplier.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_supplier.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_job_work_location.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_work_location.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_job.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_ratecard.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_ratecard.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_assignment_ea.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assignment_ea.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_assignment_ta.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assignment_ta.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_assignment_wo.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assignment_wo.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_wo_amendment.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_wo_amendment.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_match.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_match.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_expense.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_expense.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_all_orgs_calendar.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_all_orgs_calendar.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_project.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_project.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_project_agreement.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_project_agreement.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_invoice.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_invoice.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_inv_supplier_subset.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_inv_supplier_subset.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_assign_payment_request.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assign_payment_request.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_invcd_expenditure_sum.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_invcd_expenditure_sum.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "lego_interview.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_interview.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_address.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_address.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_contact_address.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_contact_address.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_place.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_place.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_job_position.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_position.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_eval_assignment.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_eval_assignment.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_eval_proj_agreement.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_eval_proj_agreement.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "lego_assignment_cac_map.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assignment_cac_map.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_job_cac_map.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_cac_map.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_job_rates.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_rates.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_sow_milestone_invoice.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_sow_milestone_invoice.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "lego_person_available_org.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_person_available_org.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_timecard_approval.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_timecard_approval.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_expense_approval.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_expense_approval.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "lego_match_stats_by_job.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_match_stats_by_job.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_sow_ms_invdet_fixed_adhoc.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_sow_ms_invdet_fixed_adhoc.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_sow_ms_invdet_rate_tables.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_sow_ms_invdet_rate_tables.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_sow_services_rate_table_rates.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_sow_services_rate_table_rates.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_sow_complex_resource.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_sow_complex_resource.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "pmuller", id: "lego_cac_current.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_cac_current.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_buyer_org_by_ent_part_list.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_buyer_org_by_ent_part_list.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_expd_detail.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_expd_detail.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_position_time_to_fill.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_position_time_to_fill.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "lego_position_history.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_position_history.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_time_to_fill.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_time_to_fill.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "datanauts", id: "lego_job_fill_trend.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_fill_trend.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "pmuller", id: "lego_user_roles.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_user_roles.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_msp_user_available_org.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_msp_user_available_org.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_job_managed_cac.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_managed_cac.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_assign_managed_cac.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assign_managed_cac.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_job_row_security.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_job_row_security.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_assignment_row_security.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assignment_row_security.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_assgn_atom_detail.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assgn_atom_detail.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_assgn_loc_cmsa_atom_or.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assgn_loc_cmsa_atom_or.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_assgn_loc_cmsa_atom_rr.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assgn_loc_cmsa_atom_rr.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_assgn_loc_st_atom_or.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assgn_loc_st_atom_or.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_assgn_loc_st_atom_rr.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_assgn_loc_st_atom_rr.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_mnth_asgn_cntspnd_orgroll.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_mnth_asgn_cntspnd_orgroll.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_mnth_asgn_cntspnd_rowroll.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_mnth_asgn_cntspnd_rowroll.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_mnth_assgn_list_spend_det.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_mnth_assgn_list_spend_det.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_monthly_assignment_list.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_monthly_assignment_list.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_req_by_status_detail.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_req_by_status_detail.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_req_by_status_org_rollup.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_req_by_status_org_rollup.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_req_by_status_row_rollup.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_req_by_status_row_rollup.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_upcoming_ends_detail.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_upcoming_ends_detail.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_upcoming_ends_org_rollup.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_upcoming_ends_org_rollup.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_upcoming_ends_row_rollup.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_upcoming_ends_row_rollup.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_blone_linked_fo_accounts.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_blone_linked_fo_accounts.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_minimal_assignment_ea_ta.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_minimal_assignment_ea_ta.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_minimal_assignment_wo.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/refresh_sql/lego_minimal_assignment_wo.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

}
