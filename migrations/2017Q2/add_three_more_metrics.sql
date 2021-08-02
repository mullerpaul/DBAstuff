----- submit to interview ratio
INSERT INTO metric 
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES 
  (32, 'submit to interview ratio', 'candidate quality', 'Y', 1, 'The ratio of interviewed candidates to all submitted candidates.')
/
-- There were 5 ranges in the metric planner; but none had range boundies.  I used standard "school-like" 90+ = A, 80+ = B, etc.
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 32, 0.9, 1.1, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 32, 0.8, 0.9, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 32, 0.7, 0.8, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 32, 0.6, 0.7, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 32, 0, 0.6, 'F', 10, NULL)
/


----- submit to request rate variance
INSERT INTO metric 
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES 
  (33, 'submit to request rate variance', 'cost', 'Y', 3, 'The average percent variation between submitted and requested rates')
/
-- There were 5 ranges in the metric planner; but none had range boundies.  I used the ones from offer accepted to request rate var.
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 33, -100, 2, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 33, 2, 7, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 33, 7, 13, 'C', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 33, 13, 100, 'D', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 33, 100, 10000, 'F', 0, NULL)
/


----- offer accepted to request rate variance
INSERT INTO metric 
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES 
  (34, 'offer accepted to request rate variance', 'cost', 'Y', 3, 'The average percent variation between the offer accepted rate and the client requested rate.')
/
-- These copied from the metric planner sheet!
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 34, -100, 2, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 34, 2, 7, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 34, 7, 13, 'C', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 34, 13, 100, 'D', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 34, 100, 10000, 'F', 0, NULL)
/


----
COMMIT
/

