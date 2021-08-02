databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile (path: "views/script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true") -- remove if you want to keep inline comments  
//  }

// These first two are actually MATERIALIZED views
  changeSet (author: "pmuller", id: "release_submission_beeline_mv.sql", runOnChange: true) {
    sqlFile (path: "views/release_submission_beeline_mv.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "release_submission_iqn_mv.sql", runOnChange: true) {
    sqlFile (path: "views/release_submission_iqn_mv.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "supplier_data_and_exclusions_view.sql", runOnChange: true) {
    sqlFile (path: "views/supplier_data_and_exclusions_view.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
 changeSet (author: "hmajid", id: "create_client_visibility_list_view.sql", runOnChange: true) {
    sqlFile (path: "views/create_client_visibility_list_view.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
}

