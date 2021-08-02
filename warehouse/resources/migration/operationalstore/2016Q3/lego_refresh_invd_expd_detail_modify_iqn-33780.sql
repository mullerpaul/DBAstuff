UPDATE lego_refresh
   SET refresh_procedure_name = 'lego_invoice.invoice_load'
 WHERE object_name = 'LEGO_INVOICED_EXPD_DETAIL'
/