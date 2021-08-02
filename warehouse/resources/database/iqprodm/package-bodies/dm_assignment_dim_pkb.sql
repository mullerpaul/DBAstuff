CREATE OR REPLACE PACKAGE BODY dm_assignment_dim_process
AS
    PROCEDURE p_main
    (
        p_source_code IN VARCHAR2
      , p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
    )
    IS
       p_msg_id            NUMBER;
       ln_count            NUMBER;
       lv_proc_name        user_jobs.what%TYPE := 'DM_ASSIGNMENT_DIM_PROCESS.P_MAIN';
       v_crnt_proc_name    user_jobs.what%TYPE;

       lv_fo_app_err_msg   VARCHAR2(2000)  := NULL;
       lv_fo_db_err_msg    VARCHAR2(2000)  := NULL;
       lv_app_err_msg      VARCHAR2(2000)  := NULL;
       lv_db_err_msg       VARCHAR2(2000)  := NULL;

       email_sender        VARCHAR2(32) := 'mart_processing@iqnavigator.com';
       email_recipients    VARCHAR2(64) := 'data_warehouse@iqnavigator.com';
       email_subject       VARCHAR2(64) := 'DM_ASSIGNMENT_DIM_PROCESS Update';
       remote_extract_done VARCHAR2(1) := 'N';

       v_inp_rec_count     NUMBER;
       
       v_cutoff_date       VARCHAR2(16);
    BEGIN
       /*
       ** Alter session so that process/optimizer
       ** can see all invisible indexes
       */
       dm_cube_utils.make_indexes_visible;

       v_crnt_proc_name := lv_proc_name;

       --
       -- Get the sequence required for logging messages
       --
       SELECT dm_msg_log_seq.NEXTVAL INTO p_msg_id FROM dual;

       --
       -- Check if the previous job still running
       --
       ln_count := dm_cube_utils.get_job_status(lv_proc_name);
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
           -- Call the procedure to get the FO New Assignment information
           --
           v_cutoff_date := TO_CHAR(SYSDATE-0.291667, 'YYYYMMDDHH24MISS'); -- Current time - 7 hours
           v_crnt_proc_name := 'DM_ASSIGNMENT_DIM_PROCESS.GET_NEW_ASSIGNMENT_CHANGES';
           dm_util_log.p_log_msg(p_msg_id,1, p_source_code || ': FO Assignment Extract',v_crnt_proc_name,'I');
           get_new_assignment_changes(p_msg_id, p_source_code, v_cutoff_date, v_inp_rec_count);
           remote_extract_done := 'Y';
           dm_util_log.p_log_msg(p_msg_id,1, NULL,NULL,'U');

           dm_util_log.p_log_load_status(p_msg_id, gv_process,'FO','COMPLETE',0,'U');

           dm_util_log.p_log_load_status(p_msg_id, gv_process,'DW','STARTED',NULL,'I');
           pull_and_transform(p_source_code, p_msg_id);

           UPDATE dm_cube_objects
              SET   last_identifier  = TO_NUMBER(v_cutoff_date)
                  , last_update_date = SYSDATE
            WHERE object_name = 'DM_ASSIGNMENT_DIM'
              AND object_source_code = p_source_code;

           COMMIT;
           dm_util_log.p_log_load_status(p_msg_id, gv_process,'DW','COMPLETE',0,'U');
       END IF;
       
           DM_UTIL_LOG.p_log_cube_load_status('DM_ASSIGNMENT_DIM', p_source_code , 'SPEND_CUBE-DIM', 'COMPLETED', p_date_id);
    EXCEPTION
       WHEN OTHERS THEN
       BEGIN
             lv_fo_db_err_msg := SQLERRM;
             IF (remote_extract_done = 'Y')
                THEN
                     lv_fo_app_err_msg := 'Unable to execute the procedure to Pull and Transform Assignment data after successful FO extraction!';
                     dm_util_log.p_log_load_status(p_msg_id, gv_process,'DW','FAILED',0,'U');
                ELSE
                     dm_util_log.p_log_load_status(p_msg_id, gv_process,'FO','FAILED',0,'U');
             END IF;
             DM_UTIL_LOG.p_log_cube_load_status('DM_ASSIGNMENT_DIM', p_source_code , 'SPEND_CUBE-DIM', 'FAILED', p_date_id);             
             dm_utils.send_email(email_sender, email_recipients, email_subject, p_source_code || ' Process failed due to the following ' || c_crlf || lv_fo_app_err_msg || c_crlf || lv_fo_db_err_msg || c_crlf);
       END;
    END p_main;

    PROCEDURE get_new_assignment_changes
    (
        p_msg_id        IN  NUMBER
      , p_source_code   IN  VARCHAR2
      , p_cutoff_date   IN  VARCHAR2
      , p_out_rec_count OUT NUMBER  -- Records Extracted
    )
    IS
       lv_proc_name         VARCHAR2(100)  := 'DM_ASSIGNMENT_DETAILS.GET_NEW_ASSIGNMENT_CHANGES';

       v_sql VARCHAR2(8192);
       v_link_name   VARCHAR2(32);    -- Name of DB Link to FO Instance
       v_min_ae_date VARCHAR2(16);
       v_prev_cutoff VARCHAR2(16);
       v_full_refresh VARCHAR2(1) := 'N';
       v_metadata_exists VARCHAR2(1) := 'Y';
    BEGIN
       CASE (p_source_code)
           WHEN 'REGULAR'  THEN v_link_name := 'FO_R';
           WHEN 'WACHOVIA' THEN v_link_name := 'WA_LINK';
           WHEN 'JPMC'     THEN v_link_name := 'JP_FO_LINK';
       END CASE;

       BEGIN
             SELECT TO_CHAR(last_identifier)
               INTO v_min_ae_date
               FROM dm_cube_objects
              WHERE object_name = 'DM_ASSIGNMENT_DIM'
                AND object_source_code = p_source_code
                AND ROWNUM = 1;

             IF (v_min_ae_date = '0')
                THEN
                     v_full_refresh    := 'Y';
                     v_metadata_exists := 'Y';
             END IF;
       EXCEPTION
            WHEN NO_DATA_FOUND THEN v_full_refresh    := 'Y';
                                    v_metadata_exists := 'N';
       END;

       IF (v_full_refresh = 'Y')
          THEN
               /*
               ** This should happen only on
               ** first time or when DM is empty
               ** NOTE: DM is interested only in data on/after 1st January 1999
               */
               v_sql := 'SELECT TO_CHAR(MIN(create_date), ''YYYYMMDDHH24MISS'')
                           FROM assignment_edition@LNK
                          WHERE valid_to_date >= TO_DATE(''19990101'', ''YYYYMMDD'')';
               v_sql := REPLACE(v_sql, '@LNK', '@' || v_link_name);
               EXECUTE IMMEDIATE v_sql INTO v_min_ae_date;

               IF (v_metadata_exists = 'N')
                  THEN
                       INSERT INTO dm_cube_objects (object_name, object_source_code, last_update_date, last_identifier) 
                       VALUES ('DM_ASSIGNMENT_DIM', p_source_code, SYSDATE, TO_NUMBER(v_min_ae_date));
                  ELSE
                       UPDATE dm_cube_objects
                          SET   last_identifier  = TO_NUMBER(v_min_ae_date)
                              , last_update_date = SYSDATE
                        WHERE object_name = 'DM_ASSIGNMENT_DIM'
                          AND object_source_code = p_source_code;
               END IF;
               COMMIT;
       END IF;
       v_prev_cutoff := v_min_ae_date;

       --DBMS_OUTPUT.PUT_LINE('v_prev_cutoff = ' || v_prev_cutoff);
       --DBMS_OUTPUT.PUT_LINE('cut off date = ' || p_cutoff_date);

       EXECUTE IMMEDIATE 'TRUNCATE TABLE fo_dm_assignments_tmp';

       v_sql := 'INSERT INTO fo_dm_assignments_tmp
                      (
                          assignment_id
                        , custom_place_id
                        , standard_place_id
                        , sourcing_method
                        , data_source_code
                        , engagement_classification 
                        , actual_end_date
                        , job_fk
                        , source_template_id
                        , rate_card_identifier_fk
                        , owning_buyer_firm_fk
                        , buyer_bro_firm_id
                        , owning_supply_firm_fk
                        , supplier_bro_firm_id
                        , custom_address_city
                        , custom_address_state
                        , custom_address_postal_code
                        , custom_country_name
                        , address_city
                        , address_state
                        , address_postal_code
                        , address_country_name
                      )
                 SELECT /*+ DRIVING_SITE(ac) */
                          ac.assignment_continuity_id
                        , adr.place_fk
                        , pl.standard_place_fk
                        , ae.sourcing_method_name_fk
                        , ''' || p_source_code || '''
                        , CASE
                            WHEN ina.project_agreement_fk IS NOT NULL THEN ''Project/SOW''
                            WHEN ac.project_agmt_fk IS NULL  THEN ''Contingent''
         		    ELSE ''Project/SOW''
                          END AS engagement_classification
                        , ae.actual_end_date
                        , ac.job_fk
                        , j.source_template_id
                        , j.rate_card_identifier_fk
                        , ac.owning_buyer_firm_fk
                        , get_bro_firm@LNK(ac.owning_buyer_firm_fk)
                        , ac.owning_supply_firm_fk
                        , get_bro_firm@LNK(ac.owning_supply_firm_fk)
                        , UPPER(REPLACE(REPLACE(REPLACE(pl.city, ''- ''), '',''), '' -''))
                        , REPLACE(pl.state, '' -'')
                        , DECODE(pl.postal_code, ''x'', NULL, pl.postal_code)
                        , UPPER(c.description)
                        , UPPER(REPLACE(REPLACE(REPLACE(spl.city, ''- ''), '',''), '' -''))
                        , REPLACE(spl.state, '' -'')
                        , DECODE(spl.postal_code, ''x'', NULL, spl.postal_code)
                        , UPPER(c1.description)
                   FROM   (
                            SELECT ae1.*
                              FROM assignment_edition@LNK ae1
                             WHERE ae1.create_date >= TO_DATE(''' || v_prev_cutoff || ''', ''YYYYMMDDHH24MISS'')
                               AND ae1.create_date <  TO_DATE(''' || p_cutoff_date || ''', ''YYYYMMDDHH24MISS'')
                             UNION           
                            SELECT /*+ DYNAMIC_SAMPLING(upd 10) */ ae2.*
                              FROM ae_sm_upd@LNK upd, assignment_edition@LNK ae2
                             WHERE upd.date_processed  >= TO_DATE(''' || v_prev_cutoff || ''', ''YYYYMMDDHH24MISS'')
                               AND upd.date_processed  <  TO_DATE(''' || p_cutoff_date || ''', ''YYYYMMDDHH24MISS'')
                               AND ae2.assignment_edition_id = upd.assignment_edition_id
                          ) ae, assignment_continuity@LNK ac, invoiced_agreement@LNK ina, job@LNK j
                        , address@LNK adr, place@LNK pl, place@LNK spl, country@LNK c, country@LNK c1
                  WHERE ac.current_edition_fk = ae.assignment_edition_id
                    AND ac.job_fk = j.job_id
                    AND ae.resource_onsite_fk = adr.contact_info_fk(+)
                    AND ina.project_agreement_fk (+) IS NOT NULL
                    AND ina.assignment_continuity_fk(+) = ac.assignment_continuity_id 
                    AND adr.place_fk = pl.value(+)
                    AND adr.address_type = ''P''
                    AND spl.value(+)= pl.standard_place_fk
                    AND c.value(+)  = TO_NUMBER(pl.country)
                    AND c1.value(+) = TO_NUMBER(spl.country)';

       v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
       EXECUTE IMMEDIATE v_sql;
       p_out_rec_count := SQL%ROWCOUNT;
       COMMIT;
    END get_new_assignment_changes;

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
          v_crnt_proc_name user_jobs.what%TYPE := 'DM_ASSIGNMENT_DETAILS.PULL_AND_TRANSFORM';
    BEGIN
          MERGE INTO dm_assignment_dim t
          USING fo_dm_assignments_tmp s
             ON (
                      t.data_source_code    = p_source_code
                  AND t.assignment_id       = s.assignment_id
                )
           WHEN MATCHED THEN UPDATE SET
                   t.custom_place_id            = s.custom_place_id
                 , t.standard_place_id          = s.standard_place_id
                 , t.sourcing_method            = s.sourcing_method
                 , t.engagement_classification  = s.engagement_classification
                 , t.last_update_date           = SYSDATE
                 , t.actual_end_date            = s.actual_end_date
                 , t.job_fk                     = s.job_fk
                 , t.source_template_id         = s.source_template_id
                 , t.rate_card_identifier_fk    = s.rate_card_identifier_fk
                 , t.owning_buyer_firm_fk       = s.owning_buyer_firm_fk
                 , t.buyer_bro_firm_id          = s.buyer_bro_firm_id
                 , t.owning_supply_firm_fk      = s.owning_supply_firm_fk
                 , t.supplier_bro_firm_id       = s.supplier_bro_firm_id
                 , t.custom_address_city        = s.custom_address_city
                 , t.custom_address_state       = s.custom_address_state
                 , t.custom_address_postal_code = s.custom_address_postal_code
                 , t.custom_country_name        = s.custom_country_name
                 , t.address_city               = s.address_city
                 , t.address_state              = s.address_state
                 , t.address_postal_code        = s.address_postal_code
                 , t.address_country_name       = s.address_country_name
           WHEN NOT MATCHED THEN INSERT
           (
                   assignment_dim_id
                 , assignment_id
                 , custom_place_id
                 , standard_place_id
                 , sourcing_method
                 , data_source_code
                 , engagement_classification
                 , last_update_date
                 , actual_end_date
                 , job_fk
                 , source_template_id
                 , rate_card_identifier_fk
                 , owning_buyer_firm_fK
                 , buyer_bro_firm_id
                 , owning_supply_firm_fk
                 , supplier_bro_firm_id
                 , custom_address_city
                 , custom_address_state
                 , custom_address_postal_code
                 , custom_country_name
                 , address_city
                 , address_state
                 , address_postal_code
                 , address_country_name
           )
           VALUES
           (
                   dm_assignment_dim_seq.NEXTVAL
                 , s.assignment_id
                 , s.custom_place_id
                 , s.standard_place_id
                 , s.sourcing_method
                 , s.data_source_code
                 , s.engagement_classification
                 , SYSDATE -- last_update_date
                 , s.actual_end_date
                 , s.job_fk
                 , s.source_template_id
                 , s.rate_card_identifier_fk
                 , s.owning_buyer_firm_fK
                 , s.buyer_bro_firm_id
                 , s.owning_supply_firm_fk
                 , s.supplier_bro_firm_id
                 , s.custom_address_city
                 , s.custom_address_state
                 , s.custom_address_postal_code
                 , s.custom_country_name
                 , s.address_city
                 , s.address_state
                 , s.address_postal_code
                 , s.address_country_name
           );
          COMMIT;

          dm_util_log.p_log_msg(p_msg_id, 5, NULL, NULL, 'U');
    END pull_and_transform;

    PROCEDURE redo_assignments(p_date_id IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
    IS
    BEGIN
          EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_assignment_dim';
 	  EXECUTE IMMEDIATE 'DROP SEQUENCE dm_assignment_dim_seq';
 	  EXECUTE IMMEDIATE 'CREATE SEQUENCE dm_assignment_dim_seq START WITH 101 CACHE 20';

          INSERT INTO dm_assignment_dim (ASSIGNMENT_DIM_ID, ASSIGNMENT_ID, DATA_SOURCE_CODE, LAST_UPDATE_DATE)
                                 VALUES (0, 0, 'REGULAR', SYSDATE);
          INSERT INTO dm_assignment_dim (ASSIGNMENT_DIM_ID, ASSIGNMENT_ID, DATA_SOURCE_CODE, LAST_UPDATE_DATE)
                                 VALUES (1, 0, 'WACHOVIA', SYSDATE);
          INSERT INTO dm_assignment_dim (ASSIGNMENT_DIM_ID, ASSIGNMENT_ID, DATA_SOURCE_CODE, LAST_UPDATE_DATE)
                                 VALUES (2, 0, 'JPMC', SYSDATE);
          COMMIT;

          UPDATE dm_cube_objects
             SET   last_identifier = 0
                 , last_update_date = SYSDATE
           WHERE object_name = 'DM_ASSIGNMENT_DIM'
             AND object_source_code = 'REGULAR';

          COMMIT;

          p_main('REGULAR', p_date_id );
    END redo_assignments;
END dm_assignment_dim_process;
/