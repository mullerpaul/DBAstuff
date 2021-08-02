CREATE OR REPLACE PACKAGE BODY dm_fotimecard_rate_event
AS
PROCEDURE extract_rate_events
(
    p_source_code IN VARCHAR2
  , p_from_date   IN VARCHAR2 -- YYYYMMDDHH24MISS
  , p_to_date     IN VARCHAR2 -- YYYYMMDDHH24MISS
  , p_start_date  IN VARCHAR2 -- YYYYMMDDHH24MISS
  , p_batch_id    IN NUMBER
)
IS
    v_link_name    VARCHAR2(16);
    v_sql          VARCHAR2(32767);
    v_rec_count    NUMBER;
BEGIN
    v_link_name := dm_rate_event.get_link_name(p_source_code);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_timecard_rate_events_tmp';
    v_sql :='
    INSERT /*+ APPEND(t) */ INTO fo_timecard_rate_events_tmp t
         (
             expenditure_date
           , batch_id
           , load_key
           , data_source_code
           , timecard_source
           , custom_address_country_id
           , assignment_type
           , buyerorg_id
           , supplierorg_id
           , assignment_id
           , job_id
           , rate_unit_type
           , rate_type
           , currency_description
           , rate_units
           , cumulative_bill_rate
           , job_title
           , assignment_edition_id
           , job_category_desc
           , job_level_desc
           , custom_address_city
           , custom_address_state
           , custom_address_postal_code
           , unparsed_custom_address
           , actual_end_date
           , buyerorg_name
           , supplierorg_name
         )
    SELECT /*+ DRIVING_SITE(ieo) */
             y.expenditure_date
           , ' || p_batch_id || '
           , ROWNUM
           , ''' || p_source_code || '''
           , ''FO''
           , pl.country
           , y.assignment_type
           , y.buyerorg_id
           , y.supplierorg_id
           , y.assignment_continuity_id
           , y.job_id
           , DECODE(y.rate_unit_fk, 0, ''Hourly'', 1, ''Daily'', 2, ''Annual'', 3, ''Monthly'', 4, ''Weekly'', ''N/A'')
           , DECODE(y.rate_identifier_fk,1,''ST'', 2,''OT'',3,''DT'',''CS:'' || ri.bo_expenditure_type)
           , cu.description
           , y.rate_units
           , ROUND(y.sum_cumulative_bill_rate/y.rate_units, 2)
           , UPPER(y.job_title)
           , assignment_edition_id
           , DECODE(jc.type, ''CUSTOM'', jc.description, get_java_constant_description@LNK(''JOB_CATEGORY'',jc.value))
           , DECODE(jc.type, ''CUSTOM'', jl.description, get_java_constant_description@LNK(''JOB_LEVEL'',jl.value))
           , UPPER(REPLACE(REPLACE(REPLACE(pl.city, ''- ''), '',''), '' -''))
           , REPLACE(pl.state, '' -'')
           , DECODE(pl.postal_code, ''x'', NULL, pl.postal_code)
           , get_java_constant_description@LNK(''PLACE'', pl.value)
           , y.actual_end_date
           , bob.name AS buyerorg_name
           , bos.name AS supplierorg_name
      FROM (
             SELECT   x.*
                    , ae.assignment_edition_id
                    , ae.job_title
                    , ae.resource_onsite_fk
                    , ae.job_level_fk
                    , ae.job_category_fk
                    , ae.actual_end_date
                    , ROW_NUMBER() OVER (PARTITION BY x.assignment_continuity_id, x.expenditure_date, x.rate_unit_fk, x.rate_identifier_fk, x.currency_unit_fk ORDER BY ae.assignment_edition_id DESC) AS rnk
               FROM (
                      SELECT   MAX(ieo.buyer_business_org_fk) AS buyerorg_id
                             , MAX(ieo.supplier_business_org_fk) AS supplierorg_id
                             , ac.assignment_continuity_id
                             , DECODE(MAX(ac.work_order_fk),NULL,''EA'',''WO'') AS assignment_type
                             , MAX(ac.job_fk) AS job_id
                             , ie.expenditure_date
                             , DECODE(iet.rate_unit_fk, 1, 0,iet.rate_unit_fk) rate_unit_fk
                             , ie.rate_identifier_fk
                             , ie.currency_unit_fk
                             , SUM(ie.quantity) AS rate_units
                             , SUM(DECODE(iet.rate_unit_fk, 1,iet.cumulative_bill_rate/8, iet.cumulative_bill_rate)*ie.quantity) AS sum_cumulative_bill_rate
                        FROM   invoiceable_expenditure_owner@LNK ieo
                             , invoiceable_expenditure@LNK ie
                             , invoiceable_expenditure_txn@LNK iet
                             , assignment_continuity@LNK ac
                       WHERE ieo.timecard_fk IS NOT NULL
                         AND ieo.custom_invoiceable_fk IS NULL
                         AND ie.invoiceable_exp_owner_fk = ieo.invoiceable_exp_owner_id
                         AND iet.reversing_expenditure_txn_fk IS NULL
                         AND iet.reversed_expenditure_txn_fk IS NULL
                         AND iet.invoiceable_expenditure_fk = ie.invoiceable_expenditure_id
                         AND iet.create_date >=  TO_DATE(''' || p_from_date || ''',''YYYYMMDDHH24MISS'')
                         AND iet.create_date  <  TO_DATE(''' || p_to_date   || ''',''YYYYMMDDHH24MISS'')
                         AND ie.expenditure_date >= ADD_MONTHS(TO_DATE(''' || p_start_date || ''',''YYYYMMDDHH24MISS''), -1) + 20
                         AND ac.assignment_continuity_id = ieo.assignment_continuity_fk
                       GROUP BY ac.assignment_continuity_id, ie.expenditure_date, DECODE(iet.rate_unit_fk, 1, 0,iet.rate_unit_fk), ie.rate_identifier_fk, ie.currency_unit_fk
                    ) x, assignment_edition@LNK ae
              WHERE x.rate_units <> 0
                AND x.sum_cumulative_bill_rate <> 0
                AND ae.assignment_continuity_fk = x.assignment_continuity_id
           ) y, rate_identifier@LNK ri, currency_unit@LNK cu
           , business_organization@LNK bob
           , business_organization@LNK bos
           , job_level@LNK jl
           , job_category@LNK jc
           , address@LNK adr
           , place@LNK pl
     WHERE y.rnk < 2
       AND bob.business_organization_id = y.buyerorg_id
       AND bos.business_organization_id = y.supplierorg_id
       AND ri.rate_identifier_id = y.rate_identifier_fk
       AND cu.value = y.currency_unit_fk
       AND jc.value (+) = y.job_category_fk
       AND jl.value(+) = y.job_level_fk
       AND adr.contact_info_fk(+) = y.resource_onsite_fk
       AND adr.address_type = ''P''
       AND pl.value(+) = adr.place_fk';

    v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
    --INSERT INTO pk_text (pk_text) VALUES (v_sql);
    EXECUTE IMMEDIATE v_sql;
    v_rec_count := SQL%ROWCOUNT;
    COMMIT;

    UPDATE fo_timecard_rate_events_tmp t
       SET t.job_title = REPLACE(REGEXP_REPLACE(t.job_title, c_regexp_rule), CHR(15712189));

    INSERT INTO dm_rate_event_stats
    (  data_source_code, batch_id, process_date, new_input_rate_events
     , reprocessed_from_quarantine, placed_in_quarantine, new_buyerorgs
     , new_supplierorgs, extract_timestamp_from, extract_timestamp_cutoff
    )
    VALUES
    (  p_source_code || '-T', p_batch_id, SYSDATE, v_rec_count
     , 0, 0, 0
     , 0, p_from_date, p_to_date
    );
    COMMIT;
END extract_rate_events;

PROCEDURE extract_all_rate_events
(
  v_resume_flag IN VARCHAR2
)
IS
    TYPE vcharTab IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
    vDataSourceList vcharTab;
    v_start_date DATE := TO_DATE('20080101000000', 'YYYYMMDDHH24MISS');
    v_prev_cutoff_date VARCHAR2(16);
    v_begin_date DATE;
    v_end_date   DATE;
    v_max_date   DATE;
    v_retry_count    PLS_INTEGER := 0;
    v_extract_count  PLS_INTEGER := 0;
BEGIN
    vDataSourceList(1) := 'WACHOVIA';
    vDataSourceList(2) := 'REGULAR';

    dm_rate_event.drop_job_indexes;
    IF (v_resume_flag = 'N')
       THEN
             --EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_timecard_rate_events';
             v_begin_date := TRUNC(ADD_MONTHS(v_start_date, -6), 'DAY')-1;
             v_prev_cutoff_date := TO_CHAR(v_begin_date, 'YYYYMMDDHH24MISS');
             BEGIN
                   UPDATE dm_cube_objects
                      SET last_identifier = v_prev_cutoff_date
                    WHERE object_name = 'TS_RATE_EVENT_ID';
             EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       BEGIN
                              FOR i IN vDataSourceList.FIRST .. vDataSourceList.LAST
                              LOOP
                                     INSERT INTO dm_cube_objects (object_name, object_source_code, last_update_date, last_identifier)
                                     VALUES ('TS_RATE_EVENT_ID', vDataSourceList(i), SYSDATE, TO_NUMBER(v_prev_cutoff_date));
                              END LOOP;
                       END;
             END;
       ELSE
             SELECT TO_DATE(MAX(last_identifier), 'YYYYMMDDHH24MISS')
               INTO v_begin_date
               FROM dm_cube_objects
              WHERE object_name = 'TS_RATE_EVENT_ID';
    END IF; -- Check for v_resume_flag

    v_max_date := TRUNC(SYSDATE, 'DAY')-1;
    WHILE (v_begin_date < v_max_date)
    LOOP
         v_end_date := v_begin_date+7; --ADD_MONTHS(v_begin_date, 1)
         FOR i IN vDataSourceList.FIRST .. vDataSourceList.LAST
         LOOP
              v_retry_count   := 0;
              v_extract_count := 0;
              WHILE (v_retry_count < 4 AND v_extract_count < 1)
              LOOP
                BEGIN
                      process_batch(vDataSourceList(i), TO_CHAR(v_end_date, 'YYYYMMDDHH24MISS'), TO_CHAR(v_start_date, 'YYYYMMDDHH24MISS'), 'Y');
                      DBMS_OUTPUT.PUT_LINE('For ' || vDataSourceList(i) || ': ' || v_begin_date || '==>' || v_end_date);
                      v_extract_count := 1;
                EXCEPTION
                   WHEN OTHERS THEN
                      IF (SQLCODE = -30926)
                         THEN
                              v_retry_count := v_retry_count + 1;
                              DBMS_LOCK.SLEEP(120);
                         ELSE
                              RAISE;
                      END IF;
                END;
              END LOOP;
              IF (v_extract_count = 0)
                 THEN
                      DBMS_OUTPUT.PUT_LINE('Unable to extract data after max retries due to ORA-30926: unable to get a stable set of rows in the source tables, Ignoring');
              END IF;
         END LOOP;
         v_begin_date := v_end_date;
    END LOOP;
    dm_rate_event.create_job_indexes;
END extract_all_rate_events;

PROCEDURE add_new_buyerorgs
(
    p_source_code IN VARCHAR2
  , p_batch_id      IN NUMBER
)
IS
       v_rec_count         PLS_INTEGER;
       email_subject       VARCHAR2(64)  := 'DM - Missing Buyerorgs Added';
BEGIN
       INSERT INTO fo_buyers_map
            (
                apex_id
              , data_source_code
              , buyerorg_id
              , std_buyerorg_id
              , is_test_org
              , last_update_date
              , rate_source_pref
            )
       SELECT fo_buyers_map_id.NEXTVAL AS apex_id
              , p_source_code AS data_source_code
              , x.buyerorg_id
              , 0 AS std_buyerorg_id
              , 'N' AS is_test_org
              , SYSDATE AS last_update_date
              , 'FO Contract' AS rate_source_pref
         FROM (
                SELECT DISTINCT buyerorg_id
                  FROM fo_timecard_rate_events_tmp t
                 WHERE NOT EXISTS (
                                    SELECT NULL
                                      FROM fo_buyers_map m
                                     WHERE m.buyerorg_id = t.buyerorg_id
                                  )
              ) x;

       v_rec_count := SQL%ROWCOUNT;

       UPDATE dm_rate_event_stats
          SET new_buyerorgs = v_rec_count
        WHERE data_source_code = p_source_code || '-T'
          AND batch_id = p_batch_id;

       IF (v_rec_count > 0)
          THEN
                dm_utils.send_email(c_email_sender, c_email_recipients, email_subject, 'Please NOTE that ' || v_rec_count || ' missing buyerorgs for ' || p_source_code || ' have been added to FO_BUYERS_MAP. Update the mapping at your earliest convenience.' || c_crlf);
       END IF;
END add_new_buyerorgs;

PROCEDURE add_new_supplierorgs
(
    p_source_code IN VARCHAR2
  , p_batch_id      IN NUMBER
)
IS
       v_rec_count         PLS_INTEGER;
       email_subject       VARCHAR2(64)  := 'DM - Missing Supplierorgs Added';
BEGIN
       INSERT INTO fo_suppliers_map
            (
                apex_id
              , data_source_code
              , supplierorg_id
              , std_supplierorg_id
              , last_update_date
            )
       SELECT   fo_suppliers_map_id.NEXTVAL AS apex_id
              , p_source_code AS data_source_code
              , x.supplierorg_id
              , 0 AS std_supplierorg_id
              , SYSDATE AS last_update_date
         FROM (
                SELECT DISTINCT supplierorg_id
                  FROM (
                         SELECT DISTINCT buyerorg_id, supplierorg_id
                           FROM fo_timecard_rate_events_tmp t
                          WHERE NOT EXISTS (
                                             SELECT NULL
                                               FROM fo_suppliers_map sm
                                              WHERE sm.supplierorg_id = t.supplierorg_id
                                           )
                            AND NOT EXISTS (
                                             SELECT NULL
                                               FROM fo_buyers_map bm
                                              WHERE bm.buyerorg_id = t.buyerorg_id
                                                AND bm.is_test_org = 'Y'
                                           )
                       ) y
              ) x;

       v_rec_count := SQL%ROWCOUNT;

       UPDATE dm_rate_event_stats
          SET new_supplierorgs = v_rec_count
        WHERE data_source_code = p_source_code || '-T'
          AND batch_id = p_batch_id;

       IF (v_rec_count > 0)
          THEN
                dm_utils.send_email(c_email_sender, c_email_recipients, email_subject, 'Please NOTE that ' || v_rec_count || ' missing supplierorgs for ' || p_source_code || ' have been added to FO_SUPPLIERS_MAP. Update the mapping at your earliest convenience.' || c_crlf);
       END IF;
END add_new_supplierorgs;

FUNCTION get_transformed_events
(
  p_batch_id        IN NUMBER
)
RETURN eventTab
PIPELINED
AS
  CURSOR c1 IS
    SELECT   t9.*
           , CASE WHEN TO_NUMBER(TO_CHAR(t9.expenditure_date, 'DD')) < 15 THEN TO_NUMBER(TO_CHAR(ADD_MONTHS(t9.expenditure_date, 1), 'YYYYMM')) 
                  ELSE TO_NUMBER(TO_CHAR(ADD_MONTHS(t9.expenditure_date, 2), 'YYYYMM')) END index_month
           , TO_NUMBER(TO_CHAR(t9.expenditure_date, 'YYYYMM')) calendar_month
      FROM (
             SELECT   dp2.std_place_id p2_std_place_id, dp2.cmsa_code p2_cmsa_code
                    , t8.*
                    -- In case of multiple location matches give least preference to non-metro CMSA
                    , ROW_NUMBER() OVER (PARTITION BY t8.batch_id, t8.load_key ORDER BY INSTR(dp2.cmsa_code, '9999') ASC) AS rnk2
               FROM (
                      SELECT   dp.std_place_id p1_std_place_id, dp.cmsa_code p1_cmsa_code
                             , t7.*
                             -- In case of multiple location matches give preference to the MSA that belongs to the same state
                             , ROW_NUMBER() OVER (PARTITION BY t7.batch_id, t7.load_key ORDER BY INSTR(dp.cmsa_code, t7.custom_address_state) DESC) AS rnk1
                        FROM (
                               SELECT   NVL(o4.std_job_title_id, 0)    AS o4_std_job_title_id
                                      , NVL(o4.std_place_id, 0)        AS o4_std_place_id
                                      , t6.*
                                 FROM (
                                        SELECT   NVL(o3.std_job_title_id, 0)    AS o3_std_job_title_id
                                               , NVL(o3.std_place_id, 0)        AS o3_std_place_id
                                               , t5.*
                                          FROM (
                                                 SELECT   NVL(o2.std_job_title_id, 0)    AS o2_std_job_title_id
                                                        , NVL(o2.std_place_id, 0)        AS o2_std_place_id
                                                        , t4.*
                                                   FROM (
                                                          SELECT   NVL(o1.std_job_title_id, 0)    AS o1_std_job_title_id
                                                                 , NVL(o1.std_place_id, 0)        AS o1_std_place_id
                                                                 , t3.*
                                                            FROM (
                                                                   SELECT   NVL(sm.std_supplierorg_id, 0) AS std_supplierorg_id
                                                                          , NVL(bm.std_buyerorg_id, 0)    AS std_buyerorg_id
                                                                          , dm_rate_event.clean_state(t.custom_address_country_id, t.custom_address_state) AS cln_state
                                                                          , dm_rate_event.clean_city(t.custom_address_city, t.custom_address_country_id, t.custom_address_state) AS cln_city
                                                                          , t.*
                                                                     FROM   fo_timecard_rate_events_tmp t
                                                                          , fo_suppliers_map sm
                                                                          , fo_buyers_map bm
                                                                    WHERE sm.supplierorg_id   (+) = t.supplierorg_id
                                                                      AND sm.data_source_code (+) = t.data_source_code
                                                                      AND bm.buyerorg_id      (+) = t.buyerorg_id
                                                                      AND bm.data_source_code (+) = t.data_source_code
                                                                      AND bm.is_test_org = 'N'
                                                                 ) t3, dm_buyer_job_overrides o1
                                                           WHERE o1.job_id           (+) = 0
                                                             AND o1.assignment_id    (+) = t3.assignment_id
                                                             AND o1.data_source_code (+) = t3.data_source_code
                                                        ) t4, dm_buyer_job_overrides o2
                                                  WHERE o2.job_id           (+) = t4.job_id
                                                    AND o2.assignment_id    (+) = 0
                                                    AND o2.data_source_code (+) = t4.data_source_code
                                               ) t5, dm_buyer_job_overrides o3
                                         WHERE o3.std_buyerorg_id  (+) = t5.std_buyerorg_id
                                           AND o3.job_title        (+) = t5.job_title
                                           -- For Buyer title overrides input data source does not matter as buyer is always from one source
                                      ) t6, dm_buyer_job_overrides o4
                                WHERE o4.std_buyerorg_id  (+) = 0
                                  AND o4.job_title        (+) = t6.job_title
                                  -- For generic title overrides input data source does not matter
                             ) t7, dm_places dp
                       WHERE dp.std_country_id  (+) = t7.custom_address_country_id
                         AND dp.std_postal_code (+) = DECODE(t7.custom_address_country_id, 1, SUBSTR(t7.custom_address_postal_code, 1, 5), t7.custom_address_postal_code)
                         AND dp.cmsa_code       (+)   IS NOT NULL
                    ) t8, dm_places dp2
              WHERE t8.rnk1 < 2
                AND dp2.std_country_id  (+) = t8.custom_address_country_id
                AND dp2.std_state       (+) = t8.cln_state
                AND dp2.std_city        (+) = t8.cln_city
                AND dp2.cmsa_code       (+)   IS NOT NULL
           ) t9
     WHERE t9.rnk2 < 2;

      CURSOR c_countries IS
             SELECT c.iso_country_name, c.std_country_id, p.std_place_id, c2.country_dim_id
               FROM dm_countries c, dm_places p, dm_country_dim c2
              WHERE c.iso_country_name IN ('Canada', 'Netherlands', 'United Kingdom', 'India')
                AND p.std_country_id = c.std_country_id
                AND c2.iso_country_name = UPPER(c.iso_country_name);

   TYPE inpEventTab IS TABLE OF c1%ROWTYPE INDEX BY PLS_INTEGER;
   vInpRecs inpEventTab;
   vOutRec  dm_timecard_rate_events%ROWTYPE;

   v_uk_place_id         dm_places.std_place_id%TYPE                     := 0;
   v_ca_place_id         dm_places.std_place_id%TYPE                     := 0;
   v_nl_place_id         dm_places.std_place_id%TYPE                     := 0;
   v_in_place_id         dm_places.std_place_id%TYPE                     := 0;
   v_effective_rate      dm_timecard_rate_events.cumulative_bill_rate%TYPE;
   v_reason_cd           dm_timecard_rate_events.transform_reason_codes%TYPE;
   v_ovr_country_id      dm_places.std_country_id%TYPE                   := 0;

   v_wac_country_id      dm_timecard_rate_events.custom_address_country_id%TYPE;
   v_wac_postal_code     dm_timecard_rate_events.custom_address_postal_code%TYPE;
   v_wac_state           dm_timecard_rate_events.custom_address_state%TYPE;
   v_wac_city            dm_timecard_rate_events.custom_address_city%TYPE;

   v_piped_count PLS_INTEGER;
BEGIN
  FOR cntry_rec IN c_countries
  LOOP
       CASE (cntry_rec.iso_country_name)
              WHEN 'Canada'          THEN v_ca_place_id   := cntry_rec.std_place_id;
                                          c_ca_country_id := cntry_rec.std_country_id;
                                          c_ca_dim_id     := cntry_rec.country_dim_id;
              WHEN 'Netherlands'     THEN v_nl_place_id   := cntry_rec.std_place_id;
                                          c_nl_country_id := cntry_rec.std_country_id;
                                          c_nl_dim_id     := cntry_rec.country_dim_id;
              WHEN 'United Kingdom'  THEN v_uk_place_id   := cntry_rec.std_place_id;
                                          c_uk_country_id := cntry_rec.std_country_id;
                                          c_uk_dim_id     := cntry_rec.country_dim_id;
              WHEN 'India'           THEN v_in_place_id   := cntry_rec.std_place_id;
                                          c_in_country_id := cntry_rec.std_country_id;
                                          c_in_dim_id     := cntry_rec.country_dim_id;
       END CASE;
  END LOOP;

  OPEN c1;
  LOOP
       FETCH c1 BULK COLLECT INTO vInpRecs LIMIT 50000;
       --DBMS_OUTPUT.PUT_LINE('New Batch : vInpRecs.COUNT = '|| vInpRecs.COUNT);
       v_piped_count := 0;
       FOR i IN 1 .. vInpRecs.COUNT
       LOOP
            v_reason_cd              := NULL;

            vOutRec.timecard_source            := vInpRecs(i).timecard_source; --p_timecard_source;
            vOutRec.expenditure_date           := vInpRecs(i).expenditure_date;
            vOutRec.batch_id                   := vInpRecs(i).batch_id;
            vOutRec.load_key                   := vInpRecs(i).load_key;
            vOutRec.data_source_code           := vInpRecs(i).data_source_code;
            vOutRec.custom_address_country_id  := vInpRecs(i).custom_address_country_id;
            vOutRec.assignment_type            := vInpRecs(i).assignment_type;
            vOutRec.buyerorg_id                := vInpRecs(i).buyerorg_id;
            vOutRec.supplierorg_id             := vInpRecs(i).supplierorg_id;
            vOutRec.assignment_id              := vInpRecs(i).assignment_id;
            vOutRec.job_id                     := vInpRecs(i).job_id;
            vOutRec.rate_unit_type             := vInpRecs(i).rate_unit_type;
            vOutRec.rate_type                  := vInpRecs(i).rate_type;
            vOutRec.currency_description       := vInpRecs(i).currency_description;
            vOutRec.rate_units                 := vInpRecs(i).rate_units;
            vOutRec.cumulative_bill_rate       := vInpRecs(i).cumulative_bill_rate;
            vOutRec.job_title                  := vInpRecs(i).job_title;
            vOutRec.assignment_edition_id      := vInpRecs(i).assignment_edition_id;
            vOutRec.job_category_desc          := vInpRecs(i).job_category_desc;
            vOutRec.job_level_desc             := vInpRecs(i).job_level_desc;
            vOutRec.custom_address_city        := vInpRecs(i).custom_address_city;
            vOutRec.custom_address_state       := vInpRecs(i).custom_address_state;
            vOutRec.custom_address_postal_code := vInpRecs(i).custom_address_postal_code;
            vOutRec.unparsed_custom_address    := vInpRecs(i).unparsed_custom_address;
            vOutRec.index_month                := vInpRecs(i).index_month;
            vOutRec.calendar_month             := vInpRecs(i).calendar_month;
            vOutRec.std_buyerorg_id            := vInpRecs(i).std_buyerorg_id;
            vOutRec.geo_dim_id                 := 0;
            vOutRec.std_supplierorg_id         := vInpRecs(i).std_supplierorg_id;
            vOutRec.std_job_title_id           := 0;
            vOutRec.std_place_id               := 0;
            vOutRec.last_update_date           := SYSDATE;
            vOutRec.actual_end_date            := vInpRecs(i).actual_end_date;
            vOutRec.buyerorg_name              := vInpRecs(i).buyerorg_name;
            vOutRec.supplierorg_name           := vInpRecs(i).supplierorg_name;

            vOutRec.delete_reason_code := 'N';
            CASE (vInpRecs(i).currency_description)
              WHEN 'USD'  THEN IF (vInpRecs(i).custom_address_country_id = 1 OR vInpRecs(i).custom_address_country_id IS NULL)
                                  THEN
                                        dm_rate_event.verify_us(vInpRecs(i).custom_address_state, vInpRecs(i).unparsed_custom_address, vInpRecs(i).supplierorg_name, vInpRecs(i).job_title, vInpRecs(i).buyerorg_name, vOutRec.std_country_id);
                                        IF (vOutRec.std_country_id = 0)
                                           THEN
                                                vOutRec.delete_reason_code := 'F';
                                           ELSE
                                                vOutRec.std_country_id := c_us_country_id;
                                        END IF;
                                  ELSE
                                        vOutRec.std_country_id := 0;
                                        vOutRec.delete_reason_code := 'F';
                               END IF;
              WHEN 'GBP'  THEN 
                               dm_rate_event.verify_uk(vInpRecs(i).custom_address_state, vInpRecs(i).unparsed_custom_address, vInpRecs(i).supplierorg_name, vInpRecs(i).job_title, vInpRecs(i).buyerorg_name, vOutRec.std_country_id);
                               IF (vOutRec.std_country_id = 0)
                                  THEN
                                       vOutRec.delete_reason_code := 'F';
                                  ELSE vOutRec.std_place_id   := v_uk_place_id;
                                       vOutRec.std_country_id := c_uk_country_id;
                               END IF;
              WHEN 'EUR'  THEN
								IF vInpRecs(i).custom_address_country_id = c_nl_country_id
									THEN 
										vOutRec.delete_reason_code := 'N';
										vOutRec.std_country_id := c_nl_country_id;
								ELSE
										vOutRec.delete_reason_code := 'F';
										vOutRec.std_country_id := 0;
								END IF;
			                  
			  
			  ELSE             vOutRec.delete_reason_code := 'F';
                               vOutRec.std_country_id := 0;
            END CASE;

            IF (vOutRec.delete_reason_code = 'N' AND (vInpRecs(i).expenditure_date < c_start_date OR vInpRecs(i).expenditure_date > ADD_MONTHS(SYSDATE, 60)))
               THEN
                     vOutRec.delete_reason_code := 'D';
            END IF;

            IF (vOutRec.delete_reason_code = 'N' AND (vInpRecs(i).job_title LIKE '%SALES%TAX%' OR (vInpRecs(i).data_source_code = 'REGULAR' AND vInpRecs(i).buyerorg_id = 16347 AND vInpRecs(i).job_title = 'PRINT SERVICES')))
               THEN
                     vOutRec.delete_reason_code := 'T';
            END IF;

            IF (vOutRec.delete_reason_code = 'N')
               THEN
                     CASE (vInpRecs(i).rate_unit_type)
                          WHEN 'Weekly'  THEN v_effective_rate := vInpRecs(i).cumulative_bill_rate/c_weekly_hours;
                          WHEN 'Daily'   THEN v_effective_rate := vInpRecs(i).cumulative_bill_rate/c_daily_hours;
                          WHEN 'Monthly' THEN v_effective_rate := vInpRecs(i).cumulative_bill_rate/c_monthly_hours;
                          WHEN 'Annual'  THEN v_effective_rate := vInpRecs(i).cumulative_bill_rate/c_annual_hours;
                          ELSE                v_effective_rate := vInpRecs(i).cumulative_bill_rate;
                     END CASE;
                     IF (v_effective_rate <= 0)
                        THEN
                              vOutRec.delete_reason_code := 'B';
                        ELSE
                              CASE (vOutRec.std_country_id)
                                WHEN c_us_country_id THEN
                                     IF (v_effective_rate < c_us_min_rate OR v_effective_rate > c_us_max_rate)
                                        THEN
                                             vOutRec.delete_reason_code := 'B';
                                     END IF;
                                WHEN c_uk_country_id THEN
                                     IF (v_effective_rate < c_uk_min_rate OR v_effective_rate > c_uk_max_rate)
                                        THEN
                                             vOutRec.delete_reason_code := 'B';
                                     END IF;
                                WHEN c_nl_country_id  THEN
                                     IF (v_effective_rate < c_nl_min_rate OR v_effective_rate > c_nl_max_rate)
                                        THEN
                                             vOutRec.delete_reason_code := 'B';
                                     END IF;
                                WHEN c_ca_country_id  THEN
                                     IF (v_effective_rate < c_ca_min_rate OR v_effective_rate > c_ca_max_rate)
                                        THEN
                                             vOutRec.delete_reason_code := 'B';
                                     END IF;
                                WHEN c_in_country_id  THEN
                                     IF (v_effective_rate < c_in_min_rate OR v_effective_rate > c_in_max_rate)
                                        THEN
                                             vOutRec.delete_reason_code := 'B';
                                     END IF;
                                ELSE          IF (v_effective_rate < 0)
                                                 THEN
                                                       vOutRec.delete_reason_code := 'B';
                                              END IF;
                              END CASE;
                     END IF;
                     vInpRecs(i).cumulative_bill_rate := v_effective_rate;
            END IF;

            /*
            ** Any further transformations are performed
            ** Only on records that are NOT already "invalidated or marked for logical deletion"
            */
            IF (vOutRec.delete_reason_code = 'N')
               THEN
                     /*
                     ** Check if there are any JOB ID and Assignment ID specific overrides
                     */
                     IF (vInpRecs(i).o1_std_job_title_id > 0)
                        THEN
                              v_reason_cd := 'ASO'; -- Assignment Specific override
                              vOutRec.std_job_title_id := vInpRecs(i).o1_std_job_title_id;
                              IF (vInpRecs(i).o1_std_place_id > 0)
                                 THEN
                                      vOutRec.std_place_id := vInpRecs(i).o1_std_place_id;
                              END IF;
                     END IF;
         
                     /*
                     ** Check if there are any JOB ID specific overrides
                     */
                     IF (vOutRec.std_job_title_id = 0 AND vInpRecs(i).o2_std_job_title_id > 0)
                        THEN
                              v_reason_cd := 'JSO'; -- Job Specific override
                              vOutRec.std_job_title_id := vInpRecs(i).o2_std_job_title_id;
                              IF (vInpRecs(i).o2_std_place_id > 0)
                                 THEN
                                      vOutRec.std_place_id := vInpRecs(i).o2_std_place_id;
                              END IF;
                     END IF;
         
                     /*
                     ** Check if there are any Buyer Org and Title specific overrides
                     */
                     IF (vOutRec.std_job_title_id = 0 AND vInpRecs(i).o3_std_job_title_id > 0)
                        THEN
                              v_reason_cd := 'BTO'; -- Buyer Org Title specific override
                              vOutRec.std_job_title_id := vInpRecs(i).o3_std_job_title_id;
                              IF (vInpRecs(i).o3_std_place_id > 0)
                                 THEN
                                      vOutRec.std_place_id := vInpRecs(i).o3_std_place_id;
                              END IF;
                     END IF;
         
                     /*
                     ** Check if there are any Generic Title level mapping/override
                     */
                     IF (vOutRec.std_job_title_id = 0 AND vInpRecs(i).o4_std_job_title_id > 0)
                        THEN
                              v_reason_cd := 'GTL'; -- Generic Title level mapping
                              vOutRec.std_job_title_id := vInpRecs(i).o4_std_job_title_id;
                              -- Can't override place in Generic Title Override
                              -- so ingore place
                     END IF;
         
                     IF (vOutRec.std_place_id = 0)
                        THEN
                             CASE (vOutRec.std_country_id)
                                WHEN c_uk_country_id THEN vOutRec.std_place_id := v_uk_place_id;
                                WHEN c_nl_country_id THEN vOutRec.std_place_id := v_nl_place_id;
                                WHEN c_ca_country_id THEN vOutRec.std_place_id := v_ca_place_id;
                                WHEN c_in_country_id THEN vOutRec.std_place_id := v_in_place_id;
                                ELSE  IF (vInpRecs(i).p1_std_place_id IS NOT NULL)
                                         THEN
                                              v_reason_cd    := v_reason_cd || ',CPZ';
                                              vOutRec.std_place_id := vInpRecs(i).p1_std_place_id;
                                         ELSE 
                                              IF (vInpRecs(i).p2_std_place_id > 0)
                                                 THEN
                                                      IF (vInpRecs(i).cln_city != vInpRecs(i).custom_address_city)
                                                         THEN
                                                               -- Applied City/State Hygiene
                                                               v_reason_cd    := v_reason_cd || ',SCC';
                                                         ELSE
                                                               v_reason_cd    := v_reason_cd || ',SPC';
                                                      END IF;
                                                      vOutRec.std_place_id := vInpRecs(i).p2_std_place_id;
                                                 ELSE
                                                      IF (vInpRecs(i).custom_address_state IS NOT NULL AND vInpRecs(i).custom_address_city IS NOT NULL)
                                                         THEN
                                                              -- Custom place that didn't match by Postal code
                                                              -- So try using State and City
                                                              BEGIN
                                                                    SELECT dp2.std_place_id
                                                                      INTO vOutRec.std_place_id
                                                                      FROM (
                                                                             SELECT dp.std_place_id
                                                                                    -- In case of multiple location matches give least preference to non-metro CMSA
                                                                                    , ROW_NUMBER() OVER (ORDER BY INSTR(dp.cmsa_code, '9999') ASC) AS rnk 
                                                                               FROM dm_places dp 
                                                                              WHERE dp.std_country_id  = vInpRecs(i).custom_address_country_id
                                                                                AND dp.std_state       = dm_rate_event.clean_state(vInpRecs(i).custom_address_country_id, vInpRecs(i).custom_address_state)
                                                                                AND dp.std_city        = dm_rate_event.clean_city(vInpRecs(i).custom_address_city, vInpRecs(i).custom_address_country_id, vInpRecs(i).custom_address_state)
                                                                                AND dp.cmsa_code IS NOT NULL
                                                                           ) dp2
                                                                     WHERE dp2.rnk < 2;
                 
                                                                    v_reason_cd := v_reason_cd || ',CPC';
                                                              EXCEPTION
                                                                  WHEN NO_DATA_FOUND THEN NULL;
                                                              END;
                                                         ELSE
                                                              IF (vInpRecs(i).unparsed_custom_address IS NOT NULL)
                                                                 THEN
                                                                       -- DBMS_OUTPUT.PUT_LINE('Trying apply Custom parsing for <' || vInpRecs(i).unparsed_custom_address || '>');
                                                                       /*
                                                                       ** Apply Special Hygiene
                                                                       ** for the benefit of Wachovia and Standard US Style Addresses
                                                                       ** to extract State, City and Postal Code information from
                                                                       ** unparsed custom address
                                                                       */
                                                                       IF (vInpRecs(i).custom_address_country_id IS NULL)
                                                                          THEN
                                                                               v_wac_country_id := 1; -- Country is defaulted to US
                                                                       END IF;
                                                                       v_wac_postal_code := dm_rate_event.wac_zip(vInpRecs(i).unparsed_custom_address);
                                                                       v_wac_state := dm_rate_event.wac_state(vInpRecs(i).unparsed_custom_address);
                                                                       -- DBMS_OUTPUT.PUT_LINE('v_wac_postal_code <' || v_wac_postal_code || '>');
                                                                       IF (v_wac_postal_code IS NOT NULL)
                                                                          THEN
                                                                               BEGIN
                                                                                     SELECT dp2.std_place_id
                                                                                       INTO vOutRec.std_place_id
                                                                                       FROM (
                                                                                              SELECT dp.std_place_id
                                                                                                     -- In case of multiple location matches give preference to the MSA that belong to same state
                                                                                                     , ROW_NUMBER() OVER (ORDER BY INSTR(dp.cmsa_code, v_wac_state) DESC) AS rnk 
                                                                                                FROM dm_places dp 
                                                                                               WHERE dp.std_country_id  = v_wac_country_id
                                                                                                 AND dp.std_postal_code = v_wac_postal_code
                                                                                                 AND dp.cmsa_code IS NOT NULL
                                                                                            ) dp2
                                                                                      WHERE dp2.rnk < 2;
                          
                                                                                     v_reason_cd := v_reason_cd || ',WUZ';
                                                                               EXCEPTION
                                                                                   WHEN NO_DATA_FOUND THEN vOutRec.std_place_id := 0;
                                                                               END;
                                                                       END IF;
                          
                                                                       IF (vOutRec.std_place_id = 0)
                                                                          THEN
                                                                                v_wac_city  := UPPER(dm_rate_event.wac_city(vInpRecs(i).unparsed_custom_address));
                                                                                IF (v_wac_state IS NOT NULL AND v_wac_city IS NOT NULL)
                                                                                   THEN
                                                                                         -- Wachovia Unaparsed Address didn't match by Postal code
                                                                                         -- So try using extracted state and City
                                                                                         -- Country is defaulted to US
                                                                                         BEGIN
                                                                                               SELECT dp2.std_place_id
                                                                                                 INTO vOutRec.std_place_id
                                                                                                 FROM (
                                                                                                        SELECT dp.std_place_id
                                                                                                               -- In case of multiple location matches give least preference to non-metro CMSA
                                                                                                               , ROW_NUMBER() OVER (ORDER BY INSTR(dp.cmsa_code, '9999') ASC) AS rnk 
                                                                                                          FROM dm_places dp 
                                                                                                         WHERE dp.std_country_id  = v_wac_country_id
                                                                                                           AND dp.std_state       = dm_rate_event.clean_state(v_wac_country_id, v_wac_state)
                                                                                                           AND dp.std_city        = dm_rate_event.clean_city(v_wac_city, v_wac_country_id, v_wac_state)
                                                                                                           AND dp.cmsa_code IS NOT NULL
                                                                                                      ) dp2
                                                                                                WHERE dp2.rnk < 2;
                          
                                                                                               v_reason_cd := v_reason_cd || ',WUC';
                                                                                         EXCEPTION
                                                                                             WHEN NO_DATA_FOUND THEN vOutRec.std_place_id := 0;
                                                                                         END;
                                                                                END IF;
                                                                       END IF;
                                                              END IF; -- Parsing from unparsed custom address
                                                      END IF; -- Both custom_address_state and custom_address_city NOT NULL
                                              END IF; -- City State Hyigene
                                      END IF; -- Match by custom zip
                             END CASE; -- All IQNDex Countries
                        ELSE -- Place Override Used
                             BEGIN
                                   -- Get Country info for override location
                                   SELECT p.std_country_id
                                     INTO v_ovr_country_id
                                     FROM dm_places p
                                    WHERE p.std_place_id = vOutRec.std_place_id
                                      AND p.std_country_id > 0;

                                   IF (v_ovr_country_id != vOutRec.std_country_id)
                                      THEN
                                           vOutRec.std_country_id := v_ovr_country_id;

                                           CASE (v_ovr_country_id)
                                             WHEN c_us_country_id THEN NULL;
                                             WHEN c_uk_country_id THEN NULL;
                                             WHEN c_nl_country_id THEN NULL;
                                             WHEN c_ca_country_id THEN NULL;
                                             WHEN c_in_country_id THEN NULL;
                                             ELSE 
                                                  -- Override country ID
                                                  -- is Not from IQNDex country list
                                                  IF (vOutRec.delete_reason_code = 'N')
                                                     THEN
                                                          vOutRec.delete_reason_code := 'F';
                                                  END IF;
                                           END CASE;
                                   END IF;
                             EXCEPTION
                                 WHEN NO_DATA_FOUND THEN NULL;
                             END;
                     END IF; -- Place Override Check
            END IF; -- Logical delete Check

            vOutRec.transform_reason_codes     := v_reason_cd;
            PIPE ROW(vOutRec);
            v_piped_count := v_piped_count + 1;
       END LOOP;
       --DBMS_OUTPUT.PUT_LINE('New Batch : Piped Out = '|| v_piped_count);
       EXIT WHEN c1%NOTFOUND;
  END LOOP;
  CLOSE c1;
END get_transformed_events;

PROCEDURE process_batch
(
    p_source_code IN VARCHAR2
  , p_cutoff_date IN VARCHAR2 -- YYYYMMDDHH24MISS
  , p_start_date  IN VARCHAR2 -- YYYYMMDDHH24MISS
  , p_skip_maint  IN VARCHAR2
)
IS
       v_cutoff_date       VARCHAR2(16);
       v_prev_cutoff_date  VARCHAR2(16);
       v_max_key           NUMBER;
       v_batch_id          NUMBER;
       v_link_name         VARCHAR2(16);
       v_reprocessed_count NUMBER := 0;
       v_retry_count       PLS_INTEGER := 0;
       v_extract_count     PLS_INTEGER := 0;
       v_rec_count PLS_INTEGER;
BEGIN
       v_link_name := dm_rate_event.get_link_name(p_source_code);

       BEGIN
             SELECT TO_CHAR(last_identifier)
               INTO v_prev_cutoff_date
               FROM dm_cube_objects
              WHERE object_name = 'TS_RATE_EVENT_ID'
                AND object_source_code = p_source_code
                AND ROWNUM = 1;
       EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 BEGIN
                        v_prev_cutoff_date := p_start_date;
                        INSERT INTO dm_cube_objects (object_name, object_source_code, last_update_date, last_identifier)
                               VALUES ('TS_RATE_EVENT_ID', p_source_code, SYSDATE, TO_NUMBER(v_prev_cutoff_date));
                 END;
       END;

       IF (p_cutoff_date IS NULL)
          THEN
               v_cutoff_date := TO_CHAR(SYSDATE-0.291667, 'YYYYMMDDHH24MISS'); -- Current time - 7 hours
          ELSE
               v_cutoff_date := p_cutoff_date;
       END IF;

       --
       -- Get the sequence required for logging messages
       --
       SELECT dm_msg_log_seq.NEXTVAL INTO v_batch_id FROM DUAL;

       extract_rate_events(p_source_code, v_prev_cutoff_date, v_cutoff_date, p_start_date, v_batch_id);

       SELECT NVL(MAX(load_key), 0)
         INTO v_max_key
         FROM fo_timecard_rate_events_tmp;

       --DBMS_OUTPUT.PUT_LINE('v_max_key = ' || v_max_key);
       IF (v_max_key > 0)
          THEN
                IF (p_skip_maint = 'N')
                   THEN
                         move_quarantine(p_source_code, v_batch_id, v_max_key, v_reprocessed_count);

                         UPDATE dm_rate_event_stats
                            SET reprocessed_from_quarantine = v_reprocessed_count
                          WHERE data_source_code = p_source_code || '-T'
                            AND batch_id = v_batch_id;
                         COMMIT;
                END IF; -- Check for skip maintenance

                /*
                ** Identify any new FO buyerorgs and add them buyers mapping
                ** table with std_buyerorg_id = 0
                */
                add_new_buyerorgs(p_source_code, v_batch_id);

                /*
                ** Identify any new FO supplierorgs and add them supplier mapping
                ** table with std_supplierorg_id = 0
                */
                add_new_supplierorgs(p_source_code, v_batch_id);

                INSERT /*+ APPEND(t) */ INTO dm_timecard_rate_events_t t
                SELECT *
                  FROM TABLE(get_transformed_events(v_batch_id));
                v_rec_count := SQL%ROWCOUNT;
                COMMIT;
                --DBMS_OUTPUT.PUT_LINE('Transfered/pipelined v_rec_count = ' || v_rec_count);

                split_timesheet_rate_events(p_source_code, v_batch_id, p_skip_maint);

                v_retry_count   := 0;
                v_extract_count := 0;
                WHILE (v_retry_count < 4 AND v_extract_count < 1)
                LOOP
                  BEGIN
                        get_and_merge_jobs_info(p_source_code, v_link_name, v_batch_id, p_skip_maint);
                        v_extract_count := 1;
                  EXCEPTION
                     WHEN OTHERS THEN v_retry_count := v_retry_count + 1;
                  END;
                END LOOP;
                IF (v_extract_count = 0)
                   THEN
                        DBMS_OUTPUT.PUT_LINE('Unable to extract data after max retries, Ignoring');
                END IF;
       END IF; -- Check if we got some new data

       /*
       ** Update Timecard specific parameter
       ** for next DM refresh process
       */
       UPDATE dm_cube_objects
          SET   last_identifier  = TO_NUMBER(v_cutoff_date)
              , last_update_date = SYSDATE
        WHERE object_name = 'TS_RATE_EVENT_ID'
          AND object_source_code = p_source_code;

       COMMIT;
END process_batch;

PROCEDURE move_quarantine
(
   p_source_code IN     VARCHAR2
 , p_batch_id    IN     NUMBER
 , p_max_key     IN     NUMBER
 , p_rec_count   IN OUT NUMBER
)
IS
BEGIN
       INSERT /*+ APPEND(t) */ INTO fo_timecard_rate_events_tmp t
       SELECT   expenditure_date
              , p_batch_id AS batch_id
              , p_max_key + ROWNUM AS load_key
              , data_source_code
              , timecard_source
              , custom_address_country_id
              , assignment_type
              , buyerorg_id
              , supplierorg_id
              , assignment_id
              , job_id
              , rate_unit_type
              , rate_type
              , currency_description
              , rate_units
              , cumulative_bill_rate
              , job_title
              , assignment_edition_id
              , job_category_desc
              , job_level_desc
              , custom_address_city
              , custom_address_state
              , custom_address_postal_code
              , unparsed_custom_address
              , actual_end_date
              , buyerorg_name
              , supplierorg_name
         FROM dm_timecard_rate_events_q
        WHERE data_source_code = p_source_code;

       p_rec_count := SQL%ROWCOUNT;
END move_quarantine;

PROCEDURE reprocess_quarantine
IS
BEGIN
    reprocess_quarantine('REGULAR');
    reprocess_quarantine('WACHOVIA');
END reprocess_quarantine;

PROCEDURE reprocess_quarantine
(
   p_source_code IN     VARCHAR2
)
IS
       v_batch_id       NUMBER;
       v_max_key        NUMBER := 0;
       v_rec_count      NUMBER := 0;
BEGIN
       --
       -- Get the sequence required for logging messages
       --
       SELECT dm_msg_log_seq.NEXTVAL INTO v_batch_id FROM DUAL;

       EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_timecard_rate_events_tmp';

       move_quarantine(p_source_code, v_batch_id, v_max_key, v_rec_count);

       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_timecard_rate_events_t';

       INSERT /*+ APPEND(t) */ INTO dm_timecard_rate_events_t t
       SELECT *
         FROM TABLE(get_transformed_events(v_batch_id));
       COMMIT;

       split_timesheet_rate_events(p_source_code, v_batch_id, 'N');
END reprocess_quarantine;

    PROCEDURE reprocess_foreign_rate_events
    IS
       v_rate_event_count NUMBER := 0;
       v_rec_count        NUMBER := 0;
    BEGIN
           INSERT /*+ APPEND(t) */ INTO dm_timecard_rate_events_q t
           SELECT m.*
             FROM dm_timecard_rate_events m
            WHERE m.delete_reason_code = 'F';
           v_rec_count := SQL%ROWCOUNT;

           DELETE dm_timecard_rate_events m                  
            WHERE m.delete_reason_code = 'F';
           v_rate_event_count := SQL%ROWCOUNT;

           IF (v_rec_count = v_rate_event_count)
              THEN
                   COMMIT;
              ELSE
                   ROLLBACK;
           END IF;

           reprocess_quarantine;
    END reprocess_foreign_rate_events;

PROCEDURE split_timesheet_rate_events
(
    p_source_code IN VARCHAR2
  , p_batch_id    IN NUMBER
  , p_skip_maint  IN VARCHAR2
)
IS
       v_logical_deleted_count NUMBER;
       v_total_count           NUMBER;
       v_transformed_count     NUMBER;
       v_sent_to_quarantine    NUMBER;
       v_sql  VARCHAR2(128);
BEGIN
        SELECT COUNT(*)
          INTO v_total_count
          FROM dm_timecard_rate_events_t m;

        SELECT COUNT(*)
          INTO v_logical_deleted_count
          FROM dm_timecard_rate_events_t m
         WHERE m.delete_reason_code <> 'N';

        /*
        ** Move All logically deleted  OR
        **      Fully Transformed Events into dm_timecard_rate_events table
        */
        INSERT /*+ APPEND(t) */ INTO dm_timecard_rate_events t
        SELECT *
          FROM dm_timecard_rate_events_t m
         WHERE m.delete_reason_code <> 'N'
            OR (
                     m.delete_reason_code = 'N'
                 AND m.std_place_id        > 0
                 AND m.std_buyerorg_id     > 0
                 AND m.std_supplierorg_id  > 0
                 AND m.std_job_title_id    > 0
               );
        v_transformed_count := SQL%ROWCOUNT - v_logical_deleted_count;
        COMMIT;

        /*
        ** Move all the remaining (partially transformed and un-transformed)
        ** rate events into dm_timecard_rate_events_q
        */
        IF (p_skip_maint = 'N')
           THEN
                v_sql := 'ALTER TABLE dm_timecard_rate_events_q TRUNCATE PARTITION ' || p_source_code || '_Q';
                EXECUTE IMMEDIATE v_sql;
        END IF;

        INSERT /*+ APPEND(t) */ INTO dm_timecard_rate_events_q
        SELECT *
          FROM dm_timecard_rate_events_t m
         WHERE m.delete_reason_code = 'N'
           AND (
                    m.std_place_id        = 0
                 OR m.std_buyerorg_id     = 0
                 OR m.std_supplierorg_id  = 0
                 OR m.std_job_title_id    = 0
               );

        v_sent_to_quarantine := SQL%ROWCOUNT;
        COMMIT;

       UPDATE dm_rate_event_stats
          SET   placed_in_quarantine = v_sent_to_quarantine
              , transformed_events = v_transformed_count
              , logically_deleted_events = v_logical_deleted_count
        WHERE data_source_code = p_source_code || '-T'
          AND batch_id = p_batch_id;

        COMMIT;

        EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_rate_event_t';
        IF (v_total_count = v_transformed_count + v_logical_deleted_count + v_sent_to_quarantine)
           THEN
                EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_timecard_rate_events_t';
        END IF;
END split_timesheet_rate_events;

PROCEDURE get_merge_missing_jobs_info
IS
       TYPE vcharTab IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
       vDataSourceList vcharTab;
       v_batch_id NUMBER;
       v_link_name         VARCHAR2(16);
BEGIN
       vDataSourceList(1) := 'WACHOVIA';
       vDataSourceList(2) := 'REGULAR';

       FOR i IN vDataSourceList.FIRST .. vDataSourceList.LAST
       LOOP
             v_link_name := dm_rate_event.get_link_name(vDataSourceList(i));

             EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_timecard_rate_events_tmp';
             INSERT INTO fo_timecard_rate_events_tmp
                    (data_source_code, job_id)
             SELECT DISTINCT e.data_source_code, e.job_id
               FROM dm_timecard_rate_events e
              WHERE e.data_source_code = vDataSourceList(i)
                AND NOT EXISTS (
                                 SELECT NULL
                                   FROM dm_jobs v
                                  WHERE v.data_source_code = e.data_source_code
                                    AND v.job_id = e.job_id
                               );

             SELECT dm_msg_log_seq.NEXTVAL INTO v_batch_id FROM DUAL;
             get_and_merge_jobs_info(vDataSourceList(i), v_link_name, v_batch_id);

             EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_timecard_rate_events_tmp';
             INSERT INTO fo_timecard_rate_events_tmp
                    (data_source_code, job_id)
             SELECT DISTINCT e.data_source_code, e.job_id
               FROM dm_rate_event_master e
              WHERE e.data_source_code = vDataSourceList(i)
                AND NOT EXISTS (
                                 SELECT NULL
                                   FROM dm_jobs v
                                  WHERE v.data_source_code = e.data_source_code
                                    AND v.job_id = e.job_id
                               );

             SELECT dm_msg_log_seq.NEXTVAL INTO v_batch_id FROM DUAL;
             get_and_merge_jobs_info(vDataSourceList(i), v_link_name, v_batch_id);
       END LOOP;
END get_merge_missing_jobs_info;

PROCEDURE get_and_merge_jobs_info
(
    p_source_code IN VARCHAR2
  , p_link_name   IN VARCHAR2
  , p_batch_id    IN NUMBER
  , p_skip_maint  IN VARCHAR2
)
IS
       v_sql VARCHAR2(32767);
BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_dm_jobs_tmp';
       v_sql := '
       INSERT INTO fo_dm_jobs_tmp
         WITH jobs_list AS (
                             SELECT /*+ DRIVING_SITE(e) MATERIALIZE */ DISTINCT e.data_source_code, e.job_id
                               FROM fo_timecard_rate_events_tmp e
                           )
       SELECT /*+ DRIVING_SITE(j) */ ''' || p_source_code || '''
              , fr.business_org_fk
              , j.buyer_firm_fk
              , j.job_id
              , NVL(bob.business_organization_id, fr.business_org_fk)
              , j.job_category_fk
              , UPPER(SUBSTR(j.position_title, 1, 128))
              , js.type AS job_state
              , j.last_modified_date
              , j.create_date AS job_created_date
              , DECODE
                (   j.internal_approval_state
                  , 0, j.date_submitted_for_matching
                  , NVL(ap.completed_date, j.date_submitted_for_matching)
                )
              , rsl.bill_rate rate_range_low
              , rsh.bill_rate rate_range_high
              , DECODE (jrc.rate_unit_fk,0,''Hourly'',1,''Daily'',2,''Annual'',3,''Monthly'',4,''Weekly'',NULL)
              , UPPER(RTRIM(LTRIM(j.description)))
              , j.source_of_record
              , fo_dm_supp_metrics.get_profile_skills_list@LNK(j.resource_profile_fk) AS job_skills_text
              , UPPER(jc.description) AS job_category_desc
              , j.source_template_id
         FROM   jobs_list t
              , job@LNK j
              , job_category@LNK jc
              , job_state@LNK js
              , job_rate_card@LNK jrc
              , rate_set@LNK rsl
              , rate_set@LNK rsh
              , firm_role@LNK fr
              , bus_org_lineage@LNK bol
              , business_organization@LNK bob
              , approval_process@LNK ap
        WHERE j.job_id = t.job_id
          AND jc.value = j.job_category_fk
          AND js.value = j.job_state_fk
          AND jrc.identifier  (+) = j.rate_card_identifier_fk
          AND rsl.rate_set_id (+) = jrc.lower_rate_set_fk
          AND rsh.rate_set_id (+) = DECODE(jrc.uses_ranges, 1, jrc.upper_rate_set_fk, jrc.lower_rate_set_fk)
          AND fr.firm_id = j.buyer_firm_fk
          AND bol.descendant_bus_org_fk    (+) = fr.business_org_fk
          AND bob.business_organization_id (+) = bol.ancestor_bus_org_fk
          AND bob.parent_business_org_fk IS NULL
          AND ap.approvable_id   (+) = j.job_id
          AND ap.approvable_type (+) = ''Job''
          AND ap.active_process  (+) = 1
          AND ap.state_code      (+) = 3';

       v_sql := replace(v_sql, '@LNK', '@' || p_link_name);
       --INSERT INTO pk_text (pk_text) VALUES (v_sql);
       EXECUTE IMMEDIATE v_sql;
       COMMIT;

       manage_title_maps2;
       dm_rate_event.merge_jobs(p_source_code, p_batch_id, p_skip_maint);
END get_and_merge_jobs_info;

PROCEDURE manage_title_maps2
IS
BEGIN
       -- Following Statement
       -- Adds new buyer specic titles
       -- where there is no current mapping
       INSERT INTO dm_fo_title_map
              (apex_id, data_source_code, buyerorg_id, job_id, job_title, std_job_title_id, last_update_date)
       SELECT   fo_title_map_id.NEXTVAL AS apex_id, t.data_source_code, t.buyerorg_id, t.job_id
              , t.job_title, NVL(t.std_job_title_id, 0) AS std_job_title_id
              , SYSDATE AS last_update_date
         FROM (
                SELECT   /*+ DYNAMIC_SAMPLING(t2 10) USE_HASH(t2, m) */ t2.data_source_code, t2.buyerorg_id, t2.job_id, t2.job_title, m.std_job_title_id
                       , COUNT(DISTINCT m.std_job_title_id) OVER (PARTITION BY t2.data_source_code, t2.buyerorg_id, t2.job_id, t2.job_title) AS count1
                       , ROW_NUMBER() OVER (PARTITION BY t2.data_source_code, t2.buyerorg_id, t2.job_id, t2.job_title ORDER BY m.std_job_title_id) AS rnk
                  FROM fo_dm_jobs_tmp t2, dm_timecard_rate_events m
                 WHERE NOT EXISTS (
                                    SELECT NULL
                                      FROM dm_fo_title_map x
                                     WHERE x.data_source_code = t2.data_source_code
                                       AND x.buyerorg_id = t2.buyerorg_id
                                       AND x.job_title  = t2.job_title
                                       AND x.job_id = t2.job_id
                                  )
                  AND m.data_source_code   (+) = t2.data_source_code
                  AND m.buyerorg_id        (+) = t2.buyerorg_id
                  AND m.job_id             (+) = t2.job_id
                  AND m.job_title          (+) = t2.job_title
                  AND m.delete_reason_code (+) = 'N'
                  AND m.std_job_title_id   (+) > 0
              ) t
        WHERE t.count1 < 2
          AND t.rnk = 1;
  
       -- Following Statement
       -- Adds new buyer specic titles conflicts
       -- where there are multiple and different mappings
       INSERT INTO dm_fo_title_map_q
              (apex_id, data_source_code, buyerorg_id, job_id, job_title, std_job_title_id, last_update_date)
       SELECT   fo_title_map_q_id.NEXTVAL AS apex_id
              , z.data_source_code, z.buyerorg_id, z.job_id, z.job_title, z.std_job_title_id
              , SYSDATE AS last_update_date
         FROM (
                SELECT   y.data_source_code, y.buyerorg_id, y.job_id, y.job_title, y.std_job_title_id
                       , ROW_NUMBER() OVER (PARTITION BY y.data_source_code, y.buyerorg_id
                                                         , y.job_id, y.job_title, y.std_job_title_id
                                                ORDER BY y.std_job_title_id) AS rnk
                  FROM (
                         SELECT /*+ DYNAMIC_SAMPLING(t2 10) DYNAMIC_SAMPLING(x 10) USE_HASH(t2, m, x) */ t2.data_source_code, t2.buyerorg_id, t2.job_id, t2.job_title, m.std_job_title_id
                           FROM fo_dm_jobs_tmp t2, dm_fo_title_map x, dm_timecard_rate_events m
                          WHERE x.data_source_code = t2.data_source_code
                            AND x.buyerorg_id = t2.buyerorg_id
                            AND x.job_title  = t2.job_title
                            AND x.job_id = t2.job_id
                            AND x.std_job_title_id > 0
                            AND m.data_source_code   = t2.data_source_code
                            AND m.buyerorg_id        = t2.buyerorg_id
                            AND m.job_id             = t2.job_id
                            AND m.job_title          = t2.job_title
                            AND m.delete_reason_code = 'N'
                            AND m.std_job_title_id   > 0
                            AND m.std_job_title_id != x.std_job_title_id
                        ) y
               ) z
         WHERE z.rnk = 1
           AND NOT EXISTS (
                            SELECT NULL
                              FROM dm_fo_title_map_q q
                             WHERE q.data_source_code = z.data_source_code
                               AND q.buyerorg_id = z.buyerorg_id
                               AND q.job_id = z.job_id
                               AND q.job_title = z.job_title
                               AND q.std_job_title_id = z.std_job_title_id
                          );
END manage_title_maps2;

PROCEDURE close_index_month
(
    p_month_number  IN NUMBER
  , p_force_refresh IN VARCHAR2
)
IS
      v_count NUMBER;
BEGIN
      /*
      ** Check and Remove conflicting (Dervrived from 'FO Contract' source)
      ** weighted rate events as necessary
      */
      BEGIN
            SELECT /*+ ORDERED */ COUNT(*)
              INTO v_count
              FROM dm_weighted_rate_events t, dm_rate_event_master m, fo_buyers_map p
             WHERE t.month_number >= p_month_number
               AND t.month_type = 'I'
               AND t.rate_event_source = 'FO Contract'
               AND m.batch_id = t.batch_id
               AND m.load_key = t.load_key
               AND m.data_source_code = t.data_source_code
               AND p.data_source_code = m.data_source_code
               AND p.buyerorg_id      = m.buyerorg_id
               AND p.rate_source_pref <> 'FO Contract';

            IF (v_count > 0 AND p_force_refresh = 'Y')
               THEN
                     DELETE dm_weighted_rate_events w
                      WHERE w.month_number >= p_month_number
                        AND w.month_type   = 'I'
                        AND w.rate_event_source = 'FO Contract'
                        AND EXISTS (
                                     SELECT NULL
                                       FROM dm_rate_event_master m, fo_buyers_map p
                                      WHERE m.batch_id = w.batch_id
                                        AND m.load_key = w.load_key
                                        AND m.data_source_code = w.data_source_code
                                        AND p.data_source_code = m.data_source_code
                                        AND p.buyerorg_id      = m.buyerorg_id
                                        AND p.rate_source_pref <> 'FO Contract'
                                   );

                     COMMIT;
               ELSE
                     IF (v_count <> 0)
                        THEN RAISE_APPLICATION_ERROR(-20520, 'Conflicting FO Contract based Index weighted rate events already exists for ' || p_month_number);
                     END IF;
            END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN NULL;
      END;

      /*
      ** Check and Remove weighted rate events as necessary
      ** derived earlier from same 'BO/FO Timecard' source
      */
      BEGIN
            SELECT COUNT(*)
              INTO v_count
              FROM dm_weighted_rate_events t
             WHERE t.month_number = p_month_number
               AND t.month_type = 'I'
               AND t.rate_event_source LIKE '% Timecard';
     
            IF (v_count > 0 AND p_force_refresh = 'Y')
               THEN
                     DELETE dm_weighted_rate_events
                      WHERE month_number = p_month_number
                        AND month_type   = 'I'
                        AND rate_event_source LIKE '% Timecard';

                     COMMIT;
               ELSE
                     IF (v_count <> 0)
                        THEN RAISE_APPLICATION_ERROR(-20520, 'Timecard based Index weighted rate events already exists for ' || p_month_number);
                     END IF;
            END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN NULL;
      END;

      INSERT INTO dm_weighted_rate_events z
        WITH rate_history AS
             (
               SELECT /*+ MATERIALIZE */ z1.*
                 FROM (
                        SELECT t.data_source_code, t.assignment_id, t.rate_type, t.currency_description
                               , t.cumulative_bill_rate, MIN(t.expenditure_date) first_used_date
                               , MAX(t.index_month) last_index_month
                          FROM dm_timecard_rate_events t, fo_buyers_map m
                         WHERE m.data_source_code = t.data_source_code
                           AND m.buyerorg_id      = t.buyerorg_id
                           AND m.rate_source_pref <> 'FO Contract'
                           AND t.index_month <= p_month_number
                           AND t.index_month > TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE(TO_CHAR(p_month_number), 'YYYYMM'), -12), 'YYYYMM'))
                           AND t.rate_type NOT IN ('DT', 'OT')
                           AND t.delete_reason_code = 'N'
                         GROUP BY   t.data_source_code, t.assignment_id, t.rate_type, t.currency_description
                                  , t.cumulative_bill_rate
                         ORDER BY t.data_source_code, t.assignment_id, t.rate_type, t.currency_description, MIN(t.expenditure_date)
                      ) z1
                WHERE z1.last_index_month = p_month_number
             )
      SELECT   y.data_source_code, y.rate_event_source
             , y.std_country_id, y.month_number, y.month_type
             , y.assignment_id, y.std_job_title_id, y.std_place_id
             , y.first_expenditure_date, y.last_expenditure_date
             , y.proximity_weight, y.duration_units
             , y.reg_bill_rate
             , y.assignment_type
             , y.currency_description
             , y.job_title
             , jt.std_job_title_desc, jc.std_job_category_id, jc.std_job_category_desc, s.cmsa_code, s.cmsa_name
             , NULL AS batch_id, NULL AS load_key, 1 AS assignment_seq_number
             , NULL buyer_bill_rate, NULL reg_pay_rate, NULL rate_event_decision_date, NULL rate_event_start_date
             , NULL rate_event_end_date, SYSDATE AS last_update_date
             , y.std_buyerorg_id
        FROM (
               SELECT   x.data_source_code, MAX(x.timecard_source) || ' Timecard' AS rate_event_source
                      , MAX(x.std_country_id) std_country_id, x.index_month month_number, 'I' month_type
                      , x.assignment_id, MAX(x.std_job_title_id) std_job_title_id, MAX(x.std_place_id) std_place_id
                      , MIN(x.expenditure_date) first_expenditure_date, MAX(x.expenditure_date) last_expenditure_date
                      , ROUND(AVG(x.proximity_weight), 2) proximity_weight, SUM(x.rate_units) duration_units
                      , ROUND(sum(x.cumulative_bill_rate*x.rate_units)/SUM(x.rate_units), 2) reg_bill_rate
                      , MAX(x.assignment_type) assignment_type
                      , MAX(x.currency_description) currency_description
                      , MAX(x.job_title) job_title
                      , MAX(x.std_buyerorg_id) std_buyerorg_id
                 FROM (
                        SELECT n.expenditure_date-rh.first_used_date AS days_since, pi.proximity_weight, n.*
                          FROM dm_timecard_rate_events n, fo_buyers_map p, rate_history rh, dm_proximity_index pi
                         WHERE n.index_month = p_month_number
                           AND p.data_source_code = n.data_source_code
                           AND p.buyerorg_id      = n.buyerorg_id
                           AND p.rate_source_pref <> 'FO Contract'
                           AND n.delete_reason_code = 'N'
                           AND n.std_place_id > 0
                           AND n.std_job_title_id > 0
                           AND n.rate_type NOT IN ('DT', 'OT')
                           AND n.data_source_code = rh.data_source_code
                           AND n.assignment_id = rh.assignment_id
                           AND n.rate_type = rh.rate_type
                           AND n.cumulative_bill_rate = rh.cumulative_bill_rate
                           AND n.currency_description = rh.currency_description
                           AND (n.expenditure_date-rh.first_used_date) BETWEEN pi.days_range_begin AND pi.days_range_end
                      ) x
                GROUP BY x.data_source_code,x.index_month, x.assignment_id
               HAVING SUM(x.rate_units) > 0
             ) y, dm_job_titles jt, dm_job_category jc, dm_places p, dm_cmsa s
       WHERE jt.std_job_title_id = y.std_job_title_id
         AND jt.is_deleted = 'N'
         AND jt.std_job_category_id > 0
         AND jc.std_job_category_id = jt.std_job_category_id
         AND p.std_place_id = y.std_place_id
         AND s.cmsa_code (+) = p.cmsa_code;

      COMMIT;
END close_index_month;

PROCEDURE close_calendar_month
(
    p_month_number  IN NUMBER
  , p_force_refresh IN VARCHAR2
)
IS
      v_count NUMBER;
BEGIN
      /*
      ** Check and Remove conflicting (Dervrived from 'FO Contract' source)
      ** weighted rate events as necessary
      */
      BEGIN
            SELECT /*+ ORDERED */ COUNT(*)
              INTO v_count
              FROM dm_weighted_rate_events t, dm_rate_event_master m, fo_buyers_map p
             WHERE t.month_number >= p_month_number
               AND t.month_type = 'C'
               AND t.rate_event_source = 'FO Contract'
               AND m.batch_id = t.batch_id
               AND m.load_key = t.load_key
               AND m.data_source_code = t.data_source_code
               AND p.data_source_code = m.data_source_code
               AND p.buyerorg_id      = m.buyerorg_id
               AND p.rate_source_pref <> 'FO Contract';

            IF (v_count > 0 AND p_force_refresh = 'Y')
               THEN
                     DELETE dm_weighted_rate_events w
                      WHERE w.month_number >= p_month_number
                        AND w.month_type   = 'C'
                        AND w.rate_event_source = 'FO Contract'
                        AND EXISTS (
                                     SELECT NULL
                                       FROM dm_rate_event_master m, fo_buyers_map p
                                      WHERE m.batch_id = w.batch_id
                                        AND m.load_key = w.load_key
                                        AND m.data_source_code = w.data_source_code
                                        AND p.data_source_code = m.data_source_code
                                        AND p.buyerorg_id      = m.buyerorg_id
                                        AND p.rate_source_pref <> 'FO Contract'
                                   );

                     COMMIT;
               ELSE
                     IF (v_count <> 0)
                        THEN RAISE_APPLICATION_ERROR(-20520, 'Conflicting FO Contract based Calendar weighted rate events already exists for ' || p_month_number);
                     END IF;
            END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN NULL;
      END;

      /*
      ** Check and Remove weighted rate events as necessary
      ** derived earlier from same 'BO/FO Timecard' source
      */
      BEGIN
            SELECT COUNT(*)
              INTO v_count
              FROM dm_weighted_rate_events t
             WHERE t.month_number = p_month_number
               AND t.month_type = 'C'
               AND t.rate_event_source LIKE '% Timecard';
     
            IF (v_count > 0 AND p_force_refresh = 'Y')
               THEN
                     DELETE dm_weighted_rate_events
                      WHERE month_number = p_month_number
                        AND month_type   = 'C'
                        AND rate_event_source LIKE '% Timecard';

                     COMMIT;
               ELSE
                     IF (v_count <> 0)
                        THEN RAISE_APPLICATION_ERROR(-20520, 'Timecard based Calendar weighted rate events already exists for ' || p_month_number);
                     END IF;
            END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN NULL;
      END;

      INSERT INTO dm_weighted_rate_events z
        WITH rate_history AS
             (
               SELECT /*+ MATERIALIZE */ z1.*
                 FROM (
                        SELECT t.data_source_code, t.assignment_id, t.rate_type, t.currency_description
                               , t.cumulative_bill_rate, MIN(t.expenditure_date) first_used_date
                               , MAX(t.calendar_month) last_calendar_month
                          FROM dm_timecard_rate_events t, fo_buyers_map m
                         WHERE m.data_source_code = t.data_source_code
                           AND m.buyerorg_id      = t.buyerorg_id
                           AND m.rate_source_pref <> 'FO Contract'
                           AND t.calendar_month <= p_month_number
                           AND t.calendar_month > TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE(TO_CHAR(p_month_number), 'YYYYMM'), -12), 'YYYYMM'))
                           AND t.rate_type NOT IN ('DT', 'OT')
                           AND t.delete_reason_code = 'N'
                         GROUP BY   t.data_source_code, t.assignment_id, t.rate_type, t.currency_description
                                  , t.cumulative_bill_rate
                         ORDER BY t.data_source_code, t.assignment_id, t.rate_type, t.currency_description, MIN(t.expenditure_date)
                      ) z1
                WHERE z1.last_calendar_month = p_month_number
             )
      SELECT   y.data_source_code, y.rate_event_source
             , y.std_country_id, y.month_number, y.month_type
             , y.assignment_id, y.std_job_title_id, y.std_place_id
             , y.first_expenditure_date, y.last_expenditure_date
             , y.proximity_weight, y.duration_units
             , y.reg_bill_rate
             , y.assignment_type
             , y.currency_description
             , y.job_title
             , jt.std_job_title_desc, jc.std_job_category_id, jc.std_job_category_desc, s.cmsa_code, s.cmsa_name
             , NULL AS batch_id, NULL AS load_key, 1 AS assignment_seq_number
             , NULL buyer_bill_rate, NULL reg_pay_rate, NULL rate_event_decision_date, NULL rate_event_start_date
             , NULL rate_event_end_date, SYSDATE AS last_update_date
             , y.std_buyerorg_id
        FROM (
               SELECT   x.data_source_code, MAX(x.timecard_source) || ' Timecard' AS rate_event_source
                      , MAX(x.std_country_id) std_country_id, x.calendar_month month_number, 'C' month_type
                      , x.assignment_id, MAX(x.std_job_title_id) std_job_title_id, MAX(x.std_place_id) std_place_id
                      , MIN(x.expenditure_date) first_expenditure_date, MAX(x.expenditure_date) last_expenditure_date
                      , ROUND(AVG(x.proximity_weight), 2) proximity_weight, SUM(x.rate_units) duration_units
                      , ROUND(sum(x.cumulative_bill_rate*x.rate_units)/SUM(x.rate_units), 2) reg_bill_rate
                      , MAX(x.assignment_type) assignment_type
                      , MAX(x.currency_description) currency_description
                      , MAX(x.job_title) job_title
                      , MAX(x.std_buyerorg_id) std_buyerorg_id
                 FROM (
                        SELECT n.expenditure_date-rh.first_used_date AS days_since, pi.proximity_weight, n.*
                          FROM dm_timecard_rate_events n, fo_buyers_map p, rate_history rh, dm_proximity_index pi
                         WHERE n.calendar_month = p_month_number
                           AND p.data_source_code = n.data_source_code
                           AND p.buyerorg_id      = n.buyerorg_id
                           AND p.rate_source_pref <> 'FO Contract'
                           AND n.delete_reason_code = 'N'
                           AND n.std_place_id > 0
                           AND n.std_job_title_id > 0
                           AND n.rate_type NOT IN ('DT', 'OT')
                           AND n.data_source_code = rh.data_source_code
                           AND n.assignment_id = rh.assignment_id
                           AND n.rate_type = rh.rate_type
                           AND n.cumulative_bill_rate = rh.cumulative_bill_rate
                           AND n.currency_description = rh.currency_description
                           AND (n.expenditure_date-rh.first_used_date) BETWEEN pi.days_range_begin AND pi.days_range_end
                      ) x
                GROUP BY x.data_source_code,x.calendar_month, x.assignment_id
               HAVING SUM(x.rate_units) > 0
             ) y, dm_job_titles jt, dm_job_category jc, dm_places p, dm_cmsa s
       WHERE jt.std_job_title_id = y.std_job_title_id
         AND jt.is_deleted = 'N'
         AND jt.std_job_category_id > 0
         AND jc.std_job_category_id = jt.std_job_category_id
         AND p.std_place_id = y.std_place_id
         AND s.cmsa_code (+) = p.cmsa_code;

END close_calendar_month;

    PROCEDURE close_all_months
    (
        p_date1         IN NUMBER
      , p_date2         IN NUMBER
      , p_force_refresh IN VARCHAR2
    )
    IS
           CURSOR c1 IS
           SELECT m.column_value AS month_number
             FROM TABLE(dm_index.get_month_keys(TO_DATE(p_date1, 'YYYYMM'), TO_DATE(p_date2, 'YYYYMM'))) m
            ORDER BY m.column_value;
    BEGIN
           FOR r1 IN c1
           LOOP
                close_index_month(r1.month_number, p_force_refresh);
                close_calendar_month(r1.month_number, p_force_refresh);
           END LOOP;
           COMMIT;
    END close_all_months;

BEGIN
   dm_rate_event.load_country_list;
END dm_fotimecard_rate_event;
/