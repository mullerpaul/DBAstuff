/*******************************************************************************
SCRIPT NAME         lego_refresh_ins_job_position.sql 
 
LEGO OBJECT NAME    LEGO_JOB_POSITION
SOURCE NAME         USPROD, WFPROD
 
CREATED             03/08/2016
 
ORIGINAL AUTHOR     Joe Pullifrone
  
*******************************************************************************/  


DECLARE

  v_source           VARCHAR2(64) := 'lego_refresh_ins_job_position.sql';
  
BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
    
  logger_pkg.set_code_location('Inserting new Refresh SQL for LEGO_JOB_POSITION USPROD, WFPROD');
  logger_pkg.info('Begin - INSERTING INTO LEGO_REFRESH');
  
  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
  VALUES ('LEGO_JOB_POSITION', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, 'NOLOGGING', 'x', 'JOB_POSITION_IQP1', 'JOB_POSITION_IQP2', 'JOB_POSITION_IQP', NULL, NULL, NULL);

  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
   VALUES ('LEGO_JOB_POSITION', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 8, 1, 'NOLOGGING', 'x', 'JOB_POSITION_WF1', 'JOB_POSITION_WF2', 'JOB_POSITION_WF', NULL, NULL, NULL);

  COMMIT;

  logger_pkg.info('Insert Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    logger_pkg.fatal('ROLLBACK', SQLCODE, 'Error inserting new Refresh SQL for LEGO_JOB_POSITION, USPROD, WFPROD - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/