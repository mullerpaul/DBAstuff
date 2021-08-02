databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "jpullifrone", id: "lego_refresh_finance_revenue_ins.sql") {
    sqlFile ("path": "lego_refresh_finance_revenue_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "rename_existing_lego_ttf.sql") {
    sqlFile ("path": "rename_existing_lego_ttf.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "rename_existing_lego_position_ttf.sql") {
    sqlFile ("path": "rename_existing_lego_position_ttf.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "lego_refresh_position_ttf_ins.sql") {
    sqlFile ("path": "lego_refresh_position_ttf_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_refresh_position_history_ins.sql") {
    sqlFile ("path": "lego_refresh_position_history_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_refresh_time_to_fill_legacy_ins.sql") {
    sqlFile ("path": "lego_refresh_time_to_fill_legacy_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }      
  changeSet (author: "jpullifrone", id: "lego_parameter_support_email_addy_ins.sql") {
    sqlFile ("path": "lego_parameter_support_email_addy_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_parameter_support_email_addy_upd.sql") {
    sqlFile ("path": "lego_parameter_support_email_addy_upd.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_object_insert_finrev.sql") {
    sqlFile ("path": "lego_object_insert_finrev.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "foid_guid_map_job_ddl_iqn-37648.sql") {
    sqlFile ("path": "foid_guid_map_job_ddl_iqn-37648.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "foid_guid_map_job_opportunity_ddl_iqn-37648.sql") {
    sqlFile ("path": "foid_guid_map_job_opportunity_ddl_iqn-37648.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "foid_guid_map_match_ddl_iqn-37648.sql") {
    sqlFile ("path": "foid_guid_map_match_ddl_iqn-37648.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_refresh_foid_guid_map_job_ins.sql") {
    sqlFile ("path": "lego_refresh_foid_guid_map_job_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_refresh_foid_guid_map_job_opp_ins.sql") {
    sqlFile ("path": "lego_refresh_foid_guid_map_job_opp_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_refresh_foid_guid_map_match_ins.sql") {
    sqlFile ("path": "lego_refresh_foid_guid_map_match_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_refresh_supplier_submission_ins.sql") {
    sqlFile ("path": "lego_refresh_supplier_submission_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "lego_refresh_supplier_release_ins.sql") {
    sqlFile ("path": "lego_refresh_supplier_release_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_assignment_wo_offer_id_ddl.sql") {
    sqlFile ("path": "lego_assignment_wo_offer_id_ddl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_parameter_support_email_addy_upd_IQN-37833.sql") {
    sqlFile ("path": "lego_parameter_support_email_addy_upd_IQN-37833.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }     
  changeSet (author: "jpullifrone", id: "drop_old_lego_views_iqn-38151.sql") {
    sqlFile ("path": "drop_old_lego_views_iqn-38151.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "create_dummy_tables_for_address_view.sql") {
    sqlFile ("path": "create_dummy_tables_for_address_view.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "hmajid", id: "create_dts_by_month.sql") {
    sqlFile ("path": "create_dts_by_month.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "hmajid", id: "insert_into_lego_refresh_group.sql") {
    sqlFile ("path": "insert_into_lego_refresh_group.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "hmajid", id: "insert_into_lego_refresh.sql") {
    sqlFile ("path": "insert_into_lego_refresh.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_refresh_supplier_scorecard_chgs_iqn-38381.sql") {
    sqlFile ("path": "lego_refresh_supplier_scorecard_chgs_iqn-38381.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  
}


