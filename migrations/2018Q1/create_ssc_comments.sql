CREATE TABLE supplier_scorecard_comments (
  client_guid   RAW(16) NOT NULL,
  last_txn_date        DATE DEFAULT sys_extract_utc(systimestamp),
  created_by_username   VARCHAR2(100 CHAR) ,
  comments             VARCHAR2(4000 CHAR)
)
/

ALTER TABLE supplier_scorecard_comments ADD CONSTRAINT ssc_comments_pk PRIMARY KEY (client_guid)
/
