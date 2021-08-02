DECLARE
   ln_count   NUMBER := 0;
BEGIN
        
        SELECT COUNT (1)
          INTO ln_count
          FROM user_objects u
         WHERE u.object_name = 'CLIENT_METRIC_CONVER_IDX1'
               AND object_type = 'INDEX';
       
        IF ln_count > 0 THEN
           EXECUTE immediate ('drop index CLIENT_METRIC_CONVER_IDX1');
        END IF; 
        
        ln_count :=0;
        
        SELECT COUNT (1)
          INTO ln_count
          FROM user_objects u
         WHERE u.object_name = 'CLIENT_METRIC_COEFF_IDX1'
               AND object_type = 'INDEX';
       
        IF ln_count > 0 THEN
           EXECUTE immediate ('drop index CLIENT_METRIC_COEFF_IDX1');
        END IF; 
        
         ln_count :=0;
	        
	        SELECT COUNT (1)
	          INTO ln_count
	          FROM user_objects u
	         WHERE u.object_name = 'CLIENT_METRIC_COEFF_IDX2'
	               AND object_type = 'INDEX';
	       
	        IF ln_count > 0 THEN
	           EXECUTE immediate ('drop index CLIENT_METRIC_COEFF_IDX2');
	        END IF; 
        
        

END;
/


CREATE INDEX SUPPLIER_SCORECARD.CLIENT_METRIC_CONVER_IDX1 ON SUPPLIER_SCORECARD.CLIENT_METRIC_CONVERSION
(CLIENT_GUID)
/


CREATE INDEX SUPPLIER_SCORECARD.CLIENT_METRIC_COEFF_IDX1 ON SUPPLIER_SCORECARD.CLIENT_METRIC_COEFFICIENT
(CLIENT_GUID)
/

CREATE INDEX SUPPLIER_SCORECARD.CLIENT_METRIC_COEFF_IDX2 ON SUPPLIER_SCORECARD.CLIENT_METRIC_COEFFICIENT
(METRIC_ID)
/
