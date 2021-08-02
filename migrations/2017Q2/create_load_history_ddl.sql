CREATE TABLE load_history
 (load_id                  NUMBER        NOT NULL,
  legacy_source            VARCHAR2(7)   NOT NULL,
  load_status              VARCHAR2(9)   NOT NULL,
  load_start_timestamp     TIMESTAMP     NOT NULL,
  load_end_timestamp       TIMESTAMP,
  error_message            VARCHAR2(512),
  merged_rows_parent_table NUMBER,
  merged_rows_child_table  NUMBER)
/

ALTER TABLE load_history
ADD CONSTRAINT load_history_pk
PRIMARY KEY (load_id)
/

ALTER TABLE load_history
ADD CONSTRAINT load_history_ck01
CHECK (load_status IN ('running','completed','failed'))
/

   
