CREATE TABLE SOS_BENCHMARKS_TTF 
( CMSA_CODE VARCHAR2(255 BYTE), 
	BENCHMARK_TYPE VARCHAR2(40 BYTE), 
	STD_JOB_CATEGORY_ID NUMBER, 
	STD_OCCUPATION_ID NUMBER, 
	UNIT VARCHAR2(10 BYTE), 
	BENCHMARK_25_PERCENTILE NUMBER(5,2), 
	BENCHMARK_50_PERCENTILE NUMBER(5,2), 
	BENCHMARK_75_PERCENTILE NUMBER(5,2), 
	LOAD_DATE DATE, 
	EFFECTIVE_DATE DATE, 
	END_DATE DATE
  )
/
