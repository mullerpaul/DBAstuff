CREATE TABLE lego_cac_collection_cdc 
 (lego_cac_collection_cdc_sk   RAW(16)         NOT NULL,   -- new PK col for this mart table (SK means "surrogate key") GUID or number?
  cac_guid                     RAW(16)         NOT NULL,
  cac_id                       NUMBER(38,0)    NOT NULL, 
  cac_kind                     NUMBER(1,0)     NOT NULL, 
  bus_org_id                   NUMBER          NOT NULL, 
  cac_collection_id            NUMBER(38,0), 
  start_date                   DATE, 
  end_date                     DATE,
  source_name                  VARCHAR2(6)     NOT NULL,
  load_datetime                DATE            NOT NULL,
  load_scn                     NUMBER          NOT NULL,
  source_key_hash              NUMBER          NOT NULL,  -- change this to varchar2(32) when we move to MD5
  source_attr_hash             NUMBER          NOT NULL)  -- change this to varchar2(32) when we move to MD5
/
  
ALTER TABLE lego_cac_collection_cdc
ADD CONSTRAINT lego_cac_collection_cdc_sk 
PRIMARY KEY (lego_cac_collection_cdc_sk)
/

CREATE INDEX lego_cac_collection_cdc_idx01
ON lego_cac_collection_cdc (source_name, source_key_hash, source_attr_hash)
COMPRESS 1
/

COMMENT ON TABLE lego_cac_collection_cdc
IS 'Stores shopshots of data in "D schema" LEGO_CAC_COLLECTION tables from all sources.  One new row for each time a source row changed.'
/


 
