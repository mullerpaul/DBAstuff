/*******************************************************************************
SCRIPT NAME         lego_invcd_expenditure_sum.sql 
 
LEGO OBJECT NAME    LEGO_INVCD_EXPENDITURE_SUM
 
CREATED             8/19/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

08/19/2014 - J.Pullifrone - IQN-19552 - new refresh_sql created - Release 12.2.0  
09/04/2014 - J.Pullifrone - IQN-18776 - for Payment Requests, getting payment_request_invdtl_id
                                        instead of payment_request_id - Release 12.2.0 
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_invcd_expenditure_sum.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_INVCD_EXPENDITURE_SUM'; 

  v_clob CLOB :=
q'{SELECT expenditure_type, expenditure_id, invoiced_amount 
     FROM (
           SELECT expenditure_type, payment_request_invdtl_id as expenditure_id, SUM(buyer_adjusted_amount) AS invoiced_amount
            FROM lego_invoice_detail 
           WHERE expenditure_type = 'Payment Requests'
             AND invoice_transaction_type NOT IN ('Buyer Management Fee','Supplier Management Fee')
           GROUP BY expenditure_type, payment_request_invdtl_id
        UNION ALL
           SELECT expenditure_type, milestone_invoice_detail_id as expenditure_id, SUM(buyer_adjusted_amount) AS invoiced_amount
             FROM lego_invoice_detail 
            WHERE expenditure_type = 'Milestones'
              AND invoice_transaction_type NOT IN ('Buyer Management Fee','Supplier Management Fee')
            GROUP BY expenditure_type, milestone_invoice_detail_id
        UNION ALL
           SELECT expenditure_type, milestone_invoice_detail_id as expenditure_id, SUM(buyer_adjusted_amount) AS invoiced_amount
             FROM lego_invoice_detail 
            WHERE expenditure_type = 'Rate Table'
              AND invoice_transaction_type NOT IN ('Buyer Management Fee','Supplier Management Fee')
            GROUP BY expenditure_type, milestone_invoice_detail_id            
        UNION ALL
           SELECT expenditure_type, timecard_entry_id as expenditure_id, SUM(buyer_adjusted_amount) AS invoiced_amount
             FROM lego_invoice_detail 
            WHERE expenditure_type = 'Time'
              AND invoice_transaction_type NOT IN ('Buyer Management Fee','Supplier Management Fee')
            GROUP BY expenditure_type, timecard_entry_id
        UNION ALL
           SELECT expenditure_type, expense_report_line_item_id as expenditure_number, SUM(buyer_adjusted_amount) AS invoiced_amount
             FROM lego_invoice_detail 
            WHERE expenditure_type = 'Expense'
              AND invoice_transaction_type NOT IN ('Buyer Management Fee','Supplier Management Fee')
            GROUP BY expenditure_type, expense_report_line_item_id)
            ORDER BY 1,2}'; 

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

