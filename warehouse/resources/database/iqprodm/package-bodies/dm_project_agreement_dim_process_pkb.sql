CREATE OR REPLACE PACKAGE BODY dm_project_agreement_dim_prcs
/******************************************************************************
 * Name:   dm_project_agreement_dim_prcs
 * Desc:   This package contains all the procedures required to
 *         migrate/process the Project agreement Dimension
 * Source: Front office Tables (Project Agreement and Project Agreement Version)
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Manoj   07/12/2010    Initial
 * JoeP    02/01/2016    Hard-coded dblink 
 *******************************************************************************/
AS

 /*****************************************************************
  * Name: process_fo_pa_dim
  * Desc: This procedure calls a procedure residing in Front office
  *       to gather the data needed for PA dim into a work table in
  *       FO and later pulls the data into data mart work table
  *
  *****************************************************************/
  PROCEDURE process_fo_pa_dim(in_msg_id        IN number,
                              id_last_run_date IN DATE,
                              on_err_num      OUT number,
                              ov_err_msg      OUT varchar2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_project_agreement_dim_prcs.process_fo_pa_dim' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER;
    CURSOR c1
    IS
    SELECT pa_id,
           pa_contract_version,
           Count(1) cnt
      FROM dm_project_agreement_tmp
      GROUP BY pa_id,
               pa_contract_version
     HAVING count(1) > 1;
  BEGIN
     on_err_num := 0;
     ov_err_msg := NULL;
     --
     -- execute the procedure to get FO Project agreement DIM data (this is a remote procedure that resides in FO reporting)
     -- this procedure gets the data since the last run
     --
     BEGIN
       FO_DM_PA_DIM_PROCESS.p_main@FO_R(in_msg_id,id_last_run_date);
     EXCEPTION
       WHEN OTHERS THEN
            lv_app_err_msg := 'Unable to execute the procedure to get the Project Agreement Dim data from FO !';
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
             lv_app_err_msg := 'Errors occured in the procedure to get PA DIM data ! ';
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
      INSERT
        INTO dm_project_agreement_tmp
             (pa_id,
              pa_contract_version,
              data_source_code,
              pa_name,
              pa_desc,
              pa_event_effective_date,
              pa_approved_date,
              pa_start_date,
              pa_end_date,
              has_milestones,
              has_pr,
              has_rate_table_pr,
              has_ctw,
              has_time_exp,
              buyerorg_id,
              supplierorg_id,
              project_id,
              valid_from_date,
              valid_to_date,
              object_version_state,
              pav_last_modified_date,
              delete_flag
             )
      SELECT  pa_id,
              pa_contract_version,
              data_source_code,
              pa_name,
              pa_desc,
              pa_event_effective_date,
              pa_approved_date,
              pa_start_date,
              pa_end_date,
              has_milestones,
              has_pr,
              has_rate_table_pr,
              has_ctw,
              has_time_exp,
              buyerorg_id,
              supplierorg_id,
              project_id,
              valid_from_date,
              valid_to_date,
              object_version_state,
              pav_last_modified_date,
              'N'
         FROM fo_dm_project_agreement_tmp@FO_R;

         --
         --fix some duplicate contract version number coming from FO due to some FO bug
         --
         for c2 in c1
         loop
           UPDATE dm_project_agreement_tmp
              SET pa_contract_version =  pa_contract_version + rownum + 10
            WHERE pa_id               = c2.pa_id
              AND pa_contract_version = c2.pa_contract_version;
         end loop;

    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into temp table dm_project_agreement_tmp the data from FO! ';
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
  END process_fo_pa_dim;

 /*****************************************************************
  * Name: process_dm_pa_dim
  * Desc: This procedure pulls the data from temp table and
  *       performs the following tasks in data mart
  *       1. First time load all the data from temp table
  *       2. All loads after the initial load needs to check
  *          data existence. if the row exists update the is_effective
  *          to 'N' and make the new row 'Y'
  * Notes: Since we are taking only the effective PAs any change to the
  *        values will create a new version in FO. so no need to compare
  *        every column to see anything has changed.
  *****************************************************************/
  PROCEDURE process_dm_pa_dim(in_msg_id            IN number,
                              iv_first_time_flag   IN varchar2,
                              on_err_num          OUT number,
                              ov_err_msg          OUT varchar2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_project_agreement_dim_prcs.process_dm_pa_dim' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER;
    ln_version_id        number;
    CURSOR pa_cur
    IS
    SELECT  pa_id
      FROM dm_pa_cursor_tmp;

  BEGIN
    on_err_num := 0;
    ov_err_msg := NULL;

    INSERT
      INTO dm_pa_cursor_tmp
     SELECT distinct pa_id
       FROM dm_project_agreement_tmp;

    IF iv_first_time_flag = 'N' THEN
       --
       -- This section deals with loads after the initial one
       --

       --
       -- Loop through cursor forall the deltas ( from temp table)
       -- and check the existence of record. If found then update the old ones effective flag to 'N'
       --
       FOR pa_cur_rec IN pa_cur
       LOOP

         SELECT count(1)
           INTO ln_count
           FROM dm_project_agreement_dim
          WHERE pa_id = pa_cur_rec.pa_id;

        IF ln_count > 0 THEN
           BEGIN
             select max(version_id)
               INTO ln_version_id
               FROM dm_project_agreement_dim
              WHERE pa_id = pa_cur_rec.pa_id;

             --
             -- update to invalidate the record
             --
             UPDATE dm_project_agreement_dim
                SET is_effective  = 'N',
                    valid_to_date = (SELECT (valid_from_date  -(1/86400))
                                       FROM dm_project_agreement_tmp
                                      WHERE pa_id = pa_cur_rec.pa_id
                                        AND pa_contract_version = ( SELECT min(pa_contract_version)
                                                                      FROM dm_project_agreement_tmp
                                                                     WHERE pa_id = pa_cur_rec.pa_id
                                                                   )
                                    ),
                    last_update_date = SYSDATE
              WHERE pa_id        = pa_cur_rec.pa_id
                AND is_effective = 'Y';

             --
             -- insert the new records for the project agreements that were updated
             --
             INSERT
               INTO dm_project_agreement_dim
                   (pa_dim_id,
                    pa_id,
                    pa_contract_version,
                    data_source_code,
                    version_id,
                    pa_name,
                    pa_desc,
                    pa_event_effective_date,
                    pa_approved_date,
                    pa_start_date,
                    pa_end_date,
                    has_milestones,
                    has_pr,
                    has_rate_table_pr,
                    has_ctw,
                    has_time_exp,
                    buyerorg_id,
                    supplierorg_id,
                    project_id,
                    is_effective,
                    valid_from_date,
                    valid_to_date,
                    batch_id,
                    last_update_date
                   )
             SELECT dm_project_agreement_dim_seq.NEXTVAL,
                    pa_id,
                    pa_contract_version,
                    data_source_code,
                    ln_version_id +1,
                    pa_name,
                    pa_desc,
                    pa_event_effective_date,
                    pa_approved_date,
                    pa_start_date,
                    pa_end_date,
                    has_milestones,
                    has_pr,
                    has_rate_table_pr,
                    has_ctw,
                    has_time_exp,
                    buyerorg_id,
                    supplierorg_id,
                    project_id,
                    (CASE WHEN (last_value(pa_contract_version) OVER (PARTITION by pa_id
                                                                ORDER BY pa_contract_version
                                                                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) )= pa_contract_version then 'Y' else 'N' end) ,
                    valid_from_date,
                    valid_to_date,
                    in_msg_id,
                    SYSDATE
               FROM dm_project_agreement_tmp
              WHERE pa_id        = pa_cur_rec.pa_id;

              --
              -- make the record in temp table as processed ( set delete flag = y)
              --
              UPDATE dm_project_agreement_tmp
                 SET delete_flag = 'Y'
               WHERE pa_id        = pa_cur_rec.pa_id;

           EXCEPTION
             WHEN OTHERS THEN
              lv_app_err_msg := 'Unable to update dm_project_agreement_dim ! ';
              lv_db_err_msg := SQLERRM;
              RAISE le_exception;
           END;
        END IF;
       END LOOP;

    END IF;


    --
    --Inserts for all situations (initial load or one after that)
    --
    BEGIN
      INSERT
        INTO dm_project_agreement_dim
             (pa_dim_id,
              pa_id,
              pa_contract_version,
              data_source_code,
              version_id,
              pa_name,
              pa_desc,
              pa_event_effective_date,
              pa_approved_date,
              pa_start_date,
              pa_end_date,
              has_milestones,
              has_pr,
              has_rate_table_pr,
              has_ctw,
              has_time_exp,
              buyerorg_id,
              supplierorg_id,
              project_id,
              is_effective,
              valid_from_date,
              valid_to_date,
              batch_id,
              last_update_date
             )
      SELECT dm_project_agreement_dim_seq.NEXTVAL,
             pa_id,
             pa_contract_version,
             data_source_code,
             1,
             pa_name,
             pa_desc,
             pa_event_effective_date,
             pa_approved_date,
             pa_start_date,
             pa_end_date,
             has_milestones,
             has_pr,
             has_rate_table_pr,
             has_ctw,
             has_time_exp,
             buyerorg_id,
             supplierorg_id,
             project_id,
             (CASE WHEN (last_value(pa_contract_version) OVER (PARTITION by pa_id
                                                                ORDER BY pa_contract_version
                                                               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) )= pa_contract_version then 'Y' else 'N' end) ,
             valid_from_date,
             valid_to_date,
             in_msg_id,
             SYSDATE
        FROM dm_project_agreement_tmp
        WHERE DELETE_FLAG = 'N';

    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to load data into dm_project_agreement_dim ! ';
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
  END process_dm_pa_dim;

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the project agreement
  *       dimension data from Front office.
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                   ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
  IS
    ln_msg_id            NUMBER;
    ln_count             NUMBER;
    ln_process_cnt       NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(4000)  := NULL;
    gv_proc_name         VARCHAR2(100)   := 'dm_project_agreement_dim_prcs.p_main' ;
    gv_app_err_msg       VARCHAR2(2000)  := NULL;
    gv_db_err_msg        VARCHAR2(2000)  := NULL;
    ge_exception         EXCEPTION;
    ln_err               NUMBER;
    fo_ln_count          NUMBER;
    bo_ln_count          NUMBER;
    ld_last_process_date DATE;
    lv_first_time_flag   VARCHAR2(1);
    ld_pav_last_update_date DATE;

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

     SELECT last_update_date
       INTO ld_last_process_date
       FROM dm_cube_objects
      WHERE object_name = 'DM_PROJECT_AGREEMENT_DIM'
      AND object_source_code =in_data_source_code;

     --
     -- truncate tables
     --
     BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_project_agreement_tmp';
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_pa_cursor_tmp';
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to trunacte work tables for Project agreement dims!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'dm_project_agreement_dim_prcs',gv_proc_name,'I'); -- log the start of main process

     --
     -- Step 1 : Run the FO process to gather the data related to Project Agreement
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Process the FO to get Project Agreement Data',gv_proc_name,'I');
     BEGIN
       process_fo_pa_dim(ln_msg_id,ld_last_process_date,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to gather the data related to Project Agreement from FO!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --
     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to gather the data related to Project Agreement from FO!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

     --
     -- Step 2 : Process the project agreement data in Data mart side and load it into the dimension table
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Process the Project agreement in data mart',gv_proc_name,'I');

     IF TRUNC(ld_last_process_date) = '01-JAN-1999' THEN
        lv_first_time_flag := 'Y';
     ELSE
        lv_first_time_flag := 'N';
     END IF;

     BEGIN
       process_dm_pa_dim(ln_msg_id,lv_first_time_flag,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to process the Project agreement in data mart!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --
     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to process the Project agreement in data mart!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

     --
     -- Step 3: Update the cube objects for last process date
     --
     SELECT max(pav_last_modified_date)
      INTO ld_pav_last_update_date
      FROM dm_project_agreement_tmp;

    IF  ld_pav_last_update_date IS NOT NULL THEN
     UPDATE dm_cube_objects
        SET last_update_date =ld_pav_last_update_date
      WHERE object_name = 'DM_PROJECT_AGREEMENT_DIM'
      AND object_source_code =in_data_source_code;
     END IF;

     Commit;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');
     
    DM_UTIL_LOG.p_log_cube_load_status('DM_PROJECT_AGREEMENT_DIM',
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
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_project_agreement_dim_prcs-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
            ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_app_err_msg,
                                               gv_db_err_msg,
                                               gv_proc_name);
    DM_UTIL_LOG.p_log_cube_load_status('DM_PROJECT_AGREEMENT_DIM',
                                               in_data_source_code,
                                               'SPEND_CUBE-DIM',
                                               'FAILED',
                                               p_date_id);     
                                               


      WHEN OTHERS THEN
           --
           -- Unknown exception, Log and raise the application error.
           --
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_project_agreement_dim_prcs-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
           gv_app_err_msg := 'Unknown Error !';
           gv_db_err_msg  := SQLERRM;
           ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                        gv_app_err_msg,
                                                        gv_db_err_msg,
                                                        gv_proc_name);
    DM_UTIL_LOG.p_log_cube_load_status('DM_PROJECT_AGREEMENT_DIM',
                                               in_data_source_code,
                                               'SPEND_CUBE-DIM',
                                               'FAILED',
                                               p_date_id);     
                                                        
  END p_main;


END dm_project_agreement_dim_prcs;
/