ALTER TABLE supplier_release 
MODIFY (client_name          VARCHAR2(128 CHAR),
        supplier_name        VARCHAR2(255 CHAR), 
        requisition_id       VARCHAR2(50), 
        requisition_currency VARCHAR2(50 CHAR), 
        requisition_title    VARCHAR2(255 CHAR), 
        requisition_industry VARCHAR2(255 CHAR), 
        requisition_country  VARCHAR2(100 CHAR), 
        requisition_state    VARCHAR2(100 CHAR), 
        requisition_city     VARCHAR2(100 CHAR), 
        release_tier         VARCHAR2(255 CHAR))
/


