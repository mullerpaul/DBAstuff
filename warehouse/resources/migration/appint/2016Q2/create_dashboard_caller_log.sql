CREATE TABLE dashboard_api_calls
 (call_time_utc   TIMESTAMP    DEFAULT SYS_EXTRACT_UTC (SYSTIMESTAMP)  NOT NULL,  --all timestamps are in UTC
  api_name        VARCHAR2(30)                                         NOT NULL,
  login_user_id   NUMBER,
  login_org       NUMBER,
  security_type   VARCHAR2(3),
  parameter_value VARCHAR2(30))
PCTFREE 0                             -- insert only table, don't save room for updates
PARTITION BY RANGE (call_time_utc)
INTERVAL(NUMTODSINTERVAL(7, 'DAY'))   -- partitions hold 7 days of data
  (PARTITION VALUES LESS THAN (to_timestamp('2016-May-10','YYYY-Mon-DD')))  -- partition "transition point"
/

GRANT SELECT ON dashboard_api_calls TO PUBLIC
/
