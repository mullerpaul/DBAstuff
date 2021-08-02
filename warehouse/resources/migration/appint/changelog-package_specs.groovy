databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "src/main/resources/database/api/package-specs/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "dashboard_data_api_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/appint/package-specs/dashboard_data_api_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }


}
