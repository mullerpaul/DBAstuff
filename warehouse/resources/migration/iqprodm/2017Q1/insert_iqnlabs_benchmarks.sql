insert into rate_and_ttf_benchmarks
select s.benchmark_type, s.std_job_category_id, s.std_occupation_id,
dm.std_place_id, s.unit, s.benchmark_25_percentile,
s.benchmark_50_percentile,
s.benchmark_75_percentile,
s.load_date, s.effective_date, s.end_date
from sos_iqnlabs_benchmarks s, dm_places dm
where dm.cmsa_code = s.cmsa_code
/
COMMIT
/
drop table sos_iqnlabs_benchmarks
/


