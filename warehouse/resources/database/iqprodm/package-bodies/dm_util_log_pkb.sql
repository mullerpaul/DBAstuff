CREATE OR REPLACE PACKAGE BODY dm_util_log
AS
/*******************************************************************
 * Author: Manoj
 * Date:  11/20/08
 * Desc: This package contains function to log errors and messages
 *       for data mart.
 *******************************************************************/

/*****************************************************
 * Function Name: f_log_error
 * Desc: This function is  used to log errors to the
 *       error tables
 *****************************************************/
 FUNCTION f_log_error(in_error_id             IN NUMBER,
                      iv_app_msg              IN VARCHAR2,
                      iv_db_msg               IN VARCHAR2,
                      iv_executing_object     IN VARCHAR2)
 RETURN NUMBER
 IS PRAGMA AUTONOMOUS_TRANSACTION;
    lvc_userid    VARCHAR2(50);
    ln_error_id   NUMBER;
    le_err_handle EXCEPTION;
    ln_err_nbr    NUMBER;
    lv_err_msg    VARCHAR2(2000);
 BEGIN

   ln_error_id := in_error_id;


    --
    -- get userid
    --
    lvc_userid := NVL(sys_context('USERENV','CLIENT_IDENTIFIER'),user);

    --
    -- Error logging
    --
    INSERT
      INTO dm_error_log
           (err_id,
           create_dt,
           executor,
           app_error_msg,
           db_error_msg,
           executing_object)
    VALUES (ln_error_id,
           sysdate,
           lvc_userid,
           iv_app_msg,
           iv_db_msg,
           iv_executing_object);
    Commit;

    RETURN ln_error_id;

 EXCEPTION
     WHEN le_err_handle THEN
       Rollback;
       RAISE_APPLICATION_ERROR(ln_err_nbr,lv_err_msg);
     WHEN OTHERS THEN
       Rollback;
       RAISE_APPLICATION_ERROR(-20001,SQLERRM);
 END f_log_error;

/*****************************************************
 * Proc Name: p_log_msg
 * Desc: This procedure is  used to log messages
 *****************************************************/
 PROCEDURE p_log_msg(in_msg_seq               IN NUMBER,
                     in_sub_seq               IN NUMBER,
                     iv_msg                   IN VARCHAR2,
                     iv_executing_object      IN VARCHAR2,
                     iv_action                IN VARCHAR2)
 IS PRAGMA AUTONOMOUS_TRANSACTION;
    lvc_userid       VARCHAR2(50);
    ln_err_nbr       NUMBER;
    lv_err_msg       VARCHAR2(2000);
    le_msg_exception EXCEPTION;
 BEGIN

    --
    -- get userid
    --
    lvc_userid := NVL(sys_context('USERENV','CLIENT_IDENTIFIER'),user);

    --
    -- Message logging
    --
    IF iv_action = 'I' THEN -- Insert
       BEGIN
         INSERT
           INTO dm_msg_log
                (msg_id,
                 sub_seq,
                 start_dt,
                 end_dt,
                 executor,
                 msg_log,
                 executing_object)
         VALUES (in_msg_seq,
                 in_sub_seq,
                 sysdate,
                 null,
                 lvc_userid,
                 iv_msg,
                 iv_executing_object);
       EXCEPTION
          WHEN OTHERS THEN
           ln_err_nbr := -20002;
           lv_err_msg := 'Insert into dm_msg_log Failed ! '||SQLERRM;
           RAISE le_msg_exception;
       END;
    ELSE
       --
       -- update
       --
       BEGIN
         UPDATE dm_msg_log
            SET end_dt  = sysdate
          WHERE msg_id  = in_msg_seq
            AND sub_seq = in_sub_seq;
       EXCEPTION
          WHEN OTHERS THEN
           ln_err_nbr := -20003;
           lv_err_msg := 'Update of dm_msg_log Failed ! '||SQLERRM;
           RAISE le_msg_exception;
       END;
    END IF;

    Commit;

 EXCEPTION
   WHEN le_msg_exception THEN
      Rollback;
      RAISE_APPLICATION_ERROR(ln_err_nbr,lv_err_msg);
   WHEN OTHERS THEN
      Rollback;
      RAISE_APPLICATION_ERROR(-20004,SQLERRM);
 END p_log_msg;

/********************************************************************
 * Proc Name: p_log_load_status
 * Desc: This procedure is  used to log the load status of DM objects
 ********************************************************************/
 PROCEDURE p_log_load_status(in_batch_id               IN NUMBER,
                             iv_object_name            IN VARCHAR2,
                             iv_object_source          IN VARCHAR2,
                             iv_load_status            IN VARCHAR2,
                             in_rows_processed         IN NUMBER,
                             iv_action                 IN VARCHAR2)
 IS PRAGMA AUTONOMOUS_TRANSACTION;
    lvc_userid       VARCHAR2(50);
    ln_err_nbr       NUMBER;
    lv_err_msg       VARCHAR2(2000);
    le_msg_exception EXCEPTION;
 BEGIN



    --
    -- Message logging
    --
    IF iv_action = 'I' THEN -- Insert
       BEGIN
         INSERT
           INTO dm_load_log
                (batch_id,
                 object_name,
                 object_source,
                 load_status,
                 load_start_date
                )
         VALUES (in_batch_id,
                 iv_object_name,
                 iv_object_source,
                 iv_load_status,
                 SYSDATE);
       EXCEPTION
          WHEN OTHERS THEN
           ln_err_nbr := -20005;
           lv_err_msg := 'Insert into dm_load_log Failed ! '||SQLERRM;
           RAISE le_msg_exception;
       END;
    ELSE
       --
       -- update
       --
       BEGIN
         UPDATE dm_load_log
            SET load_end_date  = sysdate,
                load_status    = iv_load_status,
                rows_processed = in_rows_processed
          WHERE batch_id      = in_batch_id
            AND object_name   = iv_object_name
            AND object_source = iv_object_source;
       EXCEPTION
          WHEN OTHERS THEN
           ln_err_nbr := -20006;
           lv_err_msg := 'Update of dm_msg_log Failed ! '||SQLERRM;
           RAISE le_msg_exception;
       END;
    END IF;

    Commit;

 EXCEPTION
   WHEN le_msg_exception THEN
      Rollback;
      RAISE_APPLICATION_ERROR(ln_err_nbr,lv_err_msg);
   WHEN OTHERS THEN
      Rollback;
      RAISE_APPLICATION_ERROR(-20007,SQLERRM);
 END p_log_load_status;

/********************************************************************
 * Proc Name: p_log_cube_load_status
 * Desc: This procedure is  used to log the load status of DM objects
 ********************************************************************/
 PROCEDURE p_log_cube_load_status(iv_cube_object_name  IN VARCHAR2,
                                  iv_data_source_code  IN VARCHAR2,
                                  iv_cube_object_type  IN VARCHAR2,                             
                                  iv_load_status       IN VARCHAR2,
                                  in_date_id           IN NUMBER)
 IS PRAGMA AUTONOMOUS_TRANSACTION;
    ln_cube_job_id   NUMBER;
    ln_err_nbr       NUMBER;
    lv_err_msg       VARCHAR2(2000);
    le_msg_exception EXCEPTION;
 BEGIN

  BEGIN 
    SELECT cube_job_id
      INTO ln_cube_job_id
      FROM dm_cube_jobs
     WHERE cube_object_name = iv_cube_object_name 
       AND data_source_code = iv_data_source_code;
  EXCEPTION
    WHEN OTHERS THEN
      ln_err_nbr := -20005;
      lv_err_msg := 'Unable to get Cube Job ID! '||SQLERRM;
      RAISE le_msg_exception;
  END;
  
   --
   -- Message logging
   --
   BEGIN
     INSERT
       INTO dm_cube_jobs_log
            (date_id,
             cube_job_id,
             cube_object_type,
             load_status,
             load_date
            )
     VALUES (in_date_id,
             ln_cube_job_id,
             iv_cube_object_type,
             iv_load_status,
             SYSDATE);
   EXCEPTION
       WHEN OTHERS THEN
           ln_err_nbr := -20006;
           lv_err_msg := 'Insert into dm_cube_jobs_log Failed ! '||SQLERRM;
           RAISE le_msg_exception;
   END;
   
   Commit;

 EXCEPTION
   WHEN le_msg_exception THEN
      Rollback;
      RAISE_APPLICATION_ERROR(ln_err_nbr,lv_err_msg);
   WHEN OTHERS THEN
      Rollback;
      RAISE_APPLICATION_ERROR(-20007,SQLERRM);
 END p_log_cube_load_status;
 
END dm_util_log;
/