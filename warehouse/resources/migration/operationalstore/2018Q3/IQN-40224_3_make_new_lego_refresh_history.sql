CREATE TABLE lego_refresh_history (
    object_name            VARCHAR2(30 BYTE) NOT NULL , 
    job_runtime            TIMESTAMP         NOT NULL , 
    source_name            VARCHAR2(6 BYTE)  NOT NULL , 
    status                 VARCHAR2(22 BYTE) NOT NULL , 
    dbms_scheduler_log_id  NUMBER,
    queue_start_time       TIMESTAMP,
    refresh_start_time     TIMESTAMP,
    refresh_end_time       TIMESTAMP,
    toggle_refreshed_table VARCHAR2(30 BYTE),
    error_message          VARCHAR2(512 BYTE),
    CONSTRAINT lego_refresh_history_pk
        PRIMARY KEY (object_name, job_runtime, source_name),
    CONSTRAINT lego_refresh_history_fk01
        FOREIGN KEY (job_runtime) 
        REFERENCES lego_refresh_run_history (job_runtime),
    CONSTRAINT lego_refresh_history_ck01 
        CHECK (status IN ('scheduled', 'started refresh',
                          'refresh complete', 'released',
                          'error', 'error in prerequisite',
                          'timeout', 'stopped', 'avoided'
                         )
              )
)
/

COMMENT ON TABLE lego_refresh_history
IS 'Per lego refresh information'
/

COMMENT ON COLUMN lego_refresh_history.OBJECT_NAME 
IS 'Partial PK of the table - The name of the LEGO'
/
COMMENT ON COLUMN lego_refresh_history.JOB_RUNTIME 
IS 'Partial PK of the table - The time the refresh run was started'
/
COMMENT ON COLUMN lego_refresh_history.SOURCE_NAME 
IS 'Partial PK of the table - The location where the data was pulled from.  As of 2018, the only environment with more than 1 source is US-production.'
/
COMMENT ON COLUMN lego_refresh_history.STATUS 
IS 'Result of refresh run'
/
COMMENT ON COLUMN lego_refresh_history.DBMS_SCHEDULER_LOG_ID 
IS 'Used to join to USER_SCHEDULER_% dictionary tables'
/
COMMENT ON COLUMN lego_refresh_history.QUEUE_START_TIME 
IS 'Time the scheduler job was created and started waiting to start its processing'
/
COMMENT ON COLUMN lego_refresh_history.REFRESH_START_TIME 
IS 'Time the lego stopped waiting to run and started processing'
/
COMMENT ON COLUMN lego_refresh_history.REFRESH_END_TIME 
IS 'Time the lego completed the refresh process'
/
COMMENT ON COLUMN lego_refresh_history.TOGGLE_REFRESHED_TABLE 
IS 'For toggle legos - the name of the refreshed base table'
/
COMMENT ON COLUMN lego_refresh_history.ERROR_MESSAGE 
IS 'Any error message encountered.'
/
