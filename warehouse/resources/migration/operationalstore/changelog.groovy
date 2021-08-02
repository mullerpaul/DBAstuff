databaseChangeLog {

// Since many migration scripts and refresh_sql scripts depend on logger_pkg, we include changesets to 
// create the logging table, the package spec, and package body here where they will be run first.

  changeSet (author: "IQIntelligence team", id: "create_processing_log.sql") {
    sqlFile ("path": "src/main/resources/migration/operationalstore/2015Q4/create_processing_log.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "logger_pkg_pks.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-specs/logger_pkg_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "IQIntelligence team", id: "logger_pkg_pkb.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/operationalstore/package-bodies/logger_pkg_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  
// Now that logger pkg exists, run the migration scripts.
// Every quarter, we'll have to add new directory, changelog file, and add an "include" for that file here.

  include (file: "2015Q4/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2016Q1/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2016Q2/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2016Q3/changelog.groovy", relativeToChangelogFile: "true")  
  include (file: "2016Q4/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2017Q1/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2017Q2/changelog.groovy", relativeToChangelogFile: "true") 
  include (file: "2017Q3/changelog.groovy", relativeToChangelogFile: "true")  
  include (file: "2017Q4/changelog.groovy", relativeToChangelogFile: "true")  
  include (file: "2018Q1/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2018Q2/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2018Q3/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2018Q4/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2019Q1/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2019Q2/changelog.groovy", relativeToChangelogFile: "true")
  include (file: "2019Q3/changelog.groovy", relativeToChangelogFile: "true")

}
