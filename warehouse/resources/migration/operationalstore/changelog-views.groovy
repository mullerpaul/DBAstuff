databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//

  changeSet (author: "pmuller", id: "lego_req_by_status_views.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/lego_req_by_status_views.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "lego_upcoming_ends_views.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/lego_upcoming_ends_views.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "lego_monthly_assgn_count_spend_views.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/lego_monthly_assgn_count_spend_views.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_assgn_by_location_views.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/lego_assgn_by_location_views.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "address_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/address_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }     
  changeSet (author: "hmajid", id: "create_lego_all_assign_types_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/create_lego_all_assign_types_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "hmajid", id: "create_lego_assign_month_trend_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/create_lego_assign_month_trend_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "hmajid", id: "create_lego_assign_24_mo_trend_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/create_lego_assign_24_mo_trend_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "hmajid", id: "sf_candidate_view.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/sf_candidate_view.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "hmajid", id: "create_invoiced_expd_date_ru_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/create_invoiced_expd_date_ru_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "skallichanda", id: "create_all_assign_types_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/create_all_assign_types_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "skallichanda", id: "job_vw.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/views/job_vw.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
}

