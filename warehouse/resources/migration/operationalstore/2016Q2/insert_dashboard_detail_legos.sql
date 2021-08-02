INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name, refresh_procedure_name)
VALUES  
 ('LEGO_UPCOMING_ENDS_DETAIL','USPROD','PROC TOGGLE','TWICE DAILY', 11, 2,
  'NOLOGGING', 'UPCOMING_ENDS_DETAIL_IQP1', 'UPCOMING_ENDS_DETAIL_IQP2', 'UPCOMING_ENDS_DETAIL_IQP', 
  'lego_dashboard_refresh.load_upcoming_ends_detail')
/

INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name, refresh_procedure_name)
VALUES  
 ('LEGO_REQ_BY_STATUS_DETAIL','USPROD','PROC TOGGLE','TWICE DAILY', 8, 2,
  'NOLOGGING', 'REQ_BY_STATUS_DETAIL_IQP1', 'REQ_BY_STATUS_DETAIL_IQP2', 'REQ_BY_STATUS_DETAIL_IQP', 
  'lego_dashboard_refresh.load_req_by_status_detail')
/

-- not inserting the YOY assignment count lego yet.  Not sure if its needed.

COMMIT
/

