databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/upd_cube_dim_load_status_prc.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/upd_cube_dim_load_status_prc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/dim_daily_process_prc.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/dim_daily_process_prc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/tt_fill_fact_daily_process_prc.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/tt_fill_fact_daily_process_prc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/invoice_fact_daily_process_prc.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/invoice_fact_daily_process_prc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/inv_hc_fact_daily_process_prc.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/inv_hc_fact_daily_process_prc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/hc_fact_daily_process_prc.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/hc_fact_daily_process_prc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/dw_saturday_process_prc.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/dw_saturday_process_prc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/dm_rate_events_proc.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/dm_rate_events_proc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/dm_compile_objects.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/dm_compile_objects.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "datamart", id: "warehouse/iqprodm/procedures/dim_weekly_process_prc.sql", runOnChange: true) {
    sqlFile (path: "src/main/resources/database/iqprodm/procedures/dim_weekly_process_prc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$")
  }
  
}
