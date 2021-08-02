databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "lego_tools_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_tools_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "IQIntelligence team", id: "lego_refresh_mgr_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_refresh_mgr_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "jpullifrone", id: "lego_supplier_scorecard_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_supplier_scorecard_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "IQIntelligence team", id: "lego_validate_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_validate_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "jpullifrone", id: "lego_invoice_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_invoice_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	  
  changeSet (author: "jpullifrone", id: "finance_revenue_maint_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/finance_revenue_maint_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	 
  changeSet (author: "jpullifrone", id: "foid_guid_map_maint_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/foid_guid_map_maint_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	 
  changeSet (author: "hamjid", id: "lego_date_trend_pkb.sql", runOnChange: true) {
     sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_date_trend_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "mask_person_pkb.sql", runOnChange: true) {
     sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/mask_person_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_convergence_search_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_convergence_search_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_conv_search_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_refresh_conv_search_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_ssc_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_refresh_ssc_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_dashboards_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_refresh_dashboards_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_smartview_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_refresh_smartview_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_invoice_data_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/lego_refresh_invoice_data_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
}
