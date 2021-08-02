databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "src/main/resources/database/operationalstore/postops/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
//  }


// need to rework the below script after IQN-40224 goes out since the job structure changes then.
  changeSet (author: "jpullifrone", id: "lego_disable_refresh_job_drop_active_jobs.sql", runOnChange: true, runAlways: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/preops/lego_disable_refresh_job_drop_active_jobs.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }


}



  
  
  