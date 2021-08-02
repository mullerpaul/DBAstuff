databaseChangeLog() {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "2017Q4/script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

        changeSet (author: "hmajid", id: "update_category_coefficient2.sql") {
                    sqlFile (path: "2018Q2/update_category_coefficient2.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
   changeSet (author: "hmajid", id: "update_metric_coefficient2.sql") {
                    sqlFile (path: "2018Q2/update_metric_coefficient.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
}


