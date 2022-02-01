DECLARE
   SESSION_GUID                     RAW (16) := SYS_GUID;
   REQUEST_GUID                     RAW (16) := SYS_GUID;
   CLIENT_COEFFICIENT_CATEGORY_PK   RAW (16);
   REQUEST_TIMESTAMP                TIMESTAMP := SYSTIMESTAMP;
   TRANSACTION_LOG_PK               RAW (16);
BEGIN
FOR i IN  ( SELECT   CLIENT_GUID,
                     METRIC_CATEGORY
            FROM (SELECT DISTINCT client_guid FROM client_metric_coefficient) client_meric_coefficient,
                 (SELECT DISTINCT metric_category FROM metric) client_metric_category )
LOOP

CLIENT_COEFFICIENT_CATEGORY_PK := SYS_GUID;
TRANSACTION_LOG_PK := SYS_GUID;

INSERT INTO SUPPLIER_SCORECARD.TRANSACTION_LOG (
   BUS_ORG_GUID,   
   ENTITY_GUID_1,   
   ENTITY_NAME,    
   PROCESSED_TIMESTAMP,  
   REQUEST_GUID,   
   REQUEST_TIMESTAMP,  
   SESSION_GUID,  
   TXN_DATE,  
   TXN_GUID 
  )
VALUES ( I.CLIENT_GUID,
         CLIENT_COEFFICIENT_CATEGORY_PK,
         'CLIENT_CATEGORY_COEFFICIENT',
         SYSTIMESTAMP,
         REQUEST_GUID,
         REQUEST_TIMESTAMP,
         SESSION_GUID,
         SYSDATE,
         TRANSACTION_LOG_PK);


INSERT INTO SUPPLIER_SCORECARD.CLIENT_CATEGORY_COEFFICIENT (
  CLIENT_CTGRY_COEFFICIENT_GUID,
  CLIENT_GUID,
  METRIC_CATEGORY,
  CATEGORY_COEFFICIENT,
  LAST_TXN_GUID,
  EFFECTIVE_DATE )
 VALUES(CLIENT_COEFFICIENT_CATEGORY_PK,
        I.CLIENT_GUID,
        I.METRIC_CATEGORY,
        10,
        TRANSACTION_LOG_PK,
        SYSDATE);

END LOOP;

COMMIT;

EXCEPTION WHEN OTHERS THEN
   ROLLBACK;
   RAISE;
END;
/