databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "package-bodies/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "supplier_data_utility_pkb.sql", runOnChange: true) {
    sqlFile ("path": "package-bodies/supplier_data_utility_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "client_metric_settings_util_pkb.sql", runOnChange: true) {
    sqlFile ("path": "package-bodies/client_metric_settings_util_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "client_exclusion_util_pkb.sql", runOnChange: true) {
    sqlFile ("path": "package-bodies/client_exclusion_util_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "supplier_data_api_pkb.sql", runOnChange: true) {
    sqlFile ("path": "package-bodies/supplier_data_api_pkb.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "data_test.pkb", runOnChange: true) {
    sqlFile ("path": "package-bodies/data_test.pkb", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

}
