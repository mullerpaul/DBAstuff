/*******************************************************************************
SCRIPT NAME         lego_request_to_buy.sql 
 
LEGO OBJECT NAME    LEGO_REQUEST_TO_BUY
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Sajeev Sadasivan

***************************MODIFICATION HISTORY ********************************

03/28/2014 - E.Clark      - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
04/17/2014 - J.Pullifrone - IQN-15419 - added current_phase_id for translation in view, added default english value for 
                                        current_phase in case localization is NULL - Release 12.1  
4/30/2014 - H. Majid  - IQN - 16566 -  Correct the buyer org id  
5/01/2014 - H. Majid  - IQN - 16608 -  Correct the join in order to return  the correct data
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_request_to_buy.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_REQUEST_TO_BUY'; 

  v_clob CLOB :=
    q'{SELECT *
        FROM (SELECT DISTINCT
                   bfr.business_org_fk                          AS buyer_org_id,
                   rtbc.identifier                              AS rtb_id,
                   rtbc.current_phase                           AS current_phase_id,
                   current_phase_jcl_en_us.constant_description AS current_phase_jcl_en_us,
                   rtbe.identifier                              AS rtb_edition_id,
                   rtbe.cac_collection1_fk                      AS rtb_cac_collection1_id,
                   rtbe.cac_collection2_fk                      AS rtb_cac_collection2_id,
                   NVL(rtbe.start_date, estimated_start_date)   AS rtb_start_date,
                   rtbe.end_date                                AS rtb_end_date,
                   rtbe.miscellaneous_terms                     AS rtb_miscellaneous_terms,
                   pa.contract_id                               AS rtb_project_agreement_id,
                   idv.value                                    AS rtb_project_number,
                   rtbe.purchase_order                          AS rtb_purchase_order,
                   CASE
                     WHEN rtbt.is_active = 1 THEN 'Y'
                     WHEN rtbt.is_active = 0 THEN 'N'
                   END                                        AS rtb_active_flag,
                   rtbe.description                           AS rtb_description,
                   fwrtbmgr.never_null_person_fk              AS rtb_mgr_id,
                   rtbe.title                                 AS rtb_title,
                   rtbt.title                                 AS rtb_template,
                   rtbe.state_code                            AS rtb_status,
                   rtbe.total_budget                          AS rtb_total_budget,
                   rtbe.currency_unit_fk                      AS rtb_currency_id,
                   cu.description                             AS rtb_currency_code,
                   rtbe.udf_collection_fk                     AS rtb_udf_collection_id
              FROM firm_role bfr,
                   firm_worker fwrtbmgr,
                   request_to_buy_continuity rtbc,
                   request_to_buy_edition rtbe,
                   request_to_buy_type rtbt,
                   project_agreement pa,
                   currency_unit cu,               
                   invoice_detail_value idv,
                   (SELECT constant_value, constant_description
                      FROM java_constant_lookup
                     WHERE constant_type    = 'REQUEST_TO_BUY_PHASE'
                       AND UPPER(locale_fk) = 'EN_US') current_phase_jcl_en_us
             WHERE  rtbc.owning_buyer_firm_fk = bfr.firm_id  
               AND rtbc.identifier             = rtbe.request_to_buy_continuity_fk
               AND rtbe.request_to_buy_type_fk = rtbt.rtb_type_id
               AND rtbe.rtb_manager_fk         = fwrtbmgr.firm_worker_id(+)
               AND rtbe.currency_unit_fk       = cu.value(+)
               AND pa.request_to_buy_fk(+)     = rtbc.identifier
               AND rtbe.project_number_fk      = idv.identifier(+)           
               AND NVL( (SELECT MAX(pav.end_date)
                           FROM contract_version cv,
                                project_agreement_version pav
                          WHERE cv.contract_fk         = pa.contract_id 
                            AND cv.contract_version_id = pav.contract_version_id(+)
                         ), SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh) 
               AND rtbc.current_phase          = current_phase_jcl_en_us.constant_value(+)  
                 )
                
     AS OF SCN lego_refresh_mgr_pkg.get_scn()
     ORDER BY buyer_org_id, rtb_id, rtb_edition_id}';

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

