CREATE GLOBAL TEMPORARY TABLE lego_buyers_by_ent_inv_gtt (
  object_name                 VARCHAR2(30),
  buyer_enterprise_bus_org_id NUMBER(38),
  buyer_org_id                NUMBER(38),
  invoice_id                  NUMBER(38),
  load_date                   DATE)
  ON COMMIT PRESERVE ROWS
/
CREATE UNIQUE INDEX lego_buyers_by_ent_inv_gtt_x01 ON lego_buyers_by_ent_inv_gtt(object_name, buyer_enterprise_bus_org_id, buyer_org_id, invoice_id)
/
