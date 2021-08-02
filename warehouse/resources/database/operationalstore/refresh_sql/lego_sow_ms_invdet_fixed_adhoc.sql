/*******************************************************************************
SCRIPT NAME         lego_sow_ms_invdet_fixed_adhoc.sql 
 
LEGO OBJECT NAME    LEGO_SOW_MS_INVDET_FIXED_ADHOC
 
CREATED             08/29/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

JIRA STORY          IQN-33506

***************************MODIFICATION HISTORY ********************************

08/08/2016 - jpullifrone  - IQN-34758 - adding joins to lego_cac_collection to get cac_guid,
                                        which will then be used to get cac values and desc
                                        
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_sow_ms_invdet_fixed_adhoc.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_SOW_MS_INVDET_FIXED_ADHOC'; 

  v_clob CLOB :=
q'{ SELECT mid.milestone_invoice_fk AS milestone_invoice_id,
           mid.milestone_invoice_detail_id,       
           CASE 
             WHEN mi.fixed_payment_milestone_fk IS NOT NULL THEN ppm.title 
             WHEN mi.ad_hoc_payment_type_fk IS NOT NULL THEN pt.description
           ELSE 'Unknown' --should not happen
           END AS payment_type,
           mid.allocation_percentage,
           epr.supplier_reimbursement_amt,
           sili.amount AS supplier_fee,
           epr.buyer_adjusted_amt,
           bili.amount AS buyer_fee,
           mili.amount AS markup_amt,
           epr.payment_amount AS payment_request_amount,       
           mid.cac_one_fk  AS cac1_id,
           cac1.cac_guid   AS cac1_guid,
           cac1.start_date AS cac1_start_date,
           cac1.end_date   AS cac1_end_date,
           mid.cac_two_fk  AS cac2_id,
           cac2.cac_guid   AS cac2_guid,
           cac2.start_date AS cac2_start_date,
           cac2.end_date   AS cac2_end_date,           
           cu.description  AS currency         
      FROM milestone_invoice@db_link_name AS OF SCN source_db_SCN mi,
           milestone_invoice_detail@db_link_name AS OF SCN source_db_SCN mid,
           project_payment_milestone@db_link_name AS OF SCN source_db_SCN ppm,
           payment_type@db_link_name AS OF SCN source_db_SCN pt,
           expenditure@db_link_name AS OF SCN source_db_SCN epr,
           invoice_line_item@db_link_name AS OF SCN source_db_SCN bili,
           invoice_line_item@db_link_name AS OF SCN source_db_SCN sili,
           invoice_line_item@db_link_name AS OF SCN source_db_SCN mili,
           lego_cac_collection@db_link_name cac1,
           lego_cac_collection@db_link_name cac2,
           currency_unit@db_link_name cu
     WHERE mi.identifier = mid.milestone_invoice_fk
       AND mi.fixed_payment_milestone_fk = ppm.payment_milestone_id(+)
       AND mi.ad_hoc_payment_type_fk = pt.identifier(+)
       AND mid.expenditure_fk       = epr.identifier
       AND epr.buyer_trx_fee_fk     = bili.identifier(+)
       AND epr.supplier_trx_fee_fk  = sili.identifier(+)
       AND epr.markup_trx_fee_fk    = mili.identifier(+)
       AND mid.cac_one_fk           = cac1.cac_id(+)
       AND mid.cac_two_fk           = cac2.cac_id(+)
       AND mid.currency_fk          = cu.value(+) 
       AND (mi.fixed_payment_milestone_fk IS NOT NULL OR mi.ad_hoc_payment_type_fk IS NOT NULL) }';

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

