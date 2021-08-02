INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PERSON', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 1, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PERSON_1', 'LEGO_PERSON_2', 'LEGO_PERSON', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PERSON', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 1, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PERSON_1', 'LEGO_PERSON_2', 'LEGO_PERSON', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PERSON', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 1, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PERSON_1', 'LEGO_PERSON_2', 'LEGO_PERSON', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MANAGED_CAC', 'USPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_MANAGED_CAC1', 'LEGO_MANAGED_CAC2', 'LEGO_MANAGED_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MANAGED_CAC', 'WFPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_MANAGED_CAC1', 'LEGO_MANAGED_CAC2', 'LEGO_MANAGED_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MANAGED_CAC', 'EMEA', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_MANAGED_CAC1', 'LEGO_MANAGED_CAC2', 'LEGO_MANAGED_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MANAGED_PERSON', 'USPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_MANAGED_PERSON_1', 'LEGO_MANAGED_PERSON_2', 'LEGO_MANAGED_PERSON', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MANAGED_PERSON', 'WFPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_MANAGED_PERSON_1', 'LEGO_MANAGED_PERSON_2', 'LEGO_MANAGED_PERSON', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MANAGED_PERSON', 'EMEA', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_MANAGED_PERSON_1', 'LEGO_MANAGED_PERSON_2', 'LEGO_MANAGED_PERSON', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_ASSIGNMENT', 'USPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SECURE_ASSIGNMENT_1', 'LEGO_SECURE_ASSIGNMENT_2', 'LEGO_SECURE_ASSIGNMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_ASSIGNMENT', 'WFPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SECURE_ASSIGNMENT_1', 'LEGO_SECURE_ASSIGNMENT_2', 'LEGO_SECURE_ASSIGNMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_ASSIGNMENT', 'EMEA', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SECURE_ASSIGNMENT_1', 'LEGO_SECURE_ASSIGNMENT_2', 'LEGO_SECURE_ASSIGNMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_JOB', 'USPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SECURE_JOB_1', 'LEGO_SECURE_JOB_2', 'LEGO_SECURE_JOB', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_JOB', 'WFPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SECURE_JOB_1', 'LEGO_SECURE_JOB_2', 'LEGO_SECURE_JOB', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_JOB', 'EMEA', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SECURE_JOB_1', 'LEGO_SECURE_JOB_2', 'LEGO_SECURE_JOB', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_PROJECT_AGREEMENT', 'USPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SECURE_PROJECT_AGREE_1', 'LEGO_SECURE_PROJECT_AGREE_2', 'LEGO_SECURE_PROJECT_AGREEMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_PROJECT_AGREEMENT', 'WFPROD', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SECURE_PROJECT_AGREE_1', 'LEGO_SECURE_PROJECT_AGREE_2', 'LEGO_SECURE_PROJECT_AGREEMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_PROJECT_AGREEMENT', 'EMEA', 'SQL TOGGLE', 'EVERY FOUR HOURS', 2, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SECURE_PROJECT_AGREE_1', 'LEGO_SECURE_PROJECT_AGREE_2', 'LEGO_SECURE_PROJECT_AGREEMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGN_MANAGED_CAC', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSIGN_MANAGED_CAC1', 'LEGO_ASSIGN_MANAGED_CAC2', 'LEGO_ASSIGN_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_assign_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGN_MANAGED_CAC', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSIGN_MANAGED_CAC1', 'LEGO_ASSIGN_MANAGED_CAC2', 'LEGO_ASSIGN_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_assign_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGN_MANAGED_CAC', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSIGN_MANAGED_CAC1', 'LEGO_ASSIGN_MANAGED_CAC2', 'LEGO_ASSIGN_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_assign_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_MANAGED_CAC', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_MANAGED_CAC1', 'LEGO_EXPENSE_MANAGED_CAC2', 'LEGO_EXPENSE_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_expense_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_MANAGED_CAC', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_MANAGED_CAC1', 'LEGO_EXPENSE_MANAGED_CAC2', 'LEGO_EXPENSE_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_expense_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_MANAGED_CAC', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_MANAGED_CAC1', 'LEGO_EXPENSE_MANAGED_CAC2', 'LEGO_EXPENSE_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_expense_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_MANAGED_CAC', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_JOB_MANAGED_CAC1', 'LEGO_JOB_MANAGED_CAC2', 'LEGO_JOB_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_job_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_MANAGED_CAC', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_JOB_MANAGED_CAC1', 'LEGO_JOB_MANAGED_CAC2', 'LEGO_JOB_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_job_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_MANAGED_CAC', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_JOB_MANAGED_CAC1', 'LEGO_JOB_MANAGED_CAC2', 'LEGO_JOB_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_job_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_MANAGED_CAC', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PA_MANAGED_CAC1', 'LEGO_PA_MANAGED_CAC2', 'LEGO_PA_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_pa_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_MANAGED_CAC', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PA_MANAGED_CAC1', 'LEGO_PA_MANAGED_CAC2', 'LEGO_PA_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_pa_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_MANAGED_CAC', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PA_MANAGED_CAC1', 'LEGO_PA_MANAGED_CAC2', 'LEGO_PA_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_pa_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_MANAGED_CAC', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_MANAGED_CAC1', 'LEGO_TIMECARD_MANAGED_CAC2', 'LEGO_TIMECARD_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_timecard_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_MANAGED_CAC', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_MANAGED_CAC1', 'LEGO_TIMECARD_MANAGED_CAC2', 'LEGO_TIMECARD_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_timecard_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_MANAGED_CAC', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_MANAGED_CAC1', 'LEGO_TIMECARD_MANAGED_CAC2', 'LEGO_TIMECARD_MANAGED_CAC', NULL, NULL, q'{lego_slot_security.load_lego_timecard_managed_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_ASSIGNMENT', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, assignment_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, assignment_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_ASSIGNMENT1', 'LEGO_SLOT_ASSIGNMENT2', 'LEGO_SLOT_ASSIGNMENT', NULL, NULL, q'{lego_slot_security.load_lego_slot_assignment}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_ASSIGNMENT', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, assignment_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, assignment_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_ASSIGNMENT1', 'LEGO_SLOT_ASSIGNMENT2', 'LEGO_SLOT_ASSIGNMENT', NULL, NULL, q'{lego_slot_security.load_lego_slot_assignment}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_ASSIGNMENT', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, assignment_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, assignment_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_ASSIGNMENT1', 'LEGO_SLOT_ASSIGNMENT2', 'LEGO_SLOT_ASSIGNMENT', NULL, NULL, q'{lego_slot_security.load_lego_slot_assignment}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_EXPENSE_REPORT', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, expense_report_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, expense_report_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_EXPENSE_REPORT1', 'LEGO_SLOT_EXPENSE_REPORT2', 'LEGO_SLOT_EXPENSE_REPORT', NULL, NULL, q'{lego_slot_security.load_lego_slot_expense_report}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_EXPENSE_REPORT', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, expense_report_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, expense_report_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_EXPENSE_REPORT1', 'LEGO_SLOT_EXPENSE_REPORT2', 'LEGO_SLOT_EXPENSE_REPORT', NULL, NULL, q'{lego_slot_security.load_lego_slot_expense_report}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_EXPENSE_REPORT', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, expense_report_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, expense_report_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_EXPENSE_REPORT1', 'LEGO_SLOT_EXPENSE_REPORT2', 'LEGO_SLOT_EXPENSE_REPORT', NULL, NULL, q'{lego_slot_security.load_lego_slot_expense_report}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_JOB', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, job_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, job_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_JOB1', 'LEGO_SLOT_JOB2', 'LEGO_SLOT_JOB', NULL, NULL, q'{lego_slot_security.load_lego_slot_job}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_JOB', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, job_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, job_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_JOB1', 'LEGO_SLOT_JOB2', 'LEGO_SLOT_JOB', NULL, NULL, q'{lego_slot_security.load_lego_slot_job}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_JOB', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, job_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, job_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_JOB1', 'LEGO_SLOT_JOB2', 'LEGO_SLOT_JOB', NULL, NULL, q'{lego_slot_security.load_lego_slot_job}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_PROJECT_AGREEMENT', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, project_agreement_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, project_agreement_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_PROJECT_AGREEMENT1', 'LEGO_SLOT_PROJECT_AGREEMENT2', 'LEGO_SLOT_PROJECT_AGREEMENT', NULL, NULL, q'{lego_slot_security.load_lego_slot_proj_agreement}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_PROJECT_AGREEMENT', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, project_agreement_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, project_agreement_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_PROJECT_AGREEMENT1', 'LEGO_SLOT_PROJECT_AGREEMENT2', 'LEGO_SLOT_PROJECT_AGREEMENT', NULL, NULL, q'{lego_slot_security.load_lego_slot_proj_agreement}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_PROJECT_AGREEMENT', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, project_agreement_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, project_agreement_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_PROJECT_AGREEMENT1', 'LEGO_SLOT_PROJECT_AGREEMENT2', 'LEGO_SLOT_PROJECT_AGREEMENT', NULL, NULL, q'{lego_slot_security.load_lego_slot_proj_agreement}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_TIMECARD', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, timecard_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, timecard_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_TIMECARD1', 'LEGO_SLOT_TIMECARD2', 'LEGO_SLOT_TIMECARD', NULL, NULL, q'{lego_slot_security.load_lego_slot_timecard}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_TIMECARD', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, timecard_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, timecard_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_TIMECARD1', 'LEGO_SLOT_TIMECARD2', 'LEGO_SLOT_TIMECARD', NULL, NULL, q'{lego_slot_security.load_lego_slot_timecard}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SLOT_TIMECARD', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 3, q'{(user_id, timecard_id, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (user_id, timecard_id)) ORGANIZATION INDEX COMPRESS NOLOGGING TABLESPACE LEGO_USERS}', NULL, 'LEGO_SLOT_TIMECARD1', 'LEGO_SLOT_TIMECARD2', 'LEGO_SLOT_TIMECARD', NULL, NULL, q'{lego_slot_security.load_lego_slot_timecard}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_INV_ASSGNMT', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 4, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SECURE_INV_ASSGNMT1', 'LEGO_SECURE_INV_ASSGNMT2', 'LEGO_SECURE_INV_ASSGNMT', NULL, NULL, q'{lego_slot_security.load_lego_secure_inv_assgnmt}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_INV_ASSGNMT', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 4, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SECURE_INV_ASSGNMT1', 'LEGO_SECURE_INV_ASSGNMT2', 'LEGO_SECURE_INV_ASSGNMT', NULL, NULL, q'{lego_slot_security.load_lego_secure_inv_assgnmt}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_INV_ASSGNMT', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 4, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SECURE_INV_ASSGNMT1', 'LEGO_SECURE_INV_ASSGNMT2', 'LEGO_SECURE_INV_ASSGNMT', NULL, NULL, q'{lego_slot_security.load_lego_secure_inv_assgnmt}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_INV_PRJ_AGR', 'USPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 4, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SECURE_INV_PRJ_AGR1', 'LEGO_SECURE_INV_PRJ_AGR2', 'LEGO_SECURE_INV_PRJ_AGR', NULL, NULL, q'{lego_slot_security.load_lego_secure_inv_prj_agr}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_INV_PRJ_AGR', 'WFPROD', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 4, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SECURE_INV_PRJ_AGR1', 'LEGO_SECURE_INV_PRJ_AGR2', 'LEGO_SECURE_INV_PRJ_AGR', NULL, NULL, q'{lego_slot_security.load_lego_secure_inv_prj_agr}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SECURE_INV_PRJ_AGR', 'EMEA', 'PROC TOGGLE', 'EVERY FOUR HOURS', 2, 4, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SECURE_INV_PRJ_AGR1', 'LEGO_SECURE_INV_PRJ_AGR2', 'LEGO_SECURE_INV_PRJ_AGR', NULL, NULL, q'{lego_slot_security.load_lego_secure_inv_prj_agr}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_BUS_ORG', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 3, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_BUS_ORG_1', 'LEGO_BUS_ORG_2', 'LEGO_BUS_ORG', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_BUS_ORG', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 3, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_BUS_ORG_1', 'LEGO_BUS_ORG_2', 'LEGO_BUS_ORG', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_BUS_ORG', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 3, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_BUS_ORG_1', 'LEGO_BUS_ORG_2', 'LEGO_BUS_ORG', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_LOCALES_BY_BUYER_ORG', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 3, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_LOCALES_BY_BUYER_ORG1', 'LEGO_LOCALES_BY_BUYER_ORG2', 'LEGO_LOCALES_BY_BUYER_ORG', NULL, NULL, q'{lego_udf_util.load_locales_by_buyer_org}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_LOCALES_BY_BUYER_ORG', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 3, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_LOCALES_BY_BUYER_ORG1', 'LEGO_LOCALES_BY_BUYER_ORG2', 'LEGO_LOCALES_BY_BUYER_ORG', NULL, NULL, q'{lego_udf_util.load_locales_by_buyer_org}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_LOCALES_BY_BUYER_ORG', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 3, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_LOCALES_BY_BUYER_ORG1', 'LEGO_LOCALES_BY_BUYER_ORG2', 'LEGO_LOCALES_BY_BUYER_ORG', NULL, NULL, q'{lego_udf_util.load_locales_by_buyer_org}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_LOCALE_PREF_SCORE', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 3, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_LOCALE_PREF_SCORE1', 'LEGO_LOCALE_PREF_SCORE2', 'LEGO_LOCALE_PREF_SCORE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_LOCALE_PREF_SCORE', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 3, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_LOCALE_PREF_SCORE1', 'LEGO_LOCALE_PREF_SCORE2', 'LEGO_LOCALE_PREF_SCORE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_LOCALE_PREF_SCORE', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 3, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_LOCALE_PREF_SCORE1', 'LEGO_LOCALE_PREF_SCORE2', 'LEGO_LOCALE_PREF_SCORE', NULL, NULL, NULL)
/  
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CURRENCY_CONV_RATES', 'USPROD', 'SQL TOGGLE', 'DAILY', 4, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_CURRENCY_CONV_RATES_1', 'LEGO_CURRENCY_CONV_RATES_2', 'LEGO_CURRENCY_CONV_RATES', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CURRENCY_CONV_RATES', 'WFPROD', 'SQL TOGGLE', 'DAILY', 4, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_CURRENCY_CONV_RATES_1', 'LEGO_CURRENCY_CONV_RATES_2', 'LEGO_CURRENCY_CONV_RATES', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CURRENCY_CONV_RATES', 'EMEA', 'SQL TOGGLE', 'DAILY', 4, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_CURRENCY_CONV_RATES_1', 'LEGO_CURRENCY_CONV_RATES_2', 'LEGO_CURRENCY_CONV_RATES', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ADDRESS', 'USPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 5, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.lego_address_refresh}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ADDRESS', 'WFPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 5, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.lego_address_refresh}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ADDRESS', 'EMEA', 'PROCEDURE ONLY', 'TWICE DAILY', 5, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.lego_address_refresh}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CAC_COLLECTION', 'USPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 6, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.load_lego_cacs_refresh}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CAC_COLLECTION', 'WFPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 6, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.load_lego_cacs_refresh}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CAC_COLLECTION', 'EMEA', 'PROCEDURE ONLY', 'TWICE DAILY', 6, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.load_lego_cacs_refresh}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JAVA_CONSTANT_LOOKUP', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 7, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JAVA_CONSTANT_LOOKUP1', 'LEGO_JAVA_CONSTANT_LOOKUP2', 'LEGO_JAVA_CONSTANT_LOOKUP', NULL, 
q'{PARTITION BY LIST (constant_type)
   (PARTITION p0  VALUES  ('ASGNMT_STATE'),
    PARTITION p1  VALUES  ('RELOCATION_ASS'),
    PARTITION p2  VALUES  ('SOURCING_METHOD'),
    PARTITION p3  VALUES  ('ASSIGNMENT_PHASE'),
    PARTITION p4  VALUES  ('ASGNMT_APPROVAL_STATE'),
    PARTITION p5  VALUES  ('COUNTRY'),
    PARTITION p6  VALUES  ('JOB_CATEGORY'),
    PARTITION p7  VALUES  ('JOB_LEVEL'),
    PARTITION p8  VALUES  ('JOB_PHASE'),
    PARTITION p9  VALUES  ('JOB_STATE'),
    PARTITION p10 VALUES  ('PLACE'),
    PARTITION p11 VALUES  ('SEARCHABLE_ASGNMT_STATE'),
    PARTITION p12 VALUES  ('RES_RATE_BASIS'),
    PARTITION p13 VALUES  ('PAVersionState'),
    PARTITION p14 VALUES  ('PROJECT_AGREEMENT_PHASE'),
    PARTITION p15 VALUES  ('MATCH_STATE'),
    PARTITION p16 VALUES  ('JP'),
    PARTITION p17 VALUES  ('MilestoneStatus'),
    PARTITION p18 VALUES  ('PROJECT_RFX_PHASE'),
    PARTITION p19 VALUES  ('RFxBidType'),
    PARTITION p20 VALUES  ('OVERALL_EVAL'),
    PARTITION p21 VALUES  ('REQUEST_TO_BUY_PHASE'),
    PARTITION p22 VALUES  ('DELIVERABLE_TYPE')
    )}', NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JAVA_CONSTANT_LOOKUP', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 7, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JAVA_CONSTANT_LOOKUP1', 'LEGO_JAVA_CONSTANT_LOOKUP2', 'LEGO_JAVA_CONSTANT_LOOKUP', NULL, 
q'{PARTITION BY LIST (constant_type)
   (PARTITION p0  VALUES  ('ASGNMT_STATE'),
    PARTITION p1  VALUES  ('RELOCATION_ASS'),
    PARTITION p2  VALUES  ('SOURCING_METHOD'),
    PARTITION p3  VALUES  ('ASSIGNMENT_PHASE'),
    PARTITION p4  VALUES  ('ASGNMT_APPROVAL_STATE'),
    PARTITION p5  VALUES  ('COUNTRY'),
    PARTITION p6  VALUES  ('JOB_CATEGORY'),
    PARTITION p7  VALUES  ('JOB_LEVEL'),
    PARTITION p8  VALUES  ('JOB_PHASE'),
    PARTITION p9  VALUES  ('JOB_STATE'),
    PARTITION p10 VALUES  ('PLACE'),
    PARTITION p11 VALUES  ('SEARCHABLE_ASGNMT_STATE'),
    PARTITION p12 VALUES  ('RES_RATE_BASIS'),
    PARTITION p13 VALUES  ('PAVersionState'),
    PARTITION p14 VALUES  ('PROJECT_AGREEMENT_PHASE'),
    PARTITION p15 VALUES  ('MATCH_STATE'),
    PARTITION p16 VALUES  ('JP'),
    PARTITION p17 VALUES  ('MilestoneStatus'),
    PARTITION p18 VALUES  ('PROJECT_RFX_PHASE'),
    PARTITION p19 VALUES  ('RFxBidType'),
    PARTITION p20 VALUES  ('OVERALL_EVAL'),
    PARTITION p21 VALUES  ('REQUEST_TO_BUY_PHASE'),
    PARTITION p22 VALUES  ('DELIVERABLE_TYPE')
    )}', NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JAVA_CONSTANT_LOOKUP', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 7, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JAVA_CONSTANT_LOOKUP1', 'LEGO_JAVA_CONSTANT_LOOKUP2', 'LEGO_JAVA_CONSTANT_LOOKUP', NULL, 
q'{PARTITION BY LIST (constant_type)
   (PARTITION p0  VALUES  ('ASGNMT_STATE'),
    PARTITION p1  VALUES  ('RELOCATION_ASS'),
    PARTITION p2  VALUES  ('SOURCING_METHOD'),
    PARTITION p3  VALUES  ('ASSIGNMENT_PHASE'),
    PARTITION p4  VALUES  ('ASGNMT_APPROVAL_STATE'),
    PARTITION p5  VALUES  ('COUNTRY'),
    PARTITION p6  VALUES  ('JOB_CATEGORY'),
    PARTITION p7  VALUES  ('JOB_LEVEL'),
    PARTITION p8  VALUES  ('JOB_PHASE'),
    PARTITION p9  VALUES  ('JOB_STATE'),
    PARTITION p10 VALUES  ('PLACE'),
    PARTITION p11 VALUES  ('SEARCHABLE_ASGNMT_STATE'),
    PARTITION p12 VALUES  ('RES_RATE_BASIS'),
    PARTITION p13 VALUES  ('PAVersionState'),
    PARTITION p14 VALUES  ('PROJECT_AGREEMENT_PHASE'),
    PARTITION p15 VALUES  ('MATCH_STATE'),
    PARTITION p16 VALUES  ('JP'),
    PARTITION p17 VALUES  ('MilestoneStatus'),
    PARTITION p18 VALUES  ('PROJECT_RFX_PHASE'),
    PARTITION p19 VALUES  ('RFxBidType'),
    PARTITION p20 VALUES  ('OVERALL_EVAL'),
    PARTITION p21 VALUES  ('REQUEST_TO_BUY_PHASE'),
    PARTITION p22 VALUES  ('DELIVERABLE_TYPE')
    )}', NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_CAC', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_CAC_TAB1', 'LEGO_JOB_CAC_TAB2', 'LEGO_JOB_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_CAC', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_CAC_TAB1', 'LEGO_JOB_CAC_TAB2', 'LEGO_JOB_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_CAC', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_CAC_TAB1', 'LEGO_JOB_CAC_TAB2', 'LEGO_JOB_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_CANCEL_TMP', 'USPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.upd_lego_job_cancel_tmp}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_CANCEL_TMP', 'WFPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.upd_lego_job_cancel_tmp}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_CANCEL_TMP', 'EMEA', 'PROCEDURE ONLY', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.upd_lego_job_cancel_tmp}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_OPPORTUNITY', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_OPPORTUNITY_1', 'LEGO_JOB_OPPORTUNITY_2', 'LEGO_JOB_OPPORTUNITY', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_OPPORTUNITY', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_OPPORTUNITY_1', 'LEGO_JOB_OPPORTUNITY_2', 'LEGO_JOB_OPPORTUNITY', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_OPPORTUNITY', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_OPPORTUNITY_1', 'LEGO_JOB_OPPORTUNITY_2', 'LEGO_JOB_OPPORTUNITY', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_SUPPLIER', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_SUPPLIER1', 'LEGO_JOB_SUPPLIER2', 'LEGO_JOB_SUPPLIER', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_SUPPLIER', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_SUPPLIER1', 'LEGO_JOB_SUPPLIER2', 'LEGO_JOB_SUPPLIER', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_SUPPLIER', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_SUPPLIER1', 'LEGO_JOB_SUPPLIER2', 'LEGO_JOB_SUPPLIER', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_WORK_LOCATION', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_WORK_LOCATION_1', 'LEGO_JOB_WORK_LOCATION_2', 'LEGO_JOB_WORK_LOCATION', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_WORK_LOCATION', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_WORK_LOCATION_1', 'LEGO_JOB_WORK_LOCATION_2', 'LEGO_JOB_WORK_LOCATION', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_WORK_LOCATION', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB_WORK_LOCATION_1', 'LEGO_JOB_WORK_LOCATION_2', 'LEGO_JOB_WORK_LOCATION', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB1', 'LEGO_JOB2', 'LEGO_JOB', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB1', 'LEGO_JOB2', 'LEGO_JOB', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 8, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_JOB1', 'LEGO_JOB2', 'LEGO_JOB', NULL, NULL, NULL)
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 8, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_JOB_UDF_ENUM1', 'LEGO_JOB_UDF_ENUM2', 'LEGO_JOB_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (8),
  PARTITION VALUES (18),
  PARTITION VALUES (13),
  PARTITION VALUES (7),
  PARTITION VALUES (19),
  PARTITION VALUES (20),
  PARTITION VALUES (17),
  PARTITION VALUES (11),
  PARTITION VALUES (32),
  PARTITION VALUES (1),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_job_vw','udf_collection_id')}')
/
  
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 8, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_JOB_UDF_ENUM1', 'LEGO_JOB_UDF_ENUM2', 'LEGO_JOB_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (8),
  PARTITION VALUES (18),
  PARTITION VALUES (13),
  PARTITION VALUES (7),
  PARTITION VALUES (19),
  PARTITION VALUES (20),
  PARTITION VALUES (17),
  PARTITION VALUES (11),
  PARTITION VALUES (32),
  PARTITION VALUES (1),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_job_vw','udf_collection_id')}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 8, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_JOB_UDF_ENUM1', 'LEGO_JOB_UDF_ENUM2', 'LEGO_JOB_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (8),
  PARTITION VALUES (18),
  PARTITION VALUES (13),
  PARTITION VALUES (7),
  PARTITION VALUES (19),
  PARTITION VALUES (20),
  PARTITION VALUES (17),
  PARTITION VALUES (11),
  PARTITION VALUES (32),
  PARTITION VALUES (1),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_job_vw','udf_collection_id')}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 8, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_JOB_UDF_NOENUM1', 'LEGO_JOB_UDF_NOENUM2', 'LEGO_JOB_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_job_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 8, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_JOB_UDF_NOENUM1', 'LEGO_JOB_UDF_NOENUM2', 'LEGO_JOB_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_job_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_JOB_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 8, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_JOB_UDF_NOENUM1', 'LEGO_JOB_UDF_NOENUM2', 'LEGO_JOB_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_job_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RATECARD', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 9, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_RATECARD1', 'LEGO_RATECARD2', 'LEGO_RATECARD', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RATECARD', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 9, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_RATECARD1', 'LEGO_RATECARD2', 'LEGO_RATECARD', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RATECARD', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 9, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_RATECARD1', 'LEGO_RATECARD2', 'LEGO_RATECARD', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 10, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_RFX_T1', 'LEGO_RFX_T2', 'LEGO_RFX', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 10, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_RFX_T1', 'LEGO_RFX_T2', 'LEGO_RFX', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 10, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_RFX_T1', 'LEGO_RFX_T2', 'LEGO_RFX', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX_CAC', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 10, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RFX_CAC_T1', 'LEGO_RFX_CAC_T2', 'LEGO_RFX_CAC', NULL, NULL, q'{lego_xxx.load_lego_rfx_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX_CAC', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 10, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RFX_CAC_T1', 'LEGO_RFX_CAC_T2', 'LEGO_RFX_CAC', NULL, NULL, q'{lego_xxx.load_lego_rfx_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX_CAC', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 10, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RFX_CAC_T1', 'LEGO_RFX_CAC_T2', 'LEGO_RFX_CAC', NULL, NULL, q'{lego_xxx.load_lego_rfx_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 10, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RFX_UDF_ENUM1', 'LEGO_RFX_UDF_ENUM2', 'LEGO_RFX_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_rfx_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 10, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RFX_UDF_ENUM1', 'LEGO_RFX_UDF_ENUM2', 'LEGO_RFX_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_rfx_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 10, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RFX_UDF_ENUM1', 'LEGO_RFX_UDF_ENUM2', 'LEGO_RFX_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_rfx_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 10, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RFX_UDF_NOENUM1', 'LEGO_RFX_UDF_NOENUM2', 'LEGO_RFX_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_rfx_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 10, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RFX_UDF_NOENUM1', 'LEGO_RFX_UDF_NOENUM2', 'LEGO_RFX_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_rfx_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RFX_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 10, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RFX_UDF_NOENUM1', 'LEGO_RFX_UDF_NOENUM2', 'LEGO_RFX_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_rfx_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_CAC', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_CAC_T1', 'LEGO_ASSIGNMENT_CAC_T2', 'LEGO_ASSIGNMENT_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_CAC', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_CAC_T1', 'LEGO_ASSIGNMENT_CAC_T2', 'LEGO_ASSIGNMENT_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_CAC', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_CAC_T1', 'LEGO_ASSIGNMENT_CAC_T2', 'LEGO_ASSIGNMENT_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_EA', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_EA1', 'LEGO_ASSIGNMENT_EA2', 'LEGO_ASSIGNMENT_EA', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_EA', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_EA1', 'LEGO_ASSIGNMENT_EA2', 'LEGO_ASSIGNMENT_EA', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_EA', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_EA1', 'LEGO_ASSIGNMENT_EA2', 'LEGO_ASSIGNMENT_EA', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_TA', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_TA1', 'LEGO_ASSIGNMENT_TA2', 'LEGO_ASSIGNMENT_TA', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_TA', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_TA1', 'LEGO_ASSIGNMENT_TA2', 'LEGO_ASSIGNMENT_TA', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_TA', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_TA1', 'LEGO_ASSIGNMENT_TA2', 'LEGO_ASSIGNMENT_TA', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_WO', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_WO1', 'LEGO_ASSIGNMENT_WO2', 'LEGO_ASSIGNMENT_WO', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_WO', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_WO1', 'LEGO_ASSIGNMENT_WO2', 'LEGO_ASSIGNMENT_WO', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_WO', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_ASSIGNMENT_WO1', 'LEGO_ASSIGNMENT_WO2', 'LEGO_ASSIGNMENT_WO', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_WO_AMENDMENT', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_WO_AMENDMENT1', 'LEGO_WO_AMENDMENT2', 'LEGO_WO_AMENDMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_WO_AMENDMENT', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_WO_AMENDMENT1', 'LEGO_WO_AMENDMENT2', 'LEGO_WO_AMENDMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_WO_AMENDMENT', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 11, 1, q'{TABLESPACE lego_users}', 'x', 'LEGO_WO_AMENDMENT1', 'LEGO_WO_AMENDMENT2', 'LEGO_WO_AMENDMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_ACTIVE_CAC', 'USPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 11, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP)}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.upd_lego_assignment_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_ACTIVE_CAC', 'WFPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 11, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP)}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.upd_lego_assignment_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGNMENT_ACTIVE_CAC', 'EMEA', 'PROCEDURE ONLY', 'TWICE DAILY', 11, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP)}', NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.upd_lego_assignment_cac}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MISSING_TIME', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 11, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_MISSING_TIME_1', 'LEGO_MISSING_TIME_2', 'LEGO_MISSING_TIME', NULL, NULL, q'{lego_xxx.load_lego_missing_time}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MISSING_TIME', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 11, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_MISSING_TIME_1', 'LEGO_MISSING_TIME_2', 'LEGO_MISSING_TIME', NULL, NULL, q'{lego_xxx.load_lego_missing_time}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MISSING_TIME', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 11, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_MISSING_TIME_1', 'LEGO_MISSING_TIME_2', 'LEGO_MISSING_TIME', NULL, NULL, q'{lego_xxx.load_lego_missing_time}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_UDF_ENUM1', 'LEGO_ASSGNMNT_UDF_ENUM2', 'LEGO_ASSGNMNT_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (8),
  PARTITION VALUES (7),
  PARTITION VALUES (1),
  PARTITION VALUES (13),
  PARTITION VALUES (18),
  PARTITION VALUES (19),
  PARTITION VALUES (17),
  PARTITION VALUES (20),
  PARTITION VALUES (32),
  PARTITION VALUES (11),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_assignment_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_UDF_ENUM1', 'LEGO_ASSGNMNT_UDF_ENUM2', 'LEGO_ASSGNMNT_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (8),
  PARTITION VALUES (7),
  PARTITION VALUES (1),
  PARTITION VALUES (13),
  PARTITION VALUES (18),
  PARTITION VALUES (19),
  PARTITION VALUES (17),
  PARTITION VALUES (20),
  PARTITION VALUES (32),
  PARTITION VALUES (11),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_assignment_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_UDF_ENUM1', 'LEGO_ASSGNMNT_UDF_ENUM2', 'LEGO_ASSGNMNT_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (8),
  PARTITION VALUES (7),
  PARTITION VALUES (1),
  PARTITION VALUES (13),
  PARTITION VALUES (18),
  PARTITION VALUES (19),
  PARTITION VALUES (17),
  PARTITION VALUES (20),
  PARTITION VALUES (32),
  PARTITION VALUES (11),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_assignment_vw','udf_collection_id')}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_UDF_NOENUM1', 'LEGO_ASSGNMNT_UDF_NOENUM2', 'LEGO_ASSGNMNT_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_assignment_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_UDF_NOENUM1', 'LEGO_ASSGNMNT_UDF_NOENUM2', 'LEGO_ASSGNMNT_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_assignment_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_UDF_NOENUM1', 'LEGO_ASSGNMNT_UDF_NOENUM2', 'LEGO_ASSGNMNT_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_assignment_vw','udf_collection_id')}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_WOV_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_WOV_UDF_ENUM1', 'LEGO_ASSGNMNT_WOV_UDF_ENUM2', 'LEGO_ASSGNMNT_WOV_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (1),
  PARTITION VALUES (7),
  PARTITION VALUES (8),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_assignment_vw','wov_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_WOV_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_WOV_UDF_ENUM1', 'LEGO_ASSGNMNT_WOV_UDF_ENUM2', 'LEGO_ASSGNMNT_WOV_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (1),
  PARTITION VALUES (7),
  PARTITION VALUES (8),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_assignment_vw','wov_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_WOV_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_WOV_UDF_ENUM1', 'LEGO_ASSGNMNT_WOV_UDF_ENUM2', 'LEGO_ASSGNMNT_WOV_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (1),
  PARTITION VALUES (7),
  PARTITION VALUES (8),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_assignment_vw','wov_udf_collection_id')}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_WOV_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_WOV_UDF_NOENUM1', 'LEGO_ASSGNMNT_WOV_UDF_NOENUM2', 'LEGO_ASSGNMNT_WOV_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_assignment_vw','wov_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_WOV_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_WOV_UDF_NOENUM1', 'LEGO_ASSGNMNT_WOV_UDF_NOENUM2', 'LEGO_ASSGNMNT_WOV_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_assignment_vw','wov_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSGNMNT_WOV_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_ASSGNMNT_WOV_UDF_NOENUM1', 'LEGO_ASSGNMNT_WOV_UDF_NOENUM2', 'LEGO_ASSGNMNT_WOV_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_assignment_vw','wov_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TENURE', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TENURE1', 'LEGO_TENURE2', 'LEGO_TENURE', NULL, NULL, q'{lego_xxx.load_lego_tenure}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TENURE', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TENURE1', 'LEGO_TENURE2', 'LEGO_TENURE', NULL, NULL, q'{lego_xxx.load_lego_tenure}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TENURE', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TENURE1', 'LEGO_TENURE2', 'LEGO_TENURE', NULL, NULL, q'{lego_xxx.load_lego_tenure}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_WORKER_ED_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_WORKER_ED_UDF_ENUM1', 'LEGO_WORKER_ED_UDF_ENUM2', 'LEGO_WORKER_ED_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_assignment_vw','worker_ed_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_WORKER_ED_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_WORKER_ED_UDF_ENUM1', 'LEGO_WORKER_ED_UDF_ENUM2', 'LEGO_WORKER_ED_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_assignment_vw','worker_ed_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_WORKER_ED_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_WORKER_ED_UDF_ENUM1', 'LEGO_WORKER_ED_UDF_ENUM2', 'LEGO_WORKER_ED_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_assignment_vw','worker_ed_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_WORKER_ED_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_WORKER_ED_UDF_NOENUM1', 'LEGO_WORKER_ED_UDF_NOENUM2', 'LEGO_WORKER_ED_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_assignment_vw','worker_ed_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_WORKER_ED_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_WORKER_ED_UDF_NOENUM1', 'LEGO_WORKER_ED_UDF_NOENUM2', 'LEGO_WORKER_ED_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_assignment_vw','worker_ed_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_WORKER_ED_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 11, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_WORKER_ED_UDF_NOENUM1', 'LEGO_WORKER_ED_UDF_NOENUM2', 'LEGO_WORKER_ED_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_assignment_vw','worker_ed_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MATCH', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 12, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_MATCH_1', 'LEGO_MATCH_2', 'LEGO_MATCH', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MATCH', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 12, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_MATCH_1', 'LEGO_MATCH_2', 'LEGO_MATCH', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_MATCH', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 12, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_MATCH_1', 'LEGO_MATCH_2', 'LEGO_MATCH', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIME_TO_FILL', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 12, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIME_TO_FILL_1', 'LEGO_TIME_TO_FILL_2', 'LEGO_TIME_TO_FILL', NULL, NULL, q'{lego_xxx.load_lego_time_to_fill}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIME_TO_FILL', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 12, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIME_TO_FILL_1', 'LEGO_TIME_TO_FILL_2', 'LEGO_TIME_TO_FILL', NULL, NULL, q'{lego_xxx.load_lego_time_to_fill}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIME_TO_FILL', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 12, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIME_TO_FILL_1', 'LEGO_TIME_TO_FILL_2', 'LEGO_TIME_TO_FILL', NULL, NULL, q'{lego_xxx.load_lego_time_to_fill}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EVALUATION', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 13, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_EVALUATION_1', 'LEGO_EVALUATION_2', 'LEGO_EVALUATION', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EVALUATION', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 13, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_EVALUATION_1', 'LEGO_EVALUATION_2', 'LEGO_EVALUATION', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EVALUATION', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 13, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_EVALUATION_1', 'LEGO_EVALUATION_2', 'LEGO_EVALUATION', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 14, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_EXPENSE1', 'LEGO_EXPENSE2', 'LEGO_EXPENSE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 14, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_EXPENSE1', 'LEGO_EXPENSE2', 'LEGO_EXPENSE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 14, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_EXPENSE1', 'LEGO_EXPENSE2', 'LEGO_EXPENSE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ERLI_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ERLI_UDF_ENUM1', 'LEGO_EXPENSE_ERLI_UDF_ENUM2', 'LEGO_EXPENSE_ERLI_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_expense_vw','erli_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ERLI_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ERLI_UDF_ENUM1', 'LEGO_EXPENSE_ERLI_UDF_ENUM2', 'LEGO_EXPENSE_ERLI_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_expense_vw','erli_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ERLI_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ERLI_UDF_ENUM1', 'LEGO_EXPENSE_ERLI_UDF_ENUM2', 'LEGO_EXPENSE_ERLI_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_expense_vw','erli_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ERLI_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ERLI_UDF_NOENUM1', 'LEGO_EXPENSE_ERLI_UDF_NOENUM2', 'LEGO_EXPENSE_ERLI_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_expense_vw','erli_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ERLI_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ERLI_UDF_NOENUM1', 'LEGO_EXPENSE_ERLI_UDF_NOENUM2', 'LEGO_EXPENSE_ERLI_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_expense_vw','erli_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ERLI_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ERLI_UDF_NOENUM1', 'LEGO_EXPENSE_ERLI_UDF_NOENUM2', 'LEGO_EXPENSE_ERLI_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_expense_vw','erli_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ER_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ER_UDF_ENUM1', 'LEGO_EXPENSE_ER_UDF_ENUM2', 'LEGO_EXPENSE_ER_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_expense_vw','er_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ER_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ER_UDF_ENUM1', 'LEGO_EXPENSE_ER_UDF_ENUM2', 'LEGO_EXPENSE_ER_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_expense_vw','er_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ER_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ER_UDF_ENUM1', 'LEGO_EXPENSE_ER_UDF_ENUM2', 'LEGO_EXPENSE_ER_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_expense_vw','er_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ER_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ER_UDF_NOENUM1', 'LEGO_EXPENSE_ER_UDF_NOENUM2', 'LEGO_EXPENSE_ER_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_expense_vw','er_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ER_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ER_UDF_NOENUM1', 'LEGO_EXPENSE_ER_UDF_NOENUM2', 'LEGO_EXPENSE_ER_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_expense_vw','er_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_EXPENSE_ER_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 14, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_EXPENSE_ER_UDF_NOENUM1', 'LEGO_EXPENSE_ER_UDF_NOENUM2', 'LEGO_EXPENSE_ER_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_expense_vw','er_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_ASSIGNMENT_DETAIL', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SC_ASSIGNMENT_DETAIL_1', 'LEGO_SC_ASSIGNMENT_DETAIL_2', 'LEGO_SC_ASSIGNMENT_DETAIL', NULL, NULL, q'{lego_supplier_scorecard.load_lego_sc_assignment_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_ASSIGNMENT_DETAIL', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SC_ASSIGNMENT_DETAIL_1', 'LEGO_SC_ASSIGNMENT_DETAIL_2', 'LEGO_SC_ASSIGNMENT_DETAIL', NULL, NULL, q'{lego_supplier_scorecard.load_lego_sc_assignment_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_ASSIGNMENT_DETAIL', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SC_ASSIGNMENT_DETAIL_1', 'LEGO_SC_ASSIGNMENT_DETAIL_2', 'LEGO_SC_ASSIGNMENT_DETAIL', NULL, NULL, q'{lego_supplier_scorecard.load_lego_sc_assignment_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_INTERVIEW_DETAIL', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SC_INTERVIEW_DETAIL_1', 'LEGO_SC_INTERVIEW_DETAIL_2', 'LEGO_SC_INTERVIEW_DETAIL', NULL, NULL, q'{lego_supplier_scorecard.load_lego_sc_interview_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_INTERVIEW_DETAIL', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SC_INTERVIEW_DETAIL_1', 'LEGO_SC_INTERVIEW_DETAIL_2', 'LEGO_SC_INTERVIEW_DETAIL', NULL, NULL, q'{lego_supplier_scorecard.load_lego_sc_interview_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_INTERVIEW_DETAIL', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SC_INTERVIEW_DETAIL_1', 'LEGO_SC_INTERVIEW_DETAIL_2', 'LEGO_SC_INTERVIEW_DETAIL', NULL, NULL, q'{lego_supplier_scorecard.load_lego_sc_interview_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_MATCH_DETAIL', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SC_MATCH_DETAIL_1', 'LEGO_SC_MATCH_DETAIL_2', 'LEGO_SC_MATCH_DETAIL', NULL, NULL, q'{lego_supplier_scorecard.load_lego_sc_match_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_MATCH_DETAIL', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SC_MATCH_DETAIL_1', 'LEGO_SC_MATCH_DETAIL_2', 'LEGO_SC_MATCH_DETAIL', NULL, NULL, q'{lego_supplier_scorecard.load_lego_sc_match_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_MATCH_DETAIL', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SC_MATCH_DETAIL_1', 'LEGO_SC_MATCH_DETAIL_2', 'LEGO_SC_MATCH_DETAIL', NULL, NULL, q'{lego_supplier_scorecard.load_lego_sc_match_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_PREFERRED_SUPPLIER', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SC_PREFERRED_SUPPLIER_1', 'LEGO_SC_PREFERRED_SUPPLIER_2', 'LEGO_SC_PREFERRED_SUPPLIER', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_PREFERRED_SUPPLIER', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SC_PREFERRED_SUPPLIER_1', 'LEGO_SC_PREFERRED_SUPPLIER_2', 'LEGO_SC_PREFERRED_SUPPLIER', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SC_PREFERRED_SUPPLIER', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 15, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_SC_PREFERRED_SUPPLIER_1', 'LEGO_SC_PREFERRED_SUPPLIER_2', 'LEGO_SC_PREFERRED_SUPPLIER', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SUPPLIER_SCORECARD_SUM', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 15, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SUPPLIER_SCORECARD_SUM_1', 'LEGO_SUPPLIER_SCORECARD_SUM_2', 'LEGO_SUPPLIER_SCORECARD_SUM', NULL, NULL, q'{lego_supplier_scorecard.load_lego_supplier_sc_sum}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SUPPLIER_SCORECARD_SUM', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 15, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SUPPLIER_SCORECARD_SUM_1', 'LEGO_SUPPLIER_SCORECARD_SUM_2', 'LEGO_SUPPLIER_SCORECARD_SUM', NULL, NULL, q'{lego_supplier_scorecard.load_lego_supplier_sc_sum}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_SUPPLIER_SCORECARD_SUM', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 15, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_SUPPLIER_SCORECARD_SUM_1', 'LEGO_SUPPLIER_SCORECARD_SUM_2', 'LEGO_SUPPLIER_SCORECARD_SUM', NULL, NULL, q'{lego_supplier_scorecard.load_lego_supplier_sc_sum}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD', 'USPROD', 'PROCEDURE ONLY RELEASE', 'TWICE DAILY', 16, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, 'LEGO_TIMECARD', 'WEEK_ENDING_DATE', 
q'{PARTITION BY RANGE (WEEK_ENDING_DATE)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION VALUES LESS THAN (TO_DATE('01-JAN-2000','DD-MON-YYYY'))
)}', 
q'{lego_xxx.load_lego_timecard}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD', 'WFPROD', 'PROCEDURE ONLY RELEASE', 'TWICE DAILY', 16, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, 'LEGO_TIMECARD', 'WEEK_ENDING_DATE',
q'{PARTITION BY RANGE (WEEK_ENDING_DATE)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION VALUES LESS THAN (TO_DATE('01-JAN-2000','DD-MON-YYYY'))
)}', 
q'{lego_xxx.load_lego_timecard}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD', 'EMEA', 'PROCEDURE ONLY RELEASE', 'TWICE DAILY', 16, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, NULL, NULL, 'LEGO_TIMECARD', 'WEEK_ENDING_DATE',
q'{PARTITION BY RANGE (WEEK_ENDING_DATE)
INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))
(
PARTITION VALUES LESS THAN (TO_DATE('01-JAN-2000','DD-MON-YYYY'))
)}', 
q'{lego_xxx.load_lego_timecard}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_FUTURE', 'USPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 16, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.load_lego_timecard_future}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_FUTURE', 'WFPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 16, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.load_lego_timecard_future}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_FUTURE', 'EMEA', 'PROCEDURE ONLY', 'TWICE DAILY', 16, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.load_lego_timecard_future}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_TE_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_TE_UDF_ENUM1', 'LEGO_TIMECARD_TE_UDF_ENUM2', 'LEGO_TIMECARD_TE_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_timecard_vw','te_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_TE_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_TE_UDF_ENUM1', 'LEGO_TIMECARD_TE_UDF_ENUM2', 'LEGO_TIMECARD_TE_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_timecard_vw','te_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_TE_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_TE_UDF_ENUM1', 'LEGO_TIMECARD_TE_UDF_ENUM2', 'LEGO_TIMECARD_TE_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_timecard_vw','te_udf_collection_id')}')
/


INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_TE_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_TE_UDF_NOENUM1', 'LEGO_TIMECARD_TE_UDF_NOENUM2', 'LEGO_TIMECARD_TE_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_timecard_vw','te_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_TE_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_TE_UDF_NOENUM1', 'LEGO_TIMECARD_TE_UDF_NOENUM2', 'LEGO_TIMECARD_TE_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_timecard_vw','te_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_TE_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_TE_UDF_NOENUM1', 'LEGO_TIMECARD_TE_UDF_NOENUM2', 'LEGO_TIMECARD_TE_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_timecard_vw','te_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_T_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_T_UDF_ENUM1', 'LEGO_TIMECARD_T_UDF_ENUM2', 'LEGO_TIMECARD_T_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_timecard_vw','t_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_T_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_T_UDF_ENUM1', 'LEGO_TIMECARD_T_UDF_ENUM2', 'LEGO_TIMECARD_T_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_timecard_vw','t_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_T_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_T_UDF_ENUM1', 'LEGO_TIMECARD_T_UDF_ENUM2', 'LEGO_TIMECARD_T_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_timecard_vw','t_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_T_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_T_UDF_NOENUM1', 'LEGO_TIMECARD_T_UDF_NOENUM2', 'LEGO_TIMECARD_T_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_timecard_vw','t_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_T_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_T_UDF_NOENUM1', 'LEGO_TIMECARD_T_UDF_NOENUM2', 'LEGO_TIMECARD_T_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_timecard_vw','t_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_TIMECARD_T_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 16, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_TIMECARD_T_UDF_NOENUM1', 'LEGO_TIMECARD_T_UDF_NOENUM2', 'LEGO_TIMECARD_T_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_timecard_vw','t_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_BUS_ORG_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_BUS_ORG_UDF_ENUM1', 'LEGO_BUS_ORG_UDF_ENUM2', 'LEGO_BUS_ORG_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_buyer_org_vw',null)}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_BUS_ORG_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_BUS_ORG_UDF_ENUM1', 'LEGO_BUS_ORG_UDF_ENUM2', 'LEGO_BUS_ORG_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_buyer_org_vw',null)}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_BUS_ORG_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_BUS_ORG_UDF_ENUM1', 'LEGO_BUS_ORG_UDF_ENUM2', 'LEGO_BUS_ORG_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_buyer_org_vw',null)}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_BUS_ORG_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_BUS_ORG_UDF_NOENUM1', 'LEGO_BUS_ORG_UDF_NOENUM2', 'LEGO_BUS_ORG_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_buyer_org_vw',null)}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_BUS_ORG_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_BUS_ORG_UDF_NOENUM1', 'LEGO_BUS_ORG_UDF_NOENUM2', 'LEGO_BUS_ORG_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_buyer_org_vw',null)}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_BUS_ORG_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_BUS_ORG_UDF_NOENUM1', 'LEGO_BUS_ORG_UDF_NOENUM2', 'LEGO_BUS_ORG_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_buyer_org_vw',null)}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CANDIDATE_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_CANDIDATE_UDF_ENUM1', 'LEGO_CANDIDATE_UDF_ENUM2', 'LEGO_CANDIDATE_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (7),
  PARTITION VALUES (1),
  PARTITION VALUES (11),
  PARTITION VALUES (32),
  PARTITION VALUES (8),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_person_vw','candidate_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CANDIDATE_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_CANDIDATE_UDF_ENUM1', 'LEGO_CANDIDATE_UDF_ENUM2', 'LEGO_CANDIDATE_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (7),
  PARTITION VALUES (1),
  PARTITION VALUES (11),
  PARTITION VALUES (32),
  PARTITION VALUES (8),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_person_vw','candidate_udf_collection_id')}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CANDIDATE_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_CANDIDATE_UDF_ENUM1', 'LEGO_CANDIDATE_UDF_ENUM2', 'LEGO_CANDIDATE_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (7),
  PARTITION VALUES (1),
  PARTITION VALUES (11),
  PARTITION VALUES (32),
  PARTITION VALUES (8),
  PARTITION VALUES (15),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_person_vw','candidate_udf_collection_id')}')
/


INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CANDIDATE_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_CANDIDATE_UDF_NOENUM1', 'LEGO_CANDIDATE_UDF_NOENUM2', 'LEGO_CANDIDATE_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_person_vw','candidate_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CANDIDATE_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_CANDIDATE_UDF_NOENUM1', 'LEGO_CANDIDATE_UDF_NOENUM2', 'LEGO_CANDIDATE_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_person_vw','candidate_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CANDIDATE_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_CANDIDATE_UDF_NOENUM1', 'LEGO_CANDIDATE_UDF_NOENUM2', 'LEGO_CANDIDATE_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_person_vw','candidate_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PERSON_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PERSON_UDF_ENUM1', 'LEGO_PERSON_UDF_ENUM2', 'LEGO_PERSON_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_person_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PERSON_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PERSON_UDF_ENUM1', 'LEGO_PERSON_UDF_ENUM2', 'LEGO_PERSON_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_person_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PERSON_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PERSON_UDF_ENUM1', 'LEGO_PERSON_UDF_ENUM2', 'LEGO_PERSON_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_person_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PERSON_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PERSON_UDF_NOENUM1', 'LEGO_PERSON_UDF_NOENUM2', 'LEGO_PERSON_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_person_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PERSON_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PERSON_UDF_NOENUM1', 'LEGO_PERSON_UDF_NOENUM2', 'LEGO_PERSON_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_person_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PERSON_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 17, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PERSON_UDF_NOENUM1', 'LEGO_PERSON_UDF_NOENUM2', 'LEGO_PERSON_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_person_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ALL_ORGS_CALENDAR', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 18, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_ALL_ORGS_CALENDAR_1', 'LEGO_ALL_ORGS_CALENDAR_2', 'LEGO_ALL_ORGS_CALENDAR', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ALL_ORGS_CALENDAR', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 18, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_ALL_ORGS_CALENDAR_1', 'LEGO_ALL_ORGS_CALENDAR_2', 'LEGO_ALL_ORGS_CALENDAR', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ALL_ORGS_CALENDAR', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 18, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_ALL_ORGS_CALENDAR_1', 'LEGO_ALL_ORGS_CALENDAR_2', 'LEGO_ALL_ORGS_CALENDAR', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_APPROVAL', 'USPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 19, 1, NULL, 'x', NULL, NULL, 'LEGO_APPROVAL_REFRESH', NULL, NULL, q'{lego_xxx.load_lego_approvals_refresh}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_APPROVAL', 'WFPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 19, 1, NULL, 'x', NULL, NULL, 'LEGO_APPROVAL_REFRESH', NULL, NULL, q'{lego_xxx.load_lego_approvals_refresh}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_APPROVAL', 'EMEA', 'PROCEDURE ONLY', 'TWICE DAILY', 19, 1, NULL, 'x', NULL, NULL, 'LEGO_APPROVAL_REFRESH', NULL, NULL, q'{lego_xxx.load_lego_approvals_refresh}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_CAC', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PA_CAC_TAB1', 'LEGO_PA_CAC_TAB2', 'LEGO_PA_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_CAC', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PA_CAC_TAB1', 'LEGO_PA_CAC_TAB2', 'LEGO_PA_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_CAC', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PA_CAC_TAB1', 'LEGO_PA_CAC_TAB2', 'LEGO_PA_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PROJECT_TAB1', 'LEGO_PROJECT_TAB2', 'LEGO_PROJECT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PROJECT_TAB1', 'LEGO_PROJECT_TAB2', 'LEGO_PROJECT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PROJECT_TAB1', 'LEGO_PROJECT_TAB2', 'LEGO_PROJECT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_AGREEMENT', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PROJECT_AGREEMENT1', 'LEGO_PROJECT_AGREEMENT2', 'LEGO_PROJECT_AGREEMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_AGREEMENT', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PROJECT_AGREEMENT1', 'LEGO_PROJECT_AGREEMENT2', 'LEGO_PROJECT_AGREEMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_AGREEMENT', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PROJECT_AGREEMENT1', 'LEGO_PROJECT_AGREEMENT2', 'LEGO_PROJECT_AGREEMENT', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_CAC', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PROJECT_CAC_TAB1', 'LEGO_PROJECT_CAC_TAB2', 'LEGO_PROJECT_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_CAC', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PROJECT_CAC_TAB1', 'LEGO_PROJECT_CAC_TAB2', 'LEGO_PROJECT_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_CAC', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 20, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PROJECT_CAC_TAB1', 'LEGO_PROJECT_CAC_TAB2', 'LEGO_PROJECT_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PAYMENT_REQUEST', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PAYMENT_REQUEST_1', 'LEGO_PAYMENT_REQUEST_2', 'LEGO_PAYMENT_REQUEST', NULL, NULL, q'{lego_xxx.load_lego_payment_request}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PAYMENT_REQUEST', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PAYMENT_REQUEST_1', 'LEGO_PAYMENT_REQUEST_2', 'LEGO_PAYMENT_REQUEST', NULL, NULL, q'{lego_xxx.load_lego_payment_request}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PAYMENT_REQUEST', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PAYMENT_REQUEST_1', 'LEGO_PAYMENT_REQUEST_2', 'LEGO_PAYMENT_REQUEST', NULL, NULL, q'{lego_xxx.load_lego_payment_request}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_GEO_DESC', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PA_GEO_DESC1', 'LEGO_PA_GEO_DESC2', 'LEGO_PA_GEO_DESC', NULL, NULL, q'{lego_xxx.load_lego_pa_geo_desc}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_GEO_DESC', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PA_GEO_DESC1', 'LEGO_PA_GEO_DESC2', 'LEGO_PA_GEO_DESC', NULL, NULL, q'{lego_xxx.load_lego_pa_geo_desc}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_GEO_DESC', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PA_GEO_DESC1', 'LEGO_PA_GEO_DESC2', 'LEGO_PA_GEO_DESC', NULL, NULL, q'{lego_xxx.load_lego_pa_geo_desc}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJECT_UDF_ENUM1', 'LEGO_PROJECT_UDF_ENUM2', 'LEGO_PROJECT_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_project_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJECT_UDF_ENUM1', 'LEGO_PROJECT_UDF_ENUM2', 'LEGO_PROJECT_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_project_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJECT_UDF_ENUM1', 'LEGO_PROJECT_UDF_ENUM2', 'LEGO_PROJECT_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_project_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJECT_UDF_NOENUM1', 'LEGO_PROJECT_UDF_NOENUM2', 'LEGO_PROJECT_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_project_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJECT_UDF_NOENUM1', 'LEGO_PROJECT_UDF_NOENUM2', 'LEGO_PROJECT_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_project_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJECT_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJECT_UDF_NOENUM1', 'LEGO_PROJECT_UDF_NOENUM2', 'LEGO_PROJECT_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_project_vw','udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJ_AGREEMENT_PYMNT', 'USPROD', 'PROC TOGGLE', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJ_AGREEMENT_PAYMENT_1', 'LEGO_PROJ_AGREEMENT_PAYMENT_2', 'LEGO_PROJ_AGREEMENT_PYMNT', NULL, NULL, q'{lego_xxx.load_lego_proj_agreement_pay}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJ_AGREEMENT_PYMNT', 'WFPROD', 'PROC TOGGLE', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJ_AGREEMENT_PAYMENT_1', 'LEGO_PROJ_AGREEMENT_PAYMENT_2', 'LEGO_PROJ_AGREEMENT_PYMNT', NULL, NULL, q'{lego_xxx.load_lego_proj_agreement_pay}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJ_AGREEMENT_PYMNT', 'EMEA', 'PROC TOGGLE', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJ_AGREEMENT_PAYMENT_1', 'LEGO_PROJ_AGREEMENT_PAYMENT_2', 'LEGO_PROJ_AGREEMENT_PYMNT', NULL, NULL, q'{lego_xxx.load_lego_proj_agreement_pay}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJ_AGRMT_PA_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJ_AGRMT_PA_UDF_ENUM1', 'LEGO_PROJ_AGRMT_PA_UDF_ENUM2', 'LEGO_PROJ_AGRMT_PA_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (7),
  PARTITION VALUES (8),
  PARTITION VALUES (13),
  PARTITION VALUES (1),
  PARTITION VALUES (12),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_project_agreement_vw','pa_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJ_AGRMT_PA_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJ_AGRMT_PA_UDF_ENUM1', 'LEGO_PROJ_AGRMT_PA_UDF_ENUM2', 'LEGO_PROJ_AGRMT_PA_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (7),
  PARTITION VALUES (8),
  PARTITION VALUES (13),
  PARTITION VALUES (1),
  PARTITION VALUES (12),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_project_agreement_vw','pa_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJ_AGRMT_PA_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJ_AGRMT_PA_UDF_ENUM1', 'LEGO_PROJ_AGRMT_PA_UDF_ENUM2', 'LEGO_PROJ_AGRMT_PA_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (0),
  PARTITION VALUES (3),
  PARTITION VALUES (7),
  PARTITION VALUES (8),
  PARTITION VALUES (13),
  PARTITION VALUES (1),
  PARTITION VALUES (12),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_project_agreement_vw','pa_udf_collection_id')}')
/


INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJ_AGRMT_PA_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJ_AGRMT_PA_UDF_NOENUM1', 'LEGO_PROJ_AGRMT_PA_UDF_NOENUM2', 'LEGO_PROJ_AGRMT_PA_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_project_agreement_vw','pa_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJ_AGRMT_PA_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJ_AGRMT_PA_UDF_NOENUM1', 'LEGO_PROJ_AGRMT_PA_UDF_NOENUM2', 'LEGO_PROJ_AGRMT_PA_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_project_agreement_vw','pa_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PROJ_AGRMT_PA_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PROJ_AGRMT_PA_UDF_NOENUM1', 'LEGO_PROJ_AGRMT_PA_UDF_NOENUM2', 'LEGO_PROJ_AGRMT_PA_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_project_agreement_vw','pa_udf_collection_id')}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MID_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MID_UDF_ENUM1', 'LEGO_PYMNT_REQ_MID_UDF_ENUM2', 'LEGO_PYMNT_REQ_MID_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (3),
  PARTITION VALUES (7),
  PARTITION VALUES (8),
  PARTITION VALUES (0),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_payment_request_vw','mid_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MID_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MID_UDF_ENUM1', 'LEGO_PYMNT_REQ_MID_UDF_ENUM2', 'LEGO_PYMNT_REQ_MID_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (3),
  PARTITION VALUES (7),
  PARTITION VALUES (8),
  PARTITION VALUES (0),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_payment_request_vw','mid_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MID_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MID_UDF_ENUM1', 'LEGO_PYMNT_REQ_MID_UDF_ENUM2', 'LEGO_PYMNT_REQ_MID_UDF_ENUM', NULL, 
q'{PARTITION BY LIST (locale_preference)
 (PARTITION VALUES (3),
  PARTITION VALUES (7),
  PARTITION VALUES (8),
  PARTITION VALUES (0),
  PARTITION VALUES (DEFAULT))}', 
q'{lego_udf_util.udf_enum('placeholder','lego_payment_request_vw','mid_udf_collection_id')}')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MID_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MID_UDF_NOENUM1', 'LEGO_PYMNT_REQ_MID_UDF_NOENUM2', 'LEGO_PYMNT_REQ_MID_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_payment_request_vw','mid_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MID_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MID_UDF_NOENUM1', 'LEGO_PYMNT_REQ_MID_UDF_NOENUM2', 'LEGO_PYMNT_REQ_MID_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_payment_request_vw','mid_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MID_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MID_UDF_NOENUM1', 'LEGO_PYMNT_REQ_MID_UDF_NOENUM2', 'LEGO_PYMNT_REQ_MID_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_payment_request_vw','mid_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MI_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MI_UDF_ENUM1', 'LEGO_PYMNT_REQ_MI_UDF_ENUM2', 'LEGO_PYMNT_REQ_MI_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_payment_request_vw','mi_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MI_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MI_UDF_ENUM1', 'LEGO_PYMNT_REQ_MI_UDF_ENUM2', 'LEGO_PYMNT_REQ_MI_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_payment_request_vw','mi_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MI_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MI_UDF_ENUM1', 'LEGO_PYMNT_REQ_MI_UDF_ENUM2', 'LEGO_PYMNT_REQ_MI_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_payment_request_vw','mi_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MI_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MI_UDF_NOENUM1', 'LEGO_PYMNT_REQ_MI_UDF_NOENUM2', 'LEGO_PYMNT_REQ_MI_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_payment_request_vw','mi_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MI_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MI_UDF_NOENUM1', 'LEGO_PYMNT_REQ_MI_UDF_NOENUM2', 'LEGO_PYMNT_REQ_MI_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_payment_request_vw','mi_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PYMNT_REQ_MI_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 20, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_PYMNT_REQ_MI_UDF_NOENUM1', 'LEGO_PYMNT_REQ_MI_UDF_NOENUM2', 'LEGO_PYMNT_REQ_MI_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_payment_request_vw','mi_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_REQUEST_TO_BUY', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 21, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_REQUEST_TO_BUY1', 'LEGO_REQUEST_TO_BUY2', 'LEGO_REQUEST_TO_BUY', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_REQUEST_TO_BUY', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 21, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_REQUEST_TO_BUY1', 'LEGO_REQUEST_TO_BUY2', 'LEGO_REQUEST_TO_BUY', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_REQUEST_TO_BUY', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 21, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_REQUEST_TO_BUY1', 'LEGO_REQUEST_TO_BUY2', 'LEGO_REQUEST_TO_BUY', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_REQUEST_TO_BUY_CAC', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 21, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_REQUEST_TO_BUY_CAC_T1', 'LEGO_REQUEST_TO_BUY_CAC_T2', 'LEGO_REQUEST_TO_BUY_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_REQUEST_TO_BUY_CAC', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 21, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_REQUEST_TO_BUY_CAC_T1', 'LEGO_REQUEST_TO_BUY_CAC_T2', 'LEGO_REQUEST_TO_BUY_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_REQUEST_TO_BUY_CAC', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 21, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_REQUEST_TO_BUY_CAC_T1', 'LEGO_REQUEST_TO_BUY_CAC_T2', 'LEGO_REQUEST_TO_BUY_CAC', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RQ_TO_BUY_RTB_UDF_ENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 21, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RQ_TO_BUY_RTB_UDF_ENUM1', 'LEGO_RQ_TO_BUY_RTB_UDF_ENUM2', 'LEGO_RQ_TO_BUY_RTB_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_request_to_buy_vw','rtb_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RQ_TO_BUY_RTB_UDF_ENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 21, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RQ_TO_BUY_RTB_UDF_ENUM1', 'LEGO_RQ_TO_BUY_RTB_UDF_ENUM2', 'LEGO_RQ_TO_BUY_RTB_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_request_to_buy_vw','rtb_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RQ_TO_BUY_RTB_UDF_ENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 21, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RQ_TO_BUY_RTB_UDF_ENUM1', 'LEGO_RQ_TO_BUY_RTB_UDF_ENUM2', 'LEGO_RQ_TO_BUY_RTB_UDF_ENUM', NULL, NULL, q'{lego_udf_util.udf_enum('placeholder','lego_request_to_buy_vw','rtb_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RQ_TO_BUY_RTB_UDF_NOENUM', 'USPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 21, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM1', 'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM2', 'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_request_to_buy_vw','rtb_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RQ_TO_BUY_RTB_UDF_NOENUM', 'WFPROD', 'PROC TOGGLE ARGS', 'TWICE DAILY', 21, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM1', 'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM2', 'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_request_to_buy_vw','rtb_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_RQ_TO_BUY_RTB_UDF_NOENUM', 'EMEA', 'PROC TOGGLE ARGS', 'TWICE DAILY', 21, 2, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', NULL, 'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM1', 'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM2', 'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM', NULL, NULL, q'{lego_udf_util.udf_noenum('placeholder','lego_request_to_buy_vw','rtb_udf_collection_id')}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INVOICE', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 22, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INVOICE_1', 'LEGO_INVOICE_2', 'LEGO_INVOICE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INVOICE', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 22, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INVOICE_1', 'LEGO_INVOICE_2', 'LEGO_INVOICE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INVOICE', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 22, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INVOICE_1', 'LEGO_INVOICE_2', 'LEGO_INVOICE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INV_SUPPLIER_SUBSET', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 22, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INV_SUPPLIER_SUBSET1', 'LEGO_INV_SUPPLIER_SUBSET2', 'LEGO_INV_SUPPLIER_SUBSET', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INV_SUPPLIER_SUBSET', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 22, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INV_SUPPLIER_SUBSET1', 'LEGO_INV_SUPPLIER_SUBSET2', 'LEGO_INV_SUPPLIER_SUBSET', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INV_SUPPLIER_SUBSET', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 22, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INV_SUPPLIER_SUBSET1', 'LEGO_INV_SUPPLIER_SUBSET2', 'LEGO_INV_SUPPLIER_SUBSET', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INVOICE_DETAIL', 'USPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 22, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.load_lego_invoice_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INVOICE_DETAIL', 'WFPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 22, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.load_lego_invoice_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INVOICE_DETAIL', 'EMEA', 'PROCEDURE ONLY', 'TWICE DAILY', 22, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, q'{lego_xxx.load_lego_invoice_detail}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGN_PAYMENT_REQUEST', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 22, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_ASSIGN_PAYMENT_REQUEST_1', 'LEGO_ASSIGN_PAYMENT_REQUEST_2', 'LEGO_ASSIGN_PAYMENT_REQUEST', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGN_PAYMENT_REQUEST', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 22, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_ASSIGN_PAYMENT_REQUEST_1', 'LEGO_ASSIGN_PAYMENT_REQUEST_2', 'LEGO_ASSIGN_PAYMENT_REQUEST', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_ASSIGN_PAYMENT_REQUEST', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 22, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_ASSIGN_PAYMENT_REQUEST_1', 'LEGO_ASSIGN_PAYMENT_REQUEST_2', 'LEGO_ASSIGN_PAYMENT_REQUEST', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INVCD_EXPENDITURE_SUM', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 22, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INVCD_EXPENDITURE_SUM_1', 'LEGO_INVCD_EXPENDITURE_SUM_2', 'LEGO_INVCD_EXPENDITURE_SUM', 'expenditure_type', 
q'{PARTITION BY LIST (expenditure_type) (PARTITION VALUES ('Payment Requests'), PARTITION VALUES ('Milestones'), PARTITION VALUES ('Time'), PARTITION VALUES ('Expense'), PARTITION VALUES (DEFAULT))}', NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INVCD_EXPENDITURE_SUM', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 22, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INVCD_EXPENDITURE_SUM_1', 'LEGO_INVCD_EXPENDITURE_SUM_2', 'LEGO_INVCD_EXPENDITURE_SUM', 'expenditure_type',
q'{PARTITION BY LIST (expenditure_type) (PARTITION VALUES ('Payment Requests'), PARTITION VALUES ('Milestones'), PARTITION VALUES ('Time'), PARTITION VALUES ('Expense'), PARTITION VALUES (DEFAULT))}', NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INVCD_EXPENDITURE_SUM', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 22, 3, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INVCD_EXPENDITURE_SUM_1', 'LEGO_INVCD_EXPENDITURE_SUM_2', 'LEGO_INVCD_EXPENDITURE_SUM', 'expenditure_type',
q'{PARTITION BY LIST (expenditure_type) (PARTITION VALUES ('Payment Requests'), PARTITION VALUES ('Milestones'), PARTITION VALUES ('Time'), PARTITION VALUES ('Expense'), PARTITION VALUES (DEFAULT))}', NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_CHANGE_REQUEST', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 23, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PA_CHANGE_REQUEST1', 'LEGO_PA_CHANGE_REQUEST2', 'LEGO_PA_CHANGE_REQUEST', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_CHANGE_REQUEST', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 23, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PA_CHANGE_REQUEST1', 'LEGO_PA_CHANGE_REQUEST2', 'LEGO_PA_CHANGE_REQUEST', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_PA_CHANGE_REQUEST', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 23, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_PA_CHANGE_REQUEST1', 'LEGO_PA_CHANGE_REQUEST2', 'LEGO_PA_CHANGE_REQUEST', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_REMITTANCE', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 24, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_REMITTANCE_1', 'LEGO_REMITTANCE_2', 'LEGO_REMITTANCE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_REMITTANCE', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 24, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_REMITTANCE_1', 'LEGO_REMITTANCE_2', 'LEGO_REMITTANCE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_REMITTANCE', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 24, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_REMITTANCE_1', 'LEGO_REMITTANCE_2', 'LEGO_REMITTANCE', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INTERVIEW', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 25, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INTERVIEW1', 'LEGO_INTERVIEW2', 'LEGO_INTERVIEW', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INTERVIEW', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 25, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INTERVIEW1', 'LEGO_INTERVIEW2', 'LEGO_INTERVIEW', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_INTERVIEW', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 25, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_INTERVIEW1', 'LEGO_INTERVIEW2', 'LEGO_INTERVIEW', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CAND_SEARCH', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 26, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_CAND_SEARCH1', 'LEGO_CAND_SEARCH2', 'LEGO_CAND_SEARCH', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CAND_SEARCH', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 26, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_CAND_SEARCH1', 'LEGO_CAND_SEARCH2', 'LEGO_CAND_SEARCH', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CAND_SEARCH', 'EMEA', 'SQL TOGGLE', 'TWICE DAILY', 26, 1, q'{NOLOGGING TABLESPACE LEGO_USERS STORAGE (CELL_FLASH_CACHE KEEP) COMPRESS FOR QUERY HIGH}', 'x', 'LEGO_CAND_SEARCH1', 'LEGO_CAND_SEARCH2', 'LEGO_CAND_SEARCH', NULL, NULL, NULL)
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CAND_SEARCH_IDX', 'USPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 26, 2, NULL, NULL, 'LEGO_CAND_SEARCH_IDX1', 'LEGO_CAND_SEARCH_IDX2', 'LEGO_CAND_SEARCH_IDX', NULL, NULL, q'{lego_xxx.load_candidate_search_index}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CAND_SEARCH_IDX', 'WFPROD', 'PROCEDURE ONLY', 'TWICE DAILY', 26, 2, NULL, NULL, 'LEGO_CAND_SEARCH_IDX1', 'LEGO_CAND_SEARCH_IDX2', 'LEGO_CAND_SEARCH_IDX', NULL, NULL, q'{lego_xxx.load_candidate_search_index}')
/
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
 storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
 partition_column_name, partition_clause, refresh_procedure_name)
VALUES
('LEGO_CAND_SEARCH_IDX', 'EMEA', 'PROCEDURE ONLY', 'TWICE DAILY', 26, 2, NULL, NULL, 'LEGO_CAND_SEARCH_IDX1', 'LEGO_CAND_SEARCH_IDX2', 'LEGO_CAND_SEARCH_IDX', NULL, NULL, q'{lego_xxx.load_candidate_search_index}')
/

COMMIT
/
