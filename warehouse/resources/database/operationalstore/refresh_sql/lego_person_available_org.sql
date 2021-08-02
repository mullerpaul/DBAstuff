/*******************************************************************************
SCRIPT NAME         lego_person_available_orgs.sql 
 
LEGO OBJECT NAME    LEGO_PERSON_AVAILABLE_ORG
 
CREATED             08/01/2016
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************
  08/01/2016 - pmuller - IQN-33800 - created
  
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_person_available_orgs.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_PERSON_AVAILABLE_ORG'; 

  v_clob CLOB :=
   q'{  WITH user_list
    AS (SELECT person_fk AS user_id
          FROM iq_user@db_link_name AS OF SCN source_db_SCN
         WHERE inactive_expiration_date >= add_months(SYSDATE, -1)  -- one month past expiration grace period
           AND (last_login_time >= add_months(SYSDATE, -18) OR last_login_time IS NULL)),  -- logged in in last 18months
       user_org_mappings
    AS (SELECT oa.owning_person_fk        AS login_user_id, 
               bol1.ancestor_bus_org_fk   AS login_org_id, 
               bol1.descendant_bus_org_fk AS available_org_id
          FROM bus_org_lineage@db_link_name AS OF SCN source_db_SCN bol1, 
               bus_org_lineage@db_link_name AS OF SCN source_db_SCN bol2, 
               organization_assignment_tab@db_link_name AS OF SCN source_db_SCN oa
         WHERE bol1.descendant_bus_org_fk = bol2.descendant_bus_org_fk
           AND bol2.ancestor_bus_org_fk   = oa.organization_fk
           AND oa.is_enabled              = 1
           AND oa.organization_scope      = 'ALL_DESCENDANTS'
         UNION                                        -- Not union all since we need to remove dups and make this set unique.  Some dups from
        SELECT oa.owning_person_fk AS login_user_id,  -- within a single bock are due to bad data in orgainization_assignment_tab. See IQN-33719
               bol.ancestor_bus_org_fk   AS login_org_id, 
               bol.descendant_bus_org_fk AS available_org_id
          FROM bus_org_lineage@db_link_name AS OF SCN source_db_SCN bol, 
               organization_assignment_tab@db_link_name AS OF SCN source_db_SCN oa
         WHERE bol.descendant_bus_org_fk  = oa.organization_fk
           AND oa.is_enabled              = 1
           AND oa.organization_scope      = 'ORGANIZATION_ONLY')
SELECT uo.login_user_id, uo.login_org_id, uo.available_org_id
  FROM user_list ul,
       user_org_mappings uo
 WHERE uo.login_user_id = ul.user_id}';

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

