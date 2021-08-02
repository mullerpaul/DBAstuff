databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "jpullifrone", id: "lego_sow_milestone_invoice_ins.sql") {
    sqlFile ("path": "lego_sow_milestone_invoice_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }     
  changeSet (author: "jpullifrone", id: "lego_invoice_approved_create_tbl.sql") {
    sqlFile ("path": "lego_invoice_approved_create_tbl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_buyers_by_ent_inv_gtt_create_tbl.sql") {
    sqlFile ("path": "lego_buyers_by_ent_inv_gtt_create_tbl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
    changeSet (author: "jpullifrone", id: "lego_part_by_enterprise_gtt_create_tbl.sql") {
    sqlFile ("path": "lego_part_by_enterprise_gtt_create_tbl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_part_by_ent_buyer_org_gtt_create_tbl.sql") {
    sqlFile ("path": "lego_part_by_ent_buyer_org_gtt_create_tbl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_invd_expd_detail_create_tbl.sql") {
    sqlFile ("path": "lego_invd_expd_detail_create_tbl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_refresh_ins_invd_expd_det.sql") {
    sqlFile ("path": "lego_refresh_ins_invd_expd_det.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "pmuller", id: "drop_unneeded_views.sql") {
    sqlFile ("path": "drop_unneeded_views.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_invd_expd_detail_modify_iqn-33411_a.sql") {
    sqlFile ("path": "lego_invd_expd_detail_modify_iqn-33411.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "pmuller", id: "create_automatic_refresh_job_IQN-32938.sql") {
    sqlFile ("path": "create_automatic_refresh_job_IQN-32938.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "lego_person_available_org_ins.sql") {
    sqlFile ("path": "lego_person_available_org_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_refresh_index_ins_iqn-33780.sql") {
    sqlFile ("path": "lego_refresh_index_ins_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_invoice_object_create_tbl.sql") {
    sqlFile ("path": "lego_invoice_object_create_tbl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_invoice_object_inserts_01.sql") {
    sqlFile ("path": "lego_invoice_object_inserts_01.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_invd_expd_date_ru_create_tbl_iqn-33780.sql") {
    sqlFile ("path": "lego_invd_expd_date_ru_create_tbl_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "lego_invoice_approved_modify_iqn-33780.sql") {
    sqlFile ("path": "lego_invoice_approved_modify_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }      
  changeSet (author: "jpullifrone", id: "lego_part_by_enterprise_gtt_modify_iqn-33780.sql") {
    sqlFile ("path": "lego_part_by_enterprise_gtt_modify_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }       
  changeSet (author: "jpullifrone", id: "lego_buyers_by_ent_inv_gtt_modify_iqn-33780.sql") {
    sqlFile ("path": "lego_buyers_by_ent_inv_gtt_modify_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_part_by_ent_buyer_org_gtt_modify_iqn-33780.sql") {
    sqlFile ("path": "lego_part_by_ent_buyer_org_gtt_modify_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_invoiced_expd_detail_modify_iqn-33780.sql") {
    sqlFile ("path": "lego_invoiced_expd_detail_modify_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_refresh_invd_expd_detail_modify_iqn-33780.sql") {
    sqlFile ("path": "lego_refresh_invd_expd_detail_modify_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_refresh_ins_invd_expd_date_ru.sql") {
    sqlFile ("path": "lego_refresh_ins_invd_expd_date_ru.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_revoke_from_iqprodm_01_a.sql") {
    sqlFile ("path": "lego_revoke_from_iqprodm_01.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_refresh_timecard_approval_ins.sql") {
    sqlFile ("path": "lego_refresh_timecard_approval_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_refresh_expense_approval_ins.sql") {
    sqlFile ("path": "lego_refresh_expense_approval_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_invd_expd_date_ru_modify_iqn-33780.sql") {
    sqlFile ("path": "lego_invd_expd_date_ru_modify_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_refresh_index_ins2_iqn-33780.sql") {
    sqlFile ("path": "lego_refresh_index_ins2_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_invd_expd_detail_modify2_iqn-33780.sql") {
    sqlFile ("path": "lego_invd_expd_detail_modify2_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }     
  changeSet (author: "jpullifrone", id: "lego_refresh_index_ins3_iqn-33780.sql") {
    sqlFile ("path": "lego_refresh_index_ins3_iqn-33780.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }      
  changeSet (author: "pmuller", id: "change_iot_clause_in_rollup_legos_v2.sql") {
    sqlFile ("path": "change_iot_clause_in_rollup_legos.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "add_dummy_col_to_rollup_toggles.sql") {
    sqlFile ("path": "add_dummy_col_to_rollup_toggles.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "remove_org_security_lego.sql") {
    sqlFile ("path": "remove_org_security_lego.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "lego_refresh_ins_match_stats_by_job.sql") {
    sqlFile ("path": "lego_refresh_ins_match_stats_by_job.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }      
  changeSet (author: "pmuller", id: "modify_index_metadata_iqn-34080.sql") {
    sqlFile ("path": "modify_index_metadata_iqn-34080.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_refresh_ins_sow_ms_invdet_fixed_adhoc.sql") {
    sqlFile ("path": "lego_refresh_ins_sow_ms_invdet_fixed_adhoc.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_refresh_ins_sow_ms_invdet_rate_tables.sql") {
    sqlFile ("path": "lego_refresh_ins_sow_ms_invdet_rate_tables.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_refresh_ins_sow_services_rate_table_rates.sql") {
    sqlFile ("path": "lego_refresh_ins_sow_services_rate_table_rates.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_refresh_ins_sow_complex_resource.sql") {
    sqlFile ("path": "lego_refresh_ins_sow_complex_resource.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "pmuller", id: "remove_old_CAC_objects.sql") {
    sqlFile ("path": "remove_old_CAC_objects.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "insert_CAC_lego_metadata.sql") {
    sqlFile ("path": "insert_CAC_lego_metadata.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "create_perm_cac_tables.sql") {
    sqlFile ("path": "create_perm_cac_tables.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_invoice_object_rename.sql") {
    sqlFile ("path": "lego_invoice_object_rename.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_object_inserts_01.sql") {
    sqlFile ("path": "lego_object_inserts_01.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "lego_invd_expd_detail_modify_iqn-34663.sql") {
    sqlFile ("path": "lego_invd_expd_detail_modify_iqn-34663.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_invoiced_expd_detail_mv_log.sql") {
    sqlFile ("path": "lego_invoiced_expd_detail_mv_log.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "buyer_invd_assign_spnd_mon_mv.sql") {
    sqlFile ("path": "buyer_invd_assign_spnd_mon_mv.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
 
}

