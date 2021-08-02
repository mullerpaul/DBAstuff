databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "IQN-39925_lego_user_roles_ins.sql") {
    sqlFile ("path": "IQN-39925_lego_user_roles_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-39946_lego_msp_user_available_org_ins.sql") {
    sqlFile ("path": "IQN-39946_lego_msp_user_available_org_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-39946_lego_convergence_search_ins.sql") {
    sqlFile ("path": "IQN-39946_lego_convergence_search_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40125_add_match_state_id_col.sql") {
    sqlFile ("path": "IQN-40125_add_match_state_id_col.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40222_drop_unused_lego_tables_syns.sql") {
    sqlFile ("path": "IQN-40222_drop_unused_lego_tables_syns.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40222_drop_unused_lego_views_code.sql") {
    sqlFile ("path": "IQN-40222_drop_unused_lego_views_code.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40225_make_row_sec_legos_sql_toggle.sql") {
    sqlFile ("path": "IQN-40225_make_row_sec_legos_sql_toggle.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40225_drop_row_sec_package") {
    sqlFile ("path": "IQN-40225_drop_row_sec_package.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40327_make_dash_legos_sql_toggle.sql") {
    sqlFile ("path": "IQN-40327_make_dash_legos_sql_toggle.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40327_drop_dash_package.sql") {
    sqlFile ("path": "IQN-40327_drop_dash_package.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40400_add_person_dummy_cols.sql") {
    sqlFile ("path": "IQN-40400_add_person_dummy_cols.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40496_add_convergencesearch_parameters.sql") {
    sqlFile ("path": "IQN-40496_add_convergencesearch_parameters.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

}

