databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "src/main/resources/database/api/package-bodies/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "dashboard_data_api_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/appint/package-bodies/dashboard_data_api_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }


}
