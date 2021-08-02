databaseChangeLog() {

// I've separated these data tests into two scripts to keep the fail on error ones separate 
// from the warn on error ones.  Thats mainly just because of the way I implemented the 
// fail on error flag in the test package.
  changeSet (author: "pmuller", id: "data_tests_warn_on_error.sql", runOnChange: true, runAlways: true) {
    sqlFile ("path": "data-tests/data_tests_warn_on_error.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 
  changeSet (author: "pmuller", id: "data_tests_fail_on_error.sql", runOnChange: true, runAlways: true) {
    sqlFile ("path": "data-tests/data_tests_fail_on_error.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$", "stripComments": true)
  } 

} 



