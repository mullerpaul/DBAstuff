/*******************************************************************************
SCRIPT NAME         lego_sow_ms_invdet_rate_tables.sql 
 
LEGO OBJECT NAME    LEGO_SOW_MS_INVDET_RATE_TABLES
 
CREATED             08/29/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

JIRA STORY          IQN-33506

***************************MODIFICATION HISTORY ********************************

08/08/2016 - jpullifrone  - IQN-34758 - adding joins to lego_cac_collection to get cac_guid,
                                        which will then be used to get cac values and desc
                                        
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_sow_ms_invdet_rate_tables.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_SOW_MS_INVDET_RATE_TABLES'; 

  v_clob CLOB :=
q'{ SELECT mid.milestone_invoice_fk AS milestone_invoice_id,
           mid2.milestone_invoice_detail_id,
           mid.service_fk AS service_id,
           mid.fixed_proj_resource_desc_fk AS project_resource_desc_id,
           mid.res_rate_table_edition_fk AS res_rate_table_edition_id,
           mid.resource_service_rate_fk AS resource_service_rate_id,
           mid.resource_detail_type,
           mid.timecard_fk AS timecard_id,
           mid.standard_service_rate_fk AS standard_service_rate_id,
           mid.distribution_line_number,  --verified that it should be this table
           mid.start_date AS deliverable_start_date,  --verified that it should be this table
           mid.end_date AS deliverable_end_date,  --verified that it should be this table
           mid.comments AS line_comment,  --should this be included...commments in general?     
           mid.allocation_percentage,  --verified that it should be this table
           mid.expenditure_fk AS expenditure_id,
           epr.supplier_reimbursement_amt,
           sili.amount AS supplier_fee,
           epr.buyer_adjusted_amt,
           bili.amount AS buyer_fee,
           epr.rate AS negotiable_rate,
           epr.quantity,
           epr.payment_amount AS payment_request_amount,       
           mid2.cac_one_fk  AS cac1_id,
           cac1.cac_guid    AS cac1_guid,
           cac1.start_date  AS cac1_start_date,
           cac1.end_date    AS cac1_end_date,
           mid2.cac_two_fk  AS cac2_id,
           cac2.cac_guid    AS cac2_guid,
           cac2.start_date  AS cac2_start_date,
           cac2.end_date    AS cac2_end_date,              
           cu.description AS currency         
      FROM milestone_invoice_detail@db_link_name AS OF SCN source_db_SCN mid,
           milestone_invoice_detail@db_link_name AS OF SCN source_db_SCN mid2,
           expenditure@db_link_name AS OF SCN source_db_SCN epr,
           invoice_line_item@db_link_name AS OF SCN source_db_SCN bili,
           invoice_line_item@db_link_name AS OF SCN source_db_SCN sili,
           lego_cac_collection@db_link_name cac1,
           lego_cac_collection@db_link_name cac2,           
           currency_unit@db_link_name cu
     WHERE mid.milestone_invoice_detail_id = mid2.parent_milestone_inv_detail_fk       
       AND mid.expenditure_fk        = epr.identifier
       AND epr.buyer_trx_fee_fk      = bili.identifier(+)
       AND epr.supplier_trx_fee_fk   = sili.identifier(+)
       AND mid2.cac_one_fk           = cac1.cac_id(+)
       AND mid2.cac_two_fk           = cac2.cac_id(+)       
       AND mid2.currency_fk          = cu.value(+)}';

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

