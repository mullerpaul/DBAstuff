databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "create_lego_parameter.sql") {
    sqlFile ("path": "create_lego_parameter.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "create_lego_refresh_legacy_objects.sql") {
    sqlFile ("path": "create_lego_refresh_legacy_objects.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "create_lego_scn_context.sql") {
    sqlFile ("path": "create_lego_scn_context.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_create_scheduler_programs.sql") {
    sqlFile ("path": "lego_create_scheduler_programs.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "lego_refresh_group_ins.sql") {
    sqlFile ("path": "lego_refresh_group_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
  changeSet (author: "pmuller", id: "delete_lego_refresh.sql") {
    sqlFile ("path": "delete_lego_refresh.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
  changeSet (author: "pmuller", id: "lego_source_ins.sql") {
    sqlFile ("path": "lego_source_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
  changeSet (author: "pmuller", id: "lego_refresh_ins.sql") {
    sqlFile ("path": "lego_refresh_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "update_lego_refresh.sql") {
    sqlFile ("path": "update_lego_refresh.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
  changeSet (author: "pmuller", id: "lego_parameter_ins.sql") {
    sqlFile ("path": "lego_parameter_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "jpullifrone", id: "lego_invoice_detail_gtt.sql") {
    sqlFile ("path": "lego_invoice_detail_gtt.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  

  
}
