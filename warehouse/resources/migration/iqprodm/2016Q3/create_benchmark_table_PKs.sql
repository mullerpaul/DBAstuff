-- I expect that we will always be querying this table with by specifying ALL of these indexed columns.
-- As of now, benchmark_type and std_job_category_id have 2 and 6 distinct values over millions of rows.
-- So given those two assumptions, I'll create these indexes with four columns and those first two compressed.  
-- we can re-model if necessary later.
CREATE INDEX t_review_benchmarks_idx01
ON t_review_benchmarks (benchmark_type, std_job_category_id, std_job_title_id, place_id)
COMPRESS 2 
/

CREATE INDEX iqnlabs_benchmarks_idx01
ON iqnlabs_benchmarks (benchmark_type, std_job_category_id, std_job_title_id, place_id)
COMPRESS 2
/


