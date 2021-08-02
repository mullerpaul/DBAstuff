/* 
 Created: 3/8/2017 
 Modified: 3/17/2017 
 Author: Lukas A - WI6
 Model: Supplier Scorecard
 Database: Oracle 12c 
*/

--TABLES, KEYS & COMMENTS
CREATE TABLE metric (
  metric_id           NUMBER        NOT NULL,
  metric_name         VARCHAR2(30)  NOT NULL,
  metric_category     VARCHAR2(30)  NOT NULL,
  enabled_flag        VARCHAR2(1)   NOT NULL,
  default_coefficient NUMBER        NOT NULL,
  description         VARCHAR2(100)
)
/

ALTER TABLE metric ADD CONSTRAINT metric_pk PRIMARY KEY (metric_id)
/
ALTER TABLE metric ADD CONSTRAINT metric_ck01 CHECK (enabled_flag in ('Y','N'))
/
ALTER TABLE metric ADD CONSTRAINT metric_ck02
CHECK (metric_category IN ('candidate quality','cost','efficiency'))
/

COMMENT ON TABLE metric IS 'Master record of all metrics used in supplier scorecard.'
/
COMMENT ON COLUMN metric.metric_id IS 'Unique Identifier.'
/
COMMENT ON COLUMN metric.metric_name IS 'The displayable name of the metric.'
/
COMMENT ON COLUMN metric.metric_category IS 'One of three categories a metric may count towards.'
/
COMMENT ON COLUMN metric.enabled_flag IS 'A yes or no flag which indicates if the metric is in use.  Intended as a way to filter out metrics where the base data is not yet available.'
/
COMMENT ON COLUMN metric.description IS 'Description of the metric and what it indicates.'
/
COMMENT ON COLUMN metric.default_coefficient IS 'Default weight applied to this metric in the formula for score. The metric score is multiplied by this to compute final score.'
/

---
CREATE TABLE default_metric_conversion (
  default_metric_conversion_id  NUMBER      NOT NULL,
  metric_id                     NUMBER      NOT NULL,
  greater_than_or_equal         NUMBER      NOT NULL,
  less_than                     NUMBER      NOT NULL,
  range_grade                   VARCHAR2(1) NOT NULL,
  range_score                   NUMBER,
  range_score_conversion_factor NUMBER
)
/

ALTER TABLE default_metric_conversion ADD CONSTRAINT default_metric_conversion_pk
PRIMARY KEY (default_metric_conversion_id)
/
ALTER TABLE default_metric_conversion ADD CONSTRAINT default_metric_conversion_fk01
FOREIGN KEY (metric_id) REFERENCES metric (metric_id)
/
ALTER TABLE default_metric_conversion ADD CONSTRAINT default_metric_conversion_ck01
CHECK (range_grade IN ('A','B','C','D','F'))
/
-- Either range_score OR range_score_conversion_factor MUST be populated; but not both!
ALTER TABLE default_metric_conversion ADD CONSTRAINT default_metric_conversion_ck02
CHECK ((range_score IS     NULL AND range_score_conversion_factor IS NOT NULL) OR
       (range_score IS NOT NULL AND range_score_conversion_factor IS     NULL))
/

COMMENT ON TABLE default_metric_conversion IS 'Used to convert raw metric scores into grades and score points.'
/
COMMENT ON COLUMN default_metric_conversion.default_metric_conversion_id IS 'The identifier for this metric range band.'
/
COMMENT ON COLUMN default_metric_conversion.metric_id IS 'The metric identifier.'
/
COMMENT ON COLUMN default_metric_conversion.less_than IS 'Bound (less than x) for metric grade and score value.'
/
COMMENT ON COLUMN default_metric_conversion.greater_than_or_equal IS 'Bound (greater than or equal to x) for metric grade and score value.'
/
COMMENT ON COLUMN default_metric_conversion.range_grade IS 'The grade (A,B,C,D or F) for the associated range.'
/
COMMENT ON COLUMN default_metric_conversion.range_score IS 'A constant point score for metric values in this range.'
/
COMMENT ON COLUMN default_metric_conversion.range_score_conversion_factor IS 'A conversion factor used to convert metric scores in this range into points.'
/

---
CREATE TABLE excluded_candidate (
  excluded_candidate_guid RAW(16) NOT NULL,
  client_guid             RAW(16) NOT NULL,
  candidate_guid          RAW(16) NOT NULL
)
/

ALTER TABLE excluded_candidate ADD CONSTRAINT excluded_candidate_pk PRIMARY KEY (excluded_candidate_guid)
/
ALTER TABLE excluded_candidate ADD CONSTRAINT excluded_candidate_uk UNIQUE (client_guid, candidate_guid)
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
  requisition_guid          RAW(16) NOT NULL
)
/

ALTER TABLE excluded_requisition ADD CONSTRAINT excluded_requisition_pk PRIMARY KEY (excluded_requisition_guid)
/
ALTER TABLE excluded_requisition ADD CONSTRAINT excluded_requisition_uk UNIQUE (client_guid, requisition_guid)
/
COMMENT ON TABLE excluded_requisition IS 'Requisitions the client wants excluded from metric scores.'
/
COMMENT ON COLUMN excluded_requisition.client_guid IS 'Unique Identifier for client.'
/
COMMENT ON COLUMN excluded_requisition.requisition_guid IS 'Unique Identifier for requisition.'
/

---
CREATE TABLE client_metric_coefficient (
  client_metric_coefficient_guid  RAW(16)  NOT NULL,
  client_guid                     RAW(16)  NOT NULL,
  metric_id                       NUMBER   NOT NULL,
  metric_coefficient              NUMBER   NOT NULL
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
  range_score_conversion_factor   NUMBER
)
/

ALTER TABLE client_metric_conversion ADD CONSTRAINT client_metric_conversion_pk
PRIMARY KEY (client_metric_conversion_guid)
/
ALTER TABLE client_metric_conversion ADD CONSTRAINT client_metric_conversion_fk01
FOREIGN KEY (client_metric_coefficient_guid) REFERENCES client_metric_coefficient (client_metric_coefficient_guid)
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

---
CREATE TABLE transaction_log (
	txn_guid		RAW(16) NOT NULL,
	txn_date		DATE DEFAULT SYSDATE NOT NULL,
	session_guid        	RAW (16) NOT NULL,
	request_guid         	RAW (16) NOT NULL,
	request_timestamp     	TIMESTAMP (6) NOT NULL,    
	processed_timestamp   	TIMESTAMP (6) NOT NULL,    
	bus_org_guid          	RAW (16) NOT NULL,    
	entity_name           	VARCHAR2 (100) NOT NULL,    
	entity_guid_1         	RAW (16) NOT NULL,    
	entity_guid_2         	RAW (16),    
	login_person_guid     	RAW (16),    
	proxy_person_guid     	RAW (16),    
	workflow_guid         	RAW (16),    
	request_method        	VARCHAR2 (30),    
	request_uri           	VARCHAR2 (2000),    
	MESSAGE_TEXT          	CLOB
)
PARTITION BY RANGE (txn_date)    
INTERVAL ( NUMTOYMINTERVAL (1, 'MONTH') )    
(PARTITION transaction_log_rp201702 VALUES LESS THAN (TO_DATE ('02-01-2017', 'MM-DD-YYYY')))
/

ALTER TABLE transaction_log ADD CONSTRAINT transaction_log_pk PRIMARY KEY (txn_guid)
/
ALTER TABLE transaction_log ADD CONSTRAINT transaction_log_ui01 UNIQUE (session_guid,request_guid,txn_guid)
/

