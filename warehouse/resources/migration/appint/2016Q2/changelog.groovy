databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "create_dashboard_caller_log.sql") {
    sqlFile ("path": "create_dashboard_caller_log.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

}
