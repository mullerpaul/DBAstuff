

---- Create rate and time-to-fill benchmarks table and comments
-- This final table does NOT store text attributes for location or job info.  Instead,
-- processes using this table should use the job and place IDs to JOIN to the reference 
-- tables for those topics.
-- Also, LOAD_DATE should hold the date the data was loaded into THIS table.
CREATE TABLE rate_and_ttf_benchmarks
 (benchmark_type           VARCHAR2(40)       NOT NULL, 
  std_job_category_id      NUMBER             NOT NULL, 
  std_occupation_id         NUMBER             NOT NULL, 
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
COMMENT ON TABLE rate_and_ttf_benchmarks IS 'IQN Contingent Workforce Benchmarks'
/

-- column comments
COMMENT ON COLUMN rate_and_ttf_benchmarks.benchmark_type IS 'Benchmark Type (e.g. Time To Fill, U.S. Rate Benchmarks)'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.std_job_category_id IS 'Join key to the Standard Job Categories dataset'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.std_occupation_id IS 'Join key to the Standard Occupation dataset'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.place_id IS 'Join key to the Place dataset'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.unit IS 'Unit of Measure for the Benchmark Value'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.benchmark_25_percentile IS 'Quartile boundary - 25% of observations are below this value'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.benchmark_50_percentile IS 'Quartile boundary - 50% of observations are below this value (median)'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.benchmark_75_percentile IS 'Quartile boundary - 75% of observations are below this value'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.load_date IS 'Benchmark Load Date'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.effective_date IS 'Date when the benchmark became or will become effective'
/
COMMENT ON COLUMN rate_and_ttf_benchmarks.end_date IS 'Date when the benchmark value ceased or will cease being effective'
/

