CREATE TABLE processing_log (
   log_guid             RAW (16) NOT NULL,
   log_date             DATE DEFAULT SYS_EXTRACT_UTC (SYSTIMESTAMP) NOT NULL,
   trace_level          VARCHAR2 (20 CHAR) DEFAULT 'ERROR' NOT NULL,
   instance_name        VARCHAR2 (16 CHAR),
   sid                  NUMBER DEFAULT 0 NOT NULL,
   serial#              NUMBER DEFAULT 0 NOT NULL,
   username             VARCHAR2 (30 CHAR) DEFAULT 'ORACLE' NOT NULL,
   osuser               VARCHAR2 (30 CHAR) DEFAULT 'ORACLE' NOT NULL,
   source               VARCHAR2 (61 CHAR) NOT NULL,
   code_location        VARCHAR2 (200 CHAR),
   start_time           TIMESTAMP DEFAULT SYS_EXTRACT_UTC (SYSTIMESTAMP) NOT NULL,
   end_time             TIMESTAMP,
   parent_log_guid      RAW (16),
   transaction_result   VARCHAR2 (30 CHAR),
   ERROR_CODE           NUMBER,
   MESSAGE              VARCHAR2 (4000 CHAR) NOT NULL,
   message_clob         CLOB)
PARTITION BY RANGE (log_date)
   INTERVAL ( NUMTOYMINTERVAL (1, 'MONTH') )
   (PARTITION processing_log_rp201505 VALUES LESS THAN (TO_DATE ('06-01-2015', 'MM-DD-YYYY')))
/

COMMENT ON TABLE processing_log IS 'Contains log messages in a log4j similar format.'
/
COMMENT ON COLUMN processing_log.log_guid IS 'Unique identifier for the processing_log.'
/
COMMENT ON COLUMN processing_log.log_date IS 'Partition key for the processing_log.'
/
COMMENT ON COLUMN processing_log.trace_level IS
   'The message will have one of several different trace_levels outlining the classification of the row.'
/
COMMENT ON COLUMN processing_log.instance_name IS 'In a RAC enabled DB, this will contain the instance the process is running on.'
/
COMMENT ON COLUMN processing_log.sid IS 'The system ID of the process.'
/
COMMENT ON COLUMN processing_log.serial# IS 'The serial number of the process.'
/
COMMENT ON COLUMN processing_log.username IS 'The username of the process.'
/
COMMENT ON COLUMN processing_log.osuser IS 'The OS User of the process.'
/
COMMENT ON COLUMN processing_log.source IS
   'The name of the module that generated the log message in package ||.|| procedure format.'
/
COMMENT ON COLUMN processing_log.start_time IS 'The time the message was created.'
/
COMMENT ON COLUMN processing_log.end_time IS 'The time the message was updated.'
/
COMMENT ON COLUMN processing_log.parent_log_guid IS 'This column helps maintain a calling heirachy of the procedure call.'
/
COMMENT ON COLUMN processing_log.transaction_result IS
   'If an error occurs, this will contain the result of the session''s transaction.'
/
COMMENT ON COLUMN processing_log.ERROR_CODE IS 'If an error occurs, this will contain the Oracle Error Code.'
/
COMMENT ON COLUMN processing_log.code_location IS 'The location inside the source, that generated the message.'
/
COMMENT ON COLUMN processing_log.MESSAGE IS 'The first 4000 characters of the log messagee.'
/
COMMENT ON COLUMN processing_log.message_clob IS 'The entire log message.'
/



CREATE INDEX processing_log_ni01
   ON processing_log (log_date)
   LOCAL
/

CREATE INDEX processing_log_ni02
   ON processing_log (parent_log_guid, log_date)
   LOCAL
/

CREATE INDEX processing_log_ni03
   ON processing_log (start_time, log_date)
   LOCAL
/

ALTER TABLE processing_log ADD
  CONSTRAINT processing_log_pk PRIMARY KEY (log_guid)
/

ALTER TABLE processing_log ADD (
  CONSTRAINT processing_log_fk FOREIGN KEY (parent_log_guid)
  REFERENCES processing_log (log_guid) ON DELETE CASCADE ENABLE NOVALIDATE)
/

