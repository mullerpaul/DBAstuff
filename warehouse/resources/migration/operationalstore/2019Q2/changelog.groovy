databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "hmajid", id: "IQN-43322_correct_wf_dependencies.sql") {
    sqlFile ("path": "IQN-43322_correct_wf_dependencies.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "mdunlap", id: "IQN-42715_insert_dependencies_wf.sql") {
    sqlFile ("path": "IQN-42715_insert_dependencies_wf.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
changeSet (author: "mdunlap", id: "IQN-43322_correct_wf_dependencies2.sql") {
    sqlFile ("path": "IQN-43322_correct_wf_dependencies2.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
changeSet (author: "nconcepcion", id: "IQN-43704_insert_lego_job_dependencies.sql") {
    sqlFile ("path": "IQN-43704_insert_lego_job_dependencies.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "nconcepcion", id: "IQN-43704_enable_smartview_refresh_job.sql") {
    sqlFile ("path": "IQN-43704_enable_smartview_refresh_job.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  
}

