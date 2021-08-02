databaseChangeLog() {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "2017Q4/script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

  changeSet (author: "datanauts", id: "msvc-2582_client_category_coeffient.sql") {
    sqlFile (path: "2018Q1/msvc-2582_client_category_coeffient.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "datanauts", id: "msvc-2583_insert_client_category_coefficient.sql") {
    sqlFile (path: "2018Q1/msvc-2583_insert_client_category_coefficient.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "datanauts", id: "msvc-2691_add_audit_cols_to_client_metric_coefficient_01.sql") {
    sqlFile (path: "2018Q1/msvc-2691_add_audit_cols_to_client_metric_coefficient_01.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "datanauts", id: "msvc-2691_add_audit_cols_to_client_metric_coefficient_02.sql") {
    sqlFile (path: "2018Q1/msvc-2691_add_audit_cols_to_client_metric_coefficient_02.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "datanauts", id: "msvc-2691_add_audit_cols_to_client_metric_coefficient_03.sql") {
    sqlFile (path: "2018Q1/msvc-2691_add_audit_cols_to_client_metric_coefficient_03.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "datanauts", id: "msvc-2691_add_audit_cols_to_client_metric_coefficient_04.sql") {
    sqlFile (path: "2018Q1/msvc-2691_add_audit_cols_to_client_metric_coefficient_04.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "msvc-2584_update_client_metric_multipliers.sql") {
    sqlFile (path: "2018Q1/msvc-2584_update_client_metric_multipliers.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "pmuller", id: "msvc-2692_add_audit_cols_to_client_metric_conversion.sql") {
    sqlFile (path: "2018Q1/msvc-2692_add_audit_cols_to_client_metric_conversion.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
    changeSet (author: "pmuller", id: "msvc-2692_update_audit_cols_to_client_metric_conversion.sql") {
     sqlFile (path: "2018Q1/msvc-2692_update_audit_cols_to_client_metric_conversion.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
   changeSet (author: "pmuller", id: "msvc-2692_update_effective_date_not_null.sql") {
      sqlFile (path: "2018Q1/msvc-2692_update_effective_date_not_null.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
	changeSet (author: "mdunlap", id: "msvc-2699_update_metric_table_set_value.sql") {
      sqlFile (path: "2018Q1/msvc-2699_update_metric_table_set_value.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
  changeSet (author: "mdunlap", id: "msvc-2699_add_check_constraint_metric_table.sql") {
      sqlFile (path: "2018Q1/msvc-2699_add_check_constraint_metric_table.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
    changeSet (author: "hmajid", id: "msvc-2732_add_user_name_client_metric_coefficient.sql") {
        sqlFile (path: "2018Q1/msvc-2732_add_user_name_client_metric_coefficient.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
    changeSet (author: "hmajid", id: "msvc-2732_add_user_name_client_metric_conversion.sql") {
        sqlFile (path: "2018Q1/msvc-2732_add_user_name_client_metric_conversion.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
    changeSet (author: "hmajid", id: "msvc-2732_add_user_name_client_category_coefficient.sql") {
        sqlFile (path: "2018Q1/msvc-2732_add_user_name_client_category_coefficient.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }   
    changeSet (author: "pmuller", id: "msvc-2751_add_fk_to_ccc.sql") {
      sqlFile (path: "2018Q1/msvc-2751_add_fk_to_ccc.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }  
      changeSet (author: "hmajid", id: "msvc-2764-drop_fk_in_client_metric_conversion.sql") {
        sqlFile (path: "2018Q1/msvc-2764-drop_fk_in_client_metric_conversion.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
      changeSet (author: "hmajid", id: "msvc-2764-add_two_new_col_to_client_metric_conversion.sql") {
        sqlFile (path: "2018Q1/msvc-2764-add_two_new_col_to_client_metric_conversion.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
      changeSet (author: "hmajid", id: "msvc-2764-updt_new_added_cols_client_metric_conversion.sql") {
        sqlFile (path: "2018Q1/msvc-2764-updt_new_added_cols_client_metric_conversion.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
      changeSet (author: "hmajid", id: "msvc-2764-add_foreign_key_client_metric_conversion.sql") {
        sqlFile (path: "2018Q1/msvc-2764-add_foreign_key_client_metric_conversion.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
      changeSet (author: "hmajid", id: "msvc-2764-initialize_new_column_to_notnull.sql") {
        sqlFile (path: "2018Q1/msvc-2764-initialize_new_column_to_notnull.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
      changeSet (author: "hmajid", id: "msvc-2764-drop_col_from_client_metric_conversion.sql") {
        sqlFile (path: "2018Q1/msvc-2764-drop_col_from_client_metric_conversion.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }   
      changeSet (author: "mdunlap", id: "msvc-2775_add_cols_to_client_visibility_list.sql") {
        sqlFile (path: "2018Q1/msvc-2775_add_cols_to_client_visibility_list.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }  
      changeSet (author: "mdunlap", id: "msvc-2775_add_cols_to_client_visibility_list_gtt.sql") {
        sqlFile (path: "2018Q1/msvc-2775_add_cols_to_client_visibility_list_gtt.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 
      changeSet (author: "hmajid", id: "msvc-2776-update_or_delete_visibility_data.sql") {
          sqlFile (path: "2018Q1/msvc-2776-update_or_delete_visibility_data.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }  
      changeSet (author: "hmajid", id: "msvc-2776-alter_visibility_data_setcol_notnull.sql") {
            sqlFile (path: "2018Q1/msvc-2776-alter_visibility_data_setcol_notnull.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }  
      changeSet (author: "hmajid", id: "msvc-2776-alter_visibility_gtt_data_setcol_notnull.sql") {
              sqlFile (path: "2018Q1/msvc-2776-alter_visibility_gtt_data_setcol_notnull.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }  
      changeSet (author: "hmajid", id: "msvc-2870_drop_fk_constraint.sql") {
                sqlFile (path: "2018Q1/msvc-2870_drop_fk_constraint.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }    
      changeSet (author: "hmajid", id: "msvc-2698-revoke-privs.sql") {
                    sqlFile (path: "2018Q1/msvc-2698-revoke-privs.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  }
       changeSet (author: "hmajid", id: "modify_scc_comments.sql") {
                    sqlFile (path: "2018Q1/modify_scc_comments.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
  } 

}


