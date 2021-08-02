/*******************************************************************************
SCRIPT NAME         lego_msp_user_available_org.sql 
 
LEGO OBJECT NAME    LEGO_MSP_USER_AVAILABLE_ORG
 
CREATED             05/02/2018
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************
  08/01/2016 - pmuller - IQN-39946 - created as slightly modified version of lego_person_available_org
  
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_msp_user_available_orgs.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MSP_USER_AVAILABLE_ORG'; 

  /* This is a slimmed down version of the LEGO_PERSON_AVAILABLE_ORG SQL.  
     I removed the login_org column, reordered the tables in the FROM clauses and 
     the join clauses in the WHERE for better understanding, and added the filter 
     on person.is_msp_user.  I also join through IQ_USER without any active filters to 
     ensure that we are not bringing back data for anyone who isn't a system user; but 
     are placing no activity requirements on the system users.  We could instead join 
     straight from person to user_org_mappings and get nearly the same result.
     I worry that the user_org_mappings set is not as correct or efficient as it could be.  
     I got the logic for that query from Nathan ages ago and would like to ensure it is 
     correct and that there is no better way to do it. 
     Edit - Aug 2018: Adding join to user_name_domain to get the domain name, so now we NEED 
     that join to iq_user! */
  v_clob CLOB :=
   q'{  WITH user_org_mappings
    AS (SELECT oa.owning_person_fk        AS login_user_id, 
               bol1.descendant_bus_org_fk AS available_org_id
          FROM organization_assignment_tab@db_link_name AS OF SCN source_db_SCN oa,
               bus_org_lineage@db_link_name AS OF SCN source_db_SCN bol2, 
               bus_org_lineage@db_link_name AS OF SCN source_db_SCN bol1
         WHERE oa.organization_fk         = bol2.ancestor_bus_org_fk
           AND bol2.descendant_bus_org_fk = bol1.descendant_bus_org_fk
           AND oa.is_enabled              = 1
           AND oa.organization_scope      = 'ALL_DESCENDANTS'
         UNION                                          -- Not union all since we need to remove dups and make this set unique.  Some dups from
        SELECT oa.owning_person_fk AS login_user_id,    -- within a single bock are due to bad data in orgainization_assignment_tab. See IQN-33719
               bol.descendant_bus_org_fk AS available_org_id
          FROM organization_assignment_tab@db_link_name AS OF SCN source_db_SCN oa,
               bus_org_lineage@db_link_name AS OF SCN source_db_SCN bol
         WHERE oa.organization_fk    = bol.descendant_bus_org_fk
           AND oa.is_enabled         = 1
           AND oa.organization_scope = 'ORGANIZATION_ONLY')
SELECT uo.login_user_id AS msp_user_id,
       iu.user_name, 
       und.domain_name,
       uo.available_org_id
  FROM person@db_link_name AS OF SCN source_db_SCN p,
       iq_user@db_link_name AS OF SCN source_db_SCN iu,
       user_name_domain@db_link_name AS OF SCN source_db_SCN und,
       user_org_mappings uo
 WHERE p.person_id = iu.person_fk
   AND iu.user_name_domain_fk = und.user_name_domain_id
   AND iu.person_fk = uo.login_user_id
   AND p.is_msp_user = 1}';

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

