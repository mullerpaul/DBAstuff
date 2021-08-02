databaseChangeLog {

// Since many migration scripts and refresh_sql scripts depend on logger_pkg, we include changesets to 
// create the logging table, the package spec, and package body here where they will be run first.

  changeSet (author: "IQIntelligence team", id: "create_processing_log.sql") {
    sqlFile ("path": "src/main/resources/migration/dataextract/2016Q3/create_processing_log.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "logger_pkg_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/dataextract/package-specs/logger_pkg.pks", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "IQIntelligence team", id: "logger_pkg_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/dataextract/package-bodies/logger_pkg.pkb", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  
// Now that logger pkg exists, run the migration scripts.
// Every quarter, we'll have to add new directory, changelog file, and add an "include" for that file here.


  include (file: "2016Q3/changelog.groovy", relativeToChangelogFile: "true")  

}
