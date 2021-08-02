databaseChangeLog {

  changeSet (author: "pmuller", id: "grants_to_other_mart_schemas.sql", runOnChange: true, runAlways: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/postops/grants_to_other_mart_schemas.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
//  commenting out with IQN-40224 since the job structure changes then.
//   We'll need to (re)address the problem of stopping lego refresh jobs before a migration soon.  When we do, we'll 
//   probably have to add something back in here.
//  changeSet (author: "jpullifrone", id: "enable_lego_refresh_kickoff.sql", runOnChange: true, runAlways: true) {
//    sqlFile ("path": "src/main/resources/database/operationalstore/postops/enable_lego_refresh_kickoff.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

}
