databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_utils_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_utils_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_supp_metrics_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_supp_metrics_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_rate_event_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_rate_event_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_fo_metric_graph_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_fo_metric_graph_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_currency_conversion_data_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_currency_conversion_data_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_buyer_supp_agmt_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_buyer_supp_agmt_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_geo_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_geo_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_cube_utils_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_cube_utils_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_org_dim_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_org_dim_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_person_dim_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_person_dim_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_ratecard_dim_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_ratecard_dim_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_fotimecard_rate_event_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_fotimecard_rate_event_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_botimecard_rate_event_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_botimecard_rate_event_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_iqn_index_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_iqn_index_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_invoice_fact_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_invoice_fact_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_headcount_fact_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_headcount_fact_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_inv_headcount_fact_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_inv_headcount_fact_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_worker_dim_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_worker_dim_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_tt_fill_fact_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_tt_fill_fact_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_project_agreement_dim_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_project_agreement_dim_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_populate_spend_summary_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_populate_spend_summary_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_job_dim_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_job_dim_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_invoiced_cac_dim_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_invoiced_cac_dim_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_geographic_rate_process_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_geographic_rate_process_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_assignment_dim_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_assignment_dim_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "datamart", id: "warehouse/iqprodm/package-bodies/dm_expenditure_dim_pkb.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/package-bodies/dm_expenditure_dim_pkb.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }

}
