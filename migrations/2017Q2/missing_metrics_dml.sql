-- We will probably get rid of the columns:
--   METRIC.enabled_flag
--   DEFAULT_METRIC_CONVERSION.range_score_conversion_factor
-- in the near future.  But they are there now, so I'm leeaving them in this DML script.

-- also, METRIC.default_coefficient will be populated in a later script such that 
-- every metric in a metric category has the same weight - probably like this:
--    10 / # of metrics in category
-- That will be a separate script.

-- I've hardcoded metric IDs in this script.  We DO have a sequence for METRIC; but I'm not
-- using it here because I worry that the script may be run multiple times - esp in DV07.
-- But not only that, since the score queries have the metric IDs hardcoded in the SQL, 
-- I really don't want to risk having to edit those qqueries to change metric IDs!


----- requisitions received
INSERT INTO metric 
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES 
  (26, 'requisitions received', 'efficiency', 'Y', 0, 'The number of requisitions released to the supplier in this interval.')
/
-- I made up the number of ranges, the range boundries, and the range scores!  we have to get better numbers from somewhere. 
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 26, 0, 4, 'B', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 26, 4, 10000, 'A', 30, NULL)
/


----- placements not over req rate
INSERT INTO metric 
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES 
  (27, 'placements not over req rate', 'cost', 'Y', 0, 'The number of placements which were NOT above the rate on the requisition.')
/
-- I made up the number of ranges, the range boundries, and the range scores!  we have to get better numbers from somewhere. 
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 0, 2, 'B', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 2, 10000, 'A', 40, NULL)
/


----- offer accepted count
INSERT INTO metric 
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES 
  (28, 'offers accepted', 'candidate quality', 'Y', 0, 'The number of offers which were accepted by candidates.')
/
-- I made up the number of ranges, the range boundries, and the range scores!  we have to get better numbers from somewhere. 
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 28, 0, 2, 'B', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 28, 2, 10000, 'A', 40, NULL)
/


----- supplier response ratio
INSERT INTO metric 
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES 
  (29, 'supplier response ratio', 'efficiency', 'Y', 0, 'The percentage of requests where the supplier submitted at least one candidate.')
/
-- These I copied from the metric planner sheet!
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 29, 0, 0.6, 'F', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 29, 0.6, 0.7, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 29, 0.7, 0.8, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 29, 0.8, 0.9, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 29, 0.9, 2, 'A', 50, NULL)
/


----- offer rejected ratio
INSERT INTO metric 
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES 
  (30, 'offer rejected ratio', 'candidate quality', 'Y', 0, 'The percentage of offers which were rejected by candidates.')
/
-- These I copied from the metric planner sheet!
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 30, 0, 0.05, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 30, 0.05, 0.06, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 30, 0.06, 0.15, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 30, 0.15, 0.20, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 30, 0.20, 2, 'F', 10, NULL)
/


----- unfavorable_termination_ratio
INSERT INTO metric 
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES 
  (31, 'unfavorable termination ratio', 'candidate quality', 'Y', 0, 'The percentage of assignments which ended in an unfavorable way.')
/
-- These I copied from the metric planner sheet!
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 31, 0, 0.0001, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 31, 0.0001, 0.02, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 31, 0.02, 0.03, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 31, 0.03, 0.04, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 31, 0.04, 2, 'F', 10, NULL)
/

  
COMMIT
/

