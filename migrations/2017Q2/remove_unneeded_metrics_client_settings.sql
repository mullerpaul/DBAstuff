--- delete these unneeded metrics from the 
--- client_metric_conversion and client_metric_coefficient tables.

-- total_candidates_submitted		10
-- avg_candidates_per_opportunity	13
-- unfavorable_terminations		16
-- avg_time_to_fill_days		19
-- requisitions_received		26
-- offer_accepted_count			28
-- candidates placed 			11


DELETE FROM client_metric_conversion
 WHERE client_metric_coefficient_guid IN 
     (SELECT client_metric_coefficient_guid 
        FROM client_metric_coefficient
       WHERE metric_id IN (10, 13, 16, 19, 26, 28, 11))
/

DELETE FROM client_metric_coefficient
 WHERE metric_id IN (10, 13, 16, 19, 26, 28, 11)
/

COMMIT
/

