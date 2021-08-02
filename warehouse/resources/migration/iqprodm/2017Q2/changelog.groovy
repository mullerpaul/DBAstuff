databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "lmartinez", id: "dm_cmsa_place_xref.sql") {
    sqlFile ("path": "dm_cmsa_place_xref.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

changeSet (author: "lmartinez", id: "dm_cmsa_place_xref_data.sql") {
    sqlFile ("path": "dm_cmsa_place_xref_data.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

  changeSet (author: "lmartinez", id: "rate_and_ttf_benchmarks_v.sql") {
    sqlFile ("path": "rate_and_ttf_benchmarks_v.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

   changeSet (author: "lmartinez", id: "cmsa_cleanup_script20170426.sql") {
    sqlFile ("path": "cmsa_cleanup_script20170426.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

   changeSet (author: "lmartinez", id: "iqn37357-update_benchmarks.sql") {
    sqlFile ("path": "iqn37357-update_benchmarks.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

    changeSet (author: "lmartinez", id: "rate_ttf_eff_dt_idx.sql") {
    sqlFile ("path": "rate_ttf_eff_dt_idx.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
   changeSet (author: "lmartinez", id: "sos_benchmarks_schema.sql") {
    sqlFile ("path": "sos_benchmarks_schema.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

   changeSet (author: "lmartinez", id: "sos_benchmarks_data.sql") {
    sqlFile ("path": "sos_benchmarks_data.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
   changeSet (author: "lmartinez", id: "insert_2017q2_benchmarks.sql") {
    sqlFile ("path": "insert_2017q2_benchmarks.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
   changeSet (author: "jpullifrone", id: "decompress_dm_date_dim_ddl.sql") {
    sqlFile ("path": "decompress_dm_date_dim_ddl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  


}
