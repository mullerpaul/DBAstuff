databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//


  changeSet (author: "mdunlap", id: "tableau_test_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/dataextract/views/tableau_test_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  
  
  
}
