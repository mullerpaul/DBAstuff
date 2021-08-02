CREATE TABLE lego_invoice_approved (
  invoice_id                  NUMBER(38),
  buyer_enterprise_bus_org_id NUMBER(38),
  owning_buyer_org_id         NUMBER(38) NOT NULL,
  invoice_date                DATE NOT NULL,
  detail_load_date            DATE DEFAULT NULL,
  load_time_sec               NUMBER(10),
  records_loaded              NUMBER(38) DEFAULT NULL)
/

ALTER TABLE lego_invoice_approved
ADD CONSTRAINT lego_invoice_approved_pk
PRIMARY KEY (invoice_id, buyer_enterprise_bus_org_id, owning_buyer_org_id)
/
