databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "aarrambide", id: "IQN-42131_deleteInvoice.sql") {
    sqlFile ("path": "IQN-42131_deleteInvoice.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "Datanauts", id: "IQN-42715_insert_dependencies_wf.sql") {
    sqlFile ("path": "IQN-42715_insert_dependencies_wf.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "Datanauts", id: "IQN-42857_delete_WF_in_EMEA.sql") {
    sqlFile ("path": "IQN-42857_delete_WF_in_EMEA.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  
}

