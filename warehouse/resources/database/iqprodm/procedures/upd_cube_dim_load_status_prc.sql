CREATE OR REPLACE PROCEDURE upd_cube_dim_load_status(in_date_id IN NUMBER,iv_cube_object_type IN VARCHAR2)
AS
  ln_msg_id           NUMBER;
  ln_week_id          NUMBER       := TO_CHAR(SYSDATE,'YYYYMMWW');
  lv_status           VARCHAR2(30);
  email_sender        VARCHAR2(32) := 'mart_processing@iqnavigator.com';
  email_recipients    VARCHAR2(164) := 'data_warehouse@iqnavigator.com';
  email_subject       VARCHAR2(164) := 'Cube Processing Errors! ';
  c_crlf              VARCHAR2(2)  := chr(13) || chr(10);
  ln_count            NUMBER;
  ln_err              NUMBER;
BEGIN
  SELECT cube_job_log_seq.NEXTVAL
    INTO ln_msg_id
    FROM dual;

    SELECT COUNT(1)
      INTO ln_count
      FROM dm_cube_jobs_log
     WHERE date_id = in_date_id
       AND cube_object_type = iv_cube_object_type
       AND LOAD_STATUS = 'FAILED';

    IF ln_count= 0 THEN
       lv_status := 'COMPLETED';
    ELSE
       lv_status := 'FAILED';
    END IF;

   IF lv_status = 'FAILED' THEN
      dm_utils.send_email(email_sender, email_recipients, email_subject||user,  'Some Dimension load processing Failed!'        || c_crlf ||
                         'Please see the table dm_cube_jobs_log to get the names of dimensions that failed to load today' || c_crlf ||
                         'After fixing dimension loads, dm_cube_jobs_log load_status should be set to COMPLETED for the FACT to load the data'  || c_crlf);
   END IF;
EXCEPTION
  WHEN OTHERS THEN
    ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                      'Errors occured in the procedure to update the cube dim load status!',
                                      'Err:'||SQLERRM,
                                      'upd_cube_dim_load_status');
END upd_cube_dim_load_status;
/
