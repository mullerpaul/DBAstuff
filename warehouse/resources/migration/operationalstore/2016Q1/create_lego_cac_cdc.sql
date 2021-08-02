CREATE TABLE lego_cac_cdc
 (lego_cac_cdc_sk     RAW(16)             NOT NULL,   -- new PK col for this mart table (SK means "surrogate key") GUID or number?
  cac_guid            RAW(16)             NOT NULL, 
  cac_oid             VARCHAR2(500 CHAR)  , --NOT NULL, 
  cac_value           VARCHAR2(754 CHAR)  , --NOT NULL,   --really these should be NN - its just that ther is some crazy data in IQPRODD@IQP
  cac_desc            VARCHAR2(754 CHAR), 
  cac_segment_1_id    NUMBER, 
  cac_segment_1_value VARCHAR2(150 CHAR), 
  cac_segment_1_desc  VARCHAR2(150 CHAR), 
  cac_segment_2_id    NUMBER, 
  cac_segment_2_value VARCHAR2(150 CHAR), 
  cac_segment_2_desc  VARCHAR2(150 CHAR), 
  cac_segment_3_id    NUMBER, 
  cac_segment_3_value VARCHAR2(150 CHAR), 
  cac_segment_3_desc  VARCHAR2(150 CHAR), 
  cac_segment_4_id    NUMBER, 
  cac_segment_4_value VARCHAR2(150 CHAR), 
  cac_segment_4_desc  VARCHAR2(150 CHAR), 
  cac_segment_5_id    NUMBER, 
  cac_segment_5_value VARCHAR2(150 CHAR), 
  cac_segment_5_desc  VARCHAR2(150 CHAR),
  source_name         VARCHAR2(6)         NOT NULL,
  load_datetime       DATE                NOT NULL,
  load_scn            NUMBER              NOT NULL,
  source_key          RAW(16)             NOT NULL,  -- LEGO_CAC has a GUID PK - we dont need to hash it.
  source_attr_hash    NUMBER              NOT NULL)  -- change this to varchar2(32) when we move to MD5
/
  
ALTER TABLE lego_cac_cdc
ADD CONSTRAINT lego_cac_cdc_sk 
PRIMARY KEY (lego_cac_cdc_sk)
/

CREATE INDEX lego_cac_cdc_idx01
ON lego_cac_cdc (source_name, source_key, source_attr_hash)
COMPRESS 1 
/

COMMENT ON TABLE lego_cac_cdc
IS 'Stores shopshots of data in "D schema" LEGO_CAC tables from all sources.  One new row for each time a source row changed.'
/


 
 
