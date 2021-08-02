/*******************************************************************************
SCRIPT NAME         lego_bus_org.sql 
 
LEGO OBJECT NAME    LEGO_BUS_ORG
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Derek Reiner

***************************MODIFICATION HISTORY ********************************

06/13/2014 - J.Pullifrone - IQN-17293 - added inheritance_mode column - Release 12.1.1  
07/02/2014 - J.Pullifrone - IQN-18303 - added bus_rule_org_id column - Release 12.1.2 
01/27/2016 - pmuller                  - modifications for DB links, multiple sources, and remote SCN
02/02/2016 - jpullifrone              - removed phone, fax, email information, and bro func call  
02/04/2016 - jpullifrone              - removed calendar and address_guids
05/19/2017 - jpullifrone  - IQN-37661 - add falcon_bus_org_guid
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_bus_org.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_BUS_ORG'; 

  v_clob CLOB :=
  q'{WITH foguid AS (
       SELECT fo_bus_org_id       AS bus_org_id, 
              falcon_bus_org_guid AS bus_org_guid
         FROM bus_org_falcon_map@db_link_name AS OF SCN source_db_SCN
     )
     SELECT b.business_organization_id                       AS bus_org_id,            
            CASE 
              WHEN role.firm_type = 'S' THEN 'Supplier' 
              WHEN role.firm_type = 'P' THEN 'Provider' 
              WHEN role.firm_type = 'I' THEN 'Managing' 
              ELSE 'Buyer' 
            END                                         AS bus_org_type,
            b.name                                      AS bus_org_name,
            b.parent_business_org_fk                    AS parent_bus_org_id,
            b.enterprise_fk                             AS enterprise_id,
            bo_parent.business_organization_id          AS enterprise_bus_org_id,
            bo_parent.name                              AS enterprise_name,
            mg_firm.managing_firm                       AS managing_organization_name,
            role.firm_id,
            b.marketplace_id,
            b.udf_collection_fk                         AS buyer_udf_collection_id,
            sfirm.udf_collection_fk                     AS supplier_udf_collection_id,
            b.contact_information_fk                    AS contact_info_id,
            b.inheritance_mode,
            bg.falcon_bus_org_guid                      AS bus_org_guid,
            pbg.falcon_bus_org_guid                     AS parent_bus_org_guid,
            bg_parent.falcon_bus_org_guid               AS enterprise_bus_org_guid
       FROM business_organization@db_link_name AS OF SCN source_db_SCN b,
            bus_org_falcon_map@db_link_name AS OF SCN source_db_SCN bg,
            bus_org_falcon_map@db_link_name AS OF SCN source_db_SCN pbg,
            bus_org_falcon_map@db_link_name AS OF SCN source_db_SCN bg_parent,
            firm_role@db_link_name             AS OF SCN source_db_SCN role,
            supply_firm@db_link_name           AS OF SCN source_db_SCN sfirm,
            bus_org_lineage@db_link_name       AS OF SCN source_db_SCN bol,
            business_organization@db_link_name AS OF SCN source_db_SCN bo_parent,
            (SELECT DISTINCT enterprise_fk,
                             managing_firm
               FROM (SELECT (SELECT bo.name
                               FROM iq_firm@db_link_name               AS OF SCN source_db_SCN iq,
                                    firm_role@db_link_name             AS OF SCN source_db_SCN fr,
                                    business_organization@db_link_name AS OF SCN source_db_SCN bo
                              WHERE fr.firm_id = iq.firm_id
                                AND fr.business_org_fk = bo.business_organization_id
                                AND iq.firm_id = b.iq_firm_fk)
                               managing_firm,
                            bc.enterprise_fk
                       FROM bus_org_lineage@db_link_name       AS OF SCN source_db_SCN bol,
                            business_organization@db_link_name AS OF SCN source_db_SCN b,
                            firm_role@db_link_name             AS OF SCN source_db_SCN ff,
                            buyer_firm@db_link_name            AS OF SCN source_db_SCN bf,
                            business_organization@db_link_name AS OF SCN source_db_SCN bc
                      WHERE bol.ancestor_bus_org_fk     = b.business_organization_id
                        AND bol.descendant_bus_org_fk   = bc.business_organization_id
                        AND bc.business_organization_id = ff.business_org_fk
                        AND ff.firm_id = bf.firm_id)
              WHERE managing_firm IS NOT NULL) mg_firm
      WHERE b.enterprise_fk                  = mg_firm.enterprise_fk(+)
        AND bol.ancestor_bus_org_fk          = bo_parent.business_organization_id
        AND bo_parent.parent_business_org_fk IS NULL
        AND bol.descendant_bus_org_fk        = b.business_organization_id
        AND b.business_organization_id       = role.business_org_fk(+)
        AND b.business_organization_id       = bg.fo_bus_org_id
        AND b.parent_business_org_fk         = pbg.fo_bus_org_id(+)
        AND bol.descendant_bus_org_fk        = bg.fo_bus_org_id
        AND bol.ancestor_bus_org_fk          = bg_parent.fo_bus_org_id
        AND role.firm_id                     = sfirm.firm_id(+)
        AND role.firm_id                     NOT IN (1038, 4767)
ORDER BY bus_org_id}';

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

