/*******************************************************************************
SCRIPT NAME         lego_assignment_cac.sql 
 
LEGO OBJECT NAME    LEGO_ASSIGNMENT_CAC
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark     - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2  
01/27/2016 - pmuller                 - modifications for DB links, multiple sources, and remote SCN
08/15/2016 - jpullifrone - IQN-34018 -removed parallel hint   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assignment_cac.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSIGNMENT_CAC'; 

  v_clob CLOB :=            
   q'{SELECT 
             v.assignment_continuity_id,
             lcc.cac_id,
             v.cac_collection1_id AS cac_collection_id,
             lcc.bus_org_id         AS buyer_org_id, 
             lcc.cac_kind, 
             'N'                    AS primary_active_cac,
             lcc.start_date         AS cac_start_date, 
             lcc.end_date           AS cac_end_date,
             lc.cac_guid  
        FROM (SELECT assignment_continuity_id, cac_collection1_fk AS cac_collection1_id
                FROM assignment_continuity@db_link_name AS OF SCN source_db_SCN ac, 
                     assignment_edition@db_link_name AS OF SCN source_db_SCN ae
               WHERE ac.assignment_continuity_id = ae.assignment_continuity_fk
                 AND ac.current_edition_fk       = ae.assignment_edition_id
                 AND NVL(ae.actual_end_date, SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)) v, 
             lego_cac_collection lcc, 
             lego_cac lc
       WHERE v.cac_collection1_id  = lcc.cac_collection_id
         AND lcc.cac_guid          = lc.cac_guid
       UNION ALL
      SELECT 
             v.assignment_continuity_id, 
             lcc.cac_id,
             v.cac_collection2_id AS cac_collection_id,
             lcc.bus_org_id         AS buyer_org_id, 
             lcc.cac_kind, 
             'N'                    AS primary_active_cac,
             lcc.start_date         AS cac_start_date, 
             lcc.end_date           AS cac_end_date,
             lc.cac_guid  
        FROM (SELECT assignment_continuity_id, cac_collection2_fk AS cac_collection2_id
                FROM assignment_continuity@db_link_name AS OF SCN source_db_SCN ac, 
                     assignment_edition@db_link_name AS OF SCN source_db_SCN ae
               WHERE ac.assignment_continuity_id = ae.assignment_continuity_fk
                 AND ac.current_edition_fk       = ae.assignment_edition_id
                 AND NVL(ae.actual_end_date, SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)) v, 
             lego_cac_collection lcc, 
             lego_cac lc
       WHERE v.cac_collection2_id  = lcc.cac_collection_id
         AND lcc.cac_guid          = lc.cac_guid
       ORDER BY buyer_org_id, cac_collection_id}';        
         
         

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

