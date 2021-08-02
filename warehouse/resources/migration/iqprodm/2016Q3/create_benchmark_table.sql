-- first drop tables in case they already exist
DECLARE
  le_table_doesnt_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_table_doesnt_exist, -942);

BEGIN
  BEGIN
    EXECUTE IMMEDIATE ('drop table t_review_benchmarks');
  EXCEPTION
    WHEN le_table_doesnt_exist THEN
      NULL;
  END;

  BEGIN
    EXECUTE IMMEDIATE ('drop table iqnlabs_benchmarks');
  EXCEPTION
    WHEN le_table_doesnt_exist THEN
      NULL;
  END;

END;
/
  
---- Create T_REVIEW_BENCHMARKS table
-- This table allows the denormalized storing of human-readable job category, job title, 
-- and place attributes for the purpose of manual data inspection.
-- There is no load date and the effective and end dates are optional.
CREATE TABLE t_review_benchmarks
 (benchmark_type         VARCHAR2(40)       NOT NULL, 
  std_job_category_id    NUMBER             NOT NULL, 
  std_job_category_desc  VARCHAR2(250 CHAR) NOT NULL,
  std_job_title_id       NUMBER             NOT NULL,
  std_job_title_desc     VARCHAR2(250 CHAR) NOT NULL, 
  place_id               NUMBER             NOT NULL,
  place_name             VARCHAR2(512)      NOT NULL,
  primary_state          VARCHAR2(2)        NOT NULL, 
  primary_city           VARCHAR2(40)       NOT NULL, 
  unit                   VARCHAR2(10)       NOT NULL,
  percentile_value       NUMBER(3)          NOT NULL,
  benchmark_value        NUMBER(5,2),
  effective_date         DATE,
  end_date               DATE)
/

---- Create iqnlabs_benchmarks table and comments
-- This final table does NOT store text attributes for location or job info.  Instead,
-- processes using this table should use the job and place IDs to JOIN to the reference 
-- tables for those topics.
-- Also, LOAD_DATE should hold the date the data was loaded into THIS table.
CREATE TABLE iqnlabs_benchmarks
 (benchmark_type           VARCHAR2(40)       NOT NULL, 
  std_job_category_id      NUMBER             NOT NULL, 
  std_job_title_id         NUMBER             NOT NULL, 
  place_id                 NUMBER             NOT NULL,
  unit                     VARCHAR2(10)       NOT NULL,
  benchmark_25_percentile  NUMBER(5,2),
  benchmark_50_percentile  NUMBER(5,2),
  benchmark_75_percentile  NUMBER(5,2),        
  load_date                DATE               NOT NULL, 
  effective_date           DATE               NOT NULL,
  end_date                 DATE        )  -- NULL here means the row is currently effective with no end date in sight.  
/

-- table comment
COMMENT ON TABLE iqnlabs_benchmarks IS 'IQN Contingent Workforce Benchmarks'
/

-- column comments
COMMENT ON COLUMN iqnlabs_benchmarks.benchmark_type IS 'Benchmark Type (e.g. Time To Fill, U.S. Rate Benchmarks)'
/
COMMENT ON COLUMN iqnlabs_benchmarks.std_job_category_id IS 'Join key to the Standard Job Categories dataset'
/
COMMENT ON COLUMN iqnlabs_benchmarks.std_job_title_id IS 'Join key to the Standard Job Title dataset'
/
COMMENT ON COLUMN iqnlabs_benchmarks.place_id IS 'Join key to the Place dataset'
/
COMMENT ON COLUMN iqnlabs_benchmarks.unit IS 'Unit of Measure for the Benchmark Value'
/
COMMENT ON COLUMN iqnlabs_benchmarks.benchmark_25_percentile IS 'Quartile boundary - 25% of observations are below this value'
/
COMMENT ON COLUMN iqnlabs_benchmarks.benchmark_50_percentile IS 'Quartile boundary - 50% of observations are below this value (median)'
/
COMMENT ON COLUMN iqnlabs_benchmarks.benchmark_75_percentile IS 'Quartile boundary - 75% of observations are below this value'
/
COMMENT ON COLUMN iqnlabs_benchmarks.load_date IS 'Benchmark Load Date'
/
COMMENT ON COLUMN iqnlabs_benchmarks.effective_date IS 'Date when the benchmark became or will become effective'
/
COMMENT ON COLUMN iqnlabs_benchmarks.end_date IS 'Date when the benchmark value ceased or will cease being effective'
/

