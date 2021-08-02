ALTER TABLE client_metric_coefficient
add constraint client_metric_coefficient_ck01
check (metric_coefficient between 0 and 10)
/

