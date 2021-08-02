/*******************************************************************************
SCRIPT NAME         lego_buyer_org_by_ent_part_list.sql 
 
LEGO OBJECT NAME    LEGO_BUYER_BY_ENT_PART_LIST
 
CREATED             10/12/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

JIRA STORY          IQN-33702

***************************MODIFICATION HISTORY ********************************

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_buyer_org_by_ent_part_list.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_BUYER_BY_ENT_PART_LIST'; 

  v_clob CLOB :=
q'{SELECT buyer_enterprise_bus_org_id, 
          part_name, 
          LISTAGG(buyer_org_id,',') WITHIN GROUP (ORDER BY buyer_org_id) part_list   
     FROM (SELECT 'P_'||bo_parent.business_organization_id AS part_name,
                  bo_parent.business_organization_id       AS buyer_enterprise_bus_org_id, 
                  bo.business_organization_id              AS buyer_org_id
             FROM (SELECT owning_buyer_firm_fk AS buyer_firm_id
                     FROM assignment_continuity@db_link_name AS OF SCN source_db_SCN
                   UNION
                   SELECT buyer_firm_fk AS buyer_firm_id
                     FROM project@db_link_name AS OF SCN source_db_SCN) ac, 
                  firm_role@db_link_name AS OF SCN source_db_SCN bfr,
                  business_organization@db_link_name AS OF SCN source_db_SCN      bo,
                  bus_org_lineage@db_link_name AS OF SCN source_db_SCN            bol,
                  business_organization@db_link_name AS OF SCN source_db_SCN      bo_parent
            WHERE ac.buyer_firm_id                 = bfr.firm_id
              AND bfr.business_org_fk              = bo.business_organization_id 
              AND bo.business_organization_id      = bol.descendant_bus_org_fk
              AND bol.ancestor_bus_org_fk          = bo_parent.business_organization_id
              AND bo_parent.parent_business_org_fk IS NULL)
         GROUP BY buyer_enterprise_bus_org_id, 
                  part_name}';

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

