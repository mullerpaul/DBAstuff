/*******************************************************************************
SCRIPT NAME         lego_project.sql 
 
LEGO OBJECT NAME    LEGO_PROJECT
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark - IQN-14482 - added months_in_refresh for a hard limit on data going into the  
                                   lego, added is_archived, last_modified_date - Release 12.0.2 
03/25/2016 - P.Muller            - changes for multi-source.                       
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_project.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_PROJECT'; 

  v_clob CLOB :=
     q'{SELECT p.project_id,
               bfr.business_org_fk      AS buyer_org_id,
               sfr.business_org_fk      AS supplier_org_id,
               p.org_sub_classification AS org_sub_classification,
--               p.cac_collection1_fk     AS cac_collection1_id,
--               p.cac_collection2_fk     AS cac_collection2_id,
               p.udf_collection_fk      AS udf_collection_id,
               fw.user_fk               AS project_manager_person_id,  -- never_null_person_fk is same as user_fk
               p.internal_identifier    AS project_internal_identifier,
               p.title                  AS project_title,
               p.description            AS project_description,
               p.create_date            AS project_create_date,
               p.estimated_max_budget   AS estimated_budget_max,
               p.estimated_min_budget   AS estimated_budget_min,
               p.is_archived,
               p.last_modified_date,
               cu.value                 AS project_currency_id,
               cu.description           AS project_currency
          FROM project@db_link_name AS OF SCN source_db_SCN  p,
               firm_role@db_link_name AS OF SCN source_db_SCN  bfr,    -- for buyer business org
               firm_role@db_link_name AS OF SCN source_db_SCN  sfr,    -- for seller business org
               firm_worker@db_link_name AS OF SCN source_db_SCN  fw,   -- for manager person_id
               currency_unit@db_link_name AS OF SCN source_db_SCN  cu  -- for currency name
         WHERE p.buyer_firm_fk = bfr.firm_id
           AND p.supply_firm_fk = sfr.firm_id (+)  -- outer join due to many NULLs in p.supply_firm_fk.
           AND p.currency_unit_fk = cu.value
           AND p.project_manager_fk = fw.firm_worker_id
           AND (p.is_archived = 0 OR 
               (p.is_archived = 1 AND NVL(p.last_modified_date, SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE), - months_in_refresh)))}';

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

