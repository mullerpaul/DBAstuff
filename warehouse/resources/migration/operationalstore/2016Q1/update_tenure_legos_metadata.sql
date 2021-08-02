UPDATE lego_refresh
   SET refresh_procedure_name = 'lego_tenure.load_lego_tenure'
 WHERE object_name = 'LEGO_TENURE'
/

COMMIT
/

