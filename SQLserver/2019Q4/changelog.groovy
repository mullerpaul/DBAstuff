databaseChangeLog {

/**********************************************************************************************************
  Example for adding new entries: 

  changeSet (author: "devname", id: "filename.sql") {
    sqlFile ("path": "filename.sql", "relativeToChangelogFile": true)
  }

***********************************************************************************************************/

  changeSet (author: "pmuller", id: "create_timecard.sql") {
    sqlFile ("path": "create_timecard.sql", "relativeToChangelogFile": true)
  }
  changeSet (author: "pmuller", id: "fake_timecard_client_guids.sql") {
    sqlFile ("path": "fake_timecard_client_guids.sql", "relativeToChangelogFile": true)
  }
  changeSet (author: "pmuller", id: "fake_timecard_locations.sql") {
    sqlFile ("path": "fake_timecard_locations.sql", "relativeToChangelogFile": true)
  }
  changeSet (author: "pmuller", id: "fake_timecard_week_dates.sql") {
    sqlFile ("path": "fake_timecard_week_dates.sql", "relativeToChangelogFile": true)
  }
  changeSet (author: "pmuller", id: "fake_timecard_job_ids.sql") {
    sqlFile ("path": "fake_timecard_job_ids.sql", "relativeToChangelogFile": true)
  }
  changeSet (author: "pmuller", id: "fake_timecard_insert.sql") {
    sqlFile ("path": "fake_timecard_insert.sql", "relativeToChangelogFile": true)
  }
  changeSet (author: "pmuller", id: "drop_temporary_work_tables.sql") {
    sqlFile ("path": "drop_temporary_work_tables.sql", "relativeToChangelogFile": true)
  }

}
