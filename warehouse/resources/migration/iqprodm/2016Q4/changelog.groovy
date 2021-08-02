databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "lmartinez", id: "SOS_IQNLABS_BENCHMARKS.sql") {
    sqlFile ("path": "SOS_IQNLABS_BENCHMARKS.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "SOS_IQNLABS_BENCHMARKS_DATA_TABLE.sql") {
    sqlFile ("path": "SOS_IQNLABS_BENCHMARKS_DATA_TABLE.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "insert_iqnlabs_benchmarks.sql") {
    sqlFile ("path": "insert_iqnlabs_benchmarks.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "revoke_select_from_ro_iqprodm_iqn-35244.sql") {
    sqlFile ("path": "revoke_select_from_ro_iqprodm_iqn-35244.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
   changeSet (author: "lmartinez", id: "insert_new_job_title-iqn-35735_2.sql") {
    sqlFile ("path": "insert_new_job_title-iqn-35735.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 

  changeSet (author: "lmartinez", id: "dm_std_sub_category_2.sql") {
    sqlFile ("path": "dm_std_sub_category.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  

   changeSet (author: "lmartinez", id: "dm_std_sub_category_data_table.sql") {
    sqlFile ("path": "dm_std_sub_category_data_table.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
   changeSet (author: "lmartinez", id: "update_std_job_titles_new_categories.sql") {
    sqlFile ("path": "update_std_job_titles_new_categories.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }


   changeSet (author: "lmartinez", id: "std_occupations_ddl_3.sql") {
    sqlFile ("path": "std_occupations_ddl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

  changeSet (author: "lmartinez", id: "std_occupations_data_3.sql") {
    sqlFile ("path": "std_occupations_data.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  
  changeSet (author: "lmartinez", id: "dm_occupation_hierarchy_ddl_3.sql") {
    sqlFile ("path": "dm_occupation_hierarchy_ddl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

  changeSet (author: "lmartinez", id: "job_occ_hierarchy_data_3.sql") {
    sqlFile ("path": "job_occ_hierarchy_data.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }


  changeSet (author: "lmartinez", id: "job_occ_hier_v_3.sql") {
    sqlFile ("path": "job_occ_hier_v.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  

  changeSet (author: "lmartinez", id: "occ_hierarchy_v_3.sql") {
    sqlFile ("path": "occ_hierarchy_v.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  
  changeSet (author: "lmartinez", id: "fix_occupation_data_IQN-36128_2.sql") {
    sqlFile ("path": "fix_occupation_data_IQN-36128.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  
  changeSet (author: "pmuller", id: "dm_date_dim_insert.sql") {
    sqlFile ("path": "dm_date_dim_insert_iqn-33714.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  
}

