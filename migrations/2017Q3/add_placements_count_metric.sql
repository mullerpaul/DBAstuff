----- placements count metric
INSERT INTO metric
  (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description)
VALUES
  (35, 'placements count', 'candidate quality', 'Y', 1, 'The number of placements for each supplier.')
/
INSERT INTO default_metric_conversion
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor)
VALUES
  (default_metric_conversion_seq.nextval, 35, 8, 100000, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor)
VALUES
  (default_metric_conversion_seq.nextval, 35, 6, 8, 'B', 35, NULL)
/
INSERT INTO default_metric_conversion
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor)
VALUES
  (default_metric_conversion_seq.nextval, 35, 4, 6, 'C', 25, NULL)
/
INSERT INTO default_metric_conversion
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor)
VALUES
  (default_metric_conversion_seq.nextval, 35, 2, 4, 'D', 15, NULL)
/
INSERT INTO default_metric_conversion
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor)
VALUES
  (default_metric_conversion_seq.nextval, 35, 0, 2, 'F', 5, NULL)
/

----
COMMIT
/
