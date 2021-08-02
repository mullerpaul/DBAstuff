--SET SERVEROUTPUT ON SIZE 1000000;
CREATE OR REPLACE PACKAGE BODY dm_botimecard_rate_event
AS
PROCEDURE extract_bo_rate_events
(
    p_source_code IN VARCHAR2
  , p_from_date   IN VARCHAR2 -- YYYYMMDD
  , p_to_date     IN VARCHAR2 -- YYYYMMDD
  , p_start_date  IN VARCHAR2 -- YYYYMMDD
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
    SELECT /*+ DRIVING_SITE(adr) */
             y.expenditure_date
           , ' || p_batch_id || '
           , ROWNUM
           , ''' || p_source_code || '''
           , ''BO''
           , pl.country
           , y.assignment_type
           , y.buyerorg_id
           , y.supplierorg_id
           , y.assignment_id
           , y.job_id
           , ''Hourly''
           , y.rate_type
           , y.currency_description
           , y.rate_units
           , y.bill_rate
           , UPPER(y.job_title)
           , y.assignment_edition_id
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
                    , ROW_NUMBER() OVER (PARTITION BY x.assignment_id, x.expenditure_date, x.rate_type ORDER BY ae.assignment_edition_id DESC) AS rnk
               FROM (
                      SELECT /*+ DYNAMIC_SAMPLING(br 10) */
                               ac.job_fk job_id
                             , ac.assignment_continuity_id
                             , br.*
                             , bfr.business_org_fk AS buyerorg_id
                             , sfr.business_org_fk AS supplierorg_id
                        FROM   bo_rate_events_tmp br
                             , firm_role@LNK bfr
                             , firm_role@LNK sfr
                             , assignment_continuity@LNK ac
                       WHERE br.expenditure_date >= TO_DATE(''' || p_from_date || ''',''YYYYMMDD'')
                         AND br.expenditure_date <  TO_DATE(''' || p_to_date   || ''',''YYYYMMDD'')
                         AND br.buyer_firm_id            = bfr.firm_id
                         AND br.supplier_firm_id         = sfr.firm_id
                         AND ac.assignment_continuity_id = br.assignment_id
                    ) x
                    , assignment_edition@LNK ae
              WHERE ae.assignment_continuity_fk = x.assignment_continuity_id
           ) y
           , business_organization@LNK bob
           , business_organization@LNK bos
           , job_level@LNK jl
           , job_category@LNK jc
           , address@LNK adr
           , place@LNK pl
     WHERE y.rnk  < 2
       AND bob.business_organization_id = y.buyerorg_id
       AND bos.business_organization_id = y.supplierorg_id
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
       SET t.job_title = REPLACE(REGEXP_REPLACE(t.job_title, c_regexp_rule), CHR(15712189))
     WHERE t.job_title IS NOT NULL;

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
END extract_bo_rate_events;

PROCEDURE extract_all_bo_rate_events
IS
    TYPE vcharTab IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
    vDataSourceList vcharTab;
    v_start_date DATE := TO_DATE('20080101', 'YYYYMMDD');
    v_begin_date DATE;
    v_end_date   DATE;
    v_batch_id   NUMBER;
    v_retry_count       PLS_INTEGER := 0;
    v_extract_count     PLS_INTEGER := 0;
    v_link_name    VARCHAR2(16);
BEGIN
    vDataSourceList(1) := 'REGULAR';

    dm_rate_event.drop_job_indexes;
    v_begin_date := ADD_MONTHS(v_start_date, -2);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE bo_rate_events_tmp';
    INSERT /*+ APPEND(t) */ INTO bo_rate_events_tmp t
    SELECT /*+ DRIVING_SITE(item) FULL(item) */
             MAX(item.IQN_FO_OWNING_BUYER_ID) buyer_firm_id
           , MAX(item.IQN_FO_OWNING_SUPPLIER_ID) supplier_firm_id
           , item.expenditure_item_date expenditure_date
           , DECODE(item.expenditure_type, 'Labor-Contractors', 'ST', 'Labor-Overtime', 'OT', 'Labor-Doubletime', 'DT') rate_type
           , SUM(item.quantity) RATE_UNITS
           , SUM(item.quantity * item.bill_rate)/SUM(item.quantity) bill_rate
           , MAX(item.denom_currency_code) currency_description
           , MAX(substr(task.attribute2, 1, 2)) assignment_type
           , TO_NUMBER(substr(task.attribute2, 3)) assignment_id
      FROM   pa_expenditure_items_all@IQH_IQPRODM item
           , pa_expenditures_all@IQH_IQPRODM exp
           , pa_tasks@IQH_IQPRODM task
           , pa_projects_all@IQH_IQPRODM proj
     WHERE exp.expenditure_id = item.expenditure_id
       AND task.task_id = item.task_id
       AND task.attribute2 NOT LIKE '__ACCUK%'
       AND task.attribute2 NOT LIKE '__ING%'
       AND task.attribute2 NOT LIKE '__%-%'
       AND task.attribute2 NOT LIKE '__TM%'
       AND task.attribute2 NOT LIKE '__AM%'
       AND task.attribute2 NOT LIKE '__TSY%'
       AND task.attribute2 NOT LIKE '__SSF%'
       AND task.attribute2 NOT LIKE '__DELL%'
       AND task.attribute2 NOT LIKE '%I'
       AND proj.project_id = task.project_id
       AND exp.expenditure_status_code = 'APPROVED'
       AND item.expenditure_type IN ('Labor-Contractors', 'Labor-Overtime', 'Labor-Doubletime')
       AND item.expenditure_item_date > v_begin_date
       AND item.iqn_fo_owning_buyer_id IS NOT NULL
     GROUP BY   TO_NUMBER(substr(task.attribute2, 3))
              , DECODE(item.expenditure_type, 'Labor-Contractors', 'ST', 'Labor-Overtime', 'OT', 'Labor-Doubletime', 'DT')
              , item.expenditure_item_date
    HAVING SUM(item.quantity) > 0;
    COMMIT;

    WHILE (v_begin_date < TRUNC(SYSDATE+31, 'MM'))
    LOOP
         v_end_date := ADD_MONTHS(v_begin_date, 1);
         --DBMS_OUTPUT.PUT_LINE(v_begin_date || '==>' || v_end_date);
         FOR i IN vDataSourceList.FIRST .. vDataSourceList.LAST
         LOOP
               v_link_name := dm_rate_event.get_link_name(vDataSourceList(i));
               --
               -- Get the sequence required for logging messages
               --
               SELECT dm_msg_log_seq.NEXTVAL INTO v_batch_id FROM DUAL;

               extract_bo_rate_events(vDataSourceList(i), TO_CHAR(v_begin_date, 'YYYYMMDD'), TO_CHAR(v_end_date, 'YYYYMMDD'), TO_CHAR(v_start_date, 'YYYYMMDD'), v_batch_id);

               /*
               ** Identify any new FO buyerorgs and add them buyers mapping
               ** table with std_buyerorg_id = 0
               */
               dm_fotimecard_rate_event.add_new_buyerorgs(vDataSourceList(i), v_batch_id);

               /*
               ** Identify any new FO supplierorgs and add them supplier mapping
               ** table with std_supplierorg_id = 0
               */
               dm_fotimecard_rate_event.add_new_supplierorgs(vDataSourceList(i), v_batch_id);

               INSERT /*+ APPEND(t) */ INTO dm_timecard_rate_events_t t
               SELECT *
                 FROM TABLE(dm_fotimecard_rate_event.get_transformed_events(v_batch_id));
               COMMIT;

               dm_fotimecard_rate_event.split_timesheet_rate_events(vDataSourceList(i), v_batch_id, 'Y');

               v_retry_count   := 0;
               v_extract_count := 0;
               WHILE (v_retry_count < 4 AND v_extract_count < 1)
               LOOP
                 BEGIN
                       dm_fotimecard_rate_event.get_and_merge_jobs_info(vDataSourceList(i), v_link_name, v_batch_id, 'Y');
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
END extract_all_bo_rate_events;

END dm_botimecard_rate_event;
/