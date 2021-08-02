databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "jpullifrone", id: "remove_inv_expd_dups_iqn-35075.sql") {
    sqlFile ("path": "remove_inv_expd_dups_iqn-35075.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_refresh_buyer_org_by_ent_part_list_ins.sql") {
    sqlFile ("path": "lego_refresh_buyer_org_by_ent_part_list_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_events_extr_tracker_ddl.sql") {
    sqlFile ("path": "lego_events_extr_tracker_ddl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "lego_timecard_event_ddl.sql") {
    sqlFile ("path": "lego_timecard_event_ddl.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }     
  changeSet (author: "pmuller", id: "lego_position_time_to_fill_ins.sql") {
    sqlFile ("path": "lego_position_time_to_fill_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "pmuller", id: "remove_old_ttf.sql") {
    sqlFile ("path": "remove_old_ttf.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "pmuller", id: "lego_ttf_ins.sql") {
    sqlFile ("path": "lego_ttf_ins.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   

}
