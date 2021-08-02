DECLARE
   ln_count   NUMBER := 0;
BEGIN
        
        SELECT COUNT (1)
          INTO ln_count
          FROM user_objects u
         WHERE u.object_name = 'METRIC_DATA_IDX1'
               AND object_type = 'INDEX';
       
        IF ln_count > 0 THEN
           EXECUTE immediate ('drop index  METRIC_DATA_IDX1');
        END IF; 
        
        ln_count :=0;
        
         SELECT COUNT (1)
          INTO ln_count
          FROM user_objects u
         WHERE u.object_name = 'METRIC_DATA_IDX2'
               AND object_type = 'INDEX';
       
        IF ln_count > 0 THEN
           EXECUTE immediate ('drop index  METRIC_DATA_IDX2');
        END IF; 
        
END;
/

CREATE INDEX SUPPLIER_SCORECARD.METRIC_DATA_IDX1 ON SUPPLIER_SCORECARD.METRIC_DATA_MV
(CLIENT_GUID)
/


CREATE INDEX SUPPLIER_SCORECARD.METRIC_DATA_IDX2 ON SUPPLIER_SCORECARD.METRIC_DATA_MV
(METRIC_SCORE_DATE)
/




