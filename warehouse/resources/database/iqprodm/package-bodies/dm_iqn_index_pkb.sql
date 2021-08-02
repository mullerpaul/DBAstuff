CREATE OR REPLACE PACKAGE BODY dm_index
/********************************************************************
 * Name: dm_iqn_index
 * Desc: This package contains all the procedures required to
 *       Generate/maintanin different levels of IQN Index  records
 *
 * Author   Date        Version   History
 * -----------------------------------------------------------------
 * pkattula 09/01/13    Add more rules to filter out weak titles
 *                      from Job title weights and IQNDex calculations
 * pkattula 06/13/12    Added code for UK sector level raw value adjustments
 *                      And also code for Netherlands
 * pkattula 04/16/12    Incorporate adjustments to IQNDex starting 201201
 * pkattula 04/13/12    Procs to re-build IQNDex from Frozendata added
 * pkattula 12/06/11    International IQNDex, starting with US and UK
 * pkattula 09/14/09    Initial
 ********************************************************************/
AS
    FUNCTION get_month_keys
    (
        p_date1 IN DATE
      , p_date2 IN DATE
    )
    RETURN monthTab PIPELINED
    AS
       v_year1       NUMBER(6);
       v_year2       NUMBER(6);
       v_month1      NUMBER(6);
       v_month2      NUMBER(6);
       v_month_from  NUMBER(6);
       v_month_to    NUMBER(6);
       v_month       NUMBER(6);
    BEGIN
           v_year1  := TO_NUMBER(TO_CHAR(p_date1, 'YYYY'));
           v_year2  := TO_NUMBER(TO_CHAR(p_date2, 'YYYY'));
           IF (v_year1 > v_year2)
              THEN
                    v_year1  := v_year2;
                    v_year2  := TO_NUMBER(TO_CHAR(p_date1, 'YYYY'));
                    v_month1 := TO_NUMBER(TO_CHAR(p_date2, 'MM'));
                    v_month2 := TO_NUMBER(TO_CHAR(p_date1, 'MM'));
              ELSE
                    v_month1 := TO_NUMBER(TO_CHAR(p_date1, 'MM'));
                    v_month2 := TO_NUMBER(TO_CHAR(p_date2, 'MM'));
           END IF;

           FOR i IN v_year1 .. v_year2
           LOOP
                IF (i = v_year1)
                   THEN
                         v_month_from := v_month1;
                   ELSE
                         v_month_from := 1;
                END IF;
                IF (i = v_year2)
                   THEN
                         v_month_to := v_month2;
                   ELSE
                         v_month_to := 12;
                END IF;
                FOR j IN v_month_from .. v_month_to
                LOOP
                      v_month := (i * 100) + j;
                      PIPE ROW(v_month);
                END LOOP;
           END LOOP;
    END get_month_keys;

    PROCEDURE set_country_parms
    (
      p_country     IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    )
    IS
    BEGIN
       CASE (p_country)
            WHEN 147 THEN /* UK Specific Parameters */
                          c_start_month              := 201001;
                          c_start_date               := TO_DATE(TO_CHAR(c_start_month) || '01', 'YYYYMMDD');
                          c_rolling_months           := 20;
                          c_rolling_effective_month  := TO_NUMBER(TO_CHAR(ADD_MONTHS(c_start_date, c_rolling_months-1), 'YYYYMM'));
            WHEN  97 THEN /* Netherlands Specific Parameters */
                          c_start_month              := 200801;
                          c_start_date               := TO_DATE(TO_CHAR(c_start_month) || '01', 'YYYYMMDD');
                          c_rolling_months           := 36;
                          c_rolling_effective_month  := TO_NUMBER(TO_CHAR(ADD_MONTHS(c_start_date, c_rolling_months-1), 'YYYYMM'));
            ELSE          /* Parameter valus US and any other countries */
                          c_start_month              := 200801;
                          c_start_date               := TO_DATE(TO_CHAR(c_start_month) || '01', 'YYYYMMDD');
                          c_rolling_months           := 36;
                          c_rolling_effective_month  := TO_NUMBER(TO_CHAR(ADD_MONTHS(c_start_date, c_rolling_months-1), 'YYYYMM'));
       END CASE;
    END set_country_parms;

    PROCEDURE populate_sector_region_index
    (
        p_date1       IN DATE
      , p_date2       IN DATE
      , p_country     IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_region_type IN dm_regions.std_region_type_id%TYPE
      , p_final_flag  IN VARCHAR2 DEFAULT 'Y'
    )
    IS
           base_value_count PLS_INTEGER;
           v_rec_count      NUMBER;
           email_subject       VARCHAR2(64)  := 'DM - Missing IQN Index values type=D copied from previous month';
    BEGIN
           /*
           ** See if base index values 
           ** (for starting month 200801)
           ** exist for region, sector level (index_type = 'D')
           */
           SELECT COUNT(*)
             INTO base_value_count
             FROM dm_regions r, dm_iqn_index i
            WHERE r.std_country_id = p_country
              AND r.std_region_type_id = p_region_type
              AND r.is_partof_index = 'Y'
              AND i.std_region_id = r.std_region_id
              AND i.index_type = 'D'
              AND i.adjustment_type = 'R'
              AND i.month_number = c_start_month;

           --DBMS_OUTPUT.PUT_LINE('Found ' || base_value_count || ' base index values');

           IF (base_value_count = 0)
              THEN
                   --DBMS_OUTPUT.PUT_LINE('c_start_date = ' || c_start_date);
                   --DBMS_OUTPUT.PUT_LINE('p_region_type = ' || p_region_type);
                   --DBMS_OUTPUT.PUT_LINE('p_country = ' || p_country);
                   INSERT INTO dm_iqn_index t
                          (
                              index_type
                            , adjustment_type
                            , month_number
                            , std_country_id
                            , std_region_id
                            , std_sector_id
                            , std_region_desc
                            , std_sector_desc
                            , region_weight
                            , sector_weight
                            , raw_index_value
                            , orig_raw_index_value
                            , normalized_index_value
                            , patch_type
                            , patch_source
                            , index_status
                            , last_update_date
                          )
                     WITH base_combinations AS
                          (
                            SELECT /*+ MATERIALIZE */ t.column_value AS month_number
                                   , r.std_country_id
                                   , r.std_region_id
                                   , s.std_sector_id
                              FROM   TABLE(get_month_keys(c_start_date, c_start_date)) t
                                   , dm_regions r
                                   , dm_occupational_sectors s
                                   , dm_country_sector_weights w
                             WHERE r.std_country_id = p_country
                               AND r.is_partof_index = 'Y'
                               AND r.std_region_type_id = p_region_type
                               AND s.is_partof_index = 'Y'
                               AND w.std_country_id = r.std_country_id
                               AND w.std_sector_id = s.std_sector_id
                               AND w.sector_weight > 0
                          )
                   SELECT   'D' AS index_type
                          , 'R' AS adjustment_type
                          , b.month_number
                          , b.std_country_id
                          , b.std_region_id
                          , b.std_sector_id
                          , z.std_region_desc
                          , y.std_sector_desc
                          , MIN(z.region_weight)
                          , MIN(csw.sector_weight)
                          , SUM(w.avg_bill_rate*w.rolling_avg_weight) raw_index_value
                          , SUM(w.avg_bill_rate*w.rolling_avg_weight) orig_raw_index_value
                          , 100 AS normalized_index_value
                          , 'N' AS patch_type
                          , NULL AS patch_source
                          , DECODE(p_final_flag, 'Y', 'Final', 'Preliminary') AS index_status
                          , SYSDATE AS last_update_date
                     FROM   base_combinations b, dm_sector_region_title_weights w
                          , dm_occupational_sectors y, dm_country_sector_weights csw, dm_regions z
                    WHERE w.month_number  (+) = b.month_number
                      AND w.std_region_id (+) = b.std_region_id
                      AND w.std_sector_id (+) = b.std_sector_id
                      AND w.std_country_id (+) = b.std_country_id
                      AND w.std_region_id (+) > 0
                      AND y.std_sector_id = b.std_sector_id
                      AND csw.std_country_id = b.std_country_id
                      AND csw.std_sector_id = y.std_sector_id
                      AND csw.sector_weight > 0
                      AND z.std_region_id = b.std_region_id
                    GROUP by b.month_number, b.std_country_id, b.std_sector_id, b.std_region_id, z.std_region_desc, y.std_sector_desc;

                    --DBMS_OUTPUT.PUT_LINE('Inserted ' || SQL%ROWCOUNT || ' type D Base index records');

                    IF (p_country = 1) 
                       THEN
                            /*
                            ** If country IS US then
                            ** Patch Healthcare Index values
                            ** with information from dm_bls_healthcare_rates 
                            */
                            MERGE INTO dm_iqn_index t
                            USING (
                                    SELECT i.std_country_id, o.hourly_rate, o.bls_month_number, i.month_number, i.std_region_id, i.std_sector_id
                                      FROM dm_iqn_index i, dm_bls_healthcare_rates o
                                     WHERE i.index_type = 'D'
                                       AND i.adjustment_type = 'R'
                                       AND i.std_country_id = p_country
                                       AND i.month_number = c_start_month
                                       AND i.std_sector_desc = 'Healthcare'
                                       AND o.override_month_number = i.month_number
                                  ) s
                               ON (
                                        t.std_country_id = s.std_country_id
                                    AND t.std_region_id = s.std_region_id
                                    AND t.std_sector_id = s.std_sector_id
                                    AND t.month_number  = s.month_number
                                    AND t.index_type = 'D'
                                    AND t.adjustment_type = 'R'
                                  )
                             WHEN MATCHED THEN UPDATE SET   t.patch_type             = 'O'
                                                          , t.patch_source           = 'DM_BLS_HEALTHCARE_RATES.BLS_MONTH_NUMBER = ' || TO_CHAR(s.bls_month_number)
                                                          , t.raw_index_value        = s.hourly_rate
                                                          , t.normalized_index_value = 100
                                                          , t.index_status           = DECODE(p_final_flag, 'Y', 'Final', 'Preliminary')
                                                          , t.last_update_date       = SYSDATE;
                    END IF;
           END IF;

           --DBMS_OUTPUT.PUT_LINE('p_date1 = ' || p_date1);
           --DBMS_OUTPUT.PUT_LINE('p_date2 = ' || p_date2);
           --DBMS_OUTPUT.PUT_LINE('c_start_date = ' || c_start_date);
           --DBMS_OUTPUT.PUT_LINE('p_region_type = ' || p_region_type);
           --DBMS_OUTPUT.PUT_LINE('p_country = ' || p_country);
           INSERT INTO dm_iqn_index t
                  (
                      index_type
                    , adjustment_type
                    , month_number
                    , std_country_id
                    , std_region_id
                    , std_sector_id
                    , std_region_desc
                    , std_sector_desc
                    , region_weight
                    , sector_weight
                    , raw_index_value
                    , orig_raw_index_value
                    , normalized_index_value
                    , patch_type
                    , patch_source
                    , index_status
                    , last_update_date
                  )
             WITH base_combinations AS
                  (
                    SELECT /*+ MATERIALIZE */ t.column_value AS month_number
                           , r.std_country_id
                           , r.std_region_id
                           , s.std_sector_id
                      FROM   TABLE(get_month_keys(p_date1, p_date2)) t
                           , dm_regions r
                           , dm_occupational_sectors s
                           , dm_country_sector_weights w
                     WHERE t.column_value > c_start_month
                       AND r.std_country_id = p_country
                       AND r.is_partof_index = 'Y'
                       AND r.std_region_type_id = p_region_type
                       AND s.is_partof_index = 'Y'
                       AND w.std_country_id = r.std_country_id
                       AND w.std_sector_id = s.std_sector_id
                       AND w.sector_weight > 0
                  ),
                  sector_region_base AS
                  (
                    SELECT /*+ MATERIALIZE */ i.std_sector_id
                           , i.std_country_id
                           , i.std_region_id
                           , i.raw_index_value
                      FROM   dm_iqn_index i
                           , dm_regions r
                     WHERE i.index_type = 'D'
                       AND i.adjustment_type = 'R'
                       AND i.month_number = c_start_month
                       AND i.std_country_id = p_country
                       AND i.raw_index_value > 0
                       AND r.is_partof_index = 'Y'
                       AND r.std_country_id = i.std_country_id
                       AND r.std_region_type_id = p_region_type
                       AND r.std_region_id = i.std_region_id
                  )
           SELECT   'D' AS index_type
                  , 'R' AS adjustment_type
                  , x.month_number
                  , x.std_country_id
                  , x.std_region_id
                  , x.std_sector_id
                  , z.std_region_desc
                  , y.std_sector_desc
                  , z.region_weight
                  , csw.sector_weight
                  , x.raw_index_value
                  , x.raw_index_value AS orig_raw_index_value
                  , ROUND((x.raw_index_value/srb.raw_index_value)*100, 2) AS normalized_index_value
                  , 'N' AS patch_type
                  , NULL AS patch_source
                  , DECODE(p_final_flag, 'Y', 'Final', 'Preliminary') AS index_status
                  , SYSDATE AS last_update_date
             FROM (
                    SELECT   b.month_number
                           , b.std_country_id
                           , b.std_region_id
                           , b.std_sector_id
                           , SUM(w.avg_bill_rate*w.rolling_avg_weight) raw_index_value
                      FROM   base_combinations b, dm_sector_region_title_weights w
                     WHERE w.month_number  (+) = b.month_number
                       AND w.std_region_id (+) = b.std_region_id
                       AND w.std_sector_id (+) = b.std_sector_id
                       AND w.std_country_id (+) = b.std_country_id
                       AND w.std_region_id (+) > 0
                     GROUP BY  b.month_number, b.std_country_id, b.std_region_id, b.std_sector_id
                  ) x, sector_region_base srb, dm_occupational_sectors y, dm_country_sector_weights csw, dm_regions z
            WHERE srb.std_sector_id = x.std_sector_id
              AND srb.std_region_id = x.std_region_id
              AND srb.std_country_id = x.std_country_id
              AND y.std_sector_id = x.std_sector_id
              AND csw.std_country_id = srb.std_country_id
              AND csw.std_sector_id = y.std_sector_id
              AND csw.sector_weight > 0
              AND z.std_region_id = x.std_region_id;

           --DBMS_OUTPUT.PUT_LINE('Inserted ' || SQL%ROWCOUNT || ' type D index records');

           IF (p_country = 1) 
              THEN
                    /*
                    ** Patch Healthcare Index values
                    ** with information from dm_bls_healthcare_rates 
                    */
                    MERGE INTO dm_iqn_index t
                    USING (
                            SELECT   o.hourly_rate, o.bls_month_number, b.raw_index_value AS base_raw_index_value
                                   , i.month_number, i.std_country_id, i.std_region_id, i.std_sector_id
                              FROM   TABLE(get_month_keys(p_date1, p_date2)) t
                                   , dm_iqn_index i, dm_iqn_index b, dm_bls_healthcare_rates o
                             WHERE t.column_value > c_start_month
                               AND i.month_number = t.column_value
                               AND i.std_sector_desc = 'Healthcare'
                               AND i.index_type = 'D'
                               AND i.adjustment_type = 'R'
                               AND i.std_country_id = p_country
                               AND b.index_type = i.index_type
                               AND b.adjustment_type = i.adjustment_type
                               AND b.std_country_id = i.std_country_id
                               AND b.std_sector_id = i.std_sector_id
                               AND b.std_region_id = i.std_region_id
                               AND b.month_number = c_start_month --i.month_number
                               AND o.override_month_number = i.month_number
                          ) s
                       ON (
                                t.std_country_id = s.std_country_id
                            AND t.std_region_id = s.std_region_id
                            AND t.std_sector_id = s.std_sector_id
                            AND t.month_number  = s.month_number
                            AND t.index_type = 'D'
                            AND t.adjustment_type = 'R'
                          )
                     WHEN MATCHED THEN UPDATE SET   t.patch_type             = 'O'
                                                  , t.patch_source           = 'DM_BLS_HEALTHCARE_RATES.BLS_MONTH_NUMBER = ' || TO_CHAR(s.bls_month_number)
                                                  , t.raw_index_value        = s.hourly_rate
                                                  , t.normalized_index_value = ROUND((s.hourly_rate/s.base_raw_index_value)*100, 2)
                                                  , t.index_status           = DECODE(p_final_flag, 'Y', 'Final', 'Preliminary')
                                                  , t.last_update_date       = SYSDATE;

                    /*
                    ** For All Index values after 201112
                    ** Make special adjustment
                    */
                    MERGE INTO dm_iqn_index t
                    USING (
                            SELECT   b.raw_index_value AS base_raw_index_value
                                   , i.month_number, i.std_country_id, i.std_region_id, i.std_sector_id
                                   , i.raw_index_value + (b.raw_index_value * a.adjustment_factor) new_raw_index_value
                              FROM   TABLE(get_month_keys(p_date1, p_date2)) t
                                   , dm_iqn_index i, dm_iqn_index b, dm_sector_region_adjustment a
                             WHERE t.column_value >= k_adj_start_month
                               AND i.month_number = t.column_value
                               AND i.index_type = 'D'
                               AND i.adjustment_type = 'R'
                               AND i.std_country_id = p_country
                               AND b.index_type = i.index_type
                               AND b.adjustment_type = i.adjustment_type
                               AND b.std_country_id = i.std_country_id
                               AND b.std_sector_id = i.std_sector_id
                               AND b.std_region_id = i.std_region_id
                               AND b.month_number = c_start_month
                               AND a.std_country_id = i.std_country_id
                               AND a.std_sector_id = i.std_sector_id
                               AND a.std_region_id = i.std_region_id
                               AND a.adjustment_factor <> 0
                          ) s
                       ON (
                                t.std_country_id = s.std_country_id
                            AND t.std_region_id = s.std_region_id
                            AND t.std_sector_id = s.std_sector_id
                            AND t.month_number  = s.month_number
                            AND t.index_type = 'D'
                            AND t.adjustment_type = 'R'
                          )
                     WHEN MATCHED THEN UPDATE SET   t.patch_type             = 'A'
                                                  , t.patch_source           = 'DM_SECTOR_REGION_ADJUSTMENT'
                                                  , t.raw_index_value        = s.new_raw_index_value
                                                  , t.normalized_index_value = ROUND((s.new_raw_index_value/s.base_raw_index_value)*100, 2)
                                                  , t.index_status           = DECODE(p_final_flag, 'Y', 'Final', 'Preliminary')
                                                  , t.last_update_date       = SYSDATE;
                    COMMIT;
           END IF;

           /*
           ** See if there are any
           ** Missing Index values due to no data 
           ** at region and sector level
           **
           ** If so copy data from prior month but same region and sector
           */
           MERGE INTO dm_iqn_index t
           USING (
                   SELECT   i.month_number, i.std_country_id, i.std_region_id, i.std_sector_id, i.adjustment_type, i.index_type
                          , i2.month_number prev_month_number, i2.raw_index_value, i2.normalized_index_value
                     FROM   TABLE(dm_index.get_month_keys(p_date1, p_date2)) m
                          , dm_iqn_index i, dm_iqn_index i2
                    WHERE i.month_number = m.column_value
                      AND i.index_type = 'D'
                      AND i.adjustment_type = 'R'
                      AND i.std_country_id = p_country
                      AND (
                               i.raw_index_value IS NULL
                            OR
                               (
                                      i.std_sector_desc = 'Healthcare'
                                  AND i.patch_type      = 'N'
                               )
                          )
                      AND i2.month_number = TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE(TO_CHAR(i.month_number), 'YYYYMM'), -1), 'YYYYMM'))
                      AND i2.index_type = i.index_type
                      AND i2.adjustment_type = i.adjustment_type
                      AND i2.std_country_id = i.std_country_id
                      AND i2.std_region_id = i.std_region_id
                      AND i2.std_sector_id = i.std_sector_id
                 ) s
              ON (
                       t.std_country_id = s.std_country_id
                   AND t.std_region_id = s.std_region_id
                   AND t.std_sector_id = s.std_sector_id
                   AND t.month_number  = s.month_number
                   AND t.index_type = s.index_type
                   AND t.adjustment_type = s.adjustment_type
                 )
            WHEN MATCHED THEN UPDATE SET   t.patch_type             = 'C'
                                         , t.patch_source           = 'DM_IQN_INDEX.MONTH_NUMBER = ' || TO_CHAR(s.prev_month_number)
                                         , t.raw_index_value        = s.raw_index_value
                                         , t.normalized_index_value = s.normalized_index_value
                                         , t.index_status           = DECODE(p_final_flag, 'Y', 'Final', 'Preliminary')
                                         , t.last_update_date       = SYSDATE;

           --DBMS_OUTPUT.PUT_LINE('Copied ' || SQL%ROWCOUNT || ' type D index records');
           v_rec_count := SQL%ROWCOUNT;
           COMMIT;

           IF (v_rec_count > 0)
              THEN
                    --dm_utils.send_email(c_email_sender, c_email_recipients, email_subject, 'Please make a NOTE that ' || v_rec_count || ' missing IQN Index values have been copied from previous month' || c_crlf);
                    COMMIT;
           END IF;
    END populate_sector_region_index;

    PROCEDURE populate_sector_index
    (
        p_date1      IN DATE
      , p_date2      IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_adj_type   IN dm_iqn_index.adjustment_type%TYPE DEFAULT 'R'
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
    )
    IS
           base_value_count PLS_INTEGER;
    BEGIN
           /*
           ** See if base index values 
           ** (for starting month 200801)
           ** exist for All region, sector level (index_type = 'S')
           */
           SELECT COUNT(*)
             INTO base_value_count
             FROM dm_iqn_index i
            WHERE i.std_country_id = p_country
              AND i.index_type = 'S'
              AND adjustment_type = p_adj_type
              AND month_number = c_start_month;

           IF (base_value_count = 0)
              THEN
                   INSERT INTO dm_iqn_index t
                          (
                              index_type
                            , adjustment_type
                            , month_number
                            , std_country_id
                            , std_region_id
                            , std_sector_id
                            , std_region_desc
                            , std_sector_desc
                            , region_weight
                            , sector_weight
                            , raw_index_value
                            , orig_raw_index_value
                            , normalized_index_value
                            , patch_type
                            , patch_source
                            , index_status
                            , last_update_date
                          )
                   SELECT   'S' AS index_type
                          , p_adj_type AS adjustment_type
                          , i.month_number
                          , i.std_country_id
                          , 0 AS std_region_id
                          , i.std_sector_id
                          , 'All Regions' AS std_region_desc
                          , MIN(i.std_sector_desc) std_sector_desc
                          , 1 AS region_weight
                          , MIN(i.sector_weight)
                          , SUM(i.raw_index_value * i.region_weight) raw_index_value
                          , SUM(i.orig_raw_index_value * i.region_weight) orig_raw_index_value
                          , 100 AS normalized_index_value
                          , 'N' AS patch_type
                          , NULL AS patch_source
                          , DECODE(p_final_flag, 'Y', 'Final', 'Preliminary') AS index_status
                          , SYSDATE AS last_update_date
                     FROM dm_iqn_index i
                    WHERE i.adjustment_type = p_adj_type
                      AND i.index_type      = 'D'
                      AND i.std_country_id  = p_country
                      AND i.month_number = c_start_month
                    GROUP BY i.month_number, i.std_country_id, i.std_sector_id;

                    COMMIT;

                    IF (p_country = 147)
                       THEN
                            UPDATE dm_iqn_index i
                               SET   i.raw_index_value = i.raw_index_value + DECODE(i.std_sector_id, 2, -2, 3, -1.75, 0)
                                   , i.patch_type = 'U'
                                   , i.patch_source = 'Algorithm'
                                   , i.last_update_date = SYSDATE
                             WHERE i.adjustment_type = 'R'
                               AND i.index_type      = 'S'
                               AND i.std_country_id  = p_country
                               AND i.month_number = c_start_month;
                    END IF;
           END IF;

           INSERT INTO dm_iqn_index t
                  (
                      index_type
                    , adjustment_type
                    , month_number
                    , std_country_id
                    , std_region_id
                    , std_sector_id
                    , std_region_desc
                    , std_sector_desc
                    , region_weight
                    , sector_weight
                    , raw_index_value
                    , orig_raw_index_value
                    , normalized_index_value
                    , patch_type
                    , patch_source
                    , index_status
                    , last_update_date
                  )
           SELECT   'S' AS index_type
                  , p_adj_type AS adjustment_type
                  , x.month_number
                  , x.std_country_id
                  , 0 AS std_region_id
                  , x.std_sector_id
                  , 'All Regions' AS std_region_desc
                  , x.std_sector_desc
                  , 1 AS region_weight
                  , x.sector_weight
                  , x.raw_index_value
                  , x.orig_raw_index_value
                  , ROUND((x.raw_index_value/b.raw_index_value)*100, 2) AS normalized_index_value
                  , 'N' AS patch_type
                  , NULL AS patch_source
                  , DECODE(p_final_flag, 'Y', 'Final', 'Preliminary') AS index_status
                  , SYSDATE AS last_update_date
             FROM (
                    SELECT   i.month_number
                           , i.std_country_id
                           , i.std_sector_id
                           , MIN(i.std_sector_desc) std_sector_desc
                           , MIN(i.sector_weight) sector_weight
                           , SUM(i.raw_index_value * i.region_weight) raw_index_value
                           , SUM(i.orig_raw_index_value * i.region_weight) orig_raw_index_value
                      FROM dm_iqn_index i
                     WHERE i.adjustment_type = p_adj_type
                       AND i.index_type      = 'D'
                       AND i.std_country_id  = p_country
                       AND i.month_number > c_start_month
                       AND i.month_number >= TO_NUMBER(TO_CHAR(p_date1, 'YYYYMM'))
                       AND i.month_number <= TO_NUMBER(TO_CHAR(p_date2, 'YYYYMM'))
                     GROUP BY i.month_number, i.std_country_id, i.std_sector_id
                   ) x, dm_iqn_index b
             WHERE b.adjustment_type = p_adj_type
               AND b.index_type = 'S'
               AND b.month_number = c_start_month
               AND b.std_country_id = x.std_country_id
               AND b.std_sector_id = x.std_sector_id
             ORDER BY x.std_country_id, x.std_sector_id, x.month_number;

           COMMIT;
    END populate_sector_index;

    PROCEDURE populate_region_index
    (
        p_date1      IN DATE
      , p_date2      IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_adj_type   IN dm_iqn_index.adjustment_type%TYPE DEFAULT 'R'
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
    )
    IS
           base_value_count PLS_INTEGER;
           v_final_count PLS_INTEGER;
    BEGIN
           /*
           ** See if base index values 
           ** (for starting month 200801)
           ** exist for All Occupational Sectors By Region (index_type = 'R')
           */
           SELECT COUNT(*)
             INTO base_value_count
             FROM dm_iqn_index i
            WHERE i.index_type = 'R'
              AND i.adjustment_type = p_adj_type
              AND i.std_country_id = p_country
              AND i.month_number = c_start_month;

           IF (base_value_count = 0)
              THEN
                   INSERT INTO dm_iqn_index t
                          (
                              index_type
                            , adjustment_type
                            , month_number
                            , std_country_id
                            , std_region_id
                            , std_sector_id
                            , std_region_desc
                            , std_sector_desc
                            , region_weight
                            , sector_weight
                            , raw_index_value
                            , orig_raw_index_value
                            , normalized_index_value
                            , patch_type
                            , patch_source
                            , index_status
                            , last_update_date
                          )
                   SELECT   'R' AS index_type
                          , p_adj_type AS adjustment_type
                          , i.month_number
                          , i.std_country_id
                          , i.std_region_id
                          , 0 AS std_sector_id
                          , MIN(i.std_region_desc)
                          , 'All Sectors' AS std_sector_desc
                          , MIN(i.region_weight) AS region_weight
                          , 1 AS sector_weight
                          , SUM(i.raw_index_value * i.sector_weight) AS raw_index_value
                          , SUM(i.orig_raw_index_value * i.sector_weight) AS orig_raw_index_value
                          , 100 AS normalized_index_value
                          , 'N' AS patch_type
                          , NULL AS patch_source
                          , DECODE(p_final_flag, 'Y', 'Final', 'Preliminary') AS index_status
                          , SYSDATE AS last_update_date
                     FROM dm_iqn_index i
                    WHERE i.adjustment_type = p_adj_type
                      AND i.index_type      = 'D'
                      AND i.std_country_id  = p_country
                      AND i.month_number = c_start_month
                    GROUP BY i.month_number, i.std_country_id, i.std_region_id;
           END IF;

           INSERT INTO dm_iqn_index t
                  (
                      index_type
                    , adjustment_type
                    , month_number
                    , std_country_id
                    , std_region_id
                    , std_sector_id
                    , std_region_desc
                    , std_sector_desc
                    , region_weight
                    , sector_weight
                    , raw_index_value
                    , orig_raw_index_value
                    , normalized_index_value
                    , patch_type
                    , patch_source
                    , index_status
                    , last_update_date
                  )
           SELECT   'R' AS index_type
                  , p_adj_type AS adjustment_type
                  , x.month_number
                  , x.std_country_id
                  , x.std_region_id
                  , 0 AS std_sector_id
                  , x.std_region_desc
                  , 'All Sectors' AS std_sector_desc
                  , x.region_weight
                  , 1 AS sector_weight
                  , x.raw_index_value
                  , x.orig_raw_index_value
                  , ROUND((x.raw_index_value/b.raw_index_value)*100, 2) AS normalized_index_value
                  , 'N' AS patch_type
                  , NULL AS patch_source
                  , DECODE(p_final_flag, 'Y', 'Final', 'Preliminary') AS index_status
                  , SYSDATE AS last_update_date
             FROM (
                    SELECT   i.month_number
                           , i.std_country_id
                           , i.std_region_id
                           , MIN(i.std_region_desc) AS std_region_desc
                           , MIN(i.region_weight) AS region_weight
                           , SUM(i.raw_index_value * i.sector_weight) raw_index_value
                           , SUM(i.orig_raw_index_value * i.sector_weight) orig_raw_index_value
                      FROM dm_iqn_index i
                     WHERE i.adjustment_type = p_adj_type
                       AND i.index_type      = 'D'
                       AND i.std_country_id  = p_country
                       AND i.month_number > c_start_month
                       AND i.month_number >= TO_NUMBER(TO_CHAR(p_date1, 'YYYYMM'))
                       AND i.month_number <= TO_NUMBER(TO_CHAR(p_date2, 'YYYYMM'))
                     GROUP BY i.month_number, i.std_country_id, i.std_region_id
                   ) x, dm_iqn_index b
             WHERE b.adjustment_type = p_adj_type
               AND b.index_type = 'R'
               AND b.month_number = c_start_month
               AND b.std_country_id = x.std_country_id
               AND b.std_region_id = x.std_region_id
             ORDER BY x.std_country_id, x.std_region_id, x.month_number;

           COMMIT;
    END populate_region_index;

    PROCEDURE populate_national_index
    (
        p_date1      IN DATE
      , p_date2      IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_adj_type   IN dm_iqn_index.adjustment_type%TYPE DEFAULT 'R'
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
    )
    IS
           base_value_count PLS_INTEGER;
           v_national_base_value dm_iqn_index.raw_index_value%TYPE;
    BEGIN
           /*
           ** See if base index values 
           ** (for starting month 200801)
           ** exist for National (All sector, All region) level (index_type = 'N')
           */
           SELECT COUNT(*)
             INTO base_value_count
             FROM dm_iqn_index i
            WHERE i.index_type = 'N'
              AND i.adjustment_type = p_adj_type
              AND i.std_country_id = p_country
              AND i.month_number = c_start_month;

           IF (base_value_count = 0)
              THEN
                   INSERT INTO dm_iqn_index t
                          (
                              index_type
                            , adjustment_type
                            , month_number
                            , std_country_id
                            , std_region_id
                            , std_sector_id
                            , std_region_desc
                            , std_sector_desc
                            , region_weight
                            , sector_weight
                            , raw_index_value
                            , orig_raw_index_value
                            , normalized_index_value
                            , patch_type
                            , patch_source
                            , index_status
                            , last_update_date
                          )
                   SELECT   'N' AS index_type
                          , p_adj_type AS adjustment_type
                          , i.month_number
                          , MIN(i.std_country_id) AS std_country_id
                          , MIN(i.std_region_id) AS std_region_id
                          , 0 AS std_sector_id
                          , MIN(i.std_region_desc)
                          , 'All Sectors' AS std_sector_desc
                          , MIN(i.region_weight) AS region_weight
                          , 1 AS sector_weight
                          , SUM(i.raw_index_value * i.sector_weight) AS raw_index_value
                          , SUM(i.orig_raw_index_value * i.sector_weight) AS orig_raw_index_value
                          , 100 AS normalized_index_value
                          , 'N' AS patch_type
                          , NULL AS patch_source
                          , DECODE(p_final_flag, 'Y', 'Final', 'Preliminary') AS index_status
                          , SYSDATE AS last_update_date
                     FROM dm_iqn_index i
                    WHERE i.adjustment_type = p_adj_type
                      AND i.index_type      = 'S'
                      AND i.std_country_id  = p_country
                      AND i.month_number = c_start_month
                    GROUP BY i.month_number;
           END IF;

           INSERT INTO dm_iqn_index t
                  (
                      index_type
                    , adjustment_type
                    , month_number
                    , std_country_id
                    , std_region_id
                    , std_sector_id
                    , std_region_desc
                    , std_sector_desc
                    , region_weight
                    , sector_weight
                    , raw_index_value
                    , orig_raw_index_value
                    , normalized_index_value
                    , patch_type
                    , patch_source
                    , index_status
                    , last_update_date
                  )
           SELECT   'N' AS index_type
                  , p_adj_type AS adjustment_type
                  , x.month_number
                  , x.std_country_id
                  , x.std_region_id
                  , 0 AS std_sector_id
                  , x.std_region_desc
                  , 'All Sectors' AS std_sector_desc
                  , x.region_weight
                  , 1 AS sector_weight
                  , x.raw_index_value
                  , x.orig_raw_index_value
                  , ROUND((x.raw_index_value/b.raw_index_value)*100, 2) AS normalized_index_value
                  , 'N' AS patch_type
                  , NULL AS patch_source
                  , DECODE(p_final_flag, 'Y', 'Final', 'Preliminary') AS index_status
                  , SYSDATE AS last_update_date
             FROM (
                    SELECT   i.month_number
                           , MIN(i.std_country_id) AS std_country_id
                           , MIN(i.std_region_id) AS std_region_id
                           , MIN(i.std_region_desc) AS std_region_desc
                           , MIN(i.region_weight) AS region_weight
                           , SUM(i.raw_index_value * i.sector_weight) raw_index_value
                           , SUM(i.orig_raw_index_value * i.sector_weight) orig_raw_index_value
                      FROM dm_iqn_index i
                     WHERE i.adjustment_type = p_adj_type
                       AND i.index_type      = 'S'
                       AND i.std_country_id  = p_country
                       AND i.month_number > c_start_month
                       AND i.month_number >= TO_NUMBER(TO_CHAR(p_date1, 'YYYYMM'))
                       AND i.month_number <= TO_NUMBER(TO_CHAR(p_date2, 'YYYYMM'))
                     GROUP BY i.month_number
                   ) x, dm_iqn_index b
             WHERE b.adjustment_type = p_adj_type
               AND b.index_type = 'N'
               AND b.month_number = c_start_month
               AND b.std_country_id = x.std_country_id;

           COMMIT;
    END populate_national_index;

    PROCEDURE populate_index
    (
        p_date1      IN DATE
      , p_date2      IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
      , p_upd_wts_flag IN VARCHAR2 DEFAULT 'N' -- Update Title Weights and Index based on Frozen Weighted Rate Events
    )
    IS
           CURSOR c1 IS
           SELECT std_country_id, std_region_type_id
             FROM dm_regions
            WHERE is_partof_index = 'Y'
              AND std_country_id = p_country
            GROUP BY std_country_id, std_region_type_id
           HAVING SUM(region_weight) = 1
            ORDER BY DECODE(std_region_type_id, DECODE(std_country_id, 147, 8, 97, 9, 6), 9999999999, std_region_type_id) DESC;

           v_primary_region_type dm_regions.std_region_type_id%TYPE := NULL;
           v_final_count PLS_INTEGER;
    BEGIN
           /*
           ** Set country specific parameters
           ** Index calculations
           */
           set_country_parms(p_country);

           IF (p_upd_wts_flag = 'Y')
              THEN
                   DELETE dm_iqn_index i
                    WHERE i.std_country_id = p_country
                      AND i.adjustment_type = 'R'
                      AND EXISTS (
                                   SELECT NULL
                                     FROM TABLE(get_month_keys(p_date1, p_date2)) t
                                    WHERE t.column_value = i.month_number
                                 );
              ELSE
                   DELETE dm_iqn_index i
                    WHERE i.std_country_id = p_country
                      AND i.adjustment_type = 'R'
                      AND i.index_status    = 'Preliminary'
                      AND EXISTS (
                                   SELECT NULL
                                     FROM TABLE(get_month_keys(p_date1, p_date2)) t
                                    WHERE t.column_value = i.month_number
                                 );

                  DELETE dm_sector_region_title_weights i
                   WHERE std_country_id = p_country
                     AND EXISTS (
                                  SELECT NULL
                                    FROM TABLE(get_month_keys(p_date1, p_date2)) t
                                   WHERE t.column_value = i.month_number
                                );
           END IF;

           SELECT count(*)
             INTO v_final_count
             FROM dm_iqn_index i
            WHERE i.std_country_id = p_country
              AND i.adjustment_type = 'R'
              AND i.index_status    = 'Final'
              AND EXISTS (
                           SELECT NULL
                             FROM TABLE(get_month_keys(p_date1, p_date2)) t
                            WHERE t.column_value = i.month_number
                         );

           IF (p_upd_wts_flag = 'N' AND p_final_flag = 'Y')
              THEN
                   IF (v_final_count > 0)
                      THEN
                            RAISE_APPLICATION_ERROR(-20010, 'Final Index values already exist for ' || TO_CHAR(p_date1, 'YYYYMM'));
                   END IF;

                   INSERT INTO dm_idx_wtd_rate_events
                   (
                       month_number
                     , assignment_id
                     , assignment_seq_number
                     , std_job_title_id
                     , data_source_code
                     , assignment_type
                     , duration_units
                     , proximity_weight
                     , std_job_title_desc
                     , std_place_id
                     , cmsa_code
                     , cmsa_name
                     , std_job_category_id
                     , std_job_category_desc
                     , reg_bill_rate
                     , buyer_bill_rate
                     , reg_pay_rate
                     , rate_event_decision_date
                     , rate_event_start_date
                     , rate_event_end_date
                     , currency_description
                     , job_title
                     , batch_id
                     , load_key
                     , last_update_date
                     , std_country_id
                     , rate_event_source
                     , first_expenditure_date
                     , last_expenditure_date
                     , std_buyerorg_id
                   )
                   SELECT
                       w.month_number
                     , w.assignment_id
                     , w.assignment_seq_number
                     , w.std_job_title_id
                     , w.data_source_code
                     , w.assignment_type
                     , w.duration_units
                     , w.proximity_weight
                     , w.std_job_title_desc
                     , w.std_place_id
                     , w.cmsa_code
                     , w.cmsa_name
                     , w.std_job_category_id
                     , w.std_job_category_desc
                     , w.reg_bill_rate
                     , w.buyer_bill_rate
                     , w.reg_pay_rate
                     , w.rate_event_decision_date
                     , w.rate_event_start_date
                     , w.rate_event_end_date
                     , w.currency_description
                     , w.job_title
                     , w.batch_id
                     , w.load_key
                     , w.last_update_date
                     , w.std_country_id
                     , w.rate_event_source
                     , w.first_expenditure_date
                     , w.last_expenditure_date
                     , w.std_buyerorg_id
                   FROM dm_weighted_rate_events w
                  WHERE w.month_type = 'I'
                    AND w.std_country_id = p_country
                    AND EXISTS (
                                   SELECT NULL
                                     FROM TABLE(get_month_keys(p_date1, p_date2)) t
                                    WHERE t.column_value = w.month_number
                               );
              ELSE
                   IF (p_upd_wts_flag = 'N' AND v_final_count > 0)
                      THEN
                            RAISE_APPLICATION_ERROR(-20011, 'Can not compute Preliminary Index when Final Index values already exist for ' || TO_CHAR(p_date1, 'YYYYMM'));
                   END IF;
           END IF;

           --DBMS_OUTPUT.PUT_LINE('Saved old weighted events into dm_idx_wtd_rate_events');

           /*
           ** Generate Normal/Regular Index values
           */
           FOR r1 IN c1
           LOOP
                IF (v_primary_region_type IS NULL)
                   THEN
                        v_primary_region_type := r1.std_region_type_id;
                        populate_monthly_title_avgs(p_date1, p_date2, p_country, v_primary_region_type, 'Y', p_upd_wts_flag);
                        --DBMS_OUTPUT.PUT_LINE('Done with populate_monthly_title_avgs');
                        populate_sector_region_index(p_date1, p_date2, p_country, r1.std_region_type_id, p_final_flag);
                        --DBMS_OUTPUT.PUT_LINE('Done with populate_sector_region_index');
                   --ELSE
                   --     populate_monthly_title_avgs(p_date1, p_date2, p_country, v_primary_region_type);
                END IF;
                --populate_sector_region_index(p_date1, p_date2, p_country, r1.std_region_type_id);
           END LOOP;
           COMMIT;

           populate_sector_index       (p_date1, p_date2, p_country, 'R', p_final_flag);
           COMMIT;

           FOR r1 IN c1
           LOOP
                IF (v_primary_region_type = r1.std_region_type_id)
                   THEN
                        populate_region_index       (p_date1, p_date2, p_country, 'R', p_final_flag);
                END IF;
           END LOOP;
           COMMIT;

           populate_national_index     (p_date1, p_date2, p_country, 'R', p_final_flag);
           COMMIT;
    END populate_index;

    PROCEDURE re_populate_index
    (
        p_date1 IN DATE
      , p_date2 IN DATE
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_final_flag IN VARCHAR2 DEFAULT 'Y'
    )
    IS
    BEGIN
          DELETE dm_iqn_index i
           WHERE std_country_id = p_country
             AND EXISTS (
                          SELECT NULL
                            FROM TABLE(get_month_keys(p_date1, p_date2)) t
                           WHERE t.column_value = i.month_number
                        );

          DELETE dm_sector_region_title_weights i
           WHERE std_country_id = p_country
             AND EXISTS (
                          SELECT NULL
                            FROM TABLE(get_month_keys(p_date1, p_date2)) t
                           WHERE t.column_value = i.month_number
                        );

          populate_index(p_date1, p_date2, p_country, p_final_flag);
          COMMIT;
    END re_populate_index;

    PROCEDURE redo_whole_index
    IS
    BEGIN
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_iqn_index';
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_sector_region_title_weights';
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_idx_wtd_rate_events';
          set_country_parms(1);
          populate_index(c_start_date, SYSDATE, 1,   'Y');
          set_country_parms(147);
          populate_index(c_start_date, SYSDATE, 147, 'Y');
          COMMIT;
    END redo_whole_index;

    PROCEDURE populate_monthly_title_avgs
    (
        p_date1         IN DATE
      , p_date2         IN DATE
      , p_country       IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_region_type   IN dm_regions.std_region_type_id%TYPE
      , p_national_flag IN VARCHAR2 DEFAULT 'N'
      , p_update_flag   IN VARCHAR2 DEFAULT 'N'
    )
    IS
           CURSOR c1 IS
           SELECT m.column_value AS month_number
             FROM TABLE(get_month_keys(p_date1, p_date2)) m
            ORDER BY m.column_value;
    BEGIN
           FOR r1 IN c1
           LOOP
                IF (p_update_flag = 'N')
                   THEN get_monthly_title_avgs(r1.month_number, p_country, p_region_type, p_national_flag);
                   ELSE update_monthly_title_avgs(r1.month_number, p_country, p_region_type, p_national_flag);
                END IF;
           END LOOP;
           COMMIT;
    END populate_monthly_title_avgs;

    PROCEDURE get_monthly_title_avgs
    (
        p_month         IN NUMBER
      , p_country       IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_region_type   IN dm_regions.std_region_type_id%TYPE
      , p_national_flag IN VARCHAR2 DEFAULT 'N'
    )
    IS
           CURSOR c1 IS
           SELECT m.column_value AS month_number
             FROM TABLE(get_month_keys(c_start_date, ADD_MONTHS(TO_DATE(TO_CHAR(p_month), 'YYYYMM'), -1))) m
            ORDER BY m.column_value;
    BEGIN
           get_title_buyer_weights(p_month, p_country);

           --DBMS_OUTPUT.PUT_LINE('Trying to get_monthly_title_avgs for ' || p_month);
           --DBMS_OUTPUT.PUT_LINE('p_month = ' || p_month);
           --DBMS_OUTPUT.PUT_LINE('p_country = ' || p_country);
           --DBMS_OUTPUT.PUT_LINE('p_region_type = ' || p_region_type);
           --DBMS_OUTPUT.PUT_LINE('p_national_flag = ' || p_national_flag);
           INSERT INTO dm_sector_region_title_weights
           (
               std_country_id
             , month_number
             , std_job_title_id
             , std_region_id
             , std_sector_id
             , avg_bill_rate
             , duration_units
             , avg_unadj_bill_rate
             , unadj_duration_units
           )
           WITH filtered_list AS
           (
             SELECT /*+ MATERIALIZE */ l.std_job_title_id
               FROM (
                      SELECT   w.std_job_title_id
                             , COUNT(DISTINCT w.data_source_code || '-' || w.assignment_id)   AS assignment_count
                             , COUNT(DISTINCT w.data_source_code || '-' || w.std_buyerorg_id) AS buyer_count
                        FROM dm_weighted_rate_events w
                       WHERE w.std_country_id = p_country
                         AND w.month_type = 'I'
                         AND w.month_number = p_month
                       GROUP BY w.std_job_title_id
                    ) l
              WHERE l.buyer_count      >= 3
                AND l.assignment_count >= 30
           )
           SELECT   k.std_country_id
                  , k.month_number
                  , k.std_job_title_id
                  , k.std_region_id
                  , s.std_sector_id
                  , ROUND(k.sum_bill_rate/k.duration_units, 2) avg_bill_rate
                  , k.duration_units
                  , ROUND(k.sum_unadj_bill_rate/k.unadj_duration_units, 2) avg_unadj_bill_rate
                  , k.unadj_duration_units
             FROM (
                    SELECT   x.std_country_id
                           , x.std_region_id
                           , x.std_job_title_id
                           , x.month_number
                           , MIN(x.std_job_category_id) std_job_category_id
                           , SUM(x.reg_bill_rate*x.duration_units) AS sum_bill_rate
                           , SUM(x.duration_units) AS duration_units
                           , SUM(x.unadj_reg_bill_rate*x.red_impct_duration_units) AS sum_unadj_bill_rate
                           , SUM(red_impct_duration_units) AS unadj_duration_units
                      FROM (
                             SELECT   z.std_country_id
                                    , z.std_region_id
                                    , z.std_job_title_id
                                    , z.month_number
                                    , z.std_buyerorg_id
                                    , z.data_source_code
                                    , z.std_job_category_id
                                    , z.sum_bill_rate/z.duration_units AS reg_bill_rate
                                    , z.duration_units
                                    , z.sum_unadj_bill_rate/z.unadj_duration_units AS unadj_reg_bill_rate
                                    , z.unadj_duration_units*y.reduction_factor  AS red_impct_duration_units
                               FROM (
                                      SELECT   w.std_country_id
                                             , r.std_region_id
                                             , w.std_job_title_id
                                             , w.month_number
                                             , w.std_buyerorg_id
                                             , w.data_source_code
                                             , MIN(w.std_job_category_id) std_job_category_id
                                             , SUM(w.reg_bill_rate*w.proximity_weight*w.duration_units) AS sum_bill_rate
                                             , SUM(w.duration_units*w.proximity_weight) AS duration_units
                                             , SUM(w.reg_bill_rate*w.duration_units) AS sum_unadj_bill_rate
                                             , SUM(w.duration_units) AS unadj_duration_units
                                        FROM filtered_list f, dm_weighted_rate_events w, dm_region_place_map m, dm_regions r
                                       WHERE w.std_job_title_id = f.std_job_title_id
                                         AND w.std_country_id = p_country
                                         AND m.std_place_id = w.std_place_id
                                         AND r.std_region_id = m.std_region_id
                                         AND r.is_partof_index = 'Y'
                                         AND r.std_region_type_id = p_region_type
                                         AND w.month_type = 'I'
                                         AND w.month_number = p_month
                                       GROUP BY w.std_country_id, r.std_region_id, w.std_job_title_id, w.month_number, w.std_buyerorg_id, w.data_source_code
                                    ) z,
                                    (
                                      SELECT   std_country_id
                                             , std_job_title_id
                                             , data_source_code
                                             , std_buyerorg_id
                                             , DECODE(heavy_weight, 'N', 1, reduced_volume/orig_unadj_volume) reduction_factor
                                        FROM dm_title_buyer_weights
                                    ) y
                              WHERE y.std_country_id = z.std_country_id
                                AND y.std_job_title_id = z.std_job_title_id
                                and y.data_source_code = z.data_source_code
                                and y.std_buyerorg_id = z.std_buyerorg_id
                           ) x
                     GROUP BY x.std_country_id, x.std_region_id, x.std_job_title_id, x.month_number
                  ) k, dm_job_category jc, dm_occupational_sectors s
            WHERE jc.std_job_category_id = k.std_job_category_id
              AND s.std_sector_id = jc.std_sector_id
              AND s.is_partof_index = 'Y';

           COMMIT;
           --DBMS_OUTPUT.PUT_LINE('Done computing sector region title weights for ' || p_month);
           IF (p_month >= c_rolling_effective_month)
              THEN
                    IF (p_national_flag = 'Y')
                       THEN
                             get_nat_title_rolling_avgs(p_month, p_country);
                             --DBMS_OUTPUT.PUT_LINE('Done computing natonal ' || c_rolling_months || ' month rolling averages for ' || p_month);
                    END IF;
                    update_reg_title_rolling_avgs(p_month, p_country);
                    --DBMS_OUTPUT.PUT_LINE('Done rebalancing regional title weights for ' || p_month);
                    IF (p_month = c_rolling_effective_month)
                       THEN
                            FOR r1 IN c1
                            LOOP
                                 IF (p_national_flag = 'Y')
                                    THEN
                                          copy_nat_title_rolling_avgs(r1.month_number, p_month, p_country);
                                          --DBMS_OUTPUT.PUT_LINE('Done copying natonal rolling averages from ' || p_month || ' to ' || r1.month_number);
                                 END IF;
                                 update_reg_title_rolling_avgs(r1.month_number, p_country);
                                 --DBMS_OUTPUT.PUT_LINE('Done rebalancing regional title weights for ' || r1.month_number);
                            END LOOP;
                    END IF;
           END IF;
    END get_monthly_title_avgs;

    PROCEDURE update_monthly_title_avgs
    (
        p_month         IN NUMBER
      , p_country       IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
      , p_region_type   IN dm_regions.std_region_type_id%TYPE
      , p_national_flag IN VARCHAR2 DEFAULT 'N'
    )
    IS
           CURSOR c1 IS
           SELECT m.column_value AS month_number
             FROM TABLE(get_month_keys(c_start_date, ADD_MONTHS(TO_DATE(TO_CHAR(p_month), 'YYYYMM'), -1))) m
            ORDER BY m.column_value;
    BEGIN
           --DBMS_OUTPUT.PUT_LINE('Trying to get_monthly_title_avgs for ' || p_month);
           --DBMS_OUTPUT.PUT_LINE('p_month = ' || p_month);
           --DBMS_OUTPUT.PUT_LINE('p_country = ' || p_country);
           --DBMS_OUTPUT.PUT_LINE('p_region_type = ' || p_region_type);
           --DBMS_OUTPUT.PUT_LINE('p_national_flag = ' || p_national_flag);

           DELETE dm_sector_region_title_weights t
            WHERE t.std_country_id   = p_country
              AND t.month_number     = p_month
              AND t.std_job_title_id IN (
                                          SELECT l.std_job_title_id
                                            FROM (
                                                   SELECT   w.std_job_title_id
                                                          , COUNT(DISTINCT w.data_source_code || '-' || w.assignment_id)   AS assignment_count
                                                          , COUNT(DISTINCT w.data_source_code || '-' || w.std_buyerorg_id) AS buyer_count
                                                     FROM dm_idx_wtd_rate_events w
                                                    WHERE w.std_country_id = p_country
                                                      AND w.month_number = p_month
                                                    GROUP BY w.std_job_title_id
                                                 ) l
                                           WHERE l.buyer_count      < 3
                                              OR l.assignment_count < 30
                                        );
           COMMIT;

           get_hist_title_buyer_weights(p_month, p_country);

           MERGE INTO dm_sector_region_title_weights t
           USING (
           WITH filtered_list AS
           (
             SELECT /*+ MATERIALIZE */ l.std_job_title_id
               FROM (
                      SELECT   w.std_job_title_id
                             , COUNT(DISTINCT w.data_source_code || '-' || w.assignment_id)   AS assignment_count
                             , COUNT(DISTINCT w.data_source_code || '-' || w.std_buyerorg_id) AS buyer_count
                        FROM dm_idx_wtd_rate_events w
                       WHERE w.std_country_id = p_country
                         AND w.month_number = p_month
                       GROUP BY w.std_job_title_id
                    ) l
              WHERE l.buyer_count      >= 3
                AND l.assignment_count >= 30
           )
           SELECT   k.std_country_id
                  , k.month_number
                  , k.std_job_title_id
                  , k.std_region_id
                  , s.std_sector_id
                  , ROUND(k.sum_bill_rate/k.duration_units, 2) avg_bill_rate
                  , k.duration_units
                  , ROUND(k.sum_unadj_bill_rate/k.unadj_duration_units, 2) avg_unadj_bill_rate
                  , k.unadj_duration_units
             FROM (
                    SELECT   x.std_country_id
                           , x.std_region_id
                           , x.std_job_title_id
                           , x.month_number
                           , MIN(x.std_job_category_id) std_job_category_id
                           , SUM(x.reg_bill_rate*x.duration_units) AS sum_bill_rate
                           , SUM(x.duration_units) AS duration_units
                           , SUM(x.unadj_reg_bill_rate*x.red_impct_duration_units) AS sum_unadj_bill_rate
                           , SUM(red_impct_duration_units) AS unadj_duration_units
                      FROM (
                             SELECT   z.std_country_id
                                    , z.std_region_id
                                    , z.std_job_title_id
                                    , z.month_number
                                    , z.std_buyerorg_id
                                    , z.data_source_code
                                    , z.std_job_category_id
                                    , z.sum_bill_rate/z.duration_units AS reg_bill_rate
                                    , z.duration_units
                                    , z.sum_unadj_bill_rate/z.unadj_duration_units AS unadj_reg_bill_rate
                                    , z.unadj_duration_units*y.reduction_factor  AS red_impct_duration_units
                               FROM (
                                      SELECT   w.std_country_id
                                             , r.std_region_id
                                             , w.std_job_title_id
                                             , w.month_number
                                             , w.std_buyerorg_id
                                             , w.data_source_code
                                             , MIN(w.std_job_category_id) std_job_category_id
                                             , SUM(w.reg_bill_rate*w.proximity_weight*w.duration_units) AS sum_bill_rate
                                             , SUM(w.duration_units*w.proximity_weight) AS duration_units
                                             , SUM(w.reg_bill_rate*w.duration_units) AS sum_unadj_bill_rate
                                             , SUM(w.duration_units) AS unadj_duration_units
                                        FROM filtered_list f, dm_idx_wtd_rate_events w, dm_region_place_map m, dm_regions r
                                       WHERE w.std_job_title_id = f.std_job_title_id
                                         AND w.std_country_id = p_country
                                         AND m.std_place_id = w.std_place_id
                                         AND r.std_region_id = m.std_region_id
                                         AND r.is_partof_index = 'Y'
                                         AND r.std_region_type_id = p_region_type
                                         AND w.month_number = p_month
                                       GROUP BY w.std_country_id, r.std_region_id, w.std_job_title_id, w.month_number, w.std_buyerorg_id, w.data_source_code
                                    ) z,
                                    (
                                      SELECT   std_country_id
                                             , std_job_title_id
                                             , data_source_code
                                             , std_buyerorg_id
                                             , DECODE(heavy_weight, 'N', 1, reduced_volume/orig_unadj_volume) reduction_factor
                                        FROM dm_title_buyer_weights
                                    ) y
                              WHERE y.std_country_id = z.std_country_id
                                AND y.std_job_title_id = z.std_job_title_id
                                and y.data_source_code = z.data_source_code
                                and y.std_buyerorg_id = z.std_buyerorg_id
                           ) x
                     GROUP BY x.std_country_id, x.std_region_id, x.std_job_title_id, x.month_number
                  ) k, dm_job_category jc, dm_occupational_sectors s
            WHERE jc.std_job_category_id = k.std_job_category_id
              AND s.std_sector_id = jc.std_sector_id
              AND s.is_partof_index = 'Y'
                 ) s
              ON (
                       t.std_country_id   = s.std_country_id
                   AND t.month_number     = s.month_number
                   AND t.std_region_id    = s.std_region_id
                   AND t.std_sector_id    = s.std_sector_id
                   AND t.std_job_title_id = s.std_job_title_id
                 )
           WHEN MATCHED THEN UPDATE SET   t.avg_bill_rate        = s.avg_bill_rate
                                        , t.duration_units       = s.duration_units
                                        , t.avg_unadj_bill_rate  = s.avg_unadj_bill_rate
                                        , t.unadj_duration_units = s.unadj_duration_units;

           COMMIT;
           DBMS_OUTPUT.PUT_LINE('Done computing sector region title weights for ' || p_month);
           IF (p_month >= c_rolling_effective_month)
              THEN
                    IF (p_national_flag = 'Y')
                       THEN
                             update_nat_title_rolling_avgs(p_month, p_country);
                             DBMS_OUTPUT.PUT_LINE('Done computing natonal ' || c_rolling_months || ' month rolling averages for ' || p_month);
                    END IF;
                    update_reg_title_rolling_avgs(p_month, p_country);
                    DBMS_OUTPUT.PUT_LINE('Done rebalancing regional title weights for ' || p_month);
                    IF (p_month = c_rolling_effective_month)
                       THEN
                            FOR r1 IN c1
                            LOOP
                                 IF (p_national_flag = 'Y')
                                    THEN
                                          overwrite_nat_title_rlng_avgs(r1.month_number, p_month, p_country);
                                          DBMS_OUTPUT.PUT_LINE('Done copying natonal rolling averages from ' || p_month || ' to ' || r1.month_number);
                                 END IF;
                                 update_reg_title_rolling_avgs(r1.month_number, p_country);
                                 DBMS_OUTPUT.PUT_LINE('Done rebalancing regional title weights for ' || r1.month_number);
                            END LOOP;
                    END IF;
           END IF;
    END update_monthly_title_avgs;

    PROCEDURE update_reg_title_rolling_avgs
    (
        p_month   IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    )
    IS
    BEGIN
           MERGE INTO dm_sector_region_title_weights t
           USING (
                   SELECT   w2.std_country_id
                          , w2.month_number
                          , w2.std_region_id
                          , w2.std_sector_id
                          , w2.std_job_title_id
                          , w.rolling_avg_weight
                          , SUM(w.rolling_avg_weight) OVER (PARTITION BY w2.std_region_id, w2.std_sector_id) AS sum_rolling_weight 
                     FROM dm_sector_region_title_weights w, dm_sector_region_title_weights w2
                    WHERE w.std_country_id = p_country
                      AND w.month_number = p_month
                      AND w.std_region_id = 0
                      AND w.rolling_avg_weight IS NOT NULL
                      AND w2.std_country_id = w.std_country_id
                      AND w2.month_number = w.month_number
                      AND w2.std_sector_id = w.std_sector_id
                      AND w2.std_job_title_id = w.std_job_title_id
                      AND w2.std_region_id > 0
                 ) s
              ON (
                       t.std_country_id   = s.std_country_id
                   AND t.month_number     = s.month_number
                   AND t.std_region_id    = s.std_region_id
                   AND t.std_sector_id    = s.std_sector_id
                   AND t.std_job_title_id = s.std_job_title_id
                 )
           WHEN MATCHED THEN UPDATE SET t.rolling_avg_weight = ROUND(s.rolling_avg_weight/s.sum_rolling_weight, 4);
    END update_reg_title_rolling_avgs;

    PROCEDURE copy_nat_title_rolling_avgs
    (
        p_to_month   IN NUMBER
      , p_from_month IN NUMBER
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    )
    IS
    BEGIN
           INSERT INTO dm_sector_region_title_weights t
           (
               std_country_id
             , month_number
             , std_job_title_id
             , std_region_id
             , std_sector_id
             , title_unadj_duration_units
             , sector_unadj_duration_units
             , rolling_avg_weight
           )
           SELECT   s.std_country_id
                  , p_to_month AS month_number
                  , s.std_job_title_id
                  , s.std_region_id
                  , s.std_sector_id
                  , NULL AS title_unadj_duration_units
                  , NULL AS sector_unadj_duration_units
                  , s.rolling_avg_weight
             FROM dm_sector_region_title_weights s
            WHERE s.std_country_id = p_country
              AND s.month_number = p_from_month
              AND s.std_region_id = 0
              AND EXISTS (
                           SELECT NULL
                             FROM dm_sector_region_title_weights w
                            WHERE w.std_country_id = s.std_country_id
                              AND w.month_number = p_to_month
                              AND w.std_sector_id = s.std_sector_id
                              AND w.std_region_id > 0
                              AND w.std_job_title_id = s.std_job_title_id
                         );
    END copy_nat_title_rolling_avgs;

    PROCEDURE overwrite_nat_title_rlng_avgs
    (
        p_to_month   IN NUMBER
      , p_from_month IN NUMBER
      , p_country    IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    )
    IS
    BEGIN
           MERGE INTO dm_sector_region_title_weights t
           USING (
           SELECT   s1.std_country_id
                  , p_to_month AS month_number
                  , s1.std_job_title_id
                  , s1.std_region_id
                  , s1.std_sector_id
                  , NULL AS title_unadj_duration_units
                  , NULL AS sector_unadj_duration_units
                  , s1.rolling_avg_weight
             FROM dm_sector_region_title_weights s1
            WHERE s1.std_country_id = p_country
              AND s1.month_number = p_from_month
              AND s1.std_region_id = 0
              AND EXISTS (
                           SELECT NULL
                             FROM dm_sector_region_title_weights w
                            WHERE w.std_country_id = s1.std_country_id
                              AND w.month_number = p_to_month
                              AND w.std_sector_id = s1.std_sector_id
                              AND w.std_region_id > 0
                              AND w.std_job_title_id = s1.std_job_title_id
                         )
                  ) s
              ON (
                       t.std_country_id   = s.std_country_id
                   AND t.month_number     = s.month_number
                   AND t.std_region_id    = s.std_region_id
                   AND t.std_sector_id    = s.std_sector_id
                   AND t.std_job_title_id = s.std_job_title_id
                 )
           WHEN MATCHED THEN UPDATE SET   t.title_unadj_duration_units  = s.title_unadj_duration_units
                                        , t.sector_unadj_duration_units = s.sector_unadj_duration_units
                                        , t.rolling_avg_weight          = s.rolling_avg_weight;
    END overwrite_nat_title_rlng_avgs;

    PROCEDURE get_nat_title_rolling_avgs
    (
        p_month   IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    )
    IS
    BEGIN
           INSERT INTO dm_sector_region_title_weights
           (
               std_country_id
             , month_number
             , std_job_title_id
             , std_region_id
             , std_sector_id
             , title_unadj_duration_units
             , sector_unadj_duration_units
             , rolling_avg_weight
           )
           SELECT   y.std_country_id
                  , p_month AS month_number
                  , y.std_job_title_id
                  , 0 AS std_region_id
                  , y.std_sector_id
                  , y.title_unadj_duration_units
                  , y.sector_unadj_duration_units
                  , ROUND((y.title_unadj_duration_units/y.sector_unadj_duration_units), 4) AS rolling_avg_weight
             FROM (
                    SELECT   x.std_country_id
                           , x.std_sector_id
                           , x.std_job_title_id
                           , x.title_unadj_duration_units
                           , SUM(x.title_unadj_duration_units) OVER (PARTITION BY x.std_sector_id) AS sector_unadj_duration_units
                      FROM (
                             SELECT   w.std_country_id
                                    , w.std_sector_id
                                    , w.std_job_title_id
                                    , SUM(w.unadj_duration_units) AS title_unadj_duration_units
                               FROM   TABLE(dm_index.get_month_keys(ADD_MONTHS(TO_DATE(TO_CHAR(p_month), 'YYYYMM'), -(c_rolling_months-1)), TO_DATE(TO_CHAR(p_month), 'YYYYMM'))) m
                                    , dm_sector_region_title_weights w
                              WHERE w.std_country_id = p_country
                                AND w.month_number = m.column_value
                                AND w.std_region_id <> 0
                                AND EXISTS (
                                             SELECT NULL
                                               FROM dm_sector_region_title_weights t
                                              WHERE t.std_country_id   = p_country
                                                AND t.month_number     = p_month
                                                AND t.std_region_id <> 0
                                                AND t.std_job_title_id = w.std_job_title_id
                                           )
                              GROUP BY w.std_country_id, w.std_sector_id, w.std_job_title_id
                           ) x
                  ) y;
    END get_nat_title_rolling_avgs;

    PROCEDURE update_nat_title_rolling_avgs
    (
        p_month   IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    )
    IS
    BEGIN
           MERGE INTO dm_sector_region_title_weights t
           USING (
           SELECT   y.std_country_id
                  , p_month AS month_number
                  , y.std_job_title_id
                  , 0 AS std_region_id
                  , y.std_sector_id
                  , y.title_unadj_duration_units
                  , y.sector_unadj_duration_units
                  , ROUND((y.title_unadj_duration_units/y.sector_unadj_duration_units), 4) AS rolling_avg_weight
             FROM (
                    SELECT   x.std_country_id
                           , x.std_sector_id
                           , x.std_job_title_id
                           , x.title_unadj_duration_units
                           , SUM(x.title_unadj_duration_units) OVER (PARTITION BY x.std_sector_id) AS sector_unadj_duration_units
                      FROM (
                             SELECT   w.std_country_id
                                    , w.std_sector_id
                                    , w.std_job_title_id
                                    , SUM(w.unadj_duration_units) AS title_unadj_duration_units
                               FROM   TABLE(dm_index.get_month_keys(ADD_MONTHS(TO_DATE(TO_CHAR(p_month), 'YYYYMM'), -(c_rolling_months-1)), TO_DATE(TO_CHAR(p_month), 'YYYYMM'))) m
                                    , dm_sector_region_title_weights w
                              WHERE w.std_country_id = p_country
                                AND w.month_number = m.column_value
                                AND w.std_region_id <> 0
                                AND EXISTS (
                                             SELECT NULL
                                               FROM dm_sector_region_title_weights t
                                              WHERE t.std_country_id   = p_country
                                                AND t.month_number     = p_month
                                                AND t.std_region_id <> 0
                                                AND t.std_job_title_id = w.std_job_title_id
                                           )
                              GROUP BY w.std_country_id, w.std_sector_id, w.std_job_title_id
                           ) x
                  ) y
                  ) s
              ON (
                       t.std_country_id   = s.std_country_id
                   AND t.month_number     = s.month_number
                   AND t.std_region_id    = s.std_region_id
                   AND t.std_sector_id    = s.std_sector_id
                   AND t.std_job_title_id = s.std_job_title_id
                 )
           WHEN MATCHED THEN UPDATE SET   t.title_unadj_duration_units  = s.title_unadj_duration_units
                                        , t.sector_unadj_duration_units = s.sector_unadj_duration_units
                                        , t.rolling_avg_weight          = s.rolling_avg_weight;
    END update_nat_title_rolling_avgs;

    PROCEDURE compute_title_buyer_weights
    IS
    BEGIN
          MERGE INTO dm_title_buyer_weights t2
          USING (
                  SELECT t.std_job_title_id, SUM(t.orig_unadj_volume) sum_vol_excl_heavy
                    FROM (
                           SELECT DISTINCT std_job_title_id
                             FROM dm_title_buyer_weights
                            WHERE heavy_weight = 'Y'
                         ) hv, dm_title_buyer_weights t
                   WHERE t.std_job_title_id = hv.std_job_title_id
                     AND t.heavy_weight = 'N'
                   GROUP BY t.std_job_title_id
                ) s
             ON (
                  t2.std_job_title_id = s.std_job_title_id
                )
           WHEN MATCHED THEN UPDATE SET t2.sum_vol_excl_heavy = s.sum_vol_excl_heavy;

          COMMIT;

          MERGE INTO dm_title_buyer_weights t2
          USING (
                  SELECT x.*, y.max_vol_excl_heavy, greatest(x.pct40, y.max_vol_excl_heavy) reduced_volume
                    FROM (
                           SELECT   std_job_title_id, data_source_code
                                  , std_buyerorg_id, sum_vol_excl_heavy*0.4 pct40
                             FROM dm_title_buyer_weights
                            WHERE heavy_weight = 'Y'
                         ) x,
                        (
                          SELECT t.std_job_title_id, MAX(t.orig_unadj_volume) max_vol_excl_heavy
                            FROM (
                                   SELECT DISTINCT std_job_title_id
                                     FROM dm_title_buyer_weights
                                    WHERE heavy_weight = 'Y'
                                 ) hv, dm_title_buyer_weights t
                           WHERE t.std_job_title_id = hv.std_job_title_id
                             AND t.heavy_weight = 'N'
                           GROUP BY t.std_job_title_id
                        ) y
                  WHERE y.std_job_title_id = x.std_job_title_id
                ) s3
             ON (
                      t2.std_job_title_id = s3.std_job_title_id
                  AND t2.std_buyerorg_id = s3.std_buyerorg_id
                  AND t2.data_source_code = s3.data_source_code
                )
           WHEN MATCHED THEN UPDATE SET t2.reduced_volume = s3.reduced_volume;

          COMMIT;

          MERGE INTO dm_title_buyer_weights t2
          USING (
                  SELECT   u.std_job_title_id
                         , u.std_buyerorg_id
                         , u.data_source_code
                         , x.sum_reduced_volume, ROUND(u.reduced_volume/x.sum_reduced_volume, 4) adj_weight
                    FROM (
                           SELECT t.std_job_title_id, SUM(t.reduced_volume) sum_reduced_volume
                             FROM (
                                    SELECT DISTINCT std_job_title_id
                                      FROM dm_title_buyer_weights
                                     WHERE heavy_weight = 'Y'
                                  ) hv, dm_title_buyer_weights t
                            WHERE t.std_job_title_id = hv.std_job_title_id
                            GROUP BY t.std_job_title_id
                         ) x, dm_title_buyer_weights u
                   WHERE u.std_job_title_id = x.std_job_title_id
                ) s3
             ON (
                      t2.std_job_title_id = s3.std_job_title_id
                  AND t2.std_buyerorg_id = s3.std_buyerorg_id
                  AND t2.data_source_code = s3.data_source_code
                )
           WHEN MATCHED THEN UPDATE SET   t2.sum_reduced_volume = s3.sum_reduced_volume
                                        , t2.adj_weight = s3.adj_weight;

          COMMIT;
    END compute_title_buyer_weights;

    PROCEDURE get_title_buyer_weights
    (
        p_month   IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    )
    IS
    BEGIN
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_title_buyer_weights';

          INSERT /*+ APPEND(t) */ INTO dm_title_buyer_weights t
          WITH filtered_list AS
          (
            SELECT /*+ MATERIALIZE */ l.std_job_title_id
              FROM (
                     SELECT   w.std_job_title_id
                            , COUNT(DISTINCT w.data_source_code || '-' || w.assignment_id)   AS assignment_count
                            , COUNT(DISTINCT w.data_source_code || '-' || w.std_buyerorg_id) AS buyer_count
                       FROM dm_weighted_rate_events w
                      WHERE w.std_country_id = p_country
                        AND w.month_type = 'I'
                        AND w.month_number = p_month
                      GROUP BY w.std_job_title_id
                   ) l
             WHERE l.buyer_count      >= 3
               AND l.assignment_count >= 30
          )
          SELECT   z.*
                 , CASE WHEN z.orig_weight > 0.4 THEN 'Y'
                        ELSE 'N'
                   END  AS heavy_weight
                 , z.orig_unadj_volume AS reduced_volume
                 , z.sum_orig_unadj_volume AS sum_vol_excl_heavy
                 , z.sum_orig_unadj_volume AS sum_reduced_volume
                 , z.orig_weight AS adj_weight
            FROM (
                   SELECT y.*, ROUND(y.orig_unadj_volume/y.sum_orig_unadj_volume, 4) orig_weight
                     FROM (
                            SELECT   x.*
                                   , SUM(x.orig_unadj_volume) OVER (PARTITION BY x.std_job_title_id) AS sum_orig_unadj_volume
                                   , SUM(x.orig_volume) OVER (PARTITION BY x.std_job_title_id) AS sum_orig_volume
                             FROM (
                                    SELECT   w.std_country_id
                                           , w.std_job_title_id
                                           , w.data_source_code
                                           , w.std_buyerorg_id
                                           , MIN(w.std_job_category_id) AS std_job_category_id
                                           , SUM(w.duration_units) AS orig_unadj_volume
                                           , SUM(w.duration_units*w.proximity_weight) AS orig_volume
                                           , ROUND(SUM(w.reg_bill_rate*w.duration_units)/
                                                   SUM(w.duration_units),2) AS sum_unadj_bill_rate
                                           , ROUND(SUM(w.reg_bill_rate*w.proximity_weight*w.duration_units)/
                                                   SUM(w.proximity_weight*w.duration_units),2) AS sum_bill_rate
                                      FROM dm_weighted_rate_events w, filtered_list fl
                                     WHERE w.std_country_id = p_country
                                       AND w.month_type = 'I'
                                       AND w.month_number = p_month
                                       AND fl.std_job_title_id = w.std_job_title_id
                                     GROUP BY w.std_country_id, w.std_job_title_id, w.data_source_code, w.std_buyerorg_id
                                  ) x
                          ) y
                 ) z;

          COMMIT;

          compute_title_buyer_weights;
    END get_title_buyer_weights;

    PROCEDURE get_hist_title_buyer_weights
    (
        p_month   IN NUMBER
      , p_country IN dm_iqn_index.std_country_id%TYPE DEFAULT 1
    )
    IS
    BEGIN
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_title_buyer_weights';

          INSERT /*+ APPEND(t) */ INTO dm_title_buyer_weights t
          WITH filtered_list AS
          (
            SELECT /*+ MATERIALIZE */ l.std_job_title_id
              FROM (
                     SELECT   w.std_job_title_id
                            , COUNT(DISTINCT w.data_source_code || '-' || w.assignment_id)   AS assignment_count
                            , COUNT(DISTINCT w.data_source_code || '-' || w.std_buyerorg_id) AS buyer_count
                       FROM dm_idx_wtd_rate_events w
                      WHERE w.std_country_id = p_country
                        AND w.month_number = p_month
                      GROUP BY w.std_job_title_id
                   ) l
             WHERE l.buyer_count      >= 3
               AND l.assignment_count >= 30
          )
          SELECT   z.*
                 , CASE WHEN z.orig_weight > 0.4 THEN 'Y'
                        ELSE 'N'
                   END  AS heavy_weight
                 , z.orig_unadj_volume AS reduced_volume
                 , z.sum_orig_unadj_volume AS sum_vol_excl_heavy
                 , z.sum_orig_unadj_volume AS sum_reduced_volume
                 , z.orig_weight AS adj_weight
            FROM (
                   SELECT y.*, ROUND(y.orig_unadj_volume/y.sum_orig_unadj_volume, 4) orig_weight
                     FROM (
                            SELECT   x.*
                                   , SUM(x.orig_unadj_volume) OVER (PARTITION BY x.std_job_title_id) AS sum_orig_unadj_volume
                                   , SUM(x.orig_volume) OVER (PARTITION BY x.std_job_title_id) AS sum_orig_volume
                             FROM (
                                    SELECT   w.std_country_id
                                           , w.std_job_title_id
                                           , w.data_source_code
                                           , w.std_buyerorg_id
                                           , MIN(w.std_job_category_id) AS std_job_category_id
                                           , SUM(w.duration_units) AS orig_unadj_volume
                                           , SUM(w.duration_units*w.proximity_weight) AS orig_volume
                                           , ROUND(SUM(w.reg_bill_rate*w.duration_units)/
                                                   SUM(w.duration_units),2) AS sum_unadj_bill_rate
                                           , ROUND(SUM(w.reg_bill_rate*w.proximity_weight*w.duration_units)/
                                                   SUM(w.proximity_weight*w.duration_units),2) AS sum_bill_rate
                                      FROM dm_idx_wtd_rate_events w, filtered_list fl
                                     WHERE w.std_country_id = p_country
                                       AND w.month_number = p_month
                                       AND fl.std_job_title_id = w.std_job_title_id
                                     GROUP BY w.std_country_id, w.std_job_title_id, w.data_source_code, w.std_buyerorg_id
                                  ) x
                          ) y
                 ) z;

          COMMIT;
          compute_title_buyer_weights;
    END get_hist_title_buyer_weights;
END dm_index;
/