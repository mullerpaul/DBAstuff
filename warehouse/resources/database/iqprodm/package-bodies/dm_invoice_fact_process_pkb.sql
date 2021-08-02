CREATE OR REPLACE PACKAGE BODY dm_invoice_fact_process
/********************************************************************
 * Name: dm_invoice_fact_process
 * Desc: This package contains all the procedures required to
 *       populate the invoice FACT
 *
 * Author  Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   08/10/2010  Initial
 * Sajeev  03/28/2012  Removed drop/create/mv procedures
 * Sajeev  05/21/2012  Added curr dim for CAD
 * Sajeev  08/08/2012    Added sqlerrm before rollback
 ********************************************************************/
AS
  ge_exception         EXCEPTION;
  gv_app_err_msg       VARCHAR2(2000)  := NULL;
  gv_db_err_msg        VARCHAR2(2000)  := NULL;

  procedure dump_bulk_exceptions
  (
      p_msg_id    NUMBER
  )
  as
    v_err               NUMBER;
  begin
        gv_app_err_msg := 'Number of errors is ' || sql%bulk_exceptions.count;
        gv_db_err_msg  := NULL;
        v_err := DM_UTIL_LOG.f_log_error(p_msg_id, gv_app_err_msg, gv_db_err_msg, 'INVOICE_FACT BULK ERROR');
        dbms_output.put_line (gv_app_err_msg);

        for i in 1 .. sql%bulk_exceptions.count
        loop
            gv_app_err_msg := 'Error ' || i || ' occurred during '|| 'iteration ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
            gv_db_err_msg := 'Oracle error is ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
            v_err := DM_UTIL_LOG.f_log_error(p_msg_id, gv_app_err_msg, gv_db_err_msg, 'INVOICE_FACT BULK ERROR');
            dbms_output.put_line (gv_app_err_msg);
            dbms_output.put_line (gv_db_err_msg);
        end loop;
 end dump_bulk_exceptions;

 /**************************************************************
  * Name: get_invoices
  * Desc: This proccedure gets all the invoice numbers to be
  *       processed.
  **************************************************************/
  PROCEDURE get_invoices(in_msg_id              IN  NUMBER,
                         id_last_process_date   IN  DATE,
                         od_cur_process_date    OUT DATE)
  IS
    ld_cur_process_date  DATE;
  BEGIN
    BEGIN
      SELECT max(last_update_date)
        INTO ld_cur_process_date
        FROM dm_invoiced_spend_all
       WHERE last_update_date > id_last_process_date;

    EXCEPTION
        WHEN OTHERS THEN
           gv_app_err_msg := 'get_invoices: Unable to get latest process date from dm_invoiced_spend_all';
           gv_db_err_msg := SQLERRM;
           RAISE ge_exception;
    END;

    BEGIN
      INSERT INTO dm_invoices_tmp t
             (invoice_number,
              object_source,
              invoice_date
             )
      SELECT DISTINCT
             invoice_number,
             object_source,
             invoice_date
        FROM dm_invoiced_spend_all
       WHERE last_update_date >  id_last_process_date
         AND last_update_date <= ld_cur_process_date;

    EXCEPTION
        WHEN OTHERS THEN
           gv_app_err_msg := 'get_invoices: Unable to get the invoices to be processed';
           gv_db_err_msg := SQLERRM;
           RAISE ge_exception;
    END;

    od_cur_process_date := ld_cur_process_date;

  EXCEPTION
    WHEN OTHERS THEN
      gv_app_err_msg := 'get_invoices: Unknown Error';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;
  END get_invoices;

 
 /**************************************************************
  * Name: process_invoice_fact
  * Desc: This proccedure inserts the records into the invoice
  *       FACT after getting data from invoiced spend table
  **************************************************************/
  PROCEDURE process_invoice_fact(in_msg_id               IN NUMBER)
  IS
    ld_last_update_date  		DATE;
    ln_msg_id            		NUMBER;

    TYPE inv_fact_tab_typ IS TABLE OF dm_invoice_fact%ROWTYPE;
    inv_fact_tab  			inv_fact_tab_typ;

    CURSOR inv_cur
    IS
    SELECT invoice_number,
           object_source,
           invoice_date
      FROM dm_invoices_tmp;



    dml_errors EXCEPTION;
    PRAGMA exception_init(dml_errors, -24381);
  BEGIN
    ln_msg_id           := in_msg_id;
    ld_last_update_date := SYSDATE;

    FOR inv_cur_rec IN inv_cur
    LOOP
      SELECT DM_CUBE_UTILS.get_organization_dim_id(buyer_bus_org_fk,invoice_date,'REGULAR')                    buyer_org_dim_id,
             DM_CUBE_UTILS.get_org_geo_dim_id(buyer_bus_org_fk,invoice_date,'REGULAR')                         buyer_geo_dim_id,
             DM_CUBE_UTILS.get_organization_dim_id(supplier_bus_org_fk,invoice_date,'REGULAR')                 supplier_org_dim_id,
             DM_CUBE_UTILS.get_org_geo_dim_id(supplier_bus_org_fk,invoice_date,'REGULAR')                      supplier_geo_dim_id,
             (CASE
              WHEN work_order_type in ('WO','EA') THEN
                NVL(DM_CUBE_UTILS.get_work_loc_geo_dim_id(work_order_id,'REGULAR'),0)
              ELSE
                0
              END)                                                                                             work_loc_geo_dim_id,
             DM_CUBE_UTILS.get_currency_dim_id(currency)                                                       txn_currency_dim_id,
             DM_CUBE_UTILS.get_person_dim_id(contractor_person_id,invoice_date,'REGULAR',nvl(buyer_bus_org_fk,0))     cont_person_dim_id,
             DM_CUBE_UTILS.get_person_dim_id(hm_person_id,invoice_date,'REGULAR',nvl(buyer_bus_org_fk,0))             hm_person_dim_id,
             DM_CUBE_UTILS.get_person_dim_id(expenditure_approver_pid,invoice_date,'REGULAR',nvl(buyer_bus_org_fk,0)) expnd_appr_person_dim_id,
             (CASE
             WHEN spend_category = 'Milestones' THEN
              DM_CUBE_UTILS.get_expenditure_dim_id(sow_spend_category,sow_spend_type,object_source)
             ELSE
              DM_CUBE_UTILS.get_expenditure_dim_id(spend_category,spend_type,object_source)
             END)                                                                                              expenditure_dim_id,
             DM_CUBE_UTILS.get_engagement_type_dim_id(work_order_type)                                         engagement_type_dim_id,
             DM_CUBE_UTILS.get_invoiced_cac_dim_id(nvl(buyer_bus_org_fk,0),cac1_seg1_value,
                                                                          cac1_seg2_value,
                                                                          cac1_seg3_value,
                                                                          cac1_seg4_value,
                                                                          cac1_seg5_value,
                                                                          cac2_seg1_value,
                                                                          cac2_seg2_value,
                                                                          cac2_seg3_value,
                                                                          cac2_seg4_value,
                                                                          cac2_seg5_value,
                                                                          'REGULAR')                           inv_cac_dim_id,
             DM_CUBE_UTILS.get_job_dim_id(job_id,invoice_date,'REGULAR',nvl(buyer_bus_org_fk,0))                      job_dim_id,
             DM_CUBE_UTILS.get_project_agreement_dim_id(project_agreement_id,invoice_date,'REGULAR',nvl(buyer_bus_org_fk,0)) pa_dim_id,
             (CASE
              WHEN work_order_type in ('WO','EA') THEN
                 DM_CUBE_UTILS.get_ratecard_dim_id(work_order_id,'REGULAR',nvl(buyer_bus_org_fk,0))
              ELSE
               -1*nvl(buyer_bus_org_fk,0)
              END)                                                                                         ratecard_dim_id ,
             (CASE
              WHEN NVL(to_number(to_char(assignment_start_date,'YYYYMMDD')),0) =0 THEN
               -1*NVL(dm_cube_utils.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)),nvl(buyer_bus_org_fk,0))
              ELSE
               to_number(to_number(to_char(assignment_start_date,'YYYYMMDD'))||
                         DM_CUBE_UTILS.get_data_source_id('REGULAR')||
                         DM_CUBE_UTILS.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)))
              END)                                                                                         assign_start_date_dim_id,
             (CASE
              WHEN NVL(to_number(to_char(assignment_end_date,'YYYYMMDD')),0) =0 THEN
                -1*NVL(dm_cube_utils.get_top_parent_org_id(buyer_bus_org_fk),nvl(buyer_bus_org_fk,0))
              ELSE
               to_number(to_number(to_char(assignment_end_date,'YYYYMMDD'))||
                         DM_CUBE_UTILS.get_data_source_id('REGULAR')||
                         DM_CUBE_UTILS.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)))
              END)                                                                                         assign_end_date_dim_id,
             (CASE WHEN work_order_type in ('WO','EA') THEN
                   (CASE
	            WHEN NVL(to_number(to_char(DM_CUBE_UTILS.get_assignment_actual_end_date(work_order_id,'REGULAR'),'YYYYMMDD')),0) =0 THEN
	             -1*NVL(dm_cube_utils.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)),nvl(buyer_bus_org_fk,0))
	            ELSE
	              to_number(to_number(to_char(DM_CUBE_UTILS.get_assignment_actual_end_date(work_order_id,'REGULAR'),'YYYYMMDD'))||
	                        DM_CUBE_UTILS.get_data_source_id('REGULAR')||
	                        DM_CUBE_UTILS.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)))
                    END)


              ELSE
                -1*NVL(dm_cube_utils.get_top_parent_org_id(buyer_bus_org_fk),nvl(buyer_bus_org_fk,0))
              END)                                                                                         assign_act_end_date_dim_id,
             (CASE
              WHEN NVL(to_number(to_char(expenditure_date,'YYYYMMDD')),0) =0 THEN
               -1*NVL(dm_cube_utils.get_top_parent_org_id(buyer_bus_org_fk),nvl(buyer_bus_org_fk,0))
              ELSE
               to_number(to_number(to_char(expenditure_date,'YYYYMMDD'))||
                         DM_CUBE_UTILS.get_data_source_id('REGULAR')||
                         DM_CUBE_UTILS.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)))
              END)                                                                                         expnd_date_dim_id,
             (CASE
              WHEN NVL(to_number(to_char(expenditure_approved_date,'YYYYMMDD')),0) = 0 THEN
               -1*NVL(dm_cube_utils.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)),nvl(buyer_bus_org_fk,0))
              ELSE
               to_number(to_number(to_char(expenditure_approved_date,'YYYYMMDD'))||
                         DM_CUBE_UTILS.get_data_source_id('REGULAR')||
                         DM_CUBE_UTILS.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)))
              END)                                                                                         expnd_appr_date_dim_id,
             DM_CUBE_UTILS.get_time_dim_id(expenditure_approved_date)                                      expnd_appr_time_dim_id,
             (CASE
              WHEN NVL(to_number(to_char(invoice_date,'YYYYMMDD')),0) = 0 THEN
               -1*NVL(dm_cube_utils.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)),nvl(buyer_bus_org_fk,0))
              ELSE
               to_number(to_number(to_char(invoice_date,'YYYYMMDD'))||
                         DM_CUBE_UTILS.get_data_source_id('REGULAR')||
                         DM_CUBE_UTILS.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)))
              END)                                                                                         invoice_date_dim_id,
             DM_CUBE_UTILS.get_time_dim_id(invoice_creation_date)                                          invoice_crt_time_dim_id,
             (CASE
              WHEN NVL(to_number(to_char(invoice_creation_date,'YYYYMMDD')),0) = 0 THEN
               -1*NVL(dm_cube_utils.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)),nvl(buyer_bus_org_fk,0))
              ELSE
               to_number(to_number(to_char(invoice_creation_date,'YYYYMMDD'))||
                         DM_CUBE_UTILS.get_data_source_id('REGULAR')||
                         DM_CUBE_UTILS.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)))
              END)                                                                                         invoice_crt_date_dim_id,
             (CASE
              WHEN NVL(to_number(to_char(week_ending_date,'YYYYMMDD')),0) = 0 THEN
               -1*NVL(dm_cube_utils.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)),nvl(buyer_bus_org_fk,0))
              ELSE
               to_number(to_number(to_char(week_ending_date,'YYYYMMDD'))||
                         DM_CUBE_UTILS.get_data_source_id('REGULAR')||
                         DM_CUBE_UTILS.get_top_parent_org_id(nvl(buyer_bus_org_fk,0)))
              END)                                                                                         invoice_wk_ending_date_dim_id,
             invoice_number                                                                                invoice_number,
             expenditure_number                                                                            expenditure_number,
             work_order_id                                                                                 engagement_id,
             (CASE WHEN spend_type = 'ST' THEN
                    'Labor-Contractors'
                   WHEN spend_type = 'OT' THEN
                    'Labor-Overtime'
                   WHEN spend_type = 'DT' THEN
                    'Labor-Doubletime'
             END)                                                                                          rate_type_name,
             base_bill_rate                                                                                base_bill_rate,
             base_pay_rate                                                                                 base_pay_rate,
             buyer_adjusted_bill_rate                                                                      buyer_adj_bill_rate,
             supplier_reimbursement_rate                                                                   supp_reimb_rate,
             (CASE WHEN spend_type = 'ST' THEN nvl(base_bill_rate,0) ELSE 0 END)                           reg_base_bill_rate,
             (CASE WHEN spend_type = 'ST' THEN nvl(base_pay_rate,0) ELSE 0 END)                            reg_base_pay_rate,
             (CASE WHEN spend_type = 'ST' THEN nvl(buyer_adjusted_bill_rate,0) ELSE 0 END)                 reg_buyer_adj_bill_rate,
             (CASE WHEN spend_type = 'ST' THEN nvl(supplier_reimbursement_rate,0) ELSE 0 END)              reg_supp_reimb_rate,
             (CASE WHEN spend_type = 'OT' THEN nvl(base_bill_rate,0) ELSE 0 END)                           ot_base_bill_rate,
             (CASE WHEN spend_type = 'OT' THEN nvl(base_pay_rate,0) ELSE 0 END)                            ot_base_pay_rate,
             (CASE WHEN spend_type = 'OT' THEN nvl(buyer_adjusted_bill_rate,0) ELSE 0 END)                 ot_buyer_adj_bill_rate,
             (CASE WHEN spend_type = 'OT' THEN nvl(supplier_reimbursement_rate,0) ELSE 0 END)              ot_supp_reimb_rate,
             (CASE WHEN spend_type = 'DT' THEN nvl(base_bill_rate,0) ELSE 0 END)                           dt_base_bill_rate,
             (CASE WHEN spend_type = 'DT' THEN nvl(base_pay_rate,0) ELSE 0 END)                            dt_base_pay_rate,
             (CASE WHEN spend_type = 'DT' THEN nvl(buyer_adjusted_bill_rate,0) ELSE 0 END)                 dt_buyer_adj_bill_rate,
             (CASE WHEN spend_type = 'DT' THEN nvl(supplier_reimbursement_rate,0) ELSE 0 END)              dt_supp_reimb_rate,
             buyer_fee                                                                                     buyer_fee,
             supplier_fee                                                                                  supplier_fee,
             total_fee                                                                                     total_fee,
             (CASE WHEN spend_type = 'ST' THEN nvl(quantity,0) ELSE 0 END)                                 reg_hours,
             (CASE WHEN spend_type = 'OT' THEN nvl(quantity,0) ELSE 0 END)                                 ot_hours,
             (CASE WHEN spend_type = 'DT' THEN nvl(quantity,0) ELSE 0 END)                                 dt_hours,
             (CASE WHEN spend_type = 'CS' THEN nvl(quantity,0) ELSE 0 END)                                 cs_hours,
             buyer_adjusted_amount                                                                         buyer_adj_amount,
             supplier_reimbursement_amount                                                                 supp_reimb_amount,
             (CASE WHEN spend_type = 'ST' THEN nvl(buyer_adjusted_amount,0) ELSE 0 END)                    reg_hours_buyer_adj_amount,
             (CASE WHEN spend_type = 'OT' THEN nvl(buyer_adjusted_amount,0) ELSE 0 END)                    ot_hours_buyer_adj_amount,
             (CASE WHEN spend_type = 'DT' THEN nvl(buyer_adjusted_amount,0) ELSE 0 END)                    dt_hours_buyer_adj_amount,
             (CASE WHEN spend_type = 'CS' THEN nvl(buyer_adjusted_amount,0) ELSE 0 END)                    cs_hours_buyer_adj_amount,
             (CASE WHEN spend_type = 'ST' THEN nvl(supplier_reimbursement_amount,0) ELSE 0 END)            reg_hours_supp_reimb_amount,
             (CASE WHEN spend_type = 'OT' THEN nvl(supplier_reimbursement_amount,0) ELSE 0 END)            ot_hours_supp_reimb_amount,
             (CASE WHEN spend_type = 'DT' THEN nvl(supplier_reimbursement_amount,0) ELSE 0 END)            dt_hours_supp_reimb_amount,
             (CASE WHEN spend_type = 'CS' THEN nvl(supplier_reimbursement_amount,0) ELSE 0 END)            cs_hours_supp_reimb_amount,
             (CASE WHEN DM_CUBE_UTILS.get_expenditure_category(spend_category,
                                                                    spend_type,
                                                                    object_source) = 'Tax' THEN
                   nvl(buyer_adjusted_amount,0) ELSE 0 END)                                                tax_amount,
             ln_msg_id                                                                                     batch_id,
             ld_last_update_date                                                                           last_update_date,
             'REGULAR'                                                                                     data_source_code,
             object_source                                                                                 inv_object_source,
             buyer_bus_org_fk,
             supplier_bus_org_fk,
             dm_invoice_fact_seq.NEXTVAL                                                                   invoice_fact_sequence,
             to_number(to_char(invoice_date,'YYYYMMDD'))                                                   invoice_date_id,
             to_number(to_char(expenditure_date,'YYYYMMDD'))                                               expenditure_date_id,
 		dm_cube_utils.get_curr_conv_dim_id(DM_CUBE_UTILS.get_currency_dim_id(currency),'USD',TRUNC(expenditure_date)) 			curr_conv_us_dim_id,
 		dm_cube_utils.get_curr_conv_dim_id(DM_CUBE_UTILS.get_currency_dim_id(currency),'EUR',TRUNC(expenditure_date)) 			curr_conv_eur_dim_id,
 		dm_cube_utils.get_curr_conv_dim_id(DM_CUBE_UTILS.get_currency_dim_id(currency),'GBP',TRUNC(expenditure_date))  			curr_conv_gbp_dim_id,
           CASE WHEN work_order_type in ('WO','EA') THEN 
                     NVL(dm_cube_utils.get_assignment_dim_id(work_order_id,'REGULAR'),0)
                ELSE 0
           END  														                                           assignment_dim_id,
		(CASE WHEN PROJECT_AGREEMENT_ID > 0 THEN  'Project/SOW'
                ELSE 'Contingent'
           END)																							engagement_classification,
 		dm_cube_utils.get_curr_conv_dim_id(DM_CUBE_UTILS.get_currency_dim_id(currency),'CAD',TRUNC(expenditure_date))  			curr_conv_cad_dim_id
       BULK COLLECT INTO inv_fact_tab
       FROM dm_invoiced_spend_all 
      WHERE invoice_number = inv_cur_rec.invoice_number
        AND object_source  = inv_cur_rec.object_source
        AND invoice_date   = inv_cur_rec.invoice_date;

        BEGIN
          FORALL i in inv_fact_tab.first .. inv_fact_tab.last SAVE EXCEPTIONS
          INSERT INTO dm_invoice_fact VALUES inv_fact_tab(i);

          INSERT
            INTO dm_invoices_fact_log
                 (invoice_number,
                  object_source,
                  last_process_date,
                  invoice_date
                 )
          VALUES (inv_cur_rec.invoice_number,
                  inv_cur_rec.object_source,
                  SYSDATE,
                  inv_cur_rec.invoice_date
                 );
        EXCEPTION
           WHEN dml_errors THEN 
                BEGIN
                   -- ROLLBACK?
                   dump_bulk_exceptions(ln_msg_id);
                END;
        END;
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      gv_app_err_msg := 'process_invoice_fact : Unknown Error';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;
END process_invoice_fact;

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in creating invoice FACT
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR')
  IS
    ln_msg_id            NUMBER;
    gv_proc_name         VARCHAR2(100)   := 'dm_invoice_fact_process.p_main' ;
    ln_err               NUMBER;
    ld_last_process_date DATE;
    ld_cur_process_date  DATE;
    email_sender         VARCHAR2(32) := 'mart_processing@iqnavigator.com';
    email_recipients     VARCHAR2(64) := 'data_warehouse@iqnavigator.com';
    email_subject        VARCHAR2(64) := 'Invoice Spend FACT Load Failed: ';
    c_crlf               VARCHAR2(2)  := chr(13) || chr(10);
    p_date_id            NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'));
    ln_dim_count         NUMBER;

  BEGIN
    ln_msg_id := DM_MSG_LOG_SEQ.nextval;

    dm_cube_utils.make_indexes_visible;

    BEGIN
       SELECT count(1)
         INTO ln_dim_count
         FROM dm_cube_jobs_log a,
              dm_cube_jobs b
        WHERE a.cube_job_id      = b.cube_job_id
          AND b.cube_object_type = 'SPEND_CUBE-DIM'
          AND a.date_id between TO_NUMBER(TO_CHAR((SYSDATE-6),'YYYYMMDD')) and TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
          AND a.load_status     = 'FAILED';
     END;

    IF ln_dim_count <> 0 THEN -- this means errors in DIM loads in last 7 days
       gv_app_err_msg := 'FACT did not load due to FAILED DIM process in last 7 days!';
       gv_db_err_msg  := 'Please check dm_cube_jobs_log and fix the DIM loads and then change the load status to COMPLETED from FAILED to process FACT';
       RAISE ge_exception;
    END IF;
 
    SELECT last_update_date
    INTO ld_last_process_date
    FROM dm_cube_objects
    WHERE object_name = 'DM_INVOICE_FACT'
    AND object_source_code =in_data_source_code;

    BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_invoices_tmp';
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to trunacte work table dm_invoices_tmp!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'dm_invoice_fact_process',gv_proc_name,'I'); -- log the start of main process

     --
     -- Step 2 : Run the procedure to get all the invoices that need to be processed
     --

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Procedure to get all invoices to be processed',gv_proc_name,'I');

     BEGIN
       get_invoices(ln_msg_id,ld_last_process_date,ld_cur_process_date);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to get all invoices to be processed!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

     --
     -- Step 3 : Process the invoice fact and Update cube objects
     --

     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Process the Invoice FACT',gv_proc_name,'I');

     BEGIN
       process_invoice_fact(ln_msg_id);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to process the Invoice FACT!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

     --
     -- Update the cube objects for last process date
     --

     IF ld_cur_process_date IS NOT NULL THEN
        UPDATE dm_cube_objects
         SET last_update_date = ld_cur_process_date
         WHERE object_name      = 'DM_INVOICE_FACT'
         AND object_source_code =in_data_source_code;
     END IF;

     commit;

     IF ltrim(rtrim(to_char(sysdate,'DAY'))) IN ('SATURDAY','SUNDAY') THEN

      DM_UTIL_LOG.p_log_msg(ln_msg_id,4,'Stats Gather on DM_INVOICE_FACT',gv_proc_name,'I');

       BEGIN
         DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER,TABNAME=>'DM_INVOICE_FACT',ESTIMATE_PERCENT=>2,METHOD_OPT=>'FOR ALL COLUMNS SIZE 1',CASCADE=>TRUE,no_invalidate=>FALSE);
       EXCEPTION
        WHEN OTHERS THEN
           gv_app_err_msg := 'Unable to analyze the Invoice Fact! ';
           gv_db_err_msg  := SQLERRM;
           RAISE ge_exception;
       END;

      DM_UTIL_LOG.p_log_msg(ln_msg_id,4,null,null,'U');

     END IF; 

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');

     DM_UTIL_LOG.p_log_cube_load_status('DM_INVOICE_FACT',
                                         in_data_source_code,
                                        'SPEND_CUBE-FACT',
                                        'COMPLETED',
                                         p_date_id);
     Commit;

  EXCEPTION
      WHEN ge_exception THEN
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_job_dim_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
            ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_app_err_msg,
                                               gv_db_err_msg,
                                               gv_proc_name);
           DM_UTIL_LOG.p_log_cube_load_status('DM_INVOICE_FACT',
                                               in_data_source_code,
                                              'SPEND_CUBE-FACT',
                                              'FAILED',
                                               p_date_id);
           DM_UTILS.send_email(email_sender,email_recipients,email_subject,'FACT load processing Failed!'||c_crlf||'Please see the tables dm_msg_log and dm_error_log for details');
      WHEN OTHERS THEN
           gv_db_err_msg  := SQLERRM;
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_job_dim_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
           gv_app_err_msg := 'Unknown Error !';
           ln_err         := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                        gv_app_err_msg,
                                                        gv_db_err_msg,
                                                        gv_proc_name);
           DM_UTIL_LOG.p_log_cube_load_status('DM_INVOICE_FACT',
                                         	    in_data_source_code,
                                        		'SPEND_CUBE-FACT',
                                        		'FAILED',
                                         		p_date_id);
           DM_UTILS.send_email(email_sender,email_recipients,email_subject,'FACT load processing Failed!'||c_crlf||'Please see the tables dm_msg_log and dm_error_log for details');
  END p_main;
END dm_invoice_fact_process;
/