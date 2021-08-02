CREATE GLOBAL TEMPORARY TABLE lego_part_by_enterprise_gtt (
  object_name                 VARCHAR2(30)   NOT NULL,
  buyer_enterprise_bus_org_id NUMBER(38)     NOT NULL,
  part_name                   VARCHAR2(30)   NOT NULL,
  part_list                   CLOB NOT NULL,
  load_date                   DATE NOT NULL)
  ON COMMIT PRESERVE ROWS
/
CREATE UNIQUE INDEX lego_part_by_ent_gtt_x01 ON lego_part_by_enterprise_gtt(object_name, buyer_enterprise_bus_org_id)
/
