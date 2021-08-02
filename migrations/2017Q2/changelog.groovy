databaseChangeLog() {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "2017Q2/script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

  changeSet (author: "landerson", id: "supplier_scorecard_ddl.sql") {
      sqlFile (path: "2017Q2/supplier_scorecard_ddl.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "create_load_history_sequence_ddl.sql") {
      sqlFile (path: "2017Q2/create_load_history_sequence_ddl.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "create_metric_default_sequences.sql") {
      sqlFile (path: "2017Q2/create_metric_default_sequences.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "insert_metric_and_conversion_data.sql") {
      sqlFile (path: "2017Q2/insert_metric_and_conversion_data.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "recreate_exclusion_tables.sql") {
      sqlFile (path: "2017Q2/recreate_exclusion_tables.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "recreate_client_metric_tables.sql") {
      sqlFile (path: "2017Q2/recreate_client_metric_tables.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "drop_load_history.sql_v3") {
      sqlFile (path: "2017Q2/drop_load_history.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "create_load_history_ddl.sql_4") {
      sqlFile (path: "2017Q2/create_load_history_ddl.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "missing_metrics_dml.sql") {
      sqlFile (path: "2017Q2/missing_metrics_dml.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "correct_metric_ranges.sql") {
      sqlFile (path: "2017Q2/correct_metric_ranges.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "default_metric_coefficient_update.sql") {
      sqlFile (path: "2017Q2/default_metric_coefficient_update.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "drop_temporary_tables.sql_v6") {
      sqlFile (path: "2017Q2/drop_temporary_tables.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "create_temporary_tables.sql_v7") {
      sqlFile (path: "2017Q2/create_temporary_tables.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "drop_data_tables.sql_v2") {
      sqlFile (path: "2017Q2/drop_data_tables.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "create_data_tables_ddl.sql_v3") {
      sqlFile (path: "2017Q2/create_data_tables_ddl.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "drop_metric_sequence.sql") {
      sqlFile (path: "2017Q2/drop_metric_sequence.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "remove_unneeded_metrics_client_settings.sql_v2") {
      sqlFile (path: "2017Q2/remove_unneeded_metrics_client_settings.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "remove_unneeded_metrics_defaults.sql_v2") {
      sqlFile (path: "2017Q2/remove_unneeded_metrics_defaults.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "widen_metric_name_column.sql") {
      sqlFile (path: "2017Q2/widen_metric_name_column.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "add_three_more_metrics.sql") {
      sqlFile (path: "2017Q2/add_three_more_metrics.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "rename_and_reclassify_metrics.sql") {
      sqlFile (path: "2017Q2/rename_and_reclassify_metrics.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "copy_new_metrics_to_client_specific_tables.sql") {
      sqlFile (path: "2017Q2/copy_new_metrics_to_client_specific_tables.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
}

