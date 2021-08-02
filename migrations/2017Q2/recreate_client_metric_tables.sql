DECLARE
  le_table_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_table_not_exist, -00942);
  
BEGIN
  /* This script will drop the two client metric tables if they exist.
     If they don't exist, this does nothing.
     We need this branching logic so our deploy will work in databases
     where the tables already have been deployed, AND in new installs 
     which are built from scratch, AND ones where a deployment has failed in the middle.  
     Hopefully, the need for this kind of thing will be reduced in the future! */

  BEGIN
    EXECUTE IMMEDIATE ('drop table client_metric_conversion');
  EXCEPTION
    WHEN le_table_not_exist THEN
      NULL;
  END;

  BEGIN
    EXECUTE IMMEDIATE ('drop table client_metric_coefficient');
  EXCEPTION
    WHEN le_table_not_exist THEN
      NULL;
  END;

END;
/

---
CREATE TABLE client_metric_coefficient (
  client_metric_coefficient_guid  RAW(16)  NOT NULL,
  client_guid                     RAW(16)  NOT NULL,
  metric_id                       NUMBER   NOT NULL,
  metric_coefficient              NUMBER   NOT NULL,
  last_txn_guid                   RAW(16)  NOT NULL,
  last_txn_date                   DATE     DEFAULT sys_extract_utc(systimestamp) NOT NULL
)
/

ALTER TABLE client_metric_coefficient ADD CONSTRAINT client_metric_coefficient_pk 
PRIMARY KEY (client_metric_coefficient_guid)
/
ALTER TABLE client_metric_coefficient ADD CONSTRAINT client_metric_coefficient_uk 
UNIQUE (client_guid, metric_id)
/
ALTER TABLE client_metric_coefficient ADD CONSTRAINT client_metric_coefficient_fk01
FOREIGN KEY (metric_id) REFERENCES metric (metric_id)
/
ALTER TABLE client_metric_coefficient ADD CONSTRAINT client_metric_coefficient_fk02
FOREIGN KEY (last_txn_guid) REFERENCES transaction_log (txn_guid)
/
COMMENT ON TABLE client_metric_coefficient IS 'Client specific metric weights.'
/
COMMENT ON COLUMN client_metric_coefficient.client_guid IS 'Unique Identifier for a client.'
/
COMMENT ON COLUMN client_metric_coefficient.metric_id IS 'Unique Identifier for a metric.'
/
COMMENT ON COLUMN client_metric_coefficient.metric_coefficient IS 'Weight applied to metric in formula for score.'
/

---
CREATE TABLE client_metric_conversion (
  client_metric_conversion_guid   RAW(16)      NOT NULL,
  client_metric_coefficient_guid  RAW(16)      NOT NULL,
  greater_than_or_equal           NUMBER       NOT NULL,
  less_than                       NUMBER       NOT NULL,
  range_grade                     VARCHAR2(1)  NOT NULL,
  range_score                     NUMBER,
  range_score_conversion_factor   NUMBER,
  last_txn_guid                   RAW(16)      NOT NULL,
  last_txn_date                   DATE    DEFAULT sys_extract_utc(systimestamp) NOT NULL
)
/

ALTER TABLE client_metric_conversion ADD CONSTRAINT client_metric_conversion_pk
PRIMARY KEY (client_metric_conversion_guid)
/
ALTER TABLE client_metric_conversion ADD CONSTRAINT client_metric_conversion_fk01
FOREIGN KEY (client_metric_coefficient_guid) REFERENCES client_metric_coefficient (client_metric_coefficient_guid)
/
ALTER TABLE client_metric_conversion ADD CONSTRAINT client_metric_conversion_fk02
FOREIGN KEY (last_txn_guid) REFERENCES transaction_log (txn_guid)
/
ALTER TABLE client_metric_conversion ADD CONSTRAINT client_metric_conversion_ck01
CHECK (range_grade IN ('A','B','C','D','F'))
/
-- Either range_score OR range_score_conversion_factor MUST be populated; but not both!
ALTER TABLE client_metric_conversion ADD CONSTRAINT client_metric_conversion_ck02
CHECK ((range_score IS     NULL AND range_score_conversion_factor IS NOT NULL) OR
       (range_score IS NOT NULL AND range_score_conversion_factor IS     NULL))
/

COMMENT ON TABLE client_metric_conversion IS 'Used to convert raw metric scores into grades and score points.'
/
COMMENT ON COLUMN client_metric_conversion.client_metric_conversion_guid IS 'The identifier for this metric range band.'
/
COMMENT ON COLUMN client_metric_conversion.client_metric_coefficient_guid IS 'The identifier for the parent row'
/
COMMENT ON COLUMN client_metric_conversion.less_than IS 'Bound (less than x) for metric grade and score value.'
/
COMMENT ON COLUMN client_metric_conversion.greater_than_or_equal IS 'Bound (greater than or equal to x) for metric grade and score value.'
/
COMMENT ON COLUMN client_metric_conversion.range_grade IS 'The grade (A,B,C,D or F) for the associated range.'
/
COMMENT ON COLUMN client_metric_conversion.range_score IS 'A constant point score for metric values in this range.'
/
COMMENT ON COLUMN client_metric_conversion.range_score_conversion_factor IS 'A conversion factor used to convert metric scores in this range into points.'
/

