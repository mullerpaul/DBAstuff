databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

// migration scripts
  include (file: "changelog.groovy", relativeToChangelogFile: "true")

// refresh_sql for toggle legos
  include (file: "changelog-refresh_sql.groovy", relativeToChangelogFile: "true")
  
// database objects
  include (file: "changelog-synonyms.groovy", relativeToChangelogFile: "true")
  include (file: "changelog-package_specs.groovy", relativeToChangelogFile: "true")
  include (file: "changelog-views.groovy", relativeToChangelogFile: "true")
  include (file: "changelog-package_bodies.groovy", relativeToChangelogFile: "true")
  
}
