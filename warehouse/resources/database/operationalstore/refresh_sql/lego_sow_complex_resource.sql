/*******************************************************************************
SCRIPT NAME         lego_sow_complex_resource.sql 
 
LEGO OBJECT NAME    LEGO_SOW_COMPLEX_RESOURCE
 
CREATED             08/31/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

JIRA STORY          IQN-33506

***************************MODIFICATION HISTORY ********************************

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_sow_complex_resource.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_SOW_COMPLEX_RESOURCE'; 

  v_clob CLOB :=
q'{ SELECT prd.project_resource_desc_id, 
           prdp.project_agreement_version_fk AS project_agreement_id,  
           prd.rate_table_edition_fk AS rate_table_edition_id, 
           prd.service_rate_fk AS service_rate_id, 
           prd.estimated_start_date, 
           prd.estimated_end_date, 
           prd.duration AS estimated_units, 
           prd.number_of_resources, 
           prd.estimated_cost                                   
      FROM project_resource_description@db_link_name AS OF SCN source_db_SCN prd,
           project_res_desc_phase@db_link_name AS OF SCN source_db_SCN prdp
     WHERE prdp.phase_id = prd.phase_fk
       AND prd.resource_type = 'C'
       AND prdp.project_agreement_version_fk IS NOT NULL}';

BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  UPDATE lego_refresh
     SET refresh_sql = v_clob
   WHERE object_name = v_lego_object_name;  
  
  COMMIT;
    
  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/

