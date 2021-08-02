CREATE OR REPLACE PACKAGE BODY dm_org_dim
AS
    PROCEDURE p_main
    (
        p_source_code IN VARCHAR2
        ,p_date_id     IN NUMBER  
    )
    IS
       p_msg_id            NUMBER;
       v_crnt_proc_name    user_jobs.what%TYPE := 'DM_ORG_DIM.P_MAIN';
       ln_count            NUMBER;
       lv_proc_name        user_jobs.what%TYPE := 'DM_ORG_DIM.P_MAIN';
       lv_fo_app_err_msg   VARCHAR2(2000)  := NULL;
       lv_fo_db_err_msg    VARCHAR2(2000)  := NULL;
       lv_app_err_msg      VARCHAR2(2000)  := NULL;
       lv_db_err_msg       VARCHAR2(2000)  := NULL;
       lv_ea_count         NUMBER;
       lv_wo_count         NUMBER;
       email_sender        VARCHAR2(32) := 'mart_processing@iqnavigator.com';
       email_recipients    VARCHAR2(64) := 'data_warehouse@iqnavigator.com';
       email_subject       VARCHAR2(64) := 'DM_ORAGANIZATION_DIM Update';
       remote_extract_done VARCHAR2(1) := 'N';

       v_org_prev_max_id PLS_INTEGER;
       v_org_crnt_max_id PLS_INTEGER;
    BEGIN
       dm_cube_utils.make_indexes_visible;

       --
       -- Get the sequence reuired for logging messages
       --
       SELECT dm_msg_log_seq.NEXTVAL INTO p_msg_id FROM dual;

       --
       -- Check if the previous job still running
       --
       ln_count := dm_cube_utils.get_job_status('DIM_DAILY_PROCESS;');
       IF ln_count > 1 THEN
           --
           -- previous job still running log and exit
           --
           dm_util_log.p_log_msg(p_msg_id,0,gv_process || ' - PREVIOUS JOB STILL RUNNING',lv_proc_name,'I');
           dm_util_log.p_log_msg(p_msg_id,0,NULL,NULL,'U');
       ELSE
           --
           --Log initial load status
           --
           dm_util_log.p_log_load_status(p_msg_id, gv_process,'FO','STARTED',NULL,'I');

           --
           -- Call the procedure to get the FO Organization Snapshot information
           --
           v_crnt_proc_name := 'DM_ORG_DIM.GET_NEW_ORG_CHANGES';
           dm_util_log.p_log_msg(p_msg_id,1, p_source_code || ': FO ORG DIM Extract',v_crnt_proc_name,'I');
           get_new_org_changes(p_msg_id,p_source_code);
           remote_extract_done := 'Y';
           dm_util_log.p_log_msg(p_msg_id,1, NULL,NULL,'U');

           dm_util_log.p_log_load_status(p_msg_id, gv_process,'FO','COMPLETE',0,'U');

           dm_util_log.p_log_load_status(p_msg_id, gv_process,'DW','STARTED',NULL,'I');
           pull_and_transform(p_source_code, p_msg_id);
           dm_util_log.p_log_load_status(p_msg_id, gv_process,'DW','COMPLETE',0,'U');
           --
           -- added by Manoj.  update the load status
           -- 
           DM_UTIL_LOG.p_log_cube_load_status('DM_ORGANIZATION_DIM',
                                               p_source_code,
                                               'SPEND_CUBE-DIM',
                                               'COMPLETED',
                                               p_date_id);           
       END IF;
    EXCEPTION
       WHEN OTHERS THEN
       BEGIN
             lv_fo_db_err_msg := SQLERRM;
             IF (remote_extract_done = 'Y')
                THEN
                     lv_fo_app_err_msg := 'Unable to execute the procedure to Pull and Transform Organization DIM data after successful FO extraction!';
                     dm_util_log.p_log_load_status(p_msg_id, gv_process,'DW','FAILED',0,'U');
                ELSE
                     dm_util_log.p_log_load_status(p_msg_id, gv_process,'FO','FAILED',0,'U');
             END IF;
             
           --
           -- added by Manoj.  update the load status
           -- 
           DM_UTIL_LOG.p_log_cube_load_status('DM_ORGANIZATION_DIM',
                                               p_source_code,
                                               'SPEND_CUBE-DIM',
                                               'FAILED',
                                               p_date_id);             
             dm_utils.send_email(email_sender, email_recipients, email_subject, p_source_code || ' Process failed due to the following ' || c_crlf || lv_fo_app_err_msg || c_crlf || lv_fo_db_err_msg || c_crlf);             
       END;
    END p_main;

    PROCEDURE get_new_org_changes
    (
        p_msg_id      IN  NUMBER
      , p_source_code IN  VARCHAR2
    )
    IS
      lv_proc_name         VARCHAR2(100)  := 'DM_ORG_DIM.GET_NEW_ORG_CHANGES';
      lv_app_err_msg       VARCHAR2(2000) := NULL;
      lv_db_err_msg        VARCHAR2(2000) := NULL;
      lv_err_msg           VARCHAR2(2000) := NULL;
    BEGIN
       BEGIN
         CASE (p_source_code)
              WHEN 'REGULAR'  THEN fo_dm_org_dim.get_org_delta@FO_R(p_msg_id, p_source_code);
              --WHEN 'WACHOVIA' THEN fo_dm_org_dim.get_org_delta(p_msg_id, p_source_code);
         END CASE;
  
       EXCEPTION
         WHEN OTHERS THEN
           lv_app_err_msg := 'Unable to execute the remote procedure to get the FO data for DM_ORGANIZATION_DIM !';
           lv_db_err_msg  := SQLERRM;
       END;

       --
       -- check for any errors in remote procedure
       --
       BEGIN
         CASE (p_source_code)
              WHEN 'REGULAR'  THEN 
                                   SELECT err_msg
                                     INTO lv_err_msg
                                     FROM fo_dm_org_dim_errmsg@FO_R
                                    WHERE ROWNUM < 2;
              --WHEN 'WACHOVIA' THEN 
              --                     SELECT err_msg
              --                       INTO lv_err_msg
              --                       FROM fo_dm_org_dim_errmsg
              --                      WHERE ROWNUM < 2;
         END CASE;

         IF lv_err_msg IS NOT NULL THEN
            lv_app_err_msg := 'Errors occured in the remote procedure to get DM_ORGANIZATION_DIM data! ';
            lv_db_err_msg  := lv_err_msg || ' ' || SQLERRM;
         END IF;
       EXCEPTION
           WHEN NO_DATA_FOUND THEN lv_err_msg := NULL;
       END;

       IF (lv_db_err_msg IS NOT NULL)
          THEN
               RAISE_APPLICATION_ERROR(-20501, lv_app_err_msg || lv_db_err_msg);
       END IF;
    END get_new_org_changes;

    PROCEDURE just_transform
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
    )
    IS
          v_crnt_proc_name user_jobs.what%TYPE := 'DM_ORG_DIM.JUST_TRANSFORM';
          v_prev_org_id    dm_organization_dim.org_id%TYPE := -1;
          v_prev_ver_id    dm_organization_dim.version_id%TYPE := -1;
          v_rec_count      NUMBER;
          v_org_count      NUMBER;
          v_upd_count      NUMBER;
          v_start_date     DATE;
          v_new_valid_to_date     DATE;
          v_new_org_dim_id    dm_organization_dim.org_dim_id%TYPE;
          v_prev_rec_ver_id dm_organization_dim.version_id%TYPE := -1;
          lv_db_err_msg        VARCHAR2(2000) := NULL;

          CURSOR c1 IS
            WITH parent_org_list AS
                 (
                   SELECT DISTINCT t.top_parent_org_id org_id
                     FROM fo_dm_org_dim_tmp t
                 )
          SELECT t3.*
            FROM (
                   SELECT   t2.*
                          , ROW_NUMBER() OVER (PARTITION BY t2.org_id ORDER BY t2.valid_to_date NULLS LAST) AS version_id
                          , dm_cube_utils.get_geo_dim_id(t2.country_name, t2.state_name, t2.city_name, t2.postal_code) AS primary_geo_dim_id
                     FROM (
                            SELECT   t.*
                                   , ROW_NUMBER() OVER (PARTITION BY t.org_id, t.creation_date, NVL(t.valid_to_date, TRUNC(SYSDATE))
                                                        ORDER BY NVL(t.valid_to_date, TRUNC(SYSDATE)) DESC) AS rnk
                              FROM fo_dm_org_dim_tmp t
                             WHERE EXISTS (
                                            SELECT NULL
                                              FROM parent_org_list t1
                                             WHERE t1.org_id = t.org_id
                                          )
                          ) t2
                    WHERE t2.rnk = 1
                 ) t3
           ORDER BY t3.data_source_code, t3.org_id, t3.version_id;

          CURSOR c2 IS
            WITH parent_org_list AS
                 (
                   SELECT DISTINCT t.top_parent_org_id org_id
                     FROM fo_dm_org_dim_tmp t
                 )
          SELECT t3.*
            FROM (
                   SELECT   t2.*
                          , ROW_NUMBER() OVER (partition by t2.org_id ORDER BY t2.valid_to_date NULLS LAST) AS version_id
                          , dm_cube_utils.get_geo_dim_id(t2.country_name, t2.state_name, t2.city_name, t2.postal_code) AS primary_geo_dim_id
                          , t1.org_dim_id  AS top_parent_org_dim_id
                     FROM (
                            SELECT   t.*
                                   , ROW_NUMBER() OVER (PARTITION BY t.org_id, t.creation_date, NVL(t.valid_to_date, TRUNC(SYSDATE))
                                                        ORDER BY NVL(t.valid_to_date, TRUNC(SYSDATE)) DESC) AS rnk
                              FROM fo_dm_org_dim_tmp t
                             WHERE t.org_id <> t.top_parent_org_id
                               AND NOT EXISTS (
                                                SELECT NULL
                                                  FROM parent_org_list t0
                                                 WHERE t0.org_id = t.org_id
                                              )
                          ) t2, dm_organization_dim t1
                    WHERE t2.rnk = 1
                      AND t1.org_id = t2.top_parent_org_id
                      AND t1.is_effective = 'Y'
                      AND t1.data_source_code = p_source_code
                 ) t3
           ORDER BY t3.data_source_code, t3.org_id, t3.version_id;

          v_first_time          VARCHAR2(1) := 'Y';
    BEGIN
          dm_util_log.p_log_msg(p_msg_id, 5, p_source_code || ': Transform Parent Organizations', v_crnt_proc_name, 'I');
          v_org_count := 0;
          v_upd_count := 0;
          v_prev_rec_ver_id := -1;
          FOR c1_rec IN c1
          LOOP
          BEGIN
               IF (v_first_time = 'Y')
                  THEN
                        v_first_time := 'N';
                        dm_util_log.p_log_msg(p_msg_id, 6, p_source_code || ': Time first record Fetched From Parent Orgs Transformation Query', v_crnt_proc_name, 'I');
                        dm_util_log.p_log_msg(p_msg_id, 6, NULL, NULL, 'U');
               END IF;

               IF ((v_prev_org_id <> c1_rec.org_id) OR ((v_prev_org_id = c1_rec.org_id) AND (v_prev_rec_ver_id <> c1_rec.version_id)))
                  THEN
                       v_prev_rec_ver_id := c1_rec.version_id;
                       UPDATE dm_organization_dim l
                          SET l.is_effective = 'N'
                              , l.valid_to_date = c1_rec.creation_date-(1/86400)
                              , l.last_update_date = SYSDATE
                              , l.batch_id = p_msg_id
                        WHERE l.org_id = c1_rec.org_id
                          AND l.is_effective = 'Y'
                          AND l.data_source_code = p_source_code
                       RETURNING l.version_id, l.valid_to_date INTO v_prev_ver_id, v_new_valid_to_date;

                       v_rec_count := SQL%ROWCOUNT;
                       IF (v_rec_count = 0)
                          THEN
                               v_prev_ver_id := 0;
                          ELSE
                               v_upd_count := v_upd_count+1;

                               IF (c1_rec.org_type = 'Buyer')
                                  THEN
                                       UPDATE dm_buyer_dim l
                                          SET   l.is_effective = 'N'
                                              , l.valid_to_date = v_new_valid_to_date
                                              , l.last_update_date = SYSDATE
                                              , l.batch_id = p_msg_id
                                              , l.latest_org_name = c1_rec.org_name
                                        WHERE l.org_id = c1_rec.org_id
                                          AND l.is_effective = 'Y'
                                          AND l.version_id   = v_prev_ver_id -- Additional Check to make sure versions are matching with dm_organization_dim
                                          AND l.data_source_code = p_source_code;

                                       UPDATE dm_buyer_dim l
                                          SET l.latest_org_name = c1_rec.org_name
                                        WHERE l.org_id = c1_rec.org_id
                                          AND l.is_effective = 'N'
                                          AND l.version_id   < v_prev_ver_id
                                          AND l.data_source_code = p_source_code;
                                  ELSE
                                       UPDATE dm_supplier_dim l
                                          SET   l.is_effective = 'N'
                                              , l.valid_to_date = v_new_valid_to_date
                                              , l.last_update_date = SYSDATE
                                              , l.batch_id = p_msg_id
                                              , l.latest_org_name = c1_rec.org_name
                                        WHERE l.org_id = c1_rec.org_id
                                          AND l.is_effective = 'Y'
                                          AND l.version_id   = v_prev_ver_id -- Additional Check to make sure versions are matching with dm_organization_dim
                                          AND l.data_source_code = p_source_code;

                                       UPDATE dm_supplier_dim l
                                          SET l.latest_org_name = c1_rec.org_name
                                        WHERE l.org_id = c1_rec.org_id
                                          AND l.is_effective = 'N'
                                          AND l.version_id   < v_prev_ver_id
                                          AND l.data_source_code = p_source_code;
                               END IF;
                       END IF;
                       v_start_date  := c1_rec.creation_date;
                       v_prev_org_id := c1_rec.org_id;
               END IF;

               INSERT INTO dm_organization_dim
               (
                   org_dim_id
                 , org_id
                 , data_source_code
                 , version_id
                 , org_type
                 , org_name
                 , top_parent_org_id
                 , is_effective
                 , primary_geo_dim_id
                 , valid_from_date
                 , valid_to_date
                 , top_parent_org_dim_id
                 , fo_state_name
                 , fo_city_name
                 , fo_postal_code
                 , fo_country_name
                 , batch_id
                 , last_update_date
               )
               VALUES
               (
                   dm_organization_dim_seq.NEXTVAL --org_dim_id
                 , c1_rec.org_id
                 , p_source_code
                 , v_prev_ver_id + 1
                 , c1_rec.org_type
                 , c1_rec.org_name
                 , 0 --top_parent_org_id
                 , 'Y' -- is_effective
                 , c1_rec.primary_geo_dim_id
                 , v_start_date -- valid_from_date
                 , c1_rec.valid_to_date
                 , 0 -- top_parent_org_dim_id
                 , c1_rec.state_name
                 , c1_rec.city_name
                 , c1_rec.postal_code
                 , c1_rec.country_name
                 , p_msg_id -- batch_id
                 , SYSDATE  -- last_update_date
               )
               RETURNING org_dim_id INTO v_new_org_dim_id;

               v_org_count := v_org_count+1;

               IF (c1_rec.org_type = 'Buyer')
                  THEN
                       INSERT INTO dm_buyer_dim
                       (
                           org_dim_id
                         , org_id
                         , data_source_code
                         , version_id
                         , org_type
                         , org_name
                         , latest_org_name
                         , top_parent_org_id
                         , is_effective
                         , primary_geo_dim_id
                         , valid_from_date
                         , valid_to_date
                         , top_parent_org_dim_id
                         , fo_state_name
                         , fo_city_name
                         , fo_postal_code
                         , fo_country_name
                         , batch_id
                         , last_update_date
                       )
                       VALUES
                       (
                           v_new_org_dim_id --org_dim_id
                         , c1_rec.org_id
                         , p_source_code
                         , v_prev_ver_id + 1
                         , c1_rec.org_type
                         , c1_rec.org_name
                         , c1_rec.org_name
                         , 0 --top_parent_org_id
                         , 'Y'
                         , c1_rec.primary_geo_dim_id
                         , v_start_date -- valid_from_date
                         , c1_rec.valid_to_date
                         , 0 -- top_parent_org_dim_id
                         , c1_rec.state_name
                         , c1_rec.city_name
                         , c1_rec.postal_code
                         , c1_rec.country_name
                         , p_msg_id -- batch_id
                         , SYSDATE  -- last_update_date
                       );

                       /*
                       ** If top level buyer org_id being created 
                       ** for the first time 
                       */
                       IF (v_prev_ver_id = 0 AND c1_rec.version_id = 1)
                          THEN
                               /*
                               ** Add custom DM_DATE_DIM records for this top level buyer org_id
                               */
                               dm_cube_utils.dm_date_dim_process(c1_rec.org_id, p_source_code, 'N');

                               /*
                               ** Add org_id specific dim_records to represent NULL values
                               */
                               dm_cube_utils.create_null_date_dims(p_msg_id, c1_rec.org_id, p_source_code);
                               dm_cube_utils.create_null_ratecard_dims(p_msg_id, c1_rec.org_id, p_source_code);
                               dm_cube_utils.create_null_person_dims(p_msg_id, c1_rec.org_id, p_source_code);
                               dm_cube_utils.create_null_invoiced_cac_dims(p_msg_id, c1_rec.org_id, p_source_code);
                               dm_cube_utils.create_null_pa_dims(p_msg_id, c1_rec.org_id, p_source_code);
                               dm_cube_utils.create_null_job_dims(p_msg_id, c1_rec.org_id, p_source_code);
                       END IF;
                  ELSE
                       INSERT INTO dm_supplier_dim
                       (
                           org_dim_id
                         , org_id
                         , data_source_code
                         , version_id
                         , org_type
                         , org_name
                         , latest_org_name
                         , top_parent_org_id
                         , is_effective
                         , primary_geo_dim_id
                         , valid_from_date
                         , valid_to_date
                         , top_parent_org_dim_id
                         , fo_state_name
                         , fo_city_name
                         , fo_postal_code
                         , fo_country_name
                         , batch_id
                         , last_update_date
                       )
                       VALUES
                       (
                           v_new_org_dim_id --org_dim_id
                         , c1_rec.org_id
                         , p_source_code
                         , v_prev_ver_id + 1
                         , c1_rec.org_type
                         , c1_rec.org_name
                         , c1_rec.org_name
                         , 0 --top_parent_org_id
                         , 'Y' -- is_effective
                         , c1_rec.primary_geo_dim_id
                         , v_start_date -- valid_from_date
                         , c1_rec.valid_to_date
                         , 0 -- top_parent_org_dim_id
                         , c1_rec.state_name
                         , c1_rec.city_name
                         , c1_rec.postal_code
                         , c1_rec.country_name
                         , p_msg_id -- batch_id
                         , SYSDATE  -- last_update_date
                       );
               END IF;

               COMMIT;

               IF (c1_rec.valid_to_date IS NOT NULL)
                  THEN
                       v_start_date := c1_rec.valid_to_date+(1/86400);
                  ELSE
                       v_start_date := NULL;
               END IF;
          EXCEPTION
             WHEN OTHERS THEN
             lv_db_err_msg := SQLERRM || ' for Org_id = ' || c1_rec.org_id || ', valid_to_date ' || TO_CHAR(c1_rec.valid_to_date, 'DD-MON-YYYY HH24:MI:SS');
             RAISE_APPLICATION_ERROR(-20502, lv_db_err_msg);
          END;
          END LOOP;
          COMMIT;
          dm_util_log.p_log_msg(p_msg_id, 5, NULL, NULL, 'U');
          dm_util_log.p_log_msg(p_msg_id, 7, p_source_code || ': ' || v_upd_count || ' Parent Organization versions Updated(Invalidated)', v_crnt_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, 7, NULL, NULL, 'U');
          dm_util_log.p_log_msg(p_msg_id, 8, p_source_code || ': ' || v_org_count || ' Parent Organization versions added', v_crnt_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, 8, NULL, NULL, 'U');

          dm_util_log.p_log_msg(p_msg_id, 9, p_source_code || ': Transform Organizations', v_crnt_proc_name, 'I');

          v_prev_org_id := -1;
          v_org_count := 0;
          v_upd_count := 0;
          v_first_time := 'Y';
          v_prev_rec_ver_id := -1;
          FOR c2_rec IN c2
          LOOP
          BEGIN
               IF (v_first_time = 'Y')
                  THEN
                        v_first_time := 'N';
                        dm_util_log.p_log_msg(p_msg_id, 10, p_source_code || ': Time first record Fetched From Regular Orgs Transformation Query', v_crnt_proc_name, 'I');
                        dm_util_log.p_log_msg(p_msg_id, 10, NULL, NULL, 'U');
               END IF;

               IF ((v_prev_org_id <> c2_rec.org_id) OR ((v_prev_org_id = c2_rec.org_id) AND (v_prev_rec_ver_id <> c2_rec.version_id)))
                  THEN
                       v_prev_rec_ver_id := c2_rec.version_id;
                       UPDATE dm_organization_dim l
                          SET l.is_effective = 'N'
                              , l.valid_to_date = c2_rec.creation_date-(1/86400)
                              , l.last_update_date = SYSDATE
                              , l.batch_id = p_msg_id
                        WHERE l.org_id = c2_rec.org_id
                          AND l.is_effective = 'Y'
                          AND l.data_source_code = p_source_code
                       RETURNING l.version_id, l.valid_to_date INTO v_prev_ver_id, v_new_valid_to_date;

                       v_rec_count := SQL%ROWCOUNT;
                       IF (v_rec_count = 0)
                          THEN
                               v_prev_ver_id := 0;
                          ELSE
                               v_upd_count := v_upd_count+1;

                               IF (c2_rec.org_type = 'Buyer')
                                  THEN
                                       UPDATE dm_buyer_dim l
                                          SET   l.is_effective = 'N'
                                              , l.valid_to_date = v_new_valid_to_date
                                              , l.last_update_date = SYSDATE
                                              , l.batch_id = p_msg_id
                                              , l.latest_org_name = c2_rec.org_name
                                        WHERE l.org_id = c2_rec.org_id
                                          AND l.is_effective = 'Y'
                                          AND l.version_id   = v_prev_ver_id -- Additional Check to make sure versions are matching with dm_organization_dim
                                          AND l.data_source_code = p_source_code;

                                       UPDATE dm_buyer_dim l
                                          SET l.latest_org_name = c2_rec.org_name
                                        WHERE l.org_id = c2_rec.org_id
                                          AND l.is_effective = 'N'
                                          AND l.version_id   < v_prev_ver_id
                                          AND l.data_source_code = p_source_code;
                                  ELSE
                                       UPDATE dm_supplier_dim l
                                          SET   l.is_effective = 'N'
                                              , l.valid_to_date = v_new_valid_to_date
                                              , l.last_update_date = SYSDATE
                                              , l.batch_id = p_msg_id
                                              , l.latest_org_name = c2_rec.org_name
                                        WHERE l.org_id = c2_rec.org_id
                                          AND l.is_effective = 'Y'
                                          AND l.version_id   = v_prev_ver_id -- Additional Check to make sure versions are matching with dm_organization_dim
                                          AND l.data_source_code = p_source_code;

                                       UPDATE dm_supplier_dim l
                                          SET l.latest_org_name = c2_rec.org_name
                                        WHERE l.org_id = c2_rec.org_id
                                          AND l.is_effective = 'N'
                                          AND l.version_id   < v_prev_ver_id
                                          AND l.data_source_code = p_source_code;
                               END IF;
                       END IF;
                       v_start_date  := c2_rec.creation_date;
                       v_prev_org_id := c2_rec.org_id;
               END IF;

               INSERT INTO dm_organization_dim
               (
                   org_dim_id
                 , org_id
                 , data_source_code
                 , version_id
                 , org_type
                 , org_name
                 , top_parent_org_id
                 , is_effective
                 , primary_geo_dim_id
                 , valid_from_date
                 , valid_to_date
                 , top_parent_org_dim_id
                 , fo_state_name
                 , fo_city_name
                 , fo_postal_code
                 , fo_country_name
                 , batch_id
                 , last_update_date
               )
               VALUES
               (
                   dm_organization_dim_seq.NEXTVAL --org_dim_id
                 , c2_rec.org_id
                 , p_source_code
                 , v_prev_ver_id + 1
                 , c2_rec.org_type
                 , c2_rec.org_name
                 , c2_rec.top_parent_org_id
                 , 'Y' -- is_effective
                 , c2_rec.primary_geo_dim_id
                 , v_start_date -- valid_from_date
                 , c2_rec.valid_to_date
                 , c2_rec.top_parent_org_dim_id
                 , c2_rec.state_name
                 , c2_rec.city_name
                 , c2_rec.postal_code
                 , c2_rec.country_name
                 , p_msg_id -- batch_id
                 , SYSDATE  -- last_update_date
               )
               RETURNING org_dim_id INTO v_new_org_dim_id;

               v_org_count := v_org_count+1;

               IF (c2_rec.org_type = 'Buyer')
                  THEN
                       INSERT INTO dm_buyer_dim
                       (
                           org_dim_id
                         , org_id
                         , data_source_code
                         , version_id
                         , org_type
                         , org_name
                         , latest_org_name
                         , top_parent_org_id
                         , is_effective
                         , primary_geo_dim_id
                         , valid_from_date
                         , valid_to_date
                         , top_parent_org_dim_id
                         , fo_state_name
                         , fo_city_name
                         , fo_postal_code
                         , fo_country_name
                         , batch_id
                         , last_update_date
                       )
                       VALUES
                       (
                           v_new_org_dim_id --org_dim_id
                         , c2_rec.org_id
                         , p_source_code
                         , v_prev_ver_id + 1
                         , c2_rec.org_type
                         , c2_rec.org_name
                         , c2_rec.org_name
                         , c2_rec.top_parent_org_id
                         , 'Y' -- is_effective
                         , c2_rec.primary_geo_dim_id
                         , v_start_date -- valid_from_date
                         , c2_rec.valid_to_date
                         , c2_rec.top_parent_org_dim_id
                         , c2_rec.state_name
                         , c2_rec.city_name
                         , c2_rec.postal_code
                         , c2_rec.country_name
                         , p_msg_id -- batch_id
                         , SYSDATE  -- last_update_date
                       );

                       /*
                       ** If buyer org_id being created 
                       ** for the first time 
                       */
                       IF (v_prev_ver_id = 0 AND c2_rec.version_id = 1)
                          THEN
                               /*
                               ** Add org_id specific dim_records to represent NULL values
                               */
                               dm_cube_utils.create_null_ratecard_dims(p_msg_id, c2_rec.org_id, p_source_code);
                               dm_cube_utils.create_null_person_dims(p_msg_id, c2_rec.org_id, p_source_code);
                               dm_cube_utils.create_null_invoiced_cac_dims(p_msg_id, c2_rec.org_id, p_source_code);
                               dm_cube_utils.create_null_pa_dims(p_msg_id, c2_rec.org_id, p_source_code);
                               dm_cube_utils.create_null_job_dims(p_msg_id, c2_rec.org_id, p_source_code);
                       END IF;
                  ELSE
                       INSERT INTO dm_supplier_dim
                       (
                           org_dim_id
                         , org_id
                         , data_source_code
                         , version_id
                         , org_type
                         , org_name
                         , latest_org_name
                         , top_parent_org_id
                         , is_effective
                         , primary_geo_dim_id
                         , valid_from_date
                         , valid_to_date
                         , top_parent_org_dim_id
                         , fo_state_name
                         , fo_city_name
                         , fo_postal_code
                         , fo_country_name
                         , batch_id
                         , last_update_date
                       )
                       VALUES
                       (
                           v_new_org_dim_id --org_dim_id
                         , c2_rec.org_id
                         , p_source_code
                         , v_prev_ver_id + 1
                         , c2_rec.org_type
                         , c2_rec.org_name
                         , c2_rec.org_name
                         , c2_rec.top_parent_org_id
                         , 'Y' -- is_effective
                         , c2_rec.primary_geo_dim_id
                         , v_start_date -- valid_from_date
                         , c2_rec.valid_to_date
                         , c2_rec.top_parent_org_dim_id
                         , c2_rec.state_name
                         , c2_rec.city_name
                         , c2_rec.postal_code
                         , c2_rec.country_name
                         , p_msg_id -- batch_id
                         , SYSDATE  -- last_update_date
                       );
               END IF;

               IF (c2_rec.valid_to_date IS NOT NULL)
                  THEN
                       v_start_date := c2_rec.valid_to_date+(1/86400);
                  ELSE
                       v_start_date := NULL;
               END IF;
          EXCEPTION
             WHEN OTHERS THEN
             lv_db_err_msg := SQLERRM || ' for Org_id2 =' || c2_rec.org_id || ', valid_to_date2 ' || TO_CHAR(c2_rec.valid_to_date, 'DD-MON-YYYY HH24:MI:SS');
             RAISE_APPLICATION_ERROR(-20503, lv_db_err_msg);
          END;
          END LOOP;
          COMMIT;
          dm_util_log.p_log_msg(p_msg_id, 9, NULL, NULL, 'U');
          dm_util_log.p_log_msg(p_msg_id, 11, p_source_code || ': ' || v_upd_count || ' Organization versions Updated(Invalidated)', v_crnt_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, 11, NULL, NULL, 'U');
          dm_util_log.p_log_msg(p_msg_id, 12, p_source_code || ': ' || v_org_count || ' Organization versions added', v_crnt_proc_name, 'I');
          dm_util_log.p_log_msg(p_msg_id, 12, NULL, NULL, 'U');
    END just_transform;

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
    )
    IS
          v_crnt_proc_name user_jobs.what%TYPE := 'DM_ORG_DIM.PULL_AND_TRANSFORM';
          v_rec_count      NUMBER;
    BEGIN
          dm_util_log.p_log_msg(p_msg_id, 2, p_source_code || ': Truncate DW Temp Tables', v_crnt_proc_name, 'I');
          EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_dm_org_dim_tmp';
          dm_util_log.p_log_msg(p_msg_id, 2, NULL, NULL, 'U');

          CASE (p_source_code)
            WHEN 'REGULAR'  THEN
              BEGIN
                    dm_util_log.p_log_msg(p_msg_id, 3, p_source_code || ': Pull Organization Data from FO to DW', v_crnt_proc_name, 'I');
                    INSERT INTO fo_dm_org_dim_tmp t       SELECT * FROM fo_dm_org_dim_tmp@FO_R;
                    v_rec_count := SQL%ROWCOUNT;
                    COMMIT;
                    dm_util_log.p_log_msg(p_msg_id, 3, NULL, NULL, 'U');

                    dm_util_log.p_log_msg(p_msg_id, 4, p_source_code || ': Pulled ' || v_rec_count || ' Organization Data records from FO to DW', v_crnt_proc_name, 'I');
                    dm_util_log.p_log_msg(p_msg_id, 4, NULL, NULL, 'U');
              END;
          END CASE;
          just_transform(p_source_code, p_msg_id);
    END pull_and_transform;

    PROCEDURE pull_transform_fo_org
    (
        p_source_code IN VARCHAR2
      , p_org_id      IN dm_organization_dim.org_id%TYPE
    )
    IS
         v_sql          VARCHAR2(32767);
         v_link_name    VARCHAR2(16);
         p_msg_id       NUMBER;
    BEGIN
         BEGIN
               SELECT NULL
                 INTO v_sql
                 FROM dm_organization_dim
                WHERE org_id = p_org_id
                  AND data_source_code = p_source_code
                  AND is_effective = 'Y'
                  AND ROWNUM < 2;

               -- Requested org already exists so do nothing
               RETURN;
         EXCEPTION
             WHEN NO_DATA_FOUND THEN NULL;
         END;

         dm_cube_utils.make_indexes_visible;

         --
         -- Get the sequence reuired for logging messages
         --
         SELECT dm_msg_log_seq.NEXTVAL INTO p_msg_id FROM dual;

         CASE (p_source_code)
              WHEN 'REGULAR'  THEN v_link_name := 'FO_R';
         END CASE;

         EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_dm_org_dim_tmp';
         v_sql :='INSERT INTO fo_dm_org_dim_tmp     
                  SELECT /*+ DRIVING_SITE(os) */  os.business_organization_fk
                         , ''' || p_source_code || '''
                         , os.name AS org_name
                         , DECODE(fr.firm_type, ''D'', ''Buyer'', ''Supplier'')
                         , NVL(bob.business_organization_id, fr.business_org_fk) top_parent_org_id
                         , os.creation_date
                         , os.valid_to_date
                         , UPPER(a.providence)
                         , UPPER(a.city)
                         , UPPER(a.postal_code)
                         , UPPER(c.description)
                    FROM org_snapshot@LNK os, business_organization@LNK bo, firm_role@LNK fr, address@LNK a, country@LNK c
                         , bus_org_lineage@LNK bol, business_organization@LNK bob
                   WHERE os.business_organization_fk IN (' || p_org_id || ')
                     AND bo.business_organization_id = os.business_organization_fk
                     AND fr.business_org_fk = bo.business_organization_id
                     and fr.firm_id > 0
                     and fr.firm_type IN (''D'', ''S'')
                     and a.contact_info_fk (+) = bo.contact_information_fk
                     and a.address_type (+) = ''P''
                     and a.name(+) = ''Primary''
                     and c.value (+) = a.country
                     AND bol.descendant_bus_org_fk    (+) = fr.business_org_fk
                     AND bob.business_organization_id (+) = bol.ancestor_bus_org_fk
                     AND bob.parent_business_org_fk IS NULL';

         v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
         EXECUTE IMMEDIATE v_sql;

         just_transform(p_source_code, p_msg_id);
    END pull_transform_fo_org;

    PROCEDURE redo_org_dim(p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
    IS
    BEGIN
          EXECUTE IMMEDIATE 'DROP SEQUENCE dm_organization_dim_seq';
          EXECUTE IMMEDIATE 'CREATE SEQUENCE dm_organization_dim_seq START WITH 1 CACHE 20';

          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_buyer_dim';
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_supplier_dim';
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_organization_dim';

          UPDATE mart_load_parms@FO_R
             SET parm_value = 0
           WHERE parm_name = 'ORG_DIM_SNAPSHOT_ID';

          p_main('REGULAR',p_date_id);
    END redo_org_dim;
END dm_org_dim;
/