databaseChangeLog() {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "2018Q3/script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

  changeSet (author: "pmuller", id: "msvc-3864_truncate_duplicates_table.sql") {
    sqlFile (path: "2018Q3/msvc-3864_truncate_duplicates_table.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }

  changeSet (author: "bpogrebitskiy", id: "msvc-3923_round_metrics.sql") {
    sqlFile (path: "2018Q3/msvc-3923_round_metrics.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
   changeSet (author: "hmajid", id: "supplier_name_mv.sql") {
      sqlFile (path: "2018Q3/supplier_name_mv.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
    changeSet (author: "hmajid", id: "metric_data_mv.sql") {
        sqlFile (path: "2018Q3/metric_data_mv.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
 } 
    
   changeSet (author: "hmajid", id: "create_index_client_tables_2.sql") {
            sqlFile (path: "2018Q3/create_index_client_tables_2.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
 } 
 
   changeSet (author: "hmajid", id: "create_index_metric_mv.sql") {
             sqlFile (path: "2018Q3/create_index_metric_mv.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
   changeSet (author: "hmajid", id: "setup_chain_scheduler_ssc.sql") {
               sqlFile (path: "2018Q3/setup_chain_scheduler_ssc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
  changeSet (author: "pmuller", id: "msvc-3967_wipe_cws_data.sql") {
    sqlFile (path: "2018Q3/msvc-3967_wipe_cws_data.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
  changeSet (author: "pmuller", id: "msvc-4010_fix_unusable_indexes.sql") {
    sqlFile (path: "2018Q3/msvc-4010_fix_unusable_indexes.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
  
}
