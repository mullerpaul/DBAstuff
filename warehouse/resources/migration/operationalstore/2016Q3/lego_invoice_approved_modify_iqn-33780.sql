BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE lego_invoice_approved PURGE';
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE lego_invoice_approved (
  object_name                 VARCHAR2(30),
  source_name                 VARCHAR2(6),
  invoice_id                  NUMBER(38),
  buyer_enterprise_bus_org_id NUMBER(38),
  owning_buyer_org_id         NUMBER(38) NOT NULL,
  invoice_date                DATE NOT NULL,
  load_date                   DATE DEFAULT NULL,
  load_time_sec               NUMBER(10),
  records_loaded              NUMBER(38) DEFAULT NULL)
PARTITION BY LIST (object_name)
SUBPARTITION BY LIST (source_name)
SUBPARTITION TEMPLATE (
  SUBPARTITION SP_USPROD VALUES ('USPROD'),
  SUBPARTITION SP_WFPROD VALUES ('WFPROD'))
( PARTITION P_INVD_EXPD_DET VALUES ('LEGO_INVOICED_EXPD_DETAIL'),
  PARTITION P_INVD_EXPD_DT_RU VALUES ('LEGO_INVD_EXPD_DATE_RU'))
/

ALTER TABLE lego_invoice_approved
ADD CONSTRAINT lego_invoice_approved_pk
PRIMARY KEY (object_name, source_name, invoice_id, buyer_enterprise_bus_org_id, owning_buyer_org_id)
/

ALTER TABLE lego_invoice_approved
ADD CONSTRAINT lego_invoice_approved_fk01
FOREIGN KEY (object_name, source_name)
REFERENCES lego_invoice_object (object_name, source_name)
/

