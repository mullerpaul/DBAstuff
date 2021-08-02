CREATE TABLE client_category_coefficient
(client_ctgry_coefficient_guid RAW(16)      NOT NULL,
 client_guid                   RAW(16)      NOT NULL,
 metric_category               VARCHAR2(30) NOT NULL,
 category_coefficient          NUMBER       NOT NULL,
 last_txn_guid                 RAW(16)      NOT NULL,
 last_txn_date                 DATE         DEFAULT sys_extract_utc(systimestamp) NOT NULL,
 effective_date                DATE         NOT NULL,
 termination_date              DATE,
 CONSTRAINT client_category_coefficient_pk
   PRIMARY KEY (client_ctgry_coefficient_guid),
 CONSTRAINT client_catgry_coefficient_ck01
   CHECK (category_coefficient BETWEEN 0 AND 10),
 CONSTRAINT client_catgry_coefficient_ck02
   CHECK (metric_category IN ('candidate quality','cost','efficiency')))
/

COMMENT ON COLUMN client_category_coefficient.client_ctgry_coefficient_guid
IS 'Primary Key'
/
COMMENT ON COLUMN client_category_coefficient.client_guid
IS 'The client guid (global unique identifier)'
/
COMMENT ON COLUMN client_category_coefficient.metric_category
IS 'The name of the metric category'
/
COMMENT ON COLUMN client_category_coefficient.category_coefficient
IS 'A number between 0 and 10 (inclusive) indicating how this category is weighted against other categories'
/
COMMENT ON COLUMN client_category_coefficient.last_txn_guid
IS 'FK to TRANSACTION_LOG table'
/
COMMENT ON COLUMN client_category_coefficient.last_txn_date
IS 'Date of the last modification of this row.'
/
COMMENT ON COLUMN client_category_coefficient.effective_date
IS 'When this row became active.  Since only the termination_date column is updated, this is the insert time.'
/
COMMENT ON COLUMN client_category_coefficient.termination_date
IS 'When a new coefficient was added and this one became inactive'
/

