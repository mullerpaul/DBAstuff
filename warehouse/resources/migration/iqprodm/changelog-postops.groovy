databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "src/main/resources/database/iqprodm/postops/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
//  }

  changeSet (author: "IQIntelligence team", id: "grants_to_other_mart_schemas.sql", runOnChange: true, runAlways: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/postops/grants_to_other_mart_schemas.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }

}



  
  
  