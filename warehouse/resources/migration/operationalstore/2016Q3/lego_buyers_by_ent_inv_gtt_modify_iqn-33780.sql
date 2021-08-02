BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE lego_buyers_by_ent_inv_gtt PURGE';
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE GLOBAL TEMPORARY TABLE lego_buyers_by_ent_inv_gtt (
  object_name                 VARCHAR2(30) NOT NULL,
  source_name                 VARCHAR2(30) NOT NULL,
  buyer_enterprise_bus_org_id NUMBER(38)   NOT NULL,
  buyer_org_id                NUMBER(38)   NOT NULL,
  invoice_id                  NUMBER(38)   NOT NULL,
  load_date                   DATE         NOT NULL) 
  ON COMMIT PRESERVE ROWS
/
CREATE UNIQUE INDEX lego_buyers_by_ent_inv_gtt_x01 ON lego_buyers_by_ent_inv_gtt(object_name, source_name, buyer_enterprise_bus_org_id, buyer_org_id, invoice_id)
/
