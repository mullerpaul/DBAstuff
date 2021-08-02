/*******************************************************************************
SCRIPT NAME         lego_refresh_ins_address.sql 
 
LEGO OBJECT NAME    LEGO_ADDRESS, LEGO_CONTACT_ADDRESS, LEGO_PLACE
SOURCE NAME         USPROD, WFPROD
 
CREATED             03/02/2016
 
ORIGINAL AUTHOR     Joe Pullifrone
  
*******************************************************************************/  


DECLARE

  v_source           VARCHAR2(64) := 'lego_refresh_ins_address.sql';
  
BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Remove exising LEGO_ADDRESS rows');
  logger_pkg.info('Begin - Deleting from LEGO_REFRESH');
  
  DELETE FROM lego_refresh  
    WHERE object_name IN ('LEGO_ADDRESS','LEGO_CONTACT_ADDRESS','LEGO_PLACE');

  logger_pkg.info('Delete Complete '||SQL%ROWCOUNT||' rows deleted', TRUE); 
    
  logger_pkg.set_code_location('Inserting new Refresh SQL for LEGO_PLACE, LEGO_CONTACT_ADDRESS, USPROD, WFPROD');
  logger_pkg.info('Begin - INSERTING INTO LEGO_REFRESH');
  
  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
  VALUES ('LEGO_ADDRESS', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 1, 1, 'NOLOGGING', 'x', 'LEGO_ADDRESS_IQP1', 'LEGO_ADDRESS_IQP2', 'LEGO_ADDRESS_IQP', NULL, NULL, NULL);

  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
   VALUES ('LEGO_ADDRESS', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 1, 1, 'NOLOGGING', 'x', 'LEGO_ADDRESS_WF1', 'LEGO_ADDRESS_WF2', 'LEGO_ADDRESS_WF', NULL, NULL, NULL);

     INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
  VALUES ('LEGO_PLACE', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 1, 1, 'NOLOGGING', 'x', 'LEGO_PLACE_IQP1', 'LEGO_PLACE_IQP2', 'LEGO_PLACE_IQP', NULL, NULL, NULL);

  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
   VALUES ('LEGO_PLACE', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 1, 1, 'NOLOGGING', 'x', 'LEGO_PLACE_WF1', 'LEGO_PLACE_WF2', 'LEGO_PLACE_WF', NULL, NULL, NULL);

  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
  VALUES ('LEGO_CONTACT_ADDRESS', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 1, 1, 'NOLOGGING', 'x', 'LEGO_CONTACT_ADDRESS_IQP1', 'LEGO_CONTACT_ADDRESS_IQP2', 'LEGO_CONTACT_ADDRESS_IQP', NULL, NULL, NULL);

  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
  VALUES ('LEGO_CONTACT_ADDRESS', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 1, 1, 'NOLOGGING', 'x', 'LEGO_CONTACT_ADDRESS_WF1', 'LEGO_CONTACT_ADDRESS_WF2', 'LEGO_CONTACT_ADDRESS_WF', NULL, NULL, NULL);

  
  COMMIT;

  logger_pkg.info('Insert Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    logger_pkg.fatal('ROLLBACK', SQLCODE, 'Error inserting new Refresh SQL for LEGO_PLACE, LEGO_CONTACT_ADDRESS, USPROD, WFPROD - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/