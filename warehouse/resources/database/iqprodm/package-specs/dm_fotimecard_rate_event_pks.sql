CREATE OR REPLACE PACKAGE dm_fotimecard_rate_event
AS
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
    c_regexp_rule      VARCHAR2(64) := '[\|]|[^_,:\.\(\)\[\]@#=\*\?\-\+[:alnum:]]';
    c_crlf             VARCHAR2(2) := chr(13) || chr(10);
    c_email_sender     VARCHAR2(32) := 'mart_processing@iqnavigator.com';
    c_email_recipients VARCHAR2(256) := 'mpatton@iqnavigator.com,data_warehouse@iqnavigator.com';

    TYPE eventTab    IS TABLE OF dm_timecard_rate_events%ROWTYPE;
    TYPE proxTab     IS TABLE OF dm_proximity_index%ROWTYPE;
    TYPE weventTab   IS TABLE OF dm_weighted_rate_events%ROWTYPE;
    TYPE event_curs  IS REF CURSOR RETURN dm_timecard_rate_events%ROWTYPE;
    TYPE wevent_curs IS REF CURSOR RETURN dm_weighted_rate_events%ROWTYPE;
    TYPE cntryTab    IS TABLE OF dm_geo_dim.iso_country_name%TYPE;

    c_country_list   cntryTab;

PROCEDURE extract_rate_events
(
    p_source_code IN VARCHAR2
  , p_from_date   IN VARCHAR2 -- YYYYMMDD
  , p_to_date     IN VARCHAR2 -- YYYYMMDD
  , p_start_date  IN VARCHAR2 -- YYYYMMDD
  , p_batch_id    IN NUMBER
);

PROCEDURE extract_all_rate_events
(
  v_resume_flag IN VARCHAR2 DEFAULT 'N'
);

FUNCTION get_transformed_events
(
  p_batch_id        IN NUMBER
)
RETURN eventTab
PIPELINED;

PROCEDURE process_batch
(
    p_source_code IN VARCHAR2
  , p_cutoff_date IN VARCHAR2 DEFAULT NULL -- YYYYMMDDHH24MISS
  , p_start_date  IN VARCHAR2 DEFAULT '20080101000000' -- YYYYMMDDHH24MISS
  , p_skip_maint  IN VARCHAR2 DEFAULT 'N'
);

PROCEDURE split_timesheet_rate_events
(
    p_source_code IN VARCHAR2
  , p_batch_id    IN NUMBER
  , p_skip_maint  IN VARCHAR2 DEFAULT 'N'
);

PROCEDURE get_and_merge_jobs_info
(
    p_source_code IN VARCHAR2
  , p_link_name   IN VARCHAR2
  , p_batch_id    IN NUMBER
  , p_skip_maint  IN VARCHAR2 DEFAULT 'N'
);

PROCEDURE get_merge_missing_jobs_info;

PROCEDURE manage_title_maps2;

    PROCEDURE close_index_month
    (
        p_month_number  IN NUMBER
      , p_force_refresh IN VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE close_calendar_month
    (
        p_month_number  IN NUMBER
      , p_force_refresh IN VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE close_all_months
    (
        p_date1         IN NUMBER DEFAULT 200801
      , p_date2         IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYMM'))
      , p_force_refresh IN VARCHAR2 DEFAULT 'N'
    );

PROCEDURE move_quarantine
(
   p_source_code IN     VARCHAR2
 , p_batch_id    IN     NUMBER
 , p_max_key     IN     NUMBER
 , p_rec_count   IN OUT NUMBER
);

PROCEDURE reprocess_quarantine;

PROCEDURE reprocess_quarantine
(
   p_source_code IN     VARCHAR2
);

PROCEDURE reprocess_foreign_rate_events;

PROCEDURE add_new_buyerorgs
(
    p_source_code IN VARCHAR2
  , p_batch_id      IN NUMBER
);

PROCEDURE add_new_supplierorgs
(
    p_source_code IN VARCHAR2
  , p_batch_id      IN NUMBER
);

END dm_fotimecard_rate_event;
/