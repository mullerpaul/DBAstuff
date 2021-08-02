CREATE TABLE lego_refresh_run_history (
    job_runtime                    TIMESTAMP    NOT NULL,
    remote_db_as_of_time           TIMESTAMP    NOT NULL,
    remote_db_as_of_scn            NUMBER       NOT NULL,
    caller_name                    VARCHAR2(30) NOT NULL,
    allowable_per_lego_latency_min NUMBER       NOT NULL,
    CONSTRAINT lego_refresh_run_history_pk
        PRIMARY KEY (job_runtime),
    CONSTRAINT lego_refresh_run_history_ck01
        CHECK (allowable_per_lego_latency_min BETWEEN 0 AND 1440) -- must be non-negative and less than a whole day.
)
/

COMMENT ON TABLE lego_refresh_run_history
IS 'Parent table to lego_refresh_history.  Per refresh run information'
/

COMMENT ON COLUMN lego_refresh_run_history.job_runtime
IS 'PK of this table and FK of lego_refresh_history.  The (local db) time a refresh run was started'
/
COMMENT ON COLUMN lego_refresh_run_history.remote_db_as_of_time
IS 'The time the legos were refreshed as-of - time in the remote source'
/
COMMENT ON COLUMN lego_refresh_run_history.remote_db_as_of_scn
IS 'The SCN the legos were be refreshed as-of - SCN in the remote source'
/
COMMENT ON COLUMN lego_refresh_run_history.caller_name
IS 'Entrypoint which started this refresh run'
/
COMMENT ON COLUMN lego_refresh_run_history.allowable_per_lego_latency_min
IS 'How many minutes of latency were allowable for this call'
/

