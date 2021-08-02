databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

     
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_util_log_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_util_log_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_utils_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_utils_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_supp_metrics_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_supp_metrics_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_rate_event_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_rate_event_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_fo_metric_graph_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_fo_metric_graph_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_currency_conversion_data_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_currency_conversion_data_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_buyer_supp_agmt_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_buyer_supp_agmt_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_geo_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_geo_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_cube_utils_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_cube_utils_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_org_dim_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_org_dim_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_person_dim_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_person_dim_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_ratecard_dim_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_ratecard_dim_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_fotimecard_rate_event_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_fotimecard_rate_event_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_botimecard_rate_event_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_botimecard_rate_event_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_iqn_index_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_iqn_index_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_invoice_fact_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_invoice_fact_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_headcount_fact_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_headcount_fact_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_inv_headcount_fact_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_inv_headcount_fact_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_worker_dim_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_worker_dim_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_tt_fill_fact_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_tt_fill_fact_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_project_agreement_dim_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_project_agreement_dim_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_populate_spend_summary_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_populate_spend_summary_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_job_dim_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_job_dim_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_invoiced_cac_dim_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_invoiced_cac_dim_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_geographic_rate_process_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_geographic_rate_process_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_assignment_dim_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_assignment_dim_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-specs/dm_expenditure_dim_pks.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-specs/dm_expenditure_dim_pks.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }  
  

}
