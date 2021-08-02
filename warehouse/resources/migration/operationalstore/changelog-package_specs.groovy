databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "lego_tools_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_tools_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "IQIntelligence team", id: "lego_refresh_mgr_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_refresh_mgr_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "jpullifrone", id: "lego_supplier_scorecard_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_supplier_scorecard_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "IQIntelligence team", id: "lego_validate_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_validate_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "jpullifrone", id: "lego_invoice_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_invoice_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	  
  changeSet (author: "jpullifrone", id: "finance_revenue_maint_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/finance_revenue_maint_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "foid_guid_map_maint_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/foid_guid_map_maint_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "hamjid", id: "lego_date_trend_pks.sql", runOnChange: true) {
     sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_date_trend_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "mask_person_pks.sql", runOnChange: true) {
     sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/mask_person_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_convergence_search_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_convergence_search_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_conv_search_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_refresh_conv_search_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_ssc_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_refresh_ssc_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_dashboards_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_refresh_dashboards_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_smartview_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_refresh_smartview_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_invoice_data_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/lego_refresh_invoice_data_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
}
