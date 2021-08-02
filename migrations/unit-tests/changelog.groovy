databaseChangeLog() {

  changeSet (author: "full_outer_join", id: "msvc-1666_create_client_visibility_list_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-1666_create_client_visibility_list_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
  changeSet (author: "full_outer_join", id: "msvc-1667_load_legacy_beeline_viz_data_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-1667_load_legacy_beeline_viz_data_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
  changeSet (author: "full_outer_join", id: "msvc-1622_supplier_release_gtt_ut01.sqlv2", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-1622_supplier_release_gtt_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
  changeSet (author: "full_outer_join", id: "msvc-1915_supp_data_and_excln_vw_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-1915_supp_data_and_excln_vw_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
  changeSet (author: "full_outer_join", id: "msvc-1915_load_defaults_for_all_orgs.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-1915_load_defaults_for_all_orgs.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
  changeSet (author: "full_outer_join", id: "msvc-2076_load_package_body_is_invalid_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2076_load_package_body_is_invalid_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
  changeSet (author: "full_outer_join", id: "msvc-2014_unit_test_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2014_unit_test_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }     
  changeSet (author: "datanauts", id: "msvc-2582_new_table.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2582_new_table.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
  changeSet (author: "datanauts", id: "msvc-2583_check_dataload_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2583_check_dataload_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }    
  changeSet (author: "datanauts", id: "msvc-2691_audit_table_client_metric_coefficient_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2691_audit_table_client_metric_coefficient_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }    
  changeSet (author: "datanauts", id: "msvc-2584_update_metric_coefficient_col_to_10_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2584_update_metric_coefficient_col_to_10_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
  changeSet (author: "datanauts", id: "msvc-2692_audit_table_client_metric_conversion_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2692_audit_table_client_metric_conversion_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
  changeSet (author: "datanauts", id: "msvc-2699_modify_coefficient_col_in_metric_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2699_modify_coefficient_col_in_metric_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
  changeSet (author: "datanauts", id: "msvc-2732_created_by_username_to_tables_ut01.sql_v2", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2732_created_by_username_to_tables_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
  changeSet (author: "datanauts", id: "msvc-2751_make_category_coefficient_FK_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2751_make_category_coefficient_FK_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
  changeSet (author: "datanauts", id: "msvc-2585_modify_dataload_precategory_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2585_modify_dataload_precategory_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
    changeSet (author: "datanauts", id: "msvc-2764_redesign_client_metric_conversion_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2764_redesign_client_metric_conversion_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
     changeSet (author: "datanauts", id: "msvc-2775_add_score_config_owner_col_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2775_add_score_config_owner_col_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
     changeSet (author: "datanauts", id: "msvc-2776_change_load_procedure_client_vis_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2776_change_load_procedure_client_vis_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
     /*changeSet (author: "datanauts", id: "msvc-2694_client_metric_settings_api_call_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2694_client_metric_settings_api_call_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
     changeSet (author: "datanauts", id: "msvc-2694_client_metric_settings_api_call_ut02.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2694_client_metric_settings_api_call_ut02.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }*/
     changeSet (author: "datanauts", id: "msvc-2870_remove_unique_constraint_cmc_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2870_remove_unique_constraint_cmc_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
    /* changeSet (author: "datanauts", id: "msvc-2695_client_metric_coeff_api_call_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2695_client_metric_coeff_api_call_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
     changeSet (author: "datanauts", id: "msvc-2695_client_metric_coeff_api_call_ut02.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2695_client_metric_coeff_api_call_ut02.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }*/
     changeSet (author: "datanauts", id: "msvc-2714_data_checker_into_liquidbase_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2714_data_checker_into_liquidbase_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
     /*changeSet (author: "datanauts", id: "msvc-2696_client_metriv_conv_api_call_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2696_client_metriv_conv_api_call_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   */
     changeSet (author: "datanauts", id: "msvc-2889_remove_effective_date_on_set_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2889_remove_effective_date_on_set_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
     /*changeSet (author: "datanauts", id: "msvc-2896_metric_range_grade_conv_ut01.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2896_metric_range_grade_conv_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
     changeSet (author: "datanauts", id: "msvc-2896_metric_range_grade_conv_ut02.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2896_metric_range_grade_conv_ut02.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } */
     changeSet (author: "datanauts", id: "msvc-2892_get_api_ut01_v2.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2892_get_api_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
     changeSet (author: "datanauts", id: "msvc-2892_get_api_ut02_v2.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2892_get_api_ut02.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }     
     changeSet (author: "datanauts", id: "msvc-2892_get_api_ut03_v2.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2892_get_api_ut03.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
     changeSet (author: "datanauts", id: "msvc-2892_get_api_ut04_v2.sql", runAlways: false) {
    sqlFile ("path": "unit-tests/msvc-2892_get_api_ut04.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
     changeSet (author: "datanauts", id: "msvc-2698_revoke_ssc_user_grants_ut01.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-2698_revoke_ssc_user_grants_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
     changeSet (author: "hmajid", id: "msvc-2586_client_visibility_view_ut01.sql", runAlways: false) {
        sqlFile ("path": "unit-tests/msvc-2586_client_visibility_view_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
     changeSet (author: "datanauts", id: "msvc-3159_ssc_comments_table_ut01.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3159_ssc_comments_table_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
     changeSet (author: "datanauts", id: "msvc-3159_ssc_comments_table_ut02.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3159_ssc_comments_table_ut02.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
     changeSet (author: "datanauts", id: "msvc-3160_ssc_combined_sp_01.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3160_ssc_combined_sp_01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
     changeSet (author: "datanauts", id: "msvc-3257_ssc_convert_date_on_metrics_ut01.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3257_ssc_convert_date_on_metrics_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
     changeSet (author: "datanauts", id: "msvc-3257_ssc_convert_date_on_metrics_ut02.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3257_ssc_convert_date_on_metrics_ut02.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
     changeSet (author: "datanauts", id: "msvc-3257_ssc_convert_date_on_metrics_ut03.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3257_ssc_convert_date_on_metrics_ut03.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
     changeSet (author: "datanauts", id: "msvc-3257_ssc_convert_date_on_metrics_ut04.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3257_ssc_convert_date_on_metrics_ut04.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
     changeSet (author: "datanauts", id: "msvc-3258_get_historical_data_ut01.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3258_get_historical_data_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
     changeSet (author: "datanauts", id: "msvc-3258_get_historical_data_ut02.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3258_get_historical_data_ut02.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
     changeSet (author: "datanauts", id: "msvc-3258_get_historical_data_ut03.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3258_get_historical_data_ut03.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
     changeSet (author: "datanauts", id: "msvc-3258_get_historical_data_ut04.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3258_get_historical_data_ut04.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
     changeSet (author: "datanauts", id: "msvc-3685_update_category_coefficient_col_to_1_ut01.sql_v2", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3685_update_category_coefficient_col_to_1_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
     changeSet (author: "datanauts", id: "msvc-3781_update_metric_coefficient_col_to_1_ut01.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3781_update_metric_coefficient_col_to_1_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
       changeSet (author: "datanauts", id: "msvc-3864_check_data_in_supp_rel_dup_ut01.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3864_check_data_in_supp_rel_dup_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
     changeSet (author: "datanauts", id: "msvc-3476_get_historical_data_ut01.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3476_get_historical_data_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
       changeSet (author: "datanauts", id: "msvc-3476_get_historical_data_ut02.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3476_get_historical_data_ut02.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
       changeSet (author: "datanauts", id: "msvc-3476_get_historical_data_ut03.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3476_get_historical_data_ut03.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
       changeSet (author: "datanauts", id: "msvc-3476_get_historical_data_ut04.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3476_get_historical_data_ut04.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   

        changeSet (author: "datanauts", id: "msvc-3963_get_historical_data_ut01.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3963_get_historical_data_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }  
        changeSet (author: "datanauts", id: "msvc-3963_get_historical_data_ut02.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3963_get_historical_data_ut02.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
        changeSet (author: "datanauts", id: "msvc-3963_get_historical_data_ut03.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3963_get_historical_data_ut03.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }   
        changeSet (author: "datanauts", id: "msvc-3963_get_historical_data_ut04.sql", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3963_get_historical_data_ut03.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
       changeSet (author: "datanauts", id: "msvc-3967_check_beeline_data_ut01.sqlv2", runAlways: false) {
      sqlFile ("path": "unit-tests/msvc-3967_check_beeline_data_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }     
  } 

  



