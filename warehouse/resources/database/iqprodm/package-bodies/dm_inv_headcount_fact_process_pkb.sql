CREATE OR REPLACE PACKAGE BODY dm_inv_headcount_fact_process
/********************************************************************
 * Name: dm_inv_headcount_fact_process
 * Desc: This package contains all the procedures required to
 *       populate the invoiced Headcount FACT
 *
 * Author  Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   02/14/11    Initial
 * Sajeev  03/28/2012  Removed create index and create mv
 * Sajeev  08/08/2012  Added sqlerrm before rollback
 * JoeP    02/01/2016  Hard-coded dblink
 ********************************************************************/
AS
    gv_app_err_msg       VARCHAR2(2000)  := NULL;
    gv_db_err_msg        VARCHAR2(2000)  := NULL;
    ge_exception         EXCEPTION;
 
 /**************************************************************************
  * Name: get_invoiced_assignments
  * Desc: This proccedure gets all the invoiced assignments
  *       from dm_invoiced_spend_all ( source of all invoices in data mart)
  **************************************************************************/
  PROCEDURE get_invoiced_assignments(in_msg_id              IN  NUMBER,
                                     id_last_process_date   IN  DATE,
                                     od_cur_process_date    OUT DATE)
  IS
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ld_cur_process_date  DATE;

  BEGIN
    BEGIN
      SELECT max(last_update_date)
        INTO ld_cur_process_date
        FROM dm_invoiced_spend_all
       WHERE last_update_date > id_last_process_date;
    EXCEPTION
        WHEN OTHERS THEN
           gv_app_err_msg := 'get_invoiced_assignments: Unable to get latest process date';
           gv_db_err_msg := SQLERRM;
           RAISE ge_exception;
    END;

    BEGIN
      INSERT INTO dm_inv_assignments_tmp t
             (buyer_bus_org_fk,
              supplier_bus_org_fk,
              invoice_number,
              invoice_date,
              object_source,
              assignment_id,
              assignment_type,
              job_id
             )
      SELECT DISTINCT
             buyer_bus_org_fk,
             supplier_bus_org_fk,
             invoice_number,
             invoice_date,
             object_source,
             work_order_id,
             work_order_type,
             job_id
        FROM dm_invoiced_spend_all
       WHERE last_update_date >  id_last_process_date
         AND last_update_date <= ld_cur_process_date
         AND work_order_type in ('WO','EA')
         AND nvl(buyer_bus_org_fk,0) > 0 ;

    EXCEPTION
        WHEN OTHERS THEN
           gv_app_err_msg := 'Unable to get the invoiced assignments to be processed ! ';
           gv_db_err_msg := SQLERRM;
           RAISE ge_exception;
    END;

    BEGIN
      INSERT INTO dm_invoiced_assignments_tmp t
             (buyer_bus_org_fk,
              supplier_bus_org_fk,
              invoice_number,
              invoice_date,
              object_source,
              worker_id,
              assignment_id,
              assignment_type,
              job_id
             )
      SELECT DISTINCT
             buyer_bus_org_fk,
             supplier_bus_org_fk,
             invoice_number,
             invoice_date,
             object_source,
             FO_DM_UTIL.get_worker_id@FO_R(assignment_id),
             assignment_id,
             assignment_type,
             job_id
        FROM dm_inv_assignments_tmp;

    EXCEPTION
        WHEN OTHERS THEN
           gv_app_err_msg := 'Unable to get the invoiced assignments to be processed ! ';
           gv_db_err_msg := SQLERRM;
           RAISE ge_exception;
    END;

    od_cur_process_date := ld_cur_process_date;

  EXCEPTION
    WHEN OTHERS THEN
      gv_app_err_msg := 'get_invoiced_assignments: Unknown Error !';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;
 END get_invoiced_assignments;

 /*************************************************************************
  * Name: process_fact
  * Desc: This proccedure inserts the records into the invoiced headcount
  *       FACT after getting data from the invoiced assignments temp table
  *************************************************************************/
  PROCEDURE process_fact(in_msg_id               IN NUMBER)
  IS
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ld_last_update_date  DATE;
    ln_msg_id            NUMBER;

    CURSOR hc_cur
    IS
    SELECT DM_CUBE_UTILS.get_organization_dim_id(buyer_bus_org_fk,invoice_date,'REGULAR')           buyer_org_dim_id ,
           DM_CUBE_UTILS.get_organization_dim_id(supplier_bus_org_fk,invoice_date,'REGULAR')        supplier_org_dim_id,
           invoice_number ,
           invoice_date ,
           object_source ,
           NVL(DM_CUBE_UTILS.get_worker_dim_id(worker_id,invoice_date,'REGULAR'),0)                          worker_dim_id  ,
           assignment_id ,
           NVL(DM_CUBE_UTILS.get_work_loc_geo_dim_id(assignment_id,'REGULAR'),0)                    work_loc_geo_dim_id ,
           assignment_type ,
           NVL(DM_CUBE_UTILS.get_job_dim_id(job_id,invoice_date,'REGULAR',buyer_bus_org_fk),(-1*buyer_bus_org_fk))                              job_dim_id,
           1                                                                                              worker_count,
           DM_CUBE_UTILS.get_org_geo_dim_id(buyer_bus_org_fk,invoice_date,'REGULAR')                buyer_geo_dim_id,
           worker_id,
           buyer_bus_org_fk
      FROM dm_invoiced_assignments_tmp
     WHERE worker_id IS NOT NULL;

  BEGIN
    ln_msg_id           := in_msg_id;
    ld_last_update_date := SYSDATE;

    --
    -- Process the fact records and insert into dm_invoiced_headcount_fact_dup table for any duplicate rows
    --

    FOR hc_cur_rec IN hc_cur
    LOOP
      BEGIN
        INSERT
          INTO dm_invoiced_headcount_fact
               (buyer_org_dim_id,
                supplier_org_dim_id,
                invoice_number,
                invoice_date_dim_id,
                object_source,
                worker_dim_id,
                worker_id,
                assignment_id,
                work_loc_geo_dim_id,
                assignment_type,
                job_dim_id,
                worker_count,
                invoice_date_id,
                buyer_geo_dim_id,
                buyer_bus_org_fk,
                batch_id,
                last_update_date,
                fact_sequence)
        VALUES (hc_cur_rec.buyer_org_dim_id,
                hc_cur_rec.supplier_org_dim_id,
                hc_cur_rec.invoice_number,
                to_number(to_char(hc_cur_rec.invoice_date,'YYYYMMDD')||DM_CUBE_UTILS.get_data_source_id('REGULAR')||DM_CUBE_UTILS.get_top_org_id(hc_cur_rec.BUYER_ORG_DIM_ID)),
                hc_cur_rec.object_source,
                hc_cur_rec.worker_dim_id,
                hc_cur_rec.worker_id,
                hc_cur_rec.assignment_id,
                hc_cur_rec.work_loc_geo_dim_id,
                hc_cur_rec.assignment_type,
                hc_cur_rec.job_dim_id,
                hc_cur_rec.worker_count,
                to_number(to_char(hc_cur_rec.invoice_date,'YYYYMMDD')),
                hc_cur_rec.buyer_geo_dim_id,
                hc_cur_rec.buyer_bus_org_fk,
                ln_msg_id ,
                ld_last_update_date,
                invoiced_headcount_fact_seq.NEXTVAL);
      EXCEPTION
       WHEN DUP_VAL_ON_INDEX THEN
        INSERT
          INTO dm_invoiced_headcount_fact_dup
               (
                buyer_org_dim_id,
                supplier_org_dim_id,
                invoice_number,
                invoice_date_dim_id,
                object_source,
                worker_dim_id,
                worker_id,
                assignment_id,
                work_loc_geo_dim_id,
                assignment_type,
                job_dim_id,
                worker_count,
                batch_id,
                last_update_date
               )
        VALUES (
                hc_cur_rec.buyer_org_dim_id,
                hc_cur_rec.supplier_org_dim_id,
                hc_cur_rec.invoice_number,
                to_number(to_char(hc_cur_rec.invoice_date,'YYYYMMDD')||DM_CUBE_UTILS.get_data_source_id('REGULAR')||DM_CUBE_UTILS.get_top_org_id(hc_cur_rec.BUYER_ORG_DIM_ID)),
                hc_cur_rec.object_source,
                hc_cur_rec.worker_dim_id,
                hc_cur_rec.worker_id,
                hc_cur_rec.assignment_id,
                hc_cur_rec.work_loc_geo_dim_id,
                hc_cur_rec.assignment_type,
                hc_cur_rec.job_dim_id,
                hc_cur_rec.worker_count,
                ln_msg_id ,
                ld_last_update_date
               );
        WHEN OTHERS THEN
          gv_app_err_msg := 'Unable to process the Invoiced Headcount FACT ! Assignment Id = '
                            ||to_char(hc_cur_rec.assignment_id)|| ' Invoice Number = '
                            ||hc_cur_rec.invoice_number ||' Object Source = '||hc_cur_rec.object_source;
	     gv_db_err_msg := SQLERRM;
          RAISE ge_exception;
      END;
    END LOOP;

  EXCEPTION
     WHEN OTHERS THEN
      gv_app_err_msg := 'process_fact: Unknown Error !';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;    
  END process_fact;

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in creating invoice FACT
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR')
  IS
    ln_msg_id            NUMBER;
    ln_count             NUMBER;
    ln_process_cnt       NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(4000)  := NULL;
    gv_proc_name         VARCHAR2(100)   := 'dm_inv_headcount_fact_process.p_main' ;
    ln_err               NUMBER;
    ld_last_process_date DATE;
    ld_cur_process_date  DATE;

    email_sender         VARCHAR2(32) := 'mart_processing@iqnavigator.com';
    email_recipients     VARCHAR2(64) := 'data_warehouse@iqnavigator.com';
    email_subject        VARCHAR2(64) := 'Invoiced Headcount Cube FACT Errors';

    c_crlf               VARCHAR2(2)  := chr(13) || chr(10);
    p_date_id            NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'));
    ln_dim_count         NUMBER := 0 ;

  BEGIN
      ln_msg_id := DM_MSG_LOG_SEQ.nextval;

      dm_cube_utils.make_indexes_visible;

      BEGIN
       SELECT count(1)
         INTO ln_dim_count
         FROM dm_cube_jobs_log a,
              dm_cube_jobs b
        WHERE a.cube_job_id      = b.cube_job_id
          AND b.cube_object_type in ('SPEND_CUBE-DIM','CUBE-DIM')
          AND a.date_id between TO_NUMBER(TO_CHAR((SYSDATE-6),'YYYYMMDD')) and TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
          AND a.load_status     = 'FAILED';
      END;

    	IF ln_dim_count <> 0 THEN -- this means errors in DIM loads in last 7 days
       gv_app_err_msg := 'FACT did not load due to FAILED DIM process in last 7 days!';
       gv_db_err_msg  := 'Please check dm_cube_jobs_log and fix the DIM loads and then change the load status to COMPLETED from FAILED to process FACT';
       RAISE ge_exception;
    	END IF;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'dm_inv_headcount_fact_process',gv_proc_name,'I'); -- log the start of main process

     SELECT last_update_date
       INTO ld_last_process_date
       FROM dm_cube_objects
      WHERE upper(object_name)  = 'DM_INVOICED_HEADCOUNT_FACT'
        AND object_source_code = in_data_source_code;

     BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE DM_INVOICED_ASSIGNMENTS_TMP';
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to trunacte work table dm_invoiced_assignments_tmp!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE DM_INV_ASSIGNMENTS_TMP';
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to trunacte work table dm_inv_assignments_tmp!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

    DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Procedure to get all invoiced assignments',gv_proc_name,'I');

    BEGIN
       get_invoiced_assignments(ln_msg_id,ld_last_process_date,ld_cur_process_date);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to get all invoiced assignments!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

    
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Process the Invoiced Headcount FACT',gv_proc_name,'I');
     BEGIN
       process_fact(ln_msg_id);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to process the Invoiced Headcount FACT!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

     IF ld_cur_process_date IS NOT NULL THEN
        UPDATE dm_cube_objects
           SET last_update_date = ld_cur_process_date
         WHERE object_name      = 'DM_INVOICED_HEADCOUNT_FACT'
         AND object_source_code =in_data_source_code;
     END IF;

     IF ltrim(rtrim(to_char(sysdate,'DAY'))) IN ('SATURDAY','SUNDAY') THEN   
       BEGIN
    		DM_UTIL_LOG.p_log_msg(ln_msg_id,4,'Analyze FACT for Inv Headcount',gv_proc_name,'I');

      	DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_INVOICED_HEADCOUNT_FACT', ESTIMATE_PERCENT=>2, METHOD_OPT=>'FOR ALL COLUMNS SIZE 1', CASCADE=>TRUE, no_invalidate=>FALSE);

     		DM_UTIL_LOG.p_log_msg(ln_msg_id,4,null,null,'U');

          EXCEPTION
          WHEN OTHERS THEN
           gv_app_err_msg := 'Unable to analyze the Invoiced Headcount Fact! ';
           gv_db_err_msg  := SQLERRM;
           RAISE ge_exception;
       END;
     END IF;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');

     DM_UTIL_LOG.p_log_cube_load_status('DM_INVOICED_HEADCOUNT_FACT',
                                         in_data_source_code,
                                        'INVOICED_HEADCOUNT_CUBE-FACT',
                                        'COMPLETED',
                                        p_date_id);
     Commit;

  EXCEPTION
      WHEN ge_exception THEN
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_inv_headcount_fact_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
           ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_app_err_msg,
                                               gv_db_err_msg,
                                               gv_proc_name);
           DM_UTIL_LOG.p_log_cube_load_status('DM_INVOICED_HEADCOUNT_FACT',
                                               in_data_source_code,
                                              'INVOICED_HEADCOUNT_CUBE-FACT',
                                              'FAILED',
                                               p_date_id);
           DM_UTILS.send_email(email_sender,email_recipients,email_subject,'Invoiced Headcount FACT load processing Failed!'||c_crlf||'Please see the tables dm_msg_log and dm_error_log for details');
      WHEN OTHERS THEN
           gv_db_err_msg  := SQLERRM;
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_inv_headcount_fact_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');

           gv_app_err_msg := 'Unknown Error !';
           ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                        gv_app_err_msg,
                                                        gv_db_err_msg,
                                                        gv_proc_name);
           DM_UTIL_LOG.p_log_cube_load_status('DM_INVOICED_HEADCOUNT_FACT',
                                         in_data_source_code,
                                        'INVOICED_HEADCOUNT_CUBE-FACT',
                                        'FAILED',
                                         p_date_id);
           DM_UTILS.send_email(email_sender,email_recipients,email_subject,'Invoiced Headcount FACT load processing Failed'||c_crlf||'Please see the tables dm_msg_log and dm_error_log for details');
  END p_main;
END dm_inv_headcount_fact_process;
/