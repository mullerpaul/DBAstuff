databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "jpullifrone", id: "lego_parameter_timecard_lookback.sql") {
    sqlFile ("path": "lego_parameter_timecard_lookback.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_expd_detail_ins.sql") {
    sqlFile ("path": "lego_expd_detail_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "lego_invd_expd_detail_modify_iqn-37458.sql") {
    sqlFile ("path": "lego_invd_expd_detail_modify_iqn-37458.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "finance_load_tracker_ddl_iqn-37460.sql") {
    sqlFile ("path": "finance_load_tracker_ddl_iqn-37460.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "finance_approved_invoice_ddl_iqn-37460.sql") {
    sqlFile ("path": "finance_approved_invoice_ddl_iqn-37460.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "finance_revenue_stage_ddl_iqn-37460.sql") {
    sqlFile ("path": "finance_revenue_stage_ddl_iqn-37460.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "finance_revenue_ddl_iqn-37460.sql") {
    sqlFile ("path": "finance_revenue_ddl_iqn-37460.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "finance_org_currency_iqn-37472.sql") {
    sqlFile ("path": "finance_org_currency_iqn-37472.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "finance_org_currency_inserts_iqn-37472.sql") {
    sqlFile ("path": "finance_org_currency_inserts_iqn-37472.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "finance_revenue_stage_ddl_iqn-37495.sql") {
    sqlFile ("path": "finance_revenue_stage_ddl_iqn-37495.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "finance_revenue_ddl_iqn-37495.sql") {
    sqlFile ("path": "finance_revenue_ddl_iqn-37495.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_invoice_create_dummy_objs.sql") {
    sqlFile ("path": "lego_invoice_create_dummy_objs.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "drop_finance_approved_invoice_ddl_iqn-37512.sql") {
    sqlFile ("path": "drop_finance_approved_invoice_ddl_iqn-37512.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_refresh_toggle_priv_ddl_iqn-37523.sql") {
    sqlFile ("path": "lego_refresh_toggle_priv_ddl_iqn-37523.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_refresh_toggle_priv_dml_ins_iqn-37523.sql") {
    sqlFile ("path": "lego_refresh_toggle_priv_dml_ins_iqn-37523.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "finance_revenue_stage_ddl_iqn-37523") {
    sqlFile ("path": "finance_revenue_stage_ddl_iqn-37523.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "finance_revenue_ddl_iqn-37523.sql") {
    sqlFile ("path": "finance_revenue_ddl_iqn-37523.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_cac_collection_current_create_dummy_objs.sql") {
    sqlFile ("path": "lego_cac_collection_current_create_dummy_objs.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_cac_current_create_dummy_objs.sql") {
    sqlFile ("path": "lego_cac_current_create_dummy_objs.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_bus_org_create_dummy_objs.sql") {
    sqlFile ("path": "lego_bus_org_create_dummy_objs.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "lego_invoice_create_dummy_objs_iqn-37523.sql") {
    sqlFile ("path": "lego_invoice_create_dummy_objs_iqn-37523.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }     
  changeSet (author: "jpullifrone", id: "finance_revenue_stage_ddl_iqn-37527.sql") {
    sqlFile ("path": "finance_revenue_stage_ddl_iqn-37527.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "finance_revenue_ddl_iqn-37527.sql") {
    sqlFile ("path": "finance_revenue_ddl_iqn-37527.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  
}


