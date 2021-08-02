--- delete these unneeded metrics from the metric and default_metric_conversion_tables.
-- total_candidates_submitted		10
-- avg_candidates_per_opportunity	13
-- unfavorable_terminations		16
-- avg_time_to_fill_days		19
-- requisitions_received		26
-- offer_accepted_count			28
-- candidates_placed			11


DELETE FROM default_metric_conversion
 WHERE metric_id IN (10, 13, 16, 19, 26, 28, 11)
/

DELETE FROM metric
 WHERE metric_id IN (10, 13, 16, 19, 26, 28, 11)
/

COMMIT
/

