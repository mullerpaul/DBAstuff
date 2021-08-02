UPDATE lego_refresh
   SET refresh_schedule = 'TWICE DAILY'
 WHERE refresh_group = 2
/

UPDATE lego_refresh
   SET storage_clause = 'NOLOGGING'
 WHERE refresh_group = 2
   AND storage_clause <> 'NOLOGGING'
/

COMMIT
/

   
