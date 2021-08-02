databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", "runOnChange": true) {
//    sqlFile ("path": "script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//

  changeSet (author: "jpullifrone", id: "datamart_stop_jobs.sql", "runAlways": true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/preops/datamart_stop_jobs.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  


}
