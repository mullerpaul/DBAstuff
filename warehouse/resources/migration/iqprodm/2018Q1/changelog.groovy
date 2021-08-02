databaseChangeLog {

  changeSet (author: "jpullifrone", id: "iqn-39246_dm_currency_dim_seq.sql") {
    sqlFile ("path": "iqn-39246_dm_currency_dim_seq.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "iqn-39246_curr_conv_dim_seq.sql") {
    sqlFile ("path": "iqn-39246_curr_conv_dim_seq.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "iqn-39246_dbms_schedule_saturday_6am.sql") {
    sqlFile ("path": "iqn-39246_dbms_schedule_saturday_6am.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "iqn-39246_dbms_program_curr_rate_process.sql") {
    sqlFile ("path": "iqn-39246_dbms_program_curr_rate_process.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "iqn-39246_dbms_currency_rate_jobs.sql") {
    sqlFile ("path": "iqn-39246_dbms_currency_rate_jobs.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
}
