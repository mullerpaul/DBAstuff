CREATE TABLE lego_cac_history
 (cac_guid            RAW(16)        NOT NULL,
  source_name         VARCHAR2(6)    NOT NULL,
  attribute_md5_hash  VARCHAR2(32)   NOT NULL,
  load_date           DATE           NOT NULL,
  cac_oid             VARCHAR2(500),
  cac_value           VARCHAR2(754),
  cac_desc            VARCHAR2(754),
  cac_segment_1_id    NUMBER,
  cac_segment_1_value VARCHAR2(150),
  cac_segment_1_desc  VARCHAR2(150),
  cac_segment_2_id    NUMBER,
  cac_segment_2_value VARCHAR2(150),
  cac_segment_2_desc  VARCHAR2(150),
  cac_segment_3_id    NUMBER,
  cac_segment_3_value VARCHAR2(150),
  cac_segment_3_desc  VARCHAR2(150),
  cac_segment_4_id    NUMBER,
  cac_segment_4_value VARCHAR2(150),
  cac_segment_4_desc  VARCHAR2(150),
  cac_segment_5_id    NUMBER,
  cac_segment_5_value VARCHAR2(150),
  cac_segment_5_desc  VARCHAR2(150))
/

-- This index should speed the load process since it contains all three comparison columns
CREATE INDEX lego_cac_history_idx
ON lego_cac_history (source_name, cac_guid, attribute_md5_hash)
COMPRESS 1  -- compress the source name as it will be HIGHLY repetitive
/


CREATE TABLE lego_cac_collection_history
 (cac_id             NUMBER       NOT NULL,
  source_name        VARCHAR2(6)  NOT NULL,
  attribute_md5_hash VARCHAR2(32) NOT NULL,
  load_date          DATE         NOT NULL,
  bus_org_id         NUMBER       NOT NULL,
  cac_guid           RAW(16),     -- you'd think this would be not null also, but there is one NULL row in IQP!
  cac_kind           NUMBER(1)    NOT NULL,
  cac_collection_id  NUMBER,      -- and this!  how confusing is it that this col is NOT the PK of this table?
  start_date         DATE,
  end_date           DATE)
/

-- This index should speed the load process since it contains all three comparison columns
CREATE INDEX lego_cac_collection_hist_idx
ON lego_cac_collection_history (source_name, cac_id, attribute_md5_hash)
COMPRESS 1
/


