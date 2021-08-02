BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE lego_timecard_extr_tracker PURGE';
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE lego_timecard_extr_tracker (
  object_name                  VARCHAR2(30),
  source_name                  VARCHAR2(6), 
  buyer_enterprise_bus_org_id  NUMBER(38),
  qtr_start_date               DATE,
  qtr_end_date                 DATE,
  max_event_date               DATE DEFAULT NULL,
  load_date                    DATE DEFAULT NULL,
  load_time_sec                NUMBER(10),
  records_loaded               NUMBER(38) DEFAULT NULL)
PARTITION BY LIST (object_name)
SUBPARTITION BY LIST (source_name)
SUBPARTITION TEMPLATE (
  SUBPARTITION SP_USPROD VALUES ('USPROD'),
  SUBPARTITION SP_WFPROD VALUES ('WFPROD'))
( PARTITION P_TC_EVENT VALUES ('LEGO_TIMECARD_EVENT'),
  PARTITION P_TC_ENTRY VALUES ('LEGO_TIMECARD_ENTRY'))
/

ALTER TABLE lego_timecard_extr_tracker
ADD CONSTRAINT lego_timecard_extr_tracker_pk
PRIMARY KEY (object_name, source_name, buyer_enterprise_bus_org_id, qtr_start_date, qtr_end_date) 
/

ALTER TABLE lego_timecard_extr_tracker
ADD CONSTRAINT lego_tc_extr_tracker_fk01
FOREIGN KEY (object_name, source_name)
REFERENCES lego_object (object_name, source_name)
/