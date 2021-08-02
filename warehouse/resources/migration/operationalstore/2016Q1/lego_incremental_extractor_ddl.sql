/* This table will track and determine incremental loads.  */
CREATE TABLE lego_incremental_extractor (
  object_name                VARCHAR2(30),
  data_source                VARCHAR2(30),
  batch_id                   NUMBER(20),
  bucket_id                  NUMBER(20),
  bucket_gte_dt              DATE,
  bucket_lt_dt               DATE,
  last_successful_extract_dt DATE,
  extract_count              NUMBER(20),
  snapshot_load_dt           DATE)
/

ALTER TABLE lego_incremental_extractor
ADD CONSTRAINT lego_incremental_extractor_pk 
PRIMARY KEY (object_name, data_source, batch_id, bucket_gte_dt)
/

GRANT SELECT, UPDATE ON lego_incremental_extractor TO ops
/
