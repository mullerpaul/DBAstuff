INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_DATE_TREND', 'USPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 27, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_date_trend.load_date_trends}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_DATE_TREND', 'WFPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 27, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_date_trend.load_date_trends}')
/
