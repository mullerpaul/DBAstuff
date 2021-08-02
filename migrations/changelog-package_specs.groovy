databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql", runOnChange: true) {
//    sqlFile ("path": "package-specs/script.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

  changeSet (author: "pmuller", id: "supplier_data_utility_pks.sql", runOnChange: true) {
    sqlFile ("path": "package-specs/supplier_data_utility_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "client_metric_settings_util_pks.sql", runOnChange: true) {
    sqlFile ("path": "package-specs/client_metric_settings_util_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "client_exclusion_util_pks.sql", runOnChange: true) {
    sqlFile ("path": "package-specs/client_exclusion_util_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "supplier_data_api_pks.sql", runOnChange: true) {
    sqlFile ("path": "package-specs/supplier_data_api_pks.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "data_test.pks", runOnChange: true) {
    sqlFile ("path": "package-specs/data_test.pks", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

}

