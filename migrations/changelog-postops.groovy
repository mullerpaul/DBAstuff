databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true, runAlways: true) {
//    sqlFile ("path": "postops/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
//  }

// Entries in this file are things that should run after ALL migration scripts, package DDL, view DDL, 
// have finished. That usually means object privilege scripts and synonym creation scripts; but could
// also be scripts to restart or re-enable processes after migrations.
// Scripts here should be "run on change" (preferred) or "run always" (looked at suspiciously)

  changeSet (author: "pmuller", id: "grant_schema_object_privs.sql", runOnChange: true) {
    sqlFile ("path": "postops/grant_schema_object_privs.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }
  changeSet (author: "pmuller", id: "create_user_schema_synonyms.sql", runOnChange: true) {
    sqlFile ("path": "postops/create_user_schema_synonyms.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  }

// Start unit tests scripts
  include (file: "unit-tests/changelog.groovy", relativeToChangelogFile: "true")

// Start data test scripts
// These are runAlways scripts which confirm that application data conforms to expectations
// and hopefully find data conditions which would otherwise cause the application to crash or 
// return incorrect results.  We may decide to move these elsewhere in the deploy later.
// They don't really need to be last.
  include (file: "data-tests/changelog.groovy", relativeToChangelogFile: "true")

}

