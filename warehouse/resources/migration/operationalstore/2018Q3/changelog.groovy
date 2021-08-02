databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "IQN-40743_create_refresh_dependency_table.sql") {
    sqlFile ("path": "IQN-40743_create_refresh_dependency_table.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40743_load_refresh_dependency_table.sql") {
    sqlFile ("path": "IQN-40743_load_refresh_dependency_table.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40930_add_dummy_domain_column.sql") {
    sqlFile ("path": "IQN-40930_add_dummy_domain_column.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40224_1_rename_lego_refresh_history.sql") {
    sqlFile ("path": "IQN-40224_1_rename_lego_refresh_history.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40224_2_make_lego_refresh_run_history.sql") {
    sqlFile ("path": "IQN-40224_2_make_lego_refresh_run_history.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40224_3_make_new_lego_refresh_history.sql") {
    sqlFile ("path": "IQN-40224_3_make_new_lego_refresh_history.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40224_4_drop_lego_refresh_cols.sql") {
    sqlFile ("path": "IQN-40224_4_drop_lego_refresh_cols.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40224_5_drop_refresh_group_tab.sql") {
    sqlFile ("path": "IQN-40224_5_drop_refresh_group_tab.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40224_6_add_cons_to_refresh_dependency.sql") {
    sqlFile ("path": "IQN-40224_6_add_cons_to_refresh_dependency.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40224_7_drop_scheduler_job.sql") {
    sqlFile ("path": "IQN-40224_7_drop_scheduler_job.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40224_8_make_temporary_scheduler_jobs.sql") {
    sqlFile ("path": "IQN-40224_8_make_temporary_scheduler_jobs.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40224_9_insert_ssc_dependencies.sql") {
    sqlFile ("path": "IQN-40224_9_insert_ssc_dependencies.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40890_insert_conv_search_dependencies.sql") {
    sqlFile ("path": "IQN-40890_insert_conv_search_dependencies.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40890_insert_dependencies.sql") {
    sqlFile ("path": "IQN-40890_insert_dependencies.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40890_delete_obsolete_dependency.sql") {
    sqlFile ("path": "IQN-40890_delete_obsolete_dependency.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-40890_drop_unused_lego_tables_syns.sql") {
    sqlFile ("path": "IQN-40890_drop_unused_lego_tables_syns.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-41371_make_temporary_inv_scheduler_job.sql") {
    sqlFile ("path": "IQN-41371_make_temporary_inv_scheduler_job.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

}

