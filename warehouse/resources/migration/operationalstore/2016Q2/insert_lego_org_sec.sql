INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name)  
VALUES
 ('LEGO_ORG_SECURITY','USPROD','SQL TOGGLE','TWICE DAILY', 2, 1,
  'NOLOGGING', 'ORG_SECURITY_IQP1','ORG_SECURITY_IQP2','ORG_SECURITY_IQP')
/

COMMIT
/
