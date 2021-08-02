databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "remove_emea_source.sql") {
    sqlFile ("path": "remove_emea_source.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_initload_ins.sql") {
    sqlFile ("path": "lego_refresh_initload_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "create_lego_cac_cdc.sql") {
    sqlFile ("path": "create_lego_cac_cdc.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "create_lego_cac_collection_cdc.sql") {
    sqlFile ("path": "create_lego_cac_collection_cdc.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "update_db_link_names.sql") {
    sqlFile ("path": "update_db_link_names.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "eliminate_HCC_compression.sql") {
    sqlFile ("path": "eliminate_HCC_compression.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "remove_tablespace_from_storage_clause.sql") {
    sqlFile ("path": "remove_tablespace_from_storage_clause.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_refresh_ins_address.sql") {
    sqlFile ("path": "lego_refresh_ins_address.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "remove_uneeded_job_legos.sql") {
    sqlFile ("path": "remove_uneeded_job_legos.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_refresh_ins_job_position.sql") {
    sqlFile ("path": "lego_refresh_ins_job_position.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "pmuller", id: "remove_uneeded_assignment_legos.sql") {
    sqlFile ("path": "remove_uneeded_assignment_legos.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "pmuller", id: "update_tenure_legos_metadata.sql") {
    sqlFile ("path": "update_tenure_legos_metadata.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_refresh_ins_evaluation.sql") {
    sqlFile ("path": "lego_refresh_ins_evaluation.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "lego_incremental_extractor_ddl.sql") {
    sqlFile ("path": "lego_incremental_extractor_ddl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  

}
