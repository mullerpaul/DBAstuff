databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "src/main/resources/database/appint/postops/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
//  }

  changeSet (author: "pmuller", id: "grants_to_other_mart_schemas.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/appint/postops/grants_to_other_mart_schemas.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }


}
