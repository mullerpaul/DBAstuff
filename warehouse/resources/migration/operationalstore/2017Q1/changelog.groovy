databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "jpullifrone", id: "lego_timecard_entry_create_tbl.sql") {
    sqlFile ("path": "lego_timecard_entry_create_tbl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
    changeSet (author: "jpullifrone", id: "remove_unused_tables.sql") {
    sqlFile ("path": "remove_unused_tables.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 

}


