/*******************************************************************************
SCRIPT NAME         lego_refresh_ins_evaluation.sql 
 
LEGO OBJECT NAME    LEGO_EVAL_ASSIGNMENT, LEGO_EVAL_PROJ_AGREEMENT
SOURCE NAME         USPROD, WFPROD
 
CREATED             03/24/2016
 
ORIGINAL AUTHOR     Joe Pullifrone
  
*******************************************************************************/  


DECLARE

  v_source           VARCHAR2(64) := 'lego_refresh_ins_evaluation.sql';
  
BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
    
  logger_pkg.set_code_location('Deleting old lego_refresh row for LEGO_EVALUATION');
  logger_pkg.info('Begin - DELETING FROM LEGO_REFRESH');  
  
  DELETE FROM lego_refresh 
   WHERE object_name = 'LEGO_EVALUATION';
  
  logger_pkg.info('Delete Complete', TRUE);    
  
  logger_pkg.set_code_location('Inserting new Refresh SQL for LEGO_EVAL_ASSIGNMENT and LEGO_EVAL_PROJ_AGREEMENT USPROD, WFPROD');
  logger_pkg.info('Begin - INSERTING INTO LEGO_REFRESH');
  
  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
  VALUES ('LEGO_EVAL_ASSIGNMENT', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 13, 1, 'NOLOGGING', 'x', 'EVAL_ASSIGNMENT_IQP1', 'EVAL_ASSIGNMENT_IQP2', 'EVAL_ASSIGNMENT_IQP', NULL, NULL, NULL);

  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
   VALUES ('LEGO_EVAL_ASSIGNMENT', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 13, 1, 'NOLOGGING', 'x', 'EVAL_ASSIGNMENT_WF1', 'EVAL_ASSIGNMENT_WF2', 'EVAL_ASSIGNMENT_WF', NULL, NULL, NULL);

  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
  VALUES ('LEGO_EVAL_PROJ_AGREEMENT', 'USPROD', 'SQL TOGGLE', 'TWICE DAILY', 13, 1, 'NOLOGGING', 'x', 'EVAL_PROJ_AGREEMENT_IQP1', 'EVAL_PROJ_AGREEMENT_IQP2', 'EVAL_PROJ_AGREEMENT_IQP', NULL, NULL, NULL);

  INSERT INTO lego_refresh
  (object_name, source_name, refresh_method, refresh_schedule, refresh_group, refresh_dependency_order, 
   storage_clause, refresh_sql, refresh_object_name_1, refresh_object_name_2, synonym_name, 
   partition_column_name, partition_clause, refresh_procedure_name)
   VALUES ('LEGO_EVAL_PROJ_AGREEMENT', 'WFPROD', 'SQL TOGGLE', 'TWICE DAILY', 13, 1, 'NOLOGGING', 'x', 'EVAL_PROJ_AGREEMENT_WF1', 'EVAL_PROJ_AGREEMENT_WF2', 'EVAL_PROJ_AGREEMENT_WF', NULL, NULL, NULL);

   
  COMMIT;

  logger_pkg.info('Insert Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    logger_pkg.fatal('ROLLBACK', SQLCODE, 'Error inserting new Refresh SQL for LEGO_EVAL_ASSIGNMENT and LEGO_EVAL_PROJ_AGREEMENT, USPROD, WFPROD - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/