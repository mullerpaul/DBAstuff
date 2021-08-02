/*******************************************************************************
SCRIPT NAME         lego_job_cac_map.sql 
 
LEGO OBJECT NAME    LEGO_JOB_CAC_MAP
 
CREATED             04/25/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_job_cac_map.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JOB_CAC_MAP'; 

  v_clob CLOB :=
   q'{SELECT j.job_id, x.cac_value_fk AS cac_value_id
  FROM cac_cacvalue_x@db_link_name AS OF SCN source_db_SCN x,
       (SELECT job_id, cac_collection1_fk AS cac_collection_id
          FROM job@db_link_name AS OF SCN source_db_SCN
         WHERE cac_collection1_fk IS NOT NULL
           AND (archived_date IS NULL OR 
                archived_date >= ADD_MONTHS(TRUNC(SYSDATE), -months_in_refresh))
         UNION ALL  -- union all is OK here.  cac collection IDs are either 1 or 2, not both, so we won't have dupes.
        SELECT job_id, cac_collection2_fk
          FROM job@db_link_name AS OF SCN source_db_SCN
         WHERE cac_collection2_fk IS NOT NULL
           AND (archived_date IS NULL OR 
                archived_date >= ADD_MONTHS(TRUNC(SYSDATE), -months_in_refresh))) j
 WHERE x.cac_fk = j.cac_collection_id}';

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

