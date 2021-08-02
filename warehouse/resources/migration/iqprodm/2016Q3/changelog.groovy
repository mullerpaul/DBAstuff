databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "create_benchmark_table.sql") {
    sqlFile ("path": "create_benchmark_table.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

  changeSet (author: "jpullifrone", id: "skip_steps_2345_in_dm_chain_daily_v2.sql") {
    sqlFile ("path": "skip_steps_2345_in_dm_chain_daily.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez and pmuller", id: "update_std_job_titles_IQN-33453.sql") {
    sqlFile ("path": "update_std_job_titles_IQN-33453.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "create_benchmark_table_index.sql") {
    sqlFile ("path": "create_benchmark_table_index.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "dm_buyer_invd_assign_spnd_mon_iqn-33877.sql") {
    sqlFile ("path": "dm_buyer_invd_assign_spnd_mon_iqn-33877.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "dm_buyer_invd_assign_spnd_mon_drop_iqn-34784.sql") {
    sqlFile ("path": "dm_buyer_invd_assign_spnd_mon_drop_iqn-34784.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }      
  changeSet (author: "jpullifrone", id: "retire_dm_spend_code_iqn-34165.sql") {
    sqlFile ("path": "retire_dm_spend_code_iqn-34165.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  
  
  
}

