databaseChangeLog {

//  changeSet (author: "jdoe", id: "script.sql") {
//    sqlFile ("path": "script.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
//  }

// Rates
  changeSet (author: "lmartinez", id: "create_benchmark_table.0126.01.sql") {
    sqlFile ("path": "create_benchmark_table.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "pmuller", id: "create_benchmark_table_index.0126.01.sql") {
    sqlFile ("path": "create_benchmark_table_index.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

  changeSet (author: "lmartinez", id: "SOS_IQNLABS_BENCHMARKS.0126.01.sql") {
    sqlFile ("path": "SOS_IQNLABS_BENCHMARKS.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "SOS_IQNLABS_BENCHMARKS_DATA_TABLE.0126.01.sql") {
    sqlFile ("path": "SOS_IQNLABS_BENCHMARKS_DATA_TABLE.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "insert_iqnlabs_benchmarks.0126.01.sql") {
    sqlFile ("path": "insert_iqnlabs_benchmarks.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

//ttf
  changeSet (author: "lmartinez", id: "SOS_BENCHMARKS_TTF.sql") {
    sqlFile ("path": "SOS_BENCHMARKS_TTF.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "SOS_BENCHMARKS_TTF_DATA_TABLE.sql") {
    sqlFile ("path": "SOS_BENCHMARKS_TTF_DATA_TABLE.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
   changeSet (author: "lmartinez", id: "insert_ttf_benchmarks.sql") {
    sqlFile ("path": "insert_ttf_benchmarks.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

    changeSet (author: "lmartinez", id: "alter_table_rate_ttf.sql") {
    sqlFile ("path": "alter_table_rate_ttf.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  
  // missing Marketing Assistant Rates
  changeSet (author: "lmartinez", id: "SOS_IQNLABS_MA_BENCH.sql") {
    sqlFile ("path": "SOS_IQNLABS_MA_BENCH.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "SOS_IQNLABS_MA_BENCH_DATA_TABLE.sql") {
    sqlFile ("path": "SOS_IQNLABS_MA_BENCH_DATA_TABLE.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }
  changeSet (author: "lmartinez", id: "insert_iqnlabs_benchmarks_marketing_assistant.sql") {
    sqlFile ("path": "insert_iqnlabs_benchmarks_marketing_assistant.sql", "relativeToChangelogFile": true, "endDelimiter": "\n/\\s*\n|\n/\\s*\$")
  }

}

