databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "datanauts", id: "IQN-39365_lego_refresh_job_fill_trend_ins.sql") {
    sqlFile ("path": "IQN-39365_lego_refresh_job_fill_trend_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datanauts", id: "IQN-39675_add_grant_insert.sql") {
    sqlFile ("path": "IQN-39675_add_grant_insert.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  
}

