----
CREATE TABLE lego_refresh_group
  (refresh_group          NUMBER(2,0)  NOT NULL,
   run_in_first_pass      VARCHAR2(1)  NOT NULL,
   run_in_initial_load    VARCHAR2(1)  NOT NULL,
   allow_partial_release  VARCHAR2(1)  NOT NULL,
   comments               VARCHAR2(1000))
/

ALTER TABLE lego_refresh_group
ADD CONSTRAINT lego_refresh_group_pk
PRIMARY KEY (refresh_group)
/

ALTER TABLE lego_refresh_group
ADD CONSTRAINT lego_refresh_group_ck01
CHECK (run_in_first_pass IN ('Y','N'))
/

ALTER TABLE lego_refresh_group
ADD CONSTRAINT lego_refresh_group_ck02
CHECK (run_in_initial_load IN ('Y','N'))
/

ALTER TABLE lego_refresh_group
ADD CONSTRAINT lego_refresh_group_ck03
CHECK (allow_partial_release IN ('Y','N'))
/

ALTER TABLE lego_refresh_group
ADD CONSTRAINT lego_refresh_group_ck04
CHECK (NOT (run_in_first_pass = 'Y' AND run_in_initial_load = 'Y'))
/

----
CREATE TABLE lego_source
  (source_name       VARCHAR2(6)  NOT NULL,
   db_link_name      VARCHAR2(30) NOT NULL,
   source_name_short VARCHAR2(4), 
   comments          VARCHAR2(1000))
/

ALTER TABLE lego_source
ADD CONSTRAINT lego_source_pk
PRIMARY KEY (source_name)
/

----
CREATE TABLE lego_refresh
  (object_name              VARCHAR2(30)  NOT NULL,
   source_name              VARCHAR2(6)   NOT NULL,
   refresh_method           VARCHAR2(24)  NOT NULL,
   refresh_schedule         VARCHAR2(30)  NOT NULL,
   refresh_group            NUMBER(2,0)   NOT NULL,
   refresh_dependency_order NUMBER(2,0)   NOT NULL,
   refresh_on_or_after_time DATE,
   started_refresh          VARCHAR2(1)   DEFAULT 'N' NOT NULL,
   waiting_for_release      VARCHAR2(1)   DEFAULT 'N' NOT NULL,
   release_sql              VARCHAR2(4000),
   storage_clause           VARCHAR2(4000),
   refresh_sql              CLOB,
   refresh_object_name_1    VARCHAR2(30),
   refresh_object_name_2    VARCHAR2(30),
   synonym_name             VARCHAR2(30),
   partition_column_name    VARCHAR2(30),
   partition_clause         VARCHAR2(4000),
   subpartition_column_name VARCHAR2(30),
   subpartition_clause      VARCHAR2(4000),
   num_partitions_to_swap   NUMBER,
   refresh_procedure_name   VARCHAR2(120))
/

ALTER TABLE lego_refresh
ADD CONSTRAINT lego_refresh_pk 
PRIMARY KEY (object_name, source_name)
/

ALTER TABLE lego_refresh
ADD CONSTRAINT lego_refresh_fk01 
FOREIGN KEY (refresh_group) REFERENCES lego_refresh_group (refresh_group)
/

ALTER TABLE lego_refresh
ADD CONSTRAINT lego_refresh_fk02
FOREIGN KEY (source_name) REFERENCES lego_source (source_name)
/

ALTER TABLE lego_refresh
ADD CONSTRAINT lego_refresh_ck01
CHECK (refresh_dependency_order > 0)
/

ALTER TABLE lego_refresh
ADD CONSTRAINT lego_refresh_ck02 
CHECK (started_refresh IN ('Y','N'))
/

ALTER TABLE lego_refresh
ADD CONSTRAINT lego_refresh_ck03 
CHECK (waiting_for_release IN ('Y','N'))
/

ALTER TABLE lego_refresh
ADD CONSTRAINT lego_refresh_ck04 
CHECK (refresh_method IN ('SQL TOGGLE','PROC TOGGLE','PROC TOGGLE ARGS','PROCEDURE ONLY',
                          'PROCEDURE ONLY RELEASE','PARTITION SWAP'))
/

ALTER TABLE lego_refresh
ADD CONSTRAINT lego_refresh_ck05 
CHECK (refresh_schedule IN ('EVERY FOUR HOURS','TWICE DAILY','DAILY','WEEKLY','INITIAL'))
/

CREATE TABLE lego_refresh_history
  (object_name              VARCHAR2(30) NOT NULL,
   job_runtime              TIMESTAMP(2) NOT NULL,
   source_name              VARCHAR2(6)  NOT NULL,
   status                   VARCHAR2(16) NOT NULL,
   refresh_method           VARCHAR2(20) NOT NULL,
   refresh_group            NUMBER       NOT NULL,
   refresh_dependency_order NUMBER       NOT NULL,
   dbms_scheduler_log_id    NUMBER,
   refresh_scn              NUMBER,
   queue_start_time         TIMESTAMP(2),
   refresh_start_time       TIMESTAMP(2),
   refresh_end_time         TIMESTAMP(2),
   release_time             TIMESTAMP(2),
   toggle_refreshed_table   VARCHAR2(30),
   error_message            VARCHAR2(512))
/

ALTER TABLE lego_refresh_history
ADD CONSTRAINT lego_refresh_history_pk
PRIMARY KEY (object_name, job_runtime, source_name)
/

ALTER TABLE lego_refresh_history
ADD CONSTRAINT lego_refresh_history_ck01
CHECK (status IN ('scheduled', 'started refresh', 'refresh complete',
                  'released', 'error', 'error in parent', 'timeout', 'stopped'))
/

CREATE TABLE lego_refresh_index
  (object_name     VARCHAR2(30)                       NOT NULL,
   source_name     VARCHAR2(6)                        NOT NULL,
   index_name      VARCHAR2(30)                       NOT NULL,
   index_type      VARCHAR2(20)   DEFAULT 'NONUNIQUE' NOT NULL,
   column_list     VARCHAR2(2000)                     NOT NULL,
   tablespace_name VARCHAR2(30))
/

ALTER TABLE lego_refresh_index
ADD CONSTRAINT lego_refresh_index_ind_name_uk
UNIQUE (index_name)
/

ALTER TABLE lego_refresh_index
ADD CONSTRAINT lego_refresh_index_fk01
FOREIGN KEY (object_name, source_name) REFERENCES lego_refresh (object_name, source_name)
/

----
CREATE TYPE lego_group_list_type IS TABLE OF NUMBER
/

----
COMMENT ON COLUMN lego_refresh_group.refresh_group 
IS 'PK of the table - The group ID'
/
COMMENT ON COLUMN lego_refresh_group.run_in_first_pass 
IS 'Is this group a reference LEGO which other legos depend on?'
/
COMMENT ON COLUMN lego_refresh_group.run_in_initial_load 
IS 'Is this group meant to be run in the initial deploy phase only?'
/
COMMENT ON COLUMN lego_refresh_group.allow_partial_release 
IS 'Should we release successfully refreshed LEGOs in this group if other LEGOs in this group failed?'
/
COMMENT ON COLUMN lego_refresh_group.comments 
IS 'Optional field - A description of the legos which belong to this refresh group'
/

COMMENT ON COLUMN lego_source.source_name
IS 'Name of the remote source of FO tables'
/
COMMENT ON COLUMN lego_source.db_link_name
IS 'Name of the database link object in the local database'
/
COMMENT ON COLUMN lego_source.source_name_short
IS 'A short identifier for the remote source used in the scheduler job name'
/
COMMENT ON COLUMN lego_source.comments
IS 'A longer field to store readable information about the remote FO source'
/

COMMENT ON COLUMN lego_refresh.object_name 
IS 'PK of the table - The name of the LEGO'
/
COMMENT ON COLUMN lego_refresh.refresh_method 
IS 'Toggle, partition swap, or procedural'
/
COMMENT ON COLUMN lego_refresh.refresh_schedule 
IS 'How often to refresh this lego'
/
COMMENT ON COLUMN lego_refresh.refresh_group 
IS 'The group ID'
/
COMMENT ON COLUMN lego_refresh.refresh_dependency_order 
IS 'Order in which LEGOs run within a group'
/
COMMENT ON COLUMN lego_refresh.refresh_on_or_after_time 
IS 'This lego''s next refresh will take place at or after this time (but not earlier).  NULL means no refreshes.'
/
COMMENT ON COLUMN lego_refresh.started_refresh 
IS 'Flag used to signal if refresh job has started.'
/
COMMENT ON COLUMN lego_refresh.waiting_for_release 
IS 'Flag used to signal if refresh job has completed.'
/
COMMENT ON COLUMN lego_refresh.release_sql 
IS 'DDL to release refreshed object to JASPER.'
/
COMMENT ON COLUMN lego_refresh.storage_clause 
IS 'Storage clause used when building lego.  May contain Exadata syntax, IOT syntax, or any other valid storage clause'
/
COMMENT ON COLUMN lego_refresh.refresh_sql 
IS 'Lovingly hand-crafted SQL to pull data from FO schema'
/
COMMENT ON COLUMN lego_refresh.refresh_object_name_1 
IS 'For toggle legos - the name of table 1'
/
COMMENT ON COLUMN lego_refresh.refresh_object_name_2 
IS 'For toggle legos - the name of table 2'
/
COMMENT ON COLUMN lego_refresh.synonym_name 
IS 'For toggle legos - the name of the synonym'
/
COMMENT ON COLUMN lego_refresh.partition_column_name 
IS 'For partition swap legos - the partition key'
/
COMMENT ON COLUMN lego_refresh.partition_clause 
IS 'For partition swap legos - the partition clause'
/
COMMENT ON COLUMN lego_refresh.subpartition_column_name 
IS 'For partition swap legos - the subpartition key - unused'
/
COMMENT ON COLUMN lego_refresh.subpartition_clause 
IS 'For partition swap legos - the subpartition clause - unused'
/
COMMENT ON COLUMN lego_refresh.num_partitions_to_swap 
IS 'For partition swap legos - the number of partitions to rebuild each refresh'
/
COMMENT ON COLUMN lego_refresh.refresh_procedure_name 
IS 'For procedure only legos - the name of the procedure to use'
/

COMMENT ON COLUMN lego_refresh_index.object_name 
IS 'The name of the LEGO'
/
COMMENT ON COLUMN lego_refresh_index.index_name 
IS 'Name of the index to create.'
/
COMMENT ON COLUMN lego_refresh_index.index_type 
IS 'Unique or non-unique index'
/
COMMENT ON COLUMN lego_refresh_index.column_list 
IS 'columns to index - comma separated.'
/
COMMENT ON COLUMN lego_refresh_index.tablespace_name 
IS 'index tablespace'
/

COMMENT ON COLUMN lego_refresh_history.object_name 
IS 'Partial PK of the table - The name of the LEGO'
/
COMMENT ON COLUMN lego_refresh_history.job_runtime 
IS 'Partial PK of the table - The time passed to the REFRESH procedure'
/
COMMENT ON COLUMN lego_refresh_history.status 
IS 'Result of refresh run'
/
COMMENT ON COLUMN lego_refresh_history.refresh_method 
IS 'Toggle, partition swap, or procedural'
/
COMMENT ON COLUMN lego_refresh_history.refresh_group 
IS 'The group ID'
/
COMMENT ON COLUMN lego_refresh_history.refresh_dependency_order 
IS 'Order in which LEGOs run within a group'
/
COMMENT ON COLUMN lego_refresh_history.dbms_scheduler_log_id 
IS 'Used to join to USER_SCHEDULER_% dictionary tables'
/
COMMENT ON COLUMN lego_refresh_history.refresh_scn 
IS 'The SCN used for the refresh.'
/
COMMENT ON COLUMN lego_refresh_history.queue_start_time 
IS 'Time the lego started waiting for refresh'
/
COMMENT ON COLUMN lego_refresh_history.refresh_start_time 
IS 'Time the lego stopped waiting to run and started refreshing'
/
COMMENT ON COLUMN lego_refresh_history.refresh_end_time 
IS 'Time the lego completed the refresh process'
/
COMMENT ON COLUMN lego_refresh_history.release_time 
IS 'Time the lego was released to Jasper'
/
COMMENT ON COLUMN lego_refresh_history.toggle_refreshed_table 
IS 'For toggle legos - the name of the refreshed base table'
/
COMMENT ON COLUMN lego_refresh_history.error_message 
IS 'Any error message encountered.'
/


