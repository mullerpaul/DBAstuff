create or replace PACKAGE BODY finance_revenue_maint
/******************************************************************************
 * Name: finance_revenue_maint
 * Desc: This package contains all the procedures required to
 *       load finance revenue data
 *
 * Author        Date        Version   History
 * -----------------------------------------------------------------
 * jpullifrone   04/20/2017  Initial
 * jpullifrone   04/27/2017  IQN-37512 Use Lego Invoice to get approved invoices
 * jpullifrone   04/28/2017  IQN-37523 Undoing IQN-37512.  We should join to Lego Invoice 
 *                                     in a view, not materialize approval_date in finance_revenue. 
 * jpullifrone   05/01/2017  IQN-37527 Prejoin LEGO_CAC_COLLECTION (from IQPRODD in IQPCE).
 ******************************************************************************/
AS
  gc_curr_schema             CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');
  g_source                   CONSTANT VARCHAR2(30) := 'FINANCE_REVENUE_MAINT';
  g_oc_fin_rev_job_name      CONSTANT VARCHAR2(30) := 'OCL'; --will be suffix to object_name - stands for Off-Cycle Load
  g_fin_rev_start_date       CONSTANT DATE := TO_DATE('12/31/2016 23:59:59','MM/DD/YYYY HH24:MI:SS');
  gv_error_stack             VARCHAR2(1000);  

  PROCEDURE index_maint (pi_object_name   IN lego_object.object_name%TYPE,
                         pi_process_stage IN VARCHAR2) IS
                         
  --PI_PROCESS_STAGE: BEGIN, MAINT, END
  
  v_source            VARCHAR2(61) := g_source || '.index_maint';
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('index_maint');

    IF pi_process_stage = 'MAINT' THEN

      logger_pkg.info('Gathering stats on '||pi_object_name);
      dbms_stats.gather_table_stats(ownname          => gc_curr_schema,
                                    tabname          => pi_object_name,
                                    degree           => 4);   
      logger_pkg.info('Successfully gathered stats on '||pi_object_name,TRUE);                                    
                                
    END IF;

    logger_pkg.unset_source(v_source); 
    
  END index_maint;  
  
  PROCEDURE off_cycle_fin_rev_load (pi_object_name IN lego_object.object_name%TYPE,
                                    pi_source      IN lego_object.source_name%TYPE,
                                    pi_start_ts    IN TIMESTAMP DEFAULT SYSTIMESTAMP) AS

  v_source            VARCHAR2(61) := g_source || '.off_cycle_fin_rev_load';
  lv_job_str          VARCHAR2(2000);

  BEGIN

    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('off_cycle_fin_rev_load');  

    lv_job_str :=
      'BEGIN
        logger_pkg.instantiate_logger;
        logger_pkg.set_source('''||pi_object_name||'_'||g_oc_fin_rev_job_name||''');
        finance_revenue_maint.main('''||pi_object_name||''','''||pi_source||'''); 
      EXCEPTION
        WHEN OTHERS THEN                                       
          logger_pkg.unset_source('''||pi_object_name||'_'||g_oc_fin_rev_job_name||''');                                       
      END;';

    logger_pkg.info(lv_job_str);

    DBMS_SCHEDULER.CREATE_JOB (
          job_name             => pi_object_name||'_'||g_oc_fin_rev_job_name,
          job_type             => 'PLSQL_BLOCK',
          job_action           => lv_job_str,
          start_date           => pi_start_ts,
          enabled              => TRUE,
          comments             => 'Manually populate '||pi_object_name||'-this will take a while');

    logger_pkg.info('Successfully launched job: '||lv_job_str,TRUE);
    logger_pkg.unset_source(v_source);

  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.unset_source(v_source);
      RAISE;

  END off_cycle_fin_rev_load;   


  PROCEDURE drop_oc_fin_rev_job (pi_object_name lego_object.object_name%TYPE) AS

  v_source   VARCHAR2(61) := g_source || '.drop_oc_fin_rev_job';

  BEGIN

    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('drop_oc_fin_rev_job'); 

    logger_pkg.info('Dropping job, '||pi_object_name||'_'||g_oc_fin_rev_job_name);

    DBMS_SCHEDULER.DROP_JOB(pi_object_name||'_'||g_oc_fin_rev_job_name,TRUE);  

    logger_pkg.unset_source(v_source); 

  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.warn('When others exception occurred in '||v_source,TRUE);
      logger_pkg.unset_source(v_source);
      RAISE;      

  END drop_oc_fin_rev_job;
  
  PROCEDURE load_finance_revenue AS
  
  v_source               VARCHAR2(61) := g_source || '.load_finance_revenue';
  lv_etl_date            DATE := SYSDATE;
  
  BEGIN
  
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('load_finance_revenue'); 

    logger_pkg.info('Merge data into finance_revenue'); 
    
    MERGE INTO finance_revenue r
         USING finance_revenue_stage i
            ON(r.invoiceable_expenditure_txn_id = i.invoiceable_expenditure_txn_id)
         WHEN MATCHED THEN
         UPDATE SET assignment_continuity_id    = i.assignment_continuity_id,
                    expenditure_date            = i.expenditure_date,
                    week_ending_date            = i.week_ending_date,
                    invoice_number              = i.invoice_number,
                    spend                       = i.spend,
                    currency                    = i.currency,
                    rate_identifier_id          = i.rate_identifier_id,
                    timecard_id                 = i.timecard_id,
                    payment_request_id          = i.payment_request_id,
                    assignment_bonus_id         = i.assignment_bonus_id,
                    milestone_invoice_id        = i.milestone_invoice_id,                     
                    iqn_management_fee          = i.iqn_management_fee,
                    expenditure_approval_date   = i.expenditure_approval_date,
                    buyer_adjusted_bill_rate    = i.buyer_adjusted_bill_rate,
                    supplier_reimbursement_rate = i.supplier_reimbursement_rate,
                    accounting_code             = i.accounting_code,
                    project_agreement_id        = i.project_agreement_id,
                    cac1_guid                   = i.cac1_guid,
                    etl_update_date             = lv_etl_date
         WHEN NOT MATCHED THEN
         INSERT (invoiceable_expenditure_txn_id,
                 trans_create_date,
                 trans_last_update_date,
                 buyer_org_id,
                 supplier_org_id,
                 assignment_continuity_id,
                 expenditure_date,
                 week_ending_date,
                 invoice_number,
                 spend,
                 currency,
                 rate_identifier_id,
                 timecard_id,
                 payment_request_id,
                 assignment_bonus_id,
                 milestone_invoice_id,                 
                 iqn_management_fee,
                 expenditure_approval_date,
                 buyer_adjusted_bill_rate,
                 supplier_reimbursement_rate,
                 accounting_code,
                 project_agreement_id,
                 cac1_guid,
                 etl_load_date)
        VALUES (i.invoiceable_expenditure_txn_id,
                i.trans_create_date,
                i.trans_last_update_date,
                i.buyer_org_id,
                i.supplier_org_id,
                i.assignment_continuity_id,
                i.expenditure_date,
                i.week_ending_date,
                i.invoice_number,
                i.spend,
                i.currency,
                i.rate_identifier_id,
                i.timecard_id,
                i.payment_request_id,
                i.assignment_bonus_id,
                i.milestone_invoice_id,
                i.iqn_management_fee,
                i.expenditure_approval_date,
                i.buyer_adjusted_bill_rate,
                i.supplier_reimbursement_rate,
                i.accounting_code,
                i.project_agreement_id,
                i.cac1_guid,
                lv_etl_date);

    COMMIT;
    logger_pkg.info('Successfully merged data into finance_revenue',TRUE); 

    logger_pkg.unset_source(v_source);
  
  END load_finance_revenue;  
    
  PROCEDURE fin_rev_stage (pi_start_date  IN finance_load_tracker.start_date%TYPE DEFAULT NULL,
                           pi_end_date    IN finance_load_tracker.end_date%TYPE   DEFAULT NULL,
                           po_ins_cnt    OUT PLS_INTEGER) AS

  v_source                VARCHAR2(61) := g_source || '.fin_rev_stage';


  BEGIN
    --logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('fin_rev_stage');    

    EXECUTE IMMEDIATE 'TRUNCATE TABLE finance_revenue_stage';

    logger_pkg.info('Insert into finance_revenue_stage'); 
    INSERT INTO finance_revenue_stage 
      SELECT iet.invoiceable_expenditure_txn_id,
             iet.create_date                  AS trans_create_date,
             iet.last_update_date             AS trans_last_update_date,
             ieo.buyer_business_org_fk        AS buyer_org_id,
             ieo.supplier_business_org_fk     AS supplier_org_id,
             ieo.assignment_continuity_fk     AS assignment_id,
             ie.expenditure_date              AS expenditure_date,
             ie.week_ending_date              AS week_ending_date,
             iet.current_invoice_fk           AS invoice_number,
             iet.buyer_adjusted_amount        AS spend,
             cu.description                   AS currency,
             ie.rate_identifier_fk            AS rate_identifier_id,
             ieo.timecard_fk                  AS timecard_id,
             ieo.payment_request_fk           AS payment_request_id,
             ieo.assignment_bonus_fk          AS assignment_bonus_id,
             ieo.milestone_invoice_fk         AS milestone_invoice_id,
             mgt_fee.iqn_management_fee,
             iet.create_date                  AS expenditure_approval_date,
             iet.buyer_adjusted_bill_rate,
             iet.supplier_reimbursement_rate,
             ie.accounting_code               AS accounting_code,
             ieo.project_agreement_fk         AS project_agreement_id,
             lcc1.cac_guid                    AS cac1_guid          
        FROM invoiceable_expenditure_txn@fo_iqp    iet,
             invoiceable_expenditure@fo_iqp        ie,
             invoiceable_expenditure_owner@fo_iqp  ieo,
             currency_unit@fo_iqp                  cu,  
             lego_cac_collection@fo_iqp            lcc1,			 
             (SELECT ind.invoice_fk, 
                     ind.invoiceable_expenditure_txn_fk, 
                     NVL (SUM (NVL (ili.amount, 0)), 0) iqn_management_fee
                FROM invoice_detail@fo_iqp     ind,
                     invoice_header@fo_iqp     ih,
                     invoice_line_item@fo_iqp  ili
               WHERE ind.total_management_fees_fk = ili.identifier
                 AND ih.invoice_header_id = ind.invoice_header_fk
                 AND ih.invoiceable_exp_owner_state_fk = 0
                 AND (ind.payee_business_org_fk IS NULL OR ind.payee_business_org_fk = 65997)
               GROUP BY ind.invoice_fk, 
                        ind.invoiceable_expenditure_txn_fk) mgt_fee
       WHERE ieo.invoiceable_exp_owner_id = ie.invoiceable_exp_owner_fk
         AND ie.invoiceable_expenditure_id = iet.invoiceable_expenditure_fk
         AND ie.currency_unit_fk = cu.value
         AND ie.cac_one_fk = lcc1.cac_id(+)
         AND iet.invoiceable_expenditure_txn_id = mgt_fee.invoiceable_expenditure_txn_fk(+)
         AND iet.current_invoice_fk             = mgt_fee.invoice_fk(+)
         AND (ieo.timecard_fk IS NOT NULL OR ieo.payment_request_fk IS NOT NULL OR ieo.assignment_bonus_fk IS NOT NULL OR ieo.milestone_invoice_fk IS NOT NULL)
         AND iet.create_date >  pi_start_date 
         AND iet.create_date <= pi_end_date;    
        
      po_ins_cnt := SQL%ROWCOUNT;
    
      logger_pkg.info('Successfully inserted '||po_ins_cnt||' records into finance_revenue_stage', TRUE); 

      logger_pkg.unset_source(v_source);

  END fin_rev_stage;
  
  PROCEDURE main (pi_object_name IN lego_object.object_name%TYPE,
                  pi_source      IN lego_object.source_name%TYPE,
                  pi_start_date  IN finance_load_tracker.start_date%TYPE DEFAULT NULL,
                  pi_end_date    IN finance_load_tracker.end_date%TYPE   DEFAULT NULL) AS
                           
  v_source                VARCHAR2(61) := g_source || '.main'; 
  lv_db_link_name         lego_source.db_link_name%TYPE;
  lv_src_name_short       VARCHAR2(30);  
  lv_fin_load_tracker_cnt PLS_INTEGER;
  lv_start_date           DATE;
  lv_end_date             DATE;  
  lv_bucket_end_date      DATE;
  lv_run_flag             CHAR(1);
  lv_stg_ins_count        PLS_INTEGER;
  
  BEGIN
  
    --logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('main');    

    /* get the actual dblink based on the input value of pi_source */
    --lv_db_link_name := lego_tools.get_db_link_name(pi_source);

    /* get source_name_short from lego_source to append to lego tables */
    --lv_src_name_short := lego_tools.get_src_name_short(pi_source);

    logger_pkg.info('Get start and end dates'); 

    BEGIN
      SELECT start_date, SYSDATE, run_flag
        INTO lv_start_date, lv_end_date, lv_run_flag
        FROM finance_load_tracker;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN        
        lv_start_date := g_fin_rev_start_date;
        lv_end_date := SYSDATE;
        lv_run_flag := 'N';
        
        INSERT INTO finance_load_tracker
          VALUES(lv_start_date, lv_end_date,lv_run_flag);
        COMMIT;
    END;                

    logger_pkg.info('start_date: '||lv_start_date||' end date: '||lv_end_date, TRUE); 

    WHILE lv_start_date <  lv_end_date LOOP
      
      logger_pkg.info('Get start and end bucket dates'); 

      lv_bucket_end_date := LEAST(lv_start_date + 1, lv_end_date);
      
      logger_pkg.info('Get start and end bucket dates. start_date: '||lv_start_date||' bucket end date: '||lv_bucket_end_date, TRUE);   
  
      fin_rev_stage (pi_start_date => lv_start_date,
                     pi_end_date   => lv_bucket_end_date,
                     po_ins_cnt    => lv_stg_ins_count);
                   
      logger_pkg.info('Check to see if any records were inserted into finance_revenue_stage');
    
      IF lv_stg_ins_count > 0 THEN
      
        logger_pkg.info('Yes!  Records inserted into finance_revenue_stage.  Continue...', TRUE); 
                  
        load_finance_revenue;

       ELSE
         logger_pkg.info('No records inserted into finance_revenue_stage', TRUE); 
       END IF;         
           
       lv_start_date := lv_bucket_end_date;
     
       UPDATE finance_load_tracker
          SET run_flag = 'Y',
              start_date = lv_start_date,
              end_date   = lv_end_date;  
      
       COMMIT;                        
     
     END LOOP;
    
    logger_pkg.info('Finance Revenue Processing Completed Successfully!');
    logger_pkg.info('Finance Revenue Processing Completed Successfully!',TRUE);
    logger_pkg.unset_source(v_source); 
      
  EXCEPTION
    WHEN OTHERS THEN
      gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('ROLLBACK',SQLCODE,'When others exception occurred '||lv_start_date||' : '||lv_end_date||' - '||SQLERRM,TRUE);
      logger_pkg.unset_source(v_source);
      ROLLBACK;  
      
  END main;                           

END finance_revenue_maint;
/