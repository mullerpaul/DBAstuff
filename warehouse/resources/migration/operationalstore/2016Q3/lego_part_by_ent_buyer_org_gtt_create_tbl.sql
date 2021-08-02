CREATE GLOBAL TEMPORARY TABLE lego_part_by_ent_buyer_org_gtt (
  object_name                 VARCHAR2(30),
  buyer_enterprise_bus_org_id NUMBER(38),
  buyer_org_id                NUMBER(38),
  part_name                   VARCHAR2(30),
  load_date                   DATE)
  ON COMMIT PRESERVE ROWS
/
CREATE UNIQUE INDEX part_by_ent_byr_org_gtt_x01 ON lego_part_by_ent_buyer_org_gtt(object_name, buyer_enterprise_bus_org_id, buyer_org_id)
/
