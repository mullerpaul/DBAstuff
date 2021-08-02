/*******************************************************************************
SCRIPT NAME         lego_assignment_cac_map.sql 
 
LEGO OBJECT NAME    LEGO_ASSIGNMENT_CAC_MAP
 
CREATED             04/25/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assignment_cac_map.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSIGNMENT_CAC_MAP'; 

  v_clob CLOB :=
   q'{SELECT a.assignment_continuity_id, x.cac_value_fk AS cac_value_id
  FROM cac_cacvalue_x@db_link_name AS OF SCN source_db_SCN x,
       (SELECT assignment_continuity_id, cac_collection1_fk AS cac_collection_id
          FROM assignment_continuity@db_link_name AS OF SCN source_db_SCN ac, 
               assignment_edition@db_link_name AS OF SCN source_db_SCN    ae
         WHERE ac.assignment_continuity_id = ae.assignment_continuity_fk
           AND ac.current_edition_fk       = ae.assignment_edition_id
           AND cac_collection1_fk IS NOT NULL
           AND (ae.actual_end_date IS NULL OR 
                ae.actual_end_date >= ADD_MONTHS(TRUNC(SYSDATE), -months_in_refresh)) 
         UNION ALL  -- union all is OK here.  cac collection IDs are either 1 or 2, not both, so we won't have dupes.
        SELECT assignment_continuity_id, cac_collection2_fk AS cac_collection_id
          FROM assignment_continuity@db_link_name AS OF SCN source_db_SCN ac2, 
               assignment_edition@db_link_name AS OF SCN source_db_SCN    ae2
         WHERE ac2.assignment_continuity_id = ae2.assignment_continuity_fk
           AND ac2.current_edition_fk       = ae2.assignment_edition_id
           AND cac_collection2_fk IS NOT NULL
           AND (ae2.actual_end_date IS NULL OR 
                ae2.actual_end_date >= ADD_MONTHS(TRUNC(SYSDATE), -months_in_refresh))) a
 WHERE x.cac_fk = a.cac_collection_id}';

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

