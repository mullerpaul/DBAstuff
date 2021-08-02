CREATE OR REPLACE PACKAGE BODY dm_currency_conversion_data
/******************************************************************************
 * Name:   dm_currency_conversion_data
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Manoj                 Initial
 * Sajeev  12/06/2011    Added curr_conv_dim_id
 * Sajeev  02/10/2012    Extract Daily rate from BO instead of FO
 * Sajeev  03/09/2012    Added make_indexes_visible
 * JoeP    02/01/2016    Hard-coded dblink
 * JoeP    01/30/2018    Replaced source table gl_daily_rates@R12_LINK with bo_curr_conv_gl_daily_rates@FO_R.
                         Added new proc, populate_currency_dim, to pickup new FO currency codes.
 *******************************************************************************/
AS
  PROCEDURE populate_currency_dim IS
  
  BEGIN
  
    INSERT INTO dm_currency_dim (currency_dim_id, currency_code, currency_name, last_update_date)
      SELECT dm_currency_dim_seq.NEXTVAL,
             description,
             NULL,
             SYSDATE
        FROM currency_unit@FO_R
       WHERE description IN (SELECT description
                               FROM currency_unit@FO_R
                              MINUS
                             SELECT currency_code
                               FROM dm_currency_dim);

  END populate_currency_dim;
  
  PROCEDURE populate_rates
  IS
      ln_msg_id           NUMBER;
      gv_proc_name        VARCHAR2(100)   := 'DM_CURRENCY_CONVERSION_DATA.populate_rates' ;
      gv_app_err_msg      VARCHAR2(2000)  := NULL;
      gv_db_err_msg       VARCHAR2(2000)  := NULL;
      ge_exception        EXCEPTION;
      ln_err              NUMBER;
      email_sender        VARCHAR2(32) := 'mart_processing@beeline.com';
      email_recipients    VARCHAR2(64) := 'data_warehouse@beeline.com';
      email_subject       VARCHAR2(64) := 'DM Currency Conversion Data Errors!';
      c_crlf              VARCHAR2(2) := chr(13) || chr(10);
      ld_last_update_date DATE;
      ln_count            NUMBER;
  BEGIN

    dm_cube_utils.make_indexes_visible;
     
     --
     -- Get the sequence required for logging messages
     --
     BEGIN
       SELECT DM_MSG_LOG_SEQ.nextval
         INTO ln_msg_id
         FROM dual;
     END;
     
     SELECT max(fo_last_update_date)
       INTO ld_last_update_date
       FROM dm_currency_conversion_rates;
       
     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'DM_CURRENCY_CONVERSION_DATA',gv_proc_name,'I'); -- log the start of main process
     --
     --Call to refresh dm_currency_dim
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Truncate work tables',gv_proc_name,'I');
     BEGIN
       populate_currency_dim;
     EXCEPTION
     WHEN OTHERS THEN
       gv_app_err_msg := 'Failure during refresh of dm_currency_dim!';
       gv_db_err_msg  := SQLERRM;
       RAISE ge_exception;
     END;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');
     
     --
     -- Truncate the work tables
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Truncate work tables',gv_proc_name,'I');
     BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_curr_conversion_rates_tmp';
     EXCEPTION
     WHEN OTHERS THEN
       gv_app_err_msg := 'Unable to truncate the work table dm_curr_conversion_rates_tmp!';
       gv_db_err_msg  := SQLERRM;
       RAISE ge_exception;
     END;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');
     
     --
     -- Insert the currency conversion rate from FO tables into work tables in data mart
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,4,'Insert into work tables data from FO',gv_proc_name,'I');
     BEGIN

       INSERT INTO dm_curr_conversion_rates_tmp  
        SELECT UPPER(from_cu.description) from_currency_code,
               UPPER(to_cu.description)   to_currency_code ,
               conversion_date,
               from_cu_dim.currency_dim_id from_currency_dim_id,
               to_cu_dim.currency_dim_id to_currency_dim_id,
               to_number(to_char(conversion_date,'YYYYMMDD'))  conversion_date_id,  
               from_currency_fk,
               to_currency_fk,
               conversion_type,
               conversion_rate,
               gl.creation_date fo_creation_date,
               gl.last_update_date fo_last_update_date,
               sysdate last_update_date 
          FROM bo_curr_conv_gl_daily_rates@FO_R gl,                                                                
               currency_unit@FO_R               from_cu,
               currency_unit@FO_R               to_cu,
               dm_currency_dim from_cu_dim,
               dm_currency_dim to_cu_dim
         WHERE gl.from_currency_fk          = from_cu.value
           AND gl.to_currency_fk            = to_cu.value
           AND upper(from_cu.description)   = from_cu_dim.currency_code
           AND upper(to_cu.description)     = to_cu_dim.currency_code
           AND gl.last_update_date          > ld_last_update_date; 

     EXCEPTION
     WHEN OTHERS THEN
       gv_app_err_msg := 'Unable to insert into the work table dm_curr_conversion_rates_tmp!';
       gv_db_err_msg  := SQLERRM;
       RAISE ge_exception;
     END;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,4,null,null,'U');
     
     --
     -- Merge into the main currency conversion
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,5,'Merge the data into currency conversion table from work tables',gv_proc_name,'I');
     BEGIN
       MERGE 
        INTO dm_currency_conversion_rates     a
       USING dm_curr_conversion_rates_tmp     b
          ON (a.from_currency_code = b.from_currency_code AND
              a.to_currency_code   = b.to_currency_code  AND
              a.conversion_date    = b.conversion_date)
         WHEN MATCHED THEN
              UPDATE set a.from_currency_dim_id      = b.from_currency_dim_id ,
                         a.to_currency_dim_id        = b.to_currency_dim_id ,
                         a.conversion_date_id        = b.conversion_date_id,  
                         a.from_currency_fk          = b.from_currency_fk,
                         a.to_currency_fk            = b.to_currency_fk,  
                         a.conversion_type           = b.conversion_type,
                         a.conversion_rate           = b.conversion_rate,
                         a.fo_creation_date          = b.fo_creation_date,
                         a.fo_last_update_date       = b.fo_last_update_date,
                         a.last_update_date          = sysdate
         WHEN NOT MATCHED THEN
              INSERT (curr_conv_dim_id,
                      from_currency_code,
                      to_currency_code,
                      conversion_date,
                      from_currency_dim_id,
                      to_currency_dim_id,
                      conversion_date_id,
                      from_currency_fk,
                      to_currency_fk,
                      conversion_type,
                      conversion_rate,
                      fo_creation_date,
                      fo_last_update_date,
                      last_update_date
                     )
              VALUES (curr_conv_dim_seq.nextval,
                      b.from_currency_code,
                      b.to_currency_code,
                      b.conversion_date,
                      b.from_currency_dim_id,
                      b.to_currency_dim_id,
                      b.conversion_date_id,
                      b.from_currency_fk,
                      b.to_currency_fk,
                      b.conversion_type,
                      b.conversion_rate,
                      b.fo_creation_date,
                      b.fo_last_update_date,
                      sysdate
                     );
     EXCEPTION
     WHEN OTHERS THEN
       gv_app_err_msg := 'Unable to Merge into dm_currency_conversion_rates!';
       gv_db_err_msg  := SQLERRM;
       RAISE ge_exception;     
     END;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,5,null,null,'U');
     
     SELECT COUNT(1) into ln_count FROM dm_curr_conversion_rates_tmp;
     
     DM_UTIL_LOG.p_log_msg(ln_msg_id,6,to_char(ln_count)||' Records Processed!',gv_proc_name,'I');
     DM_UTIL_LOG.p_log_msg(ln_msg_id,6,null,null,'U');
     
     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');
     
     Commit;
     
  EXCEPTION
  WHEN ge_exception THEN
    Rollback;
    DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'DM Currency Conversion Data-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
    DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
    ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                 gv_app_err_msg,
                                                 gv_db_err_msg,
                                                 gv_proc_name);
    --dm_utils.send_email(email_sender, email_recipients, email_subject,  'Currency Conversion population failed in '||gv_proc_name || c_crlf || gv_app_err_msg || c_crlf || gv_db_err_msg || c_crlf);
    
  WHEN OTHERS THEN
    Rollback;
    DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'DM Currency Conversion Data-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
    DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
    gv_app_err_msg := 'Unknown Error !';
    gv_db_err_msg  := SQLERRM;
    ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                 gv_app_err_msg,
                                                 gv_db_err_msg,
                                                 gv_proc_name);
    --dm_utils.send_email(email_sender, email_recipients, email_subject,  'Currency Conversion population failed in '||gv_proc_name || c_crlf || gv_app_err_msg || c_crlf || gv_db_err_msg || c_crlf);
  
  END populate_rates;

END dm_currency_conversion_data;
/