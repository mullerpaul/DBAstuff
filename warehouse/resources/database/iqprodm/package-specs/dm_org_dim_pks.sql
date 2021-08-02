CREATE OR REPLACE PACKAGE dm_org_dim
AS
    gv_process user_jobs.what%TYPE := 'DM_ORG_DIM';
    c_crlf          VARCHAR2(2) := chr(13) || chr(10);

    PROCEDURE p_main
    (
        p_source_code IN VARCHAR2
       ,p_date_id     IN NUMBER
    );

    PROCEDURE get_new_org_changes
    (
        p_msg_id      IN  NUMBER
      , p_source_code IN  VARCHAR2
    );

    PROCEDURE just_transform
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
    );

    /*
    ** Pull the already extracted data
    ** from remote FO temp/stage tables
    ** into local temp/stage tables
    ** and then tranform/apply to final
    ** DM tables
    */
    PROCEDURE pull_and_transform
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
    );

    PROCEDURE pull_transform_fo_org
    (
        p_source_code IN VARCHAR2
      , p_org_id      IN dm_organization_dim.org_id%TYPE
    );

    PROCEDURE redo_org_dim(p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));
END dm_org_dim;
/