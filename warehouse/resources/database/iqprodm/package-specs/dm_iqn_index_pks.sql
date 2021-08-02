CREATE OR REPLACE PACKAGE dm_index
AS
    k_start_month              NUMBER := 200701;
    k_start_date    DATE   := TO_DATE(TO_CHAR(k_start_month) || '01', 'YYYYMMDD');

    c_start_month              NUMBER;
    c_start_date               DATE;
    c_rolling_months           NUMBER;
    c_rolling_effective_month  NUMBER;

    k_adj_start_month          NUMBER := 201201;
    c_crlf          VARCHAR2(2) := chr(13) || chr(10);
    c_email_sender        VARCHAR2(32) := 'mart_processing@iqnavigator.com';
    c_email_recipients    VARCHAR2(256) := 'mpatton@iqnavigator.com,data_warehouse@iqnavigator.com';

    TYPE monthTab    IS TABLE OF NUMBER(6);
    TYPE indexTab    IS TABLE OF dm_iqn_index%ROWTYPE;
    TYPE index_curs IS REF CURSOR RETURN dm_iqn_index%ROWTYPE;

    /*
    ** Pipelined function to generate
    ** all the month keys (month numbers) between p_date1 and p_date2 (both including)
    ** p_date1 is expected to be smaller(earlier) than p_date2
    */
    FUNCTION get_month_keys
    (
        p_date1 IN DATE
      , p_date2 IN DATE
    )
    RETURN monthTab PIPELINED;

    /*
    ** Procedure to 
    ** Generate and Populate
    ** Detailed level (By Occupational Sector and Region)
    ** Index records for all months between p_date1 and p_date2 (both including)
    ** p_date1 is expected to be smaller(earlier) than p_date2
    */
    PROCEDURE populate_sector_region_index
    (
        p_date1       IN DATE
      , p_date2       IN DATE
      , p_country     IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_region_type IN dm_regions.std_region_type_id%TYPE
      , p_final_flag  IN VARCHAR2 DEFAULT 'Y'
    );

    /*
    ** Procedure to 
    ** Generate and Populate
    ** All Regions By Occupational Sector level
    ** Index records for all the months between p_date1 and p_date2 (both including)
    ** p_date1 is expected to be smaller(earlier) than p_date2
    */
    PROCEDURE populate_sector_index
    (
        p_date1      IN DATE
      , p_date2      IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_adj_type   IN dm_iqn_index.adjustment_type%TYPE DEFAULT 'R'
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
    );

    /*
    ** Procedure to 
    ** Generate and Populate
    ** All Occupational Sectors By Region level
    ** Index records for all the months between p_date1 and p_date2 (both including)
    ** p_date1 is expected to be smaller(earlier) than p_date2
    */
    PROCEDURE populate_region_index
    (
        p_date1      IN DATE
      , p_date2      IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_adj_type   IN dm_iqn_index.adjustment_type%TYPE DEFAULT 'R'
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
    );

    /*
    ** Procedure to 
    ** Generate and Populate
    ** National Level (All Occupational Sectors and All Regions)
    ** Index records for all the months between p_date1 and p_date2 (both including)
    ** p_date1 is expected to be smaller(earlier) than p_date2
    */
    PROCEDURE populate_national_index
    (
        p_date1      IN DATE
      , p_date2      IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_adj_type   IN dm_iqn_index.adjustment_type%TYPE DEFAULT 'R'
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
    );

    /*
    ** Master Procedure to 
    ** Generate and Populate
    ** All Level
    ** Index records for all the months between p_date1 and p_date2 (both including)
    ** p_date1 is expected to be smaller(earlier) than p_date2
    */
    PROCEDURE populate_index
    (
        p_date1      IN DATE
      , p_date2      IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
      , p_upd_wts_flag IN VARCHAR2 DEFAULT 'N' -- Update Title Weights and Index based on Frozen Weighted Rate Events
    );

    /*
    ** Master Procedure to 
    ** Generate and Replace (Delete followed by Insert)
    ** All Level
    ** Index records for all the months between p_date1 and p_date2 (both including)
    ** p_date1 is expected to be smaller(earlier) than p_date2
    */
    PROCEDURE re_populate_index
    (
        p_date1      IN DATE
      , p_date2      IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
    );

    /*
    ** Master Procedure to 
    ** Generate and Replace (Truncate followed by Insert)
    ** All Index records for All Weighted Rate Events (that exist)
    ** for All Index levels
    */
    PROCEDURE redo_whole_index;

    PROCEDURE populate_monthly_title_avgs
    (
        p_date1         IN DATE
      , p_date2         IN DATE
      , p_country       IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_region_type   IN dm_regions.std_region_type_id%TYPE
      , p_national_flag IN VARCHAR2 DEFAULT 'N'
      , p_update_flag   IN VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE get_monthly_title_avgs
    (
        p_month         IN NUMBER
      , p_country       IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_region_type   IN dm_regions.std_region_type_id%TYPE
      , p_national_flag IN VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE update_monthly_title_avgs
    (
        p_month         IN NUMBER
      , p_country       IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_region_type   IN dm_regions.std_region_type_id%TYPE
      , p_national_flag IN VARCHAR2 DEFAULT 'N'
    );

    PROCEDURE get_nat_title_rolling_avgs
    (
        p_month       IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    );

    PROCEDURE update_nat_title_rolling_avgs
    (
        p_month   IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    );

    PROCEDURE update_reg_title_rolling_avgs
    (
        p_month       IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    );

    PROCEDURE copy_nat_title_rolling_avgs
    (
        p_to_month   IN NUMBER
      , p_from_month IN NUMBER
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    );

    PROCEDURE overwrite_nat_title_rlng_avgs
    (
        p_to_month   IN NUMBER
      , p_from_month IN NUMBER
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    );

    PROCEDURE get_title_buyer_weights
    (
        p_month   IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    );

    PROCEDURE get_hist_title_buyer_weights
    (
        p_month   IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    );
END dm_index;
/