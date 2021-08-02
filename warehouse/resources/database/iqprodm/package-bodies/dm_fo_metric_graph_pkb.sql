CREATE OR REPLACE PACKAGE BODY dm_fo_metric_graph
/* This package conatins all the procedures required to support the metric graphs
   needed for Old UI
 */

AS
ln_prev_month_number number := TO_NUMBER(TO_CHAR(add_months(trunc(sysdate, 'MONTH'), -1),'YYYYMM'));
    ln_curr_month_number number := TO_NUMBER(TO_CHAR(sysdate,'YYYYMM'));
  PROCEDURE gen_spend(in_msg_id in number)
  /* Used to calculate buyer side metric */
  IS
  ln_err number;
  BEGIN
  
    -- Always delete current month and previous month data
    BEGIN
      DELETE DM_FO_SPEND_GRAPH where month_number in (ln_prev_month_number,ln_curr_month_number);
    EXCEPTION WHEN OTHERS THEN
               ln_err            := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                            'Unable to delete the buyer side metric',
                                                                        SQLERRM,
                                                               'DM_FO_METRIC_GRAPH.gen_spend');
    END;

    BEGIN
    INSERT INTO DM_FO_SPEND_GRAPH
    select l.ancestor_bus_org_fk                     AS    buyer_org_id,
                trunc(last_day(to_date(e.month_number,'YYYYMM')))        AS    month,
                e.month_number,
                e.supplier_bus_org_fk                         AS    supply_org_id,
                (CASE 
                      WHEN spend_category IN ('Labor', 'Time') THEN
                       2
                      WHEN spend_category IN ('Milestones') THEN
                       1
                      ELSE
                      0
                    END) AS    amount_category,
                sum(e.buyer_adjusted_amount) 		AS	amount,
              e.currency 							AS	currency_code,
              TRUNC(SYSDATE)
    from      dm_spend_summary e,
           DM_BUS_ORG_LINEAGE l
          where e.BUYER_BUS_ORG_FK = l.DESCENDANT_BUS_ORG_FK
            and e.month_number in (ln_prev_month_number,ln_curr_month_number)
    group by      l.ancestor_bus_org_fk, trunc(last_day(to_date(e.month_number,'YYYYMM'))) ,e.month_number,e.supplier_bus_org_fk ,1,e.currency,
    (CASE 
                      WHEN spend_category IN ('Labor', 'Time') THEN
                       2
                      WHEN spend_category IN ('Milestones') THEN
                       1
                      ELSE
                      0
                    END) ,TRUNC(SYSDATE);
    EXCEPTION WHEN OTHERS THEN
     ln_err            := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                              'Unable to insert the buyer side metric',
                                                              SQLERRM,
                                                           'DM_FO_METRIC_GRAPH.gen_billing');
    END;

  END gen_spend;

  PROCEDURE gen_billing(in_msg_id in number)
    /* Used to calculate supplier side metric */

  IS
  ln_err number;
  BEGIN
      -- Always delete current month and previous month data
      BEGIN
        DELETE DM_FO_BILL_GRAPH where month_number in (ln_prev_month_number,ln_curr_month_number);
      EXCEPTION WHEN OTHERS THEN
           ln_err            := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                                    'Unable to delete the supplier side metric',
                                                                    SQLERRM,
                                                           'DM_FO_METRIC_GRAPH.gen_billing');
      END;

      BEGIN
      INSERT INTO DM_FO_BILL_GRAPH
      select l.ancestor_bus_org_fk                     AS    supply_org_id,
                  trunc(last_day(to_date(e.month_number,'YYYYMM')))        AS    month,
                  e.month_number,
                  e.buyer_bus_org_fk                         AS    buyer_org_id,
                  (CASE 
                      WHEN spend_category IN ('Labor', 'Time') THEN
                       2
                      WHEN spend_category IN ('Milestones') THEN
                       1
                      ELSE
                      0
                    END)                                          AS    amount_category,
                  sum(e.supplier_reimbursement_amount) 		AS	amount,
                e.currency 							AS	currency_code,
                TRUNC(SYSDATE)
      from      dm_spend_summary e,
             DM_BUS_ORG_LINEAGE l
            where e.SUPPLIER_BUS_ORG_FK = l.DESCENDANT_BUS_ORG_FK
              and e.month_number in (ln_prev_month_number,ln_curr_month_number)
      group by      l.ancestor_bus_org_fk, trunc(last_day(to_date(e.month_number,'YYYYMM'))) ,e.month_number, e.buyer_bus_org_fk ,1,e.currency,
      (CASE 
                      WHEN spend_category IN ('Labor', 'Time') THEN
                       2
                      WHEN spend_category IN ('Milestones') THEN
                       1
                      ELSE
                      0
                    END) ,TRUNC(SYSDATE);

    EXCEPTION WHEN OTHERS THEN
     ln_err            := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                              'Unable to insert the supplier side metric',
                                                              SQLERRM,
                                                           'DM_FO_METRIC_GRAPH.gen_billing');
    END;

  END gen_billing;


  PROCEDURE gen_contractor_hours(in_msg_id IN NUMBER)
      /* Used to calculate Buyer side contractor hours*/

  IS
   ln_err number;
  BEGIN
  -- Always delete current month and previous month data
  BEGIN
   DELETE DM_FO_CONTRACTOR_HOURS where month_number in (ln_prev_month_number,ln_curr_month_number);
  EXCEPTION WHEN OTHERS THEN
   ln_err            := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                              'Unable to delete the contractor hours',
                                                              SQLERRM,
                                                           'DM_FO_METRIC_GRAPH.gen_contractor_hours');
  END;

  BEGIN
  INSERT INTO DM_FO_CONTRACTOR_HOURS
  select
      buyer_org_id,
      month, creation_month, month_number,hours, TRUNC(SYSDATE)
    from
  (
    select l.ancestor_bus_org_fk buyer_org_id, trunc(last_day(to_date(te.month_number,'YYYYMM'))) month,
          trunc(last_day(to_date(te.month_number,'YYYYMM'))) creation_month,te.month_number, sum(te.quantity) hours
    from      dm_spend_summary te,
               DM_BUS_ORG_LINEAGE l
              where te.BUYER_BUS_ORG_FK = l.DESCENDANT_BUS_ORG_FK
            and te.month_number in (ln_prev_month_number,ln_curr_month_number)
            group by l.ancestor_bus_org_fk ,trunc(last_day(to_date(te.month_number,'YYYYMM'))) ,
          trunc(last_day(to_date(te.month_number,'YYYYMM'))) ,te.month_number);

  EXCEPTION WHEN OTHERS THEN
   ln_err            := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                              'Unable to insert the contractor hours',
                                                              SQLERRM,
                                                           'DM_FO_METRIC_GRAPH.gen_contractor_hours');
  END;

 END gen_contractor_hours;

 PROCEDURE main
 
 IS
 
 ln_msg_id number;
 ln_err number;
 gv_proc_name varchar2(100) := 'DM_FO_METRIC_GRAPH';
 gv_app_err_msg VARCHAR2(2000);
 gv_db_err_msg  VARCHAR2(2000);
 ge_exception EXCEPTION;
 BEGIN
      --
      -- Get the sequence reuired for logging messages
      --
      BEGIN
        SELECT DM_MSG_LOG_SEQ.nextval
          INTO ln_msg_id
          FROM dual;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'Spend Metric graph population for buyer',gv_proc_name,'I');
     BEGIN
         gen_spend(ln_msg_id);
     EXCEPTION
         WHEN OTHERS THEN
              gv_app_err_msg := 'Unable to execute the procedure to populate spend metric for buyer!';
              gv_db_err_msg := SQLERRM;
     	 RAISE ge_exception;
     END;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Billing Metric graph population for supplier',gv_proc_name,'I');
     BEGIN
         gen_billing(ln_msg_id);
     EXCEPTION
         WHEN OTHERS THEN
              gv_app_err_msg := 'Unable to execute the procedure to populate billing metric for supplier!';
              gv_db_err_msg := SQLERRM;
     	 RAISE ge_exception;
     END;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Contractor hours for buyer',gv_proc_name,'I');
     BEGIN
         gen_contractor_hours(ln_msg_id);
     EXCEPTION
         WHEN OTHERS THEN
              gv_app_err_msg := 'Unable to execute the procedure to populate contractor hours for buyer!';
              gv_db_err_msg := SQLERRM;
     	 RAISE ge_exception;
     END;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

     Commit;
     
     --
     --call the Fo procedure put the data
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,4,'Migrate the data to FO',gv_proc_name,'I');
     BEGIN
          fo_dm_metric_graph.main@FO_R(ln_msg_id);
     EXCEPTION
         WHEN OTHERS THEN
              gv_app_err_msg := 'Unable to execute the procedure to migrate the data to FO!';
              gv_db_err_msg := SQLERRM;
     	 RAISE ge_exception;
     END;
     DM_UTIL_LOG.p_log_msg(ln_msg_id,4,null,null,'U');
     Commit;

    EXCEPTION
            WHEN ge_exception THEN
              --
              -- user defined exception, Log and raise the application error.
              --
              Rollback;

              ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                 gv_app_err_msg,
                                                 gv_db_err_msg,
                                                 gv_proc_name);
              --
              -- Log the final load status for FO
              --
              

            WHEN OTHERS THEN
              --
              -- Unknown exception, Log and raise the application error.
              --
              Rollback;

              gv_app_err_msg := 'Unknown Error !';
              gv_db_err_msg  := SQLERRM;
              ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                           gv_app_err_msg,
                                                           gv_db_err_msg,
                                                           gv_proc_name);

 END main;
END dm_fo_metric_graph;
/