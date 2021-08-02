
DECLARE
   v_cnt   NUMBER := 0;
BEGIN
        
        SELECT COUNT (1)
          INTO v_cnt
          FROM user_objects u
         WHERE u.object_name = 'SUPPLIER_NAME_MV'
               AND object_type = 'MATERIALIZED VIEW';
       
        IF v_cnt > 0 THEN
           EXECUTE immediate ('drop materialized view SUPPLIER_NAME_MV');
        END IF; 
        
END;
/


CREATE MATERIALIZED VIEW supplier_scorecard.supplier_name_mv (
                   qry,
                   log_in_client_guid,
                   client_guid,
                   supplier_guid,
                   Supplier_name
                   )
TABLESPACE FALCON_SUPPLIER_SCORECARD
PCTUSED    0
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
 NOCACHE
 NOCOMPRESS
 NOPARALLEL
 BUILD immediate
 REFRESH FORCE ON DEMAND
 WITH PRIMARY KEY
 AS SELECT 'Beeline' qry,
                  cvl.log_in_client_guid,
         client_guid,
         supplier_guid, 
         MAX (supplier_name) Supplier_name
    FROM SUPPLIER_SCORECARD.RELEASE_SUBMISSION_BEELINE_MV mv
    JOIN SUPPLIER_SCORECARD.client_visibility_list cvl
      ON cvl.visible_client_guid = mv.client_guid          
 GROUP BY log_in_client_guid,  client_guid,supplier_guid
         UNION ALL
  SELECT 'IQN' QRY,
         cvl.log_in_client_guid,
         client_guid,
         supplier_guid, 
         MAX (supplier_name) Supplier_name
    FROM SUPPLIER_SCORECARD.RELEASE_SUBMISSION_IQN_MV mv
    JOIN SUPPLIER_SCORECARD.client_visibility_list cvl
      ON cvl.visible_client_guid = mv.client_guid
GROUP BY log_in_client_guid, client_guid, supplier_guid
/


GRANT SELECT ON supplier_scorecard.supplier_name_mv  TO OPS
/

GRANT SELECT ON supplier_scorecard.supplier_name_mv  TO READONLY
/

GRANT SELECT ON supplier_scorecard.supplier_name_mv  TO SUPPLIER_SCORECARD_USER
/
 

