/*******************************************************************************
SCRIPT NAME         lego_request_to_buy_cac.sql 
 
LEGO OBJECT NAME    LEGO_REQUEST_TO_BUY_CAC
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Sajeev Sadasivan

***************************MODIFICATION HISTORY ********************************

 
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_request_to_buy_cac.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_REQUEST_TO_BUY_CAC'; 

  v_clob CLOB :=
   q'{SELECT v.identifier           AS rtb_id, 
             v.cac_collection1_fk   AS cac_collection_id,
             lcc.cac_id,
             lcc.bus_org_id         AS buyer_org_id, 
             lcc.cac_kind, 
             lcc.start_date         AS cac_start_date, 
             lcc.end_date           AS cac_end_date,
             lcc.cac_guid
        FROM request_to_buy_edition AS OF SCN lego_refresh_mgr_pkg.get_scn() v, lego_cac_collection lcc
       WHERE v.cac_collection1_fk  = lcc.cac_collection_id
       UNION ALL
      SELECT v.identifier           AS rtb_id,  
             v.cac_collection2_fk   AS cac_collection_id,
             lcc.cac_id,
             lcc.bus_org_id         AS buyer_org_id, 
             lcc.cac_kind, 
             lcc.start_date         AS cac_start_date, 
             lcc.end_date           AS cac_end_date,
             lcc.cac_guid
        FROM request_to_buy_edition AS OF SCN lego_refresh_mgr_pkg.get_scn() v, lego_cac_collection lcc
       WHERE v.cac_collection2_fk  = lcc.cac_collection_id
      ORDER BY buyer_org_id, cac_collection_id, cac_id}';

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

