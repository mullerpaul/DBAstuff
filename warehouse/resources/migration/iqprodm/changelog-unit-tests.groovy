databaseChangeLog {

  changeSet (author: "jpullifrone", id: "iqn-38261_ut_dm_date_dim_insert.sq") {
    sqlFile ("path": "src/main/resources/database/iqprodm/unit-tests/iqn-38261_ut01_dm_date_dim_insert.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  changeSet (author: "jpullifrone", id: "iqn-39246_currency_conversion_ut01.sql") {
    sqlFile ("path": "src/main/resources/database/iqprodm/unit-tests/iqn-39246_currency_conversion_ut01.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 
}
