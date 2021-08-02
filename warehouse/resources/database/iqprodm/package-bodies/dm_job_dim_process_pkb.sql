CREATE OR REPLACE PACKAGE BODY dm_job_dim_process
/******************************************************************************
 * Name:   dm_job_dim_process
 * Desc:   This package contains all the procedures required to
 *         migrate/process the Job Dimension
 * Source: Front office Tables (Job and related tables)
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Manoj   07/30/2010    Initial
 * JoeP    02/01/2016    Hard-coded dblink 
 *******************************************************************************/
AS

 /*****************************************************************
  * Name: process_fo_job_dim
  * Desc: This procedure calls a procedure residing in Front office
  *       to gather the data needed for Job dim into a work table in
  *       FO and later pulls the data into data mart work table
  *
  *****************************************************************/
  PROCEDURE process_fo_job_dim(in_msg_id              IN  NUMBER,
                               in_last_processed_id   IN  NUMBER,
                               id_last_processed_date IN  DATE,
                               on_err_num             OUT NUMBER,
                               ov_err_msg             OUT VARCHAR2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_job_dim_process.process_fo_job_dim' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER;

  BEGIN
     on_err_num := 0;
     ov_err_msg := NULL;
     --
     -- execute the procedure to get FO Project agreement DIM data (this is a remote procedure that resides in FO reporting)
     -- this procedure gets the data since the last run
     --
     BEGIN
       FO_DM_JOB_DIM_PROCESS.p_main@FO_R(in_msg_id,'REGULAR',in_last_processed_id,id_last_processed_date);
     EXCEPTION
       WHEN OTHERS THEN
            lv_app_err_msg := 'Unable to execute the procedure to get the Job Dim data from FO !';
            lv_db_err_msg := SQLERRM;
	    RAISE le_exception;
     END;

     --
     -- check for any errors in remote procedure
     --
     BEGIN
       SELECT err_msg
         INTO lv_err_msg
         FROM fo_dm_err_msg_tmp@FO_R;

          IF lv_err_msg IS NOT NULL THEN
             lv_app_err_msg := 'Errors occured in the procedure to get Job DIM data ! ';
             lv_db_err_msg := lv_err_msg||' '||SQLERRM;
             RAISE le_exception;
          END IF;

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
             lv_err_msg := NULL;
     END;

    --
    -- Pull the data from Front office to a temp table
    --
    BEGIN
      INSERT INTO dm_job_dim_tmp t
             (data_source_code,
              buyerorg_id,
	      buyerfirm_id,
	      job_id,
	      top_buyerorg_id,
	      job_category_id,
	      job_title,
              job_state,
	      last_modified_date,
	      job_created_date,
	      job_approved_date,
              rate_range_low,
              rate_range_high,
              rate_type,
	      job_desc,
	      source_of_record,
	      job_skills_text,
	      job_category_desc,
	      source_template_id,
	      job_level_id,
	      job_level_desc
             )
      SELECT  data_source_code,
              buyerorg_id,
	      buyerfirm_id,
	      job_id,
	      top_buyerorg_id,
	      job_category_id,
	      job_title,
              job_state,
	      last_modified_date,
	      job_created_date,
	      job_approved_date,
              rate_range_low,
              rate_range_high,
              rate_type,
	      job_desc,
	      source_of_record,
	      job_skills_text,
	      job_category_desc,
	      source_template_id,
	      job_level_id,
	      job_level_desc
         FROM fo_dm_job_dim_tmp@FO_R;
         commit;
    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into temp table dm_job_dim_tmp the data from FO! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
    END;


  EXCEPTION
    WHEN le_exception THEN
      --
      -- user defined exception, Log and raise the application error.
      --
      on_err_num := DM_UTIL_LOG.f_log_error(in_msg_id,
                                             lv_app_err_msg,
                                             lv_db_err_msg,
                                             lv_proc_name);

      ov_err_msg := lv_app_err_msg;
    WHEN OTHERS THEN
      --
      -- Unknown exception, Log and raise the application error.
      --
      Rollback;
      lv_app_err_msg := 'Unknown Error !';
      lv_db_err_msg  := SQLERRM;
      on_err_num     := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                 lv_app_err_msg,
                                                 lv_db_err_msg,
                                                 lv_proc_name);
      ov_err_msg     := lv_app_err_msg;
  END process_fo_job_dim;

 /*****************************************************************
  * Name: process_dm_job_dim
  * Desc: This procedure pulls the data from temp table and
  *       performs the following tasks in data mart
  *       1. First time load all the data from temp table
  *       2. All loads after the initial load needs to check
  *          data existence. if the row exists update the is_effective
  *          to 'N' and make the new row 'Y'
  *****************************************************************/
  PROCEDURE process_dm_job_dim(in_msg_id            IN number,
                              iv_first_time_flag   IN varchar2,
                              on_err_num          OUT number,
                              ov_err_msg          OUT varchar2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_job_dim_process.process_dm_job_dim' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER;
    ld_date              DATE                    ;
    ln_version_id        NUMBER;
    ln_job_dim_id        NUMBER;
    CURSOR job_cur
    IS
    SELECT distinct a.*
      FROM dm_job_dim     b,
           dm_job_dim_tmp a
     WHERE a.job_id = b.job_id
       AND a.data_source_code = b.data_source_code;

  BEGIN
    on_err_num := 0;
    ov_err_msg := NULL;

    ld_date :=SYSDATE;

    IF iv_first_time_flag = 'N' THEN
       --
       -- This section deals with loads after the initial one
       --

       --
       -- Loop through cursor forall the deltas ( from temp table)
       -- and check anything has changed. If anything is changed then update the old ones effective flag to 'N'
       --
       FOR job_cur_rec IN job_cur
       LOOP

        SELECT count(1)
          INTO ln_count
          FROM dm_job_dim
         WHERE job_id                                     = job_cur_rec.job_id
           AND buyerorg_id                                = job_cur_rec.buyerorg_id
           AND nvl(top_buyerorg_id,0)                     = nvl(job_cur_rec.top_buyerorg_id,0)
           AND nvl(job_category_id,0)                     = nvl(job_cur_rec.job_category_id,0)
           AND nvl(job_title,'x')                         = nvl(job_cur_rec.job_title,'x')
           AND nvl(job_state,'x')                         = nvl(job_cur_rec.job_state,'x')
           AND nvl(job_last_modified_date,'01-JAN-1999')  = nvl(job_cur_rec.last_modified_date,'01-JAN-1999')
           AND nvl(job_created_date,'01-JAN-1999')        = nvl(job_cur_rec.job_created_date,'01-JAN-1999')
           AND nvl(job_approved_date,'01-JAN-1999')       = nvl(job_cur_rec.job_approved_date,'01-JAN-1999')
           AND nvl(job_desc,'x')                          = nvl(job_cur_rec.job_desc,'x')
           AND nvl(job_skills_text,'x')                   = nvl(job_cur_rec.job_skills_text,'x')
           AND nvl(rate_range_low,0)                      = nvl(job_cur_rec.rate_range_low,0)
           AND nvl(rate_range_high,0)                     = nvl(job_cur_rec.rate_range_high,0)
           AND nvl(rate_type,'x')                         = nvl(job_cur_rec.rate_type,'x')
           AND nvl(job_category_desc,'x')                 = nvl(job_cur_rec.job_category_desc,'x')
           AND nvl(job_level_id,0)                        = nvl(job_cur_rec.job_level_id,0)
           AND nvl(job_level_desc,'x')                    = nvl(job_cur_rec.job_level_desc,'x')
           AND nvl(source_template_id,0)                  = nvl(job_cur_rec.source_template_id,0);

        IF ln_count = 0 THEN
           BEGIN
             UPDATE dm_job_dim
                SET is_effective     = 'N',
                    valid_to_date    = (ld_date  -(1/86400)),
                    last_update_date = SYSDATE
              WHERE job_id           = job_cur_rec.job_id
                AND is_effective     = 'Y'
                RETURNING version_id INTO ln_version_id;
           EXCEPTION
             WHEN OTHERS THEN
              lv_app_err_msg := 'Unable to update dm_job_dim ! ';
              lv_db_err_msg := SQLERRM;
              RAISE le_exception;
           END;

         BEGIN

          INSERT
            INTO dm_job_dim
                 (job_dim_id,
                  job_id,
                  buyerorg_id,
                  data_source_code,
                  top_buyerorg_id,
                  job_category_id,
                  job_title,
                  std_buyerorg_id,
                  job_state,
                  job_last_modified_date,
                  job_created_date,
                  job_approved_date,
                  job_desc,
                  job_skills_text,
                  rate_range_low,
                  rate_range_high,
                  rate_type,
                  job_category_desc,
                  std_job_category_id,
                  job_level_id,
                  job_level_desc,
                  std_job_title_id,
                  source_template_id,
                  source_of_record,
                  version_id,
                  is_effective,
                  valid_from_date,
                  valid_to_date,
                  batch_id,
                  last_update_date
                 )
          SELECT  dm_job_dim_seq.NEXTVAL,
                  job_cur_rec.job_id,
                  job_cur_rec.buyerorg_id,
                  job_cur_rec.data_source_code,
                  job_cur_rec.top_buyerorg_id,
                  job_cur_rec.job_category_id,
                  job_cur_rec.job_title,
                  (SELECT std_buyerorg_id FROM fo_buyers_map WHERE buyerorg_id =job_cur_rec.buyerorg_id and data_source_code =job_cur_rec.data_source_code),
                  job_cur_rec.job_state,
                  job_cur_rec.last_modified_date,
                  job_cur_rec.job_created_date,
                  job_cur_rec.job_approved_date,
                  job_cur_rec.job_desc,
                  job_cur_rec.job_skills_text,
                  job_cur_rec.rate_range_low,
                  job_cur_rec.rate_range_high,
                  job_cur_rec.rate_type,
                  job_cur_rec.job_category_desc,
                  TO_NUMBER(DM_UTILS.get_std_category(job_cur_rec.job_title,job_cur_rec.buyerorg_id,job_cur_rec.data_source_code,'ID')),
                  job_cur_rec.job_level_id,
                  job_cur_rec.job_level_desc,
                  TO_NUMBER(DM_UTILS.get_std_title(job_cur_rec.job_title,job_cur_rec.buyerorg_id,job_cur_rec.data_source_code,'ID')),
                  job_cur_rec.source_template_id,
                  job_cur_rec.source_of_record,
                  ln_version_id+1,
                  'Y',
                  ld_date,
                  null,
                  in_msg_id,
                  ld_date
               FROM DUAL;

        EXCEPTION
	   WHEN OTHERS THEN
	        lv_app_err_msg := 'Unable to insert into job dim for the latest version of Job records ! ';
	        lv_db_err_msg := SQLERRM;
                RAISE le_exception;
         END;
        END IF;
       END LOOP;

    END IF;


    --
    --Inserts for all new transactions
    --
    BEGIN
      INSERT
        INTO dm_job_dim
             (job_dim_id,
              job_id,
              buyerorg_id,
              data_source_code,
              top_buyerorg_id,
              job_category_id,
              job_title,
              std_buyerorg_id,
              job_state,
              job_last_modified_date,
              job_created_date,
              job_approved_date,
              job_desc,
              job_skills_text,
              rate_range_low,
              rate_range_high,
              rate_type,
              job_category_desc,
              std_job_category_id,
              job_level_id,
              job_level_desc,
              std_job_title_id,
              source_template_id,
              source_of_record,
              version_id,
              is_effective,
              valid_from_date,
              valid_to_date,
              batch_id,
              last_update_date
             )
     SELECT  dm_job_dim_seq.NEXTVAL,
             djt.job_id,
             djt.buyerorg_id,
             djt.data_source_code,
             djt.top_buyerorg_id,
             djt.job_category_id,
             djt.job_title,
             (SELECT bm.std_buyerorg_id FROM fo_buyers_map bm WHERE bm.buyerorg_id =djt.buyerorg_id and bm.data_source_code =djt.data_source_code),
             djt.job_state,
             djt.last_modified_date,
             djt.job_created_date,
             djt.job_approved_date,
             djt.job_desc,
             djt.job_skills_text,
             djt.rate_range_low,
             djt.rate_range_high,
             djt.rate_type,
             djt.job_category_desc,
             TO_NUMBER(DM_UTILS.get_std_category(djt.job_title,djt.buyerorg_id,djt.data_source_code,'ID')),
             djt.job_level_id,
             djt.job_level_desc,
             TO_NUMBER(DM_UTILS.get_std_title(djt.job_title,djt.buyerorg_id,djt.data_source_code,'ID')),
             djt.source_template_id,
             djt.source_of_record,
             1,
             'Y',
             djt.job_created_date,
             null,
             in_msg_id,
             ld_date
        FROM dm_job_dim_tmp djt
       WHERE NOT EXISTS
             (SELECT 'X'
                FROM dm_job_dim j
               WHERE j.job_id = djt.job_id
                AND j.data_source_code = djt.data_source_code);

        EXCEPTION
	   WHEN OTHERS THEN
	        lv_app_err_msg := 'Unable to insert into job dim for new Job records ! ';
	        lv_db_err_msg := SQLERRM;
                RAISE le_exception;
        END;

  EXCEPTION
    WHEN le_exception THEN
      --
      -- user defined exception, Log and raise the application error.
      --
      on_err_num := DM_UTIL_LOG.f_log_error(in_msg_id,
                                             lv_app_err_msg,
                                             lv_db_err_msg,
                                             lv_proc_name);

      ov_err_msg := lv_app_err_msg;
    WHEN OTHERS THEN
      --
      -- Unknown exception, Log and raise the application error.
      --
      Rollback;
      lv_app_err_msg := 'Unknown Error !';
      lv_db_err_msg  := SQLERRM;
      on_err_num     := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                 lv_app_err_msg,
                                                 lv_db_err_msg,
                                                 lv_proc_name);
      ov_err_msg     := lv_app_err_msg;
  END process_dm_job_dim;

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the job
  *       dimension data from Front office.
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                   ,p_date_id          IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
  IS
    ln_msg_id            NUMBER;
    ln_count             NUMBER;
    ln_process_cnt       NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(4000)  := NULL;
    gv_proc_name         VARCHAR2(100)   := 'dm_job_dim_process.p_main' ;
    gv_app_err_msg       VARCHAR2(2000)  := NULL;
    gv_db_err_msg        VARCHAR2(2000)  := NULL;
    ge_exception         EXCEPTION;
    ln_err               NUMBER;
    ld_last_process_date DATE;
    ln_last_processed_id NUMBER;
    lv_first_time_flag   VARCHAR2(1);
    ld_upd_date          DATE;
    ln_upd_id            NUMBER;

  BEGIN

 dm_cube_utils.make_indexes_visible;

     --
     -- Get the sequence reuired for logging messages
     --
     BEGIN
       SELECT DM_MSG_LOG_SEQ.nextval
         INTO ln_msg_id
         FROM dual;
     END;

     SELECT last_update_date,
            last_identifier
       INTO ld_last_process_date,
            ln_last_processed_id
       FROM dm_cube_objects
      WHERE object_name = 'DM_JOB_DIM'
      AND object_source_code =in_data_source_code;

     --
     -- truncate tables
     --
     BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_job_dim_tmp';
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to trunacte work tables for Job dims!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'dm_job_dim_process',gv_proc_name,'I'); -- log the start of main process

     --
     -- Step 1 : Run the FO process to gather the data related to JOB
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Process the FO to get Job Data',gv_proc_name,'I');
     BEGIN
       process_fo_job_dim(ln_msg_id,ln_last_processed_id,ld_last_process_date,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to gather the data related to Job from FO!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --
     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to gather the data related to Job from FO!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

     --
     -- Step 2 : Process the job data in Data mart side and load it into the dimension table
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Process the Job in data mart',gv_proc_name,'I');

     IF TRUNC(ld_last_process_date) = '01-JAN-1999' THEN
        lv_first_time_flag := 'Y';
     ELSE
        lv_first_time_flag := 'N';
     END IF;

     BEGIN
       process_dm_job_dim(ln_msg_id,lv_first_time_flag,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to process the Job in data mart!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --
     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to process the Job in data mart!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

     --
     -- Step 3: Update the cube objects for last process date
     --


     BEGIN
       SELECT last_processed_date,
              last_processed_id
         INTO ld_upd_date,
              ln_upd_id
         FROM fo_dm_process_job_info_tmp@FO_R;

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
            NULL;
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to select the remote table fo_dm_process_job_info_tmp residing in FO !';
            gv_db_err_msg := SQLERRM;
	    RAISE ge_exception;
     END;

     IF ld_upd_date IS NOT NULL THEN
        UPDATE dm_cube_objects
           SET last_update_date = ld_upd_date
         WHERE object_name      = 'DM_JOB_DIM'
         AND object_source_code =in_data_source_code;
     END IF;

     IF ln_upd_id IS NOT NULL THEN
        UPDATE dm_cube_objects
           SET last_identifier  = ln_upd_id
         WHERE object_name      = 'DM_JOB_DIM'
         AND object_source_code =in_data_source_code;
     END IF;

     Commit;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');
     
     DM_UTIL_LOG.p_log_cube_load_status('DM_JOB_DIM',
                                         in_data_source_code,
                                        'SPEND_CUBE-DIM',
                                        'COMPLETED',
                                         p_date_id);     

  EXCEPTION
      WHEN ge_exception THEN
           --
           -- user defined exception, Log and raise the application error.
           --
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_job_dim_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
            ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_app_err_msg,
                                               gv_db_err_msg,
                                               gv_proc_name);
                                               
          DM_UTIL_LOG.p_log_cube_load_status('DM_JOB_DIM',
                                             in_data_source_code,
                                             'SPEND_CUBE-DIM',
                                             'FAILED',
                                              p_date_id);                                                    


      WHEN OTHERS THEN
           --
           -- Unknown exception, Log and raise the application error.
           --
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_job_dim_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
           gv_app_err_msg := 'Unknown Error !';
           gv_db_err_msg  := SQLERRM;
           ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                        gv_app_err_msg,
                                                        gv_db_err_msg,
                                                        gv_proc_name);
                                                        
          DM_UTIL_LOG.p_log_cube_load_status('DM_JOB_DIM',
                                             in_data_source_code,
                                             'SPEND_CUBE-DIM',
                                             'FAILED',
                                              p_date_id);                                                                                                            
  END p_main;


END dm_job_dim_process;
/