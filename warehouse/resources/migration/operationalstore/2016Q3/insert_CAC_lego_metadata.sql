-- USPROD  CAC lego
INSERT INTO lego_refresh
 (object_name,
  source_name,
  refresh_method,
  refresh_schedule,
  refresh_group,
  refresh_dependency_order,
  storage_clause,
  refresh_sql,
  refresh_object_name_1,
  refresh_object_name_2,
  synonym_name)
VALUES
 ('LEGO_CAC_CURRENT',
  'USPROD',
  'SQL TOGGLE',
  'TWICE DAILY',
  6,
  1,
  'NOLOGGING',
  'x',
  'CAC_CURRENT_IQP1',
  'CAC_CURRENT_IQP2',
  'CAC_CURRENT_IQP')
/

-- WF  CAC lego
INSERT INTO lego_refresh
 (object_name,
  source_name,
  refresh_method,
  refresh_schedule,
  refresh_group,
  refresh_dependency_order,
  storage_clause,
  refresh_sql,
  refresh_object_name_1,
  refresh_object_name_2,
  synonym_name)
VALUES
 ('LEGO_CAC_CURRENT',
  'WFPROD',
  'SQL TOGGLE',
  'TWICE DAILY',
  6,
  1,
  'NOLOGGING',
  'x',
  'CAC_CURRENT_WF1',
  'CAC_CURRENT_WF2',
  'CAC_CURRENT_WF')
/

-- USPROD  CAC Collection lego
INSERT INTO lego_refresh
 (object_name,
  source_name,
  refresh_method,
  refresh_schedule,
  refresh_group,
  refresh_dependency_order,
  storage_clause,
  refresh_sql,
  refresh_object_name_1,
  refresh_object_name_2,
  synonym_name)
VALUES
 ('LEGO_CAC_COLLECTION_CURRENT',
  'USPROD',
  'SQL TOGGLE',
  'TWICE DAILY',
  6,
  1,
  'NOLOGGING',
  'x',
  'CAC_COLLECTION_CURRENT_IQP1',
  'CAC_COLLECTION_CURRENT_IQP2',
  'CAC_COLLECTION_CURRENT_IQP')
/

-- WF  CAC Collection lego
INSERT INTO lego_refresh
 (object_name,
  source_name,
  refresh_method,
  refresh_schedule,
  refresh_group,
  refresh_dependency_order,
  storage_clause,
  refresh_sql,
  refresh_object_name_1,
  refresh_object_name_2,
  synonym_name)
VALUES
 ('LEGO_CAC_COLLECTION_CURRENT',
  'WFPROD',
  'SQL TOGGLE',
  'TWICE DAILY',
  6,
  1,
  'NOLOGGING',
  'x',
  'CAC_COLLECTION_CURRENT_WF1',
  'CAC_COLLECTION_CURRENT_WF2',
  'CAC_COLLECTION_CURRENT_WF')
/

-- Unified CAC history lego
INSERT INTO lego_refresh
 (object_name,
  source_name,
  refresh_method,
  refresh_schedule,
  refresh_group,
  refresh_dependency_order,
  refresh_procedure_name)
VALUES
 ('LEGO_CAC_HISTORY',
  'USPROD',  -- really is unified across sources but need to specify a source here.  going with usprod since thats more common.
  'PROCEDURE ONLY',
  'TWICE DAILY',
  6,
  2,
  'LEGO_CAC_PROCEDURES.load_cac_history')
/

-- Unified CAC Collection history lego 
INSERT INTO lego_refresh
 (object_name,
  source_name,
  refresh_method,
  refresh_schedule,
  refresh_group,
  refresh_dependency_order,
  refresh_procedure_name)
VALUES
 ('LEGO_CAC_COLLECTION_HISTORY',
  'USPROD',  -- really is unified across sources but need to specify a source here.  going with usprod since thats more common.
  'PROCEDURE ONLY',
  'TWICE DAILY',
  6,
  2,
  'LEGO_CAC_PROCEDURES.load_cac_collection_history')
/

COMMIT
/
