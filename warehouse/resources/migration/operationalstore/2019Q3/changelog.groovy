databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "skallichanda", id: "IQN-44736_delete_WF_references_in_EMEA.sql") {
    sqlFile ("path": "IQN-44736_delete_WF_references_in_EMEA.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  
}

