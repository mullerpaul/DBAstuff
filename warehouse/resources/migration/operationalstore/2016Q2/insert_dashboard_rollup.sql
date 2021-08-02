INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name, refresh_procedure_name)
VALUES  
 ('LEGO_UPCOMING_ENDS_ROW_ROLLUP','USPROD','PROC TOGGLE','TWICE DAILY', 11, 3,
  'NOLOGGING',    -- perhaps make this an IOT in the future
  'UPCOMING_ENDS_ROW_ROLLUP_IQP1', 'UPCOMING_ENDS_ROW_ROLLUP_IQP2', 'UPCOMING_ENDS_ROW_ROLLUP_IQP', 
  'lego_dashboard_refresh.load_upcoming_ends_row_rollup')
/
INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name, refresh_procedure_name)
VALUES  
 ('LEGO_UPCOMING_ENDS_ORG_ROLLUP','USPROD','PROC TOGGLE','TWICE DAILY', 11, 3,
  'NOLOGGING',    -- perhaps make this an IOT in the future
  'UPCOMING_ENDS_ORG_ROLLUP_IQP1', 'UPCOMING_ENDS_ORG_ROLLUP_IQP2', 'UPCOMING_ENDS_ORG_ROLLUP_IQP', 
  'lego_dashboard_refresh.load_upcoming_ends_org_rollup')
/

INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name, refresh_procedure_name)
VALUES  
 ('LEGO_REQ_BY_STATUS_ROW_ROLLUP','USPROD','PROC TOGGLE','TWICE DAILY', 8, 3,
  'NOLOGGING',    -- perhaps make this an IOT in the future
  'REQ_BY_STATUS_ROW_ROLLUP_IQP1', 'REQ_BY_STATUS_ROW_ROLLUP_IQP2', 'REQ_BY_STATUS_ROW_ROLLUP_IQP', 
  'lego_dashboard_refresh.load_req_by_status_row_rollup')
/
INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name, refresh_procedure_name)
VALUES  
 ('LEGO_REQ_BY_STATUS_ORG_ROLLUP','USPROD','PROC TOGGLE','TWICE DAILY', 8, 3,
  'NOLOGGING',    -- perhaps make this an IOT in the future
  'REQ_BY_STATUS_ORG_ROLLUP_IQP1', 'REQ_BY_STATUS_ORG_ROLLUP_IQP2', 'REQ_BY_STATUS_ORG_ROLLUP_IQP', 
  'lego_dashboard_refresh.load_req_by_status_org_rollup')
/

-- not inserting the YOY assignment count legos yet.  Not sure if they are needed.

COMMIT
/

