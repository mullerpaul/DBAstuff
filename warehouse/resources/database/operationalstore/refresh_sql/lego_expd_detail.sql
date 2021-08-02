/*******************************************************************************
SCRIPT NAME         lego_expd_detail.sql 
 
LEGO OBJECT NAME    LEGO_EXPD_DETAIL
 
CREATED             4/19/2017
 
ORIGINAL AUTHOR     Joe Pullifrone

JIRA STORY          IQN-37425

***************************MODIFICATION HISTORY ********************************

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_expd_detail.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_EXPD_DETAIL'; 

v_clob CLOB :=
q'{ 
WITH iet AS (
  SELECT NULL AS payee_business_org_id,
         NULL AS invoice_id,
		 NULL AS invoice_number,
         invoiceable_expenditure_txn_id,
         iet.invoiceable_expenditure_fk,
         iet.rate_unit_fk                AS rate_unit_id,
		 NULL                            AS invoice_date,
		 NULL                            AS invoice_create_date,
         iet.create_date                 AS iet_create_date,
         iet.last_update_date            AS iet_last_update_date,
         iet.create_date                 AS iet_expenditure_approval_date,
         iet.base_pay_rate,
         iet.base_bill_rate,
         iet.buyer_adjusted_bill_rate,
         iet.supplier_reimbursement_rate,
         iet.payment_amount,
         iet.bill_amount,
         iet.buyer_adjusted_amount,
         iet.supplier_reimbursement_amount,
		 0 AS buyer_fee,
		 0 AS supplier_fee
    FROM invoiceable_expenditure_txn@db_link_name AS OF SCN source_db_SCN iet
   WHERE current_invoice_fk IS NULL
     AND iet.create_date >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   UNION ALL
  SELECT ind.payee_business_org_fk       AS payee_business_org_id,
         i.invoice_id,
		 i.invoice_number,
		 invoiceable_expenditure_txn_id,
         iet.invoiceable_expenditure_fk,
         iet.rate_unit_fk                AS rate_unit_id,
		 i.invoice_date,
		 i.create_date                   AS invoice_create_date,
         iet.create_date                 AS iet_create_date,
         iet.last_update_date            AS iet_last_update_date,
         iet.create_date                 AS iet_expenditure_approval_date,
         iet.base_pay_rate,
         iet.base_bill_rate,
         iet.buyer_adjusted_bill_rate,
         iet.supplier_reimbursement_rate,
         iet.payment_amount,
         iet.bill_amount,
         iet.buyer_adjusted_amount,
         iet.supplier_reimbursement_amount,
		 ilib.amount                    AS buyer_fee,    --when ind.flexrate_type is null
         ilis.amount                    AS supplier_fee  --when ind.flexrate_type is null 
     FROM invoiceable_expenditure_txn@db_link_name AS OF SCN source_db_SCN iet,
	      invoice@db_link_name AS OF SCN source_db_SCN i,
          invoice_header@db_link_name AS OF SCN source_db_SCN ih,
		  invoice_detail@db_link_name AS OF SCN source_db_SCN ind,
	      invoice_line_item@db_link_name AS OF SCN source_db_SCN ilib,
          invoice_line_item@db_link_name AS OF SCN source_db_SCN ilis
    WHERE iet.current_invoice_fk = i.invoice_id
	  AND i.invoice_id           = ih.invoice_fk
	  AND ih.invoice_header_id   = ind.invoice_header_fk
      AND ih.invoiceable_exp_owner_state_fk = 0
	  AND iet.buyer_management_fees_fk       = ilib.identifier(+)
      AND iet.supplier_management_fees_fk    = ilis.identifier(+)
      AND i.state_fk <> 2
      AND iet.create_date >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh) ) 
SELECT ieo.buyer_business_org_fk    AS buyer_org_id,
       ieo.supplier_business_org_fk AS supplier_org_id,
       iet.invoiceable_expenditure_txn_id,
       ie.invoiceable_expenditure_id,
       ieo.invoiceable_exp_owner_id,
       ieo.candidate_fk                AS candidate_id,
       ieo.assignment_continuity_fk    AS assignment_continuity_id,
       ieo.timecard_fk                 AS timecard_id,
       ie.timecard_entry_fk            AS timecard_entry_id,  
       ie.time_expenditure_fk          AS time_expenditure_id,
       ieo.payment_request_fk          AS payment_request_id,
       ie.payment_request_invdtl_fk    AS payment_request_invdtl_id,
       ieo.assignment_bonus_fk         AS assignment_bonus_id,
       ieo.project_agreement_fk        AS project_agreement_id,
       ieo.milestone_invoice_fk        AS milestone_invoice_id, 
       ie.milestone_invoice_detail_fk  AS milestone_invoice_detail_id,
       ieo.expense_report_fk           AS expense_report_id,
       ie.expense_report_line_item_fk  AS expense_report_line_item_id,
       iet.rate_unit_id,
       ie.rate_identifier_fk           AS rate_identifier_id,       
       ieo.expenditure_number,  
       iet.invoice_id,
       ie.expenditure_date             AS expenditure_date,
       ie.week_ending_date             AS week_ending_date,        
       ieo.inv_exp_create_date         AS ieo_create_date,
       iet.iet_create_date,
       ieo.submittal_date              AS ieo_submittal_date,
       ieo.last_update_date            AS ieo_last_update_date,
       iet.iet_last_update_date,
       iet.iet_expenditure_approval_date,      
       ie.quantity,
       iet.base_pay_rate,
       iet.base_bill_rate,
       iet.buyer_adjusted_bill_rate,
       iet.supplier_reimbursement_rate,
       iet.payment_amount,
       iet.bill_amount,
       iet.buyer_adjusted_amount,
       iet.supplier_reimbursement_amount,
       iet.buyer_fee,
       iet.supplier_fee,
       ie.currency_unit_fk          AS currency_unit_id,
       ie.accounting_code,
       ie.cac_one_fk                AS cac1_id,
       ie.cac_two_fk                AS cac2_id,
       ieo.has_uninvoiced_txns
  FROM iet,
       invoiceable_expenditure@db_link_name AS OF SCN source_db_SCN        ie,
       invoiceable_expenditure_owner@db_link_name AS OF SCN source_db_SCN  ieo
 WHERE ieo.invoiceable_exp_owner_id  = ie.invoiceable_exp_owner_fk
   AND ie.invoiceable_expenditure_id = iet.invoiceable_expenditure_fk}';    

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
