databaseChangeLog() {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "2017Q4/script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

  changeSet (author: "pmuller", id: "create_client_visibility_list.sql") {
      sqlFile (path: "2017Q4/create_client_visibility_list.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "create_client_visibility_list_gtt.sql") {
      sqlFile (path: "2017Q4/create_client_visibility_list_gtt.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "add_new_col_to_load_hist.sql") {
      sqlFile (path: "2017Q4/add_new_col_to_load_hist.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "one_time_legacy_beeline_visibility_data_load.sql") {
      sqlFile (path: "2017Q4/one_time_legacy_beeline_visibility_data_load.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "msvc-1622_script1.sql") {
      sqlFile (path: "2017Q4/msvc-1622_script1.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "msvc-1622_script2.sql") {
      sqlFile (path: "2017Q4/msvc-1622_script2.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "copy_defaults_to_intermediate_level_orgs.sql") {
      sqlFile (path: "2017Q4/copy_defaults_to_intermediate_level_orgs.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "jcutiongco", id: "msvc-2014-create_table_supplier_release_duplicates.sql") {
      sqlFile (path: "2017Q4/msvc-2014-create_table_supplier_release_duplicates.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  
}

