DELETE FROM lego_refresh_dependency
 WHERE object_name = 'LEGO_INVCD_EXPENDITURE_SUM'
   AND relies_on_object_name = 'LEGO_INVOICE_DETAIL'
/

COMMIT
/
