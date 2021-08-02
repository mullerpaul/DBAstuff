databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "remove_schema_objects.sql") {
    sqlFile ("path": "remove_schema_objects.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

}
