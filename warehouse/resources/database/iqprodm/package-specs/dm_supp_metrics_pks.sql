CREATE OR REPLACE PACKAGE dm_supp_metrics
/********************************************************************
 * Name: dm_supp_metrics
 * Desc: This package contains all the procedures required to
 *       migrate/process Supplier Metrics data to be used in
 *       Data mart
 *
 * Author   Date        Version   History
 * -----------------------------------------------------------------
 * pkattula 12/12/09    Initial
 ********************************************************************/
AS
    gv_process user_jobs.what%TYPE := 'DM_SUPP_METRICS';
    c_crlf     VARCHAR2(2) := chr(13) || chr(10);

    TYPE ReasonsTab     IS TABLE OF VARCHAR2(128) INDEX BY BINARY_INTEGER;
    vNegativeReasons    ReasonsTab;
    TYPE supSmryTab     IS TABLE OF dm_supplier_summary%ROWTYPE;
    TYPE supSmryCur     IS REF CURSOR RETURN dm_supplier_summary%ROWTYPE;
    TYPE supStdSmryTab  IS TABLE OF dm_supplier_std_summary%ROWTYPE;
    TYPE supStdSmryCur  IS REF CURSOR RETURN dm_supplier_std_summary%ROWTYPE;

    PROCEDURE p_main
    (
        in_source_code IN VARCHAR2
      , p_month        IN  VARCHAR2 -- Month (as YYYYMM)
    );
  
    PROCEDURE get_supplier_metrics
    (
        in_msg_id      IN  NUMBER
      , on_err_num     OUT NUMBER
      , ov_err_msg     OUT VARCHAR2
      , ov_ea_count    OUT NUMBER
      , ov_wo_count    OUT NUMBER
      , in_source_code IN  VARCHAR2
      , p_month        IN  VARCHAR2 -- Month (as YYYYMM)
    );

    PROCEDURE pull_and_transform
    (
        p_source_code  IN VARCHAR2
      , p_month        IN VARCHAR2 -- Month (as YYYYMM)
    );

    PROCEDURE pull_and_transform
    (
        in_source_code IN VARCHAR2
      , in_msg_id      IN NUMBER
      , p_month        IN  VARCHAR2 -- Month (as YYYYMM)
    );

    PROCEDURE manage_title_maps;

    PROCEDURE merge_jobs
    (
        in_source_code IN VARCHAR2
      , in_msg_id      IN NUMBER
    );

    PROCEDURE transform_supplier_metrics
    (
        in_source_code IN VARCHAR2
      , in_msg_id      IN NUMBER
      , p_month        IN VARCHAR2 -- Month (as YYYYMM)
    );

    PROCEDURE gen_monthly_event_summary
    (
        p_source_code  IN VARCHAR2
      , p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    );

    PROCEDURE gen_fo_monthly_event_summary
    (
        p_source_code  IN VARCHAR2
      , p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    );

    PROCEDURE gen_std_monthly_event_summary
    (
        p_source_code  IN VARCHAR2
      , p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    );

    PROCEDURE gen_std_monthly_summary_forall
    (
        p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    );

    FUNCTION is_negative_reason(p_reason_ended VARCHAR)
    RETURN NUMBER;

    FUNCTION gen_supplier_ratios
    (
        p_source_code  IN VARCHAR2
      , p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    )
    RETURN supSmryTab PIPELINED;

    FUNCTION gen_supplier_std_ratios
    (
        p_source_code  IN VARCHAR2
      , p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    )
    RETURN supStdSmryTab PIPELINED;

    FUNCTION gen_supplier_std_ratios_forall
    (
        p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    )
    RETURN supStdSmryTab PIPELINED;

    PROCEDURE copy_metrics
    (
        p_source_code IN VARCHAR2
      , p_period_from IN VARCHAR2 -- as YYYYNN
      , p_period_to   IN VARCHAR2 -- as YYYYNN
    );

    FUNCTION in_the_period
    (
        p_month        IN VARCHAR2 -- Month (as YYYYMM)
      , p_month_from   IN VARCHAR2 -- Month (as YYYYMM)
      , p_month_to     IN VARCHAR2 -- Month (as YYYYMM)
    )
    RETURN NUMBER;

    PROCEDURE drop_job_indexes;

    PROCEDURE create_job_indexes;

END dm_supp_metrics;
/