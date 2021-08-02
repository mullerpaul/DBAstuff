databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile (path: "script.sql", endDelimiter: "\n/\\s*\n|\n/\\s*\$", stripComments: "true")
//  }
//
//  include file: "another_file.groovy"

  changeSet (author: "IQIntelligence team", id: "dm_invoiced_spend_lv.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/views/dm_invoiced_spend_lv.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  

  changeSet (author: "IQIntelligence team", id: "dm_rate_summary_lv.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/views/dm_rate_summary_lv.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "IQIntelligence team", id: "dm_supplier_score_card_lv.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/views/dm_supplier_score_card_lv.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "IQIntelligence team", id: "dm_invoice_fact_v.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/views/dm_invoice_fact_v.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "IQIntelligence team", id: "dm_headcount_fact_v.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/views/dm_headcount_fact_v.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  

  changeSet (author: "IQIntelligence team", id: "dm_atom_job_title_cat.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/views/dm_atom_job_title_cat.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }  
  
  changeSet (author: "IQIntelligence team", id: "dm_atom_place.sql", runOnChange: true) {
    sqlFile ("path": "src/main/resources/database/iqprodm/views/dm_atom_place.sql", "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  } 

}
