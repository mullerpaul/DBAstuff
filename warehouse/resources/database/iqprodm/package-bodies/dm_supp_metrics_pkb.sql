CREATE OR REPLACE PACKAGE BODY dm_supp_metrics
/********************************************************************
 * Name: dm_supp_metrics
 * Desc: This package contains all the procedures required to
 *       migrate/process Supplier Metrics data to be used in

 *
 * Author   Date        Version   History
 * -----------------------------------------------------------------
 * pkattula 12/12/09    Initial
 * sajeev   11/11/11    Replaced dba_jobs with user_jobs
 * JoeP     02/01/2016  Hard-coded dblink
 ********************************************************************/
AS
  PROCEDURE p_main
  (
      in_source_code IN VARCHAR2
    , p_month        IN VARCHAR2 -- Month (as YYYYMM)
  )
  IS
     ln_msg_id           NUMBER;
     v_crnt_proc_name    user_jobs.what%TYPE := 'DM_SUPP_METRICS.P_MAIN';
     ln_count            NUMBER;
     lv_proc_name        user_jobs.what%TYPE := 'DM_SUPP_METRICS.P_MAIN'; lv_fo_app_err_msg   VARCHAR2(2000)  := NULL;
     lv_fo_db_err_msg    VARCHAR2(2000)  := NULL;
     ln_err_num          NUMBER;
     lv_err_msg          VARCHAR2(4000)  := NULL;
     lv_app_err_msg      VARCHAR2(2000)  := NULL;
     lv_db_err_msg       VARCHAR2(2000)  := NULL;
     lv_ea_count         NUMBER;
     lv_wo_count         NUMBER;
     ge_fo_exception     EXCEPTION;
     email_sender        VARCHAR2(32) := 'mart_processing@iqnavigator.com';
     email_recipients    VARCHAR2(64) := 'data_warehouse@iqnavigator.com';
     email_subject       VARCHAR2(64) := 'DM Supplier Metrics Update -' || in_source_code;
     remote_extract_done VARCHAR2(1) := 'N';
  BEGIN
     --
     -- Get the sequence reuired for logging messages
     --
     SELECT dm_msg_log_seq.NEXTVAL INTO ln_msg_id FROM dual;

     --
     -- Check if the previous job still running
     --
 /*    BEGIN
       SELECT count(*)
         INTO ln_count
         FROM user_jobs dj,
              dba_jobs_running djr
        WHERE dj.job      = djr.job
          AND dj.log_user = USER
          AND dj.what     = lv_proc_name;
     EXCEPTION
       WHEN OTHERS THEN
         --
         -- Unable to read user_jobs status log and exit
         --
         dm_util_log.p_log_msg(ln_msg_id,0, gv_process || ' - ERROR IN GETTING RUNNING JOB STATUS',lv_proc_name,'I');
         dm_util_log.p_log_msg(ln_msg_id,0,NULL,NULL,'U');
     END;
   */

     ln_count := dm_cube_utils.get_job_status('DM_SUPP_METRICS.P_MAIN;');

     IF ln_count > 0 THEN
         --
         -- previous job still running log and exit
         --
         dm_util_log.p_log_msg(ln_msg_id,0,gv_process || ' - PREVIOUS JOB STILL RUNNING',lv_proc_name,'I');
         dm_util_log.p_log_msg(ln_msg_id,0,NULL,NULL,'U');
     ELSE
         dm_populate_spend_summary.p_main();

         --
         --Log initial load status
         --
         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'FO','STARTED',NULL,'I');

         --
         -- Call the procedure to get the FO rate event data.
         --
         v_crnt_proc_name := 'DM_SUPP_METRICS.GET_SUPPLIER_METRICS';
         dm_util_log.p_log_msg(ln_msg_id,1, in_source_code || ': FO Supplier Metrics Extract',v_crnt_proc_name,'I');
         get_supplier_metrics(ln_msg_id,ln_err_num,lv_err_msg, lv_ea_count, lv_wo_count, in_source_code, p_month);
         remote_extract_done := 'Y';
         dm_util_log.p_log_msg(ln_msg_id,1, NULL,NULL,'U');

         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'FO','COMPLETE',0,'U');

         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'DW','STARTED',NULL,'I');
         pull_and_transform(in_source_code, ln_msg_id, p_month);
         dm_util_log.p_log_load_status(ln_msg_id, gv_process,'DW','COMPLETE',0,'U');
     END IF;
  EXCEPTION
     WHEN OTHERS THEN
     BEGIN
           lv_fo_db_err_msg := SQLERRM;
           IF (remote_extract_done = 'Y')
              THEN
                   lv_fo_app_err_msg := 'Unable to execute the procedure to Pull and Transform Supplier metrics data after successful FO extraction!';
                   dm_util_log.p_log_load_status(ln_msg_id, gv_process,'DW','FAILED',0,'U');
              ELSE
                   dm_util_log.p_log_load_status(ln_msg_id, gv_process,'FO','FAILED',0,'U');
           END IF;
           dm_utils.send_email(email_sender, email_recipients, email_subject, in_source_code || ' Process failed due to the following ' || c_crlf || lv_fo_app_err_msg || c_crlf || lv_fo_db_err_msg || c_crlf);
     END;
  END p_main;

  FUNCTION is_negative_reason(p_reason_ended VARCHAR)
  RETURN NUMBER
  IS
         pos1 PLS_INTEGER;
  BEGIN
         FOR i IN vNegativeReasons.FIRST..vNegativeReasons.LAST
         LOOP
              pos1 := INSTR(p_reason_ended, vNegativeReasons(i));
              IF (pos1 > 0) THEN RETURN(1); END IF;
         END LOOP;
         RETURN(0);
  END is_negative_reason;

  PROCEDURE get_supplier_metrics
  (
      in_msg_id      IN  NUMBER
    , on_err_num     OUT NUMBER
    , ov_err_msg     OUT VARCHAR2
    , ov_ea_count    OUT NUMBER
    , ov_wo_count    OUT NUMBER
    , in_source_code IN  VARCHAR2
    , p_month        IN  VARCHAR2 -- Month (as YYYYMM)
  )
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)  := 'DM_SUPP_METRICS.GET_SUPPLIER_METRICS';
    lv_app_err_msg       VARCHAR2(2000) := NULL;
    lv_db_err_msg        VARCHAR2(2000) := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000) := NULL;
  BEGIN
     BEGIN

       CASE (in_source_code)
            WHEN 'REGULAR'  THEN fo_dm_supp_metrics.get_monthly_supplier_events@FO_R(p_month, in_source_code);
                                 INSERT INTO fo_dm_job_category_tmp
                                 (
                                     data_source_code
                                   , job_category_id
                                   , job_category_desc
                                 )
                                 SELECT in_source_code, job_category_id, fo_dm_util.get_job_category@FO_R(job_category_id) AS job_category_desc
                                   FROM (
                                          SELECT DISTINCT job_category_id
                                            FROM dm_jobs j
                                           WHERE j.data_source_code = in_source_code
                                             AND j.job_category_id IS NOT NULL
                                             AND j.job_category_id <> 0
                                        );
            WHEN 'WACHOVIA' THEN fo_dm_supp_metrics.get_monthly_supplier_events@WA_LINK(p_month, in_source_code);
                                 INSERT INTO fo_dm_job_category_tmp
                                 (
                                     data_source_code
                                   , job_category_id
                                   , job_category_desc
                                 )
                                 SELECT in_source_code, job_category_id, fo_dm_util.get_job_category@WA_LINK(job_category_id) AS job_category_desc
                                   FROM (
                                          SELECT DISTINCT job_category_id
                                            FROM dm_jobs j
                                           WHERE j.data_source_code = in_source_code
                                             AND j.job_category_id IS NOT NULL
                                             AND j.job_category_id <> 0
                                        );
--            WHEN 'JPMC'     THEN fo_dm_supp_metrics.get_monthly_supplier_events@JP_FO_LINK(p_month, in_source_code);
--                                 INSERT INTO fo_dm_job_category_tmp
--                                 (
--                                     data_source_code
--                                   , job_category_id
--                                   , job_category_desc
--                                 )
--                                 SELECT in_source_code, job_category_id, fo_dm_util.get_job_category@JP_FO_LINK(job_category_id) AS job_category_desc
--                                   FROM (
--                                          SELECT DISTINCT job_category_id
--                                            FROM dm_jobs j
--                                           WHERE j.data_source_code = in_source_code
--                                             AND j.job_category_id IS NOT NULL
--                                             AND j.job_category_id <> 0
--                                        );
       END CASE;

     EXCEPTION
       WHEN OTHERS THEN
         lv_app_err_msg := 'Unable to execute the remote procedure to get the FO Supplier Metrics data !';
         lv_db_err_msg  := SQLERRM;
     END;

     --
     -- check for any errors in remote procedure
     --
     BEGIN
       CASE (in_source_code)
            WHEN 'REGULAR'  THEN
                                 SELECT err_msg
                                   INTO lv_err_msg
                                   FROM fo_dm_supp_metrics_errmsg@FO_R
                                  WHERE ROWNUM < 2;
            WHEN 'WACHOVIA' THEN
                                 SELECT err_msg
                                   INTO lv_err_msg
                                   FROM fo_dm_supp_metrics_errmsg@WA_LINK
                                  WHERE ROWNUM < 2;
--            WHEN 'JPMC' THEN
--                                 SELECT err_msg
--                                   INTO lv_err_msg
--                                   FROM fo_dm_supp_metrics_errmsg@JP_FO_LINK
--                                  WHERE ROWNUM < 2;
       END CASE;

       IF lv_err_msg IS NOT NULL THEN
          lv_app_err_msg := 'Errors occured in the remote procedure to get Supplier Metrics data! ';
          lv_db_err_msg  := lv_err_msg || ' ' || SQLERRM;
       END IF;
     EXCEPTION
         WHEN NO_DATA_FOUND THEN lv_err_msg := NULL;
     END;

     IF (lv_db_err_msg IS NOT NULL)
        THEN
             RAISE_APPLICATION_ERROR(-20501, lv_app_err_msg || lv_db_err_msg);
     END IF;
  END get_supplier_metrics;

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

  PROCEDURE pull_and_transform
  (
      p_source_code  IN VARCHAR2
    , p_month        IN VARCHAR2 -- Month (as YYYYMM)
  )
  IS
        v_msg_id NUMBER;
  BEGIN
        --
        -- Get the sequence reuired for logging messages
        --
        SELECT dm_msg_log_seq.NEXTVAL INTO v_msg_id FROM dual;

        pull_and_transform(p_source_code, v_msg_id, p_month);
  END pull_and_transform;

  PROCEDURE pull_and_transform
  (
      in_source_code IN VARCHAR2
    , in_msg_id      IN NUMBER
    , p_month        IN VARCHAR2 -- Month (as YYYYMM)
  )
  IS
     v_crnt_proc_name user_jobs.what%TYPE := 'DM_SUPP_METRICS.PULL_AND_TRANSFORM';
     v_rec_count      NUMBER;
  BEGIN
     dm_util_log.p_log_msg(in_msg_id, 2, in_source_code || ': Truncate DW Temp Tables', v_crnt_proc_name, 'I');
     EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_dm_jobs_tmp';
     --EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_dm_job_snap_tmp';
     EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_dm_job_supplier_tmp';
     EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_dm_supplier_event_tmp';

     -- Drop Domain Indexes on DM_JOBS Table
     drop_job_indexes();

     dm_util_log.p_log_msg(in_msg_id, 2, NULL, NULL, 'U');

     CASE (in_source_code)
          WHEN 'REGULAR'  THEN
               BEGIN
                      dm_util_log.p_log_msg(in_msg_id, 3, in_source_code || ': Pull Jobs Data from FO to DW', v_crnt_proc_name, 'I');
                      INSERT INTO fo_dm_jobs_tmp t       SELECT * FROM fo_dm_jobs_tmp@FO_R;
                      v_rec_count := SQL%ROWCOUNT;
                      COMMIT;
                      dm_util_log.p_log_msg(in_msg_id, 3, NULL, NULL, 'U');
                      dm_util_log.p_log_msg(in_msg_id, 4, in_source_code || ': Pulled ' || v_rec_count || ' Jobs Data records from FO to DW', v_crnt_proc_name, 'I');
                      dm_util_log.p_log_msg(in_msg_id, 4, NULL, NULL, 'U');

                      --dm_util_log.p_log_msg(in_msg_id, 5, in_source_code || ': Pull Job Snapshot from FO to DW', v_crnt_proc_name, 'I');
                      --INSERT INTO fo_dm_job_snap_tmp t SELECT * FROM fo_dm_job_snap_tmp@FO_R;
                      --COMMIT;
                      --dm_util_log.p_log_msg(in_msg_id, 5, NULL, NULL, 'U');
                      --dm_util_log.p_log_msg(in_msg_id, 6, in_source_code || ': Pulled ' || v_rec_count || ' Job Snapshot records from FO to DW', v_crnt_proc_name, 'I');
                      --dm_util_log.p_log_msg(in_msg_id, 6, NULL, NULL, 'U');

                      dm_util_log.p_log_msg(in_msg_id, 7, in_source_code || ': Pull Job Supplier Data from FO to DW', v_crnt_proc_name, 'I');
                      INSERT INTO fo_dm_job_supplier_tmp t     SELECT * FROM fo_dm_job_supplier_tmp@FO_R;
                      v_rec_count := SQL%ROWCOUNT;
                      COMMIT;
                      dm_util_log.p_log_msg(in_msg_id, 7, NULL, NULL, 'U');
                      dm_util_log.p_log_msg(in_msg_id, 8, in_source_code || ': Pulled ' || v_rec_count || ' Job Supplier Data records from FO to DW', v_crnt_proc_name, 'I');
                      dm_util_log.p_log_msg(in_msg_id, 8, NULL, NULL, 'U');

                      dm_util_log.p_log_msg(in_msg_id, 9, in_source_code || ': Pull Supplier Event Data from FO to DW', v_crnt_proc_name, 'I');
                      INSERT INTO fo_dm_supplier_event_tmp t     SELECT * FROM fo_dm_supplier_event_tmp@FO_R;
                      v_rec_count := SQL%ROWCOUNT;
                      COMMIT;
                      dm_util_log.p_log_msg(in_msg_id, 9, NULL, NULL, 'U');
                      dm_util_log.p_log_msg(in_msg_id,10, in_source_code || ': Pulled ' || v_rec_count || ' Supplier Event Data records from FO to DW', v_crnt_proc_name, 'I');
                      dm_util_log.p_log_msg(in_msg_id,10, NULL, NULL, 'U');
               END;
          WHEN 'WACHOVIA' THEN
               BEGIN
                      dm_util_log.p_log_msg(in_msg_id, 3, in_source_code || ': Pull Jobs Data from FO to DW', v_crnt_proc_name, 'I');
                      INSERT INTO fo_dm_jobs_tmp t       SELECT * FROM fo_dm_jobs_tmp@WA_LINK;
                      v_rec_count := SQL%ROWCOUNT;
                      COMMIT;
                      dm_util_log.p_log_msg(in_msg_id, 3, NULL, NULL, 'U');
                      dm_util_log.p_log_msg(in_msg_id, 4, in_source_code || ': Pulled ' || v_rec_count || ' Jobs Data records from FO to DW', v_crnt_proc_name, 'I');
                      dm_util_log.p_log_msg(in_msg_id, 4, NULL, NULL, 'U');

                      -- dm_util_log.p_log_msg(in_msg_id, 5, in_source_code || ': Pull Job Snapshot from FO to DW', v_crnt_proc_name, 'I');
                      -- INSERT INTO fo_dm_job_snap_tmp t SELECT * FROM fo_dm_job_snap_tmp@WA_LINK;
                      -- COMMIT;
                      -- dm_util_log.p_log_msg(in_msg_id, 5, NULL, NULL, 'U');
                      -- dm_util_log.p_log_msg(in_msg_id, 6, in_source_code || ': Pulled ' || v_rec_count || ' Job Snapshot records from FO to DW', v_crnt_proc_name, 'I');
                      -- dm_util_log.p_log_msg(in_msg_id, 6, NULL, NULL, 'U');

                      dm_util_log.p_log_msg(in_msg_id, 7, in_source_code || ': Pull Job Supplier Data from FO to DW', v_crnt_proc_name, 'I');
                      INSERT INTO fo_dm_job_supplier_tmp t     SELECT * FROM fo_dm_job_supplier_tmp@WA_LINK;
                      v_rec_count := SQL%ROWCOUNT;
                      COMMIT;
                      dm_util_log.p_log_msg(in_msg_id, 7, NULL, NULL, 'U');
                      dm_util_log.p_log_msg(in_msg_id, 8, in_source_code || ': Pulled ' || v_rec_count || ' Job Supplier Data records from FO to DW', v_crnt_proc_name, 'I');
                      dm_util_log.p_log_msg(in_msg_id, 8, NULL, NULL, 'U');

                      dm_util_log.p_log_msg(in_msg_id, 9, in_source_code || ': Pull Supplier Event Data from FO to DW', v_crnt_proc_name, 'I');
                      INSERT INTO fo_dm_supplier_event_tmp t     SELECT * FROM fo_dm_supplier_event_tmp@WA_LINK;
                      v_rec_count := SQL%ROWCOUNT;
                      COMMIT;
                      dm_util_log.p_log_msg(in_msg_id, 9, NULL, NULL, 'U');
                      dm_util_log.p_log_msg(in_msg_id,10, in_source_code || ': Pulled ' || v_rec_count || ' Supplier Event Data records from FO to DW', v_crnt_proc_name, 'I');
                      dm_util_log.p_log_msg(in_msg_id,10, NULL, NULL, 'U');
               END;
--          WHEN 'JPMC' THEN
--               BEGIN
--                      dm_util_log.p_log_msg(in_msg_id, 3, in_source_code || ': Pull Jobs Data from FO to DW', v_crnt_proc_name, 'I');
--                      INSERT INTO fo_dm_jobs_tmp t       SELECT * FROM fo_dm_jobs_tmp@JP_FO_LINK;
--                      v_rec_count := SQL%ROWCOUNT;
--                      COMMIT;
--                      dm_util_log.p_log_msg(in_msg_id, 3, NULL, NULL, 'U');
--                      dm_util_log.p_log_msg(in_msg_id, 4, in_source_code || ': Pulled ' || v_rec_count || ' Jobs Data records from FO to DW', v_crnt_proc_name, 'I');
--                      dm_util_log.p_log_msg(in_msg_id, 4, NULL, NULL, 'U');
--
--                      -- dm_util_log.p_log_msg(in_msg_id, 5, in_source_code || ': Pull Job Snapshot from FO to DW', v_crnt_proc_name, 'I');
--                      -- INSERT INTO fo_dm_job_snap_tmp t SELECT * FROM fo_dm_job_snap_tmp@JP_FO_LINK;
--                      -- COMMIT;
--                      -- dm_util_log.p_log_msg(in_msg_id, 5, NULL, NULL, 'U');
--                      -- dm_util_log.p_log_msg(in_msg_id, 6, in_source_code || ': Pulled ' || v_rec_count || ' Job Snapshot records from FO to DW', v_crnt_proc_name, 'I');
--                      -- dm_util_log.p_log_msg(in_msg_id, 6, NULL, NULL, 'U');
--
--                      dm_util_log.p_log_msg(in_msg_id, 7, in_source_code || ': Pull Job Supplier Data from FO to DW', v_crnt_proc_name, 'I');
--                      INSERT INTO fo_dm_job_supplier_tmp t     SELECT * FROM fo_dm_job_supplier_tmp@JP_FO_LINK;
--                      v_rec_count := SQL%ROWCOUNT;
--                      COMMIT;
--                      dm_util_log.p_log_msg(in_msg_id, 7, NULL, NULL, 'U');
--                      dm_util_log.p_log_msg(in_msg_id, 8, in_source_code || ': Pulled ' || v_rec_count || ' Job Supplier Data records from FO to DW', v_crnt_proc_name, 'I');
--                      dm_util_log.p_log_msg(in_msg_id, 8, NULL, NULL, 'U');
--
--                      dm_util_log.p_log_msg(in_msg_id, 9, in_source_code || ': Pull Supplier Event Data from FO to DW', v_crnt_proc_name, 'I');
--                      INSERT INTO fo_dm_supplier_event_tmp t     SELECT * FROM fo_dm_supplier_event_tmp@JP_FO_LINK;
--                      v_rec_count := SQL%ROWCOUNT;
--                      COMMIT;
--                      dm_util_log.p_log_msg(in_msg_id, 9, NULL, NULL, 'U');
--                      dm_util_log.p_log_msg(in_msg_id,10, in_source_code || ': Pulled ' || v_rec_count || ' Supplier Event Data records from FO to DW', v_crnt_proc_name, 'I');
--                      dm_util_log.p_log_msg(in_msg_id,10, NULL, NULL, 'U');
--               END;
     END CASE;

     transform_supplier_metrics(   in_source_code, in_msg_id, p_month);

     -- Re-create Domain Indexes on DM_JOBS Table
     create_job_indexes();

  END pull_and_transform;

  PROCEDURE copy_metrics
  (
      p_source_code IN VARCHAR2
    , p_period_from IN VARCHAR2 -- as YYYYNN
    , p_period_to   IN VARCHAR2 -- as YYYYNN
  )
  IS
  BEGIN
        DELETE dm_supplier_summary t
         WHERE t.data_source_code = p_source_code
           AND t.period_number    = p_period_to;

        INSERT INTO dm_supplier_summary t
               (
                   data_source_code
                 , period_number
                 , buyerorg_id
                 , supplierorg_id
                 , job_category_id
                 , job_category_desc
                 , candidates_submitted
                 , avg_submit_days
                 , avg_submit_bus_days
                 , candidates_forwarded_2hm
                 , avg_fwd_2hm_days
                 , avg_fwd_2hm_bus_days
                 , avg_fwd_2hm_days_4filled
                 , avg_fwd_2hm_bus_days_4filled
                 , candidates_interviewed
                 , avg_time_to_fill_days
                 , candidates_withdrawn
                 , candidates_offered
                 , candidates_declined
                 , candidates_accepted
                 , candidates_started
                 , ea_candidates_started
                 , targeted_jobs_count
                 , rate_compliance_count
                 , candidates_ended
                 , negative_evaluations_count
                 , positive_evaluations_count
                 , adverse_event_count
                 , submitted_candidates_ratio
                 , qualified_candidates_ratio
                 , interviewed_candidates_ratio
                 , fill_ratio
                 , supplier_score
                 , supplier_rank
                 , spend_amt
                 , opportunities_received
               )
        SELECT
                   data_source_code
                 , p_period_to AS month_number
                 , buyerorg_id
                 , supplierorg_id
                 , job_category_id
                 , job_category_desc
                 , candidates_submitted
                 , avg_submit_days
                 , avg_submit_bus_days
                 , candidates_forwarded_2hm
                 , avg_fwd_2hm_days
                 , avg_fwd_2hm_bus_days
                 , avg_fwd_2hm_days_4filled
                 , avg_fwd_2hm_bus_days_4filled
                 , candidates_interviewed
                 , avg_time_to_fill_days
                 , candidates_withdrawn
                 , candidates_offered
                 , candidates_declined
                 , candidates_accepted
                 , candidates_started
                 , ea_candidates_started
                 , targeted_jobs_count
                 , rate_compliance_count
                 , candidates_ended
                 , negative_evaluations_count
                 , positive_evaluations_count
                 , adverse_event_count
                 , submitted_candidates_ratio
                 , qualified_candidates_ratio
                 , interviewed_candidates_ratio
                 , fill_ratio
                 , supplier_score
                 , supplier_rank
                 , spend_amt
                 , opportunities_received
          FROM dm_supplier_summary s
         WHERE s.data_source_code = p_source_code
           AND s.period_number    = p_period_from;

        COMMIT;

        DELETE dm_supplier_std_summary t
         WHERE t.data_source_code = p_source_code
           AND t.period_number    = p_period_to;

        INSERT INTO dm_supplier_std_summary t
               (
                   data_source_code
                 , period_number
                 , std_buyerorg_id
                 , std_supplierorg_id
                 , std_job_category_id
                 , std_job_category_desc
                 , candidates_submitted
                 , avg_submit_days
                 , avg_submit_bus_days
                 , candidates_forwarded_2hm
                 , avg_fwd_2hm_days
                 , avg_fwd_2hm_bus_days
                 , avg_fwd_2hm_days_4filled
                 , avg_fwd_2hm_bus_days_4filled
                 , candidates_interviewed
                 , avg_time_to_fill_days
                 , candidates_withdrawn
                 , candidates_offered
                 , candidates_declined
                 , candidates_accepted
                 , candidates_started
                 , ea_candidates_started
                 , targeted_jobs_count
                 , rate_compliance_count
                 , candidates_ended
                 , negative_evaluations_count
                 , positive_evaluations_count
                 , adverse_event_count
                 , submitted_candidates_ratio
                 , qualified_candidates_ratio
                 , interviewed_candidates_ratio
                 , fill_ratio
                 , supplier_score
                 , supplier_rank
                 , spend_amt
                 , opportunities_received
               )
        SELECT
                   data_source_code
                 , p_period_to AS month_number
                 , std_buyerorg_id
                 , std_supplierorg_id
                 , std_job_category_id
                 , std_job_category_desc
                 , candidates_submitted
                 , avg_submit_days
                 , avg_submit_bus_days
                 , candidates_forwarded_2hm
                 , avg_fwd_2hm_days
                 , avg_fwd_2hm_bus_days
                 , avg_fwd_2hm_days_4filled
                 , avg_fwd_2hm_bus_days_4filled
                 , candidates_interviewed
                 , avg_time_to_fill_days
                 , candidates_withdrawn
                 , candidates_offered
                 , candidates_declined
                 , candidates_accepted
                 , candidates_started
                 , ea_candidates_started
                 , targeted_jobs_count
                 , rate_compliance_count
                 , candidates_ended
                 , negative_evaluations_count
                 , positive_evaluations_count
                 , adverse_event_count
                 , submitted_candidates_ratio
                 , qualified_candidates_ratio
                 , interviewed_candidates_ratio
                 , fill_ratio
                 , supplier_score
                 , supplier_rank
                 , spend_amt
                 , opportunities_received
          FROM dm_supplier_std_summary s
         WHERE s.data_source_code = p_source_code
           AND s.period_number    = p_period_from;

        COMMIT;

        DELETE dm_supplier_std_summary t
         WHERE t.data_source_code = 'ALL'
           AND t.period_number    = p_period_to;

        INSERT INTO dm_supplier_std_summary t
               (
                   data_source_code
                 , period_number
                 , std_buyerorg_id
                 , std_supplierorg_id
                 , std_job_category_id
                 , std_job_category_desc
                 , candidates_submitted
                 , avg_submit_days
                 , avg_submit_bus_days
                 , candidates_forwarded_2hm
                 , avg_fwd_2hm_days
                 , avg_fwd_2hm_bus_days
                 , avg_fwd_2hm_days_4filled
                 , avg_fwd_2hm_bus_days_4filled
                 , candidates_interviewed
                 , avg_time_to_fill_days
                 , candidates_withdrawn
                 , candidates_offered
                 , candidates_declined
                 , candidates_accepted
                 , candidates_started
                 , ea_candidates_started
                 , targeted_jobs_count
                 , rate_compliance_count
                 , candidates_ended
                 , negative_evaluations_count
                 , positive_evaluations_count
                 , adverse_event_count
                 , submitted_candidates_ratio
                 , qualified_candidates_ratio
                 , interviewed_candidates_ratio
                 , fill_ratio
                 , supplier_score
                 , supplier_rank
                 , spend_amt
                 , opportunities_received
               )
        SELECT
                   data_source_code
                 , p_period_to AS month_number
                 , std_buyerorg_id
                 , std_supplierorg_id
                 , std_job_category_id
                 , std_job_category_desc
                 , candidates_submitted
                 , avg_submit_days
                 , avg_submit_bus_days
                 , candidates_forwarded_2hm
                 , avg_fwd_2hm_days
                 , avg_fwd_2hm_bus_days
                 , avg_fwd_2hm_days_4filled
                 , avg_fwd_2hm_bus_days_4filled
                 , candidates_interviewed
                 , avg_time_to_fill_days
                 , candidates_withdrawn
                 , candidates_offered
                 , candidates_declined
                 , candidates_accepted
                 , candidates_started
                 , ea_candidates_started
                 , targeted_jobs_count
                 , rate_compliance_count
                 , candidates_ended
                 , negative_evaluations_count
                 , positive_evaluations_count
                 , adverse_event_count
                 , submitted_candidates_ratio
                 , qualified_candidates_ratio
                 , interviewed_candidates_ratio
                 , fill_ratio
                 , supplier_score
                 , supplier_rank
                 , spend_amt
                 , opportunities_received
          FROM dm_supplier_std_summary s
         WHERE s.data_source_code = 'ALL'
           AND s.period_number    = p_period_from;

        COMMIT;
  END copy_metrics;

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
                  SELECT   /*+ dynamic_sampling(t2 10) USE_HASH(t2, m) */ t2.data_source_code, t2.buyerorg_id, t2.job_id, t2.job_title, m.std_job_title_id
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
                           SELECT /*+ dynamic_sampling(t2 10) dynamic_sampling(x 10) USE_HASH(t2, m, x) */ t2.data_source_code, t2.buyerorg_id, t2.job_id, t2.job_title, m.std_job_title_id
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
           WHERE z.rnk = 1;
  END manage_title_maps;

  PROCEDURE merge_jobs
  (
      in_source_code IN VARCHAR2
    , in_msg_id      IN NUMBER
  )
  IS
         v_rec_count      NUMBER;
         v_crnt_proc_name    user_jobs.what%TYPE := 'DM_SUPP_METRICS.MERGE_JOBS';
  BEGIN
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
         dm_util_log.p_log_msg(in_msg_id, 30, NULL, NULL, 'U');
         dm_util_log.p_log_msg(in_msg_id, 31, in_source_code || ': Merged ' || v_rec_count || ' Jobs Metrics records', v_crnt_proc_name, 'I');
         dm_util_log.p_log_msg(in_msg_id, 31, NULL, NULL, 'U');

         DBMS_OUTPUT.PUT_LINE('Merged ' || v_rec_count || ' Jobs records');

  END merge_jobs;

  PROCEDURE transform_supplier_metrics
  (
      in_source_code IN VARCHAR2
    , in_msg_id      IN NUMBER
    , p_month        IN VARCHAR2 -- Month (as YYYYMM)
  )
  IS
         v_crnt_proc_name user_jobs.what%TYPE := 'DM_SUPP_METRICS.TRANSFORM_SUPPLIER_METRICS';
         v_rec_count      NUMBER;
         --CURSOR fill_snap_cur IS
         --       SELECT x.*
         --         FROM (
         --                SELECT   j.job_state, s2.*
         --                       , LEAD(s2.month_number, 1, 0) OVER (partition by s2.job_id,s2.supplierorg_id order by s2.month_number) as next_snap_month
         --                  FROM fo_dm_job_snap_tmp s, dm_jobs j, dm_job_monthly_snapshot s2
         --                 WHERE s.month_number = p_month
         --                   AND j.job_id = s.job_id
         --                   AND s2.month_number <= s.month_number
         --                   AND s2.job_id = s.job_id
         --                   AND s2.data_source_code = s.data_source_code
         --                   AND s2.buyerorg_id = s.buyerorg_id
         --                   AND s2.supplierorg_id = s.supplierorg_id
         --              ) x
         --        WHERE x.next_snap_month = p_month
         --          AND (x.next_snap_month-x.month_number) > 1
         --        ORDER by x.job_id, x.supplierorg_id, x.month_number;

         crnt_month NUMBER;
         month_mod  NUMBER;
         v_month_part VARCHAR2(8);
         v_year_part  VARCHAR2(8);
  BEGIN
         dm_util_log.p_log_msg(in_msg_id, 30, in_source_code || ': Transform and Merge Supplier Metrics', v_crnt_proc_name, 'I');
         merge_jobs(in_source_code, in_msg_id);

         -- MERGE INTO dm_job_monthly_snapshot t
         -- USING (
         --         SELECT    j.data_source_code
         --                 , j.buyerorg_id
         --                 , j.supplierorg_id
         --                 , j.job_id
         --                 , j.month_number
         --                 , j.available_positions_at_eom
         --                 , j.total_positions_at_eom
         --                 , j.closed_positions_at_eom
         --                 , j.filled_positions_at_eom
         --                 , jb.job_category_id
         --                 , jb.job_category_desc
         --           FROM fo_dm_job_snap_tmp j, dm_jobs jb
         --          WHERE jb.data_source_code = j.data_source_code
         --            AND jb.buyerorg_id = j.buyerorg_id
         --            AND jb.job_id = j.job_id
         --       ) s
         --    ON (
         --             t.data_source_code = s.data_source_code
         --         AND t.buyerorg_id      = s.buyerorg_id
         --         AND t.supplierorg_id   = s.supplierorg_id
         --         AND t.job_id           = s.job_id
         --         AND t.month_number     = s.month_number
         --       )
         --  WHEN MATCHED THEN UPDATE SET
         --             t.available_positions_at_eom = s.available_positions_at_eom
         --           , t.total_positions_at_eom     = s.total_positions_at_eom
         --           , t.closed_positions_at_eom    = s.closed_positions_at_eom
         --           , t.filled_positions_at_eom    = s.filled_positions_at_eom
         --           , t.job_category_id            = s.job_category_id
         --           , t.job_category_desc          = s.job_category_desc
         --  WHEN NOT MATCHED THEN INSERT
         --         (
         --             data_source_code
         --           , buyerorg_id
         --           , supplierorg_id
         --           , job_id
         --           , month_number
         --           , job_category_id
         --           , job_category_desc
         --           , available_positions_at_eom
         --           , total_positions_at_eom
         --           , closed_positions_at_eom
         --           , filled_positions_at_eom
         --         )
         --         VALUES
         --         (
         --             s.data_source_code
         --           , s.buyerorg_id
         --           , s.supplierorg_id
         --           , s.job_id
         --           , s.month_number
         --           , s.job_category_id
         --           , s.job_category_desc
         --           , s.available_positions_at_eom
         --           , s.total_positions_at_eom
         --           , s.closed_positions_at_eom
         --           , s.filled_positions_at_eom
         --         );
         -- v_rec_count := SQL%ROWCOUNT;
         -- COMMIT;
         -- DBMS_OUTPUT.PUT_LINE('Merged ' || v_rec_count || ' JOB Snapshot records');

         --v_rec_count := 0;
         --FOR fill_snap_rec IN fill_snap_cur
         --LOOP
              /*
              ** Following logic is to
              ** ensure January comes after December
              ** example : 200912 + 1 should be 201001 (not 200913)
              */
         --     crnt_month := fill_snap_rec.month_number + 1;
         --     month_mod  := MOD(crnt_month, 100);
         --     IF (month_mod > 12)
         --        THEN
         --             crnt_month := crnt_month - month_mod + 101;
         --     END IF;

         --     WHILE(crnt_month < fill_snap_rec.next_snap_month)
         --     LOOP
         --          INSERT INTO dm_job_monthly_snapshot
         --          (
         --              data_source_code
         --            , buyerorg_id
         --            , supplierorg_id
         --            , job_id
         --            , month_number
         --            , available_positions_at_eom
         --            , total_positions_at_eom
         --            , closed_positions_at_eom
         --            , filled_positions_at_eom
         --          )
         --          VALUES
         --          (
         --              fill_snap_rec.data_source_code
         --            , fill_snap_rec.buyerorg_id
         --            , fill_snap_rec.supplierorg_id
         --            , fill_snap_rec.job_id
         --            , crnt_month
         --            , fill_snap_rec.available_positions_at_eom
         --            , fill_snap_rec.total_positions_at_eom
         --            , fill_snap_rec.closed_positions_at_eom
         --            , fill_snap_rec.filled_positions_at_eom
         --          );

                   /*
                   ** Following logic is to
                   ** ensure January comes after December
                   ** example : 200912 + 1 should be 201001 (not 200913)
                   */
         --          crnt_month := crnt_month + 1;
         --          month_mod  := MOD(crnt_month, 100);
         --          IF (month_mod > 12)
         --             THEN
         --                  crnt_month := crnt_month - month_mod + 101;
         --          END IF;

         --          v_rec_count := v_rec_count + 1;
         --     END LOOP;
         --END LOOP;
         --COMMIT;
         --DBMS_OUTPUT.PUT_LINE('Added ' || v_rec_count || ' JOB Snapshot Filling records');

         MERGE INTO dm_job_supplier_details t
         USING (
                 SELECT    j.data_source_code
                         , j.buyerorg_id
                         , j.job_id
                         , j.job_opportunity_id
                         , j.supplierorg_id
                         , j.supplierfirm_id
                         , j.top_supplierorg_id
                         , j.distribution_tier_level
                         , j.rate_range_low
                         , j.rate_range_high
                         , j.rate_type
                         , j.job_opportunity_create_date
                         , j.job_opportunity_state
                         , j.job_opportunity_retracted_date
                         , NVL(bm.std_buyerorg_id, 0) AS std_buyerorg_id
                         , NVL(sm.std_supplierorg_id, 0) AS std_supplierorg_id
                   FROM fo_dm_job_supplier_tmp j, fo_buyers_map bm, fo_suppliers_map sm
                  WHERE bm.buyerorg_id      (+) = j.buyerorg_id
                    AND bm.data_source_code (+) = j.data_source_code
                    AND sm.supplierorg_id   (+) = j.supplierorg_id
                    AND sm.data_source_code (+) = j.data_source_code
               ) s
            ON (
                     t.data_source_code   = s.data_source_code
                 AND t.buyerorg_id        = s.buyerorg_id
                 AND t.job_id             = s.job_id
                 AND t.supplierorg_id     = s.supplierorg_id
                 AND t.job_opportunity_id = s.job_opportunity_id
               )
          WHEN MATCHED THEN UPDATE SET
                     t.top_supplierorg_id             = s.top_supplierorg_id
                   , t.distribution_tier_level        = s.distribution_tier_level
                   , t.rate_range_low                 = s.rate_range_low
                   , t.rate_range_high                = s.rate_range_high
                   , t.rate_type                      = s.rate_type
                   , t.job_opportunity_create_date    = s.job_opportunity_create_date
                   , t.job_opportunity_state          = s.job_opportunity_state
                   , t.job_opportunity_retracted_date = s.job_opportunity_retracted_date
                   , t.std_buyerorg_id                = s.std_buyerorg_id
                   , t.std_supplierorg_id             = s.std_supplierorg_id
          WHEN NOT MATCHED THEN INSERT
                 (
                     data_source_code
                   , buyerorg_id
                   , job_id
                   , job_opportunity_id
                   , supplierorg_id
                   , top_supplierorg_id
                   , distribution_tier_level
                   , rate_range_low
                   , rate_range_high
                   , rate_type
                   , job_opportunity_create_date
                   , job_opportunity_state
                   , job_opportunity_retracted_date
                   , std_buyerorg_id
                   , std_supplierorg_id
                 )
                 VALUES
                 (
                     s.data_source_code
                   , s.buyerorg_id
                   , s.job_id
                   , s.job_opportunity_id
                   , s.supplierorg_id
                   , s.top_supplierorg_id
                   , s.distribution_tier_level
                   , s.rate_range_low
                   , s.rate_range_high
                   , s.rate_type
                   , s.job_opportunity_create_date
                   , s.job_opportunity_state
                   , s.job_opportunity_retracted_date
                   , s.std_buyerorg_id
                   , s.std_supplierorg_id
                 );

         v_rec_count := SQL%ROWCOUNT;
         COMMIT;

         UPDATE dm_jobs j
            SET j.has_sole_supplier_flag = 'N'
          WHERE j.has_sole_supplier_flag = 'Y'
            AND EXISTS ( SELECT NULL
                           FROM dm_job_supplier_details js, fo_dm_job_supplier_tmp t
                          WHERE t.data_source_code = js.data_source_code
                            AND t.job_id = js.job_id
                            AND t.buyerorg_id = js.buyerorg_id
                            AND js.data_source_code = j.data_source_code
                            AND js.job_id = j.job_id
                            AND js.buyerorg_id = j.buyerorg_id
                            AND js.distribution_tier_level > 1
                       );

          MERGE INTO dm_jobs j
          USING (
                  SELECT js.job_id, count(DISTINCT js.supplierorg_id)
                    FROM dm_jobs j2, dm_job_supplier_details js
                   WHERE j2.has_sole_supplier_flag = 'Y'
                     AND j2.data_source_code = js.data_source_code
                     AND j2.buyerorg_id = js.buyerorg_id
                     AND j2.job_id = js.job_id
                     AND js.distribution_tier_level = 1
                   GROUP BY js.job_id
                  HAVING COUNT(DISTINCT js.supplierorg_id) > 1
                ) jl
             ON (
                  j.job_id = jl.job_id
                )
            WHEN MATCHED THEN UPDATE
                     SET j.has_sole_supplier_flag = 'N';

         INSERT INTO fo_dm_supplier_event_tmp t
                 (
                     data_source_code
                   , buyerorg_id
                   , job_id
                   , job_opportunity_id
                   , supplierorg_id
                   , candidate_id
                   , event_type
                   , event_date
                   , event_attribute1
                   , event_attribute2
                   , event_attribute3
                   , event_attribute4
                   , event_attribute5
                   , event_attribute6
                 )
         SELECT
                     s.data_source_code
                   , s.buyerorg_id
                   , s.job_id
                   , s.job_opportunity_id
                   , s.supplierorg_id
                   , s.candidate_id
                   , 'Assignment Created' AS event_type
                   , s.event_date
                   , s.event_attribute1
                   , s.event_attribute2
                   , s.event_attribute3
                   , s.event_attribute4
                   , s.event_attribute5
                   , s.event_attribute6
           FROM fo_dm_supplier_event_tmp s
          WHERE s.event_attribute5 = 'EA'
            AND s.event_type = 'Offer Made';
         v_rec_count := SQL%ROWCOUNT;
         COMMIT;

         MERGE INTO dm_job_supplier_event_details t
         USING (
                 SELECT j2.*
                   FROM (
                          SELECT    j.data_source_code
                                  , j.buyerorg_id
                                  , j.job_id
                                  , j.job_opportunity_id
                                  , j.supplierorg_id
                                  , j.candidate_id
                                  , j.event_type
                                  , j.event_date
                                  , 'A' AS event_quality_indicator
                                  , j.event_attribute1
                                  , j.event_attribute2
                                  , j.event_attribute3
                                  , j.event_attribute4
                                  , j.event_attribute5
                                  , j.event_attribute6
                                  , ROW_NUMBER() OVER (PARTITION BY j.job_id, j.supplierorg_id,  j.candidate_id, j.event_type ORDER BY j.event_date DESC) AS rnk
                            FROM fo_dm_supplier_event_tmp j
                        ) j2
                  WHERE j2.rnk < 2
               ) s
            ON (
                     t.data_source_code   = s.data_source_code
                 AND t.buyerorg_id        = s.buyerorg_id
                 AND t.job_id             = s.job_id
                 AND t.supplierorg_id     = s.supplierorg_id
                 AND t.job_opportunity_id = s.job_opportunity_id
                 AND t.candidate_id       = s.candidate_id
                 AND t.event_type         = s.event_type
                 AND t.event_date         = s.event_date
               )
          WHEN MATCHED THEN UPDATE SET
                     t.event_quality_indicator = s.event_quality_indicator
                   , t.event_attribute1        = s.event_attribute1
                   , t.event_attribute2        = s.event_attribute2
                   , t.event_attribute3        = s.event_attribute3
                   , t.event_attribute4        = s.event_attribute4
                   , t.event_attribute5        = s.event_attribute5
                   , t.event_attribute6        = s.event_attribute6
          WHEN NOT MATCHED THEN INSERT
                 (
                     data_source_code
                   , buyerorg_id
                   , job_id
                   , job_opportunity_id
                   , supplierorg_id
                   , candidate_id
                   , event_type
                   , event_date
                   , event_quality_indicator
                   , event_attribute1
                   , event_attribute2
                   , event_attribute3
                   , event_attribute4
                   , event_attribute5
                   , event_attribute6
                 )
                 VALUES
                 (
                     s.data_source_code
                   , s.buyerorg_id
                   , s.job_id
                   , s.job_opportunity_id
                   , s.supplierorg_id
                   , s.candidate_id
                   , s.event_type
                   , s.event_date
                   , s.event_quality_indicator
                   , s.event_attribute1
                   , s.event_attribute2
                   , s.event_attribute3
                   , s.event_attribute4
                   , s.event_attribute5
                   , s.event_attribute6
                 );
         v_rec_count := SQL%ROWCOUNT;
         COMMIT;

         /*
         ** Generate Current month's metrics
         */
         gen_monthly_event_summary(in_source_code, p_month, p_month, NULL);

         v_month_part := SUBSTR(p_month, 5, 2);
         v_year_part  := SUBSTR(p_month, 1, 4);
         IF (v_month_part = '01')
            THEN
                  /*
                  ** Copy Current month's metrics
                  ** AS YTD Metrics
                  */
                  copy_metrics(in_source_code, p_month, v_year_part);
            ELSE
                  /*
                  ** Generate YTD Metrics
                  */
                  gen_monthly_event_summary(in_source_code, v_year_part, v_year_part || '01', p_month);

                  IF (v_month_part = '03')
                     THEN
                           /*
                           ** Copy current YTD Metrics
                           ** AS Current Year's Q1 Metrics
                           */
                           copy_metrics(in_source_code, v_year_part, v_year_part || '1');
                     ELSE
                           CASE (v_month_part)
                             WHEN '06' THEN gen_monthly_event_summary(in_source_code, v_year_part || '2', v_year_part || '04', p_month);
                             WHEN '09' THEN gen_monthly_event_summary(in_source_code, v_year_part || '3', v_year_part || '07', p_month);
                             WHEN '12' THEN gen_monthly_event_summary(in_source_code, v_year_part || '4', v_year_part || '10', p_month);
                             ELSE NULL;
                           END CASE;
                  END IF;
         END IF;
  END transform_supplier_metrics;

  PROCEDURE gen_monthly_event_summary
  (
      p_source_code  IN VARCHAR2
    , p_period       IN VARCHAR2 --       (as YYYYNN)
    , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
    , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
  )
  IS
  BEGIN
         IF (p_source_code <> 'ALL')
            THEN
                  gen_fo_monthly_event_summary  (p_source_code, p_period, p_month1, p_month2);
                  --gen_std_monthly_event_summary (p_source_code, p_period, p_month1, p_month2);
         END IF;

         --gen_std_monthly_summary_forall(p_period, p_month1, p_month2);
  END gen_monthly_event_summary;

  PROCEDURE gen_fo_monthly_event_summary
  (
      p_source_code  IN VARCHAR2
    , p_period       IN VARCHAR2 --       (as YYYYNN)
    , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
    , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
  )
  IS
         v_rec_count      NUMBER;
  BEGIN
         MERGE INTO dm_supplier_summary t
         USING (
                 SELECT   x.*
                        , DENSE_RANK() OVER (PARTITION BY x.buyerorg_id, x.job_category_id ORDER BY x.supplier_score DESC NULLS LAST) AS supplier_rank2
                   FROM TABLE(dm_supp_metrics.gen_supplier_ratios(p_source_code, p_period, p_month1, p_month2)) x
               ) z
            ON (
                     z.data_source_code = t.data_source_code
                 AND z.period_number    = t.period_number
                 AND z.buyerorg_id      = t.buyerorg_id
                 AND z.supplierorg_id   = t.supplierorg_id
                 AND z.job_category_id  = t.job_category_id
               )
          WHEN MATCHED THEN UPDATE SET
                   t.job_category_desc            = z.job_category_desc
                 , t.candidates_submitted         = z.candidates_submitted
                 , t.avg_submit_days              = z.avg_submit_days
                 , t.avg_submit_bus_days          = z.avg_submit_bus_days
                 , t.candidates_forwarded_2hm     = z.candidates_forwarded_2hm
                 , t.avg_fwd_2hm_days             = z.avg_fwd_2hm_days
                 , t.avg_fwd_2hm_bus_days         = z.avg_fwd_2hm_bus_days
                 , t.avg_fwd_2hm_days_4filled     = z.avg_fwd_2hm_days_4filled
                 , t.avg_fwd_2hm_bus_days_4filled = z.avg_fwd_2hm_bus_days_4filled
                 , t.candidates_interviewed       = z.candidates_interviewed
                 , t.avg_time_to_fill_days        = z.avg_time_to_fill_days
                 , t.candidates_withdrawn         = z.candidates_withdrawn
                 , t.candidates_offered           = z.candidates_offered
                 , t.candidates_declined          = z.candidates_declined
                 , t.candidates_accepted          = z.candidates_accepted
                 , t.candidates_started           = z.candidates_started
                 , t.ea_candidates_started        = z.ea_candidates_started
                 , t.targeted_jobs_count          = z.targeted_jobs_count
                 , t.rate_compliance_count        = z.rate_compliance_count
                 , t.candidates_ended             = z.candidates_ended
                 , t.negative_evaluations_count   = z.negative_evaluations_count
                 , t.positive_evaluations_count   = z.positive_evaluations_count
                 , t.adverse_event_count          = z.adverse_event_count
                 , t.submitted_candidates_ratio   = z.submitted_candidates_ratio
                 , t.qualified_candidates_ratio   = z.qualified_candidates_ratio
                 , t.interviewed_candidates_ratio = z.interviewed_candidates_ratio
                 , t.fill_ratio                   = z.fill_ratio
                 , t.supplier_score               = z.supplier_score
                 , t.supplier_rank                = z.supplier_rank2
                 , t.spend_amt                    = z.spend_amt
                 , t.opportunities_received       = z.opportunities_received
          WHEN NOT MATCHED THEN INSERT
               (
                   data_source_code
                 , period_number
                 , buyerorg_id
                 , supplierorg_id
                 , job_category_id
                 , job_category_desc
                 , candidates_submitted
                 , avg_submit_days
                 , avg_submit_bus_days
                 , candidates_forwarded_2hm
                 , avg_fwd_2hm_days
                 , avg_fwd_2hm_bus_days
                 , avg_fwd_2hm_days_4filled
                 , avg_fwd_2hm_bus_days_4filled
                 , candidates_interviewed
                 , avg_time_to_fill_days
                 , candidates_withdrawn
                 , candidates_offered
                 , candidates_declined
                 , candidates_accepted
                 , candidates_started
                 , ea_candidates_started
                 , targeted_jobs_count
                 , rate_compliance_count
                 , candidates_ended
                 , negative_evaluations_count
                 , positive_evaluations_count
                 , adverse_event_count
                 , submitted_candidates_ratio
                 , qualified_candidates_ratio
                 , interviewed_candidates_ratio
                 , fill_ratio
                 , supplier_score
                 , supplier_rank
                 , spend_amt
                 , opportunities_received
               )
               VALUES
               (
                   z.data_source_code
                 , z.period_number
                 , z.buyerorg_id
                 , z.supplierorg_id
                 , z.job_category_id
                 , z.job_category_desc
                 , z.candidates_submitted
                 , z.avg_submit_days
                 , z.avg_submit_bus_days
                 , z.candidates_forwarded_2hm
                 , z.avg_fwd_2hm_days
                 , z.avg_fwd_2hm_bus_days
                 , z.avg_fwd_2hm_days_4filled
                 , z.avg_fwd_2hm_bus_days_4filled
                 , z.candidates_interviewed
                 , z.avg_time_to_fill_days
                 , z.candidates_withdrawn
                 , z.candidates_offered
                 , z.candidates_declined
                 , z.candidates_accepted
                 , z.candidates_started
                 , z.ea_candidates_started
                 , z.targeted_jobs_count
                 , z.rate_compliance_count
                 , z.candidates_ended
                 , z.negative_evaluations_count
                 , z.positive_evaluations_count
                 , z.adverse_event_count
                 , z.submitted_candidates_ratio
                 , z.qualified_candidates_ratio
                 , z.interviewed_candidates_ratio
                 , z.fill_ratio
                 , z.supplier_score
                 , z.supplier_rank2
                 , z.spend_amt
                 , z.opportunities_received
               );

     v_rec_count := SQL%ROWCOUNT;
     COMMIT;
  END gen_fo_monthly_event_summary;

    PROCEDURE gen_std_monthly_event_summary
    (
        p_source_code  IN VARCHAR2
      , p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    )
    IS
         v_rec_count      NUMBER;
    BEGIN
         MERGE INTO dm_supplier_std_summary t
         USING (
                 SELECT   x.*
                        , DENSE_RANK() OVER (PARTITION BY x.std_buyerorg_id, x.std_job_category_id ORDER BY x.supplier_score DESC) AS supplier_rank2
                   FROM TABLE(dm_supp_metrics.gen_supplier_std_ratios(p_source_code, p_period, p_month1, p_month2)) x
               ) z
            ON (
                     z.data_source_code = t.data_source_code
                 AND z.period_number    = t.period_number
                 AND z.std_buyerorg_id      = t.std_buyerorg_id
                 AND z.std_supplierorg_id   = t.std_supplierorg_id
                 AND z.std_job_category_id  = t.std_job_category_id
               )
          WHEN MATCHED THEN UPDATE SET
                   t.std_job_category_desc        = z.std_job_category_desc
                 , t.candidates_submitted         = z.candidates_submitted
                 , t.avg_submit_days              = z.avg_submit_days
                 , t.avg_submit_bus_days          = z.avg_submit_bus_days
                 , t.candidates_forwarded_2hm     = z.candidates_forwarded_2hm
                 , t.avg_fwd_2hm_days             = z.avg_fwd_2hm_days
                 , t.avg_fwd_2hm_bus_days         = z.avg_fwd_2hm_bus_days
                 , t.avg_fwd_2hm_days_4filled     = z.avg_fwd_2hm_days_4filled
                 , t.avg_fwd_2hm_bus_days_4filled = z.avg_fwd_2hm_bus_days_4filled
                 , t.candidates_interviewed       = z.candidates_interviewed
                 , t.avg_time_to_fill_days        = z.avg_time_to_fill_days
                 , t.candidates_withdrawn         = z.candidates_withdrawn
                 , t.candidates_offered           = z.candidates_offered
                 , t.candidates_declined          = z.candidates_declined
                 , t.candidates_accepted          = z.candidates_accepted
                 , t.candidates_started           = z.candidates_started
                 , t.ea_candidates_started        = z.ea_candidates_started
                 , t.targeted_jobs_count          = z.targeted_jobs_count
                 , t.rate_compliance_count        = z.rate_compliance_count
                 , t.candidates_ended             = z.candidates_ended
                 , t.negative_evaluations_count   = z.negative_evaluations_count
                 , t.positive_evaluations_count   = z.positive_evaluations_count
                 , t.adverse_event_count          = z.adverse_event_count
                 , t.submitted_candidates_ratio   = z.submitted_candidates_ratio
                 , t.qualified_candidates_ratio   = z.qualified_candidates_ratio
                 , t.interviewed_candidates_ratio = z.interviewed_candidates_ratio
                 , t.fill_ratio                   = z.fill_ratio
                 , t.supplier_score               = z.supplier_score
                 , t.supplier_rank                = z.supplier_rank2
                 , t.spend_amt                    = z.spend_amt
          WHEN NOT MATCHED THEN INSERT
               (
                   data_source_code
                 , period_number
                 , std_buyerorg_id
                 , std_supplierorg_id
                 , std_job_category_id
                 , std_job_category_desc
                 , candidates_submitted
                 , avg_submit_days
                 , avg_submit_bus_days
                 , candidates_forwarded_2hm
                 , avg_fwd_2hm_days
                 , avg_fwd_2hm_bus_days
                 , avg_fwd_2hm_days_4filled
                 , avg_fwd_2hm_bus_days_4filled
                 , candidates_interviewed
                 , avg_time_to_fill_days
                 , candidates_withdrawn
                 , candidates_offered
                 , candidates_declined
                 , candidates_accepted
                 , candidates_started
                 , ea_candidates_started
                 , targeted_jobs_count
                 , rate_compliance_count
                 , candidates_ended
                 , negative_evaluations_count
                 , positive_evaluations_count
                 , adverse_event_count
                 , submitted_candidates_ratio
                 , qualified_candidates_ratio
                 , interviewed_candidates_ratio
                 , fill_ratio
                 , supplier_score
                 , supplier_rank
                 , spend_amt
               )
               VALUES
               (
                   z.data_source_code
                 , z.period_number
                 , z.std_buyerorg_id
                 , z.std_supplierorg_id
                 , z.std_job_category_id
                 , z.std_job_category_desc
                 , z.candidates_submitted
                 , z.avg_submit_days
                 , z.avg_submit_bus_days
                 , z.candidates_forwarded_2hm
                 , z.avg_fwd_2hm_days
                 , z.avg_fwd_2hm_bus_days
                 , z.avg_fwd_2hm_days_4filled
                 , z.avg_fwd_2hm_bus_days_4filled
                 , z.candidates_interviewed
                 , z.avg_time_to_fill_days
                 , z.candidates_withdrawn
                 , z.candidates_offered
                 , z.candidates_declined
                 , z.candidates_accepted
                 , z.candidates_started
                 , z.ea_candidates_started
                 , z.targeted_jobs_count
                 , z.rate_compliance_count
                 , z.candidates_ended
                 , z.negative_evaluations_count
                 , z.positive_evaluations_count
                 , z.adverse_event_count
                 , z.submitted_candidates_ratio
                 , z.qualified_candidates_ratio
                 , z.interviewed_candidates_ratio
                 , z.fill_ratio
                 , z.supplier_score
                 , z.supplier_rank2
                 , z.spend_amt
               );

     v_rec_count := SQL%ROWCOUNT;
     COMMIT;
    END gen_std_monthly_event_summary;

    PROCEDURE gen_std_monthly_summary_forall
    (
        p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    )
    IS
         v_rec_count      NUMBER;
    BEGIN
         MERGE INTO dm_supplier_std_summary t
         USING (
                 SELECT   x.*
                        , DENSE_RANK() OVER (PARTITION BY x.std_job_category_id ORDER BY x.supplier_score DESC) AS supplier_rank2
                   FROM TABLE(dm_supp_metrics.gen_supplier_std_ratios_forall(p_period, p_month1, p_month2)) x
               ) z
            ON (
                     z.data_source_code     = t.data_source_code
                 AND z.period_number        = t.period_number
                 AND z.std_buyerorg_id      = t.std_buyerorg_id
                 AND z.std_supplierorg_id   = t.std_supplierorg_id
                 AND z.std_job_category_id  = t.std_job_category_id
               )
          WHEN MATCHED THEN UPDATE SET
                   t.std_job_category_desc        = z.std_job_category_desc
                 , t.candidates_submitted         = z.candidates_submitted
                 , t.avg_submit_days              = z.avg_submit_days
                 , t.avg_submit_bus_days          = z.avg_submit_bus_days
                 , t.candidates_forwarded_2hm     = z.candidates_forwarded_2hm
                 , t.avg_fwd_2hm_days             = z.avg_fwd_2hm_days
                 , t.avg_fwd_2hm_bus_days         = z.avg_fwd_2hm_bus_days
                 , t.avg_fwd_2hm_days_4filled     = z.avg_fwd_2hm_days_4filled
                 , t.avg_fwd_2hm_bus_days_4filled = z.avg_fwd_2hm_bus_days_4filled
                 , t.candidates_interviewed       = z.candidates_interviewed
                 , t.avg_time_to_fill_days        = z.avg_time_to_fill_days
                 , t.candidates_withdrawn         = z.candidates_withdrawn
                 , t.candidates_offered           = z.candidates_offered
                 , t.candidates_declined          = z.candidates_declined
                 , t.candidates_accepted          = z.candidates_accepted
                 , t.candidates_started           = z.candidates_started
                 , t.ea_candidates_started        = z.ea_candidates_started
                 , t.targeted_jobs_count          = z.targeted_jobs_count
                 , t.rate_compliance_count        = z.rate_compliance_count
                 , t.candidates_ended             = z.candidates_ended
                 , t.negative_evaluations_count   = z.negative_evaluations_count
                 , t.positive_evaluations_count   = z.positive_evaluations_count
                 , t.adverse_event_count          = z.adverse_event_count
                 , t.submitted_candidates_ratio   = z.submitted_candidates_ratio
                 , t.qualified_candidates_ratio   = z.qualified_candidates_ratio
                 , t.interviewed_candidates_ratio = z.interviewed_candidates_ratio
                 , t.fill_ratio                   = z.fill_ratio
                 , t.supplier_score               = z.supplier_score
                 , t.supplier_rank                = z.supplier_rank2
                 , t.spend_amt                    = z.spend_amt
                 , t.opportunities_received       = z.opportunities_received
          WHEN NOT MATCHED THEN INSERT
               (
                   data_source_code
                 , period_number
                 , std_buyerorg_id
                 , std_supplierorg_id
                 , std_job_category_id
                 , std_job_category_desc
                 , candidates_submitted
                 , avg_submit_days
                 , avg_submit_bus_days
                 , candidates_forwarded_2hm
                 , avg_fwd_2hm_days
                 , avg_fwd_2hm_bus_days
                 , avg_fwd_2hm_days_4filled
                 , avg_fwd_2hm_bus_days_4filled
                 , candidates_interviewed
                 , avg_time_to_fill_days
                 , candidates_withdrawn
                 , candidates_offered
                 , candidates_declined
                 , candidates_accepted
                 , candidates_started
                 , ea_candidates_started
                 , targeted_jobs_count
                 , rate_compliance_count
                 , candidates_ended
                 , negative_evaluations_count
                 , positive_evaluations_count
                 , adverse_event_count
                 , submitted_candidates_ratio
                 , qualified_candidates_ratio
                 , interviewed_candidates_ratio
                 , fill_ratio
                 , supplier_score
                 , supplier_rank
                 , spend_amt
                 , opportunities_received
               )
               VALUES
               (
                   z.data_source_code
                 , z.period_number
                 , z.std_buyerorg_id
                 , z.std_supplierorg_id
                 , z.std_job_category_id
                 , z.std_job_category_desc
                 , z.candidates_submitted
                 , z.avg_submit_days
                 , z.avg_submit_bus_days
                 , z.candidates_forwarded_2hm
                 , z.avg_fwd_2hm_days
                 , z.avg_fwd_2hm_bus_days
                 , z.avg_fwd_2hm_days_4filled
                 , z.avg_fwd_2hm_bus_days_4filled
                 , z.candidates_interviewed
                 , z.avg_time_to_fill_days
                 , z.candidates_withdrawn
                 , z.candidates_offered
                 , z.candidates_declined
                 , z.candidates_accepted
                 , z.candidates_started
                 , z.ea_candidates_started
                 , z.targeted_jobs_count
                 , z.rate_compliance_count
                 , z.candidates_ended
                 , z.negative_evaluations_count
                 , z.positive_evaluations_count
                 , z.adverse_event_count
                 , z.submitted_candidates_ratio
                 , z.qualified_candidates_ratio
                 , z.interviewed_candidates_ratio
                 , z.fill_ratio
                 , z.supplier_score
                 , z.supplier_rank2
                 , z.spend_amt
                 , z.opportunities_received
               );

     v_rec_count := SQL%ROWCOUNT;
     COMMIT;
    END gen_std_monthly_summary_forall;

    FUNCTION in_the_period
    (
        p_month        IN VARCHAR2 -- Month (as YYYYMM)
      , p_month_from   IN VARCHAR2 -- Month (as YYYYMM)
      , p_month_to     IN VARCHAR2 -- Month (as YYYYMM)
    )
    RETURN NUMBER
    IS
    BEGIN
          IF (p_month IS NULL OR p_month_from IS NULL)
             THEN
                  RETURN(TO_NUMBER(NULL));
             ELSE
                  IF (p_month_to IS NULL)
                     THEN
                           IF (p_month = p_month_from)
                              THEN
                                   RETURN(1);
                              ELSE
                                   RETURN(0);
                           END IF;
                     ELSE
                           IF (p_month >= p_month_from AND p_month <= p_month_to)
                              THEN
                                   RETURN(1);
                              ELSE
                                   RETURN(0);
                           END IF;
                  END IF;
          END IF;
    END in_the_period;

    FUNCTION gen_supplier_ratios
    (
        p_source_code  IN VARCHAR2
      , p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    )
    RETURN supSmryTab PIPELINED
    IS
         c1 supSmryCur;
         vInpRecs supSmryTab;
         v_prev_buyer_id NUMBER;
         v_prev_std_buyer_id NUMBER;
         v_crnt_std_buyer_id NUMBER;
         TYPE nameTab      IS TABLE OF dm_supplier_score_weights.value_name%TYPE;
         TYPE weightTab    IS TABLE OF dm_supplier_score_weights.value_weight%TYPE;
         v_advese_names    nameTab;
         v_score_names     nameTab;
         v_advese_weights  weightTab;
         v_score_weights   weightTab;
         v_adverse_count    NUMBER;
         v_supplier_score  NUMBER;
    BEGIN
             OPEN c1 FOR
             WITH jobs_touched AS
             (
               SELECT d.data_source_code, d.buyerorg_id, d.job_id, d.event_attribute6 AS assignment_id, j.job_category_id
                 FROM dm_job_supplier_event_details d, dm_jobs j
                WHERE d.event_type = 'Assignment Created'
                  AND d.event_attribute5 = 'WO'
                  AND d.data_source_code = p_source_code
                  AND j.job_id = d.job_id
                  AND d.event_date >= TO_DATE(p_month1, 'YYYYMM')
                  AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                  AND j.has_sole_supplier_flag = 'N'
             ),
                  targeted_jobs AS
             (
               SELECT d.data_source_code, d.buyerorg_id, d.job_id, d.event_attribute6 AS assignment_id, j.job_category_id
                 FROM dm_job_supplier_event_details d, dm_jobs j
                WHERE d.event_type = 'Assignment Started'
                  AND d.event_attribute5 = 'WO'
                  AND d.data_source_code = p_source_code
                  AND j.job_id = d.job_id
                  AND d.event_date >= TO_DATE(p_month1, 'YYYYMM')
                  AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                  AND j.has_sole_supplier_flag = 'Y'
             ),
                  jobs_started AS
             (
               SELECT d.data_source_code, d.buyerorg_id, d.job_id, d.event_attribute6 AS assignment_id, j.job_category_id
                 FROM dm_job_supplier_event_details d, dm_jobs j
                WHERE d.event_type = 'Assignment Started'
                  AND d.event_attribute5 = 'WO'
                  AND d.data_source_code = p_source_code
                  AND j.job_id = d.job_id
                  AND d.event_date >= TO_DATE(p_month1, 'YYYYMM')
                  AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 2) - 1
                  AND j.has_sole_supplier_flag = 'N'
                  AND EXISTS (select 'x'
                                from jobs_touched jt
                               where jt.job_id = d.job_id
                                 and jt.assignment_id = d.event_attribute6
                                 and jt.data_source_code = d.data_source_code)
             ),
                  job_pa_events AS
             (
                SELECT d.*
                  FROM dm_job_supplier_event_details d
                 WHERE EXISTS (
                                SELECT NULL
                                  FROM jobs_touched jt
                                 WHERE jt.job_id = d.job_id
                                   AND jt.data_source_code = d.data_source_code
                              )
                   AND d.event_type IN ('Candidate Submitted', 'Forwarded to Hiring Manager', 'Interview Scheduled/Pending')
                   AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                   AND d.data_source_code = d.data_source_code
             ),
                  spend_sum AS
             (
               SELECT   p_source_code              AS data_source_code
                      , buyer_bus_org_fk           AS buyerorg_id
                      , supplier_bus_org_fk        AS supplierorg_id
                      , UPPER(job_category)        AS job_category_desc
                      , SUM(buyer_adjusted_amount) AS spend_amt
                 FROM dm_spend_summary
                WHERE month_number BETWEEN p_month1 AND NVL(p_month2, p_month1)
                GROUP BY buyer_bus_org_fk, supplier_bus_org_fk, UPPER(job_category)
             )
             SELECT /*+ dynamic_sampling(jct 10) */
                      z.data_source_code
                    , z.period_number
                    , z.buyerorg_id
                    , z.supplierorg_id
                    , z.job_category_id
                    , z.candidates_submitted
                    , GREATEST(z.avg_submit_days, 0) avg_submit_days
                    , LEAST(z.avg_submit_bus_days, GREATEST(z.avg_submit_days, 0)) avg_submit_bus_days
                    , z.candidates_forwarded_2hm
                    , z.avg_fwd_2hm_days
                    , z.avg_fwd_2hm_bus_days
                    , z.avg_fwd_2hm_days_4filled
                    , z.avg_fwd_2hm_bus_days_4filled
                    , z.candidates_interviewed
                    , z.avg_time_to_fill_days
                    , z.candidates_withdrawn
                    , z.candidates_offered
                    , z.candidates_declined
                    , z.candidates_accepted
                    , z.candidates_started
                    , z.ea_candidates_started
                    , z.rate_compliance_count
                    , z.candidates_ended
                    , z.negative_evaluations_count
                    , GREATEST((z.candidates_ended-z.negative_evaluations_count), 0) AS positive_evaluations_count
                    --, z.targeted_jobs_count -- This is replaced with targeted_jobs with clause where has_sole_supplier_flag = 'Y'
                    , NVL(tj.targeted_jobs_count,0) as targeted_jobs_count
                    , jct.job_category_desc
                    , CAST (0 AS NUMBER(10,4)) AS adverse_event_count
                    , CAST (0 AS NUMBER(10,4)) AS submitted_candidates_ratio
                    , CAST (0 AS NUMBER(10,4)) AS qualified_candidates_ratio
                    , CAST (0 AS NUMBER(10,4)) AS interviewed_candidates_ratio
                    , CAST (0 AS NUMBER(10,4)) AS fill_ratio
                    , CAST (0 AS NUMBER(12,4)) AS supplier_score
                    , CAST (0 AS NUMBER      ) AS supplier_rank
                    , NVL(ss.spend_amt, 0)     AS spend_amt
                    , op.opportunity_count     AS opportunities_received
               FROM (
                      SELECT   y.data_source_code
                             , y.period_number
                             , y.buyerorg_id
                             , y.supplierorg_id
                             , y.job_category_id
                             , MIN(y.job_category_desc) AS job_category_desc
                             , SUM(y.submit_count) AS candidates_submitted
                             , AVG(y.time_to_submit) AS avg_submit_days
                             , AVG(y.time2submit_bdays) AS avg_submit_bus_days
                             , SUM(y.fwd2hm_count) AS candidates_forwarded_2hm
                             , AVG(y.time_to_fwd2hm) AS avg_fwd_2hm_days
                             , AVG(y.time2fwd2hm_bdays) AS avg_fwd_2hm_bus_days
                             , AVG(y.time_to_fwd2hm_4filled) AS avg_fwd_2hm_days_4filled
                             , AVG(y.time2fwd2hm_bdays_4filled) AS avg_fwd_2hm_bus_days_4filled
                             , SUM(y.intw_count) AS candidates_interviewed
                             , AVG(y.time_to_fill) AS avg_time_to_fill_days
                             , SUM(y.withdrawn_count) AS candidates_withdrawn
                             , SUM(y.offer_count) AS candidates_offered
                             , SUM(y.decl_count) AS candidates_declined
                             , SUM(y.acpt_count) AS candidates_accepted
                             , SUM(y.start_count) AS candidates_started
                             , SUM(y.start_ea_count) AS ea_candidates_started
                             , SUM(y.target_job_count) AS targeted_jobs_count
                             , SUM(y.rate_compl_count) AS rate_compliance_count
                             , SUM(y.ended_count) AS candidates_ended
                             , SUM(y.negative_evaluations_count) AS negative_evaluations_count
                        FROM (
                               SELECT   x.period_number
                                      , x.data_source_code
                                      , x.buyerorg_id
                                      , x.supplierorg_id
                                      , x.job_opportunity_id
                                      , x.job_category_id
                                      , x.job_category_desc
                                      , DECODE(in_the_period(x.jo_month_number, p_month1, p_month2), 1, x.job_opportunity_id, NULL) current_period_opp_id
                                      , x.candidate_id
                                      , x.submit_count
                                      , ROUND((x.submit_time-x.jo_create_date), 4) time_to_submit
                                      , dm_utils.bdays(x.jo_create_date,x.submit_time) time2submit_bdays
                                      , x.fwd2hm_count
                                      , ROUND((x.fwd2hm_time -x.submit_time), 4) time_to_fwd2hm
                                      , DECODE(x.start_count, 0, NULL, ROUND((x.fwd2hm_time -x.submit_time), 4)) time_to_fwd2hm_4filled
                                      , dm_utils.bdays(x.submit_time,x.fwd2hm_time) time2fwd2hm_bdays
                                      , DECODE(x.start_count, 0, NULL, dm_utils.bdays(x.submit_time,x.fwd2hm_time)) time2fwd2hm_bdays_4filled
                                      , x.intw_count
                                      , ROUND((x.intw_time-x.submit_time), 4) time_to_intw
                                      , x.start_count
                                      , x.start_ea_count
                                      , x.target_job_count
                                      , ROUND((x.fill_time-x.jo_create_date), 4) time_to_fill
                                      , x.offer_count
                                      , x.withdrawn_count
                                      , x.decl_count
                                      , x.acpt_count
                                      , x.ended_count
                                      , x.rate_compl_count
                                      , DECODE(x.ended_count, 0, 0, DECODE(x.terminated_count, 0, DECODE(x.negative_evaluations_count, 0, 0, 1), 1), 0) negative_evaluations_count
                                      , x.job_id
                                 FROM (
                                        SELECT c.period_number, c.data_source_code, c.buyerorg_id, c.supplierorg_id, c.job_opportunity_id, c.candidate_id
                                               , MIN(c.jo_month_number) jo_month_number
                                               , MIN(c.job_category_id) job_category_id
                                               , MIN(c.job_category_desc) job_category_desc
                                               , MIN(c.job_opportunity_create_date) jo_create_date
                                               , SUM(c.submit_count) AS submit_count
                                               , MIN(c.submit_time)  AS submit_time
                                               , SUM(c.fwd2hm_count) AS fwd2hm_count
                                               , MIN(c.fwd2hm_time) AS fwd2hm_time
                                               , SUM(c.intw_count) AS intw_count
                                               , MIN(c.intw_time) AS intw_time
                                               , SUM(c.start_count) AS start_count
                                               , SUM(c.start_ea_count) AS start_ea_count
                                               , SUM(c.target_job_count) AS target_job_count
                                               , MIN(c.fill_time) AS fill_time
                                               , SUM(c.offer_count) AS offer_count
                                               , SUM(c.withdrawn_count) AS withdrawn_count
                                               , SUM(c.decl_count) AS decl_count
                                               , SUM(c.acpt_count) AS acpt_count
                                               , SUM(c.ended_count) AS ended_count
                                               , SUM(c.rate_compl_count) AS rate_compl_count
                                               , SUM(c.negative_evaluations_count) AS negative_evaluations_count
                                               , SUM(c.terminated_count) AS terminated_count
                                               , MAX(c.job_id) AS job_id
                                          FROM (
                                                 SELECT   b.*
                                                        , DECODE(b.event_type, 'Candidate Submitted', 1, 0) submit_count
                                                        , DECODE(b.event_type, 'Candidate Submitted', b.event_date, NULL) submit_time
                                                        , DECODE(b.event_type, 'Forwarded to Hiring Manager', 1, 0) fwd2hm_count
                                                        , DECODE(b.event_type, 'Forwarded to Hiring Manager', b.event_date, NULL) fwd2hm_time
                                                        , DECODE(b.event_type, 'Interview Scheduled/Pending', 1, 0) intw_count
                                                        , DECODE(b.event_type, 'Interview Scheduled/Pending', b.event_date, NULL) intw_time
                                                        , DECODE(b.event_type, 'Assignment Started', 1, 0) start_count
                                                        , DECODE(b.event_type, 'Assignment Started', DECODE(b.event_attribute5,'EA', 1, 0), 0) start_ea_count
                                                        , DECODE(b.event_type, 'Assignment Started', DECODE(b.event_attribute2,'Manual Contract', 1, 0), 0) target_job_count
                                                        , DECODE(b.event_type, 'Assignment Started', b.event_date, NULL) fill_time
                                                        , DECODE(b.event_type, 'Offer Made', 1, 0) offer_count
                                                        , DECODE(b.event_type, 'Candidate Withdrawn', 1, 0) withdrawn_count
                                                        , DECODE(b.event_type, 'Offer Declined', 1, 0) decl_count
                                                        , DECODE(b.event_type, 'Offer Accepted', 1, 0) acpt_count
                                                        , DECODE(b.event_type, 'Assignment Ended', 1, 0) ended_count
                                                        , DECODE(b.event_type, 'Assignment Ended', DECODE(b.event_attribute2, 'TERMINATED', 1, 0), 0) terminated_count
                                                        , DECODE(b.event_type, 'Assignment Started', NVL2(b.rate_range_high, DECODE(SIGN(b.rate_range_high-NVL(b.event_attribute1,0)), -1, 0, 1), 1), NULL) rate_compl_count
                                                        , DECODE(b.event_type, 'Evaluation Performed', 1, 0) negative_evaluations_count
                                                   FROM (
                                                          SELECT   a.*
                                                                 , ROW_NUMBER() OVER
                                                                   (
                                                                     PARTITION BY   a.period_number, a.data_source_code, a.job_opportunity_id
                                                                                  , NVL(a.event_attribute6, 0), a.buyerorg_id
                                                                                  , a.supplierorg_id, a.candidate_id, a.event_type
                                                                         ORDER BY event_date DESC
                                                                   ) AS rnk
                                                            FROM (
                                                                    SELECT   p_period AS period_number
                                                                           , NVL(jpe.data_source_code, s.data_source_code) AS data_source_code
                                                                           , NVL(jpe.buyerorg_id, s.buyerorg_id) AS buyerorg_id
                                                                           , NVL(jpe.job_id, s.job_id) AS job_id
                                                                           , NVL(jpe.job_opportunity_id, s.job_opportunity_id) AS job_opportunity_id
                                                                           , NVL(jpe.supplierorg_id, s.supplierorg_id) AS supplierorg_id
                                                                           , NVL(jpe.event_type, 'DUMMY EVENT') AS event_type
                                                                           , jpe.candidate_id
                                                                           , jpe.event_date
                                                                           , jpe.event_quality_indicator
                                                                           , jpe.event_attribute1
                                                                           , jpe.event_attribute2
                                                                           , jpe.event_attribute3
                                                                           , jpe.event_attribute4
                                                                           , jpe.event_attribute5
                                                                           , jpe.event_attribute6
                                                                           , NVL(s.rate_range_low, j.rate_range_low) AS rate_range_low
                                                                           , NVL(s.rate_range_high, j.rate_range_high) AS rate_range_high
                                                                           , s.job_opportunity_create_date
                                                                           , j.job_category_id
                                                                           , j.job_category_desc
                                                                           , TO_NUMBER(TO_CHAR(s.job_opportunity_create_date, 'YYYYMM')) AS jo_month_number
                                                                      FROM dm_job_supplier_details s, dm_jobs j, job_pa_events jpe
                                                                     WHERE s.data_source_code = p_source_code
                                                                       AND EXISTS (
                                                                                    SELECT NULL
                                                                                      FROM jobs_touched jt
                                                                                     WHERE jt.job_id = s.job_id
                                                                                       AND jt.data_source_code = s.data_source_code
                                                                                  )
                                                                       AND j.data_source_code = s.data_source_code
                                                                       AND j.buyerorg_id = s.buyerorg_id
                                                                       AND j.job_id = s.job_id
                                                                       AND jpe.data_source_code (+)= s.data_source_code
                                                                       AND jpe.job_id (+) = s.job_id
                                                                       AND jpe.job_opportunity_id (+) = s.job_opportunity_id
                                                                       AND jpe.buyerorg_id (+) = s.buyerorg_id
                                                                     UNION ALL
                                                                    SELECT   p_period AS month_number
                                                                           , d.*
                                                                           , NVL(s.rate_range_low, j.rate_range_low) AS rate_range_low
                                                                           , NVL(s.rate_range_high, j.rate_range_high) AS rate_range_high
                                                                           , s.job_opportunity_create_date
                                                                           , j.job_category_id
                                                                           , j.job_category_desc
                                                                           , TO_NUMBER(TO_CHAR(s.job_opportunity_create_date, 'YYYYMM')) AS jo_month_number
                                                                      FROM dm_job_supplier_event_details d, dm_job_supplier_details s, dm_jobs j
                                                                     WHERE d.event_type IN ('Assignment Started', 'Offer Made', 'Offer Accepted')
                                                                       AND d.event_attribute5 = 'WO'
                                                                       AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 2) -1
                                                                       AND d.data_source_code = p_source_code
                                                                       AND EXISTS (
                                                                                    SELECT NULL
                                                                                      FROM jobs_touched jt
                                                                                     WHERE jt.job_id = d.job_id
                                                                                       AND jt.assignment_id = d.event_attribute6
                                                                                       AND jt.data_source_code = d.data_source_code
                                                                                  )
                                                                       AND s.data_source_code = d.data_source_code
                                                                       AND s.job_opportunity_id = d.job_opportunity_id
                                                                       AND s.buyerorg_id = d.buyerorg_id
                                                                       AND s.supplierorg_id = d.supplierorg_id
                                                                       AND j.data_source_code = d.data_source_code
                                                                       AND j.buyerorg_id = d.buyerorg_id
                                                                       AND j.job_id = d.job_id
                                                                     UNION ALL
                                                                    SELECT   p_period AS month_number
                                                                           , d.*
                                                                           , NVL(s.rate_range_low, j.rate_range_low) AS rate_range_low
                                                                           , NVL(s.rate_range_high, j.rate_range_high) AS rate_range_high
                                                                           , s.job_opportunity_create_date
                                                                           , j.job_category_id
                                                                           , j.job_category_desc
                                                                           , TO_NUMBER(TO_CHAR(s.job_opportunity_create_date, 'YYYYMM')) AS jo_month_number
                                                                      FROM dm_job_supplier_event_details d, dm_job_supplier_details s, dm_jobs j
                                                                     WHERE (
                                                                                 d.event_type IN ('Candidate Withdrawn', 'Offer Declined', 'Assignment Ended')
                                                                              OR
                                                                                 (
                                                                                        d.event_type = 'Evaluation Performed'
                                                                                    AND SIGN(d.event_attribute2) = -1
                                                                                 )
                                                                           )
                                                                       AND d.event_attribute5 = 'WO'
                                                                       AND d.event_date >= TO_DATE(p_month1, 'YYYYMM')
                                                                       AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                                                                       AND d.data_source_code = p_source_code
                                                                       AND s.data_source_code = d.data_source_code
                                                                       AND s.job_opportunity_id = d.job_opportunity_id
                                                                       AND s.buyerorg_id = d.buyerorg_id
                                                                       AND s.supplierorg_id = d.supplierorg_id
                                                                       AND j.data_source_code = d.data_source_code
                                                                       AND j.buyerorg_id = d.buyerorg_id
                                                                       AND j.job_id = d.job_id
                                                                 ) a
                                                        ) b
                                                  WHERE b.rnk < 2
                                               ) c
                                         GROUP BY c.period_number, c.data_source_code, c.buyerorg_id, c.supplierorg_id, c.job_opportunity_id, c.candidate_id
                                      ) x
                             ) y
                       GROUP BY y.period_number, y.data_source_code, y.buyerorg_id, y.supplierorg_id, y.job_category_id
                    ) z,
                    (
                        SELECT s.data_source_code, s.buyerorg_id, s.supplierorg_id, js.job_category_id, COUNT(DISTINCT s.job_id) AS opportunity_count
                           FROM dm_job_supplier_details s, jobs_started js
                          WHERE s.data_source_code = p_source_code
                            AND js.job_id = s.job_id
                            AND js.data_source_code = s.data_source_code
                          GROUP BY s.data_source_code, s.buyerorg_id, s.supplierorg_id, js.job_category_id
                    ) op,
                    (
                        SELECT s.data_source_code, s.buyerorg_id, s.supplierorg_id, tj.job_category_id, COUNT(*) AS targeted_jobs_count
                           FROM dm_job_supplier_details s, targeted_jobs tj
                          WHERE s.data_source_code = p_source_code
                            AND tj.job_id = s.job_id
                            AND tj.data_source_code = s.data_source_code
                          GROUP BY s.data_source_code, s.buyerorg_id, s.supplierorg_id, tj.job_category_id
                    ) tj,
                    fo_dm_job_category_tmp jct,
                    spend_sum ss
              WHERE op.buyerorg_id           = z.buyerorg_id
                AND op.job_category_id       = z.job_category_id
                AND op.supplierorg_id        = z.supplierorg_id
                AND op.data_source_code      = z.data_source_code
                AND jct.data_source_code     = z.data_source_code
                AND jct.job_category_id      = z.job_category_id
                AND tj.buyerorg_id       (+) = z.buyerorg_id
                AND tj.job_category_id   (+) = z.job_category_id
                AND tj.supplierorg_id    (+) = z.supplierorg_id
                AND tj.data_source_code  (+) = z.data_source_code
                AND ss.buyerorg_id       (+) = z.buyerorg_id
                AND ss.job_category_desc (+) = jct.job_category_desc
                AND ss.supplierorg_id    (+) = z.supplierorg_id
                AND ss.data_source_code  (+) = z.data_source_code;

         v_prev_buyer_id     := -1;
         v_prev_std_buyer_id := -1;
         v_crnt_std_buyer_id := -1;
         LOOP
              FETCH c1 BULK COLLECT INTO vInpRecs LIMIT 1000;
              FOR i IN 1 .. vInpRecs.COUNT
              LOOP
                   /*
                   ** Input data from Cursor (c1) is expected to be sorted by buyerorg_id
                   ** When ever buyer new/changing
                   ** Get Buyer specific weight/scoring metadata
                   ** The queries fetch generic metadata incase
                   ** buyer specific overrides are not avaliable
                   */
                   IF (v_prev_buyer_id != vInpRecs(i).buyerorg_id )
                      THEN
                           v_prev_buyer_id := vInpRecs(i).buyerorg_id;
                           BEGIN
                                  SELECT bm.std_buyerorg_id
                                    INTO v_crnt_std_buyer_id
                                    FROM fo_buyers_map bm
                                   WHERE bm.data_source_code = p_source_code
                                     AND bm.buyerorg_id = v_prev_buyer_id
                                     AND bm.std_buyerorg_id > 0
                                     AND bm.is_test_org = 'N';
                           EXCEPTION
                               WHEN NO_DATA_FOUND THEN v_crnt_std_buyer_id := 0;
                           END;

                           IF (v_prev_std_buyer_id != v_crnt_std_buyer_id)
                              THEN
                                    v_prev_std_buyer_id := v_crnt_std_buyer_id;
                                    SELECT x.value_name, x.value_weight
                                      BULK COLLECT INTO v_advese_names, v_advese_weights
                                      FROM (
                                             SELECT   w.value_name
                                                    , w.value_weight
                                                    , ROW_NUMBER() OVER (PARTITION BY w.value_name ORDER BY w.std_buyerorg_id DESC) AS rnk
                                               FROM dm_supplier_score_weights w
                                              WHERE w.data_source_code = p_source_code
                                                AND w.weight_type = 'AdverseEventScore'
                                                AND w.std_buyerorg_id IN (0, v_crnt_std_buyer_id)
                                           ) x
                                     WHERE x.rnk < 2;

                                    SELECT x.value_name, x.value_weight
                                      BULK COLLECT INTO v_score_names, v_score_weights
                                      FROM (
                                             SELECT   w.value_name
                                                    , w.value_weight
                                                    , ROW_NUMBER() OVER (PARTITION BY w.value_name ORDER BY w.std_buyerorg_id DESC) AS rnk
                                               FROM dm_supplier_score_weights w
                                              WHERE w.data_source_code = p_source_code
                                                AND w.weight_type = 'SupplierScore'
                                                AND w.std_buyerorg_id IN (0, v_crnt_std_buyer_id)
                                           ) x
                                     WHERE x.rnk < 2;
                           END IF;
                   END IF;

                   v_adverse_count := vInpRecs(i).negative_evaluations_count;
                   --v_adverse_count := 0;
                   --FOR j IN 1 .. v_advese_names.COUNT
                   --LOOP
                   --     CASE v_advese_names(j)
                   --          WHEN 'NEGATIVE_EVALUATIONS_COUNT' THEN v_adverse_count := v_adverse_count + vInpRecs(i).negative_evaluations_count*v_advese_weights(j);
                   --          WHEN 'CANDIDATES_ENDED_NEGATIVE'  THEN v_adverse_count := v_adverse_count + vInpRecs(i).candidates_ended_negative*v_advese_weights(j);

                   --          WHEN 'CANDIDATES_WITHDRAWN'       THEN v_adverse_count := v_adverse_count + vInpRecs(i).candidates_withdrawn*v_advese_weights(j);
                   --          ELSE NULL;
                   --     END CASE;
                   --END LOOP;
                   vInpRecs(i).adverse_event_count := v_adverse_count;

                   IF (vInpRecs(i).opportunities_received IS NULL OR vInpRecs(i).opportunities_received = 0)
                      THEN
                            vInpRecs(i).submitted_candidates_ratio := 0;
                      ELSE
                            vInpRecs(i).submitted_candidates_ratio := vInpRecs(i).candidates_submitted/vInpRecs(i).opportunities_received;
                   END IF;

                   IF (vInpRecs(i).candidates_submitted = 0)
                      THEN
                            vInpRecs(i).qualified_candidates_ratio   := 0;
                            vInpRecs(i).interviewed_candidates_ratio := 0;
                            vInpRecs(i).fill_ratio                   := 0;
                      ELSE
                            vInpRecs(i).qualified_candidates_ratio   := vInpRecs(i).candidates_forwarded_2hm/vInpRecs(i).candidates_submitted;
                            vInpRecs(i).interviewed_candidates_ratio := vInpRecs(i).candidates_interviewed/vInpRecs(i).candidates_submitted;
                            vInpRecs(i).fill_ratio                   := vInpRecs(i).candidates_started/vInpRecs(i).candidates_submitted;
                   END IF;

                   IF (vInpRecs(i).candidates_ended = 0 AND vInpRecs(i).candidates_started = 0 AND vInpRecs(i).candidates_submitted = 0 AND vInpRecs(i).candidates_withdrawn = 0 AND vInpRecs(i).negative_evaluations_count = 0)
                      THEN
                            v_supplier_score := NULL;
                      ELSE
                            v_supplier_score := 0;
                            FOR j IN 1 .. v_score_names.COUNT
                            LOOP
                                 CASE v_score_names(j)
                                      WHEN 'ADVERSE_EVENT_SCORE'          THEN v_supplier_score := v_supplier_score + v_adverse_count*v_score_weights(j);
                                      WHEN 'FILL_RATIO'                   THEN v_supplier_score := v_supplier_score + vInpRecs(i).fill_ratio*v_score_weights(j);
                                      WHEN 'INTERVIEWED_CANDIDATES_RATIO' THEN v_supplier_score := v_supplier_score + vInpRecs(i).interviewed_candidates_ratio*v_score_weights(j);
                                      WHEN 'QUALIFIED_CANDIDATES_RATIO'   THEN v_supplier_score := v_supplier_score + vInpRecs(i).qualified_candidates_ratio*v_score_weights(j);
                                      WHEN 'SUBMITTED_CANDIDATES_RATIO'   THEN v_supplier_score := v_supplier_score + vInpRecs(i).submitted_candidates_ratio*v_score_weights(j);
                                      ELSE NULL;
                                 END CASE;
                            END LOOP;
                   END IF;
                   vInpRecs(i).supplier_score := v_supplier_score;
                   PIPE ROW(vInpRecs(i));
              END LOOP;
              EXIT WHEN c1%NOTFOUND;
         END LOOP;
         CLOSE c1;

    END gen_supplier_ratios;

    FUNCTION gen_supplier_std_ratios
    (
        p_source_code  IN VARCHAR2
      , p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    )
    RETURN supStdSmryTab PIPELINED
    IS
         c1 supStdSmryCur;
         vInpRecs supStdSmryTab;
         v_prev_buyer_id NUMBER;
         TYPE nameTab     IS TABLE OF dm_supplier_score_weights.value_name%TYPE;
         TYPE weightTab   IS TABLE OF dm_supplier_score_weights.value_weight%TYPE;
         v_advese_names    nameTab;
         v_score_names     nameTab;
         v_advese_weights  weightTab;
         v_score_weights   weightTab;
         v_adverse_count    NUMBER;
         v_supplier_score  NUMBER;
    BEGIN
             OPEN c1 FOR
             WITH jobs_touched AS
             (
               SELECT d.data_source_code, j.std_buyerorg_id, d.buyerorg_id, d.job_id, d.event_attribute6 as assignment_id
                 FROM dm_job_supplier_event_details d, dm_jobs j
                WHERE d.event_type = 'Assignment Created'
                  AND d.event_attribute5 = 'WO'
                  AND d.data_source_code = p_source_code
                  AND j.job_id = d.job_id
                  AND d.event_date >= TO_DATE(p_month1, 'YYYYMM')
                  AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                  AND j.has_sole_supplier_flag = 'N'
                  AND j.std_buyerorg_id > 0
                  AND j.std_job_category_id > 0
             ),
                  spend_sum AS
             (
               SELECT   p_source_code AS data_source_code
                      , x.std_buyerorg_id
                      , x.std_supplierorg_id
                      , x.std_job_category_id
                      , SUM(x.buyer_adjusted_amount) AS spend_amt
                 FROM (
                        SELECT   bm.std_buyerorg_id
                               , sm.std_supplierorg_id
                               , dj.std_job_category_id
                               , sp.buyer_adjusted_amount
                               , ROW_NUMBER() OVER (PARTITION BY bm.buyerorg_id, sm.supplierorg_id, mp.job_title ORDER BY mp.std_job_title_id) AS rnk
                          FROM dm_spend_summary sp, dm_fo_title_map mp, dm_job_titles dj, fo_suppliers_map sm, fo_buyers_map bm
                         WHERE sp.month_number BETWEEN p_month1 AND NVL(p_month2, p_month1)
                           AND mp.data_source_code = p_source_code
                           AND mp.buyerorg_id      = sp.buyer_bus_org_fk
                           AND mp.job_title        = UPPER(LTRIM(RTRIM(sp.job_title)))
                           AND bm.buyerorg_id      = mp.buyerorg_id
                           AND bm.data_source_code = mp.data_source_code
                           AND dj.std_job_title_id = mp.std_job_title_id
                           AND dj.is_deleted       = 'N'
                           AND dj.std_job_category_id > 0
                           AND sm.data_source_code = p_source_code
                           AND sm.supplierorg_id   = sp.supplier_bus_org_fk
                           AND sm.std_supplierorg_id > 0
                      ) x
                WHERE x.rnk = 1
                GROUP BY  x.std_buyerorg_id, x.std_supplierorg_id, x.std_job_category_id
             )
             SELECT   z.data_source_code
                    , z.period_number
                    , z.std_buyerorg_id
                    , z.std_supplierorg_id
                    , z.std_job_category_id
                    , z.candidates_submitted
                    , GREATEST(z.avg_submit_days, 0) avg_submit_days
                    , LEAST(z.avg_submit_bus_days, GREATEST(z.avg_submit_days, 0)) avg_submit_bus_days
                    , z.candidates_forwarded_2hm
                    , z.avg_fwd_2hm_days
                    , z.avg_fwd_2hm_bus_days
                    , z.avg_fwd_2hm_days_4filled
                    , z.avg_fwd_2hm_bus_days_4filled
                    , z.candidates_interviewed
                    , z.avg_time_to_fill_days
                    , z.candidates_withdrawn
                    , z.candidates_offered
                    , z.candidates_declined
                    , z.candidates_accepted
                    , z.candidates_started
                    , z.ea_candidates_started
                    , z.rate_compliance_count
                    , z.candidates_ended
                    , z.negative_evaluations_count
                    , (z.candidates_ended-z.negative_evaluations_count) AS positive_evaluations_count
                    , z.targeted_jobs_count
                    , jc.std_job_category_desc
                    , CAST (0 AS NUMBER(10,4)) AS adverse_event_count
                    , CAST (0 AS NUMBER(10,4)) AS submitted_candidates_ratio
                    , CAST (0 AS NUMBER(10,4)) AS qualified_candidates_ratio
                    , CAST (0 AS NUMBER(10,4)) AS interviewed_candidates_ratio
                    , CAST (0 AS NUMBER(10,4)) AS fill_ratio
                    , CAST (0 AS NUMBER(12,4)) AS supplier_score
                    , CAST (0 AS NUMBER      ) AS supplier_rank
                    , NVL(ss.spend_amt, 0)     AS spend_amt
                    , CAST (NULL AS NUMBER   ) AS opportunities_received
               FROM (
                      SELECT   y.data_source_code
                             , y.period_number
                             , y.std_buyerorg_id
                             , y.std_supplierorg_id
                             , y.std_job_category_id
                             , SUM(y.submit_count) AS candidates_submitted
                             , AVG(y.time_to_submit) AS avg_submit_days
                             , AVG(y.time2submit_bdays) AS avg_submit_bus_days
                             , SUM(y.fwd2hm_count) AS candidates_forwarded_2hm
                             , AVG(y.time_to_fwd2hm) AS avg_fwd_2hm_days
                             , AVG(y.time2fwd2hm_bdays) AS avg_fwd_2hm_bus_days
                             , AVG(y.time_to_fwd2hm_4filled) AS avg_fwd_2hm_days_4filled
                             , AVG(y.time2fwd2hm_bdays_4filled) AS avg_fwd_2hm_bus_days_4filled
                             , SUM(y.intw_count) AS candidates_interviewed
                             , AVG(y.time_to_fill) AS avg_time_to_fill_days
                             , SUM(y.withdrawn_count) AS candidates_withdrawn
                             , SUM(y.offer_count) AS candidates_offered
                             , SUM(y.decl_count) AS candidates_declined
                             , SUM(y.acpt_count) AS candidates_accepted
                             , SUM(y.start_count) AS candidates_started
                             , SUM(y.start_ea_count) AS ea_candidates_started
                             , SUM(y.target_job_count) AS targeted_jobs_count
                             , SUM(y.rate_compl_count) AS rate_compliance_count
                             , SUM(y.ended_count) AS candidates_ended
                             , SUM(y.negative_evaluations_count) AS negative_evaluations_count
                        FROM (
                               SELECT   x.period_number
                                      , x.data_source_code
                                      , x.std_buyerorg_id
                                      , x.std_supplierorg_id
                                      , x.job_opportunity_id
                                      , x.std_job_category_id
                                      , DECODE(in_the_period(x.jo_month_number, p_month1, p_month2), 1, x.job_opportunity_id, NULL) current_period_opp_id
                                      , x.candidate_id
                                      , x.submit_count
                                      , ROUND((x.submit_time-x.jo_create_date), 4) time_to_submit
                                      , dm_utils.bdays(x.jo_create_date,x.submit_time) time2submit_bdays
                                      , x.fwd2hm_count
                                      , ROUND((x.fwd2hm_time -x.submit_time), 4) time_to_fwd2hm
                                      , DECODE(x.start_count, 0, NULL, ROUND((x.fwd2hm_time -x.submit_time), 4)) time_to_fwd2hm_4filled
                                      , dm_utils.bdays(x.submit_time,x.fwd2hm_time) time2fwd2hm_bdays
                                      , DECODE(x.start_count, 0, NULL, dm_utils.bdays(x.submit_time,x.fwd2hm_time)) time2fwd2hm_bdays_4filled
                                      , x.intw_count
                                      , ROUND((x.intw_time-x.submit_time), 4) time_to_intw
                                      , x.start_count
                                      , x.start_ea_count
                                      , x.target_job_count
                                      , ROUND((x.fill_time-x.jo_create_date), 4) time_to_fill
                                      , x.offer_count
                                      , x.withdrawn_count
                                      , x.decl_count
                                      , x.acpt_count
                                      , x.ended_count
                                      , x.rate_compl_count
                                      , DECODE(x.terminated_count, 0, DECODE(x.negative_evaluations_count, 0, 0, 1), 1) negative_evaluations_count
                                 FROM (
                                        SELECT   c.period_number, c.data_source_code, c.std_buyerorg_id, c.std_supplierorg_id, c.job_opportunity_id, c.candidate_id
                                               , MIN(c.jo_month_number) jo_month_number
                                               , MIN(c.std_job_category_id) std_job_category_id
                                               , MIN(c.job_opportunity_create_date) jo_create_date
                                               , SUM(c.submit_count) AS submit_count
                                               , MIN(c.submit_time)  AS submit_time
                                               , SUM(c.fwd2hm_count) AS fwd2hm_count
                                               , MIN(c.fwd2hm_time) AS fwd2hm_time
                                               , SUM(c.intw_count) AS intw_count
                                               , MIN(c.intw_time) AS intw_time
                                               , SUM(c.start_count) AS start_count
                                               , SUM(c.start_ea_count) AS start_ea_count
                                               , SUM(c.target_job_count) AS target_job_count
                                               , MIN(c.fill_time) AS fill_time
                                               , SUM(c.offer_count) AS offer_count
                                               , SUM(c.withdrawn_count) AS withdrawn_count
                                               , SUM(c.decl_count) AS decl_count
                                               , SUM(c.acpt_count) AS acpt_count
                                               , SUM(c.ended_count) AS ended_count
                                               , SUM(c.rate_compl_count) AS rate_compl_count
                                               , SUM(c.negative_evaluations_count) AS negative_evaluations_count
                                               , SUM(c.terminated_count) AS terminated_count
                                          FROM (
                                                 SELECT   b.*
                                                        , DECODE(b.event_type, 'Candidate Submitted', 1, 0) submit_count
                                                        , DECODE(b.event_type, 'Candidate Submitted', b.event_date, NULL) submit_time
                                                        , DECODE(b.event_type, 'Forwarded to Hiring Manager', 1, 0) fwd2hm_count
                                                        , DECODE(b.event_type, 'Forwarded to Hiring Manager', b.event_date, NULL) fwd2hm_time
                                                        , DECODE(b.event_type, 'Interview Scheduled/Pending', 1, 0) intw_count
                                                        , DECODE(b.event_type, 'Interview Scheduled/Pending', b.event_date, NULL) intw_time
                                                        , DECODE(b.event_type, 'Assignment Started', 1, 0) start_count
                                                        , DECODE(b.event_type, 'Assignment Started', DECODE(b.event_attribute5,'EA', 1, 0), 0) start_ea_count
                                                        , DECODE(b.event_type, 'Assignment Started', DECODE(b.event_attribute2,'Manual Contract', 1, 0), 0) target_job_count
                                                        , DECODE(b.event_type, 'Assignment Started', b.event_date, NULL) fill_time
                                                        , DECODE(b.event_type, 'Offer Made', 1, 0) offer_count
                                                        , DECODE(b.event_type, 'Candidate Withdrawn', 1, 0) withdrawn_count
                                                        , DECODE(b.event_type, 'Offer Declined', 1, 0) decl_count
                                                        , DECODE(b.event_type, 'Offer Accepted', 1, 0) acpt_count
                                                        , DECODE(b.event_type, 'Assignment Ended', 1, 0) ended_count
                                                        , DECODE(b.event_type, 'Assignment Ended', DECODE(b.event_attribute2, 'TERMINATED', 1, 0), 0) terminated_count
                                                        , DECODE(b.event_type, 'Assignment Started', NVL2(b.rate_range_high, DECODE(SIGN(b.rate_range_high-NVL(b.event_attribute1,0)), -1, 0, 1), 1), NULL) rate_compl_count
                                                        , DECODE(b.event_type, 'Evaluation Performed', 1, 0) negative_evaluations_count
                                                   FROM (
                                                          SELECT   a.*
                                                                 , ROW_NUMBER() OVER
                                                                   (
                                                                     PARTITION BY   a.period_number, a.data_source_code, a.job_opportunity_id
                                                                                  , NVL(a.event_attribute6, 0), a.std_buyerorg_id
                                                                                  , a.std_supplierorg_id, a.candidate_id, a.event_type
                                                                         ORDER BY a.event_date DESC
                                                                   ) AS rnk
                                                            FROM (
                                                                    SELECT   p_period AS period_number
                                                                           , d.*
                                                                           , NVL(s.rate_range_low, j.rate_range_low) AS rate_range_low
                                                                           , NVL(s.rate_range_high, j.rate_range_high) AS rate_range_high
                                                                           , s.job_opportunity_create_date
                                                                           , TO_NUMBER(TO_CHAR(s.job_opportunity_create_date, 'YYYYMM')) AS jo_month_number
                                                                           , j.std_buyerorg_id
                                                                           , j.std_job_category_id
                                                                           , s.std_supplierorg_id
                                                                      FROM dm_job_supplier_event_details d, dm_job_supplier_details s, dm_jobs j
                                                                     WHERE d.event_type IN ('Candidate Submitted', 'Forwarded to Hiring Manager', 'Interview Scheduled/Pending')
                                                                       AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                                                                       AND d.data_source_code = p_source_code
                                                                       AND EXISTS (
                                                                                    SELECT NULL
                                                                                      FROM jobs_touched jt
                                                                                     WHERE jt.job_id = d.job_id
                                                                                       AND jt.data_source_code = d.data_source_code
                                                                                  )
                                                                       AND s.data_source_code = d.data_source_code
                                                                       AND s.job_opportunity_id = d.job_opportunity_id
                                                                       AND s.buyerorg_id = d.buyerorg_id
                                                                       AND s.supplierorg_id = d.supplierorg_id
                                                                       AND s.std_supplierorg_id > 0
                                                                       AND j.data_source_code = d.data_source_code
                                                                       AND j.buyerorg_id = d.buyerorg_id
                                                                       AND j.job_id = d.job_id
                                                                       AND j.std_buyerorg_id > 0
                                                                       AND j.std_job_category_id > 0
                                                                     UNION ALL
                                                                    SELECT   p_period AS month_number
                                                                           , d.*
                                                                           , NVL(s.rate_range_low, j.rate_range_low) AS rate_range_low
                                                                           , NVL(s.rate_range_high, j.rate_range_high) AS rate_range_high
                                                                           , s.job_opportunity_create_date
                                                                           , TO_NUMBER(TO_CHAR(s.job_opportunity_create_date, 'YYYYMM')) AS jo_month_number
                                                                           , j.std_buyerorg_id
                                                                           , j.std_job_category_id
                                                                           , s.std_supplierorg_id
                                                                      FROM dm_job_supplier_event_details d, dm_job_supplier_details s, dm_jobs j
                                                                     WHERE d.event_type IN ('Assignment Started', 'Offer Made', 'Offer Accepted')
                                                                       AND d.event_attribute5 = 'WO'
                                                                       AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                                                                       AND d.data_source_code = p_source_code
                                                                       AND EXISTS (
                                                                                    SELECT NULL
                                                                                      FROM jobs_touched jt
                                                                                     WHERE jt.job_id = d.job_id
                                                                                       AND jt.assignment_id = d.event_attribute6
                                                                                       AND jt.data_source_code = d.data_source_code
                                                                                  )
                                                                       AND s.data_source_code = d.data_source_code
                                                                       AND s.job_opportunity_id = d.job_opportunity_id
                                                                       AND s.buyerorg_id = d.buyerorg_id
                                                                       AND s.supplierorg_id = d.supplierorg_id
                                                                       AND s.std_supplierorg_id > 0
                                                                       AND j.data_source_code = d.data_source_code
                                                                       AND j.buyerorg_id = d.buyerorg_id
                                                                       AND j.job_id = d.job_id
                                                                       AND j.std_buyerorg_id > 0
                                                                       AND j.std_job_category_id > 0
                                                                     UNION ALL
                                                                    SELECT   p_period AS month_number
                                                                           , d.*
                                                                           , NVL(s.rate_range_low, j.rate_range_low) AS rate_range_low
                                                                           , NVL(s.rate_range_high, j.rate_range_high) AS rate_range_high
                                                                           , s.job_opportunity_create_date
                                                                           , TO_NUMBER(TO_CHAR(s.job_opportunity_create_date, 'YYYYMM')) AS jo_month_number
                                                                           , j.std_buyerorg_id
                                                                           , j.std_job_category_id
                                                                           , s.std_supplierorg_id
                                                                      FROM dm_job_supplier_event_details d, dm_job_supplier_details s, dm_jobs j
                                                                     WHERE (
                                                                                 d.event_type IN ('Candidate Withdrawn', 'Offer Declined', 'Assignment Ended')
                                                                              OR
                                                                                 (
                                                                                        d.event_type = 'Evaluation Performed'
                                                                                    AND SIGN(d.event_attribute2) = -1
                                                                                 )
                                                                           )
                                                                       AND d.event_attribute5 = 'WO'
                                                                       AND d.event_date >= TO_DATE(p_month1, 'YYYYMM')
                                                                       AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                                                                       AND d.data_source_code = p_source_code
                                                                       AND s.data_source_code = d.data_source_code
                                                                       AND s.job_opportunity_id = d.job_opportunity_id
                                                                       AND s.buyerorg_id = d.buyerorg_id
                                                                       AND s.supplierorg_id = d.supplierorg_id
                                                                       AND s.std_supplierorg_id > 0
                                                                       AND j.data_source_code = d.data_source_code
                                                                       AND j.buyerorg_id = d.buyerorg_id
                                                                       AND j.job_id = d.job_id
                                                                       AND j.std_buyerorg_id > 0
                                                                       AND j.std_job_category_id > 0
                                                                 ) a
                                                        ) b
                                                  WHERE b.rnk < 2
                                               ) c
                                         GROUP BY c.period_number, c.data_source_code, c.std_buyerorg_id, c.std_supplierorg_id, c.job_opportunity_id, c.candidate_id
                                      ) x
                             ) y
                       GROUP BY y.period_number, y.data_source_code, y.std_buyerorg_id, y.std_supplierorg_id, y.std_job_category_id
                    ) z, dm_job_category jc, spend_sum ss
              WHERE jc.std_job_category_id       = z.std_job_category_id
                AND ss.std_buyerorg_id       (+) = z.std_buyerorg_id
                AND ss.std_job_category_id   (+) = z.std_job_category_id
                AND ss.std_supplierorg_id    (+) = z.std_supplierorg_id
                AND ss.data_source_code      (+) = z.data_source_code;

         v_prev_buyer_id := -1;
         LOOP
              FETCH c1 BULK COLLECT INTO vInpRecs LIMIT 1000;
              FOR i IN 1 .. vInpRecs.COUNT
              LOOP
                   /*
                   ** Input data from Cursor (c1) is expected to be sorted by buyerorg_id
                   ** When ever buyer new/changing
                   ** Get Buyer specific weight/scoring metadata
                   ** The queries fetch generic metadata incase
                   ** buyer specific overrides are not avaliable
                   */
                   IF (v_prev_buyer_id != vInpRecs(i).std_buyerorg_id )
                      THEN
                           v_prev_buyer_id := vInpRecs(i).std_buyerorg_id;
                           SELECT x.value_name, x.value_weight
                             BULK COLLECT INTO v_advese_names, v_advese_weights
                             FROM (
                                    SELECT   w.value_name
                                           , w.value_weight
                                           , ROW_NUMBER() OVER (PARTITION BY w.value_name ORDER BY w.std_buyerorg_id DESC) AS rnk
                                      FROM dm_supplier_score_weights w
                                     WHERE w.data_source_code = p_source_code
                                       AND w.weight_type = 'AdverseEventScore'
                                       AND w.std_buyerorg_id IN (0, v_prev_buyer_id)
                                  ) x
                            WHERE x.rnk < 2;

                           SELECT x.value_name, x.value_weight
                             BULK COLLECT INTO v_score_names, v_score_weights
                             FROM (
                                    SELECT   w.value_name
                                           , w.value_weight
                                           , ROW_NUMBER() OVER (PARTITION BY w.value_name ORDER BY w.std_buyerorg_id DESC) AS rnk
                                      FROM dm_supplier_score_weights w
                                     WHERE w.data_source_code = p_source_code
                                       AND w.weight_type = 'SupplierScore'
                                       AND w.std_buyerorg_id IN (0, v_prev_buyer_id)
                                  ) x
                            WHERE x.rnk < 2;
                   END IF;

                   v_adverse_count := vInpRecs(i).negative_evaluations_count;
                   --v_adverse_count := 0;
                   --FOR j IN 1 .. v_advese_names.COUNT
                   --LOOP
                   --     CASE v_advese_names(j)
                   --          WHEN 'NEGATIVE_EVALUATIONS_COUNT' THEN v_adverse_count := v_adverse_count + vInpRecs(i).negative_evaluations_count*v_advese_weights(j);
                   --          WHEN 'CANDIDATES_ENDED_NEGATIVE'  THEN v_adverse_count := v_adverse_count + vInpRecs(i).candidates_ended_negative*v_advese_weights(j);

                   --          WHEN 'CANDIDATES_WITHDRAWN'       THEN v_adverse_count := v_adverse_count + vInpRecs(i).candidates_withdrawn*v_advese_weights(j);
                   --          ELSE NULL;
                   --     END CASE;
                   --END LOOP;
                   vInpRecs(i).adverse_event_count := v_adverse_count;

                   IF (vInpRecs(i).opportunities_received IS NULL OR vInpRecs(i).opportunities_received = 0)
                      THEN
                            vInpRecs(i).submitted_candidates_ratio := 0;
                      ELSE
                            vInpRecs(i).submitted_candidates_ratio := vInpRecs(i).candidates_submitted/vInpRecs(i).opportunities_received;
                   END IF;

                   IF (vInpRecs(i).candidates_submitted = 0)
                      THEN
                            vInpRecs(i).qualified_candidates_ratio   := 0;
                            vInpRecs(i).interviewed_candidates_ratio := 0;
                            vInpRecs(i).fill_ratio                   := 0;
                      ELSE
                            vInpRecs(i).qualified_candidates_ratio   := vInpRecs(i).candidates_forwarded_2hm/vInpRecs(i).candidates_submitted;
                            vInpRecs(i).interviewed_candidates_ratio := vInpRecs(i).candidates_interviewed/vInpRecs(i).candidates_submitted;
                            vInpRecs(i).fill_ratio                   := vInpRecs(i).candidates_started/vInpRecs(i).candidates_submitted;
                   END IF;

                   v_supplier_score := 0;
                   FOR j IN 1 .. v_score_names.COUNT
                   LOOP
                        CASE v_score_names(j)
                             WHEN 'ADVERSE_EVENT_SCORE'          THEN v_supplier_score := v_supplier_score + v_adverse_count*v_score_weights(j);
                             WHEN 'FILL_RATIO'                   THEN v_supplier_score := v_supplier_score + vInpRecs(i).fill_ratio*v_score_weights(j);
                             WHEN 'INTERVIEWED_CANDIDATES_RATIO' THEN v_supplier_score := v_supplier_score + vInpRecs(i).interviewed_candidates_ratio*v_score_weights(j);
                             WHEN 'QUALIFIED_CANDIDATES_RATIO'   THEN v_supplier_score := v_supplier_score + vInpRecs(i).qualified_candidates_ratio*v_score_weights(j);
                             WHEN 'SUBMITTED_CANDIDATES_RATIO'   THEN v_supplier_score := v_supplier_score + vInpRecs(i).submitted_candidates_ratio*v_score_weights(j);
                             ELSE NULL;
                        END CASE;
                   END LOOP;
                   vInpRecs(i).supplier_score := v_supplier_score;
                   PIPE ROW(vInpRecs(i));
              END LOOP;
              EXIT WHEN c1%NOTFOUND;
         END LOOP;
         CLOSE c1;

    END gen_supplier_std_ratios;

    FUNCTION gen_supplier_std_ratios_forall
    (
        p_period       IN VARCHAR2 --       (as YYYYNN)
      , p_month1       IN VARCHAR2 -- Month (as YYYYMM)
      , p_month2       IN VARCHAR2 -- Month (as YYYYMM)
    )
    RETURN supStdSmryTab PIPELINED
    IS
         c1 supStdSmryCur;
         vInpRecs supStdSmryTab;
         v_prev_buyer_id NUMBER;
         TYPE nameTab      IS TABLE OF dm_supplier_score_weights.value_name%TYPE;
         TYPE weightTab    IS TABLE OF dm_supplier_score_weights.value_weight%TYPE;
         v_advese_names    nameTab;
         v_score_names     nameTab;
         v_advese_weights  weightTab;
         v_score_weights   weightTab;
         v_adverse_count    NUMBER;
         v_supplier_score  NUMBER;
    BEGIN
             OPEN c1 FOR
             WITH jobs_touched AS
             (
               SELECT d.data_source_code, j.std_buyerorg_id, d.buyerorg_id, d.job_id, d.event_attribute6 as assignment_id
                 FROM dm_job_supplier_event_details d, dm_jobs j
                WHERE d.event_type = 'Assignment Created'
                  AND d.event_attribute5 = 'WO'
                  AND j.job_id = d.job_id
                  AND d.event_date >= TO_DATE(p_month1, 'YYYYMM')
                  AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                  AND j.has_sole_supplier_flag = 'N'
                  AND j.std_buyerorg_id > 0
                  AND j.std_job_category_id > 0
             ),
                  spend_sum AS
             (
               SELECT   x.std_supplierorg_id
                      , x.std_job_category_id
                      , SUM(x.buyer_adjusted_amount) AS spend_amt
                 FROM (
                        SELECT   bm.std_buyerorg_id
                               , sm.std_supplierorg_id
                               , dj.std_job_category_id
                               , sp.buyer_adjusted_amount
                               , ROW_NUMBER() OVER (PARTITION BY bm.buyerorg_id, sm.supplierorg_id, mp.job_title ORDER BY mp.std_job_title_id) AS rnk
                          FROM dm_spend_summary sp, dm_fo_title_map mp, dm_job_titles dj, fo_suppliers_map sm, fo_buyers_map bm
                         WHERE sp.month_number BETWEEN p_month1 AND NVL(p_month2, p_month1)
                           AND mp.data_source_code = 'REGULAR'
                           AND mp.buyerorg_id      = sp.buyer_bus_org_fk
                           AND mp.job_title        = UPPER(LTRIM(RTRIM(sp.job_title)))
                           AND bm.buyerorg_id      = mp.buyerorg_id
                           AND bm.data_source_code = mp.data_source_code
                           AND dj.std_job_title_id = mp.std_job_title_id
                           AND dj.is_deleted       = 'N'
                           AND dj.std_job_category_id > 0
                           AND sm.data_source_code = 'REGULAR'
                           AND sm.supplierorg_id   = sp.supplier_bus_org_fk
                           AND sm.std_supplierorg_id > 0
                      ) x
                WHERE x.rnk = 1
                GROUP BY  x.std_supplierorg_id, x.std_job_category_id
             )
             SELECT   'ALL' AS data_source_code
                    , z.period_number
                    , 0 AS std_buyerorg_id
                    , z.std_supplierorg_id
                    , z.std_job_category_id
                    , z.candidates_submitted
                    , GREATEST(z.avg_submit_days, 0) avg_submit_days
                    , LEAST(z.avg_submit_bus_days, GREATEST(z.avg_submit_days, 0)) avg_submit_bus_days
                    , z.candidates_forwarded_2hm
                    , z.avg_fwd_2hm_days
                    , z.avg_fwd_2hm_bus_days
                    , z.avg_fwd_2hm_days_4filled
                    , z.avg_fwd_2hm_bus_days_4filled
                    , z.candidates_interviewed
                    , z.avg_time_to_fill_days
                    , z.candidates_withdrawn
                    , z.candidates_offered
                    , z.candidates_declined
                    , z.candidates_accepted
                    , z.candidates_started
                    , z.ea_candidates_started
                    , z.rate_compliance_count
                    , z.candidates_ended
                    , z.negative_evaluations_count
                    , (z.candidates_ended-z.negative_evaluations_count) AS positive_evaluations_count
                    , z.targeted_jobs_count
                    , jc.std_job_category_desc
                    , CAST (0 AS NUMBER(10,4)) AS adverse_event_count
                    , CAST (0 AS NUMBER(10,4)) AS submitted_candidates_ratio
                    , CAST (0 AS NUMBER(10,4)) AS qualified_candidates_ratio
                    , CAST (0 AS NUMBER(10,4)) AS interviewed_candidates_ratio
                    , CAST (0 AS NUMBER(10,4)) AS fill_ratio
                    , CAST (0 AS NUMBER(12,4)) AS supplier_score
                    , CAST (0 AS NUMBER      ) AS supplier_rank
                    , NVL(ss.spend_amt, 0)     AS spend_amt
                    , CAST (NULL AS NUMBER   ) AS opportunities_received
               FROM (
                      SELECT   y.period_number
                             , y.std_supplierorg_id
                             , y.std_job_category_id
                             , SUM(y.submit_count) AS candidates_submitted
                             , AVG(y.time_to_submit) AS avg_submit_days
                             , AVG(y.time2submit_bdays) AS avg_submit_bus_days
                             , SUM(y.fwd2hm_count) AS candidates_forwarded_2hm
                             , AVG(y.time_to_fwd2hm) AS avg_fwd_2hm_days
                             , AVG(y.time2fwd2hm_bdays) AS avg_fwd_2hm_bus_days
                             , AVG(y.time_to_fwd2hm_4filled) AS avg_fwd_2hm_days_4filled
                             , AVG(y.time2fwd2hm_bdays_4filled) AS avg_fwd_2hm_bus_days_4filled
                             , SUM(y.intw_count) AS candidates_interviewed
                             , AVG(y.time_to_fill) AS avg_time_to_fill_days
                             , SUM(y.withdrawn_count) AS candidates_withdrawn
                             , SUM(y.offer_count) AS candidates_offered
                             , SUM(y.decl_count) AS candidates_declined
                             , SUM(y.acpt_count) AS candidates_accepted
                             , SUM(y.start_count) AS candidates_started
                             , SUM(y.start_ea_count) AS ea_candidates_started
                             , SUM(y.target_job_count) AS targeted_jobs_count
                             , SUM(y.rate_compl_count) AS rate_compliance_count
                             , SUM(y.ended_count) AS candidates_ended
                             , SUM(y.negative_evaluations_count) AS negative_evaluations_count
                        FROM (
                               SELECT   x.period_number
                                      , x.data_source_code
                                      , x.std_buyerorg_id
                                      , x.std_supplierorg_id
                                      , x.job_opportunity_id
                                      , x.std_job_category_id
                                      , DECODE(in_the_period(x.jo_month_number, p_month1, p_month2), 1, x.job_opportunity_id, NULL) current_period_opp_id
                                      , x.candidate_id
                                      , x.submit_count
                                      , ROUND((x.submit_time-x.jo_create_date), 4) time_to_submit
                                      , dm_utils.bdays(x.jo_create_date,x.submit_time) time2submit_bdays
                                      , x.fwd2hm_count
                                      , ROUND((x.fwd2hm_time -x.submit_time), 4) time_to_fwd2hm
                                      , DECODE(x.start_count, 0, NULL, ROUND((x.fwd2hm_time -x.submit_time), 4)) time_to_fwd2hm_4filled
                                      , dm_utils.bdays(x.submit_time,x.fwd2hm_time) time2fwd2hm_bdays
                                      , DECODE(x.start_count, 0, NULL, dm_utils.bdays(x.submit_time,x.fwd2hm_time)) time2fwd2hm_bdays_4filled
                                      , x.intw_count
                                      , ROUND((x.intw_time-x.submit_time), 4) time_to_intw
                                      , x.start_count
                                      , x.start_ea_count
                                      , x.target_job_count
                                      , ROUND((x.fill_time-x.jo_create_date), 4) time_to_fill
                                      , x.offer_count
                                      , x.withdrawn_count
                                      , x.decl_count
                                      , x.acpt_count
                                      , x.ended_count
                                      , x.rate_compl_count
                                      , DECODE(x.terminated_count, 0, DECODE(x.negative_evaluations_count, 0, 0, 1), 1) negative_evaluations_count
                                 FROM (
                                        SELECT   c.period_number, c.data_source_code, c.std_buyerorg_id, c.std_supplierorg_id, c.job_opportunity_id, c.candidate_id
                                               , MIN(c.jo_month_number) jo_month_number
                                               , MIN(c.std_job_category_id) std_job_category_id
                                               , MIN(c.job_opportunity_create_date) jo_create_date
                                               , SUM(c.submit_count) AS submit_count
                                               , MIN(c.submit_time)  AS submit_time
                                               , SUM(c.fwd2hm_count) AS fwd2hm_count
                                               , MIN(c.fwd2hm_time) AS fwd2hm_time
                                               , SUM(c.intw_count) AS intw_count
                                               , MIN(c.intw_time) AS intw_time
                                               , SUM(c.start_count) AS start_count
                                               , SUM(c.start_ea_count) AS start_ea_count
                                               , SUM(c.target_job_count) AS target_job_count
                                               , MIN(c.fill_time) AS fill_time
                                               , SUM(c.offer_count) AS offer_count
                                               , SUM(c.withdrawn_count) AS withdrawn_count
                                               , SUM(c.decl_count) AS decl_count
                                               , SUM(c.acpt_count) AS acpt_count
                                               , SUM(c.ended_count) AS ended_count
                                               , SUM(c.rate_compl_count) AS rate_compl_count
                                               , SUM(c.negative_evaluations_count) AS negative_evaluations_count
                                               , SUM(c.terminated_count) AS terminated_count
                                          FROM (
                                                 SELECT   b.*
                                                        , DECODE(b.event_type, 'Candidate Submitted', 1, 0) submit_count
                                                        , DECODE(b.event_type, 'Candidate Submitted', b.event_date, NULL) submit_time
                                                        , DECODE(b.event_type, 'Forwarded to Hiring Manager', 1, 0) fwd2hm_count
                                                        , DECODE(b.event_type, 'Forwarded to Hiring Manager', b.event_date, NULL) fwd2hm_time
                                                        , DECODE(b.event_type, 'Interview Scheduled/Pending', 1, 0) intw_count
                                                        , DECODE(b.event_type, 'Interview Scheduled/Pending', b.event_date, NULL) intw_time
                                                        , DECODE(b.event_type, 'Assignment Started', 1, 0) start_count
                                                        , DECODE(b.event_type, 'Assignment Started', DECODE(b.event_attribute5,'EA', 1, 0), 0) start_ea_count
                                                        , DECODE(b.event_type, 'Assignment Started', DECODE(b.event_attribute2,'Manual Contract', 1, 0), 0) target_job_count
                                                        , DECODE(b.event_type, 'Assignment Started', b.event_date, NULL) fill_time
                                                        , DECODE(b.event_type, 'Offer Made', 1, 0) offer_count
                                                        , DECODE(b.event_type, 'Candidate Withdrawn', 1, 0) withdrawn_count
                                                        , DECODE(b.event_type, 'Offer Declined', 1, 0) decl_count
                                                        , DECODE(b.event_type, 'Offer Accepted', 1, 0) acpt_count
                                                        , DECODE(b.event_type, 'Assignment Ended', 1, 0) ended_count
                                                        , DECODE(b.event_type, 'Assignment Ended', DECODE(b.event_attribute2, 'TERMINATED', 1, 0), 0) terminated_count
                                                        , DECODE(b.event_type, 'Assignment Started', NVL2(b.rate_range_high, DECODE(SIGN(b.rate_range_high-NVL(b.event_attribute1,0)), -1, 0, 1), 1), NULL) rate_compl_count
                                                        , DECODE(b.event_type, 'Evaluation Performed', 1, 0) negative_evaluations_count
                                                   FROM (
                                                          SELECT   a.*
                                                                 , ROW_NUMBER() OVER
                                                                   (
                                                                     PARTITION BY   a.period_number, a.data_source_code, a.job_opportunity_id
                                                                                  , NVL(a.event_attribute6, 0), a.std_buyerorg_id
                                                                                  , a.std_supplierorg_id, a.candidate_id, a.event_type
                                                                         ORDER BY a.event_date DESC
                                                                   ) AS rnk
                                                            FROM (
                                                                    SELECT   p_period AS period_number
                                                                           , d.*
                                                                           , NVL(s.rate_range_low, j.rate_range_low) AS rate_range_low
                                                                           , NVL(s.rate_range_high, j.rate_range_high) AS rate_range_high
                                                                           , s.job_opportunity_create_date
                                                                           , TO_NUMBER(TO_CHAR(s.job_opportunity_create_date, 'YYYYMM')) AS jo_month_number
                                                                           , j.std_buyerorg_id
                                                                           , j.std_job_category_id
                                                                           , s.std_supplierorg_id
                                                                      FROM dm_job_supplier_event_details d, dm_job_supplier_details s, dm_jobs j
                                                                     WHERE d.event_type IN ('Candidate Submitted', 'Forwarded to Hiring Manager', 'Interview Scheduled/Pending')
                                                                       AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                                                                       AND EXISTS (
                                                                                    SELECT NULL
                                                                                      FROM jobs_touched jt
                                                                                     WHERE jt.job_id = d.job_id
                                                                                       AND jt.data_source_code = d.data_source_code
                                                                                  )
                                                                       AND s.data_source_code = d.data_source_code
                                                                       AND s.job_opportunity_id = d.job_opportunity_id
                                                                       AND s.buyerorg_id = d.buyerorg_id
                                                                       AND s.supplierorg_id = d.supplierorg_id
                                                                       AND s.std_supplierorg_id > 0
                                                                       AND j.data_source_code = d.data_source_code
                                                                       AND j.buyerorg_id = d.buyerorg_id
                                                                       AND j.job_id = d.job_id
                                                                       AND j.std_buyerorg_id > 0
                                                                       AND j.std_job_category_id > 0
                                                                     UNION ALL
                                                                    SELECT   p_period AS month_number
                                                                           , d.*
                                                                           , NVL(s.rate_range_low, j.rate_range_low) AS rate_range_low
                                                                           , NVL(s.rate_range_high, j.rate_range_high) AS rate_range_high
                                                                           , s.job_opportunity_create_date
                                                                           , TO_NUMBER(TO_CHAR(s.job_opportunity_create_date, 'YYYYMM')) AS jo_month_number
                                                                           , j.std_buyerorg_id
                                                                           , j.std_job_category_id
                                                                           , s.std_supplierorg_id
                                                                      FROM dm_job_supplier_event_details d, dm_job_supplier_details s, dm_jobs j
                                                                     WHERE d.event_type IN ('Assignment Started', 'Offer Made', 'Offer Accepted')
                                                                       AND d.event_attribute5 = 'WO'
                                                                       AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                                                                       AND EXISTS (
                                                                                    SELECT NULL
                                                                                      FROM jobs_touched jt
                                                                                     WHERE jt.job_id = d.job_id
                                                                                       AND jt.assignment_id = d.event_attribute6
                                                                                       AND jt.data_source_code = d.data_source_code
                                                                                  )
                                                                       AND s.data_source_code = d.data_source_code
                                                                       AND s.job_opportunity_id = d.job_opportunity_id
                                                                       AND s.buyerorg_id = d.buyerorg_id
                                                                       AND s.supplierorg_id = d.supplierorg_id
                                                                       AND s.std_supplierorg_id > 0
                                                                       AND j.data_source_code = d.data_source_code
                                                                       AND j.buyerorg_id = d.buyerorg_id
                                                                       AND j.job_id = d.job_id
                                                                       AND j.std_buyerorg_id > 0
                                                                       AND j.std_job_category_id > 0
                                                                     UNION ALL
                                                                    SELECT   p_period AS month_number
                                                                           , d.*
                                                                           , NVL(s.rate_range_low, j.rate_range_low) AS rate_range_low
                                                                           , NVL(s.rate_range_high, j.rate_range_high) AS rate_range_high
                                                                           , s.job_opportunity_create_date
                                                                           , TO_NUMBER(TO_CHAR(s.job_opportunity_create_date, 'YYYYMM')) AS jo_month_number
                                                                           , j.std_buyerorg_id
                                                                           , j.std_job_category_id
                                                                           , s.std_supplierorg_id
                                                                      FROM dm_job_supplier_event_details d, dm_job_supplier_details s, dm_jobs j
                                                                     WHERE (
                                                                                 d.event_type IN ('Candidate Withdrawn', 'Offer Declined', 'Assignment Ended')
                                                                              OR
                                                                                 (
                                                                                        d.event_type = 'Evaluation Performed'
                                                                                    AND SIGN(d.event_attribute2) = -1
                                                                                 )
                                                                           )
                                                                       AND d.event_attribute5 = 'WO'
                                                                       AND d.event_date >= TO_DATE(p_month1, 'YYYYMM')
                                                                       AND d.event_date <  ADD_MONTHS(TO_DATE(NVL(p_month2, p_month1), 'YYYYMM'), 1)
                                                                       AND s.data_source_code = d.data_source_code
                                                                       AND s.job_opportunity_id = d.job_opportunity_id
                                                                       AND s.buyerorg_id = d.buyerorg_id
                                                                       AND s.supplierorg_id = d.supplierorg_id
                                                                       AND s.std_supplierorg_id > 0
                                                                       AND j.data_source_code = d.data_source_code
                                                                       AND j.buyerorg_id = d.buyerorg_id
                                                                       AND j.job_id = d.job_id
                                                                       AND j.std_buyerorg_id > 0
                                                                       AND j.std_job_category_id > 0
                                                                 ) a
                                                        ) b
                                                  WHERE b.rnk < 2
                                               ) c
                                         GROUP BY c.period_number, c.data_source_code, c.std_buyerorg_id, c.std_supplierorg_id, c.job_opportunity_id, c.candidate_id
                                      ) x
                             ) y
                       GROUP BY y.period_number, y.std_supplierorg_id, y.std_job_category_id
                    ) z, dm_job_category jc, spend_sum ss
              WHERE jc.std_job_category_id       = z.std_job_category_id
                AND ss.std_job_category_id   (+) = z.std_job_category_id
                AND ss.std_supplierorg_id    (+) = z.std_supplierorg_id;

         v_prev_buyer_id := -1;
         LOOP
              FETCH c1 BULK COLLECT INTO vInpRecs LIMIT 1000;
              FOR i IN 1 .. vInpRecs.COUNT
              LOOP
                   --SELECT w.value_name , w.value_weight
                   --  BULK COLLECT INTO v_advese_names, v_advese_weights
                   --  FROM dm_supplier_score_weights w
                   -- WHERE w.data_source_code = 'ALL'
                   --   AND w.weight_type = 'AdverseEventScore'
                   --   AND w.std_buyerorg_id = 0;

                   SELECT w.value_name , w.value_weight
                     BULK COLLECT INTO v_score_names, v_score_weights
                     FROM dm_supplier_score_weights w
                    WHERE w.data_source_code = 'ALL'
                      AND w.weight_type = 'SupplierScore'
                      AND w.std_buyerorg_id = 0;

                   v_adverse_count := vInpRecs(i).negative_evaluations_count;
                   --v_adverse_count := 0;
                   --FOR j IN 1 .. v_advese_names.COUNT
                   --LOOP
                   --     CASE v_advese_names(j)
                   --          WHEN 'NEGATIVE_EVALUATIONS_COUNT' THEN v_adverse_count := v_adverse_count + vInpRecs(i).negative_evaluations_count*v_advese_weights(j);
                   --          WHEN 'CANDIDATES_ENDED_NEGATIVE'  THEN v_adverse_count := v_adverse_count + vInpRecs(i).candidates_ended_negative*v_advese_weights(j);

                   --          WHEN 'CANDIDATES_WITHDRAWN'       THEN v_adverse_count := v_adverse_count + vInpRecs(i).candidates_withdrawn*v_advese_weights(j);
                   --          ELSE NULL;
                   --     END CASE;
                   --END LOOP;
                   vInpRecs(i).adverse_event_count := v_adverse_count;

                   IF (vInpRecs(i).opportunities_received IS NULL OR vInpRecs(i).opportunities_received = 0)
                      THEN
                            vInpRecs(i).submitted_candidates_ratio := 0;
                      ELSE
                            vInpRecs(i).submitted_candidates_ratio := vInpRecs(i).candidates_submitted/vInpRecs(i).opportunities_received;
                   END IF;

                   IF (vInpRecs(i).candidates_submitted = 0)
                      THEN
                            vInpRecs(i).qualified_candidates_ratio   := 0;
                            vInpRecs(i).interviewed_candidates_ratio := 0;
                            vInpRecs(i).fill_ratio                   := 0;
                      ELSE
                            vInpRecs(i).qualified_candidates_ratio   := vInpRecs(i).candidates_forwarded_2hm/vInpRecs(i).candidates_submitted;
                            vInpRecs(i).interviewed_candidates_ratio := vInpRecs(i).candidates_interviewed/vInpRecs(i).candidates_submitted;
                            vInpRecs(i).fill_ratio                   := vInpRecs(i).candidates_started/vInpRecs(i).candidates_submitted;
                   END IF;

                   v_supplier_score := 0;
                   FOR j IN 1 .. v_score_names.COUNT
                   LOOP
                        CASE v_score_names(j)
                             WHEN 'ADVERSE_EVENT_SCORE'          THEN v_supplier_score := v_supplier_score + v_adverse_count*v_score_weights(j);
				     WHEN 'FILL_RATIO'                   THEN v_supplier_score := v_supplier_score + vInpRecs(i).fill_ratio*v_score_weights(j);
				     WHEN 'INTERVIEWED_CANDIDATES_RATIO' THEN v_supplier_score := v_supplier_score + vInpRecs(i).interviewed_candidates_ratio*v_score_weights(j);
				     WHEN 'QUALIFIED_CANDIDATES_RATIO'   THEN v_supplier_score := v_supplier_score + vInpRecs(i).qualified_candidates_ratio*v_score_weights(j);
				     WHEN 'SUBMITTED_CANDIDATES_RATIO'   THEN v_supplier_score := v_supplier_score + vInpRecs(i).submitted_candidates_ratio*v_score_weights(j);
				     ELSE NULL;
				END CASE;
			   END LOOP;
			   vInpRecs(i).supplier_score := v_supplier_score;
			   PIPE ROW(vInpRecs(i));
		      END LOOP;
		      EXIT WHEN c1%NOTFOUND;
		 END LOOP;
		 CLOSE c1;
	    END gen_supplier_std_ratios_forall;

	BEGIN
	    vNegativeReasons(1)  := 'NOT ELIGIBLE FOR REHIRE';
	    vNegativeReasons(2)  := 'PERFORMANCE (PRODUCTIVITY/QUALITY)';
	    vNegativeReasons(3)  := 'ABSENT WITHOUT NOTIFICATION';
	    vNegativeReasons(4)  := 'BACKGROUND SCREEN RESULTS (UNFAVORABLE)';
	    vNegativeReasons(5)  := 'TARDINESS';
	    vNegativeReasons(6)  := 'ABSENCES';
	    vNegativeReasons(7)  := 'ABSENTEEISM';
	    vNegativeReasons(8)  := 'UNACCEPTABLE BEHAVIOR';
	    vNegativeReasons(9)  := 'DELIVERABLES UNACCEPTABLE';
	    vNegativeReasons(10) := 'NON-COMPLIANCE';
	    vNegativeReasons(11) := 'UNSATIFACTORY WORK';
	    vNegativeReasons(12) := 'NOT REHIREABLE';
	    vNegativeReasons(13) := 'NO CALL';
	    vNegativeReasons(14) := 'NO SHOW';
	    vNegativeReasons(15) := 'NOT SHOW UP';
	    vNegativeReasons(16) := 'ATTENDANCE';
	    vNegativeReasons(17) := 'VIOLATION OF COMPANY POLICY';
	    vNegativeReasons(18) := 'DELIVERABLES UNACCEPTABLE';
	    vNegativeReasons(19) := 'REFUND REQUESTED';
	    vNegativeReasons(20) := 'NOT PASS BACKGROUND CHECK';
	    vNegativeReasons(21) := 'FAILED DRUG/BACKGROUND CHECK';
	    vNegativeReasons(22) := 'JOB ABANDONMENT';
END dm_supp_metrics;
/