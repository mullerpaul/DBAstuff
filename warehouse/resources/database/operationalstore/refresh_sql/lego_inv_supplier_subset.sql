/*******************************************************************************
SCRIPT NAME         lego_inv_supplier_subset.sql 
 
LEGO OBJECT NAME    LEGO_INV_SUPPLIER_SUBSET
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

 
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_inv_supplier_subset.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_INV_SUPPLIER_SUBSET'; 

  v_clob CLOB :=
     q'{SELECT iss.supplier_bus_org_fk AS supplier_org_id, 
               iss.invoice_fk          AS invoice_id, 
               isx.invoice_detail_fk   AS invoice_detail_id, 
               ibsssx.supplier_invoice_number, 
               ibsssx.supplier_invoice_date  
          FROM invoiced_supplier_subset     AS OF SCN lego_refresh_mgr_pkg.get_scn() iss, 
               inv_supp_subset_inv_detail_x AS OF SCN lego_refresh_mgr_pkg.get_scn() isx,
               inv_buy_subset_supp_subset_x AS OF SCN lego_refresh_mgr_pkg.get_scn() ibsssx
         WHERE ibsssx.invoiced_supplier_subset_fk = iss.invoiced_supplier_subset_id
           AND isx.invoiced_supplier_subset_fk    = iss.invoiced_supplier_subset_id
           AND ibsssx.invoiced_buyer_subset_fk    IS NULL
           AND (ibsssx.supplier_invoice_date      IS NOT NULL OR ibsssx.supplier_invoice_number IS NOT NULL)
           AND iss.invoice_fk                     IS NOT NULL   
           AND iss.is_iqn_supplier_subset         = 0
        UNION ALL
        SELECT iss.supplier_bus_org_fk AS supplier_org_id, 
               iss.invoice_fk          AS invoice_id, 
               isx.invoice_detail_fk   AS invoice_detail_id, 
               ibsssx.supplier_invoice_number, 
               ibsssx.supplier_invoice_date 
          FROM invoiced_supplier_subset iss, 
               inv_supp_subset_inv_detail_x AS OF SCN lego_refresh_mgr_pkg.get_scn() isx,
               inv_buy_subset_inv_detail_x  AS OF SCN lego_refresh_mgr_pkg.get_scn() ibx, 
               inv_buy_subset_supp_subset_x AS OF SCN lego_refresh_mgr_pkg.get_scn() ibsssx
         WHERE ibsssx.invoiced_supplier_subset_fk = iss.invoiced_supplier_subset_id
           AND ibsssx.invoiced_buyer_subset_fk    = ibx.invoiced_buyer_subset_fk
           AND ibx.invoice_detail_fk              = isx.invoice_detail_fk 
           AND isx.invoiced_supplier_subset_fk    = iss.invoiced_supplier_subset_id
           AND (ibsssx.supplier_invoice_date      IS NOT NULL OR ibsssx.supplier_invoice_number IS NOT NULL)
           AND iss.invoice_fk                     IS NOT NULL
           AND iss.is_iqn_supplier_subset         = 0
           ORDER BY supplier_org_id, invoice_id, invoice_detail_id, supplier_invoice_number, supplier_invoice_date}';

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

