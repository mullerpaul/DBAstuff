--- FIX for msvc-1179

-- step 1: delete the 3 default metrics 
DELETE FROM default_metric_conversion 
 WHERE metric_id = 27
/

-- step 2: load corrected defaults
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 4, 10000, 'A', 40, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 3, 4, 'B', 30, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 2, 3, 'C', 20, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 1, 2, 'D', 10, NULL)
/
INSERT INTO default_metric_conversion 
  (default_metric_conversion_id, metric_id, greater_than_or_equal, less_than, range_grade, range_score, range_score_conversion_factor) 
VALUES 
  (default_metric_conversion_seq.nextval, 27, 0, 1, 'F', 0, NULL)
/


-- step 3: wipe existing client child settings (number of defaults x number of clients)
DELETE FROM client_metric_conversion 
 WHERE client_metric_coefficient_guid IN (SELECT client_metric_coefficient_guid
                                            FROM client_metric_coefficient
										   WHERE metric_id = 27)
/

-- step 4: wipe existing client parent settings 
DELETE FROM client_metric_coefficient 
 WHERE metric_id = 27
/

-- step 5: reload client settings from defaults in client_metric_coefficient (parent) and client_metric_conversion (child)
DECLARE
  lv_bulk_session_guid RAW(16) := sys_guid();
BEGIN  
  FOR j IN (SELECT DISTINCT client_guid
              FROM supplier_release) LOOP

    client_metric_settings_util.copy_defaults_to_client ( pi_client_guid  => j.client_guid,
                                                          pi_session_guid => lv_bulk_session_guid,
                                                          pi_request_guid => sys_guid() );    
  END LOOP;

END;
/


--  all done!
COMMIT
/

  
