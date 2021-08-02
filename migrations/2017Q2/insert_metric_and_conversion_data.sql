INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'candidates submitted', 'candidate quality', 'Y', 0.2, 'Number of candidates submitted by a supplier.')
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 0 ,5, 'F', 0, NULL)
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 5 ,10, 'D', 20, NULL)
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 10 ,15, 'C', 50, NULL)
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 15 ,20, 'B', 80, NULL)
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 20 ,500, 'A', 120, NULL)
/

---
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'candidates placed', 'candidate quality', 'Y', 0.5, 'Number of candidates placed into positions.')
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 0 ,6, 'C', 10, NULL)
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 6 ,15, 'B', 50, NULL)
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 15 ,500, 'A', 150, NULL)
/

---
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'candidates declined', 'candidate quality', 'N', 0, ' Number of candidates declined to a position for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'cands per opportunity', 'candidate quality', 'N', 0, ' Average number of candidates submitted to a single position for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'acceptance rate', 'candidate quality', 'N', 0, ' Candidates accepted over candidates submitted for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'submit hire ratio', 'candidate quality', 'N', 0, ' Candidates hired over candidates submitted for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'unfavorable terminations', 'candidate quality', 'N', 0, ' Number of positions unfavorably terminated for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'interview rating', 'candidate quality', 'N', 0, ' Average interview rating for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'interview to hire ratio', 'candidate quality', 'N', 0, ' Candidates hired over candidates interviewed for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'time to fill', 'efficiency', 'N', 0, ' Average time to fill a position for a supplier.')
/

---
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'first cand response time', 'efficiency', 'Y', 0.3, ' Average time before first response by a candidate for a req for a supplier.')
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 0 ,2, 'A', 400, NULL)
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 2 ,4, 'B', 200, NULL)
/
INSERT INTO default_metric_conversion (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES (default_metric_conversion_seq.nextval, metric_seq.currval, 4 ,60, 'C', 80, NULL)
/

---
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'interview response time', 'efficiency', 'N', 0, ' Average time between an interview requested and scheduled for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'offer response time', 'efficiency', 'N', 0, ' Average time between an offer made and accepted for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'placements over req rate', 'cost', 'N', 0, ' Number of placements for a supplier where candidate pay is over the request rate.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'rate competitiveness', 'cost', 'N', 0, ' Average percent variation between offer accepted rate and requested rate for a supplier.')
/
INSERT INTO metric (metric_id, metric_name, metric_category, enabled_flag, default_coefficient, description) 
VALUES (metric_seq.nextval, 'markup percentage', 'cost', 'N', 0, ' Average percent markup from pay rate to bill rate.')
/

COMMIT
/

