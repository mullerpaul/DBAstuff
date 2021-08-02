INSERT INTO lego_refresh
  SELECT 'LEGO_SUPPLIER_SCORECARD',
         source_name,
         refresh_method,
         refresh_schedule,
         refresh_group,
         refresh_dependency_order,
         NVL(refresh_on_or_after_time,TRUNC(SYSDATE)) - 7,
         'N',
         storage_clause,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         'lego_supplier_scorecard.load_supplier_scorecard'
    FROM lego_refresh
   WHERE object_name = 'LEGO_SUPPLIER_RELEASE'
     AND source_name = 'USPROD'
/  
        
DELETE FROM lego_refresh
 WHERE object_name IN('LEGO_SUPPLIER_SUBMISSION','LEGO_SUPPLIER_RELEASE')
/

DELETE FROM lego_refresh
 WHERE refresh_group = 15
/

COMMIT
/