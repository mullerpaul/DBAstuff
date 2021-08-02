databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "jpullifrone", id: "dm_invoiced_spend_all_mv_log.sql") {
    sqlFile ("path": "dm_invoiced_spend_all_mv_log.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "dm_buyer_invd_assign_spnd_mon_mv.sql") {
    sqlFile ("path": "dm_buyer_invd_assign_spnd_mon_mv.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "dm_cmsa_lat_long.sql") {
    sqlFile ("path": "dm_cmsa_lat_long.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   
  changeSet (author: "jpullifrone", id: "dm_cmsa_lat_long_data.sql") {
    sqlFile ("path": "dm_cmsa_lat_long_data.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }    
  changeSet (author: "jpullifrone", id: "dm_atom_assign_xref.sql") {
    sqlFile ("path": "dm_atom_assign_xref.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "drop_dm_buyer_invd_assign_spnd_mon.sql") {
    sqlFile ("path": "drop_dm_buyer_invd_assign_spnd_mon.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
  changeSet (author: "jpullifrone", id: "dm_buyer_invd_assign_spnd_mon_ondemand.sql") {
    sqlFile ("path": "dm_buyer_invd_assign_spnd_mon_ondemand.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }   

}

