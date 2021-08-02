databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "IQN_41512_widen_source_name_0.sql") {
    sqlFile ("path": "IQN_41512_widen_source_name_0.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN_41512_new_source_1.sql") {
    sqlFile ("path": "IQN_41512_new_source_1.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN_41512_modify_constraint_2.sql") {
    sqlFile ("path": "IQN_41512_modify_constraint_2.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN_41512_ins_auth_lego_metadata_3.sql") {
    sqlFile ("path": "IQN_41512_ins_auth_lego_metadata_3.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN_41512_insert_dependency_4.sql") {
    sqlFile ("path": "IQN_41512_insert_dependency_4.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "mdunlap", id: "IQN-41440_run_dts_by_month.sql") {
    sqlFile ("path": "IQN-41440_run_dts_by_month.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-41616_drop_and_recreate_refresh_jobs.sql") {
    sqlFile ("path": "IQN-41616_drop_and_recreate_refresh_jobs.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-41588_minimal_assignment_ins.sql") {
    sqlFile ("path": "IQN-41588_minimal_assignment_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-41588_change_dependencies.sql") {
    sqlFile ("path": "IQN-41588_change_dependencies.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-41594_modify_conv_search_job") {
    sqlFile ("path": "IQN-41594_modify_conv_search_job.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "IQN-41703_resched_EMEA_job.sql") {
    sqlFile ("path": "IQN-41703_resched_EMEA_job.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

}

