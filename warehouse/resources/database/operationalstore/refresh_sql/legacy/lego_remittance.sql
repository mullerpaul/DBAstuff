/*******************************************************************************
SCRIPT NAME         lego_remittance.sql 
 
LEGO OBJECT NAME    LEGO_REMITTANCE
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

03/28/2014 - E.Clark - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
04/09/2014 - E.Clark - IQN-15695 - fixed join to INVOICE table to restrict to x months. - Release 12.0.3
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_remittance.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_REMITTANCE'; 

  v_clob CLOB :=
   q'{SELECT ra.expenditure_buyer_org_fk        AS buyer_org_id,
             ra.supplier_organization_fk        AS supplier_org_id,
             ra.invoicing_buyer_org_fk          AS invoicing_buyer_org_id,
             ra.invoice_fk                      AS invoice_id,
             ra.invoice_header_fk               AS invoice_header_id,
             ra.supplier_invoice_number         AS custom_invoice_number,
             rp.remit_payment_id                AS remit_payment_id,
             r.remittance_id                    AS remittance_id,
             ra.remit_allocation_id             AS remit_allocation_id,
             ih.expenditure_number              AS expenditure_number,
             rp.payment_number                  AS payment_number,
             cu.value                           AS payment_currency_id,
             cu.description                     AS payment_currency,
             rp.payment_date                    AS payment_date,
             ra.bin_pay_amount                  AS payment_amount,
             ra.posting_date                    AS posting_date,
             ra.payment_term_days               AS payment_term_days,
             ra.comments                        AS comments,
             rp.payment_type                    AS payment_type,
             rp.payment_account_name            AS payment_account_name,
             ra.buyer_pymt_receipt_date         AS buyer_pymt_receipt_date
        FROM remittance                 AS OF SCN lego_refresh_mgr_pkg.get_scn r,
             remittance_payment         AS OF SCN lego_refresh_mgr_pkg.get_scn rp,
             remittance_allocation      AS OF SCN lego_refresh_mgr_pkg.get_scn ra,
             invoice_header             AS OF SCN lego_refresh_mgr_pkg.get_scn ih,
             invoice                    AS OF SCN lego_refresh_mgr_pkg.get_scn i,
             currency_unit cu
       WHERE r.remittance_id      = ra.remittance_fk
         AND r.remit_payment_fk   = rp.remit_payment_id
         AND rp.currency_unit_fk  = cu.value
         AND ra.invoice_header_fk = ih.invoice_header_id(+)
         AND ra.invoice_fk        = i.invoice_id 
         AND NVL(i.invoice_date,SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh) 
       ORDER BY buyer_org_id, supplier_org_id, invoice_id, invoice_header_id}';

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

