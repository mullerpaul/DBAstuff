databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "configure_group_2.sql") {
    sqlFile ("path": "configure_group_2.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "insert_lego_org_sec.sql") {
    sqlFile ("path": "insert_lego_org_sec.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "group2_tweaks.sql") {
    sqlFile ("path": "group2_tweaks.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "lego_req_by_status_detail.sql") {
    sqlFile ("path": "lego_req_by_status_detail.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_req_by_status_org_rollup.sql") {
    sqlFile ("path": "lego_req_by_status_org_rollup.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_req_by_status_row_rollup.sql") {
    sqlFile ("path": "lego_req_by_status_row_rollup.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_upcoming_ends_detail.sql") {
    sqlFile ("path": "lego_upcoming_ends_detail.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_upcoming_ends_org_rollup.sql") {
    sqlFile ("path": "lego_upcoming_ends_org_rollup.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_upcoming_ends_row_rollup.sql") {
    sqlFile ("path": "lego_upcoming_ends_row_rollup.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_job_rates_ins.sql") {
    sqlFile ("path": "lego_job_rates_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "lego_monthly_assignment_list_ins.sql") {
    sqlFile ("path": "lego_monthly_assignment_list_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_mnth_assgn_list_spend_det_ins.sql") {
    sqlFile ("path": "lego_mnth_assgn_list_spend_det_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_mnth_assgn_count_spend_org_rollup_ins.sql") {
    sqlFile ("path": "lego_mnth_assgn_count_spend_org_rollup_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_mnth_assgn_count_spend_row_rollup_ins.sql") {
    sqlFile ("path": "lego_mnth_assgn_count_spend_row_rollup_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "insert_lego_assgn_atom_detail.sql") {
    sqlFile ("path": "insert_lego_assgn_atom_detail.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "insert_lego_assgn_by_loc_atom_org_rollup.sql") {
    sqlFile ("path": "insert_lego_assgn_by_loc_atom_org_rollup.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }     
    changeSet (author: "jpullifrone", id: "assgn_loc_cmsa_atom_or.sql") {
    sqlFile ("path": "assgn_loc_cmsa_atom_or.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
    changeSet (author: "jpullifrone", id: "assgn_loc_state_atom_or.sql") {
    sqlFile ("path": "assgn_loc_state_atom_or.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
    changeSet (author: "jpullifrone", id: "lego_refresh_index_upd_assgn_loc.sql") {
    sqlFile ("path": "lego_refresh_index_upd_assgn_loc.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
    changeSet (author: "jpullifrone", id: "assgn_loc_state_atom_rr.sql") {
    sqlFile ("path": "assgn_loc_state_atom_rr.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
    changeSet (author: "jpullifrone", id: "assgn_loc_cmsa_atom_rr.sql") {
    sqlFile ("path": "assgn_loc_cmsa_atom_rr.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
    changeSet (author: "jpullifrone", id: "lego_refresh_iqn32537_cleanup.sql") {
    sqlFile ("path": "lego_refresh_iqn32537_cleanup.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }       
     
}

