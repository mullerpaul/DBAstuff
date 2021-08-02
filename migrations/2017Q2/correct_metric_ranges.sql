--- First delete bogus test data.  
-- At this time, only three metrics have the correct range scores entered.
DELETE FROM default_metric_conversion
 WHERE metric_id NOT IN (29, 30, 31)
/

----- metric: 10 - candidates submitted - not in metric planner - ranges made up by Paul
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 10, 2, 1000, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 10, 1, 2, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 10, 0, 1, 'F', 0, NULL)
/

----- metric: 11 - candidates placed - ranges from metric planner
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 11, 8, 10000, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 11, 6, 8, 'B', 35, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 11, 4, 6, 'C', 25, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 11, 2, 4, 'D', 15, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 11, 0, 2, 'F', 5, NULL)
/

----- metric: 12 - candidates declined - not in metric planner - ranges made up by Paul
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 12, 0, 1, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 12, 1, 2, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 12, 2, 5, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 12, 5, 10, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 12, 10, 10000, 'F', 10, NULL)
/


----- metric: 13 - avg candidates per opportunity - not in metric planner - ranges made up by Paul
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 13, 4, 10000, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 13, 2, 4, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 13, 1, 2, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 13, 0, 1, 'F', 0, NULL)
/


----- metric: 14 - acceptance rate - from metric planner
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 14, 0.98, 1.1, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 14, 0.97, 0.98, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 14, 0.96, 0.97, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 14, 0.93, 0.96, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 14, 0, 0.93, 'F', 10, NULL)
/


----- metric: 15 - submit to hire ratio - from metric planner - (had to invert)
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 15, 0.1, 1.1, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 15, 0.067, 0.1, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 15, 0.05, 0.067, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 15, 0.04, 0.05, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 15, 0, 0.04, 'F', 10, NULL)
/


----- metric: 16 - unfavorable terminations - not in metric planner - ranges made up by Paul 
-- Unfavorable termination RATIO is in the metric planner and is probably a better metric than this simple count.
-- We may want to eliminate this one from the tables AND from the score queries.
-- But since it is in the score queries, I'll leave it for now in order to avoid changing the SQL.
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 16, 0, 1, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 16, 1, 2, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 16, 2, 5, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 16, 5, 10000, 'F', 10, NULL)
/


----- metric: 17 - interview rating - from metric planner
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 17, 4, 10000, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 17, 3, 4, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 17, 2, 3, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 17, 1, 2, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 17, 0, 1, 'F', 10, NULL)
/


----- metric: 18 interview to hire ratio - from metric planner - (had to invert)
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 18, .25, 1, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 18, 0.143, 0.25, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 18, 0.1, 0.143, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 18, 0.067, 0.1, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 18, 0, 0.067, 'F', 10, NULL)
/


----- metric: 19 - avg time to fill (days) - not in metric planner - ranges made up by Paul 
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 19, 0, 2, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 19, 2, 4, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 19, 4, 8, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 19, 8, 14, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 19, 14, 10000, 'F', 10, NULL)
/


----- metric: 20 avg first candidate response time (calendar days) - from metric planner
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 20, 0, 1, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 20, 1, 2, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 20, 2, 3, 'C', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 20, 3, 4, 'D', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 20, 4, 10000, 'F', 0, NULL)
/


----- metric: 21 - avg interview response time (days) - from metric planner
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 21, 0, 2, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 21, 2, 3, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 21, 3, 4, 'C', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 21, 4, 5, 'D', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 21, 5, 10000, 'F', 0, NULL)
/


----- metric: 22 - avg offer response time (days)
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 22, 0, 2, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 22, 2, 3, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 22, 3, 4, 'C', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 22, 4, 5, 'D', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 22, 5, 10000, 'F', 0, NULL)
/


----- metric: 23 - placements over request rate - from metric planner
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 23, 0, 1, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 23, 1, 2, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 23, 2, 3, 'C', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 23, 3, 4, 'D', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 23, 4, 10000, 'F', 0, NULL)
/


----- metric: 24 - rate competitiveness - from metric planner - (had to convert from %)
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 24, 0.98, 1.1, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 24, 0.97, 0.98, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 24, 0.96, 0.97, 'C', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 24, 0.95, 0.96, 'D', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 24, 0, 0.95, 'F', 0, NULL)
/


----- metric: 25 - avg markup percentage - not in metric planner - made up by Paul
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 25, 0, 1.2, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 25, 1.2, 1.5, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 25, 1.5, 2, 'C', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 25, 2, 2.5, 'D', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 25, 2.5, 10000, 'F', 0, NULL)
/


----- metric: 26 - requisitions received - not in metric planner - made up by Paul
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 26, 5, 10000, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 26, 3, 5, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 26, 2, 3, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 26, 0, 2, 'D', 20, NULL)
/


----- metric: 27 - placements not over req rate - no ranges in metric planner - made up by Paul
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 3, 10000, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 2, 3, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 0, 2, 'D', 20, NULL)
/


----- metric: 28 - offers accepted - not in metric planner - made up by Paul
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 28, 3, 10000, 'A', 50, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 28, 2, 3, 'B', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 28, 1, 2, 'C', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 28, 0, 1, 'F', 10, NULL)
/



--- Thats all folks!
COMMIT
/

