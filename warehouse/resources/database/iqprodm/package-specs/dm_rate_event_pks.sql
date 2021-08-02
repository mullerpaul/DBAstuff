CREATE OR REPLACE PACKAGE dm_rate_event
AS
    gv_process user_jobs.what%TYPE := 'DM_RATE_EVENT';
    c_us_country_id    NUMBER := 1;
    c_uk_country_id    NUMBER;
    c_nl_country_id    NUMBER;
    c_ca_country_id    NUMBER;
    c_in_country_id    NUMBER;
    c_us_dim_id        NUMBER;
    c_uk_dim_id        NUMBER;
    c_ca_dim_id        NUMBER;
    c_in_dim_id        NUMBER;
    c_nl_dim_id        NUMBER;

    v_uk_place_id         dm_places.std_place_id%TYPE                     := 0;
    v_ca_place_id         dm_places.std_place_id%TYPE                     := 0;
    v_nl_place_id         dm_places.std_place_id%TYPE                     := 0;
    v_in_place_id         dm_places.std_place_id%TYPE                     := 0;
    v_sql              VARCHAR2(32767);
    v_link_name        VARCHAR2(32);    -- Name of DB Link to FO Instance

    c_us_max_rate      NUMBER := 500;
    c_us_min_rate      NUMBER := 5;
    c_uk_max_rate      NUMBER := 300;
    c_uk_min_rate      NUMBER := 3;
    c_nl_max_rate      NUMBER := 416;
    c_nl_min_rate      NUMBER := 4.16;
    c_ca_max_rate      NUMBER := 500;
    c_ca_min_rate      NUMBER := 5;
    c_in_max_rate      NUMBER := 25000;
    c_in_min_rate      NUMBER := 250;
    c_weekly_hours     NUMBER := 40;
    c_daily_hours      NUMBER := 8;
    c_monthly_hours    NUMBER := 184;
    c_annual_hours     NUMBER := 2080;
    c_start_date       DATE   := TO_DATE('20070101', 'YYYYMMDD');
    c_crlf             VARCHAR2(2) := chr(13) || chr(10);
    c_regexp_rule      VARCHAR2(64) := '[\|]|[^_,:\.\(\)\[\]@#=\*\?\-\+[:alnum:]]';
    c_email_sender     VARCHAR2(32) := 'mart_processing@iqnavigator.com';
    c_email_recipients VARCHAR2(256):= 'mpatton@iqnavigator.com,data_warehouse@iqnavigator.com';

    TYPE eventTab    IS TABLE OF dm_rate_event_master%ROWTYPE;
    TYPE proxTab     IS TABLE OF dm_proximity_index%ROWTYPE;
    TYPE weventTab   IS TABLE OF dm_weighted_rate_events%ROWTYPE;
    TYPE event_curs  IS REF CURSOR RETURN dm_rate_event_master%ROWTYPE;
    TYPE wevent_curs IS REF CURSOR RETURN dm_weighted_rate_events%ROWTYPE;
    TYPE cntryTab    IS TABLE OF dm_geo_dim.iso_country_name%TYPE;

    c_country_list   cntryTab;
    proxWeights      proxTab;

    /*
    ** Pipelined Table Function
    ** to provide input rate event data
    ** based on type of processing
    ** p_type = 1 ==> Fresh/New Rate Events from Front Office
    ** p_type = 2 ==> Un-transformed/Partially transformed from DW
    */
    FUNCTION get_events(p_type IN NUMBER) RETURN eventTab PIPELINED;

    /*
    ** Transform rate event data
    */
    PROCEDURE transform_rate_events
    (
        p_type        IN NUMBER
      , p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
      , p_skip_maint  IN VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE p_main
    (
        p_source_code IN VARCHAR2
    );

    PROCEDURE get_new_rate_events
    (
        p_msg_id      IN  NUMBER
      , p_cutoff_date  IN  VARCHAR2
      , on_err_num     OUT NUMBER
      , ov_err_msg     OUT VARCHAR2
      , ov_ea_count    OUT NUMBER
      , ov_wo_count    OUT NUMBER
      , p_source_code IN  VARCHAR2
      , p_prev_cutoff  OUT VARCHAR2
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
        p_source_code    IN VARCHAR2
      , p_msg_id         IN NUMBER
      , p_from_timestamp IN NUMBER
      , p_to_timestamp   IN NUMBER
      , p_skip_maint     IN VARCHAR2 DEFAULT 'N'
    );

    /*
    ** Generic function to cleanup and extract state information
    ** from FO state column
    */
    FUNCTION clean_state(p_country_id NUMBER, p_state IN VARCHAR2) RETURN VARCHAR2;

    /*
    ** Generic function to cleanup and extract city information
    ** from FO city column
    */
    FUNCTION clean_city(p_city IN VARCHAR2, p_country_id NUMBER, p_state IN VARCHAR2) RETURN VARCHAR2;

    /*
    ** Wachovia Specific Function to extract zipcode
    ** from un-parsed custom address
    */
    FUNCTION wac_zip  (unparsed VARCHAR2) RETURN VARCHAR2;

    /*
    ** Wachovia Specific Function to extract state code
    ** from un-parsed custom address
    */
    FUNCTION wac_state(unparsed VARCHAR2) RETURN VARCHAR2;

    /*
    ** Wachovia Specific Function to extract city
    ** from un-parsed custom address
    */
    FUNCTION wac_city (unparsed VARCHAR2) RETURN VARCHAR2;

    /*
    ** Procedure to logically delete (delete_flag = 'Y')
    ** any prior rate events for which we have new 
    ** updates/version
    */
    PROCEDURE inv_prior_events
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
      , p_skip_maint  IN VARCHAR2 DEFAULT 'N'
    );

    /*
    ** Procedure to take all un-transformed or partially transformed
    ** and make another attempt 
    ** to transform based on latest mappings and other support data
    */
    PROCEDURE update_rate_events;

    /*
    ** Procedure to take all rate event flagged as foreign
    ** and make another attempt 
    ** to transform based on latest mappings and other support data
    */
    PROCEDURE reprocess_foreign_rate_events;

    /*
    ** Procedure to take all rate events
    ** and re-process them
    ** to transform based on latest algorithm, mappings and other support data
    */
    PROCEDURE reprocess_rate_events;

    /*
    ** Procedure to take rate events from all quarantine tables
    ** and re-process them
    ** to transform based on latest mappings and other support data
    */
    PROCEDURE reprocess_quarantine;

    FUNCTION get_transformed_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    ) 
    RETURN weventTab PIPELINED;

    FUNCTION get_monthly_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    ) 
    RETURN weventTab PIPELINED;

    FUNCTION get_weighted_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    ) 
    RETURN weventTab PIPELINED;

    PROCEDURE populate_weighted_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    );

    PROCEDURE redo_batch_weighted_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    );

    PROCEDURE redo_all_weighted_events;

    PROCEDURE add_new_buyerorgs
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
    );

    PROCEDURE add_new_supplierorgs
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
    );

    PROCEDURE split_rate_events
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
      , p_skip_maint  IN VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE inv_flagged_events;

    PROCEDURE re_extract_rate_events
    (
      p_source_code IN VARCHAR2
    );

    PROCEDURE manage_title_maps;

    PROCEDURE merge_jobs
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
      , p_skip_maint  IN VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE drop_job_indexes;

    PROCEDURE create_job_indexes;

    PROCEDURE clean_job_text_fields;

    FUNCTION get_link_name(p_source_code IN VARCHAR2) RETURN VARCHAR2;

    PROCEDURE get_rateiq_snapshot
    (
        p_month_number  IN NUMBER
      , p_force_refresh IN VARCHAR DEFAULT 'N'
    );

    PROCEDURE verify_uk
    (
        p_state                 dm_rate_event_master.custom_address_state%TYPE
      , p_full_address          dm_rate_event_master.unparsed_custom_address%TYPE
      , p_supplierorg_name      dm_rate_event_master.supplierorg_name%TYPE
      , p_job_title             dm_rate_event_master.job_title%TYPE
      , p_buyerorg_name         dm_rate_event_master.buyerorg_name%TYPE
      , p_std_country_id IN OUT dm_rate_event_master.std_country_id%TYPE
    );

    PROCEDURE verify_us
    (
        p_state                 dm_rate_event_master.custom_address_state%TYPE
      , p_full_address          dm_rate_event_master.unparsed_custom_address%TYPE
      , p_supplierorg_name      dm_rate_event_master.supplierorg_name%TYPE
      , p_job_title             dm_rate_event_master.job_title%TYPE
      , p_buyerorg_name         dm_rate_event_master.buyerorg_name%TYPE
      , p_std_country_id IN OUT dm_rate_event_master.std_country_id%TYPE
    );

    FUNCTION is_country_name
    (
        p_country IN dm_rate_event_master.unparsed_custom_address%TYPE
      , p_exclude IN dm_rate_event_master.unparsed_custom_address%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE load_proximity_waits;
    PROCEDURE load_country_list;

    FUNCTION get_job_status(in_what IN VARCHAR2) RETURN NUMBER;
END dm_rate_event;
/