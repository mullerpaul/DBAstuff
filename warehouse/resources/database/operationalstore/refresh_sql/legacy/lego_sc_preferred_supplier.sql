/*******************************************************************************
SCRIPT NAME         lego_sc_preferred_supplier.sql 
 
LEGO OBJECT NAME    LEGO_SC_PREFERRED_SUPPLIER
 
CREATED             8/6/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

08/06/2014 - J.Pullifrone - IQN-19352 - new refresh_sql created - Release 12.1.3  
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_sc_preferred_supplier.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_SC_PREFERRED_SUPPLIER'; 

  v_clob CLOB :=
q'{WITH max_cv AS
       (SELECT bro.buyer_org_id, sro.supplier_org_id, MAX(cv.contract_version_id) AS contract_version_id            
          FROM            
              (SELECT bo.buyer_firm_id, bo.buyer_org_id, bo.buyer_rule_org_id, bfr.firm_id AS buyer_rule_firm_id 
                 FROM firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn() bfr,
                      lego_buyer_org_vw bo
                WHERE bo.buyer_rule_org_id = bfr.business_org_fk) bro,  
              (SELECT so.supplier_firm_id, so.supplier_org_id, so.supplier_rule_org_id, sfr.firm_id AS supplier_rule_firm_id 
                 FROM firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn() sfr,
                      lego_supplier_org_vw so
                WHERE so.supplier_rule_org_id = sfr.business_org_fk) sro,
               buyer_supplier_agreement AS OF SCN lego_refresh_mgr_pkg.get_scn() bsa, 
               contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn() cv
         WHERE bro.buyer_rule_firm_id    = bsa.buyer_firm_fk
           AND sro.supplier_rule_firm_id = bsa.supply_firm_fk 
           AND bsa.contract_id           = cv.contract_fk
           AND cv.object_version_state = 2
         GROUP BY bro.buyer_org_id, sro.supplier_org_id) 
--assignment contract version (WO)
SELECT max_cv.buyer_org_id, max_cv.supplier_org_id, smt.preferred_supplier
  FROM contract_term AS OF SCN lego_refresh_mgr_pkg.get_scn() ct,
       contract_term AS OF SCN lego_refresh_mgr_pkg.get_scn() ct2,
       contract_term AS OF SCN lego_refresh_mgr_pkg.get_scn() ct3,
       contract_reference_term AS OF SCN lego_refresh_mgr_pkg.get_scn() crt,
       supplier_misc_term AS OF SCN lego_refresh_mgr_pkg.get_scn() smt,
       max_cv
 WHERE ct.contract_version_fk  = max_cv.contract_version_id
   AND ct.contract_term_id     = crt.contract_term_id
   AND crt.contract_version_fk = ct2.contract_version_fk
   AND ct2.contract_term_id    = ct3.parent_contract_term_fk
   AND ct3.contract_term_id    = smt.contract_term_id
UNION ALL
-- For EA and other objects that are passing in a contract version id which relates to a buyer supplier agreement
-- we will not have data in the 1st query, but this query will return that information
SELECT max_cv.buyer_org_id, max_cv.supplier_org_id, smt.preferred_supplier
  FROM contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn() cv, 
       contract_term    AS OF SCN lego_refresh_mgr_pkg.get_scn() ct1, 
       contract_term    AS OF SCN lego_refresh_mgr_pkg.get_scn() ct2,
       supplier_misc_term AS OF SCN lego_refresh_mgr_pkg.get_scn() smt,
       max_cv                            
 WHERE cv.contract_version_id = max_cv.contract_version_id
   AND cv.contract_version_id = ct1.contract_version_fk
   AND ct1.contract_term_id   = ct2.parent_contract_term_fk
   AND ct2.contract_term_id   = smt.contract_term_id
 ORDER BY buyer_org_id, supplier_org_id}';

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

