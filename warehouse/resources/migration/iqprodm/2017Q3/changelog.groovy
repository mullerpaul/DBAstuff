databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

   changeSet (author: "lmartinez", id: "sos_benchmarks_schema.sql") {
    sqlFile ("path": "sos_benchmarks_schema.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "sos_benchmarks_data.sql") {
    sqlFile ("path": "sos_benchmarks_data.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "insert_2017q2_benchmarks.sql") {
    sqlFile ("path": "insert_2017q2_benchmarks.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "iqn-38008_dropDwOnDemandProc.sql") {
    sqlFile ("path": "iqn-38008_dropDwOnDemandProc.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "dm_date_dim_rebuild_unusable_indices_iqn-38261.sql") {
    sqlFile ("path": "dm_date_dim_rebuild_unusable_indices_iqn-38261.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "dm_date_dim_top_level_default_insert_iqn-38261.sql") {
    sqlFile ("path": "dm_date_dim_top_level_default_insert_iqn-38261.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  
}
