ALTER TABLE metric
add constraint metric_ck03
check (default_coefficient between 0 and 10)
/
