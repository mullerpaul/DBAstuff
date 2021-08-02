CREATE OR REPLACE PACKAGE BODY dm_populate_spend_summary
/********************************************************************
 * Name: dm_populate_spend_summary
 * Desc: This package contains all the procedures required to
 *       populate the spend summary
 *
 *
 * Author  Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   10/13/09    Initial
 * Sajeev  11/3/2011   Removed nologging
 * JoeP    02/01/2016  Hard-coded dblink 
 ********************************************************************/
AS

/**************************************************************
  * Name: p_remove_canceled_invoices
  * Desc: This proccedure removes the canceled invoices (
  **************************************************************/
  PROCEDURE p_remove_canceled_invoices(in_msg_id   IN  NUMBER,
                                       on_err_num  OUT NUMBER,
                                      ov_err_msg  OUT VARCHAR2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_populate_spend_summary.p_remove_canceled_invoices' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    
    CURSOR inv_cur
    IS
    SELECT invoice_number
      FROM dm_bo_canceled_invoices
     WHERE process_date IS NULL;   
  BEGIN
    BEGIN
     FOR inv_cur_rec IN inv_cur
     LOOP
         DELETE dm_spend_summary WHERE invoice_number = inv_cur_rec.invoice_number and object_source = 'BOI';
     END LOOP;
     UPDATE dm_bo_canceled_invoices SET process_date = SYSDATE WHERE process_date IS NULL;
     COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
           lv_app_err_msg := 'Unable to delete dm_spend_summary ! ';
           lv_db_err_msg := SQLERRM;
           RAISE le_exception;
    END;
  EXCEPTION
    WHEN le_exception THEN
      --
      -- user defined exception, Log and raise the application error.
      --
      Rollback;
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
  END p_remove_canceled_invoices;
  
 /**************************************************************
  * Name: p_create_summary
  * Desc: This proccedure populates the spend summary table
  *       from invoiced spend table.
  **************************************************************/
  PROCEDURE p_create_summary(in_msg_id   IN  NUMBER,
                             on_err_num  OUT NUMBER,
                             ov_err_msg  OUT VARCHAR2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_populate_spend_summary.p_create_summary' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_last_batch_id     NUMBER;
    TYPE dm_batch_tab    IS TABLE OF dm_invoiced_spend_all.batch_id%TYPE;
    dm_batch_id_tab      dm_batch_tab;
    TYPE dm_inv_tab      IS TABLE OF dm_invoiced_spend_all.invoice_number%TYPE;
    dm_inv_number_tab    dm_inv_tab ;
    ld_date              DATE                   := SYSDATE;
    ln_no                NUMBER                 := 1;

    CURSOR batch_cur
    IS
    SELECT DISTINCT
           batch_id
      FROM dm_invoiced_batches
     WHERE process_date IS NULL;

    CURSOR inv_cur(in_batch_id IN NUMBER)
    IS
    SELECT DISTINCT
           invoice_number,
           object_source
      FROM dm_invoiced_spend_all
     WHERE batch_id        = in_batch_id
       AND invoice_number >= '01-JAN-2008';

  BEGIN



        --
        -- Loop through the batches
        --
        FOR batch_cur_rec IN batch_cur
        LOOP

          --
          -- Loop all the invoice numbers in the batch and populate the summary table
          --
          ln_commit := 0;
          FOR inv_cur_rec IN inv_cur(batch_cur_rec.batch_id)
          LOOP
           ln_commit := ln_commit +1;
           ln_no     := ln_no     +1;

           DM_UTIL_LOG.p_log_msg(in_msg_id,ln_no,'Processing Batch: '||to_char(batch_cur_rec.batch_id)||' Invoice: '||inv_cur_rec.invoice_number||'-'||inv_cur_rec.object_source,'dm_populate_spend_summary.p_create_summary','I');

           BEGIN
            INSERT
              INTO dm_spend_summary  
                   (buyer_bus_org_fk,
                supplier_bus_org_fk,
                week_number,
                spend_category,
                spend_type,
                job_title,
                job_category,
                invoice_number,
                object_source,
                buyer_bus_org_name,
                supplier_bus_org_name,
                top_buyer_bus_org_fk,
                top_buyer_bus_org_name,
                top_supplier_bus_org_fk,
                top_supplier_bus_org_name,
                month_number,
                qtr_number,
                year,
                std_job_title,
                std_job_category,
                buyer_adjusted_amount,
                supplier_reimbursement_amount,
                quantity,
                batch_id,
                currency,
                last_update_date)
             SELECT nvl(buyer_bus_org_fk,0),
                nvl(supplier_bus_org_fk,0),
                TO_NUMBER(TO_CHAR(invoice_date,'YYYYWW')),
                CASE 
                WHEN nvl(spend_category,'N/A') IN ('Bonus','Placement Costs','Services') THEN
                  'Payment Requests'
                WHEN nvl(spend_category,'N/A') IN ('Labor','Labor Adjustments') THEN
                  'Time'
                WHEN nvl(spend_category,'N/A') IN ('Travel '||chr(38)||' Entertainment') THEN
                  'Expense'
                WHEN nvl(spend_category,'N/A') IN ('VAT') THEN
                  'Tax and Discounts'
                ELSE
                  nvl(spend_category,'N/A')
                END  ,
            nvl(spend_type,'N/A'),
            nvl(job_title,'N/A'),
                nvl(job_category,'N/A'),
                invoice_number,
                object_source,
            buyer_bus_org_name,
                supplier_bus_org_name,
                rpt_util_executive.get_parent_bus_org_id@FO_R(buyer_bus_org_fk),
                rpt_util_executive.get_parent_bus_org_name@FO_R(buyer_bus_org_fk),
                rpt_util_executive.get_parent_bus_org_id@FO_R(supplier_bus_org_fk),
                rpt_util_executive.get_parent_bus_org_name@FO_R(supplier_bus_org_fk),
                TO_NUMBER(TO_CHAR(invoice_date,'YYYYMM')),
                TO_NUMBER(TO_CHAR(invoice_date,'YYYYQ')),
                TO_NUMBER(TO_CHAR(invoice_date,'YYYY')),
                dm_utils.get_std_title(nvl(job_title,'N/A'),buyer_bus_org_fk),
                dm_utils.get_std_category(nvl(job_title,'N/A'),buyer_bus_org_fk),
                SUM(buyer_adjusted_amount),
                SUM(supplier_reimbursement_amount),
                SUM(quantity),
                batch_cur_rec.batch_id,
                currency,
                ld_date
           FROM dm_invoiced_spend_all
          WHERE batch_id       = batch_cur_rec.batch_id
            AND invoice_number = inv_cur_rec.invoice_number
            AND object_source  = inv_cur_rec.object_source
            AND invoice_date  >= '01-JAN-2008'
          GROUP
             BY nvl(buyer_bus_org_fk,0),
                nvl(supplier_bus_org_fk,0),
                TO_NUMBER(TO_CHAR(invoice_date,'YYYYWW')),
                CASE 
                WHEN nvl(spend_category,'N/A') IN ('Bonus','Placement Costs','Services') THEN
                  'Payment Requests'
                WHEN nvl(spend_category,'N/A') IN ('Labor','Labor Adjustments') THEN
                  'Time'
                WHEN nvl(spend_category,'N/A') IN ('Travel '||chr(38)||' Entertainment') THEN
                  'Expense'
                WHEN nvl(spend_category,'N/A') IN ('VAT') THEN
                  'Tax and Discounts'
                ELSE
                  nvl(spend_category,'N/A')
                END ,
            nvl(spend_type,'N/A'),
            nvl(job_title,'N/A'),
                nvl(job_category,'N/A'),
                invoice_number,
                object_source,
            buyer_bus_org_name,
                supplier_bus_org_name,
                rpt_util_executive.get_parent_bus_org_id@FO_R(buyer_bus_org_fk),
                rpt_util_executive.get_parent_bus_org_name@FO_R(buyer_bus_org_fk),
                rpt_util_executive.get_parent_bus_org_id@FO_R(supplier_bus_org_fk),
                rpt_util_executive.get_parent_bus_org_name@FO_R(supplier_bus_org_fk),
                TO_NUMBER(TO_CHAR(invoice_date,'YYYYMM')),
                TO_NUMBER(TO_CHAR(invoice_date,'YYYYQ')),
                TO_NUMBER(TO_CHAR(invoice_date,'YYYY')),
                dm_utils.get_std_title(nvl(job_title,'N/A'),buyer_bus_org_fk),
                dm_utils.get_std_category(nvl(job_title,'N/A'),buyer_bus_org_fk),
                batch_cur_rec.batch_id,
                currency,
                ld_date;

          IF ln_commit = 100 THEN
             Commit;
             ln_commit := 0;
          END IF;

          DM_UTIL_LOG.p_log_msg(in_msg_id,ln_no,null,null,'U');

           EXCEPTION
              WHEN OTHERS THEN
                lv_app_err_msg := 'Unable to insert into dm_spend_summary ! ';
                lv_db_err_msg := SQLERRM;
                RAISE le_exception;
       END;
      END LOOP; -- End invoice numbers

      --
      -- Update the processed batches
      --
      UPDATE dm_invoiced_batches
         SET process_date = SYSDATE
       WHERE batch_id = batch_cur_rec.batch_id;
        END LOOP;   -- Endbatch



        Commit;

  EXCEPTION
    WHEN le_exception THEN
      --
      -- user defined exception, Log and raise the application error.
      --
      Rollback;
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
  END p_create_summary;

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the FO and BO invoiced data
  *       to the data mart temp tables
  ****************************************************************/
  PROCEDURE p_main
  IS
    ln_msg_id           NUMBER;
    ln_count            NUMBER;
    ln_process_cnt      NUMBER;
    ln_err_num          NUMBER;
    ln_err              NUMBER;
    lv_err_msg          VARCHAR2(4000)  := NULL;
    gv_proc_name        VARCHAR2(100)   := 'DM_POPULATE_SPEND_SUMMARY.p_main' ;
    gv_app_err_msg      VARCHAR2(2000)  := NULL;
    gv_db_err_msg       VARCHAR2(2000)  := NULL;
    ge_exception        EXCEPTION;

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

     --
     -- Check the previous job still running
     --
 /*    BEGIN
       SELECT count(*)
         INTO ln_count
         FROM user_jobs dj,
              dba_jobs_running djr
        WHERE dj.job      = djr.job
          AND dj.LOG_USER = USER
          AND dj.WHAT     = 'DM_POPULATE_SPEND_SUMMARY.p_main';
     EXCEPTION
       WHEN OTHERS THEN
         --
         -- for any errors
         --
         DM_UTIL_LOG.p_log_msg(ln_msg_id,0,'DM_POPULATE_SPEND_SUMMARY-ERROR IN GETTING RUNNING JOB STATUS','DM_POPULATE_SPEND_SUMMARY.p_main','I');
         DM_UTIL_LOG.p_log_msg(ln_msg_id,0,null,null,'U');
     END; */

         ln_count := dm_cube_utils.get_job_status('DM_POPULATE_SPEND_SUMMARY.p_main;');



     IF ln_count > 1 THEN
         --
         -- previous job still running log and exit
         --
         DM_UTIL_LOG.p_log_msg(ln_msg_id,0,'DM_POPULATE_SPEND_SUMMARY-PREVIOUS JOB RUNNING','DM_POPULATE_SPEND_SUMMARY.p_main','I');
         DM_UTIL_LOG.p_log_msg(ln_msg_id,0,null,null,'U');

     ELSE

            DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'DM_POPULATE_SPEND_SUMMARY',gv_proc_name,'I'); -- log the start of main process
            DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_POPULATE_SPEND_SUMMARY','ALL',NULL,ln_process_cnt,'I');
            
            --
            -- procedure to populate the spend summary
            --
            BEGIN
              p_create_summary(ln_msg_id,ln_err_num,lv_err_msg);
            EXCEPTION
              WHEN OTHERS THEN
                gv_app_err_msg := 'Unable to execute the procedure to Create the Spend summary!';
                gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
            END;

            --
            --  check for any errors returned after executing the procedure
            --
            IF ln_err_num > 0 THEN
               gv_app_err_msg := 'Errors occured in the procedure to get Create the Spend Summary!';
               gv_db_err_msg  := lv_err_msg||' '||SQLERRM;
           RAISE ge_exception;
            END IF;

            --
            -- once populated call the procedure to delete the BO canceled invoices
            --
            BEGIN
              p_remove_canceled_invoices(ln_msg_id,ln_err_num,lv_err_msg);
            EXCEPTION
              WHEN OTHERS THEN
                gv_app_err_msg := 'Unable to execute the procedure to remove the canceled invoices from spend summary!';
                gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
            END;

            --
            --  check for any errors returned after executing the procedure
            --
            IF ln_err_num > 0 THEN
               gv_app_err_msg := 'Errors occured in the procedure to remove the canceled invoices from spend summary!';
               gv_db_err_msg  := lv_err_msg||' '||SQLERRM;
           RAISE ge_exception;
            END IF;
            
            Commit;

            DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');-- End of main process

            --
            -- Log the final load status for FO
            --
            DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_POPULATE_SPEND_SUMMARY','ALL','COMPLETE',ln_process_cnt,'U');

     END IF;
  EXCEPTION
    WHEN ge_exception THEN
       --
       -- user defined exception, Log and raise the application error.
       --
       Rollback;
       DM_UTIL_LOG.p_log_msg(ln_msg_id,0,'DM_POPULATE_SPEND_SUMMARY-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
       DM_UTIL_LOG.p_log_msg(ln_msg_id,0,null,null,'U');
       ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                          gv_app_err_msg,
                                          gv_db_err_msg,
                                          gv_proc_name);
       --
       -- Log the final load status for FO
       --
       DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_POPULATE_SPEND_SUMMARY','ALL','FAILED',ln_process_cnt,'U');

    WHEN OTHERS THEN
       --
       -- Unknown exception, Log and raise the application error.
       --
       Rollback;
       DM_UTIL_LOG.p_log_msg(ln_msg_id,0,'DM_POPULATE_SPEND_SUMMARY-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
       DM_UTIL_LOG.p_log_msg(ln_msg_id,0,null,null,'U');
       gv_app_err_msg := 'Unknown Error !';
       gv_db_err_msg  := SQLERRM;
       ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                    gv_app_err_msg,
                                                    gv_db_err_msg,
                                                    gv_proc_name);
       --
       -- Log the final load status for FO
       --
       DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_POPULATE_SPEND_SUMMARY','ALL','FAILED',ln_process_cnt,'U');

  END p_main;


END dm_populate_spend_summary;
/