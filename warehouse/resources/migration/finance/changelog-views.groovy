databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//

  changeSet (author: "mdunlap", id: "finance_test_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/finance/views/finance_test_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "mdunlap", id: "finance_revenue_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/finance/views/finance_revenue_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
   
}
