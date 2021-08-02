CREATE OR REPLACE PACKAGE BODY dm_invoiced_spend
/********************************************************************
 * Name: dm_invoiced_spend
 * Desc: This package contains all the procedures required to
 *       migrate/process FO and BO invoiced data to be used in
 *       Invoiced spend Data mart
 *
 * Author  Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   11/20/08    Initial
 * JoeP    02/01/2016  Hard-coded dblink
 ********************************************************************/
AS

 /**************************************************************
  * Name: p_get_fo_invoiced_data
  * Desc: This proccedure is used to gather all the FO invoiced
  *       information required for the data mart temp tables
  **************************************************************/
  PROCEDURE p_get_fo_invoiced_data(in_msg_id   IN NUMBER,
                                   on_err_num OUT NUMBER,
                                   ov_err_msg OUT VARCHAR2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_invoiced_spend.p_get_fo_invoiced_data' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
  BEGIN
    BEGIN

        --
        -- execute the procedure to get FO invoiced data -- this is a remote procedure that resides in FO reporting.
        --
        BEGIN
          FO_DM_INVOICED_SPEND.p_main@FO_R(in_msg_id);
        EXCEPTION
          WHEN OTHERS THEN
            lv_app_err_msg := 'Unable to execute the procedure to get the FO Invoiced data !';
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
               lv_app_err_msg := 'Errors occured in the procedure to get FOI ! ';
	       lv_db_err_msg := lv_err_msg||' '||SQLERRM;
	       RAISE le_exception;
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               lv_err_msg := NULL;
        END;


      INSERT
        INTO dm_invoiced_spend_all 
             (buyer_bus_org_fk,
	      buyer_bus_org_name,
	      supplier_bus_org_fk,
	      supplier_bus_org_name,
	      invoice_number,
	      invoice_number_supplier,
              invoice_date,
              invoice_due_date,
              expenditure_number,
              transaction_type,
              expenditure_date,
              week_ending_date,
              work_order_id,
              work_order_type,
              customer_supplier_internal_id,
              accounting_code,
              buyer_resource_id,
              buyer_fee,
              supplier_fee,
              total_fee,
              cac1_seg1_value,
              cac1_seg2_value,
              cac1_seg3_value,
              cac1_seg4_value,
              cac1_seg5_value,
              cac2_seg1_value,
              cac2_seg2_value,
              cac2_seg3_value,
              cac2_seg4_value,
              cac2_seg5_value,
              curr_contractor_full_name,
              contractor_person_id,
              currency,
              hm_full_name,
              hm_person_id,
              spend_category,
              spend_type,
              buyer_adjusted_amount,
              supplier_reimbursement_amount,
              quantity,
              base_bill_rate,
              buyer_adjusted_bill_rate,
              base_pay_rate,
              supplier_reimbursement_rate,
              markup_pct,
              job_title,
              supplier_reference_num,
              assignment_start_date,
              assignment_end_date,
              expenditure_approved_date,
              expenditure_approver,
              expenditure_approver_pid,
              job_id,
              job_category,
              job_level,
              supplier_resource_id,
              batch_id,
              object_source,
              last_update_date,
              project_agreement_id,
              project_agreement_name,
              supp_invoice_number,
              supp_invoice_date,
              tax_type,
              invoice_creation_date,
              sow_spend_category,
              sow_spend_type)
       SELECT buyer_bus_org_fk,
	      buyer_bus_org_name,
	      supplier_bus_org_fk,
	      supplier_bus_org_name,
	      invoice_number,
	      invoice_number_supplier,
              invoice_date,
              invoice_due_date,
              expenditure_number,
              transaction_type,
              expenditure_date,
              week_ending_date,
              work_order_id,
              work_order_type,
              customer_supplier_internal_id,
              accounting_code,
              buyer_resource_id,
              buyer_fee,
              supplier_fee,
              total_fee,
              cac1_seg1_value,
              cac1_seg2_value,
              cac1_seg3_value,
              cac1_seg4_value,
              cac1_seg5_value,
              cac2_seg1_value,
              cac2_seg2_value,
              cac2_seg3_value,
              cac2_seg4_value,
              cac2_seg5_value,
              curr_contractor_full_name,
              contractor_person_id,
              currency,
              hm_full_name,
              hm_person_id,
              spend_category,
              spend_type,
              buyer_adjusted_amount,
              supplier_reimbursement_amount,
              quantity,
              base_bill_rate,
              buyer_adjusted_bill_rate,
              base_pay_rate,
              supplier_reimbursement_rate,
              markup_pct,
              job_title,
              supplier_reference_num,
              assignment_start_date,
              assignment_end_date,
              expenditure_approved_date,
              expenditure_approver,
              expenditure_approver_pid,
              job_id,
              job_category,
              job_level,
              supplier_resource_id,
              in_msg_id,
              'FOI',
              SYSDATE,
              project_agreement_id,
              project_agreement_name,
              supp_invoice_number,
              supp_invoice_date,
              tax_type,
              invoice_creation_date,
              sow_spend_category,
              sow_spend_type
         FROM fo_dm_inv_details_final_tmp@FO_R;
    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into dm_invoiced_spend_all ! ';
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
  END p_get_fo_invoiced_data;


 /**************************************************************
  * Name: p_get_bo_invoiced_data
  * Desc: This proccedure is used to gather all the BO invoiced
  *       information required for the data mart temp tables
  **************************************************************/
  PROCEDURE p_get_bo_invoiced_data(in_msg_id   IN NUMBER,
                                   on_err_num OUT NUMBER,
                                   ov_err_msg OUT VARCHAR2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_invoiced_spend.p_get_bo_invoiced_data' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    min_id               NUMBER;
    max_id               NUMBER;
    offset               NUMBER;
    TYPE inv_dm_tab IS TABLE OF dm_invoiced_spend_all%ROWTYPE;
    inv_tab  inv_dm_tab;

    ln_cnt               NUMBER;

  BEGIN
    BEGIN

        --
        -- execute the procedure to get BO invoiced data -- this is a remote procedure that resides in FO reporting.
        --
        BEGIN
          fo_bo_dm_invoiced_spend.p_main@FO_R(in_msg_id);          
        EXCEPTION
          WHEN OTHERS THEN
            lv_app_err_msg := 'Unable to execute the procedure to get the BO Invoiced data !';
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
               lv_app_err_msg := 'Errors occured in the procedure to get BOI ! ';
	       lv_db_err_msg := lv_err_msg||' '||SQLERRM;
	       RAISE le_exception;
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               lv_err_msg := NULL;
        END;

      INSERT
        INTO dm_invoiced_spend_all 
             (buyer_bus_org_fk,
	      buyer_bus_org_name,
	      supplier_bus_org_fk,
	      supplier_bus_org_name,
	      invoice_number,
	      invoice_number_supplier,
              invoice_date,
              invoice_due_date,
              expenditure_number,
              transaction_type,
              expenditure_date,
              week_ending_date,
              work_order_id,
              work_order_type,
              customer_supplier_internal_id,
              accounting_code,
              buyer_resource_id,
              buyer_fee,
              supplier_fee,
              total_fee,
              cac1_seg1_value,
              cac1_seg2_value,
              cac1_seg3_value,
              cac1_seg4_value,
              cac1_seg5_value,
              cac2_seg1_value,
              cac2_seg2_value,
              cac2_seg3_value,
              cac2_seg4_value,
              cac2_seg5_value,
              curr_contractor_full_name,
              contractor_person_id,
              currency,
              hm_full_name,
              hm_person_id,
              spend_category,
              spend_type,
              buyer_adjusted_amount,
              supplier_reimbursement_amount,
              quantity,
              base_bill_rate,
              buyer_adjusted_bill_rate,
              base_pay_rate,
              supplier_reimbursement_rate,
              markup_pct,
              job_title,
              supplier_reference_num,
              assignment_start_date,
              assignment_end_date,
              expenditure_approved_date,
              expenditure_approver,
              expenditure_approver_pid,
              job_id,
              job_category,
              job_level,
              supplier_resource_id,
              batch_id,
              object_source,
              last_update_date,
              project_agreement_id,
              project_agreement_name,
              supp_invoice_number,
              supp_invoice_date,
              tax_type,
              invoice_creation_date,
              sow_spend_category,
              sow_spend_type)
       SELECT buyer_bus_org_fk,
	      buyer_bus_org_name,
	      supplier_bus_org_fk,
	      supplier_bus_org_name,
	      invoice_number,
	      invoice_number_supplier,
              invoice_date,
              invoice_due_date,
              expenditure_number,
              transaction_type,
              expenditure_date,
              week_ending_date,
              work_order_id,
              work_order_type,
              customer_supplier_internal_id,
              accounting_code,
              buyer_resource_id,
              buyer_fee,
              supplier_fee,
              total_fee,
              cac1_seg1_value,
              cac1_seg2_value,
              cac1_seg3_value,
              cac1_seg4_value,
              cac1_seg5_value,
              cac2_seg1_value,
              cac2_seg2_value,
              cac2_seg3_value,
              cac2_seg4_value,
              cac2_seg5_value,
              curr_contractor_full_name,
              contractor_person_id,
              currency,
              hm_full_name,
              hm_person_id,
              spend_category,
              spend_type,
              buyer_adjusted_amount,
              supplier_reimbursement_amount,
              quantity,
              base_bill_rate,
              buyer_adjusted_bill_rate,
              base_pay_rate,
              supplier_reimbursement_rate,
              markup_pct,
              job_title,
              supplier_reference_num,
              assignment_start_date,
              assignment_end_date,
              expenditure_approved_date,
              expenditure_approver,
              expenditure_approver_pid,
              job_id,
              job_category,
              job_level,
              supplier_resource_id,
              in_msg_id,
              'BOI',
              SYSDATE,
              project_agreement_id,
              project_agreement_name,
              supp_invoice_number,
              supp_invoice_date,
              tax_type,
              invoice_creation_date,
              sow_spend_category,
              sow_spend_type              
         FROM fo_bo_dm_invoiced_spend_all@FO_R;
    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into dm_invoiced_spend_all for BO data! ';
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
  END p_get_bo_invoiced_data;

/**************************************************************
  * Name: p_bo_deletes
  * Desc: This proccedure is used to delete the cancelled invoices
  *       in back office from the data mart tables
  **************************************************************/
  PROCEDURE p_bo_deletes(in_msg_id   IN NUMBER,
                                   on_err_num OUT NUMBER,
                                   ov_err_msg OUT VARCHAR2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_invoiced_spend.p_bo_deletes' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    TYPE del_dm_tab IS TABLE OF VARCHAR2(20);
    del_tab  del_dm_tab;

  BEGIN
    
      --
      -- This data is coming from the execution of p_get_bo_invoiced_data procedure
      -- 
      BEGIN

      SELECT distinct invoice_number
       BULK COLLECT INTO del_tab
       FROM FO_BO_DM_CANCELED_INVOICES@FO_R;

        FORALL i in del_tab.first .. del_tab.last
          DELETE dm_invoiced_spend_all where invoice_number = del_tab(i) and object_source = 'BOI';


        INSERT INTO dm_bo_canceled_invoices(invoice_number,load_date)
        SELECT distinct invoice_number,SYSDATE
           FROM FO_BO_DM_CANCELED_INVOICES@FO_R;
      EXCEPTION
        WHEN OTHERS THEN
          lv_app_err_msg := 'Unable to execute the procedure to delete the canceled invoices from data mart!';
          lv_db_err_msg := SQLERRM;
          RAISE le_exception;
      END;
      COMMIT;     
    
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
  END p_bo_deletes;


 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the FO and BO invoiced data
  *       to the data mart temp tables
  ****************************************************************/
  PROCEDURE p_main(iv_section IN VARCHAR2 DEFAULT 'BOTH')
  IS
    ln_msg_id           NUMBER;
    ln_count            NUMBER;
    ln_process_cnt      NUMBER;
    ln_err_num          NUMBER;
    lv_err_msg          VARCHAR2(4000)  := NULL;
    gv_fo_proc_name     VARCHAR2(100)   := 'DM_INVOICED_SPEND.p_main(FOI)' ;
    gv_fo_app_err_msg   VARCHAR2(2000)  := NULL;
    gv_fo_db_err_msg    VARCHAR2(2000)  := NULL;
    ge_fo_exception     EXCEPTION;
    gv_bo_proc_name     VARCHAR2(100)   := 'DM_INVOICED_SPEND.p_main(BOI)' ;
    gv_bo_app_err_msg   VARCHAR2(2000)  := NULL;
    gv_bo_db_err_msg    VARCHAR2(2000)  := NULL;
    ge_bo_exception     EXCEPTION;
    ln_err              NUMBER;
    fo_ln_count         NUMBER;
    bo_ln_count         NUMBER;
    email_sender        VARCHAR2(32) := 'mart_processing@iqnavigator.com';
    email_recipients    VARCHAR2(64) := 'data_warehouse@iqnavigator.com';
    email_subject       VARCHAR2(64) := 'Invoiced Spend Errors!';
    c_crlf          VARCHAR2(2) := chr(13) || chr(10);

  BEGIN
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
     ln_count := dm_cube_utils.get_job_status('DM_INVOICED_SPEND.p_main;');

     IF ln_count > 1 THEN
         --
         -- previous job still running log and exit
         --
         DM_UTIL_LOG.p_log_msg(ln_msg_id,0,'DM_INVOICED_SPEND-PREVIOUS JOB RUNNING','DM_INVOICED_SPEND.p_main','I');
         DM_UTIL_LOG.p_log_msg(ln_msg_id,0,null,null,'U');

     ELSE

        DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'DM_INVOICED_SPEND',gv_fo_proc_name,'I'); -- log the start of main process

        --
        -- BEGIN FO processing
        --
        IF iv_section IN ('BOTH','FOI') THEN

          BEGIN  -- section FOI
            --
            --Log initial load status
            --
            DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_INVOICED_SPEND_ALL','FOI','STARTED',NULL,'I');

            --
            -- Call the procedure to get the FO invoiced data.
            --
            DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'FO Invoice Migration Process',gv_fo_proc_name,'I');
            BEGIN
              p_get_fo_invoiced_data(ln_msg_id,ln_err_num,lv_err_msg);
            EXCEPTION
              WHEN OTHERS THEN
                gv_fo_app_err_msg := 'Unable to execute the procedure to get FO invoiced data!';
                gv_fo_db_err_msg := SQLERRM;
	        RAISE ge_fo_exception;
            END;

            --
            --  check for any errors returned after executing the procedure
            --
            IF ln_err_num > 0 THEN
               gv_fo_app_err_msg := 'Errors occured in the procedure to get FO invoiced data!';
               gv_fo_db_err_msg := lv_err_msg||' '||SQLERRM;
	       RAISE ge_fo_exception;
            END IF;

            DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

            --
            --call the procedure to update the migrate status of FOI -- this is a remote procedure residing in FO reporting
            --
            DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'FO Invoice Migration Status Update',gv_fo_proc_name,'I');
            BEGIN
              FO_DM_INVOICED_SPEND.p_upd_migration@FO_R(ln_msg_id);
            EXCEPTION
              WHEN OTHERS THEN
                gv_fo_app_err_msg := 'Unable to execute the procedure to update the migrate flag for FO invoicing!';
                gv_fo_db_err_msg := SQLERRM;
	        RAISE ge_fo_exception;
            END;

            --
            -- check for any errors in remote procedure
            --
            BEGIN
              SELECT err_msg
                INTO lv_err_msg
                FROM fo_dm_err_msg_tmp@FO_R;

                IF lv_err_msg IS NOT NULL THEN
                   gv_fo_app_err_msg := 'Errors occured in the procedure to process FO data! ';
	           gv_fo_db_err_msg := lv_err_msg||' '||SQLERRM;
	           RAISE ge_fo_exception;
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   lv_err_msg := NULL;
            END;

            DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

            --
            -- get the number of rows processed
            --
            BEGIN
              SELECT COUNT(1)
                INTO ln_process_cnt
                FROM fo_dm_inv_details_final_tmp@FO_R;
            EXCEPTION
               WHEN OTHERS THEN
                  gv_fo_app_err_msg := 'Error in getting count for FO! ';
                  gv_fo_db_err_msg  :=  SQLERRM;
                  RAISE ge_fo_exception;
            END;

            --
            -- Log the count
            --
            DM_UTIL_LOG.p_log_msg(ln_msg_id,4,to_char(ln_process_cnt)||' Rows Processed for FO Invoicing !',gv_fo_proc_name,'I');
            DM_UTIL_LOG.p_log_msg(ln_msg_id,4,null,null,'U');

            Commit;

            --
            -- Log the final load status for FO
            --
            DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_INVOICED_SPEND_ALL','FOI','COMPLETE',ln_process_cnt,'U');

            --
            --Insert into dm_invoiced_batches used in populating spend summary
            --
            IF nvl(ln_process_cnt,0) > 0 THEN
               INSERT into dm_invoiced_batches(batch_id,object_source,load_date) VALUES(ln_msg_id,'FOI',SYSDATE);
               Commit;
            END IF;

          EXCEPTION
            WHEN ge_fo_exception THEN
              --
              -- user defined exception, Log and raise the application error.
              --
              Rollback;
              DM_UTIL_LOG.p_log_msg(ln_msg_id,0,'dm_invoiced_spend-ERROR..Please see the dm_error_log for details',gv_fo_proc_name,'I');
              DM_UTIL_LOG.p_log_msg(ln_msg_id,0,null,null,'U');
              ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_fo_app_err_msg,
                                               gv_fo_db_err_msg,
                                               gv_fo_proc_name);
              --
              -- Log the final load status for FO
              --
              DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_INVOICED_SPEND_ALL','FOI','FAILED',ln_process_cnt,'U');
              dm_utils.send_email(email_sender, email_recipients, email_subject,  'FOI Process failed in '||gv_fo_proc_name || c_crlf || gv_fo_app_err_msg || c_crlf || gv_fo_db_err_msg || c_crlf);

            WHEN OTHERS THEN
              --
              -- Unknown exception, Log and raise the application error.
              --
              Rollback;
              DM_UTIL_LOG.p_log_msg(ln_msg_id,0,'dm_invoiced_spend-ERROR..Please see the dm_error_log for details',gv_fo_proc_name,'I');
              DM_UTIL_LOG.p_log_msg(ln_msg_id,0,null,null,'U');
              gv_fo_app_err_msg := 'Unknown Error !';
              gv_fo_db_err_msg  := SQLERRM;
              ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                           gv_fo_app_err_msg,
                                                           gv_fo_db_err_msg,
                                                           gv_fo_proc_name);
              --
              -- Log the final load status for FO
              --
              DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_INVOICED_SPEND_ALL','FOI','FAILED',ln_process_cnt,'U');
              dm_utils.send_email(email_sender, email_recipients, email_subject,  'FOI Process failed in '||gv_fo_proc_name || c_crlf || gv_fo_app_err_msg || c_crlf || gv_fo_db_err_msg || c_crlf);

          END; -- End of FOI

        END IF;
        --
        -- END FO processing
        --

        --
        -- BEGIN BO processing
        --
        --

        IF iv_section IN ('BOTH','BOI') THEN
        -- check for any failed loads from last run. If anything failed, it needs to addressed first before running the new one
        --
        BEGIN
          SELECT count(*)
            INTO bo_ln_count
            FROM dm_load_log
           WHERE batch_id = (SELECT max(batch_id) FROM dm_load_log WHERE object_name = 'DM_INVOICED_SPEND_ALL' AND object_source = 'BOI')
             AND object_name   = 'DM_INVOICED_SPEND_ALL'
             AND object_source = 'BOI'
             AND load_status = 'FAILED';
        END;

        IF bo_ln_count > 0 THEN
           --
           -- previous load failed log and exit
           --
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'DM_INVOICED_SPEND-PREVIOUS BOI Load Failed','DM_INVOICED_SPEND.p_main','I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');


        ELSE


          BEGIN  -- section BOI
            --
            --Log initial load status
            --
            DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_INVOICED_SPEND_ALL','BOI','STARTED',NULL,'I');

            --
            -- Call the procedure to get the BO invoiced data.
            --
            DM_UTIL_LOG.p_log_msg(ln_msg_id,5,'BO Invoice Migration Process',gv_bo_proc_name,'I');
            BEGIN
              p_get_bo_invoiced_data(ln_msg_id,ln_err_num,lv_err_msg);
            EXCEPTION
              WHEN OTHERS THEN
                gv_bo_app_err_msg := 'Unable to execute the procedure to get BO invoiced data!';
                gv_bo_db_err_msg := SQLERRM;
	        RAISE ge_bo_exception;
            END;

            --
            --  check for any errors returned after executing the procedure
            --
            IF ln_err_num > 0 THEN
               gv_bo_app_err_msg := 'Errors occured in the procedure to get BO invoiced data!';
               gv_bo_db_err_msg := lv_err_msg||' '||SQLERRM;
	       RAISE ge_bo_exception;
            END IF;

            DM_UTIL_LOG.p_log_msg(ln_msg_id,5,null,null,'U');

            --
            -- get the number of rows processed
            --
            BEGIN
              SELECT COUNT(1)
                INTO ln_process_cnt
                FROM FO_BO_DM_INVOICED_SPEND_ALL@FO_R;
            EXCEPTION
               WHEN OTHERS THEN
                  gv_bo_app_err_msg := 'Error in getting count for FO! ';
                  gv_bo_db_err_msg  :=  SQLERRM;
                  RAISE ge_bo_exception;
            END;

            --
            -- Log the count
            --
            DM_UTIL_LOG.p_log_msg(ln_msg_id,6,to_char(ln_process_cnt)||' Rows Processed for BO Invoicing !',gv_bo_proc_name,'I');
            DM_UTIL_LOG.p_log_msg(ln_msg_id,6,null,null,'U');

            --
            --call the procedure to Delete Cancelled Invoices from data mart
            --
            DM_UTIL_LOG.p_log_msg(ln_msg_id,7,'Delete Cancelled Invoices from data mart ',gv_bo_proc_name,'I');
            BEGIN
              p_bo_deletes(ln_msg_id,ln_err_num,lv_err_msg);
            EXCEPTION
              WHEN OTHERS THEN
                gv_bo_app_err_msg := 'Unable to execute the procedure to Delete BO invoiced data from data mart!';
                gv_bo_db_err_msg := SQLERRM;
	        RAISE ge_bo_exception;
            END;

            --
            --  check for any errors returned after executing the procedure
            --
            IF ln_err_num > 0 THEN
               gv_bo_app_err_msg := 'Errors occured in the procedure to Delete BO invoiced data from data mart!';
               gv_bo_db_err_msg := lv_err_msg||' '||SQLERRM;
	       RAISE ge_bo_exception;
            END IF;
            DM_UTIL_LOG.p_log_msg(ln_msg_id,7,null,null,'U');


            Commit;

            --
            -- Log the final load status for FO
            --
            DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_INVOICED_SPEND_ALL','BOI','COMPLETE',ln_process_cnt,'U');

            --
            --Insert into dm_invoiced_batches used in populating spend summary
            --
            IF nvl(ln_process_cnt,0) > 0 THEN
               INSERT into dm_invoiced_batches(batch_id,object_source,load_date) VALUES(ln_msg_id,'BOI',SYSDATE);
               Commit;
            END IF;
          EXCEPTION
            WHEN ge_bo_exception THEN
              --
              -- user defined exception, Log and raise the application error.
              --
              Rollback;
              DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_invoiced_spend-ERROR..Please see the dm_error_log for details',gv_bo_proc_name,'I');
              DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
              ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                 gv_bo_app_err_msg,
                                                 gv_bo_db_err_msg,
                                                 gv_bo_proc_name);
              --
              -- Log the final load status for FO
              --
              DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_INVOICED_SPEND_ALL','BOI','FAILED',ln_process_cnt,'U');
              dm_utils.send_email(email_sender, email_recipients, email_subject,  'BOI Process failed in '||gv_bo_proc_name || c_crlf || gv_bo_app_err_msg || c_crlf || gv_bo_db_err_msg || c_crlf);

            WHEN OTHERS THEN
              --
              -- Unknown exception, Log and raise the application error.
              --
              Rollback;
              DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_invoiced_spend-ERROR..Please see the dm_error_log for details',gv_bo_proc_name,'I');
              DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
              gv_bo_app_err_msg := 'Unknown Error !';
              gv_bo_db_err_msg  := SQLERRM;
              ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                           gv_bo_app_err_msg,
                                                           gv_bo_db_err_msg,
                                                           gv_bo_proc_name);
              --
              -- Log the final load status for FO
              --
              DM_UTIL_LOG.p_log_load_status(ln_msg_id,'DM_INVOICED_SPEND_ALL','BOI','FAILED',ln_process_cnt,'U');
              dm_utils.send_email(email_sender, email_recipients, email_subject,  'BOI Process failed in '||gv_bo_proc_name || c_crlf || gv_bo_app_err_msg || c_crlf || gv_bo_db_err_msg || c_crlf);

          END; -- End of BOI

        END IF;
        END IF;
        --
        -- END BO processing
        --


        DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');-- End of main process

     END IF;

  END p_main;


END dm_invoiced_spend;
/