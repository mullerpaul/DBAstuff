databaseChangeLog {

// Since many migration scripts and refresh_sql scripts depend on logger_pkg, we include changesets to 
// create the logging table, the package spec, and package body here where they will be run first.

  changeSet (author: "IQIntelligence team", id: "create_processing_log.sql") {
    sqlFile ("path": "src/main/resources/migration/iqprodm/2016Q3/create_processing_log.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "logger_pkg_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/package-specs/logger_pkg_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	
  changeSet (author: "IQIntelligence team", id: "logger_pkg_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/package-bodies/logger_pkg_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }	

//  include file: "another_file.groovy"

  include (file: "2015Q4/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2016Q2/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2016Q3/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2016Q4/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2017Q1/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2017Q2/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2017Q3/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2018Q1/changelog.groovy", relativeToChangelogFile: "true")

}
