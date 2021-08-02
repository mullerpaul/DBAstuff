databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

// preops
  include (file: "changelog-preops.groovy", relativeToChangelogFile: "true")

// migration scripts
  include (file: "changelog.groovy", relativeToChangelogFile: "true")

// database objects
  include (file: "changelog-package_specs.groovy", relativeToChangelogFile: "true")
  include (file: "changelog-views.groovy", relativeToChangelogFile: "true")
  include (file: "changelog-package_bodies.groovy", relativeToChangelogFile: "true")

// postopts
  include (file: "changelog-postops.groovy", relativeToChangelogFile: "true")

}
