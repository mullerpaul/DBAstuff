CREATE INDEX t_review_benchmarks_idx01
ON t_review_benchmarks (benchmark_type, std_job_category_id, std_job_title_id, place_id)
COMPRESS 2
/

CREATE INDEX iqnlabs_benchmarks_idx01
ON iqnlabs_benchmarks (benchmark_type, std_job_category_id, std_job_title_id, place_id)
COMPRESS 2
/


