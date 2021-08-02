/*******************************************************************************
SCRIPT NAME         lego_pa_cac.sql 
 
LEGO OBJECT NAME    LEGO_PA_CAC
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Sajeev Sadasivan

***************************MODIFICATION HISTORY ********************************

03/28/2014 - E.Clark - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_pa_cac.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_PA_CAC'; 

  v_clob CLOB :=
     q'{SELECT pa.contract_id         AS project_agreement_id, 
               pa.cac_collection1_fk  AS cac_collection_id,
               lcc.cac_id,
               lcc.bus_org_id         AS buyer_org_id, 
               lcc.cac_kind, 
               lcc.start_date         AS cac_start_date, 
               lcc.end_date           AS cac_end_date,
               lcc.cac_guid
          FROM project_agreement AS OF SCN lego_refresh_mgr_pkg.get_scn() pa,
               lego_cac_collection lcc
         WHERE pa.cac_collection1_fk      = lcc.cac_collection_id
           AND NVL((SELECT MAX(pav.end_date)
                      FROM project_agreement_version AS OF SCN lego_refresh_mgr_pkg.get_scn() pav,
                           contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn() cv
                     WHERE pa.contract_id             = cv.contract_fk 
                       AND cv.contract_version_id     = pav.contract_version_id(+)
                    ), SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
         UNION ALL
        SELECT pa.contract_id         AS project_agreement_id,  
               pa.cac_collection2_fk  AS cac_collection_id,
               lcc.cac_id,
               lcc.bus_org_id         AS buyer_org_id, 
               lcc.cac_kind, 
               lcc.start_date         AS cac_start_date, 
               lcc.end_date           AS cac_end_date,
               lcc.cac_guid
          FROM project_agreement AS OF SCN lego_refresh_mgr_pkg.get_scn() pa,
               lego_cac_collection lcc
         WHERE pa.cac_collection2_fk      = lcc.cac_collection_id
           AND NVL((SELECT MAX(pav.end_date)
                      FROM project_agreement_version AS OF SCN lego_refresh_mgr_pkg.get_scn() pav,
                           contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn() cv
                     WHERE pa.contract_id             = cv.contract_fk 
                       AND cv.contract_version_id     = pav.contract_version_id(+)
                    ), SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
         ORDER BY buyer_org_id, project_agreement_id, cac_collection_id, cac_id}';

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

