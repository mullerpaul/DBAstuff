DROP TABLE excluded_candidate PURGE
/
DROP TABLE excluded_requisition PURGE
/

---
CREATE TABLE excluded_candidate (
  excluded_candidate_guid RAW(16) NOT NULL,
  client_guid             RAW(16) NOT NULL,
  candidate_guid          RAW(16) NOT NULL,
  last_txn_guid           RAW(16) NOT NULL,
  last_txn_date           DATE    DEFAULT sys_extract_utc(systimestamp) NOT NULL
)
/

ALTER TABLE excluded_candidate ADD CONSTRAINT excluded_candidate_pk PRIMARY KEY (excluded_candidate_guid)
/
ALTER TABLE excluded_candidate ADD CONSTRAINT excluded_candidate_uk UNIQUE (client_guid, candidate_guid)
/
ALTER TABLE excluded_candidate ADD CONSTRAINT excluded_candidate_fk01
FOREIGN KEY (last_txn_guid) REFERENCES transaction_log (txn_guid)
/
COMMENT ON TABLE excluded_candidate IS 'Candidates the client wants excluded from metric scores.'
/
COMMENT ON COLUMN excluded_candidate.client_guid IS 'Unique Identifier for client.'
/
COMMENT ON COLUMN excluded_candidate.candidate_guid IS 'Unique Identifier for candidate.'
/

---
CREATE TABLE excluded_requisition (
  excluded_requisition_guid RAW(16) NOT NULL,
  client_guid               RAW(16) NOT NULL,
  requisition_guid          RAW(16) NOT NULL,
  last_txn_guid             RAW(16) NOT NULL,
  last_txn_date             DATE    DEFAULT sys_extract_utc(systimestamp) NOT NULL
)
/

ALTER TABLE excluded_requisition ADD CONSTRAINT excluded_requisition_pk PRIMARY KEY (excluded_requisition_guid)
/
ALTER TABLE excluded_requisition ADD CONSTRAINT excluded_requisition_uk UNIQUE (client_guid, requisition_guid)
/
ALTER TABLE excluded_requisition ADD CONSTRAINT excluded_requisition_fk01
FOREIGN KEY (last_txn_guid) REFERENCES transaction_log (txn_guid)
/
COMMENT ON TABLE excluded_requisition IS 'Requisitions the client wants excluded from metric scores.'
/
COMMENT ON COLUMN excluded_requisition.client_guid IS 'Unique Identifier for client.'
/
COMMENT ON COLUMN excluded_requisition.requisition_guid IS 'Unique Identifier for requisition.'
/


