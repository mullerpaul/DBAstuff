INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name, refresh_procedure_name)
VALUES  
 ('LEGO_JOB_RATES','USPROD','SQL TOGGLE','TWICE DAILY', 8, 1, 'NOLOGGING', 'JOB_RATES_IQP1', 'JOB_RATES_IQP2', 'JOB_RATES_IQP', NULL)
/
INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name, refresh_procedure_name)
VALUES  
 ('LEGO_JOB_RATES','WFPROD','SQL TOGGLE','TWICE DAILY', 8, 1, 'NOLOGGING', 'JOB_RATES_WF1', 'JOB_RATES_WF2', 'JOB_RATES_IQP', NULL)
/