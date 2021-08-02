-- MSVC_3923
-- Cleanup for supplier_scorecard.client_metric_conversion
-- Find records with invalid records that have 2 decimal places and round them up or down accordingly.

DECLARE
select_s VARCHAR2(256);
v_sysdate VARCHAR2(10) := to_char(SYSDATE ,'MMDDYYYY');

BEGIN
  select_s := 'ALTER TABLE SOS_MSVC_3923 RENAME TO SOS_MSVC_3923_' || v_sysdate;
  EXECUTE IMMEDIATE select_s;
EXCEPTION
  WHEN OTHERS THEN
    IF sqlcode != -0942 THEN 
      RAISE; 
    END IF;
END;
/

CREATE TABLE SOS_MSVC_3923 (
  CLIENT_METRIC_CONVERSION_GUID RAW(16) NOT NULL,
  greater_than_or_equal         NUMBER NOT NULL,
  less_than                     NUMBER NOT NULL 
)
/

INSERT INTO SOS_MSVC_3923 
(
  SELECT conv.CLIENT_METRIC_CONVERSION_GUID, greater_than_or_equal, less_than
        FROM client_metric_conversion conv
        WHERE (conv.less_than LIKE '%.___%' or conv.GREATER_THAN_OR_EQUAL LIKE '%.___%') 
)
/

COMMIT
/

DECLARE
	count_expected            number;
	count_actual              number := 0;  
  loc_greater_than_or_equal number;
  loc_less_than             number;
  
  CURSOR records_to_update
  is
    SELECT * from SOS_MSVC_3923;

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('MSVC-3923');
  
  SELECT COUNT(*) INTO count_expected FROM SOS_MSVC_3923;
  FOR aRecord IN records_to_update LOOP  
    loc_greater_than_or_equal := round(aRecord.greater_than_or_equal, 2);  
    loc_less_than := round(aRecord.less_than, 2);  
    logger_pkg.info('MSVC-3923 Update client_metric_conversion: ' || aRecord.CLIENT_METRIC_CONVERSION_GUID 
      || ' greater_than_or_equal OLD/NEW: ' || aRecord.greater_than_or_equal || ' / ' || loc_greater_than_or_equal
      || ' and less_than: OLD/NEW: ' || aRecord.less_than || ' / ' || loc_less_than);
    
    BEGIN
      update client_metric_conversion conv set 
        conv.greater_than_or_equal = loc_greater_than_or_equal,  
        conv.less_than = loc_less_than
      where conv.CLIENT_METRIC_CONVERSION_GUID = aRecord.CLIENT_METRIC_CONVERSION_GUID;  
    END;    
    count_actual := count_actual + 1;  
  END LOOP;
  
  logger_pkg.info('MSVC-3923 Updated: ' || count_actual || ' records'); 
 
  if (count_expected <> count_actual)
	then
     rollback;
     logger_pkg.info(
          'MSVC-3923 EXCEPTION: Updated wrong number of rows. Expected ' 
               || count_expected || ' inserted ' || count_actual
     );
	else
     commit;
	end if;
	
	logger_pkg.info('MSVC-3923 End');
	logger_pkg.unset_source('MSVC-3923');
END;  
/     
