databaseChangeLog() {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "2017Q3/script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

  changeSet (author: "pmuller", id: "update_client_specific_metric_settings.sql") {
      sqlFile (path: "2017Q3/update_client_specific_metric_settings.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }

  changeSet (author: "driott", id: "add_placements_count_metric.sql") {
      sqlFile (path: "2017Q3/add_placements_count_metric.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }

  changeSet (author: "driott", id: "copy_metric_settings_single_client") {
      sqlFile (path: "2017Q3/copy_metric_settings_single_client.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }

  changeSet (author: "driott", id: "copy_metric_settings_all_clients") {
      sqlFile (path: "2017Q3/copy_metric_settings_all_clients.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "jpullifrone", id: "metric_placements_not_over_req_rate_reload_msvc-1179.sql") {
      sqlFile (path: "2017Q3/metric_placements_not_over_req_rate_reload_msvc-1179.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "update_metric_enabled_flag.sql") {
      sqlFile (path: "2017Q3/update_metric_enabled_flag.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "wipe_and_reload_all_client_metric_configs.sql") {
      sqlFile (path: "2017Q3/wipe_and_reload_all_client_metric_configs.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "drop_data_tables.sql_msvc-1344") {
      sqlFile (path: "2017Q3/drop_data_tables.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "create_data_tables_ddl.sql_msvc-1344") {
      sqlFile (path: "2017Q3/create_data_tables_ddl.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "update_two_metric_names.sql") {
      sqlFile (path: "2017Q3/update_two_metric_names.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  
}

