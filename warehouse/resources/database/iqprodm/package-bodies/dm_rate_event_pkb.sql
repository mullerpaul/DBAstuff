CREATE OR REPLACE PACKAGE BODY dm_rate_event
/**********************************************************************************
 * Name: dm_rate_event
 * Desc: This package contains all the procedures required to
 *       migrate/process FO rate event data to be used in
 *       Data mart
 *
 * Author   Date        Version   History
 * --------------------------------------------------------------------------------
 * jpullifrone 01/07/16    Make Netherland-based rate events fully transformed IQN-29683
 * pkattula    08/02/13    Integration with Timecard based rate events
 * pkattula    06/15/13    Frozen RateIQ
 * pkattula    01/16/12    Changes to do incremental extracts
 *                         based on timestamp(create_date) for rate events
 * pkattula    05/12/09    Initial
 ********************************************************************************/
AS
  PROCEDURE p_main
  (
      p_source_code IN VARCHAR2
  )
  IS
     v_prev_cutoff       VARCHAR2(16);
     ln_msg_id           NUMBER;
     v_crnt_proc_name    user_jobs.what%TYPE := 'DM_RATE_EVENT.P_MAIN';
     ln_count            NUMBER;
     lv_proc_name        user_jobs.what%TYPE := 'DM_RATE_EVENT.P_MAIN';
     lv_fo_app_err_msg   VARCHAR2(2000)  := NULL;
     lv_fo_db_err_msg    VARCHAR2(2000)  := NULL;
     ln_err_num          NUMBER;
     lv_err_msg          VARCHAR2(4000)  := NULL;
     lv_ea_count         NUMBER;
     lv_wo_count         NUMBER;
     ge_fo_exception     EXCEPTION;
     email_subject       VARCHAR2(64) := 'DM Rate Event Update';
     remote_extract_done VARCHAR2(1) := 'N';
     v_cutoff_date       VARCHAR2(16);
  BEGIN
     EXECUTE IMMEDIATE 'ALTER SESSION SET "_b_tree_bitmap_plans"=false';

     EXECUTE IMMEDIATE 'ALTER SESSION SET optimizer_use_invisible_indexes = true';

     --
     -- Get the sequence reuired for logging messages
     --
     SELECT dm_msg_log_seq.NEXTVAL INTO ln_msg_id FROM DUAL;

     --
     -- Check if the previous job still running
     --
     ln_count := get_job_status('DM_RATE_EVENTS_PROC;');
     IF ln_count > 1 THEN
         --
         -- previous job still running log and exit
         --
         dm_util_log.p_log_msg(ln_msg_id,0,gv_process || ' - PREVIOUS JOB STILL RUNNING',lv_proc_name,'I');
         dm_util_log.p_log_msg(ln_msg_id,0,NULL,NULL,'U');
     ELSE

         --
         --Log initial load status
         --
         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'FO','STARTED',NULL,'I');

         --
         -- Call the procedure to get the FO rate event data.
         --
         v_cutoff_date := TO_CHAR(SYSDATE-0.291667, 'YYYYMMDDHH24MISS'); -- Current time - 7 hours
         v_crnt_proc_name := 'DM_RATE_EVENT.GET_NEW_RATE_EVENTS';
         dm_util_log.p_log_msg(ln_msg_id,1, p_source_code || ': FO Rate Event Extract',v_crnt_proc_name,'I');
         get_new_rate_events(ln_msg_id, v_cutoff_date, ln_err_num,lv_err_msg, lv_ea_count, lv_wo_count, p_source_code, v_prev_cutoff);
         remote_extract_done := 'Y';
         dm_util_log.p_log_msg(ln_msg_id,1, NULL,NULL,'U');

         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'FO','COMPLETE',0,'U');

         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'DW','STARTED',NULL,'I');
         pull_and_transform(p_source_code, ln_msg_id, v_prev_cutoff, v_cutoff_date);
         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'DW','COMPLETE',0,'U');

         /*
         ** Update Workorder specific parameter
         ** for next DM refresh process
         */
         UPDATE dm_cube_objects
            SET   last_identifier  = TO_NUMBER(v_cutoff_date)
                , last_update_date = SYSDATE
          WHERE object_name IN ('WO_RATE_EVENT_ID', 'EA_RATE_EVENT_ID')
            AND object_source_code = p_source_code;

         COMMIT;
     END IF;
  EXCEPTION
     WHEN OTHERS THEN
     BEGIN
           lv_fo_db_err_msg := SQLERRM;
           IF (remote_extract_done = 'Y')
              THEN
                   lv_fo_app_err_msg := 'Unable to execute the procedure to Pull and Transform Rate Event data after successful FO extraction!';
                   dm_util_log.p_log_load_status(ln_msg_id, gv_process,'DW','FAILED',0,'U');
              ELSE
                   dm_util_log.p_log_load_status(ln_msg_id, gv_process,'FO','FAILED',0,'U');
           END IF;
           dm_utils.send_email(c_email_sender, c_email_recipients, email_subject, p_source_code || ' Process failed due to the following ' || c_crlf || lv_fo_app_err_msg || c_crlf || lv_fo_db_err_msg || c_crlf);
     END;
  END p_main;

  PROCEDURE get_new_rate_events
  (
      p_msg_id       IN  NUMBER
    , p_cutoff_date  IN  VARCHAR2
    , on_err_num     OUT NUMBER
    , ov_err_msg     OUT VARCHAR2
    , ov_ea_count    OUT NUMBER
    , ov_wo_count    OUT NUMBER
    , p_source_code  IN  VARCHAR2
    , p_prev_cutoff  OUT VARCHAR2
  )
  IS
    le_exception   EXCEPTION;
    lv_proc_name   VARCHAR2(100)  := 'DM_RATE_EVENT.GET_NEW_RATE_EVENTS';
    lv_app_err_msg VARCHAR2(2000) := NULL;
    lv_db_err_msg  VARCHAR2(2000) := NULL;
    ln_commit      NUMBER;
    ln_err_num     NUMBER;
    lv_err_msg     VARCHAR2(2000) := NULL;
    v_ea_from_date VARCHAR2(16);
    v_wo_from_date VARCHAR2(16);
  BEGIN
     BEGIN
       v_link_name := get_link_name(p_source_code);

       BEGIN
             SELECT TO_CHAR(last_identifier)
               INTO v_ea_from_date
               FROM dm_cube_objects
              WHERE object_name = 'EA_RATE_EVENT_ID'
                AND object_source_code = p_source_code
                AND ROWNUM = 1;
       EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 BEGIN
                        /*
                        ** This should happen only on
                        ** first time or when DM is empty
                        ** NOTE: DM is interested only in data on/after 1st January 2007
                        */
                        v_sql := 'SELECT TO_CHAR(MIN(create_date), ''YYYYMMDDHH24MISS'')
                                    FROM assignment_edition@LNK
                                   WHERE valid_to_date >= TO_DATE(''20070101'', ''YYYYMMDD'')';
                        v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
                        EXECUTE IMMEDIATE v_sql INTO v_ea_from_date;

                        INSERT INTO dm_cube_objects (object_name, object_source_code, last_update_date, last_identifier)
                               VALUES ('EA_RATE_EVENT_ID', p_source_code, SYSDATE, TO_NUMBER(v_ea_from_date));
                 END;
       END;
       p_prev_cutoff := v_ea_from_date;

       BEGIN
             SELECT TO_CHAR(last_identifier)
               INTO v_wo_from_date
               FROM dm_cube_objects
              WHERE object_name = 'WO_RATE_EVENT_ID'
                AND object_source_code = p_source_code
                AND ROWNUM = 1;
       EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 BEGIN
                        /*
                        /*
                        ** This should happen only on
                        ** first time or when DM is empty
                        ** NOTE: DM is interested only in data on/after 1st January 2007
                        */
                        v_sql := 'SELECT TO_CHAR(MIN(create_date), ''YYYYMMDDHH24MISS'')
                                    FROM work_order_effectivity_view@LNK
                                   WHERE valid_to_date >= TO_DATE(''20070101'', ''YYYYMMDD'')';
                        v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
                        EXECUTE IMMEDIATE v_sql INTO v_wo_from_date;

                        INSERT INTO dm_cube_objects (object_name, object_source_code, last_update_date, last_identifier)
                        VALUES ('WO_RATE_EVENT_ID', p_source_code, SYSDATE, TO_NUMBER(v_wo_from_date));
                 END;
       END;

       v_sql := 'BEGIN fo_dm_rate_event.get_new_rate_events@LNK(:p_msg_id, :p_source_code, :p_cutoff_date, :v_ea_from_date, :v_wo_from_date); END;';
       v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
       EXECUTE IMMEDIATE v_sql USING p_msg_id, p_source_code, p_cutoff_date,  v_ea_from_date, v_wo_from_date;

     EXCEPTION
       WHEN OTHERS THEN
         lv_app_err_msg := 'Unable to execute the remote procedure to get the FO Rate Event data !';
         lv_db_err_msg  := SQLERRM;
     END;

     --
     -- check for any errors in remote procedure
     --
     BEGIN
       v_sql := 'SELECT err_msg
                   FROM fo_dm_rate_event_errmsg@LNK
                  WHERE ROWNUM < 2';
       v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
       EXECUTE IMMEDIATE v_sql INTO lv_err_msg;

       IF lv_err_msg IS NOT NULL THEN
          lv_app_err_msg := 'Errors occured in the remote procedure to get Rate Event data! ';
          lv_db_err_msg  := lv_err_msg || ' ' || SQLERRM;
       END IF;
     EXCEPTION
         WHEN NO_DATA_FOUND THEN lv_err_msg := NULL;
     END;

     IF (lv_db_err_msg IS NOT NULL)
        THEN
             RAISE_APPLICATION_ERROR(-20501, lv_app_err_msg || lv_db_err_msg);
     END IF;
  END get_new_rate_events;

  PROCEDURE pull_and_transform
  (
      p_source_code    IN VARCHAR2
    , p_msg_id         IN NUMBER
    , p_from_timestamp IN NUMBER
    , p_to_timestamp   IN NUMBER
    , p_skip_maint     IN VARCHAR2
  )
  IS
     v_crnt_proc_name user_jobs.what%TYPE := 'DM_RATE_EVENT.PULL_AND_TRANSFORM';
     v_rec_count      NUMBER;
     v_ea_rec_count   NUMBER;
     v_wo_rec_count   NUMBER;
  BEGIN
     dm_util_log.p_log_msg(p_msg_id, 2, p_source_code || ': Truncate DW Temp Tables', v_crnt_proc_name, 'I');
     EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_rate_event_tmp';
     EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_dm_jobs_tmp';

     dm_util_log.p_log_msg(p_msg_id, 2, NULL, NULL, 'U');

     dm_util_log.p_log_msg(p_msg_id, 3, p_source_code || ': Pull Jobs Data from FO to DW', v_crnt_proc_name, 'I');
     v_sql := 'INSERT INTO fo_dm_jobs_tmp t
               (  data_source_code, buyerorg_id, buyerfirm_id, job_id, top_buyerorg_id, job_category_id, job_title
                , job_state, last_modified_date, job_created_date, job_approved_date , rate_range_low, rate_range_high
                , rate_unit_type , job_desc , source_of_record , job_skills_text , job_category_desc , source_template_id
               )
               SELECT data_source_code, buyerorg_id, buyerfirm_id, job_id, top_buyerorg_id, job_category_id, job_title
                       , job_state, last_modified_date, job_created_date, job_approved_date, rate_range_low, rate_range_high
                       , rate_type, job_desc, source_of_record, job_skills_text, job_category_desc , source_template_id
                 FROM fo_dm_jobs_tmp@LNK';

     v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
     EXECUTE IMMEDIATE v_sql;
     v_rec_count := SQL%ROWCOUNT;
     COMMIT;

     dm_util_log.p_log_msg(p_msg_id, 3, NULL, NULL, 'U');
     dm_util_log.p_log_msg(p_msg_id, 4, p_source_code || ': Pulled ' || v_rec_count || ' Jobs Data records from FO to DW', v_crnt_proc_name, 'I');
     dm_util_log.p_log_msg(p_msg_id, 4, NULL, NULL, 'U');
     dm_util_log.p_log_msg(p_msg_id, 3, p_source_code || ': Pull Rate Events from FO to DW', v_crnt_proc_name, 'I');

     v_sql := 'INSERT INTO fo_rate_event_tmp t
               (  buyerorg_id, supplierorg_id, job_level_id, job_level_desc, job_category_id, job_category_desc, job_title
                , buyerorg_name, supplierorg_name, assignment_id, assignment_type, assignment_rate_edition_id, assignment_edition_id
                , work_order_version, assignment_start_date, assignment_end_date, rate_event_acceptance_date, rate_event_start_date
                , rate_event_end_date, currency_description, reg_bill_rate, ot_bill_rate, dt_bill_rate, buyer_bill_rate, buyer_ot_rate
                , buyer_dt_rate, supplier_reg_reimb_rate, supplier_ot_reimb_rate, supplier_dt_reimb_rate, reg_pay_rate
                , ot_pay_rate, dt_pay_rate, place_id, address_city, address_state, address_postal_code, address_country_id
                , source_template_id, job_id, batch_id, load_key, custom_address_city, custom_address_state, custom_address_postal_code
                , custom_address_country_id, buyer_address_city, buyer_address_state, buyer_address_postal_code, buyer_address_country_id
                , unparsed_address, unparsed_custom_address, custom_place_id, fo_source_of_record, rate_unit_type, data_source_code
               )
               SELECT buyerorg_id, supplierorg_id, job_level_id, job_level_desc, job_category_id, job_category_desc, job_title
                       , buyerorg_name, supplierorg_name, assignment_id, assignment_type, assignment_rate_edition_id, assignment_edition_id
                       , work_order_version, assignment_start_date, assignment_end_date, rate_event_acceptance_date, rate_event_start_date
                       , rate_event_end_date, currency_description, reg_bill_rate, ot_bill_rate, dt_bill_rate, buyer_bill_rate, buyer_ot_rate
                       , buyer_dt_rate, supplier_reg_reimb_rate, supplier_ot_reimb_rate, supplier_dt_reimb_rate, reg_pay_rate
                       , ot_pay_rate, dt_pay_rate, place_id, address_city, address_state, address_postal_code , address_country_id
                       , source_template_id, job_id, batch_id, load_key, custom_address_city, custom_address_state , custom_address_postal_code
                       , custom_address_country_id, buyer_address_city, buyer_address_state, buyer_address_postal_code, buyer_address_country_id
                       , unparsed_address, unparsed_custom_address, custom_place_id, fo_source_of_record, rate_type, data_source_code
                 FROM fo_rate_event_tmp@LNK';

     v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
     EXECUTE IMMEDIATE v_sql;

     v_wo_rec_count := SQL%ROWCOUNT;
     COMMIT;
     dm_util_log.p_log_msg(p_msg_id, 3, NULL, NULL, 'U');

     UPDATE fo_rate_event_tmp t
        SET t.job_title         = REPLACE(REGEXP_REPLACE(t.job_title, c_regexp_rule), CHR(15712189))
      WHERE t.job_title IS NOT NULL;

     COMMIT;

     INSERT INTO dm_rate_event_stats
            (
               data_source_code
             , batch_id
             , process_date
             , new_input_rate_events
             , reprocessed_from_quarantine
             , placed_in_quarantine
             , new_buyerorgs
             , new_supplierorgs
             , extract_timestamp_from
             , extract_timestamp_cutoff
            )
     VALUES (
               p_source_code
             , p_msg_id
             , SYSDATE
             , v_wo_rec_count
             , 0
             , 0
             , 0
             , 0
             , p_from_timestamp
             , p_to_timestamp
            );
     IF (v_wo_rec_count > 0)
        THEN
              SELECT COUNT(*)
                INTO v_ea_rec_count
                FROM fo_rate_event_tmp
               WHERE assignment_type = 'EA';

              v_wo_rec_count := v_wo_rec_count - v_ea_rec_count;
              dm_util_log.p_log_msg(p_msg_id, 4, p_source_code || ': Pulled ' || v_wo_rec_count || ' Work Order Rate Event records from FO to DW', v_crnt_proc_name, 'I');
              dm_util_log.p_log_msg(p_msg_id, 4, NULL, NULL, 'U');
              dm_util_log.p_log_msg(p_msg_id, 5, p_source_code || ': Pulled ' || v_ea_rec_count || ' Express Assignment Rate Event records from FO to DW', v_crnt_proc_name, 'I');
              dm_util_log.p_log_msg(p_msg_id, 5, NULL, NULL, 'U');
     END IF;

     transform_rate_events     (1, p_source_code, p_msg_id, p_skip_maint);

     manage_title_maps;

     merge_jobs(p_source_code, p_msg_id);

     populate_weighted_events(p_msg_id);
  END pull_and_transform;

  PROCEDURE inv_flagged_events
  IS
      CURSOR all_batches IS
             SELECT DISTINCT data_source_code, batch_id
               FROM dm_rate_event_master
              ORDER BY batch_id;
  BEGIN
         FOR batch_list IN all_batches
         LOOP
              UPDATE dm_rate_event_master t
                 SET   t.delete_reason_code = 'Y'
                     , t.last_update_date   = SYSDATE
               WHERE batch_id = batch_list.batch_id
                 AND data_source_code = batch_list.data_source_code
                 AND delete_reason_code NOT IN ('N', 'Y')
                 AND EXISTS (
                              SELECT NULL
                                FROM dm_rate_event_master v
                               WHERE v.data_source_code = t.data_source_code
                                 AND v.assignment_type  = t.assignment_type
                                 AND v.assignment_id    = t.assignment_id
                                 AND v.batch_id > t.batch_id
                       );
              COMMIT;
         END LOOP;
  END inv_flagged_events;

  PROCEDURE inv_prior_events
  (
      p_source_code IN VARCHAR2
    , p_msg_id      IN NUMBER
    , p_skip_maint  IN VARCHAR2
  )
  IS
     v_crnt_proc_name user_jobs.what%TYPE := 'DM_RATE_EVENT.INV_PRIOR_EVENTS';
     v_invalidated_rec_count  NUMBER;
     v_reprocessed_count      NUMBER := 0;
     v_max_key NUMBER;
  BEGIN
         DELETE dm_weighted_rate_events w
          WHERE batch_id IS NOT NULL
            AND EXISTS (
                         SELECT NULL
                           FROM dm_rate_event_master e
                          WHERE EXISTS (
                                         SELECT NULL
                                           FROM fo_rate_event_tmp v
                                          WHERE v.data_source_code = e.data_source_code
                                            AND v.assignment_type  = e.assignment_type
                                            AND v.assignment_id    = e.assignment_id
                                       )
                            AND e.batch_id = w.batch_id
                            AND e.load_key = w.load_key
                       );

         dm_util_log.p_log_msg(p_msg_id, 9, p_source_code || ': Invalidate Prior Rate Events in DW', v_crnt_proc_name, 'I');
         UPDATE dm_rate_event_master t
            SET   t.delete_reason_code = 'Y'
                , t.last_update_date   = SYSDATE
          WHERE EXISTS (
                         SELECT NULL
                           FROM fo_rate_event_tmp v
                          WHERE v.data_source_code = t.data_source_code
                            AND v.assignment_type  = t.assignment_type
                            AND v.assignment_id    = t.assignment_id
                       );
         v_invalidated_rec_count := SQL%ROWCOUNT;
         dm_util_log.p_log_msg(p_msg_id,  9, NULL, NULL, 'U');
         dm_util_log.p_log_msg(p_msg_id, 10, p_source_code || ': Invalidated ' || v_invalidated_rec_count || ' Rate Event records', v_crnt_proc_name, 'I');
         dm_util_log.p_log_msg(p_msg_id, 10, NULL, NULL, 'U');

         SELECT NVL(MAX(load_key), 0)
           INTO v_max_key
           FROM fo_rate_event_tmp;

         IF (p_skip_maint = 'N')
            THEN
                /*
                ** Add Any untransformed events from prior
                ** runs held in table dm_rate_event_q
                ** back into fo_rate_event_tmp
                ** so that they will be processed along with
                ** the new batch of events extracted from FO
                **
                ** The last NOT EXISTS basically drops any assignments
                ** for which have newer version in the current batch
                ** This is equivalent of invalidating
                ** old rate events whenever there is new version of assignment
                */
                INSERT INTO fo_rate_event_tmp
                     (
                         buyerorg_id
                       , supplierorg_id
                       , job_level_id
                       , job_level_desc
                       , job_category_id
                       , job_category_desc
                       , job_title
                       , buyerorg_name
                       , supplierorg_name
                       , assignment_id
                       , assignment_type
                       , assignment_rate_edition_id
                       , assignment_edition_id
                       , work_order_version
                       , assignment_start_date
                       , assignment_end_date
                       , rate_event_acceptance_date
                       , rate_event_start_date
                       , rate_event_end_date
                       , currency_description
                       , reg_bill_rate
                       , ot_bill_rate
                       , dt_bill_rate
                       , buyer_bill_rate
                       , buyer_ot_rate
                       , buyer_dt_rate
                       , supplier_reg_reimb_rate
                       , supplier_ot_reimb_rate
                       , supplier_dt_reimb_rate
                       , reg_pay_rate
                       , ot_pay_rate
                       , dt_pay_rate
                       , place_id
                       , address_city
                       , address_state
                       , address_postal_code
                       , address_country_id
                       , source_template_id
                       , job_id
                       , batch_id
                       , load_key
                       , custom_address_city
                       , custom_address_state
                       , custom_address_postal_code
                       , custom_address_country_id
                       , buyer_address_city
                       , buyer_address_state
                       , buyer_address_postal_code
                       , buyer_address_country_id
                       , unparsed_address
                       , unparsed_custom_address
                       , custom_place_id
                       , fo_source_of_record
                       , rate_unit_type
                       , data_source_code
                     )
                SELECT   t.buyerorg_id
                       , t.supplierorg_id
                       , t.job_level_id
                       , t.job_level_desc
                       , t.job_category_id
                       , t.job_category_desc
                       , t.job_title
                       , t.buyerorg_name
                       , t.supplierorg_name
                       , t.assignment_id
                       , t.assignment_type
                       , t.assignment_rate_edition_id
                       , t.assignment_edition_id
                       , t.work_order_version
                       , t.assignment_start_date
                       , t.assignment_end_date
                       , t.rate_event_acceptance_date
                       , t.rate_event_start_date
                       , t.rate_event_end_date
                       , t.currency_description
                       , t.reg_bill_rate
                       , t.ot_bill_rate
                       , t.dt_bill_rate
                       , t.buyer_bill_rate
                       , t.buyer_ot_rate
                       , t.buyer_dt_rate
                       , t.supplier_reg_reimb_rate
                       , t.supplier_ot_reimb_rate
                       , t.supplier_dt_reimb_rate
                       , t.reg_pay_rate
                       , t.ot_pay_rate
                       , t.dt_pay_rate
                       , t.place_id
                       , t.address_city
                       , t.address_state
                       , t.address_postal_code
                       , t.address_country_id
                       , t.source_template_id
                       , t.job_id
                       , p_msg_id AS batch_id
                       , v_max_key + ROWNUM AS load_key
                       , t.custom_address_city
                       , t.custom_address_state
                       , t.custom_address_postal_code
                       , t.custom_address_country_id
                       , t.buyer_address_city
                       , t.buyer_address_state
                       , t.buyer_address_postal_code
                       , t.buyer_address_country_id
                       , t.unparsed_address
                       , t.unparsed_custom_address
                       , t.custom_place_id
                       , t.fo_source_of_record
                       , t.rate_unit_type
                       , t.data_source_code
                  FROM dm_rate_event_q t
                 WHERE t.data_source_code = p_source_code
                   AND NOT EXISTS (
                                    SELECT NULL
                                      FROM fo_rate_event_tmp v
                                     WHERE v.data_source_code = t.data_source_code
                                       AND v.assignment_type  = t.assignment_type
                                       AND v.assignment_id    = t.assignment_id
                                  );
                v_reprocessed_count := SQL%ROWCOUNT;
         END IF; -- Check for Skip Maintenance

       UPDATE dm_rate_event_stats
          SET   invalidated_prior_events = v_invalidated_rec_count
              , reprocessed_from_quarantine = v_reprocessed_count
        WHERE data_source_code = p_source_code
          AND batch_id = p_msg_id;
  END inv_prior_events;

    FUNCTION clean_state(p_country_id NUMBER, p_state IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
       IF (p_country_id <> 1) THEN RETURN(p_state); END IF;

       CASE
            WHEN p_state like 'Virtual %' THEN RETURN(SUBSTR(REPLACE(p_state, 'Virtual '), 1, 2));
            WHEN p_state like '% Virtual' THEN RETURN(SUBSTR(REPLACE(p_state, ' Virtual'), 1, 2));
            WHEN p_state = 'WarsawIN'     THEN RETURN('IN');
            ELSE                               RETURN(SUBSTR(p_state, 1, 2));
       END CASE;
    END  clean_state;

    FUNCTION clean_city(p_city IN VARCHAR2, p_country_id NUMBER, p_state IN VARCHAR2) RETURN VARCHAR2
    IS
       pos1    PLS_INTEGER;
       pos2    PLS_INTEGER;
       pos3    PLS_INTEGER;
       pos4    PLS_INTEGER;
       pos     PLS_INTEGER;
       part1   VARCHAR2(100);
       part2   VARCHAR2(100);
       v_city  VARCHAR2(100);
       v_state VARCHAR2(100);
    BEGIN
       v_state := clean_state(p_country_id, p_state);

       IF (v_state = 'NC' AND p_city = 'WINSTON-SALEM')  THEN RETURN('WINSTON SALEM'); END IF;
       IF (v_state = 'NC' AND p_city = 'WINSTEN-SALEM')  THEN RETURN('WINSTON SALEM'); END IF;

       pos1 := INSTR(p_city, '-');
       pos2 := INSTR(p_city, '/');
       IF (pos1 = 0)
          THEN
               pos := pos2;
          ELSE
               IF (pos2 = 0)
                  THEN
                       pos := pos1;
                  ELSE
                       pos := least(pos1, pos2);
               END IF;
       END IF;

       pos3 := INSTR(p_city, ' (');
       IF (pos3 > 0)
          THEN
               IF (pos = 0)
                  THEN
                       pos := pos3;
                  ELSE
                       pos := least(pos, pos3);
               END IF;
       END IF;

       pos4 := REGEXP_INSTR(p_city, '[[:digit:]]');
       IF (pos4 > 0)
          THEN
               pos4 := INSTR(p_city, ' ', pos4-LENGTH(p_city)-1);
               IF (pos = 0)
                  THEN
                       pos := pos4;
                  ELSE
                       pos := least(pos, pos4);
               END IF;
       END IF;
       --DBMS_OUTPUT.PUT_LINE('pos=' || pos || ', pos4=' || pos4);

       IF (pos = 0)
          THEN
               v_city := p_city;
          ELSE
               part1 := SUBSTR(p_city, 1, pos-1);
               part2 := SUBSTR(p_city, pos+1);
               IF (part1 LIKE ' %') THEN part1 := SUBSTR(part1, 2); END IF;
               IF (part2 LIKE ' %') THEN part2 := SUBSTR(part2, 2); END IF;
               CASE
                    WHEN part1 IN ('EAST','EASTERN','SOUTH','SOUTHERN','CENTRAL','METRO','DOWNTOWN','EAST BAY','SILICON VALLEY','WEST','WESTERN','NORTH', 'NORTHERN') THEN v_city := part2;
                    WHEN part1 IS NULL THEN v_city := part2;
                    ELSE v_city := part1;
               END CASE;
       END IF;
       --DBMS_OUTPUT.PUT_LINE('v_city1=' || v_city);

       CASE
            WHEN v_state = 'MO' AND v_city = 'KS CITY'        THEN v_city := 'KANSAS CITY';
            WHEN v_state = 'MA' AND v_city = 'N. REDDING'     THEN v_city := 'NORTH READING';
            WHEN v_state = 'TX' AND v_city = 'W. FT. HOOD'    THEN v_city := 'FORT HOOD';
            WHEN v_state = 'IL' AND v_city = 'OAKBROOK'       THEN v_city := 'OAK BROOK';
            WHEN v_state = 'CO' AND v_city = 'DENVER DTC'     THEN v_city := 'DENVER';
            WHEN v_state = 'AL' AND v_city = 'THORNSBY'       THEN v_city := 'THORSBY';
            WHEN v_state = 'WI' AND v_city = 'MANASHA'        THEN v_city := 'MENASHA';
            WHEN v_state = 'NY' AND v_city like '%NYC'        THEN v_city := 'NEW YORK';
            WHEN v_state = 'NY' AND v_city like 'NEW YORK%'   THEN v_city := 'NEW YORK';
            WHEN v_state = 'NY' AND v_city = 'POUGHKEESPSIE'  THEN v_city := 'POUGHKEEPSIE';
            WHEN v_state = 'DC' AND v_city = 'WASHINGTON DC'  THEN v_city := 'WASHINGTON';
            WHEN v_state = 'FL' AND v_city = 'KEY WEST'       THEN NULL;
            WHEN v_state = 'CA' AND v_city = 'CENTRAL VALLEY' THEN NULL;
            WHEN v_city like '%ST. %'        THEN v_city := REPLACE(v_city, 'ST.', 'SAINT');
            WHEN v_city like 'ST %'          THEN v_city := REPLACE(v_city, 'ST ', 'SAINT ');
            WHEN v_city like '%FT. %'        THEN v_city := REPLACE(v_city, 'FT.', 'FORT');
            WHEN v_city like 'FT %'          THEN v_city := REPLACE(v_city, 'FT ', 'FORT ');
            WHEN v_city like '%MT. %'        THEN v_city := REPLACE(v_city, 'MT.', 'MOUNT');
            WHEN v_city like 'MT %'          THEN v_city := REPLACE(v_city, 'MT ', 'MOUNT ');
            WHEN v_city like '% CITY %'      THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' CITY')+4);
            WHEN v_city like '% TOWN %'      THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' TOWN')+4);
            WHEN v_city like '% VIA%'        THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' VIA')-1);
            WHEN v_city like '% BRANCH%'     THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' BRANCH')-1);
            WHEN v_city like '% CENTER%'     THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' CENTER')-1);
            WHEN v_city like '% SQUARE%'     THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' SQUARE')-1);
            WHEN v_city like '% SOUTH'       THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' SOUTH')-1);
            WHEN v_city like '% NORTH'       THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' NORTH')-1);
            WHEN v_city like '% WEST'        THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' WEST')-1);
            WHEN v_city like '% WESTERN'     THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' WESTERN')-1);
            WHEN v_city like '% EAST'        THEN v_city := SUBSTR(v_city, 1, INSTR(v_city, ' EAST')-1);
            WHEN v_city like 'CENTRAL %'     THEN v_city := REPLACE(v_city, 'CENTRAL ');
            WHEN v_city like 'SOUTHERN %'    THEN v_city := REPLACE(v_city, 'SOUTHERN ');
            WHEN v_city like 'NORTHERN %'    THEN v_city := REPLACE(v_city, 'NORTHERN ');
            WHEN v_city like '% NORTHWEST'   THEN v_city := REPLACE(v_city, ' NORTHWEST ');
            WHEN v_city like 'VIRTUAL %'     THEN v_city := REPLACE(v_city, 'VIRTUAL ');
            WHEN v_city like '% VIRTUAL'     THEN v_city := REPLACE(v_city, ' VIRTUAL');
            WHEN v_city like 'DOWNTOWN %'    THEN v_city := REPLACE(v_city, 'DOWNTOWN ');
            WHEN v_city like '% DOWNTOWN%'   THEN v_city := REPLACE(v_city, ' DOWNTOWN');
            WHEN pos = 0                     THEN NULL;
            ELSE BEGIN
                       --DBMS_OUTPUT.PUT_LINE('v_city2=' || v_city);
                       pos1 := INSTR(v_city, '-');
                       pos2 := INSTR(v_city, '/');
                       IF (pos1 = 0)
                          THEN
                               IF (pos2 > 0)
                                  THEN
                                       v_city := SUBSTR(v_city, 1, pos2-1);
                               END IF;
                          ELSE
                               IF (pos2 > 0)
                                  THEN
                                       pos := least(pos1, pos2);
                                       v_city := SUBSTR(v_city, 1, pos-1);
                                  ELSE
                                       v_city := SUBSTR(v_city, 1, pos1-1);
                               END IF;
                       END IF;
                 END;
       END CASE;
       pos1 := INSTR(v_city, ' ');
       IF (pos1 > 0)
          THEN
               part1 := SUBSTR(v_city, 1, pos1-1);
               part2 := SUBSTR(v_city, pos1+1);
               IF ((part2 <> 'FE' AND LENGTH(part2) < 3) OR part2 = part1)
                  THEN RETURN(part1);
               END IF;
       END IF;
       return(v_city);
    END clean_city;

    FUNCTION wac_zip(unparsed VARCHAR2) return VARCHAR2
    IS
    BEGIN
           RETURN(SUBSTR(unparsed, INSTR(unparsed, ' ', -1, 1)+1, 5));
    END wac_zip;

    FUNCTION wac_state(unparsed VARCHAR2) return VARCHAR2
    IS
    BEGIN
           RETURN(SUBSTR(unparsed, INSTR(unparsed, ' ', -1, 2)+1, 2));
    END wac_state;

    FUNCTION wac_city(unparsed VARCHAR2) return VARCHAR2
    IS
        pos1 pls_integer;
        pos2 pls_integer;
        pos3 pls_integer;
        tok1_len pls_integer;
        tok1 VARCHAR2(256);
        tok2 VARCHAR2(256);
        tok3 VARCHAR2(256);
        special_chars pls_integer := 0;
        numeric_string NUMBER := -1;
    BEGIN
        pos1 := INSTR(unparsed, ' ', -1, 4);
        pos2 := INSTR(unparsed, ' ', -1, 3);
        pos3 := INSTR(unparsed, ' ', -1, 2);

        tok1 := SUBSTR(unparsed, pos1+1, pos2-pos1-1);
        tok1_len := LENGTH(tok1);
        tok2 := SUBSTR(unparsed, pos2+1, pos3-pos2-1);

        -- DBMS_OUTPUT.PUT_LINE('tok1 = ' || tok1);
        -- DBMS_OUTPUT.PUT_LINE('tok2 = ' || tok2);

        special_chars := INSTR(tok1, '-');
        IF (special_chars = 0)
           THEN
                special_chars := INSTR(tok1, '/');
        END IF;

        IF (special_chars = 0)
           THEN
                special_chars := INSTR(tok1, ':');
        END IF;

        IF (special_chars = 0)
           THEN
                special_chars := INSTR(tok1, '#');
        END IF;

        BEGIN
              numeric_string := TO_NUMBER(tok1);
        EXCEPTION
          WHEN OTHERS THEN NULL;
        END;

        CASE
          WHEN tok1_len = 1        THEN RETURN(tok2);
          WHEN special_chars > 0   THEN RETURN(tok2);
          WHEN tok1 = tok2         THEN RETURN(tok2);
          WHEN numeric_string >= 0 THEN RETURN(tok2);
          WHEN tok1 IN ('Dr','Rd','Blvd','Place','St','Plaza','Ct','Park','Cir','Center','Sq','Ave','Avenue','Bridge','Island','Pike','Way','Street','Hwy','Bldg','Building','Suite','Suites','Bypass','Plz','Tower','Complex','Pkwy','Parkway','Drive','Circle','Court','Road','Ste','Floor','Fl','Broadway','Trail','Trl','Ln','Lane','Flr','Pl','Dr.','Ctr','Boulevard','Blvd.','Tpke','Turnpike','Centre','Streets','Aves','Village', '2005088001l', 'Banking', 'Bank')
                                   THEN RETURN(tok2);
          ELSE                          RETURN(tok1 || ' ' || tok2);
        END CASE;
    END wac_city;

    FUNCTION get_events
    (
      p_type IN NUMBER
    )
    RETURN eventTab
    PIPELINED
    AS
          c1       event_curs;
          vInpRecs eventTab;
    BEGIN
          IF (p_type = 1)
             THEN
                  OPEN c1 FOR SELECT
                                       0 AS std_buyerorg_id
                                     , 0 AS std_supplierorg_id
                                     , 0 AS std_job_title_id
                                     , 0 AS std_place_id
                                     , 0 AS std_country_id
                                     , CAST(NULL AS VARCHAR2(64)) AS transform_reason_codes
                                     , buyerorg_id
                                     , supplierorg_id
                                     , job_level_id
                                     , job_level_desc
                                     , job_category_id
                                     , job_category_desc
                                     , job_title
                                     , buyerorg_name
                                     , supplierorg_name
                                     , assignment_id
                                     , rate_event_acceptance_date
                                     , assignment_type
                                     , assignment_rate_edition_id
                                     , assignment_edition_id
                                     , work_order_version
                                     , assignment_start_date
                                     , assignment_end_date
                                     , CAST (LEAST(rate_event_acceptance_date, rate_event_start_date) AS DATE) AS rate_event_decision_date
                                     , rate_event_start_date
                                     , rate_event_end_date
                                     , currency_description
                                     , reg_bill_rate
                                     , ot_bill_rate
                                     , dt_bill_rate
                                     , buyer_bill_rate
                                     , buyer_ot_rate
                                     , buyer_dt_rate
                                     , supplier_reg_reimb_rate
                                     , supplier_ot_reimb_rate
                                     , supplier_dt_reimb_rate
                                     , reg_pay_rate
                                     , ot_pay_rate
                                     , dt_pay_rate
                                     , address_city
                                     , address_state
                                     , address_postal_code
                                     , address_country_id
                                     , source_template_id
                                     , job_id
                                     , place_id
                                     , batch_id
                                     , load_key
                                     , CAST (SYSDATE AS DATE) AS last_update_date
                                     , custom_address_city
                                     , custom_address_state
                                     , custom_address_postal_code
                                     , custom_address_country_id
                                     , buyer_address_city
                                     , buyer_address_state
                                     , buyer_address_postal_code
                                     , buyer_address_country_id
                                     , unparsed_address
                                     , unparsed_custom_address
                                     , custom_place_id
                                     , fo_source_of_record
                                     , rate_unit_type
                                     , data_source_code
                                     , CAST('N' AS VARCHAR2(1)) AS delete_reason_code
                                FROM fo_rate_event_tmp;
             ELSE
                  IF (p_type = 2)
                     THEN
                           OPEN c1 FOR SELECT m.*
                                         FROM dm_rate_event_master m
                                        WHERE m.delete_reason_code = 'N'
                                          AND (
                                                   m.std_buyerorg_id     = 0
                                                OR m.std_supplierorg_id  = 0
                                                OR m.std_job_title_id    = 0
                                                OR m.std_place_id        = 0
                                              );
                     ELSE
                           IF (p_type = 3)
                              THEN
                                   OPEN c1 FOR SELECT m.*
                                                 FROM dm_rate_event_master m
                                                WHERE m.delete_reason_code = 'F';
                              ELSE
                                   OPEN c1 FOR SELECT m.*
                                                 FROM dm_rate_event_master m
                                                WHERE m.delete_reason_code != 'Y';
                           END IF;
                  END IF;
          END IF;
          LOOP
               FETCH c1 BULK COLLECT INTO vInpRecs LIMIT 50000;
               FOR i IN 1 .. vInpRecs.COUNT
               LOOP
                    PIPE ROW(vInpRecs(i));
               END LOOP;
               EXIT WHEN c1%NOTFOUND;
          END LOOP;
          CLOSE c1;
    END get_events;

    PROCEDURE add_new_buyerorgs
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
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
                      FROM fo_rate_event_tmp t
                     WHERE NOT EXISTS (
                                        SELECT NULL
                                          FROM fo_buyers_map m
                                         WHERE m.buyerorg_id = t.buyerorg_id
                                      )
                  ) x;

           v_rec_count := SQL%ROWCOUNT;

           UPDATE dm_rate_event_stats
              SET new_buyerorgs = v_rec_count
            WHERE data_source_code = p_source_code
              AND batch_id = p_msg_id;

           IF (v_rec_count > 0)
              THEN
                    dm_utils.send_email(c_email_sender, c_email_recipients, email_subject, 'Please NOTE that ' || v_rec_count || ' missing buyerorgs for ' || p_source_code || ' have been added to FO_BUYERS_MAP. Update the mapping at your earliest convenience.' || c_crlf);
           END IF;
    END add_new_buyerorgs;

    PROCEDURE add_new_supplierorgs
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
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
                               FROM fo_rate_event_tmp t
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
            WHERE data_source_code = p_source_code
              AND batch_id = p_msg_id;

           IF (v_rec_count > 0)
              THEN
                    dm_utils.send_email(c_email_sender, c_email_recipients, email_subject, 'Please NOTE that ' || v_rec_count || ' missing supplierorgs for ' || p_source_code || ' have been added to FO_SUPPLIERS_MAP. Update the mapping at your earliest convenience.' || c_crlf);
           END IF;
    END add_new_supplierorgs;

    PROCEDURE transform_rate_events
    (
        p_type        IN NUMBER
      , p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
      , p_skip_maint  IN VARCHAR2
    )
    IS
        v_crnt_proc_name user_jobs.what%TYPE := 'DM_RATE_EVENT.TRANSFORM_RATE_EVENTS';
        v_processed_rec_count  NUMBER;

      CURSOR inp1 IS
      SELECT t9.*
       FROM (
             SELECT dp2.std_place_id p2_std_place_id, dp2.cmsa_code p2_cmsa_code
                    , t8.*
                    -- In case of multiple location matches give least preference to non-metro CMSA
                    , ROW_NUMBER() OVER (PARTITION BY t8.batch_id, t8.load_key ORDER BY INSTR(dp2.cmsa_code, '9999') ASC) AS rnk2
               FROM (
                      SELECT dp.std_place_id p1_std_place_id, dp.cmsa_code p1_cmsa_code
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
                                                 SELECT
                                                          NVL(o2.std_job_title_id, 0)    AS o2_std_job_title_id
                                                        , NVL(o2.std_place_id, 0)        AS o2_std_place_id
                                                        , t4.*
                                                   FROM (
                                                          SELECT
                                                                   NVL(o1.std_job_title_id, 0)    AS o1_std_job_title_id
                                                                 , NVL(o1.std_place_id, 0)        AS o1_std_place_id
                                                                 , t3.*
                                                            FROM (
                                                                   SELECT /*+ DYNAMIC_SAMPLING(t 2) */
                                                                            NVL(sm.std_supplierorg_id, 0) AS new_std_supplierorg_id
                                                                          , NVL(bm.std_buyerorg_id, 0)    AS new_std_buyerorg_id
                                                                          , clean_state(t.address_country_id, t.address_state) AS cln_state
                                                                          , clean_city(t.address_city, t.custom_address_country_id, t.address_state) AS cln_city
                                                                          , t.*
                                                                     FROM TABLE(get_events(p_type)) t, fo_suppliers_map sm, fo_buyers_map bm
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
                AND dp2.std_country_id  (+) = t8.address_country_id
                AND dp2.std_state       (+) = t8.cln_state
                AND dp2.std_city        (+) = t8.cln_city
                AND dp2.cmsa_code       (+)   IS NOT NULL
            ) t9
      WHERE t9.rnk2 < 2;

      v_reason_cd           dm_rate_event_master.transform_reason_codes%TYPE;
      v_std_job_title_id    dm_buyer_job_overrides.std_job_title_id%TYPE    := 0;
      v_std_place_id        dm_places.std_place_id%TYPE                     := 0;

      v_std_country_id      dm_places.std_country_id%TYPE                   := 0;
      v_ovr_country_id      dm_places.std_country_id%TYPE                   := 0;
      v_delete_reason_code  dm_rate_event_master.delete_reason_code%TYPE    := 'N';
      v_rec_count           PLS_INTEGER;
      v_update_count        PLS_INTEGER;
      v_wac_country_id      dm_rate_event_master.custom_address_country_id%TYPE;
      v_wac_postal_code     dm_rate_event_master.custom_address_postal_code%TYPE;
      v_wac_state           dm_rate_event_master.custom_address_state%TYPE;
      v_wac_city            dm_rate_event_master.custom_address_city%TYPE;
      v_city                dm_rate_event_master.custom_address_city%TYPE;
      v_state               dm_rate_event_master.custom_address_state%TYPE;
      v_effective_rate      dm_rate_event_master.reg_bill_rate%TYPE;
      v_first_time          VARCHAR2(1) := 'Y';
  BEGIN

      /*
      ** p_type = 1 ==> Regular stream of data, not to be confused with REGULAR data source
      */
      IF (p_type = 1)
         THEN
               /*
               ** Identify any new FO buyerorgs and add them buyers mapping
               ** table with std_buyerorg_id = 0
               */
               add_new_buyerorgs(p_source_code, p_msg_id);

               /*
               ** Identify any new FO supplierorgs and add them supplier mapping
               ** table with std_supplierorg_id = 0
               */
               add_new_supplierorgs(p_source_code, p_msg_id);

               /*
               ** Invlidate prior versions of rate events
               ** for which we have new versions
               */
               inv_prior_events(p_source_code, p_msg_id, p_skip_maint);

               EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_rate_event_t';
      END IF;

      dm_util_log.p_log_msg(p_msg_id, 11, p_source_code || ': Transform Rate Events', v_crnt_proc_name, 'I');
      v_processed_rec_count := 0;
      v_rec_count           := 0;
      v_update_count        := 0;
      FOR inp_rec IN inp1
      LOOP
            v_rec_count := v_rec_count + 1;
            IF (v_first_time = 'Y')
               THEN
                     v_first_time := 'N';
                     dm_util_log.p_log_msg(p_msg_id, 12, p_source_code || ': Time first record Fetched From Base Transformation Query', v_crnt_proc_name, 'I');
                     dm_util_log.p_log_msg(p_msg_id, 12, NULL, NULL, 'U');
            END IF;

            v_reason_cd              := NULL;
            v_std_job_title_id       := 0;
            v_std_place_id           := 0;
            v_std_country_id         := 0;

            v_delete_reason_code := 'N';
            CASE (inp_rec.currency_description)
              WHEN 'USD'  THEN IF (inp_rec.custom_address_country_id = 1 OR inp_rec.custom_address_country_id IS NULL)
                                  THEN
                                        verify_us(inp_rec.custom_address_state, inp_rec.unparsed_custom_address, inp_rec.supplierorg_name, inp_rec.job_title, inp_rec.buyerorg_name, v_std_country_id);
                                        IF (v_std_country_id = 0)
                                           THEN
                                                v_delete_reason_code := 'F';
                                        END IF;
                               END IF;
              WHEN 'GBP'  THEN
                               verify_uk(inp_rec.custom_address_state, inp_rec.unparsed_custom_address, inp_rec.supplierorg_name, inp_rec.job_title, inp_rec.buyerorg_name, v_std_country_id);
                               IF (v_std_country_id = 0)
                                  THEN
                                       v_delete_reason_code := 'F';
                               END IF;
              WHEN 'EUR' THEN
			                   IF inp_rec.custom_address_country_id = c_nl_country_id 
							      THEN 
								    v_delete_reason_code := 'N';
									v_std_country_id := c_nl_country_id;
								  ELSE
								    v_delete_reason_code := 'F';
                                    v_std_country_id := 0;
							   END IF;
			  
			  ELSE             v_delete_reason_code := 'F';
                               v_std_country_id := 0;
            END CASE;

            IF ((v_delete_reason_code = 'N') AND ((inp_rec.rate_event_start_date < c_start_date AND inp_rec.rate_event_end_date < c_start_date) OR (inp_rec.rate_event_end_date > ADD_MONTHS(SYSDATE, 60))))
               THEN
                     v_delete_reason_code := 'D';
            END IF;

            IF ((v_delete_reason_code = 'N') AND (inp_rec.job_title LIKE '%SALES%TAX%' OR (inp_rec.buyerorg_id = 16347 AND inp_rec.job_title = 'PRINT SERVICES')))
               THEN
                     v_delete_reason_code := 'T';
            END IF;

            IF (v_delete_reason_code = 'N')
               THEN
                     CASE (inp_rec.rate_unit_type)
                          WHEN 'Weekly'  THEN v_effective_rate := inp_rec.reg_bill_rate/c_weekly_hours;
                          WHEN 'Daily'   THEN v_effective_rate := inp_rec.reg_bill_rate/c_daily_hours;
                          WHEN 'Monthly' THEN v_effective_rate := inp_rec.reg_bill_rate/c_monthly_hours;
                          WHEN 'Annual'  THEN v_effective_rate := inp_rec.reg_bill_rate/c_annual_hours;
                          ELSE                v_effective_rate := inp_rec.reg_bill_rate;
                     END CASE;
                     IF (v_effective_rate <= 0)
                        THEN
                              v_delete_reason_code := 'B';
                        ELSE
                              CASE (v_std_country_id)
                                WHEN c_us_country_id THEN
                                     IF (v_effective_rate < c_us_min_rate OR v_effective_rate > c_us_max_rate)
                                        THEN
                                             v_delete_reason_code := 'B';
                                     END IF;
                                WHEN c_uk_country_id THEN
                                     IF (v_effective_rate < c_uk_min_rate OR v_effective_rate > c_uk_max_rate)
                                        THEN
                                             v_delete_reason_code := 'B';
                                     END IF;
                                WHEN c_nl_country_id  THEN
                                     IF (v_effective_rate < c_nl_min_rate OR v_effective_rate > c_nl_max_rate)
                                        THEN
                                             v_delete_reason_code := 'B';
                                     END IF;
                                WHEN c_ca_country_id  THEN
                                     IF (v_effective_rate < c_ca_min_rate OR v_effective_rate > c_ca_max_rate)
                                        THEN
                                             v_delete_reason_code := 'B';
                                     END IF;
                                WHEN c_in_country_id  THEN
                                     IF (v_effective_rate < c_in_min_rate OR v_effective_rate > c_in_max_rate)
                                        THEN
                                             v_delete_reason_code := 'B';
                                     END IF;
                                ELSE          IF (v_effective_rate < 0)
                                                 THEN
                                                       v_delete_reason_code := 'B';
                                              END IF;
                              END CASE;
                     END IF;
            END IF;

            /*
            ** Any further transformations are performed
            ** Only on records that are NOT already "invalidated or marked for logical deletion"
            */
            IF (v_delete_reason_code = 'N')
               THEN
                     /*
                     ** Check if there are any JOB ID and Assignment ID specific overrides
                     */
                     IF (inp_rec.o1_std_job_title_id > 0)
                        THEN
                              v_reason_cd := 'ASO'; -- Assignment Specific override
                              v_std_job_title_id := inp_rec.o1_std_job_title_id;
                              IF (inp_rec.o1_std_place_id > 0)
                                 THEN
                                      v_std_place_id := inp_rec.o1_std_place_id;
                              END IF;
                     END IF;

                     /*
                     ** Check if there are any JOB ID specific overrides
                     */
                     IF (v_std_job_title_id = 0 AND inp_rec.o2_std_job_title_id > 0)
                        THEN
                              v_reason_cd := 'JSO'; -- Job Specific override
                              v_std_job_title_id := inp_rec.o2_std_job_title_id;
                              IF (inp_rec.o2_std_place_id > 0)
                                 THEN
                                      v_std_place_id := inp_rec.o2_std_place_id;
                              END IF;
                     END IF;

                     /*
                     ** Check if there are any Buyer Org and Title specific overrides
                     */
                     IF (v_std_job_title_id = 0 AND inp_rec.o3_std_job_title_id > 0)
                        THEN
                              v_reason_cd := 'BTO'; -- Buyer Org Title specific override
                              v_std_job_title_id := inp_rec.o3_std_job_title_id;
                              IF (v_std_place_id = 0 AND inp_rec.o3_std_place_id > 0)
                                 THEN
                                      v_std_place_id := inp_rec.o3_std_place_id;
                              END IF;
                     END IF;

                     /*
                     ** Check if there are any Generic Title level mapping/override
                     */
                     IF (v_std_job_title_id = 0 AND inp_rec.o4_std_job_title_id > 0)
                        THEN
                              v_reason_cd := 'GTL'; -- Generic Title level mapping
                              v_std_job_title_id := inp_rec.o4_std_job_title_id;
                              -- Can't override place in Generic Title Override
                              -- so ingore place
                     END IF;


                     IF (v_std_place_id = 0)
                        THEN
                             CASE (v_std_country_id)
                                WHEN c_uk_country_id THEN v_std_place_id   := v_uk_place_id;
                                WHEN c_nl_country_id THEN v_std_place_id   := v_nl_place_id;
                                WHEN c_ca_country_id THEN v_std_place_id   := v_ca_place_id;
                                WHEN c_in_country_id THEN v_std_place_id   := v_in_place_id;
                                ELSE  IF (inp_rec.p1_std_place_id IS NOT NULL)
                                         THEN
                                              v_reason_cd    := v_reason_cd || ',CPZ';
                                              v_std_place_id := inp_rec.p1_std_place_id;
                                         ELSE
                                              IF (inp_rec.p2_std_place_id > 0)
                                                 THEN
                                                      IF (inp_rec.cln_city != inp_rec.address_city)
                                                         THEN
                                                               -- Applied City/State Hygiene
                                                               v_reason_cd    := v_reason_cd || ',SCC';
                                                         ELSE
                                                               v_reason_cd    := v_reason_cd || ',SPC';
                                                      END IF;
                                                      v_std_place_id := inp_rec.p2_std_place_id;
                                                 ELSE
                                                      IF (inp_rec.custom_address_state IS NOT NULL AND inp_rec.custom_address_city IS NOT NULL)
                                                         THEN
                                                              -- Custom place that didn't match by Postal code
                                                              -- So try using State and City
                                                              BEGIN
                                                                    SELECT dp2.std_place_id
                                                                      INTO v_std_place_id
                                                                      FROM (
                                                                             SELECT dp.std_place_id
                                                                                    -- In case of multiple location matches give least preference to non-metro CMSA
                                                                                    , ROW_NUMBER() OVER (ORDER BY INSTR(dp.cmsa_code, '9999') ASC) AS rnk
                                                                               FROM dm_places dp
                                                                              WHERE dp.std_country_id  = inp_rec.custom_address_country_id
                                                                                AND dp.std_state       = clean_state(inp_rec.custom_address_country_id, inp_rec.custom_address_state)
                                                                                AND dp.std_city        = clean_city(inp_rec.custom_address_city, inp_rec.custom_address_country_id, inp_rec.custom_address_state)
                                                                                AND dp.cmsa_code IS NOT NULL
                                                                           ) dp2
                                                                     WHERE dp2.rnk < 2;

                                                                    v_reason_cd := v_reason_cd || ',CPC';
                                                              EXCEPTION
                                                                  WHEN NO_DATA_FOUND THEN NULL;
                                                              END;
                                                         ELSE
                                                              IF (inp_rec.unparsed_custom_address IS NOT NULL)
                                                                 THEN
                                                                       -- DBMS_OUTPUT.PUT_LINE('Trying apply Custom parsing for <' || inp_rec.unparsed_custom_address || '>');
                                                                       /*
                                                                       ** Apply Special Hygiene
                                                                       ** to extract State, City and Postal Code information from
                                                                       ** unparsed custom address
                                                                       */
                                                                       v_wac_country_id := 1; -- Country is defaulted to US
                                                                       v_wac_postal_code := wac_zip(inp_rec.unparsed_custom_address);
                                                                       v_wac_state := wac_state(inp_rec.unparsed_custom_address);
                                                                       -- DBMS_OUTPUT.PUT_LINE('v_wac_postal_code <' || v_wac_postal_code || '>');
                                                                       IF (v_wac_postal_code IS NOT NULL)
                                                                          THEN
                                                                               BEGIN
                                                                                     SELECT dp2.std_place_id
                                                                                       INTO v_std_place_id
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
                                                                                   WHEN NO_DATA_FOUND THEN NULL;
                                                                               END;
                                                                       END IF;

                                                                       IF (v_std_place_id = 0)
                                                                          THEN
                                                                                v_wac_city  := UPPER(wac_city(inp_rec.unparsed_custom_address));
                                                                                IF (v_wac_state IS NOT NULL AND v_wac_city IS NOT NULL)
                                                                                   THEN
                                                                                         -- Wachovia Unaparsed Address didn't match by Postal code
                                                                                         -- So try using extracted state and City
                                                                                         -- Country is defaulted to US
                                                                                         BEGIN
                                                                                               SELECT dp2.std_place_id
                                                                                                 INTO v_std_place_id
                                                                                                 FROM (
                                                                                                        SELECT dp.std_place_id
                                                                                                               -- In case of multiple location matches give least preference to non-metro CMSA
                                                                                                               , ROW_NUMBER() OVER (ORDER BY INSTR(dp.cmsa_code, '9999') ASC) AS rnk
                                                                                                          FROM dm_places dp
                                                                                                         WHERE dp.std_country_id  = v_wac_country_id
                                                                                                           AND dp.std_state       = clean_state(v_wac_country_id, v_wac_state)
                                                                                                           AND dp.std_city        = clean_city(v_wac_city, v_wac_country_id, v_wac_state)
                                                                                                           AND dp.cmsa_code IS NOT NULL
                                                                                                      ) dp2
                                                                                                WHERE dp2.rnk < 2;

                                                                                               v_reason_cd := v_reason_cd || ',WUC';
                                                                                         EXCEPTION
                                                                                             WHEN NO_DATA_FOUND THEN NULL;
                                                                                         END;
                                                                                END IF;
                                                                       END IF;
                                                              END IF;
                                                      END IF;
                                              END IF;
                                      END IF;
                             END CASE;
                        ELSE
                             BEGIN
                                   -- Get Country info for override location
                                   SELECT p.std_country_id
                                     INTO v_ovr_country_id
                                     FROM dm_places p
                                    WHERE p.std_place_id = v_std_place_id
                                      AND p.std_country_id > 0;

                                   IF (v_ovr_country_id != v_std_country_id)
                                      THEN
                                           v_std_country_id := v_ovr_country_id;

                                           CASE (v_ovr_country_id)
                                             WHEN c_us_country_id THEN NULL;
                                             WHEN c_uk_country_id THEN NULL;
                                             WHEN c_nl_country_id THEN NULL;
                                             WHEN c_ca_country_id THEN NULL;
                                             WHEN c_in_country_id THEN NULL;
                                             ELSE
                                                  IF (v_delete_reason_code = 'N')
                                                     THEN
                                                          v_delete_reason_code := 'F';
                                                  END IF;
                                           END CASE;
                                   END IF;
                             EXCEPTION
                                 WHEN NO_DATA_FOUND THEN NULL;
                             END;
                     END IF;
            END IF;

            IF (p_type = 1)
               THEN
                     /*
                     ** First put events after transformations into temp table
                     */
                     INSERT INTO dm_rate_event_t
                     (
                         std_buyerorg_id
                       , std_supplierorg_id
                       , std_job_title_id
                       , std_place_id
                       , std_country_id
                       , transform_reason_codes
                       , buyerorg_id
                       , supplierorg_id
                       , job_level_id
                       , job_level_desc
                       , job_category_id
                       , job_category_desc
                       , job_title
                       , buyerorg_name
                       , supplierorg_name
                       , assignment_id
                       , assignment_type
                       , assignment_rate_edition_id
                       , assignment_edition_id
                       , work_order_version
                       , assignment_start_date
                       , assignment_end_date
                       , rate_event_acceptance_date
                       , rate_event_decision_date
                       , rate_event_start_date
                       , rate_event_end_date
                       , currency_description
                       , reg_bill_rate
                       , ot_bill_rate
                       , dt_bill_rate
                       , buyer_bill_rate
                       , buyer_ot_rate
                       , buyer_dt_rate
                       , supplier_reg_reimb_rate
                       , supplier_ot_reimb_rate
                       , supplier_dt_reimb_rate
                       , reg_pay_rate
                       , ot_pay_rate
                       , dt_pay_rate
                       , address_city
                       , address_state
                       , address_postal_code
                       , address_country_id
                       , source_template_id
                       , job_id
                       , batch_id
                       , load_key
                       , last_update_date
                       , place_id
                       , custom_address_city
                       , custom_address_state
                       , custom_address_postal_code
                       , custom_address_country_id
                       , buyer_address_city
                       , buyer_address_state
                       , buyer_address_postal_code
                       , buyer_address_country_id
                       , unparsed_address
                       , unparsed_custom_address
                       , custom_place_id
                       , fo_source_of_record
                       , rate_unit_type
                       , data_source_code
                       , delete_reason_code
                     )
                     VALUES
                     (
                         inp_rec.new_std_buyerorg_id
                       , inp_rec.new_std_supplierorg_id
                       , v_std_job_title_id
                       , v_std_place_id
                       , v_std_country_id
                       , v_reason_cd
                       , inp_rec.buyerorg_id
                       , inp_rec.supplierorg_id
                       , inp_rec.job_level_id
                       , inp_rec.job_level_desc
                       , inp_rec.job_category_id
                       , inp_rec.job_category_desc
                       , inp_rec.job_title
                       , inp_rec.buyerorg_name
                       , inp_rec.supplierorg_name
                       , inp_rec.assignment_id
                       , inp_rec.assignment_type
                       , inp_rec.assignment_rate_edition_id
                       , inp_rec.assignment_edition_id
                       , inp_rec.work_order_version
                       , inp_rec.assignment_start_date
                       , inp_rec.assignment_end_date
                       , inp_rec.rate_event_acceptance_date
                       , inp_rec.rate_event_decision_date
                       , inp_rec.rate_event_start_date
                       , inp_rec.rate_event_end_date
                       , inp_rec.currency_description
                       , inp_rec.reg_bill_rate
                       , inp_rec.ot_bill_rate
                       , inp_rec.dt_bill_rate
                       , inp_rec.buyer_bill_rate
                       , inp_rec.buyer_ot_rate
                       , inp_rec.buyer_dt_rate
                       , inp_rec.supplier_reg_reimb_rate
                       , inp_rec.supplier_ot_reimb_rate
                       , inp_rec.supplier_dt_reimb_rate
                       , inp_rec.reg_pay_rate
                       , inp_rec.ot_pay_rate
                       , inp_rec.dt_pay_rate
                       , inp_rec.address_city
                       , inp_rec.address_state
                       , inp_rec.address_postal_code
                       , inp_rec.address_country_id
                       , inp_rec.source_template_id
                       , inp_rec.job_id
                       , inp_rec.batch_id
                       , inp_rec.load_key
                       , SYSDATE
                       , inp_rec.place_id
                       , inp_rec.custom_address_city
                       , inp_rec.custom_address_state
                       , inp_rec.custom_address_postal_code
                       , inp_rec.custom_address_country_id
                       , inp_rec.buyer_address_city
                       , inp_rec.buyer_address_state
                       , inp_rec.buyer_address_postal_code
                       , inp_rec.buyer_address_country_id
                       , inp_rec.unparsed_address
                       , inp_rec.unparsed_custom_address
                       , inp_rec.custom_place_id
                       , inp_rec.fo_source_of_record
                       , inp_rec.rate_unit_type
                       , inp_rec.data_source_code
                       , v_delete_reason_code
                     );
               ELSE
                     /*
                     ** See if tranformation came-up with something different
                     ** Update only when something is different
                     */
                     IF (
                             inp_rec.std_place_id        != v_std_place_id
                          OR inp_rec.std_job_title_id    != v_std_job_title_id
                          OR inp_rec.std_supplierorg_id  != inp_rec.new_std_supplierorg_id
                          OR inp_rec.std_buyerorg_id     != inp_rec.new_std_buyerorg_id
                          OR inp_rec.delete_reason_code  != v_delete_reason_code
                          OR inp_rec.std_country_id      != v_std_country_id
                        )
                        THEN
                              UPDATE dm_rate_event_master
                                 SET   std_buyerorg_id        = inp_rec.new_std_buyerorg_id
                                     , std_supplierorg_id     = inp_rec.new_std_supplierorg_id
                                     , std_job_title_id       = v_std_job_title_id
                                     , std_place_id           = v_std_place_id
                                     , std_country_id         = v_std_country_id
                                     , transform_reason_codes = v_reason_cd
                                     , delete_reason_code     = v_delete_reason_code
                                     , batch_id               = p_msg_id
                                     , load_key               = v_update_count + 1
                                     , last_update_date       = SYSDATE
                               WHERE batch_id = inp_rec.batch_id
                                 AND load_key = inp_rec.load_key;

                               v_update_count := v_update_count + 1;
                     END IF;
            END IF;

            IF (v_rec_count = 1000)
               THEN
                     COMMIT;
                     v_processed_rec_count := v_processed_rec_count + v_rec_count;
                     v_rec_count := 0;
            END IF;
      END LOOP;

      COMMIT;
      v_processed_rec_count := v_processed_rec_count + v_rec_count;
      dm_util_log.p_log_msg(p_msg_id, 11, NULL, NULL, 'U');
      IF (p_type = 1)
         THEN
               /*
               ** Move Fully Transformed Events into DM_RATE_EVENT_MASTER table
               ** and all the remaining into DM_RATE_EVENT_Q
               ** respectively depending on the source
               */
               split_rate_events(p_source_code, p_msg_id, p_skip_maint);
               dm_util_log.p_log_msg(p_msg_id, 13, p_source_code || ': ' || v_processed_rec_count || ' Rate Event records processed/inserted', v_crnt_proc_name, 'I');
         ELSE
               dm_util_log.p_log_msg(p_msg_id, 13, p_source_code || ': ' || v_processed_rec_count || ' Rate Event records processed and ' || v_update_count || ' records updated', v_crnt_proc_name, 'I');
      END IF;
      dm_util_log.p_log_msg(p_msg_id, 13, NULL, NULL, 'U');
  END transform_rate_events;

  PROCEDURE split_rate_events
  (
      p_source_code IN VARCHAR2
    , p_msg_id      IN NUMBER
    , p_skip_maint  IN VARCHAR2
  )
  IS
        v_logical_deleted_count NUMBER;
        v_transformed_count NUMBER;
        v_sent_to_quarantine NUMBER;
  BEGIN
        SELECT COUNT(*)
          INTO v_logical_deleted_count
          FROM dm_rate_event_t m
         WHERE m.delete_reason_code <> 'N';

        /*
        ** Move Fully Transformed Events into DM_RATE_EVENT_MASTER table
        */
        INSERT INTO dm_rate_event_master
             (
                 std_buyerorg_id
               , std_supplierorg_id
               , std_job_title_id
               , std_place_id
               , std_country_id
               , transform_reason_codes
               , buyerorg_id
               , supplierorg_id
               , job_level_id
               , job_level_desc
               , job_category_id
               , job_category_desc
               , job_title
               , buyerorg_name
               , supplierorg_name
               , assignment_id
               , assignment_type
               , assignment_rate_edition_id
               , assignment_edition_id
               , work_order_version
               , assignment_start_date
               , assignment_end_date
               , rate_event_acceptance_date
               , rate_event_decision_date
               , rate_event_start_date
               , rate_event_end_date
               , currency_description
               , reg_bill_rate
               , ot_bill_rate
               , dt_bill_rate
               , buyer_bill_rate
               , buyer_ot_rate
               , buyer_dt_rate
               , supplier_reg_reimb_rate
               , supplier_ot_reimb_rate
               , supplier_dt_reimb_rate
               , reg_pay_rate
               , ot_pay_rate
               , dt_pay_rate
               , address_city
               , address_state
               , address_postal_code
               , address_country_id
               , source_template_id
               , job_id
               , batch_id
               , load_key
               , last_update_date
               , place_id
               , custom_address_city
               , custom_address_state
               , custom_address_postal_code
               , custom_address_country_id
               , buyer_address_city
               , buyer_address_state
               , buyer_address_postal_code
               , buyer_address_country_id
               , unparsed_address
               , unparsed_custom_address
               , custom_place_id
               , fo_source_of_record
               , rate_unit_type
               , data_source_code
               , delete_reason_code
             )
        SELECT   m.std_buyerorg_id
               , m.std_supplierorg_id
               , m.std_job_title_id
               , m.std_place_id
               , m.std_country_id
               , m.transform_reason_codes
               , m.buyerorg_id
               , m.supplierorg_id
               , m.job_level_id
               , m.job_level_desc
               , m.job_category_id
               , m.job_category_desc
               , m.job_title
               , m.buyerorg_name
               , m.supplierorg_name
               , m.assignment_id
               , m.assignment_type
               , m.assignment_rate_edition_id
               , m.assignment_edition_id
               , m.work_order_version
               , m.assignment_start_date
               , m.assignment_end_date
               , m.rate_event_acceptance_date
               , m.rate_event_decision_date
               , m.rate_event_start_date
               , m.rate_event_end_date
               , m.currency_description
               , m.reg_bill_rate
               , m.ot_bill_rate
               , m.dt_bill_rate
               , m.buyer_bill_rate
               , m.buyer_ot_rate
               , m.buyer_dt_rate
               , m.supplier_reg_reimb_rate
               , m.supplier_ot_reimb_rate
               , m.supplier_dt_reimb_rate
               , m.reg_pay_rate
               , m.ot_pay_rate
               , m.dt_pay_rate
               , m.address_city
               , m.address_state
               , m.address_postal_code
               , m.address_country_id
               , m.source_template_id
               , m.job_id
               , m.batch_id
               , m.load_key
               , m.last_update_date
               , m.place_id
               , m.custom_address_city
               , m.custom_address_state
               , m.custom_address_postal_code
               , m.custom_address_country_id
               , m.buyer_address_city
               , m.buyer_address_state
               , m.buyer_address_postal_code
               , m.buyer_address_country_id
               , m.unparsed_address
               , m.unparsed_custom_address
               , m.custom_place_id
               , m.fo_source_of_record
               , m.rate_unit_type
               , m.data_source_code
               , m.delete_reason_code
          FROM dm_rate_event_t m
         WHERE m.delete_reason_code <> 'N'
            OR (
                     m.delete_reason_code = 'N'
                 AND m.std_place_id        > 0
                 AND m.std_buyerorg_id     > 0
                 AND m.std_supplierorg_id  > 0
                 AND m.std_job_title_id    > 0
               );

        v_transformed_count := SQL%ROWCOUNT - v_logical_deleted_count;

                /*
                ** Move all the remaining (partially transformed and un-transformed)
                ** rate events into DM_RATE_EVENT_Q
                */
                IF (p_skip_maint = 'N')
                   THEN
                        EXECUTE IMMEDIATE 'ALTER TABLE dm_rate_event_q TRUNCATE PARTITION ' || p_source_code || '_Q DROP STORAGE';
                END IF;
                INSERT /*+ APPEND(t) */ INTO dm_rate_event_q t
                     (
                         std_buyerorg_id
                       , std_supplierorg_id
                       , std_job_title_id
                       , std_place_id
                       , std_country_id
                       , transform_reason_codes
                       , buyerorg_id
                       , supplierorg_id
                       , job_level_id
                       , job_level_desc
                       , job_category_id
                       , job_category_desc
                       , job_title
                       , buyerorg_name
                       , supplierorg_name
                       , assignment_id
                       , assignment_type
                       , assignment_rate_edition_id
                       , assignment_edition_id
                       , work_order_version
                       , assignment_start_date
                       , assignment_end_date
                       , rate_event_acceptance_date
                       , rate_event_decision_date
                       , rate_event_start_date
                       , rate_event_end_date
                       , currency_description
                       , reg_bill_rate
                       , ot_bill_rate
                       , dt_bill_rate
                       , buyer_bill_rate
                       , buyer_ot_rate
                       , buyer_dt_rate
                       , supplier_reg_reimb_rate
                       , supplier_ot_reimb_rate
                       , supplier_dt_reimb_rate
                       , reg_pay_rate
                       , ot_pay_rate
                       , dt_pay_rate
                       , address_city
                       , address_state
                       , address_postal_code
                       , address_country_id
                       , source_template_id
                       , job_id
                       , batch_id
                       , load_key
                       , last_update_date
                       , place_id
                       , custom_address_city
                       , custom_address_state
                       , custom_address_postal_code
                       , custom_address_country_id
                       , buyer_address_city
                       , buyer_address_state
                       , buyer_address_postal_code
                       , buyer_address_country_id
                       , unparsed_address
                       , unparsed_custom_address
                       , custom_place_id
                       , fo_source_of_record
                       , rate_unit_type
                       , data_source_code
                       , delete_reason_code
                     )
                SELECT   m.std_buyerorg_id
                       , m.std_supplierorg_id
                       , m.std_job_title_id
                       , m.std_place_id
                       , m.std_country_id
                       , m.transform_reason_codes
                       , m.buyerorg_id
                       , m.supplierorg_id
                       , m.job_level_id
                       , m.job_level_desc
                       , m.job_category_id
                       , m.job_category_desc
                       , m.job_title
                       , m.buyerorg_name
                       , m.supplierorg_name
                       , m.assignment_id
                       , m.assignment_type
                       , m.assignment_rate_edition_id
                       , m.assignment_edition_id
                       , m.work_order_version
                       , m.assignment_start_date
                       , m.assignment_end_date
                       , m.rate_event_acceptance_date
                       , m.rate_event_decision_date
                       , m.rate_event_start_date
                       , m.rate_event_end_date
                       , m.currency_description
                       , m.reg_bill_rate
                       , m.ot_bill_rate
                       , m.dt_bill_rate
                       , m.buyer_bill_rate
                       , m.buyer_ot_rate
                       , m.buyer_dt_rate
                       , m.supplier_reg_reimb_rate
                       , m.supplier_ot_reimb_rate
                       , m.supplier_dt_reimb_rate
                       , m.reg_pay_rate
                       , m.ot_pay_rate
                       , m.dt_pay_rate
                       , m.address_city
                       , m.address_state
                       , m.address_postal_code
                       , m.address_country_id
                       , m.source_template_id
                       , m.job_id
                       , m.batch_id
                       , m.load_key
                       , m.last_update_date
                       , m.place_id
                       , m.custom_address_city
                       , m.custom_address_state
                       , m.custom_address_postal_code
                       , m.custom_address_country_id
                       , m.buyer_address_city
                       , m.buyer_address_state
                       , m.buyer_address_postal_code
                       , m.buyer_address_country_id
                       , m.unparsed_address
                       , m.unparsed_custom_address
                       , m.custom_place_id
                       , m.fo_source_of_record
                       , m.rate_unit_type
                       , m.data_source_code
                       , m.delete_reason_code
                  FROM dm_rate_event_t m
                 WHERE m.data_source_code = p_source_code
                   AND m.delete_reason_code = 'N'
                   AND (
                            m.std_place_id        = 0
                         OR m.std_buyerorg_id     = 0
                         OR m.std_supplierorg_id  = 0
                         OR m.std_job_title_id    = 0
                       );
        v_sent_to_quarantine := SQL%ROWCOUNT;

       UPDATE dm_rate_event_stats
          SET   placed_in_quarantine = v_sent_to_quarantine
              , transformed_events = v_transformed_count
              , logically_deleted_events = v_logical_deleted_count
        WHERE data_source_code = p_source_code
          AND batch_id = p_msg_id;

        COMMIT;

        EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_rate_event_t';
  END split_rate_events;

  PROCEDURE update_rate_events
  IS
     ln_msg_id        NUMBER;
     v_crnt_proc_name user_jobs.what%TYPE := 'DM_RATE_EVENT.UPDATE_RATE_EVENTS';
  BEGIN
     --
     -- Get the sequence required for logging messages
     --
     SELECT dm_msg_log_seq.NEXTVAL INTO ln_msg_id FROM DUAL;

     transform_rate_events(2, 'DW-REFRESH', ln_msg_id);
  END update_rate_events;

    PROCEDURE reprocess_foreign_rate_events
    IS
       v_rate_event_count NUMBER := 0;
       v_rec_count        NUMBER := 0;
    BEGIN

     --dm_cube_utils.make_indexes_visible;
     EXECUTE IMMEDIATE 'ALTER SESSION SET optimizer_use_invisible_indexes = true';

     INSERT /*+ APPEND(t) */ INTO dm_rate_event_q t
          (
              std_buyerorg_id
            , std_supplierorg_id
            , std_job_title_id
            , std_place_id
            , std_country_id
            , transform_reason_codes
            , buyerorg_id
            , supplierorg_id
            , job_level_id
            , job_level_desc
            , job_category_id
            , job_category_desc
            , job_title
            , buyerorg_name
            , supplierorg_name
            , assignment_id
            , assignment_type
            , assignment_rate_edition_id
            , assignment_edition_id
            , work_order_version
            , assignment_start_date
            , assignment_end_date
            , rate_event_acceptance_date
            , rate_event_decision_date
            , rate_event_start_date
            , rate_event_end_date
            , currency_description
            , reg_bill_rate
            , ot_bill_rate
            , dt_bill_rate
            , buyer_bill_rate
            , buyer_ot_rate
            , buyer_dt_rate
            , supplier_reg_reimb_rate
            , supplier_ot_reimb_rate
            , supplier_dt_reimb_rate
            , reg_pay_rate
            , ot_pay_rate
            , dt_pay_rate
            , address_city
            , address_state
            , address_postal_code
            , address_country_id
            , source_template_id
            , job_id
            , batch_id
            , load_key
            , last_update_date
            , place_id
            , custom_address_city
            , custom_address_state
            , custom_address_postal_code
            , custom_address_country_id
            , buyer_address_city
            , buyer_address_state
            , buyer_address_postal_code
            , buyer_address_country_id
            , unparsed_address
            , unparsed_custom_address
            , custom_place_id
            , fo_source_of_record
            , rate_unit_type
            , data_source_code
            , delete_reason_code
          )
     SELECT   m.std_buyerorg_id
            , m.std_supplierorg_id
            , m.std_job_title_id
            , m.std_place_id
            , m.std_country_id
            , m.transform_reason_codes
            , m.buyerorg_id
            , m.supplierorg_id
            , m.job_level_id
            , m.job_level_desc
            , m.job_category_id
            , m.job_category_desc
            , m.job_title
            , m.buyerorg_name
            , m.supplierorg_name
            , m.assignment_id
            , m.assignment_type
            , m.assignment_rate_edition_id
            , m.assignment_edition_id
            , m.work_order_version
            , m.assignment_start_date
            , m.assignment_end_date
            , m.rate_event_acceptance_date
            , m.rate_event_decision_date
            , m.rate_event_start_date
            , m.rate_event_end_date
            , m.currency_description
            , m.reg_bill_rate
            , m.ot_bill_rate
            , m.dt_bill_rate
            , m.buyer_bill_rate
            , m.buyer_ot_rate
            , m.buyer_dt_rate
            , m.supplier_reg_reimb_rate
            , m.supplier_ot_reimb_rate
            , m.supplier_dt_reimb_rate
            , m.reg_pay_rate
            , m.ot_pay_rate
            , m.dt_pay_rate
            , m.address_city
            , m.address_state
            , m.address_postal_code
            , m.address_country_id
            , m.source_template_id
            , m.job_id
            , m.batch_id
            , m.load_key
            , m.last_update_date
            , m.place_id
            , m.custom_address_city
            , m.custom_address_state
            , m.custom_address_postal_code
            , m.custom_address_country_id
            , m.buyer_address_city
            , m.buyer_address_state
            , m.buyer_address_postal_code
            , m.buyer_address_country_id
            , m.unparsed_address
            , m.unparsed_custom_address
            , m.custom_place_id
            , m.fo_source_of_record
            , m.rate_unit_type
            , m.data_source_code
            , m.delete_reason_code
       FROM dm_rate_event_master m
      WHERE m.delete_reason_code = 'F';

      v_rec_count := SQL%ROWCOUNT;

     DELETE dm_rate_event_master m
      WHERE m.delete_reason_code = 'F';

     v_rate_event_count := SQL%ROWCOUNT;
     IF (v_rec_count = v_rate_event_count)
        THEN
             COMMIT;
             reprocess_quarantine;
        ELSE
             ROLLBACK;
     END IF;
    END reprocess_foreign_rate_events;

    PROCEDURE reprocess_quarantine
    IS
     ln_msg_id        NUMBER;
    BEGIN
     --
     -- Get the sequence required for logging messages
     --
     SELECT dm_msg_log_seq.NEXTVAL INTO ln_msg_id FROM DUAL;

     --
     -- Process all REGULAR rate_event records from dm_rate_event_q
     --
     EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_rate_event_tmp';
     transform_rate_events(1, 'REGULAR', ln_msg_id);
     populate_weighted_events(ln_msg_id);

     --
     -- Get the sequence required for logging messages
     --
     SELECT dm_msg_log_seq.NEXTVAL INTO ln_msg_id FROM DUAL;

     --
     -- Process all WACHOVIA rate_event records from dm_rate_event_q
     --
     EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_rate_event_tmp';
     transform_rate_events(1, 'WACHOVIA', ln_msg_id);
     populate_weighted_events(ln_msg_id);

    END reprocess_quarantine;

    FUNCTION get_transformed_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    )
    RETURN weventTab
    PIPELINED
    AS
          c1       wevent_curs;
          vInpRecs weventTab;
    BEGIN
          /*
          ** Level is no longer required to generate weighted rate events
          **
          */
          OPEN c1 FOR SELECT
                               m.data_source_code
                             , p.rate_source_pref AS rate_event_source
                             , m.std_country_id
                             , CAST (0 AS NUMBER(6)) AS month_number
                             , CAST (NULL AS VARCHAR2(1)) AS month_type
                             , m.assignment_id
                             , m.std_job_title_id
                             , m.std_place_id
                             , CAST (NULL AS DATE) AS first_expenditure_date
                             , CAST (NULL AS DATE) AS last_expenditure_date
                             , CAST (0.00 AS NUMBER(4,2)) AS proximity_weight
                             , CAST (0.00 AS NUMBER(6,2)) AS duration_units
                             , m.reg_bill_rate/DECODE(m.rate_unit_type, 'Hourly', 1, 'Monthly', c_monthly_hours, 'Daily', c_daily_hours, 'Weekly', c_weekly_hours, 'Annual', c_annual_hours, 1) as reg_bill_rate
                             , m.assignment_type
                             , m.currency_description
                             , m.job_title
                             , CAST (NULL AS VARCHAR2(250 CHAR)) AS std_job_title_desc
                             , CAST (0 AS NUMBER) AS std_job_category_id
                             , CAST (NULL AS VARCHAR2(250 CHAR)) AS std_job_category_desc
                             , CAST (NULL AS VARCHAR2(6 CHAR)) AS cmsa_code
                             , CAST (NULL AS VARCHAR2(128 CHAR)) AS cmsa_name
                             , m.batch_id
                             , m.load_key
                             , m.work_order_version AS assignment_seq_number
                             , m.buyer_bill_rate/DECODE(m.rate_unit_type, 'Hourly', 1, 'Monthly', c_monthly_hours, 'Daily', c_daily_hours, 'Weekly', c_weekly_hours, 'Annual', c_annual_hours, 1) AS buyer_bill_rate
                             , m.reg_pay_rate/DECODE(m.rate_unit_type, 'Hourly', 1, 'Monthly', c_monthly_hours, 'Daily', c_daily_hours, 'Weekly', c_weekly_hours, 'Annual', c_annual_hours, 1) AS reg_pay_rate
                             , m.rate_event_decision_date
                             , m.rate_event_start_date
                             , m.rate_event_end_date
                             , CAST (SYSDATE AS DATE) AS last_update_date
                             , m.std_buyerorg_id
                        FROM dm_rate_event_master m, fo_buyers_map p
                       WHERE p.data_source_code = m.data_source_code
                         AND p.buyerorg_id = m.buyerorg_id
                         AND p.rate_source_pref = 'FO Contract'
                         AND m.delete_reason_code = 'N'
                         AND m.std_country_id      > 0
                         AND m.std_place_id        > 0
                         AND m.std_buyerorg_id     > 0
                         AND m.std_supplierorg_id  > 0
                         AND m.std_job_title_id    > 0
                         AND m.rate_event_end_date < TO_DATE('21000101', 'YYYYMMDD')
                         AND m.batch_id = p_batch_id;
          LOOP
               FETCH c1 BULK COLLECT INTO vInpRecs LIMIT 50000;
               FOR i IN 1 .. vInpRecs.COUNT
               LOOP
                    PIPE ROW(vInpRecs(i));
               END LOOP;
               EXIT WHEN c1%NOTFOUND;
          END LOOP;
          CLOSE c1;
    END get_transformed_events;

    FUNCTION get_monthly_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    )
    RETURN weventTab
    PIPELINED
    AS
          c1       wevent_curs;
          vInpRecs weventTab;

          v_crnt_dt  DATE;
          v_eom_dt   DATE;
          v_months   NUMBER(8,4);
          v_hours    NUMBER(10,4);
          v_days_since_decision    NUMBER(12,4);
          j PLS_INTEGER;
    BEGIN
          OPEN c1 FOR SELECT
                               t.data_source_code
                             , t.rate_event_source
                             , t.std_country_id
                             , t.month_number
                             , t.month_type
                             , t.assignment_id
                             , t.std_job_title_id
                             , t.std_place_id
                             , t.first_expenditure_date
                             , t.last_expenditure_date
                             , t.proximity_weight
                             , t.duration_units
                             , t.reg_bill_rate
                             , t.assignment_type
                             , t.currency_description
                             , t.job_title
                             , t.std_job_title_desc
                             , t.std_job_category_id
                             , t.std_job_category_desc
                             , s.cmsa_code
                             , s.cmsa_name
                             , t.batch_id
                             , t.load_key
                             , NVL(t.assignment_seq_number, t.ea_seq_number) AS assignment_seq_number
                             , t.buyer_bill_rate
                             , t.reg_pay_rate
                             , t.rate_event_decision_date
                             , t.rate_event_start_date
                             , t.rate_event_end_date
                             , t.last_update_date
                             , t.std_buyerorg_id
                        FROM (
                               SELECT   x.std_country_id
                                      , x.month_type
                                      , x.month_number
                                      , x.assignment_id
                                      , x.assignment_type
                                      , x.assignment_seq_number
                                      , CAST (ROW_NUMBER() OVER (PARTITION by x.assignment_id, x.assignment_type, x.data_source_code ORDER BY x.rate_event_decision_date) AS NUMBER) AS ea_seq_number
                                      , x.std_job_title_id
                                      , x.data_source_code
                                      , x.duration_units
                                      , x.proximity_weight
                                      , x.std_job_title_desc
                                      , x.std_place_id
                                      , x.cmsa_code
                                      , x.cmsa_name
                                      , x.std_job_category_id
                                      , x.std_job_category_desc
                                      , x.reg_bill_rate
                                      , x.buyer_bill_rate
                                      , x.reg_pay_rate
                                      , x.rate_event_decision_date
                                      , x.rate_event_start_date
                                      , x.rate_event_end_date
                                      , x.currency_description
                                      , x.job_title
                                      , x.batch_id
                                      , x.load_key
                                      , x.last_update_date
                                      , x.rate_event_source
                                      , x.first_expenditure_date
                                      , x.last_expenditure_date
                                      , x.std_buyerorg_id
                                 FROM TABLE(get_transformed_events(p_batch_id)) x
                             ) t, dm_places p, dm_cmsa s
                       WHERE p.std_place_id = t.std_place_id
                         AND s.cmsa_code (+) = p.cmsa_code;
          LOOP
               FETCH c1 BULK COLLECT INTO vInpRecs LIMIT 50000;
               FOR i IN 1 .. vInpRecs.COUNT
               LOOP
                     /*
                     ** Split Rate Event by Calendar monthly buckets
                     ** and also calculate proximity weights
                     */
                     v_crnt_dt  := vInpRecs(i).rate_event_decision_date;
                     vInpRecs(i).month_type := 'C';
                     IF (v_crnt_dt < c_start_date)
                        THEN
                              v_crnt_dt := c_start_date;
                     END IF;

                     WHILE(v_crnt_dt <= vInpRecs(i).rate_event_end_date)
                     LOOP
                           vInpRecs(i).proximity_weight := 0;
                           v_eom_dt := TRUNC(ADD_MONTHS(v_crnt_dt, 1), 'MONTH')-1;
                           IF (v_eom_dt > vInpRecs(i).rate_event_end_date)
                              THEN
                                    v_eom_dt := vInpRecs(i).rate_event_end_date;
                           END IF;
                           -- DBMS_OUTPUT.PUT_LINE('Start = ' || v_crnt_dt);
                           -- DBMS_OUTPUT.PUT_LINE('End = ' || v_eom_dt);
                           v_months := ROUND(MONTHS_BETWEEN(v_eom_dt + 1, v_crnt_dt), 4);
                           -- DBMS_OUTPUT.PUT_LINE('Month key - ' || TO_CHAR(v_crnt_dt, 'YYYYMM') || ' months = ' || v_months || ', hours = ' || v_hours);
                           vInpRecs(i).month_number     := TO_NUMBER(TO_CHAR(v_crnt_dt, 'YYYYMM'));
                           vInpRecs(i).duration_units   := v_months * c_monthly_hours;
                           v_days_since_decision := v_crnt_dt - vInpRecs(i).rate_event_decision_date;

                           IF (v_days_since_decision < 0 OR proxWeights.COUNT = 0)
                              THEN
                                    vInpRecs(i).proximity_weight := 1;
                              ELSE
                                    j := 1;
                                    WHILE (vInpRecs(i).proximity_weight = 0 AND j <= proxWeights.COUNT)
                                    LOOP
                                          -- DBMS_OUTPUT.PUT_LINE('looking at  = ' || proxWeights(j).days_range_begin || '-' || proxWeights(j).days_range_end);
                                          IF (
                                                    v_days_since_decision <= proxWeights(j).days_range_end
                                               AND
                                                    v_days_since_decision >= proxWeights(j).days_range_begin
                                             )
                                             THEN
                                                   vInpRecs(i).proximity_weight := proxWeights(j).proximity_weight;
                                          END IF;
                                          j := j + 1;
                                    END LOOP;
                                    IF (vInpRecs(i).proximity_weight = 0)
                                       THEN
                                             vInpRecs(i).proximity_weight := 1;
                                    END IF;
                           END IF;
                           PIPE ROW(vInpRecs(i));
                           v_crnt_dt := v_eom_dt + 1;
                     END LOOP;

                     /*
                     ** Split Rate Event by Index monthly buckets
                     ** and also calculate proximity weights
                     */
                     v_crnt_dt  := vInpRecs(i).rate_event_decision_date;
                     vInpRecs(i).month_type := 'I';
                     IF (v_crnt_dt < c_start_date)
                        THEN
                              v_crnt_dt := c_start_date;
                     END IF;

                     WHILE(v_crnt_dt <= vInpRecs(i).rate_event_end_date)
                     LOOP
                           vInpRecs(i).proximity_weight := 0;
                           IF (TO_NUMBER(TO_CHAR(v_crnt_dt, 'DD')) > 20)
                              THEN
                                    v_eom_dt := ADD_MONTHS(TRUNC(v_crnt_dt, 'MONTH'), 1)+19;
                              ELSE
                                    v_eom_dt := TRUNC(v_crnt_dt, 'MONTH')+19;
                           END IF;

                           IF (v_eom_dt > vInpRecs(i).rate_event_end_date)
                              THEN
                                    v_eom_dt := vInpRecs(i).rate_event_end_date;
                           END IF;
                           -- DBMS_OUTPUT.PUT_LINE('Start = ' || v_crnt_dt);
                           -- DBMS_OUTPUT.PUT_LINE('End = ' || v_eom_dt);
                           v_months := ROUND(MONTHS_BETWEEN(v_eom_dt + 1, v_crnt_dt), 4);
                           -- DBMS_OUTPUT.PUT_LINE('Index Month key - ' || TO_CHAR(v_eom_dt, 'YYYYMM') || ' months = ' || v_months || ', hours = ' || v_hours);
                           IF (TO_NUMBER(TO_CHAR(v_eom_dt, 'DD')) > 20)
                               THEN
                                     vInpRecs(i).month_number     := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(v_eom_dt, 'MONTH'), 1), 'YYYYMM'));
                               ELSE
                                     vInpRecs(i).month_number     := TO_NUMBER(TO_CHAR(v_eom_dt, 'YYYYMM'));
                           END IF;
                           vInpRecs(i).duration_units   := v_months * c_monthly_hours;
                           v_days_since_decision := v_crnt_dt - vInpRecs(i).rate_event_decision_date;

                           IF (v_days_since_decision < 0 OR proxWeights.COUNT = 0)
                              THEN
                                    vInpRecs(i).proximity_weight := 1;
                              ELSE
                                    j := 1;
                                    WHILE (vInpRecs(i).proximity_weight = 0 AND j <= proxWeights.COUNT)
                                    LOOP
                                          -- DBMS_OUTPUT.PUT_LINE('looking at  = ' || proxWeights(j).days_range_begin || '-' || proxWeights(j).days_range_end);
                                          IF (
                                                    v_days_since_decision <= proxWeights(j).days_range_end
                                               AND
                                                    v_days_since_decision >= proxWeights(j).days_range_begin
                                             )
                                             THEN
                                                   vInpRecs(i).proximity_weight := proxWeights(j).proximity_weight;
                                          END IF;
                                          j := j + 1;
                                    END LOOP;
                                    IF (vInpRecs(i).proximity_weight = 0)
                                       THEN
                                             vInpRecs(i).proximity_weight := 1;
                                    END IF;
                           END IF;
                           PIPE ROW(vInpRecs(i));
                           v_crnt_dt := v_eom_dt + 1;
                     END LOOP;
               END LOOP;
               EXIT WHEN c1%NOTFOUND;
          END LOOP;
          CLOSE c1;
    END get_monthly_events;

    FUNCTION get_weighted_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    )
    RETURN weventTab
    PIPELINED
    AS
          c1       wevent_curs;
          vInpRecs weventTab;
    BEGIN
          OPEN c1 FOR SELECT
                               m.data_source_code
                             , m.rate_event_source
                             , m.std_country_id
                             , m.month_number
                             , m.month_type
                             , m.assignment_id
                             , m.std_job_title_id
                             , m.std_place_id
                             , m.first_expenditure_date
                             , m.last_expenditure_date
                             , m.proximity_weight
                             , m.duration_units
                             , m.reg_bill_rate
                             , m.assignment_type
                             , m.currency_description
                             , m.job_title
                             , jt.std_job_title_desc
                             , jt.std_job_category_id
                             , jc.std_job_category_desc
                             , m.cmsa_code
                             , m.cmsa_name
                             , m.batch_id
                             , m.load_key
                             , m.assignment_seq_number
                             , m.buyer_bill_rate
                             , m.reg_pay_rate
                             , m.rate_event_decision_date
                             , m.rate_event_start_date
                             , m.rate_event_end_date
                             , m.last_update_date
                             , m.std_buyerorg_id
                        FROM TABLE(get_monthly_events(p_batch_id)) m, dm_job_titles jt, dm_job_category jc
                       WHERE jt.std_job_title_id = m.std_job_title_id
                         AND jt.is_deleted = 'N'
                         AND jt.std_job_category_id > 0
                         AND jc.std_job_category_id = jt.std_job_category_id;
          LOOP
               FETCH c1 BULK COLLECT INTO vInpRecs LIMIT 50000;
               FOR i IN 1 .. vInpRecs.COUNT
               LOOP
                    PIPE ROW(vInpRecs(i));
               END LOOP;
               EXIT WHEN c1%NOTFOUND;
          END LOOP;
          CLOSE c1;
    END get_weighted_events;

    PROCEDURE populate_weighted_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    )
    IS
    	  lv_db_err_msg        VARCHAR2(2000) := NULL;
    BEGIN

          INSERT INTO dm_weighted_rate_events t
          (
              std_country_id
            , month_type
            , month_number
            , assignment_id
            , assignment_type
            , assignment_seq_number
            , std_job_title_id
            , data_source_code
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
            , rate_event_source
            , first_expenditure_date
            , last_expenditure_date
            , std_buyerorg_id
          )
          SELECT   s.std_country_id
                 , s.month_type
                 , s.month_number
                 , s.assignment_id
                 , s.assignment_type
                 , s.assignment_seq_number
                 , s.std_job_title_id
                 , s.data_source_code
                 , s.duration_units
                 , s.proximity_weight
                 , s.std_job_title_desc
                 , s.std_place_id
                 , s.cmsa_code
                 , s.cmsa_name
                 , s.std_job_category_id
                 , s.std_job_category_desc
                 , s.reg_bill_rate
                 , s.buyer_bill_rate
                 , s.reg_pay_rate
                 , s.rate_event_decision_date
                 , s.rate_event_start_date
                 , s.rate_event_end_date
                 , s.currency_description
                 , s.job_title
                 , s.batch_id
                 , s.load_key
                 , s.last_update_date
                 , s.rate_event_source
                 , s.first_expenditure_date
                 , s.last_expenditure_date
                 , s.std_buyerorg_id
            FROM TABLE(get_weighted_events(p_batch_id)) s;

          COMMIT;
    EXCEPTION
          WHEN OTHERS THEN
               lv_db_err_msg := 'Unable to generate weighted rate events for batch_id = ' || p_batch_id || ' due to ' || SQLERRM;
               ROLLBACK;
               DBMS_OUTPUT.PUT_LINE(lv_db_err_msg);
               RAISE_APPLICATION_ERROR(-20502, lv_db_err_msg);
    END populate_weighted_events;

    PROCEDURE redo_batch_weighted_events
    (
        p_batch_id IN dm_rate_event_master.batch_id%TYPE
    )
    IS
    BEGIN
          DELETE dm_weighted_rate_events
           WHERE batch_id IS NOT NULL
             AND batch_id = p_batch_id;

          populate_weighted_events(p_batch_id);

          COMMIT;
    EXCEPTION
          WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Unable to process batch_id = ' || p_batch_id || ' due to ' || SQLERRM);
    END redo_batch_weighted_events;

    PROCEDURE redo_all_weighted_events
    IS
      CURSOR all_batches IS
             SELECT DISTINCT batch_id
               FROM dm_rate_event_master;
    BEGIN
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_weighted_rate_events';
          FOR batch_list IN all_batches
          LOOP
               populate_weighted_events(batch_list.batch_id);
          END LOOP;
    END redo_all_weighted_events;

    PROCEDURE reprocess_rate_events
    IS
      CURSOR all_batches IS
             SELECT DISTINCT data_source_code, batch_id
               FROM dm_rate_event_r
              ORDER BY batch_id;

          v_rate_event_count NUMBER := 0;
          v_rec_count        NUMBER := 0;
    BEGIN
          EXECUTE IMMEDIATE 'ALTER SESSION SET "_b_tree_bitmap_plans"=false';
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_rate_event_r';

          SELECT COUNT(*)
            INTO v_rate_event_count
            FROM dm_rate_event_master;

          INSERT INTO dm_rate_event_r t
          SELECT e.*
            FROM dm_rate_event_master e;
          v_rec_count := SQL%ROWCOUNT;

          IF (v_rec_count = v_rate_event_count)
             THEN
                  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_rate_event_master';
                  EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_weighted_rate_events';
                  FOR batch_list IN all_batches
                  LOOP
                       EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_rate_event_tmp';

                       INSERT INTO fo_rate_event_tmp t
                       (
                                buyerorg_id
                              , supplierorg_id
                              , job_level_id
                              , job_level_desc
                              , job_category_id
                              , job_category_desc
                              , job_title
                              , buyerorg_name
                              , supplierorg_name
                              , assignment_id
                              , assignment_type
                              , assignment_rate_edition_id
                              , assignment_edition_id
                              , work_order_version
                              , assignment_start_date
                              , assignment_end_date
                              , rate_event_acceptance_date
                              , rate_event_start_date
                              , rate_event_end_date
                              , currency_description
                              , reg_bill_rate
                              , ot_bill_rate
                              , dt_bill_rate
                              , buyer_bill_rate
                              , buyer_ot_rate
                              , buyer_dt_rate
                              , supplier_reg_reimb_rate
                              , supplier_ot_reimb_rate
                              , supplier_dt_reimb_rate
                              , reg_pay_rate
                              , ot_pay_rate
                              , dt_pay_rate
                              , place_id
                              , address_city
                              , address_state
                              , address_postal_code
                              , address_country_id
                              , source_template_id
                              , job_id
                              , batch_id
                              , load_key
                              , custom_address_city
                              , custom_address_state
                              , custom_address_postal_code
                              , custom_address_country_id
                              , buyer_address_city
                              , buyer_address_state
                              , buyer_address_postal_code
                              , buyer_address_country_id
                              , unparsed_address
                              , unparsed_custom_address
                              , custom_place_id
                              , fo_source_of_record
                              , rate_unit_type
                              , data_source_code
                       )
                       SELECT   q.buyerorg_id
                              , q.supplierorg_id
                              , q.job_level_id
                              , q.job_level_desc
                              , q.job_category_id
                              , q.job_category_desc
                              , q.job_title
                              , q.buyerorg_name
                              , q.supplierorg_name
                              , q.assignment_id
                              , q.assignment_type
                              , q.assignment_rate_edition_id
                              , q.assignment_edition_id
                              , q.work_order_version
                              , q.assignment_start_date
                              , q.assignment_end_date
                              , q.rate_event_acceptance_date
                              , q.rate_event_start_date
                              , q.rate_event_end_date
                              , q.currency_description
                              , q.reg_bill_rate
                              , q.ot_bill_rate
                              , q.dt_bill_rate
                              , q.buyer_bill_rate
                              , q.buyer_ot_rate
                              , q.buyer_dt_rate
                              , q.supplier_reg_reimb_rate
                              , q.supplier_ot_reimb_rate
                              , q.supplier_dt_reimb_rate
                              , q.reg_pay_rate
                              , q.ot_pay_rate
                              , q.dt_pay_rate
                              , q.place_id
                              , q.address_city
                              , q.address_state
                              , q.address_postal_code
                              , q.address_country_id
                              , q.source_template_id
                              , q.job_id
                              , q.batch_id
                              , q.load_key
                              , q.custom_address_city
                              , q.custom_address_state
                              , q.custom_address_postal_code
                              , q.custom_address_country_id
                              , q.buyer_address_city
                              , q.buyer_address_state
                              , q.buyer_address_postal_code
                              , q.buyer_address_country_id
                              , q.unparsed_address
                              , q.unparsed_custom_address
                              , q.custom_place_id
                              , q.fo_source_of_record
                              , q.rate_unit_type
                              , q.data_source_code
                         FROM dm_rate_event_r q
                        WHERE q.batch_id = batch_list.batch_id
                          AND q.data_source_code = batch_list.data_source_code;

                       COMMIT;

                       transform_rate_events     (1, batch_list.data_source_code, batch_list.batch_id);
                       populate_weighted_events(batch_list.batch_id);

                       COMMIT;
                  END LOOP;
          END IF;
    END reprocess_rate_events;

    PROCEDURE re_extract_rate_events
    (
      p_source_code IN VARCHAR2
    )
    IS
         TYPE dateTab IS TABLE OF VARCHAR2(16);
         TYPE numTab  IS TABLE OF NUMBER;

         v_sql          VARCHAR2(4096);
         v_link_name    VARCHAR2(16);
         v_prev_cutoff  VARCHAR2(16);
         v_group_id     numTab;
         v_from_date    dateTab;
         v_cutoff_date  dateTab;
         v_msg_id       NUMBER;
         v_err_num      NUMBER;
         v_err_msg      VARCHAR2(4000)  := NULL;
         v_ea_count     NUMBER;
         v_wo_count     NUMBER;
    BEGIN
         dm_rate_event.drop_job_indexes;
         v_link_name := get_link_name(p_source_code);

         v_sql :='
         SELECT   group_id, TO_CHAR(range_low, ''YYYYMMDDHH24MISS'') range_low
                , TO_CHAR(cut_off, ''YYYYMMDDHH24MISS'') cut_off
           FROM (
                  SELECT   group_id, range_low, range_high
                         , LEAD(range_low, 1, range_high+(1/86400)) OVER (ORDER BY range_low) cut_off, cnt
                    FROM (
                           SELECT   group_id, MIN(create_date) AS range_low
                                  , MAX(create_date) AS  range_high, count(*) AS cnt
                             FROM (
                                    SELECT ae1.create_date, NTILE(50) OVER(ORDER BY ae1.create_date) AS group_id
                                      FROM   assignment_edition@LNK ae1
                                     WHERE NVL(valid_to_date, create_date) >= TO_DATE(''20070101'', ''YYYYMMDD'')
                                       AND create_date < SYSDATE-0.291667
                                  )
                            GROUP BY group_id
                         )
                )
          ORDER BY group_id';

         v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
         EXECUTE IMMEDIATE v_sql BULK COLLECT INTO v_group_id, v_from_date, v_cutoff_date;
         FOR i IN 1 .. v_group_id.COUNT
         LOOP
               IF (i = 1)
                  THEN
                        UPDATE dm_cube_objects
                           SET   last_identifier  = TO_NUMBER(v_from_date(i))
                               , last_update_date = SYSDATE
                         WHERE object_name IN ('WO_RATE_EVENT_ID', 'EA_RATE_EVENT_ID')
                           AND object_source_code = p_source_code;
               END IF;

               DBMS_OUTPUT.PUT_LINE('group_id ' || v_group_id(i) || ' ' || v_from_date(i) || ' to ' || v_cutoff_date(i));
               --
               -- Get the sequence required for logging messages
               --
               SELECT dm_msg_log_seq.NEXTVAL INTO v_msg_id FROM DUAL;
               get_new_rate_events(v_msg_id, v_cutoff_date(i), v_err_num, v_err_msg, v_ea_count, v_wo_count, p_source_code, v_prev_cutoff);
               v_prev_cutoff := v_from_date(i);
               pull_and_transform(p_source_code, v_msg_id, v_prev_cutoff, v_cutoff_date(i),'Y');

               /*
               ** Update Workorder specific parameter
               ** for next DM refresh process
               */
               UPDATE dm_cube_objects
                  SET   last_identifier  = TO_NUMBER(v_cutoff_date(i))
                      , last_update_date = SYSDATE
                WHERE object_name IN ('WO_RATE_EVENT_ID', 'EA_RATE_EVENT_ID')
                  AND object_source_code = p_source_code;

               COMMIT;
         END LOOP;
         dm_rate_event.create_job_indexes;
    END re_extract_rate_events;

    PROCEDURE drop_job_indexes
    IS
    BEGIN
       BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX DJ_IDX01';
       EXCEPTION
            WHEN OTHERS THEN NULL;
       END;
       BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX DJ_IDX02';
       EXCEPTION
            WHEN OTHERS THEN NULL;
       END;
       BEGIN
            EXECUTE IMMEDIATE 'DROP INDEX DJ_IDX03';
       EXCEPTION
            WHEN OTHERS THEN NULL;
       END;
    END drop_job_indexes;

    PROCEDURE create_job_indexes
    IS
    BEGIN
       BEGIN
            EXECUTE IMMEDIATE 'CREATE INDEX DJ_IDX01 ON DM_JOBS (JOB_TITLE) INDEXTYPE IS CTXSYS.CONTEXT';
       EXCEPTION
            WHEN OTHERS THEN NULL;
       END;
       BEGIN
            EXECUTE IMMEDIATE 'CREATE INDEX DJ_IDX02 ON DM_JOBS (JOB_DESC) INDEXTYPE IS CTXSYS.CONTEXT';
       EXCEPTION
            WHEN OTHERS THEN NULL;
       END;
       BEGIN
            EXECUTE IMMEDIATE 'CREATE INDEX DJ_IDX03 ON DM_JOBS (JOB_SKILLS_TEXT) INDEXTYPE IS CTXSYS.CONTEXT';
       EXCEPTION
            WHEN OTHERS THEN NULL;
       END;
    END create_job_indexes;

    PROCEDURE manage_title_maps
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
                      FROM fo_dm_jobs_tmp t2, dm_rate_event_master m
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
           (
           apex_id, data_source_code, buyerorg_id, job_id, job_title, std_job_title_id, last_update_date
           )
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
                               FROM fo_dm_jobs_tmp t2, dm_fo_title_map x, dm_rate_event_master m
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
    END manage_title_maps;

    PROCEDURE merge_jobs
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
      , p_skip_maint  IN VARCHAR2
    )
    IS
           v_rec_count      NUMBER;
           v_crnt_proc_name    user_jobs.what%TYPE := 'DM_RATE_EVENT.MERGE_JOBS';
    BEGIN
           IF (p_skip_maint = 'N')
              THEN
                   -- Drop Domain Indexes on DM_JOBS Table
                   drop_job_indexes();
           END IF;

           /*
           ** Remove pipes, control and any non-printable characters
           ** from job_title, job_desc and job_skills_text columns
           */
           UPDATE fo_dm_jobs_tmp t
              SET   t.job_title       = REPLACE(REGEXP_REPLACE(t.job_title,       c_regexp_rule), CHR(15712189))
                  , t.job_desc        = REPLACE(REGEXP_REPLACE(t.job_desc,        c_regexp_rule), CHR(15712189))
                  , t.job_skills_text = REPLACE(REGEXP_REPLACE(t.job_skills_text, c_regexp_rule), CHR(15712189));
           COMMIT;

           MERGE INTO dm_jobs t
           USING (
                   SELECT   j.data_source_code
                          , j.buyerorg_id
                          , j.buyerfirm_id
                          , j.job_id
                          , j.top_buyerorg_id
                          , j.job_category_id
                          , j.job_title
                          , j.job_state
                          , j.last_modified_date
                          , j.job_created_date
                          , j.job_approved_date
                          , j.rate_range_low
                          , j.rate_range_high
                          , j.rate_unit_type
                          , j.job_desc
                          , j.job_skills_text
                          , bm.std_buyerorg_id
                          , j.job_category_desc
                          , t.std_job_title_id
                          , t.std_job_category_id
                          , j.source_template_id
                     FROM fo_dm_jobs_tmp j, dm_fo_title_map m, dm_job_titles t, fo_buyers_map bm
                    WHERE m.data_source_code = j.data_source_code
                      AND m.buyerorg_id = j.buyerorg_id
                      AND m.job_title = j.job_title
                      AND m.job_id  = j.job_id
                      AND t.std_job_title_id = m.std_job_title_id
                      AND bm.buyerorg_id      = j.buyerorg_id
                      AND bm.data_source_code = j.data_source_code
                 ) s
              ON (
                       t.data_source_code    = s.data_source_code
                   AND t.job_id              = s.job_id
                   AND t.buyerorg_id         = s.buyerorg_id
                 )
            WHEN MATCHED THEN UPDATE SET
                       t.job_category_id      = s.job_category_id
                     , t.job_title     = s.job_title
                     , t.job_state     = s.job_state
                     , t.last_modified_date = s.last_modified_date
                     , t.job_created_date = s.job_created_date
                     , t.job_approved_date = s.job_approved_date
                     , t.job_desc = s.job_desc
                     , t.job_skills_text = s.job_skills_text
                     , t.rate_range_low = s.rate_range_low
                     , t.rate_range_high = s.rate_range_high
                     , t.rate_unit_type = s.rate_unit_type
                     , t.job_category_desc = s.job_category_desc
                     , t.std_job_category_id = s.std_job_category_id
                     , t.std_job_title_id = s.std_job_title_id
                     , t.source_template_id = s.source_template_id
            WHEN NOT MATCHED THEN INSERT
                   (
                       data_source_code
                     , buyerorg_id
                     , job_id
                     , top_buyerorg_id
                     , job_category_id
                     , job_title
                     , std_buyerorg_id
                     , job_state
                     , last_modified_date
                     , job_created_date
                     , job_approved_date
                     , job_desc
                     , job_skills_text
                     , rate_range_low
                     , rate_range_high
                     , rate_unit_type
                     , job_category_desc
                     , has_sole_supplier_flag
                     , std_job_category_id
                     , std_job_title_id
                     , source_template_id
                   )
                   VALUES
                   (
                       s.data_source_code
                     , s.buyerorg_id
                     , s.job_id
                     , s.top_buyerorg_id
                     , s.job_category_id
                     , s.job_title
                     , s.std_buyerorg_id
                     , s.job_state
                     , s.last_modified_date
                     , s.job_created_date
                     , s.job_approved_date
                     , s.job_desc
                     , s.job_skills_text
                     , s.rate_range_low
                     , s.rate_range_high
                     , s.rate_unit_type
                     , s.job_category_desc
                     , 'Y'
                     , s.std_job_category_id
                     , s.std_job_title_id
                     , s.source_template_id
                   );

           v_rec_count := SQL%ROWCOUNT;
           COMMIT;
           dm_util_log.p_log_msg(p_msg_id, 30, NULL, NULL, 'U');
           dm_util_log.p_log_msg(p_msg_id, 31, p_source_code || ': Merged ' || v_rec_count || ' Jobs records', v_crnt_proc_name, 'I');
           dm_util_log.p_log_msg(p_msg_id, 31, NULL, NULL, 'U');

           DBMS_OUTPUT.PUT_LINE('Merged ' || v_rec_count || ' Jobs records');

           IF (p_skip_maint = 'N')
              THEN
                   -- Re-create Domain Indexes on DM_JOBS Table
                   create_job_indexes();
           END IF;
    END merge_jobs;

    PROCEDURE clean_job_text_fields
    IS
    BEGIN
           -- Drop Domain Indexes on DM_JOBS Table
           drop_job_indexes();

           /*
           ** Remove pipes, control and any non-printable characters
           ** from job_title, job_desc and job_skills_text columns
           */
           UPDATE dm_jobs t
              SET   t.job_title       = REPLACE(REGEXP_REPLACE(t.job_title,       c_regexp_rule), CHR(15712189))
                  , t.job_desc        = REPLACE(REGEXP_REPLACE(t.job_desc,        c_regexp_rule), CHR(15712189))
                  , t.job_skills_text = REPLACE(REGEXP_REPLACE(t.job_skills_text, c_regexp_rule), CHR(15712189));

           UPDATE dm_rate_event_master t
              SET t.job_title         = REPLACE(REGEXP_REPLACE(t.job_title,       c_regexp_rule), CHR(15712189))
            WHERE t.job_title IS NOT NULL;

           UPDATE dm_rate_event_q t
              SET t.job_title         = REPLACE(REGEXP_REPLACE(t.job_title,       c_regexp_rule), CHR(15712189))
            WHERE t.job_title IS NOT NULL;

           COMMIT;

           -- Re-create Domain Indexes on DM_JOBS Table
           create_job_indexes();
    END clean_job_text_fields;

    FUNCTION get_link_name(p_source_code IN VARCHAR2) RETURN VARCHAR2
    IS
           l_link_name VARCHAR2(32); -- Name of DB Link to FO Instance
    BEGIN
           CASE (p_source_code)
                WHEN 'REGULAR'  THEN l_link_name := 'FO_R';
                WHEN 'WACHOVIA' THEN l_link_name := 'WA_LINK';
                ELSE                 l_link_name := 'FO_R';
           END CASE;
           RETURN(l_link_name);
    END get_link_name;

    PROCEDURE get_rateiq_snapshot
    (
        p_month_number  IN NUMBER
      , p_force_refresh IN VARCHAR
    )
    IS
           v_null VARCHAR2(1);
    BEGIN
           BEGIN
                  SELECT NULL
                    INTO v_null
                    FROM rateiq_snapshot
                   WHERE month_number = p_month_number
                     AND ROWNUM < 2;

                  IF (p_force_refresh = 'Y')
                     THEN
                           DELETE rateiq_snapshot
                            WHERE month_number = p_month_number;

                           COMMIT;
                     ELSE
                           RAISE_APPLICATION_ERROR(-20520, 'RateIQ Snapshot already exists for ' || p_month_number);
                  END IF;
           EXCEPTION
              WHEN NO_DATA_FOUND THEN NULL;
           END;

           INSERT /*+ APPEND(t) */ INTO rateiq_snapshot t
           (
                    month_number
                  , std_job_category_desc
                  , std_job_title_desc
                  , std_job_title_id
                  , assignment_id
                  , assignment_seq_number
                  , data_source_code
                  , cmsa_code
                  , cmsa_name
                  , std_buyerorg_id
                  , rate_event_decision_date
                  , rate_event_start_date
                  , rate_event_end_date
                  , reg_bill_rate
                  , duration_units
                  , job_title
                  , job_desc
                  , job_skills_text
                  , std_region_type_id
                  , std_region_desc
           )
           SELECT   w.month_number
                  , REPLACE(REGEXP_REPLACE(w.std_job_category_desc, c_regexp_rule), CHR(15712189)) AS std_job_category_desc
                  , REPLACE(REGEXP_REPLACE(w.std_job_title_desc,    c_regexp_rule), CHR(15712189)) AS std_job_title_desc
                  , w.std_job_title_id
                  , w.assignment_id
                  , w.assignment_seq_number
                  , w.data_source_code
                  , w.cmsa_code
                  , w.cmsa_name
                  , r.std_buyerorg_id
                  , w.rate_event_decision_date
                  , w.rate_event_start_date
                  , w.rate_event_end_date
                  , w.reg_bill_rate
                  , w.duration_units
                  , REPLACE(REGEXP_REPLACE(r.job_title,       c_regexp_rule), CHR(15712189)) AS job_title
                  , REPLACE(REGEXP_REPLACE(j.job_desc,        c_regexp_rule), CHR(15712189)) AS job_desc
                  , REPLACE(REGEXP_REPLACE(j.job_skills_text, c_regexp_rule), CHR(15712189)) AS job_skills_text
                  , rg.std_region_type_id
                  , rg.std_region_desc
             FROM dm_weighted_rate_events w, dm_rate_event_master r,
                  dm_jobs j, dm_region_place_map rpm, dm_regions rg
            WHERE w.std_country_id = 1
              AND w.month_number = p_month_number
              AND w.month_type = 'C'
              AND w.batch_id IS NOT NULL
              AND w.load_key IS NOT NULL
              AND r.batch_id = w.batch_id
              AND r.load_key = w.load_key
              AND r.std_buyerorg_id <> 87732
              AND j.data_source_code (+) = r.data_source_code
              AND j.job_id (+) = r.job_id
              AND rpm.std_place_id = w.std_place_id
              AND rg.std_country_id = w.std_country_id
              AND rg.std_region_type_id = 6
              AND rg.std_region_id = rpm.std_region_id;

           COMMIT;
    END get_rateiq_snapshot;

    PROCEDURE verify_uk
    (
        p_state                 dm_rate_event_master.custom_address_state%TYPE
      , p_full_address          dm_rate_event_master.unparsed_custom_address%TYPE
      , p_supplierorg_name      dm_rate_event_master.supplierorg_name%TYPE
      , p_job_title             dm_rate_event_master.job_title%TYPE
      , p_buyerorg_name         dm_rate_event_master.buyerorg_name%TYPE
      , p_std_country_id IN OUT dm_rate_event_master.std_country_id%TYPE
    )
    IS
          v_full_address     dm_rate_event_master.unparsed_custom_address%TYPE;
          v_job_title        dm_rate_event_master.job_title%TYPE;
          v_buyerorg_name    dm_rate_event_master.buyerorg_name%TYPE;
          v_supplierorg_name dm_rate_event_master.supplierorg_name%TYPE;
          v_state            dm_rate_event_master.custom_address_state%TYPE;
    BEGIN
          v_full_address     := UPPER(p_full_address);
          v_job_title        := UPPER(p_job_title);
          v_buyerorg_name    := UPPER(p_buyerorg_name);
          v_supplierorg_name := UPPER(p_supplierorg_name);
          v_state            := UPPER(p_state);
          IF (
                  v_full_address NOT LIKE 'UNITED KINGDOM%'
              AND v_full_address <> 'UK'
              AND v_full_address NOT LIKE 'UK -%'
              AND v_full_address NOT LIKE 'GBR%'
              AND v_full_address NOT LIKE 'ENGLAND -%'
              AND (
                      v_full_address = 'NON-UK'
                   OR v_full_address = 'USA'
                   OR v_full_address LIKE '% INDIA %'
                   OR v_full_address LIKE 'INDIA %'
                   OR v_full_address LIKE '%IRELAND%'
                   OR v_full_address LIKE '%ITALY %'
                   OR v_full_address LIKE 'IT - %'
                   OR v_full_address LIKE '%EUROPE %'
                   OR v_full_address LIKE 'UNITED STATES%'
                   OR v_full_address LIKE 'NETHERLANDS%'
                   OR v_full_address LIKE '%PHILIPPINES%'
                   OR v_full_address LIKE '%SPAIN%'
                   OR v_full_address LIKE '%OFFSHORE%'
                   OR v_full_address LIKE '%OFF SHORE%'
                   OR v_full_address LIKE 'R - MEXICO %'
                   OR v_full_address LIKE '%CANADA%'
                   OR v_full_address LIKE '%ISRAEL%'
                   OR v_full_address LIKE 'OSL%'
                   OR v_full_address LIKE 'GERMANY%'
                   OR v_full_address LIKE 'FRANCE%'
                   OR v_full_address LIKE 'KAZAKHSTAN%'
                   OR v_full_address LIKE 'AUSTRALIA%'
                   OR v_full_address LIKE 'MALAYSIA%'
                   OR v_full_address LIKE 'TRINIDAD%'
                   OR v_full_address LIKE 'BELGIUM%'
                   OR v_full_address LIKE 'HUNGARY%'
                   OR (is_country_name(v_full_address, 'UNITED KINGDOM') = 'Y')
                   OR (is_country_name(v_state,        'UNITED KINGDOM') = 'Y')
                   OR v_full_address IN ('OTHER','UNKNOWN','OFFSHORE','OFF SHORE','Z - OTHER','ASIA')
                   OR v_state        IN ('OTHER','UNKNOWN','OFFSHORE','OFF SHORE','Z - OTHER','ASIA')
                   OR v_state LIKE '%OFFSHORE%'
                   OR v_supplierorg_name LIKE '%OFFSHORE%'
                   OR v_supplierorg_name LIKE '%OFF SHORE%'
                   OR v_job_title LIKE '%INDIA%'
                   OR v_job_title LIKE '%OFFSHORE%'
                   OR v_job_title LIKE '%OFF SHORE%'
                   OR v_buyerorg_name LIKE '% INDIA'
                   OR v_buyerorg_name LIKE '% INDIA %'
                   OR v_buyerorg_name LIKE 'INDIA %'
                  )
             )
             THEN p_std_country_id := 0;
             ELSE p_std_country_id := c_uk_country_id;
          END IF;
    END verify_uk;

    PROCEDURE verify_us
    (
        p_state                 dm_rate_event_master.custom_address_state%TYPE
      , p_full_address          dm_rate_event_master.unparsed_custom_address%TYPE
      , p_supplierorg_name      dm_rate_event_master.supplierorg_name%TYPE
      , p_job_title             dm_rate_event_master.job_title%TYPE
      , p_buyerorg_name         dm_rate_event_master.buyerorg_name%TYPE
      , p_std_country_id IN OUT dm_rate_event_master.std_country_id%TYPE
    )
    IS
          v_full_address     dm_rate_event_master.unparsed_custom_address%TYPE;
          v_job_title        dm_rate_event_master.job_title%TYPE;
          v_buyerorg_name    dm_rate_event_master.buyerorg_name%TYPE;
          v_supplierorg_name dm_rate_event_master.supplierorg_name%TYPE;
          v_state            dm_rate_event_master.custom_address_state%TYPE;
    BEGIN
          v_full_address     := UPPER(p_full_address);
          v_job_title        := UPPER(p_job_title);
          v_buyerorg_name    := UPPER(p_buyerorg_name);
          v_supplierorg_name := UPPER(p_supplierorg_name);
          v_state            := UPPER(p_state);
          IF (
                  v_full_address LIKE '% INDIA %'
               OR v_full_address LIKE 'INDIA %'
               OR v_full_address LIKE '%IRELAND%'
               OR v_full_address LIKE '%SCOTLAND%'
               OR v_full_address LIKE '%ITALY %'
               OR v_full_address LIKE 'IT - %'
               OR v_full_address LIKE '%EUROPE %'
               OR v_full_address LIKE 'UNITED KINGDOM%'
               OR v_full_address LIKE 'UK - %'
               OR v_full_address = 'UK'
               OR v_full_address LIKE 'GBR%'
               OR v_full_address LIKE 'ENGLAND -%'
               OR v_full_address LIKE 'NETHERLANDS%'
               OR v_full_address LIKE '%PHILIPPINES%'
               OR v_full_address LIKE '%SPAIN%'
               OR v_full_address LIKE '%OFFSHORE%'
               OR v_full_address LIKE '%OFF SHORE%'
               OR v_full_address LIKE 'R - MEXICO %'
               OR v_full_address LIKE '%CANADA%'
               OR v_full_address LIKE '%ISRAEL%'
               OR v_full_address LIKE 'OSL%'
               OR v_full_address LIKE 'GERMANY%'
               OR v_full_address LIKE 'FRANCE%'
               OR v_full_address LIKE 'KAZAKHSTAN%'
               OR v_full_address LIKE 'AUSTRALIA%'
               OR v_full_address LIKE 'MALAYSIA%'
               OR v_full_address LIKE 'TRINIDAD%'
               OR v_full_address LIKE 'BELGIUM%'
               OR v_full_address LIKE 'HUNGARY%'
               OR (is_country_name(v_full_address, 'UNITED STATES') = 'Y')
               OR (is_country_name(v_state,        'UNITED STATES') = 'Y')
               OR v_full_address IN ('OTHER','UNKNOWN','OFFSHORE','OFF SHORE','Z - OTHER','ASIA')
               OR v_state        IN ('OTHER','UNKNOWN','OFFSHORE','OFF SHORE','Z - OTHER','ASIA')
               OR v_state LIKE '%OFFSHORE%'
               OR v_supplierorg_name LIKE '%OFFSHORE%'
               OR v_supplierorg_name LIKE '%OFF SHORE%'
               OR v_job_title LIKE '%INDIA%'
               OR v_job_title LIKE '%OFFSHORE%'
               OR v_job_title LIKE '%OFF SHORE%'
               OR v_buyerorg_name LIKE '% INDIA'
               OR v_buyerorg_name LIKE '% INDIA %'
               OR v_buyerorg_name LIKE 'INDIA %'
             )
             THEN p_std_country_id := 0;
             ELSE p_std_country_id := c_us_country_id;
          END IF;
    END verify_us;

    PROCEDURE load_country_list
    IS
    BEGIN
          SELECT REGEXP_REPLACE(REGEXP_REPLACE(iso_country_name,' \(.*\)'), ',.*')
            BULK COLLECT INTO c_country_list
            FROM dm_geo_dim
           WHERE city_name IS NULL
             AND postal_code IS NULL
             AND state_name IS NULL
             AND is_effective = 'Y'
             AND iso_country_name IS NOT NULL
           ORDER BY DECODE(iso_country_name,'INDIA',1,'RUSSIA',2,'NETHERLANDS',3,'MALAYSIA',4,'SINGAPORE',5,'POLAND',6,'GERMANY',7,'IRELAND',8,'PHILIPPINES',9,'BELGIUM',10,'SWITZERLAND',11,'AUSTRALIA',12,'CANADA',997,'UNITED KINGDOM',998,'UNITED STATES',999, 30), iso_country_name;

          --DBMS_OUTPUT.PUT_LINE('c_country_list.COUNT = ' || c_country_list.COUNT);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
    END load_country_list;

    FUNCTION is_country_name
    (
        p_country IN dm_rate_event_master.unparsed_custom_address%TYPE
      , p_exclude IN dm_rate_event_master.unparsed_custom_address%TYPE
    ) RETURN VARCHAR2
    IS
       v_country_name dm_rate_event_master.unparsed_custom_address%TYPE := UPPER(p_country);
       j PLS_INTEGER;
    BEGIN
       CASE (v_country_name)
            WHEN 'OTHER'     THEN RETURN('N');
            WHEN 'UNKNOWN'   THEN RETURN('N');
            WHEN 'OFFSHORE'  THEN RETURN('N');
            WHEN 'OFF SHORE' THEN RETURN('N');
            WHEN 'Z - OTHER' THEN RETURN('N');
            WHEN 'ASIA'      THEN RETURN('N');
          ELSE
               FOR j IN 1 .. c_country_list.COUNT
               LOOP
                    IF (v_country_name = c_country_list(j) AND (c_country_list(j) <> p_exclude)) THEN RETURN('Y'); END IF;
               END LOOP;
       END CASE;
       RETURN('N');
    END is_country_name;

    PROCEDURE load_proximity_waits
    IS
    BEGIN
          SELECT *
            BULK COLLECT INTO proxWeights
            FROM dm_proximity_index
           ORDER BY days_range_begin;

           --DBMS_OUTPUT.PUT_LINE('proxWeights.COUNT = ' || proxWeights.COUNT);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
    END;

    PROCEDURE load_country_ids
    IS
      CURSOR c_countries IS
             SELECT c.iso_country_name, c.std_country_id, p.std_place_id, c2.country_dim_id
               FROM dm_countries c, dm_places p, dm_country_dim c2
              WHERE c.iso_country_name IN ('Canada', 'Netherlands', 'United Kingdom', 'India')
                AND p.std_country_id = c.std_country_id
                AND c2.iso_country_name = UPPER(c.iso_country_name);
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
    END load_country_ids;

    FUNCTION get_job_status(in_what IN VARCHAR2) RETURN NUMBER
    IS
       v_count NUMBER := 0;
    BEGIN
          SELECT MAX(CASE WHEN THIS_DATE IS NOT NULL THEN 1 ELSE 0 END)
            INTO v_count
            FROM user_jobs dj
           WHERE dj.log_user = USER
             AND upper(dj.what)   = UPPER(in_what);

          RETURN v_count;

    EXCEPTION
       WHEN OTHERS THEN RETURN 0;
    END get_job_status;
BEGIN
   load_proximity_waits;
   load_country_list;
   load_country_ids;
END dm_rate_event;
/