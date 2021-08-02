DELETE FROM lego_refresh 
 WHERE refresh_group = 2
   AND source_name = 'WFPROD'
/

DELETE FROM lego_refresh 
 WHERE refresh_group = 2
   AND object_name IN ('LEGO_SECURE_PROJECT_AGREEMENT','LEGO_EXPENSE_MANAGED_CAC',
                       'LEGO_PA_MANAGED_CAC','LEGO_TIMECARD_MANAGED_CAC',
                       'LEGO_SLOT_EXPENSE_REPORT','LEGO_SLOT_PROJECT_AGREEMENT',
                       'LEGO_SLOT_TIMECARD','LEGO_SECURE_INV_ASSGNMT','LEGO_SECURE_INV_PRJ_AGR')
/

-- package used in refreshes was renamed.  update metadata.
UPDATE lego_refresh
   SET refresh_procedure_name = REPLACE(refresh_procedure_name, 'lego_slot_security', 'lego_row_security')
 WHERE refresh_group = 2
   AND refresh_dependency_order = 2  --this gets two of the four, the next updates will get the other two.
/

-- rename individual legos to be more correct
UPDATE lego_refresh
   SET object_name = 'LEGO_ASSIGNMENT_ROW_SECURITY',
       refresh_procedure_name = 'lego_row_security.load_assignment_row_security',
       refresh_object_name_1 = 'ASSIGNMENT_ROW_SECURITY_IQP1',
       refresh_object_name_2 = 'ASSIGNMENT_ROW_SECURITY_IQP2',
       synonym_name = 'ASSIGNMENT_ROW_SECURITY_IQP'
 WHERE object_name = 'LEGO_SLOT_ASSIGNMENT'
/

UPDATE lego_refresh
   SET object_name = 'LEGO_JOB_ROW_SECURITY',
       refresh_procedure_name = 'lego_row_security.load_lego_job_row_security',
       refresh_object_name_1 = 'JOB_ROW_SECURITY_IQP1',
       refresh_object_name_2 = 'JOB_ROW_SECURITY_IQP2',
       synonym_name = 'JOB_ROW_SECURITY_IQP'
 WHERE object_name = 'LEGO_SLOT_JOB'
/

UPDATE lego_refresh
   SET object_name = 'LEGO_ASSIGNMENT_SLOTS',
       refresh_object_name_1 = 'ASSIGNMENT_SLOTS_IQP1',
       refresh_object_name_2 = 'ASSIGNMENT_SLOTS_IQP2',
       synonym_name = 'ASSIGNMENT_SLOTS_IQP'
 WHERE object_name = 'LEGO_SECURE_ASSIGNMENT'
/

UPDATE lego_refresh
   SET object_name = 'LEGO_JOB_SLOTS',
       refresh_object_name_1 = 'JOB_SLOTS_IQP1',
       refresh_object_name_2 = 'JOB_SLOTS_IQP2',
       synonym_name = 'JOB_SLOTS_IQP'
 WHERE object_name = 'LEGO_SECURE_JOB'
/

-- Create two new CTAS security legos
INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name)  
VALUES
 ('LEGO_ASSIGNMENT_CAC_MAP','USPROD','SQL TOGGLE','EVERY FOUR HOURS', 2, 1,
  'NOLOGGING', 'ASSIGNMENT_CAC_MAP_IQP1','ASSIGNMENT_CAC_MAP_IQP2','ASSIGNMENT_CAC_MAP_IQP')
/
 
INSERT INTO lego_refresh
 (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
  storage_clause, refresh_object_name_1, refresh_object_name_2, synonym_name)  
VALUES
 ('LEGO_JOB_CAC_MAP','USPROD','SQL TOGGLE','EVERY FOUR HOURS', 2, 1,
  'NOLOGGING', 'JOB_CAC_MAP_IQP1','JOB_CAC_MAP_IQP2','JOB_CAC_MAP_IQP')
/


COMMIT
/

