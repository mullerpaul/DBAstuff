-- I expect that we will always be querying this table with by specifying ALL of these indexed columns.
-- As of now, benchmark_type and std_job_category_id have 2 and 6 distinct values over millions of rows.
-- So given those two assumptions, I'll create these indexes with four columns and those first two compressed.  
-- we can re-model if necessary later.
CREATE INDEX rate_and_ttf_benchmarks_idx01
ON rate_and_ttf_benchmarks (benchmark_type, std_job_category_id, std_occupation_id, place_id)
COMPRESS 2
/


 
