/*******************************************************************************
SCRIPT NAME         lego_invoice.sql 
 
LEGO OBJECT NAME    LEGO_INVOICE
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

04/09/2014 - J.Pullifrone - IQN-15645 - added months_in_refresh for a hard limit 
                                        on data going into the lego - Release 12.0.3   
01/27/2016 - P.Muller                 - Modifications for DB links, multiple sources, and remote SCN
04/26/2017 - J.Pullifrone - IQN-37470 - add invoice approved date   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_invoice.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_INVOICE'; 

  v_clob CLOB :=
'SELECT i.invoice_id,
        i.business_organization_fk               AS buyer_org_id,
        DECODE(i.is_adjustment,0,''No'',''Yes'') AS is_adjustment,
        i.cutoff_time,
        i.expenditure_count,
        i.total_bill_amount,
        i.total_buyer_adjusted_amount,
        i.total_supplier_reimb_amount,
        i.total_fee_amount,
        i.total_buyer_fee_amount,
        i.total_supplier_fee_amount,
        i.bill_through_date,
        i.create_date                            AS invoice_create_date,
        i.create_user_fk                         AS created_by_person_id,
        i.last_update_date,
		invapprv.approved_date,
        i.last_update_user_fk                    AS last_updated_by_person_id,
        i.version,
        i.invoice_adjustment_fk                  AS invoice_adjustment_id,
        i.invoice_number,
        DECODE(i.has_taxes_discounts_applied,0,''No'',''Yes'') AS has_taxes_discounts_applied,
        i.net_buyer_adjusted_amount,
        i.total_buyer_tax_amount,
        i.total_buyer_discount_amount,
        i.configuration_edition_fk               AS configuration_edition_id,
        i.total_supplier_tax_amount,
        i.total_supplier_discount_amount,
        i.net_supplier_reimb_amount,
        i.invoice_batch_fk                       AS invoice_batch_id,
        i.invoice_date,
        i.total_mgmt_fee_tax_amount,
        i.total_mgmt_fee_rebate_amount,
        i.total_wthldg_tax_on_fee_amount,
        cu.value                                 AS currency_id,
        cu.description                           AS currency
   FROM invoice@db_link_name AS OF SCN source_db_SCN         i,
        currency_unit@db_link_name AS OF SCN source_db_SCN   cu,
		(SELECT invoice_id, MAX(timestamp) AS approved_date
           FROM invoice_event_description@db_link_name AS OF SCN source_db_SCN ied,
                event_description@db_link_name AS OF SCN source_db_SCN ed,
                invoice@db_link_name AS OF SCN source_db_SCN i
          WHERE ied.identifier = ed.identifier
            AND ed.event_name_fk = 8002
            AND i.invoice_id = ied.invoice_owner_id
          GROUP BY i.invoice_id) invapprv
  WHERE i.currency_unit_fk = cu.value(+)
    AND i.invoice_id       = invapprv.invoice_id
    AND i.state_fk         = 2
    AND i.invoice_date >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh) 
  ORDER BY i.business_organization_fk, i.invoice_date';

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

