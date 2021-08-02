CREATE OR REPLACE PACKAGE dm_assignment_dim_process
AS
    gv_process user_jobs.what%TYPE := 'DM_ASSIGNMENT_DIM_PROCESS';
    c_crlf          VARCHAR2(2) := chr(13) || chr(10);

    PROCEDURE p_main
    (
        p_source_code IN VARCHAR2
      , p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
    );

    PROCEDURE get_new_assignment_changes
    (
        p_msg_id        IN  NUMBER
      , p_source_code   IN  VARCHAR2
      , p_cutoff_date   IN  VARCHAR2
      , p_out_rec_count OUT NUMBER  -- Records Extracted
    );

    PROCEDURE pull_and_transform
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
    );

    PROCEDURE redo_assignments(p_date_id IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));
END dm_assignment_dim_process;
/