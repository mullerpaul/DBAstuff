databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "iqn-38831_step1_recreate_MV_log.sql") {
    sqlFile ("path": "iqn-38831_step1_recreate_MV_log.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "pmuller", id: "iqn-38831_step2_reload_MV.sql") {
    sqlFile ("path": "iqn-38831_step2_reload_MV.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 

}

