CREATE OR REPLACE PACKAGE BODY lego_util
AS

/* 25 Jul 2013 MDunlap - Remove References to LEGO_APPROVALs Process as it is now a sql toggle refresh.  
   19 Feb 2014 JPullifrone - Removed Shell-specific procedures. IQN-13853 Release 12.0.1 */

gc_curr_schema       CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');
gv_months_in_refresh PLS_INTEGER := NVL(lego_refresh_mgr_pkg.get_lego_parameter_num_value(pi_parameter_name => 'months_in_refresh'),24);
gv_error_stack       VARCHAR2(1000);

/*******************************************************************************
 *PROCEDURE NAME : remove_invoice_data
 *DATE CREATED   : February 13, 2015
 *AUTHOR         : Joe Pullifrone
 *PURPOSE        : This procedure accepts an invoice_id and invoice_date (current invoice_date) 
                   as input with the purpose of deleting all records from any Lego
                   table associated with those values.  The reason for the dynamic SQL is because 
                   one does not know whether any of the Lego tables exist.  The 
                   tables tied to the LEGO_INVOICE object are Toggle tables and it is possible 
                   that either one, both, or neither table exists.  The table tied to
                   the LEGO_INVOICE_DETAIL must exist otherwise this package would be invalid
                   and thus would not run.
 *MODIFICATIONS:
 *              
 ******************************************************************************/
  PROCEDURE remove_invoice_data (i_invoice_id            NUMBER,
                                 i_current_invoice_date  DATE) IS
  
    c_source                   CONSTANT VARCHAR2(30) := 'lego_util.remove_invoice_data';
    v_table_name               VARCHAR2(30);
    
    CURSOR cur_tbl_list IS 
      SELECT lr.refresh_object_name_1 AS table_name
        FROM user_tables ut, lego_refresh lr
       WHERE ut.table_name = lr.refresh_object_name_1
         AND lr.object_name = 'LEGO_INVOICE'
      UNION ALL
      SELECT lr.refresh_object_name_2
        FROM user_tables ut, lego_refresh lr
       WHERE ut.table_name = lr.refresh_object_name_2
         AND lr.object_name = 'LEGO_INVOICE'
      UNION ALL
      SELECT table_name 
        FROM user_tables
       WHERE table_name = 'LEGO_INVOICE_DETAIL'; 
  
  BEGIN
  
    --Only including instantiation of logger here since this proc will mainly be
    --called from a HF script and it is hard to enforce using it in the HF script.
    logger_pkg.instantiate_logger;  
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(c_source);
       
    
    FOR rec_tbl_list IN cur_tbl_list LOOP
 
      v_table_name := rec_tbl_list.table_name; 
        
      logger_pkg.info('deleting data from table: '||v_table_name||' for invoice_id: '|| i_invoice_id||' with invoice_date: '||i_current_invoice_date);
      
      EXECUTE IMMEDIATE 'DELETE FROM '|| v_table_name ||
                        ' WHERE invoice_date = :1
                            AND invoice_id   = :2'
                  USING i_current_invoice_date, i_invoice_id;  
      
      logger_pkg.info('deleted '||TO_CHAR(SQL%ROWCOUNT)||' rows from table: '||v_table_name||' for invoice_id: '|| i_invoice_id ||' with invoice_date: '|| i_current_invoice_date, TRUE);
    
    END LOOP;
    
    logger_pkg.unset_source(c_source);
   
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_error_stack := SQLERRM || chr(10) ||
                        dbms_utility.format_error_backtrace;
      logger_pkg.fatal('ROLLBACK',
                       SQLCODE,
                       'Error deleting data from table: '||v_table_name||' for invoice_id: '|| i_invoice_id||' with invoice_date: '||i_current_invoice_date||', '||
                       SQLERRM);
                       
      logger_pkg.unset_source(c_source);
      RAISE;
  
  END remove_invoice_data;
  
  ----------------------------------------------------------------------------------
  FUNCTION most_recently_loaded_table(i_lego_name lego_refresh.object_name%TYPE)
  /* Function which returns the name of the most recently built base table for 
     toggle legos.  This is useful if your procedure needs to build a lego based 
     on a previously built lego. */
    RETURN VARCHAR2 IS
    lv_return              VARCHAR2(30) := NULL;
    lv_older_base_table    VARCHAR2(30);

    le_invalid_object_name EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_invalid_object_name, -44002);
  BEGIN
    /* For SQL toggle, PROC toggle, and PROC toggle args legos, we can get the name 
    of the most recently loaded base table from lego_refresh_history.toggle_refreshed_table.  
    In most cases, the lego checked should be a parent lego to this lego!! */
    SELECT toggle_refreshed_table
      INTO lv_return
      FROM (SELECT job_runtime,
                   toggle_refreshed_table,
                   MAX(job_runtime) over() AS max_runtime
              FROM lego_refresh_history
             WHERE object_name = i_lego_name
               AND toggle_refreshed_table IS NOT NULL
               AND status IN ('released','refresh complete'))
     WHERE job_runtime = max_runtime;
  
    RETURN dbms_assert.sql_object_name(lv_return);
  
    EXCEPTION
      WHEN no_data_found
        THEN
        /*  Probably an incorrect input.  But this can also happen if we are checking  
        for a lego that is not a parent to this lego and it hasn't run yet.  
        Either way, we are in trouble and must fail.  */
          logger_pkg.fatal('Cannot find most recently refreshed table for ' || i_lego_name);
          raise_application_error(-20100, 'Cannot find most recently refreshed table for ' || i_lego_name); 

      WHEN le_invalid_object_name
        THEN
        /* The table to be returned does not actually exist! We've seen this happen in the following circumstances: 
             A lego in a allow_partial_release group refreshes but does not release.
             The lego is restarted, dropping and recreating the toggle base table.
             While our lego is being refreshed, a lego in a different group which depends on our lego calls this function.
             This function returns the name of the table built in the previous refresh; but that doesn't exist now because its being re-built now.
        To fix this, I've added a call to dbms_assert and this exception block.  This will return the other base table name. */
          SELECT base_table_name
            INTO lv_older_base_table
            FROM (SELECT refresh_object_name_1 AS base_table_name
                    FROM lego_refresh
                   WHERE object_name = i_lego_name
                   UNION ALL
                  SELECT refresh_object_name_2 AS base_table_name
                    FROM lego_refresh
                   WHERE object_name = i_lego_name)
           WHERE base_table_name <> lv_return;

          logger_pkg.warn('Most recently refreshed table for ' || i_lego_name ||
                          ' is ' || lv_return || ' but that table does not exist!  Using ' || 
                          lv_older_base_table || ' instead.');

          RETURN lv_older_base_table;                

  END most_recently_loaded_table;

  ----------------------------------------------------------------------------------
  FUNCTION get_exadata_storage_clause(i_lego_name lego_refresh.object_name%TYPE)
  /* Function which returns exadata_storage_clause value for a given lego. */
    RETURN VARCHAR2 IS
    
    lv_return lego_refresh.exadata_storage_clause%TYPE;
  BEGIN
    SELECT exadata_storage_clause
      INTO lv_return
      FROM lego_refresh
     WHERE object_name = upper(i_lego_name);
    
    RETURN lv_return;

  EXCEPTION
    WHEN no_data_found
      THEN RETURN NULL;

  END get_exadata_storage_clause;        
    
  ----------------------------------------------------------------------------------
  FUNCTION get_partition_clause(i_lego_name lego_refresh.object_name%TYPE)
  /* Function which returns partition_clause value for a given lego. */
    RETURN VARCHAR2 IS
    
    lv_return lego_refresh.partition_clause%TYPE;
  BEGIN
    SELECT partition_clause
      INTO lv_return
      FROM lego_refresh
     WHERE object_name = upper(i_lego_name);
    
    RETURN lv_return;

  EXCEPTION
    WHEN no_data_found
      THEN RETURN NULL;

  END get_partition_clause;        

/*******************************************************************************
 *PROCEDURE NAME : load_lego_inv_det_worker(fka, load_lego_invoice_detail)
 *DATE CREATED   : August 15, 2012
 *AUTHOR         : Joe Pullifrone
 *PURPOSE        : Grabs new approved invoices from INVOICE table and loads
 *                 them into the LEGO_INVOICE and LEGO_INVOICE_DETAIL table.
 *                 Also populates invoices that fail in EXTRACT_INIT in a
 *                 separate error table in addition to reprocessing them.
 *MODIFICATIONS:
 *               17 Feb 2013 J.Pullifrone added NULL to initial cursor - Release 11.2
 *               27 Feb 2013 J.Pullifrone added more debug info.
 *               added exception section for cursor to get object_name and job_runtime.
 *               added date ranges to init cursor to allow for multi-threading.
 *               removed invoice detail collection and instead am using a 
 *               insert into select.
 *               also changed so that this procedure is now being called by
 *               load_lego_invoice_detail. Rel 11.1.2 
 *               06 Mar 2013 adjusted_bill_rate in INSERT INTO SELECT statement
 *               was out of place, causing invalid values for OT AND REGULAR
 *               hours.  Rel 11.1.2.  
 *               02 Apr 2013 J.Pullifrone remove references to USER. Rel 11.2    
 *               11 Apr 2013 Adding logic to handle adjustment invoices - RJ-633 - Rel 11.2.1
 *               07 May 2013 Adding clause in CURSOR, rc_inv, to exclude invoices
 *                           that may have already been loaded in LEGO_INVOICE_DETAIL.
 *                           Dups were being loaded when the two base tables got out of sync.
 *                           This will prevent that from happening.  RJ-761 - Rel 11.2.1     
 *               05 Jun 2013 Tightened up logic for choosing which invoices to load into 
 *                           LEGO_INVOICE_DETAIL during typical load scenario- IQN-3213 - Rel 11.3.0  
 *               18 Jun 2013 Adding new column to LEGO_INVOICE_DETAIL, org_sub_classification - IQN-4902 Rel 11.3.0
 *               25 Jun 2013 Adding two new columns to LEGO_INVOICE_DETAIL, shell_invoice_number, shell_invoice_iqn_number
 *                           Also, in v_rc_curr_stmnt, added MINUS to exclude those invoices in the error table - mainly 
 *                           for re-load scenarios IQN-4987 Rel 11.3.0 
 *               02 Jul 2013 Remove NVL from join AND NVL(gis.company_code,'x') = NVL(gtt.cac1_segment1_value,'x'). I spoke
 *                           with Anel and she said we can ignore if gis.company_code IS NULL.  IQN-5604 , Rel 11.3.0    
 *               09 Aug 2013 Replaced query in rec_inv cursor that looked at invoiceable_exp_owner_state_fk in invoice_header
 *                           and replaced it with query that checks expenditure_count in invoice. IQN-6582 - Rel 11.3.2     
 *               16 Aug 2013 Added CAC Descriptions to LEGO_INVOICE_DETAIL. Removed code that is mistakenly being
 *                           run inside loop (removed from lego_laod_inv_det_worker to load_lego_invoice_detail) IQN-6705 - Rel 11.3.2
 *               05 Sep 2013 Removed redundant join clause from gtt.invoice_id = gis.invoice_id (Shell Inv Number) - Rel 11.4
 *               26 Mar 2014 Added joins to rate_identifier (to avoid join in view) and rate_unit (to avoid CASE stmt in view.
 *                           Added TRUNC functions to expenditure_date and week_ending_date as well.  Also adding partition
 *                           drop logic for LEGO_INVOICE_DETAIL.  rc_inv also needs date filter as well.  IQN-14532 and IQN-14482 - Release 12.0.2 
 *               04 Sep 2014 Add new column to EXTRACT_BASE_GTT and thus LEGO_INVOICE_DETAIL, IQN-18776 - Release 12.2.0    
 *               24 Sep 2015 Removed code which drops old partitions.  IQN-28112
 ******************************************************************************/

  PROCEDURE load_lego_inv_det_worker (i_is_init_load     CHAR     DEFAULT 'N',
                                      i_date_range_min   DATE     DEFAULT NULL,
                                      i_date_range_max   DATE     DEFAULT NULL,
                                      i_lego_invoice_2   VARCHAR2 DEFAULT NULL,
                                      i_lego_object_name VARCHAR2,
                                      i_job_runtime      TIMESTAMP) IS

  rc_inv     SYS_REFCURSOR;

   
  TYPE rec_inv IS RECORD (
    invoice_id     invoice.invoice_id%TYPE,
    invoice_type   VARCHAR2(30));
  
  TYPE t_inv IS TABLE OF rec_inv INDEX BY PLS_INTEGER;
    v_inv_arr     t_inv;

  v_source                      VARCHAR2(61) := 'load_lego_inv_det_worker';
  v_err_no                      NUMBER;
  v_err_msg                     VARCHAR2(2000);
  v_rc_curr_stmnt               VARCHAR2(2000);
  v_lego_invoice_1              lego_refresh.refresh_object_name_1%TYPE;
  v_lego_invoice_2              lego_refresh.refresh_object_name_2%TYPE;  
  v_last_invoice_loaded         NUMBER;
  v_last_invoice_loaded_clause  VARCHAR2(300);
  v_inv_det_coll_limit          PLS_INTEGER := 1000;
  v_adjustment_invoice_id       NUMBER;
  v_inv_det_reprocess_max_cnt   NUMBER;
  v_ins_inv_det_str1            CLOB;
  v_ins_inv_det_str2            CLOB;

  BEGIN
    logger_pkg.set_level('DEBUG');
    logger_pkg.set_source(v_source);
   
    IF i_is_init_load = 'Y' THEN
     
      logger_pkg.set_code_location('Get last invoice loaded');
      --what was the last invoice loaded into LEGO_INVOICE_DETAIL?  
      --we use the MIN function because invoices are loaded from highest to lowest
      --if MIN(invoice_id) is NOT NULL then build a where clause to add to the re_inv cursor.
      --if MIN(invoice_id) is NULL then populate NULL in v_last_invoice_loaded_clause 
      SELECT last_invoice_loaded, NVL2(last_invoice_loaded, ' AND invoice_id < '||last_invoice_loaded, NULL)
        INTO v_last_invoice_loaded, v_last_invoice_loaded_clause
        FROM (SELECT MIN(invoice_id) last_invoice_loaded
                FROM lego_invoice_detail
               WHERE invoice_date >= i_date_range_min
                 AND invoice_date <  i_date_range_max);
      logger_pkg.debug('Last invoice loaded: '||v_last_invoice_loaded||'; Clause appended: '||v_last_invoice_loaded_clause);                 
                
      v_rc_curr_stmnt :=   'SELECT invoice_id, NULL
                              FROM '||i_lego_invoice_2||' 
                             WHERE invoice_date >= TO_DATE('''||TO_CHAR(i_date_range_min,'MM/DD/YYYY')||''',''MM/DD/YYYY'')
                               AND invoice_date <  TO_DATE('''||TO_CHAR(i_date_range_max,'MM/DD/YYYY')||''',''MM/DD/YYYY'') '||
                               v_last_invoice_loaded_clause||
                           ' MINUS 
                            SELECT invoice_id, NULL
                              FROM lego_invoice_detail_error
                             ORDER BY invoice_id DESC';
      
      
      logger_pkg.debug('Invoice RefCursor: '||v_rc_curr_stmnt); 
      
      OPEN rc_inv FOR
        v_rc_curr_stmnt;

    ELSE --typical load scenario

      logger_pkg.set_code_location('Check for LEGO_INVOICE_1 and LEGO_INVOICE_2');
      --make sure that BOTH Toggle Refresh (LEGO_INVOICE_1 and LEGO_INVOICE_2) tables exist
      --if both do not exist, exception will be raised
      SELECT UPPER(lr.refresh_object_name_1), UPPER(lr.refresh_object_name_2)
        INTO v_lego_invoice_1, v_lego_invoice_2
        FROM lego_refresh lr, user_tables ut1, user_tables ut2
       WHERE UPPER(lr.refresh_object_name_1) = ut1.table_name
         AND UPPER(lr.refresh_object_name_2) = ut2.table_name
         AND UPPER(lr.object_name) = 'LEGO_INVOICE';


      --get invoice detail max reprocess count value - default to 6 if for some reason NULL is returned
      v_inv_det_reprocess_max_cnt := NVL(lego_refresh_mgr_pkg.get_lego_parameter_num_value('inv_det_reprocess_max_cnt'),6);
      
      logger_pkg.set_code_location('Get invoices that need to have their details loaded');
      OPEN rc_inv FOR '      
        SELECT /*+parallel(4)*/
               invoice_id, invoice_type
          FROM (
                ((((
                    --find a unique list of invoice_id in tables 1 and 2 that do not exist in LEGO_INVOICE_DETAIL_ERROR
                    SELECT invoice_id, NULL AS invoice_type
                      FROM '||v_lego_invoice_1||'
                     WHERE invoice_date >= ADD_MONTHS(TRUNC(SYSDATE), -1 * '||gv_months_in_refresh||' ) 
                    UNION
                    SELECT invoice_id, NULL AS invoice_type
                      FROM '||v_lego_invoice_2||' 
                     WHERE invoice_date >= ADD_MONTHS(TRUNC(SYSDATE), -1 * '||gv_months_in_refresh||' ) )                  
                   MINUS
                   SELECT invoice_id, NULL AS invoice_type
                     FROM lego_invoice_detail_error
                                           
                  )--combine with invoices in the error table to be reprocessed
                  UNION ALL
                  SELECT invoice_id, ''FAILED'' AS invoice_type
                    FROM lego_invoice_detail_error
                   WHERE reprocess_count <= '||v_inv_det_reprocess_max_cnt||'
                                     
                 )--minus out any invoices that may have already been inserted into detail table
                 MINUS
                 SELECT invoice_id, NULL AS invoice_type
                   FROM lego_invoice_detail
                  WHERE invoice_date >= ADD_MONTHS(TRUNC(SYSDATE), -1 * '||gv_months_in_refresh||' )                   
                                   
                )--minus out any invoices that have no expenditures
                MINUS
                SELECT invoice_id, NULL AS invoice_type
                  FROM invoice
                 WHERE invoice_date >= ADD_MONTHS(TRUNC(SYSDATE), -1 * '||gv_months_in_refresh||' )
                   AND expenditure_count = 0
               )';


    END IF;

    FETCH rc_inv BULK COLLECT INTO v_inv_arr;
    CLOSE rc_inv;

    --For all new invoices, call extract_init.ext_start to load them into LEGO_INVOICE_DETAIL

    FOR i IN 1 .. v_inv_arr.COUNT LOOP
    
      --check to see if this invoice is an adjustment.
      --if it is then an invoice_id will be returned
      --and passed into extract_init.ext_start as an
      --adjustement invoice
      BEGIN
        SELECT invoice_id
          INTO v_adjustment_invoice_id
          FROM invoice AS OF SCN lego_refresh_mgr_pkg.get_scn()
         WHERE invoice_id = v_inv_arr(i).invoice_id
           AND is_adjustment = 1;  
      EXCEPTION
        WHEN OTHERS THEN
        v_adjustment_invoice_id := NULL;
      END;     

      extract_init.ext_start(
          sinextractid         => 'LEGO_INVOICE_DETAIL',
          ninvoiceid           => CASE WHEN v_adjustment_invoice_id IS NULL THEN v_inv_arr(i).invoice_id ELSE NULL END,
          nadjinvoiceid        => v_adjustment_invoice_id,
          ninvsuppliersubsetid => NULL,
          ninvbuyersubsetid    => NULL,
          stables2wipe         => NULL,
          ninmsgid             => rpt_msg_log_seq.nextval,
          ninmsgsubseq         => '1',
          nerrno               => v_err_no,
          serrmsg              => v_err_msg,
          sexecutingobject     => i_lego_object_name
          );


      IF v_err_no IS NULL THEN       

        v_ins_inv_det_str1 := 
         q'{INSERT /*+append*/ INTO lego_invoice_detail
            SELECT gtt.invoice_id
                  ,gtt.extract_id
                  ,gtt.msg_id
                  ,gtt.invoice_detail_id
                  ,gtt.invoice_header_fk                              AS invoice_header_id
                  ,gtt.invoiceable_expenditure_fk                     AS invoiceable_expenditure_id
                  ,gtt.invoiceable_expenditure_txn_fk                 AS invoiceable_expenditure_txn_id
                  ,gtt.expense_report_fk                              AS expense_report_id
                  ,gtt.timecard_fk                                    AS timecard_id
                  ,gtt.payment_request_fk                             AS payment_request_id
                  ,gtt.payment_request_invdtl_fk                      AS payment_request_invdtl_id
                  ,gtt.milestone_invoice_fk                           AS milestone_invoice_id
                  ,gtt.assignment_continuity_fk                       AS assignment_continuity_id
                  ,gtt.expenditure_number
                  ,gtt.supplier_management_fees_fk                    AS supplier_management_fees_id
                  ,gtt.buyer_management_fees_fk                       AS buyer_management_fees_id
                  ,gtt.total_management_fees_fk                       AS total_management_fees_id
                  ,gtt.buyer_fee_amount
                  ,gtt.supplier_fee_amount
                  ,gtt.total_fee_amount
                  ,gtt.buyer_invoice_number
                  ,gtt.is_transaction_fees_subset
                  ,gtt.currency_unit_fk                               AS currency_unit_id
                  ,gtt.currency_code
                  ,gtt.rate_identifier_fk                             AS rate_identifier_id
                  ,ri.bo_expenditure_type                             AS rate_identifier_name
                  ,gtt.quantity                  
                  ,gtt.supplier_reimbursement_rate                    AS supplier_reimb_bill_rate
                  ,gtt.regular_hours
                  ,gtt.ot_hours
                  ,gtt.dt_hours
                  ,gtt.buyer_adjusted_bill_rate                       AS adjusted_bill_rate
                  ,gtt.ot_rate                                        AS adjusted_ot_rate
                  ,gtt.dt_rate                                        AS adjusted_dt_rate
                  ,gtt.expenditure_type
                  ,gtt.invoice_transaction_type
                  ,gtt.expense_type_name
                  ,gtt.payment_type_name
                  ,gtt.flexrate_type
                  ,gtt.flexrate_buyer_amount
                  ,gtt.flexrate_supplier_amount
                  ,gtt.flexrate_exp_type_name_fk                      AS flexrate_exp_type_name_id
                  ,gtt.reversed_expenditure_txn_fk                    AS reversed_expenditure_txn_id
                  ,gtt.invoice_date
                  ,TRUNC(gtt.week_ending_date)                        AS week_ending_date
                  ,TRUNC(gtt.expenditure_date)                        AS expenditure_date
                  ,gtt.bill_through_date
                  ,gtt.buyer_bus_org_fk                               AS buyer_bus_org_id
                  ,la1.address_guid                                   AS buyer_bus_org_bill_to_add_guid
                  ,gtt.buyer_bus_org_tax_id
                  ,gtt.supplier_bus_org_fk                            AS supplier_bus_org_id
                  ,la2.address_guid                                   AS suppl_bus_org_pymnt_add_guid
                  ,gtt.supplier_bus_org_tax_id
                  ,gtt.payment_amount
                  ,gtt.markup_amount
                  ,gtt.bill_amount
                  ,gtt.buyer_adjusted_amount
                  ,gtt.supplier_reimbursement_amount
                  ,gtt.candidate_id
                  ,gtt.unique_resource_id
                  ,gtt.state_fk                                       AS state_id
                  ,gtt.is_adjustment
                  ,gtt.customer_supplier_internal_id
                  ,gtt.invoiced_buyer_supplier_id
                  ,gtt.rate_unit_fk                                   AS rate_unit_id
                  ,ru.description                                     AS rate_unit_desc
                  ,gtt.base_bill_rate                                 AS reg_bill_rate
                  ,gtt.service_identifier
                  ,gtt.assignment_bonus_fk                            AS assignment_bonus_id
                  ,gtt.direct_hire_agmt_fk                            AS direct_hire_agmt_id
                  ,gtt.reversing_expenditure_txn_fk                   AS reversing_expenditure_txn_id
                  ,gtt.is_for_backoffice_reversal
                  ,gtt.reversed_flexrate_inv_dtl_fk                   AS reversed_flexrate_inv_dtl_id
                  ,gtt.project_agreement_fk                           AS project_agreement_id
                  ,gtt.buyer_taxable_country                          AS buyer_taxable_country_id
                  ,gtt.accounting_code
                  ,gtt.cac1_segment1_value
                  ,gtt.cac1_segment2_value
                  ,gtt.cac1_segment3_value
                  ,gtt.cac1_segment4_value
                  ,gtt.cac1_segment5_value
                  ,gtt.cac2_segment1_value
                  ,gtt.cac2_segment2_value
                  ,gtt.cac2_segment3_value
                  ,gtt.cac2_segment4_value
                  ,gtt.cac2_segment5_value
                  ,gtt.invalidating_event_desc_fk                     AS invalidating_event_desc_id
                  ,gtt.base_pay_rate                                  AS reg_pay_rate
                  ,gtt.flexrate_mgmt_fee_amount
                  ,gtt.tax_rule_fk                                    AS tax_rule_id
                  ,gtt.exp_detail_comment
                  ,gtt.expenditure_category
                  ,gtt.invoiced_agreement_fk                          AS invoiced_agreement_id
                  ,gtt.flexrate_rule_usage_fk                         AS flexrate_rule_usage_id
                  ,gtt.flex_rule_fk                                   AS flex_rule_id
                  ,gtt.iqn_invoice_number
                  ,gtt.buyer_tax_amount
                  ,gtt.supplier_tax_amount
                  ,gtt.mgmt_fee_tax_amount
                  ,gtt.mgmt_fee_rebate_amount
                  ,gtt.is_vat_applied_on_fee
                  ,gtt.buyer_discount_amount
                  ,gtt.supplier_discount_amount
                  ,gtt.invoiceable_exp_owner_state_fk                 AS invoiceable_exp_owner_state_id
                  ,gtt.payee_business_org_fk                          AS payee_org_id
                  ,gtt.is_iqn_mgmt_fee_payee
                  ,gtt.expense_report_line_item_fk                    AS expense_report_line_item_id
                  ,gtt.milestone_invoice_detail_fk                    AS milestone_invoice_detail_id
                  ,gtt.timecard_entry_fk                              AS timecard_entry_id
                  ,gtt.buyer_fee_calc_percent
                  ,gtt.supplier_fee_calc_percent
                  ,gtt.total_fee_calc_percent
                  ,gtt.approval_date
                  ,gtt.partial_rate_percent
                  ,gtt.position_title
                  ,gtt.flexrate_buyer_rate
                  ,gtt.cs_hours
                  ,gtt.cs_rate                                        AS adjusted_cs_rate
                  ,gtt.purchase_order
                  ,gtt.custom_invoiceable_fk                          AS custom_invoiceable_id
                  ,gtt.ariba_network_id
                  ,gtt.manager_user_fk                                AS hiring_mgr_person_id
                  ,gtt.sales_tax_amt_rollup
                  ,gtt.discount_amt_rollup
                  ,gtt.mfr_amt_rollup
                  ,gtt.sales_tax_amt_on_fee_rollup
                  ,gtt.debit_credit_indicator
                  ,gtt.curr_conv_info_fk                              AS curr_conv_info_id
                  ,gtt.org_sub_classification
                  ,gtt.cac1_segment1_desc
                  ,gtt.cac1_segment2_desc
                  ,gtt.cac1_segment3_desc
                  ,gtt.cac1_segment4_desc
                  ,gtt.cac1_segment5_desc
                  ,gtt.cac2_segment1_desc
                  ,gtt.cac2_segment2_desc
                  ,gtt.cac2_segment3_desc
                  ,gtt.cac2_segment4_desc
                  ,gtt.cac2_segment5_desc
                  ,NVL(gtt.assignment_continuity_fk, -1)                             AS secjn_assignment_continuity_id
                  ,NVL(gtt.project_agreement_fk, -1)                                 AS secjn_project_agreement_id
                  ,COALESCE (gtt.assignment_continuity_fk, gtt.project_agreement_fk) AS secjn_proj_agree_assgn_cont_id
              FROM extract_base_gtt        gtt,
                   rate_identifier         ri,
                   rate_unit               ru,
                   lego_contact_address_vw la1,
                   lego_contact_address_vw la2                                                 
             WHERE gtt.rate_identifier_fk              = ri.rate_identifier_id(+)
               AND gtt.rate_unit_fk                    = ru.value(+)
               AND gtt.buyer_bus_org_bill_to_addr_fk   = la1.contact_info_id(+)
               AND la1.address_type(+)                 = 'Payment'                                                       
               AND gtt.supplier_bus_org_pymnt_addr_fk  = la2.contact_info_id(+)
               AND la2.address_type(+)                 = 'Payment'}';

      
        logger_pkg.debug (v_ins_inv_det_str1||v_ins_inv_det_str2);
        EXECUTE IMMEDIATE v_ins_inv_det_str1||v_ins_inv_det_str2;

          --delete the failed invoices from lego_invoice_detail_error since
          --now they reprocessed successfully
          IF v_inv_arr(i).invoice_type = 'FAILED' THEN
        
            DELETE FROM lego_invoice_detail_error
             WHERE invoice_id = v_inv_arr(i).invoice_id; 
           
          END IF;
        
      ELSE --then the EXTRACT_BASE_GTT populate failed      
       
        MERGE INTO lego_invoice_detail_error t
             USING (SELECT v_inv_arr(i).invoice_id   AS invoice_id, 
                           i_lego_object_name        AS lego_object_name, 
                           i_job_runtime             AS job_runtime, 
                           v_err_msg                 AS error_message
                      FROM dual) s
                ON (t.invoice_id = s.invoice_id)
             WHEN NOT MATCHED THEN 
               INSERT VALUES (s.invoice_id, s.lego_object_name, s.job_runtime, SYSTIMESTAMP, s.error_message, 0)  
             WHEN MATCHED THEN
               UPDATE SET t.lego_object_name = i_lego_object_name,
                          t.job_runtime      = i_job_runtime,
                          t.failure_date     = SYSTIMESTAMP,
                          t.error_message    = v_err_msg,
                          t.reprocess_count  = t.reprocess_count + 1;
         
      END IF;
      
      COMMIT;

    END LOOP; --loop for every invoice to be loaded in lego_invoice        
    
END load_lego_inv_det_worker;

/*******************************************************************************
 *PROCEDURE NAME : load_lego_invoice_detail
 *DATE CREATED   : February 27, 2013
 *AUTHOR         : Joe Pullifrone
 *PURPOSE        : This is the new called procedure from lego_refresh_mgr_pkg.
 *                 For init loads, it will create multiple Scheduler jobs for 
 *                 an equal number of date ranges based on invoice_date, 
 *                 effectively multi-threading the load of LEGO_INVOICE_DETAIL.
 *                 
 *MODIFICATIONS: 27 Jun 2013 J.Pullifrone Changed constant c_num_inst to c_num_threads and 
 *                                        and now storing in lego_parameter.
 *               26 Mar 2014 J.Pullifrone Limiting invoice init loads to the number of months
 *                                        defined in gv_months_in_refresh. IQN-14482 - Release 12.0.2 
 *                      
 ******************************************************************************/
 
PROCEDURE load_lego_invoice_detail (i_is_init_load CHAR DEFAULT 'N') IS
                              
  c_num_threads  PLS_INTEGER  := NVL(lego_refresh_mgr_pkg.get_lego_parameter_num_value('inv_det_num_threads'),12);
  v_source       VARCHAR2(61) := 'load_lego_invoice_detail';

--based on the c_num_threads constant value, this cursor will return multiple 
--buckets of date ranges with the same or similar number of invoice records.  
CURSOR cur_date_buckets IS
  SELECT MIN(invoice_date) start_date, MAX(invoice_date) end_date, ntile_bucket
    FROM (
            SELECT invoice_date, ntile(c_num_threads) OVER (ORDER BY invoice_date) AS ntile_bucket
              FROM invoice
             WHERE invoice_date >= ADD_MONTHS(TRUNC(SYSDATE), -1 * gv_months_in_refresh)
         )
    GROUP BY ntile_bucket
   ORDER BY start_date; 
   
  v_lego_object_name    lego_refresh.object_name%TYPE;
  v_job_runtime         lego_refresh_history.job_runtime%TYPE;
  v_tbl_cnt             PLS_INTEGER;
  v_inv_refresh_sql     lego_refresh.refresh_sql%TYPE;
  v_inv_storage         lego_refresh.exadata_storage_clause%TYPE;
  v_lego_invoice_2      lego_refresh.refresh_object_name_2%TYPE; 
  v_jobs_still_running  CHAR(1)         := 'Y';
  v_job_name_date       VARCHAR2(30)    := TO_CHAR(SYSDATE,'YYYYMMDDHHMI');
  v_job_not_complete    PLS_INTEGER     := 0;
                                
BEGIN

  logger_pkg.set_level('DEBUG');
  logger_pkg.set_source(v_source);
  
  logger_pkg.set_code_location('Get Object Name and Job Runtime');

  --get the lego object name and job_runtime of the lego being built
  --it is either going to be LEGO_INVOICE_DETAIL_INIT or LEGO_INVOICE_DETAIL
  BEGIN
   
  SELECT lrh.object_name, lrh.job_runtime
    INTO v_lego_object_name, v_job_runtime
    FROM lego_refresh_history lrh
   WHERE lrh.object_name = DECODE(i_is_init_load,'Y','LEGO_INVOICE_DETAIL_INIT','LEGO_INVOICE_DETAIL')
     AND lrh.refresh_end_time IS NULL
     AND lrh.job_runtime = (SELECT MAX(lrh2.job_runtime)
                              FROM lego_refresh_history lrh2
                             WHERE lrh.object_name = lrh2.object_name);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_lego_object_name := CASE i_is_init_load
                              WHEN 'Y' THEN 'LEGO_INVOICE_DETAIL_INIT'
                            ELSE
                              'LEGO_INVOICE_DETAIL'
                            END;
      v_job_runtime      := SYSTIMESTAMP;
  END;                               
    
  logger_pkg.debug('Object Name - '||v_lego_object_name||'; Job Runtime - '||v_job_runtime);     
  
  logger_pkg.set_code_location('See if this is an init load or regular load');
  logger_pkg.debug('Init Load = '||i_is_init_load);
  
  --check if this is an init load or normal load.  If it is a normal load then
  --skip all of the logic in this procedure and call the worker.
  IF i_is_init_load = 'N' THEN
    load_lego_inv_det_worker (i_is_init_load     => 'N',
                              i_lego_object_name => v_lego_object_name,
                              i_job_runtime      => v_job_runtime);     
  ELSE                                                                  
    
    logger_pkg.set_code_location('Start Initial Load - Create LEGO_INVOICE_2 if it doesn not exist');

    --Populate the second lego_invoice_2 table.  This step is not required in
    --order to populate lego_invoice_detail with an initial load but it is
    --necessary in order to successfully run lego_invoice_detail in the
    --normal refresh schedule.  The bottom line is that during the first
    --refresh of lego_invoice_detail, both lego_invoice_1 and
    --lego_invoice_2 must already exist.

    SELECT refresh_object_name_2, refresh_sql, exadata_storage_clause
      INTO v_lego_invoice_2, v_inv_refresh_sql, v_inv_storage
      FROM lego_refresh
     WHERE object_name = 'LEGO_INVOICE';

    SELECT COUNT(*)
      INTO v_tbl_cnt
      FROM user_tables
     WHERE table_name = v_lego_invoice_2;

    IF v_tbl_cnt = 0 THEN   
      EXECUTE IMMEDIATE 'CREATE TABLE '||v_lego_invoice_2||' '||v_inv_storage||' AS '|| v_inv_refresh_sql;
      logger_pkg.debug('CREATE TABLE '||v_lego_invoice_2||' '||v_inv_storage||' AS '|| v_inv_refresh_sql);
    END IF;  
   
    --loop through the date buckets and pass its values into the Scheduler job.
    --the number of jobs created is equal to the value of c_num_threads.
    logger_pkg.set_code_location('Looping through date buckets');
    FOR rec_db IN cur_date_buckets LOOP    

      logger_pkg.debug('Creating Scheduler Job: '||'LEGO_INVDETINIT'||v_job_name_date||'_'||rec_db.ntile_bucket);
  
      DBMS_SCHEDULER.CREATE_JOB (
         job_name             => 'LEGO_INVDETINIT'||v_job_name_date||'_'||rec_db.ntile_bucket,
         job_type             => 'PLSQL_BLOCK',
         job_action           => 'BEGIN 
                                    lego_util.load_lego_inv_det_worker
                                             (i_is_init_load     => ''Y'',
                                              i_date_range_min   => TO_DATE('''||TO_CHAR(rec_db.start_date,'MM/DD/YYYY')||''',''MM/DD/YYYY''),
                                              i_date_range_max   => TO_DATE('''||TO_CHAR(rec_db.end_date,  'MM/DD/YYYY')||''',''MM/DD/YYYY''),
                                              i_lego_invoice_2   => '''||v_lego_invoice_2||''',
                                              i_lego_object_name => '''||v_lego_object_name||''',
                                              i_job_runtime      => TO_TIMESTAMP('''||TO_CHAR(v_job_runtime,  'MM/DD/YYYY HH:MI:SSxFF')||''',''MM/DD/YYYY HH:MI:SSxFF'')
                                             ); 
                                  END;',
         start_date           =>  SYSTIMESTAMP,
         enabled              =>  TRUE,
         comments             => 'Populate LEGO_INVOICE_DETAIL - inst '||rec_db.ntile_bucket||' - this will take a while');  
  
      DBMS_LOCK.SLEEP(5);
  
    END LOOP;
  
    --after the jobs are submitted, loop while one or more of them are still
    --running.  exit the loop when none are running
    logger_pkg.set_code_location('Loop while jobs are still running');
    WHILE v_jobs_still_running = 'Y' LOOP
  
      SELECT DECODE(COUNT(*), 0, 'N','Y')
        INTO v_jobs_still_running
        FROM user_scheduler_running_jobs
       WHERE job_name LIKE 'LEGO_INVDETINIT'||v_job_name_date||'%';
       
       logger_pkg.debug('Are jobs still running?: '||v_jobs_still_running);

      DBMS_LOCK.SLEEP(900);
  
    END LOOP;
  
    logger_pkg.set_code_location('Check if all jobs completed successfully');
    SELECT COUNT(*)
      INTO v_job_not_complete
      FROM user_scheduler_job_run_details
     WHERE job_name LIKE 'LEGO_INVDETINIT'||v_job_name_date||'%'
       AND status <> 'SUCCEEDED';
       
    logger_pkg.debug('How many jobs did NOT complete successfully?: '||v_job_not_complete);       
     
     --if any jobs did complete successfully, raise and exception and exit 
     --this procedure.  the exception will be propagated back to the caller
     --in the refresh manager pkg.
     IF v_job_not_complete > 0 THEN
       raise_application_error(-20094,
                                'Scheduler job failed with jobname like LEGO_INVDETINIT'||v_job_name_date||'%');
     ELSE                                
       logger_pkg.set_code_location('Gather Stats and Update lego_refresh');
       --if all jobs completed successfully then gather stats
       DBMS_STATS.gather_table_stats(ownname => gc_curr_schema,
                                     tabname =>'LEGO_INVOICE_DETAIL');

       --update lego_refresh table so that normal refresh loads will begin for LEGO_INVOICE and LEGO_INVOICE_DETAIL.
       --update the next_refresh_time based on another lego of the same frequency so that they stay IN synch
       UPDATE lego_refresh
          SET next_refresh_time = (SELECT next_refresh_time
                                     FROM lego_refresh
                                    WHERE object_name = 'LEGO_PERSON')
        WHERE object_name IN('LEGO_INVOICE','LEGO_INVOICE_DETAIL');
       COMMIT;

     END IF;     
   
  END IF;

END load_lego_invoice_detail;


PROCEDURE upd_lego_assignment_cac
AS

   /*---------------------------------------------------------------------------*\
   || PROCEDURE NAME       : upd_lego_assignment_cac
   || AUTHOR               : Erik Clark
   || DATE CREATED         : September 19, 2012
   || PURPOSE              : This procedure is used to update the data lego LEGO_ASSIGNMENT_CAC with ACTIVE CAC flag.
   ||                      : This procedure should be executed AFTER the LEGO_ASSIGNMENT_CAC table is refreshed,
   ||                      : and BEFORE the synonym toggle is changed.
   || MODIFICATION HISTORY : 03 Apr 2013 J.Pullifrone removed references to USER - replace with sys_context constant
   ||                        gc_curr_schema.  Rel 11.2.
   ||                      : 04/15/2013 - E.Clark - added code for local dB installs surrounding COMPRESS - Release 11.2.1
   ||                      : 04/30/2013 - Adding GRANT section as IQPRODR does not always have select access on
   ||                      :            - IQPRODD.LEGO_ASSIGNMENT_CAC_T1 and IQPRODD.LEGO_ASSIGNMENT_CAC_T2 - Release 11.2.1
   ||                      : 08/18/2014 - pmuller - IQN-19497 - convert all logging to use LOGGER_PKG - 12.2
   \*---------------------------------------------------------------------------*/

   CURSOR drop_inx_cur (p_table_name VARCHAR2) IS
      SELECT index_name
        FROM user_indexes
       WHERE table_name  = p_table_name;

   v_sql              VARCHAR2(4000);
   v_curr_table_num   NUMBER;
   v_refreshing_tab   NUMBER;
   v_storage          LEGO_REFRESH.EXADATA_STORAGE_CLAUSE%TYPE;
   v_count            PLS_INTEGER;
   ---
   tbl_not_exist      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(tbl_not_exist, -942);
   ---
   idx_not_exist      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(idx_not_exist, -1418);

BEGIN
   logger_pkg.set_code_location('assignment_active_cac refresh');
   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_assignment_active_cac PURGE';
   EXCEPTION
      WHEN tbl_not_exist THEN
         NULL;  -- do nothing
   END;

   BEGIN
      SELECT NVL(SUBSTR(curr_table_name,-1),2)
        INTO v_curr_table_num
        FROM lego_refresh_object_state_vw
       WHERE object_name = 'LEGO_ASSIGNMENT_WO';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_curr_table_num := 2;
   END;

   SELECT exadata_storage_clause
     INTO v_storage
     FROM lego_refresh
    WHERE object_name = 'LEGO_ASSIGNMENT_ACTIVE_CAC';

   IF v_curr_table_num = 1 THEN
      v_refreshing_tab := 2;
   ELSE
      v_refreshing_tab := 1;
   END IF;

   logger_pkg.debug('REFRESH TAB :' || v_refreshing_tab);
   DECLARE   
      table_does_not_exist  EXCEPTION;  
      PRAGMA                EXCEPTION_INIT(table_does_not_exist, -942); -- ORA-00942
   BEGIN
      EXECUTE IMMEDIATE 'GRANT SELECT ON LEGO_ASSIGNMENT_CAC_T1 TO ' || SUBSTR(gc_curr_schema, 1, (LENGTH(gc_curr_schema) -1) ) || 'R';
   EXCEPTION
      WHEN table_does_not_exist THEN 
         NULL;
   END;

   DECLARE   
      table_does_not_exist  EXCEPTION;  
      PRAGMA                EXCEPTION_INIT(table_does_not_exist, -942); -- ORA-00942
   BEGIN
      EXECUTE IMMEDIATE 'GRANT SELECT ON LEGO_ASSIGNMENT_CAC_T2 TO ' || SUBSTR(gc_curr_schema, 1, (LENGTH(gc_curr_schema) -1) ) || 'R';
   EXCEPTION
      WHEN table_does_not_exist THEN 
         NULL;
   END;

   v_sql :=
   'CREATE TABLE lego_assignment_active_cac '|| v_storage ||
   'AS
    SELECT assignment_continuity_id,
           CASE WHEN cac_collection1_id IS NOT NULL THEN
              RPT_UTIL_CAC.get_active_cac_segment_flag
                 (assignment_continuity_id,
                  work_order_id,
                  assignment_state_id,
                  NULL,
                  onboard_allowed,
                  cac_collection1_id,
                  1, --cac_kind
                  assignment_start_dt,
                  assignment_end_dt,
                  assignment_actual_end_dt,
                  ' || v_refreshing_tab || ')
           ELSE NULL END AS active_cac_id_1,
           CASE WHEN cac_collection2_id IS NOT NULL THEN
              RPT_UTIL_CAC.get_active_cac_segment_flag
                 (assignment_continuity_id,
                  work_order_id,
                  assignment_state_id,
                  NULL,
                  onboard_allowed,
                  cac_collection2_id,
                  2, --cac_kind
                  assignment_start_dt,
                  assignment_end_dt,
                  assignment_actual_end_dt,
                  ' || v_refreshing_tab || ')
           ELSE NULL END AS active_cac_id_2
      FROM (SELECT assignment_continuity_id, work_order_id,
                   assignment_state_id, onboard_allowed,
                   cac_collection1_id, cac_collection2_id,
                   assignment_start_dt, assignment_end_dt, assignment_actual_end_dt
              FROM lego_assignment_wo' || v_refreshing_tab ||
           ' UNION ALL
            SELECT assignment_continuity_id, work_order_id,
                   assignment_state_id, onboard_allowed,
                   cac_collection1_id, cac_collection2_id,
                   assignment_start_dt, assignment_end_dt, assignment_actual_end_dt
              FROM lego_assignment_ea' || v_refreshing_tab ||
           ' UNION ALL
            SELECT assignment_continuity_id, work_order_id,
                   assignment_state_id, onboard_allowed,
                   cac_collection1_id, cac_collection2_id,
                   assignment_start_dt, assignment_end_dt, assignment_actual_end_dt
              FROM lego_assignment_ta' || v_refreshing_tab || ')';

   logger_pkg.debug('creating table lego_assignment_active_cac');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.debug('creating table lego_assignment_active_cac - complete', TRUE);

   v_sql :=
   'UPDATE lego_assignment_cac_t' || v_refreshing_tab || ' a
       SET primary_active_cac = :1
     WHERE a.cac_id IN (SELECT active_cac_id_1
                          FROM lego_assignment_active_cac
                         WHERE active_cac_id_1 IS NOT NULL
                         UNION ALL
                        SELECT active_cac_id_2
                          FROM lego_assignment_active_cac
                         WHERE active_cac_id_2 IS NOT NULL) ';

   logger_pkg.debug('updating lego_assignment_cac_t' || v_refreshing_tab);
   EXECUTE IMMEDIATE v_sql USING 'Y';
   logger_pkg.debug('updating lego_assignment_cac_t' || v_refreshing_tab || 
                    ' complete. ' || to_char(SQL%ROWCOUNT) || ' rows updated.', TRUE);
   COMMIT;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_assignment_active_cac PURGE';
   EXCEPTION
      WHEN tbl_not_exist THEN
         NULL;  -- do nothing
   END;

   FOR drop_inx_rec IN drop_inx_cur ( 'LEGO_ASSIGNMENT_CAC_T' || v_refreshing_tab  ) LOOP
      BEGIN
         EXECUTE IMMEDIATE 'DROP INDEX ' || drop_inx_rec.index_name;
         logger_pkg.debug('index ' || drop_inx_rec.index_name || ' dropped');
      EXCEPTION
         WHEN idx_not_exist THEN
            NULL;  -- do nothing
      END;
   END LOOP;

   SELECT COUNT(*)
    INTO v_count
    FROM lego_refresh
   WHERE object_name = 'LEGO_ASSIGNMENT_WO'
     AND exadata_storage_clause LIKE '%COMPRESS FOR QUERY HIGH%';

   IF v_count > 0 THEN
      logger_pkg.debug('compressing table lego_assignment_cac_t' || v_refreshing_tab);     
      EXECUTE IMMEDIATE 'ALTER TABLE lego_assignment_cac_t' || v_refreshing_tab || ' MOVE COMPRESS FOR QUERY HIGH';
      logger_pkg.debug('compressing table lego_assignment_cac_t' || v_refreshing_tab || 
                       ' complete', TRUE);     
   END IF;

   logger_pkg.debug('stats for lego_assignment_cac_t' || v_refreshing_tab);
   DBMS_STATS.gather_table_stats(ownname=> gc_curr_schema, tabname=> 'LEGO_ASSIGNMENT_CAC_T' || v_refreshing_tab);
   logger_pkg.debug('stats for lego_assignment_cac_t' || v_refreshing_tab || 
                    ' complete', TRUE);

EXCEPTION
   WHEN OTHERS THEN
     ROLLBACK;
     logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                      pi_error_code         => SQLCODE,
                      pi_message            => SQLERRM);
     RAISE;

END upd_lego_assignment_cac;

-----------------------

PROCEDURE upd_lego_job_cancel_tmp
AS

   /*---------------------------------------------------------------------------*\
   || PROCEDURE NAME       : upd_lego_job_cancel_tmp
   || AUTHOR               : Erik Clark
   || DATE CREATED         : September 3, 2013
   || PURPOSE              : This procedure makes a tmp table of job canceled reasons to 
   ||                      : eliminate long running queries. This table is then used in LEGO_JOB refresh. - Release 11.3.2
   || MODIFICATION HISTORY : 08/18/2014 - pmuller - IQN-19497 - convert all logging to use LOGGER_PKG - Release 12.2
   \*---------------------------------------------------------------------------*/

   v_sql              VARCHAR2(10000);
   v_storage          LEGO_REFRESH.EXADATA_STORAGE_CLAUSE%TYPE;
   ---
   tbl_not_exist      EXCEPTION;
   PRAGMA             EXCEPTION_INIT(tbl_not_exist, -942);

BEGIN
   logger_pkg.set_code_location('job cancel_tmp refresh');
   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_job_cancel_tmp PURGE';
   EXCEPTION
      WHEN tbl_not_exist THEN
         NULL;  -- do nothing
   END;

   SELECT exadata_storage_clause
     INTO v_storage
     FROM lego_refresh
    WHERE object_name = 'LEGO_JOB_CANCEL_TMP';

   v_sql :=
   'CREATE TABLE lego_job_cancel_tmp '|| v_storage ||
   q'{ AS
        SELECT /*+ PARALLEL (4) */ 
               job_id,
               LISTAGG(description, '; ') WITHIN GROUP (ORDER BY description) AS reason_canceled
          FROM (WITH job_base
                  AS
                 (SELECT jed.job_owner_id AS job_id,
                         x.event_reason_type,
                         x.event_reason_id
                    FROM job_event_description     AS OF SCN lego_refresh_mgr_pkg.get_scn() jed,
                         event_description         AS OF SCN lego_refresh_mgr_pkg.get_scn() ed,
                         event_desc_event_reason_x AS OF SCN lego_refresh_mgr_pkg.get_scn() x
                   WHERE jed.identifier      = ed.identifier
                     AND jed.identifier      = x.event_desc_id
                     AND x.event_reason_type IN ('E','O','C')
                     AND ed.event_name_fk    = 29003)
                  SELECT j.job_id,
                         er.description
                    FROM job_base j,
                         event_reason   AS OF SCN lego_refresh_mgr_pkg.get_scn() er
                   WHERE j.event_reason_type = 'E'
                     AND j.event_reason_id   = er.value
                   UNION ALL
                  SELECT j.job_id,
                         oe.description
                    FROM job_base j,
                         other_event_reason   AS OF SCN lego_refresh_mgr_pkg.get_scn() oe
                   WHERE j.event_reason_type = 'O'
                     AND j.event_reason_id   = oe.value
                   UNION ALL
                  SELECT j.job_id,
                         ce.description
                    FROM job_base j,
                         custom_event_reason  AS OF SCN lego_refresh_mgr_pkg.get_scn() ce
                   WHERE j.event_reason_type = 'C'
                     AND j.event_reason_id   = ce.identifier) --END WITH
         WHERE job_id IN (--Only include descriptions concated less than 4000 characters
                          SELECT job_id
                            FROM (WITH job_base2
                                    AS
                                 (SELECT jed.job_owner_id AS job_id,
                                         x.event_reason_type,
                                         x.event_reason_id
                                    FROM job_event_description     AS OF SCN lego_refresh_mgr_pkg.get_scn() jed,
                                         event_description         AS OF SCN lego_refresh_mgr_pkg.get_scn() ed,
                                         event_desc_event_reason_x AS OF SCN lego_refresh_mgr_pkg.get_scn() x
                                   WHERE jed.identifier      = ed.identifier
                                     AND jed.identifier      = x.event_desc_id
                                     AND x.event_reason_type IN ('E','O','C')
                                     AND ed.event_name_fk    = 29003)
                                  SELECT j.job_id,
                                         er.description
                                    FROM job_base2 j,
                                         event_reason   AS OF SCN lego_refresh_mgr_pkg.get_scn() er
                                   WHERE j.event_reason_type = 'E'
                                     AND j.event_reason_id   = er.value
                                   UNION ALL
                                  SELECT j.job_id,
                                         oe.description
                                    FROM job_base2 j,
                                         other_event_reason   AS OF SCN lego_refresh_mgr_pkg.get_scn() oe
                                   WHERE j.event_reason_type = 'O'
                                     AND j.event_reason_id   = oe.value
                                   UNION ALL
                                  SELECT j.job_id,
                                         ce.description
                                    FROM job_base2 j,
                                         custom_event_reason  AS OF SCN lego_refresh_mgr_pkg.get_scn() ce
                                   WHERE j.event_reason_type = 'C'
                                     AND j.event_reason_id   = ce.identifier
                                ) --END WITH
                           GROUP BY job_id
                           HAVING SUM(LENGTH(description)) + (COUNT(description) *2) -2 < 4000)
         GROUP BY job_id}';
   logger_pkg.debug('create table lego_job_cancel_tmp');
   EXECUTE IMMEDIATE v_sql;

   v_sql := 'GRANT SELECT ON LEGO_JOB_CANCEL_TMP TO ' || 'RO_' || gc_curr_schema;
   EXECUTE IMMEDIATE v_sql;

   logger_pkg.debug('stats for lego_job_cancel_tmp');
   DBMS_STATS.gather_table_stats(ownname=> gc_curr_schema, tabname=> 'LEGO_JOB_CANCEL_TMP');

   logger_pkg.info('lego_job_cancel_tmp complete');
   
EXCEPTION
   WHEN OTHERS THEN
      logger_pkg.fatal(pi_transaction_result => NULL,
                       pi_error_code         => SQLCODE,
                       pi_message            => SQLERRM);
      RAISE;

END upd_lego_job_cancel_tmp;

------------------------

PROCEDURE load_lego_rfx_cac (p_table_name IN VARCHAR2)
AS

   /*---------------------------------------------------------------------------*\
   || PROCEDURE NAME       : load_lego_rfx_cac
   || AUTHOR               : Erik Clark
   || DATE CREATED         : October 15, 2012
   || PURPOSE              : This procedure is used to load data into the LEGO_RFX_CAC_T1 or LEGO_RFX_CAC_T2
   || MODIFICATION HISTORY : 10/03/2013 - Added CAC APPROVER - 11.4.1
   ||                      : 08/14/2014 - pmuller - rewrote to make use of P_table_name input,
   ||                      : most_recently_loaded_table function, and to use logger_pkg logging. - 12.2
   \*---------------------------------------------------------------------------*/

   v_sql            VARCHAR2(4000);
   v_refreshing_tab VARCHAR2(30) := most_recently_loaded_table(i_lego_name => 'LEGO_RFX');

BEGIN
   v_sql :=
    'SELECT v.lego_rfx_id,
            v.cac_collection1_id   AS cac_collection_id,
            lcc.cac_id,
            lcc.bus_org_id         AS buyer_org_id,
            lcc.cac_kind,
            lcc.start_date         AS cac_start_date,
            lcc.end_date           AS cac_end_date,
            (SELECT firm_worker.never_null_person_fk AS cac_approver_person_id
               FROM firm_worker AS OF SCN lego_refresh_mgr_pkg.get_scn(),
                    category_node AS OF SCN lego_refresh_mgr_pkg.get_scn(),
                    cac_cacvalue_x AS OF SCN lego_refresh_mgr_pkg.get_scn()
              WHERE cac_cacvalue_x.cac_fk            = lcc.cac_id
                AND cac_cacvalue_x.cac_value_fk      = category_node.categorizable_fk
                AND category_node.categorizable_type = ''CACValue''
                AND category_node.approver_fk        = firm_worker.firm_worker_id
                AND ROWNUM = 1) AS cac_approver_person_id,
            lcc.cac_guid
       FROM ' || v_refreshing_tab || ' v, lego_cac_collection lcc
      WHERE v.cac_collection1_id = lcc.cac_collection_id
      UNION ALL
     SELECT v.lego_rfx_id,
            v.cac_collection2_id   AS cac_collection_id,
            lcc.cac_id,
            lcc.bus_org_id         AS buyer_org_id,
            lcc.cac_kind,
            lcc.start_date         AS cac_start_date,
            lcc.end_date           AS cac_end_date,
            (SELECT firm_worker.never_null_person_fk AS cac_approver_person_id
               FROM firm_worker AS OF SCN lego_refresh_mgr_pkg.get_scn(),
                    category_node AS OF SCN lego_refresh_mgr_pkg.get_scn(),
                    cac_cacvalue_x AS OF SCN lego_refresh_mgr_pkg.get_scn()
              WHERE cac_cacvalue_x.cac_fk            = lcc.cac_id
                AND cac_cacvalue_x.cac_value_fk      = category_node.categorizable_fk
                AND category_node.categorizable_type = ''CACValue''
                AND category_node.approver_fk        = firm_worker.firm_worker_id
                AND ROWNUM = 1) AS cac_approver_person_id,
            lcc.cac_guid
       FROM ' || v_refreshing_tab || ' v, lego_cac_collection lcc
      WHERE v.cac_collection2_id  = lcc.cac_collection_id
      ORDER BY buyer_org_id, cac_collection_id, cac_id';

   lego_refresh_mgr_pkg.ctas(pi_table_name             => p_table_name,
                             pi_stmt_clob              => v_sql,
                             pi_exadata_storage_clause => get_exadata_storage_clause('LEGO_RFX_CAC'),
                             pi_partition_clause       => get_partition_clause('LEGO_RFX_CAC'));

END load_lego_rfx_cac;

------------------------

PROCEDURE load_lego_proj_agreement_pay (p_table_name IN VARCHAR2)
AS

/*----------------------------------------------------------------------------*\
|| PROCEDURE NAME       : load_lego_proj_agreement_pay
|| AUTHOR               : Joe Pullifrone
|| DATE CREATED         : October 25, 2012
|| PURPOSE              : This procedure is used to load data into the
||                        LEGO_PROJ_AGREEMENT_PAYMENT_1 or
||                        LEGO_PROJ_AGREEMENT_PAYMENT_2
|| MODIFICATION
|| HISTORY :    03 Apr 2014 J.Pullifrone added () after call to get SCN. Rel 11.2.
||              17 Aug 2013 J.Pullifrone - IQN-6275 - Added Currency ID - Rel 11.3.2
||              24 Sep 2013 J.Pullifrone - IQN-8205 - Missing Currency Info - Rel 11.4
||              18 Mar 2014 E.Clark      - IQN 14764 - Removed geo_desc function from the loader, 
||                                         create separate lego for it - Release 12.0.2
||              18 Aug 2014 pmuller      - IQN-19497 - convert all logging to use LOGGER_PKG - 12.2
\*----------------------------------------------------------------------------*/

   v_sql                   CLOB;
   v_curr_table_num        NUMBER;
   v_refreshing_tab        VARCHAR2(30);
   v_refresh_object_name_1 VARCHAR2(30);
   v_refresh_object_name_2 VARCHAR2(30);
   v_storage               lego_refresh.exadata_storage_clause%type;

BEGIN
   logger_pkg.set_code_location('LEGO_PROJ_AGREEMENT_PYMNT refresh');
   BEGIN
      SELECT NVL(SUBSTR(curr_table_name,-1),2), refresh_object_name_1, refresh_object_name_2
        INTO v_curr_table_num, v_refresh_object_name_1, v_refresh_object_name_2
        FROM lego_refresh_object_state_vw
       WHERE object_name = 'LEGO_PROJECT_AGREEMENT';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_curr_table_num := 2;
         v_refresh_object_name_2 := 'LEGO_PROJECT_AGREEMENT'||v_curr_table_num;
   END;

   SELECT exadata_storage_clause
     INTO v_storage
     FROM lego_refresh
    WHERE object_name = 'LEGO_PROJ_AGREEMENT_PYMNT';

   IF v_curr_table_num = 1 THEN
      v_refreshing_tab := v_refresh_object_name_2;
   ELSE
      v_refreshing_tab := v_refresh_object_name_1;
   END IF;

   logger_pkg.debug ('Dependency table used: '||v_refreshing_tab||', Table being built: '|| p_table_name);

   v_sql := 'CREATE TABLE '||p_table_name|| ' ' || v_storage ||' AS
 SELECT   lpa.buyer_org_id                                       AS buyer_org_id,
          lpa.supplier_org_id                                    AS supplier_org_id,
          lpa.project_agreement_id                               AS project_agreement_id,
          lpa.project_agreement_version_id                       AS project_agreement_version_id,
          ppm.payment_milestone_id                               AS payment_milestone_id,
          ppm.title                                              AS title,
          ppm.start_date                                         AS estimated_start_date,
          ppm.end_date                                           AS estimated_end_date,
          CASE
             WHEN ppm.allow_mult_supplier_pay_rqst = 1 THEN ''Yes''
             WHEN ppm.allow_mult_supplier_pay_rqst = 0 THEN ''No''
             ELSE NULL
          END                                                    AS allow_multiple_paym_req,
          CASE
             WHEN ex.is_billable_event = 1 THEN ''Yes''
             WHEN ex.is_billable_event = 0 THEN ''No''
             ELSE NULL
          END                                                    AS is_billable,
          lpa.pa_currency_id                                     AS currency_id,
          lpa.pa_currency                                        AS currency,
          NULL                                                   AS phase_number,
          NULL                                                   AS phase_description,
          NULL                                                   AS expense_type_desc,
          NULL                                                   AS rate_table_edition_id,
          NULL                                                   AS rate_table_name,
          NULL                                                   AS rate_table_type,
          NULL                                                   AS rate_table_rate,
          NULL                                                   AS adjustable_rate,
          NULL                                                   AS resource_phase_desc,
          NULL                                                   AS resource_phase_number,
          NULL                                                   AS is_rate_table_res_rate_neg,
          NULL                                                   AS number_of_resources,
          NULL                                                   AS shift_label,
          NULL                                                   AS resource_est_units,
          NULL                                                   AS resource_est_cost,
          ex.payment_amount                                      AS payment_amount,
          ex.supplier_reimbursement_amt                          AS supplier_reimbursement_amount,
          silt.amount                                            AS management_fee,
          bilt.amount                                            AS contracted_fee,
          ppm.comments                                                  AS comments,
          ''Milestone Payment Request''                                 AS payment_request_type
     FROM '||v_refreshing_tab||' lpa,
          project_payment_milestone AS OF SCN lego_refresh_mgr_pkg.get_scn() ppm,
          expenditure               AS OF SCN lego_refresh_mgr_pkg.get_scn() ex,
          invoice_line_item         AS OF SCN lego_refresh_mgr_pkg.get_scn() silt,
          invoice_line_item         AS OF SCN lego_refresh_mgr_pkg.get_scn() bilt
    WHERE lpa.project_agreement_version_id      = ppm.project_agreement_version_fk(+)
      AND ppm.expenditure_fk     = ex.identifier
      AND ex.supplier_trx_fee_fk = silt.identifier(+)
      AND ex.buyer_trx_fee_fk    = bilt.identifier(+)
      UNION ALL
   SELECT lpa.buyer_org_id                                       AS buyer_org_id,
          lpa.supplier_org_id                                    AS supplier_org_id,
          lpa.project_agreement_id                               AS project_agreement_id,
          lpa.project_agreement_version_id                       AS project_agreement_version_id,
          NULL                                                   AS payment_milestone_id,
          NULL                                                   AS title,
          NULL                                                   AS estimated_start_date,
          NULL                                                   AS estimated_end_date,
          NULL                                                   AS allow_multiple_paym_req,
          NULL                                                   AS is_billable,
          lpa.pa_currency_id                                     AS currency_id,
          lpa.pa_currency                                        AS currency,
          cp.complx_proj_exp_desc_phase_id                       AS phase_number,
          cp.phase_description                                   AS phase_description,
          et.name                                                AS expense_type_desc,
          NULL                                                   AS rate_table_edition_id,
          NULL                                                   AS rate_table_name,
          NULL                                                   AS rate_table_type,
          NULL                                                   AS rate_table_rate,
          NULL                                                   AS adjustable_rate,
          NULL                                                   AS resource_phase_desc,
          NULL                                                   AS resource_phase_number,
          NULL                                                   AS is_rate_table_res_rate_neg,
          NULL                                                   AS number_of_resources,
          NULL                                                   AS shift_label,
          NULL                                                   AS resource_est_units,
          NULL                                                   AS resource_est_cost,
          c.amount                                               AS payment_amount,
          NULL                                                   AS supplier_reimbursement_amount,
          NULL                                                   AS management_fee,
          NULL                                                   AS contracted_fee,
          NULL                                                   AS comments,
          ''Ad-Hoc Payment Request''                             AS payment_request_type
     FROM '||v_refreshing_tab||' lpa,
          complx_proj_exp_desc_phase AS OF SCN lego_refresh_mgr_pkg.get_scn() cp,
          complex_project_exp_desc   AS OF SCN lego_refresh_mgr_pkg.get_scn() c,
          expense_type               AS OF SCN lego_refresh_mgr_pkg.get_scn() et
    WHERE lpa.project_agreement_version_id                = cp.project_agreement_version_fk
      AND cp.complx_proj_exp_desc_phase_id = c.cped_phase_fk
      AND c.expense_type_fk                = et.expense_type_id(+)
   UNION ALL
   SELECT lpa.buyer_org_id                                       AS buyer_org_id,
          lpa.supplier_org_id                                    AS supplier_org_id,
          lpa.project_agreement_id                               AS project_agreement_id,
          lpa.project_agreement_version_id                       AS project_agreement_version_id,
          NULL                                                   AS payment_milestone_id,
          NULL                                                   AS title,
          NULL                                                   AS estimated_start_date,
          NULL                                                   AS estimated_end_date,
          NULL                                                   AS allow_multiple_paym_req,
          NULL                                                   AS is_billable,
          NULL                                                   AS currency_id,
          NULL                                                   AS currency,
          NULL                                                   AS phase_number,
          NULL                                                   AS phase_description,
          NULL                                                   AS expense_type_desc,
          rte.rate_table_edition_id                              AS rate_table_edition_id,
          rte.name                                               AS rate_table_name,
          NULL                                                   AS rate_table_type,
          NULL                                                   AS rate_table_rate,
          NULL                                                   AS adjustable_rate,
          NULL                                                   AS resource_phase_desc,
          NULL                                                   AS resource_phase_number,
          NULL                                                   AS is_rate_table_res_rate_neg,
          NULL                                                   AS number_of_resources,
          NULL                                                   AS shift_label,
          NULL                                                   AS resource_est_units,
          NULL                                                   AS resource_est_cost,
          NULL                                                   AS payment_amount,
          NULL                                                   AS supplier_reimbursement_amount,
          NULL                                                   AS management_fee,
          NULL                                                   AS contracted_fee,
          NULL                                                   AS comments,
          ''Rate Table Payment Request''                         AS payment_request_type
     FROM '||v_refreshing_tab||' lpa,
          project_agreement_version AS OF SCN lego_refresh_mgr_pkg.get_scn() pav,
          rate_table_continuity     AS OF SCN lego_refresh_mgr_pkg.get_scn() rtc,
          rate_table_edition        AS OF SCN lego_refresh_mgr_pkg.get_scn() rte
    WHERE lpa.project_agreement_version_id             = pav.contract_version_id
      AND rtc.current_edition_fk        = rte.rate_table_edition_id
      AND rtc.rate_table_continuity_id  = pav.rate_table_continuity_fk
   UNION ALL
   SELECT lpa.buyer_org_id                                       AS buyer_org_id,
          lpa.supplier_org_id                                    AS supplier_org_id,
          lpa.project_agreement_id                               AS project_agreement_id,
          lpa.project_agreement_version_id                       AS project_agreement_version_id,
          NULL                                                   AS payment_milestone_id,
          j.position_title                                       AS title,
          prd.estimated_start_date                               AS estimated_start_date,
          prd.estimated_end_date                                 AS estimated_end_date,
          NULL                                                   AS allow_multiple_paym_req,
          CASE
            WHEN prd.is_billable = 1 THEN ''Yes''
            WHEN prd.is_billable = 0 THEN ''No''
            ELSE NULL
          END                                                    AS is_billable,
          lpa.pa_currency_id                                     AS currency_id,
          lpa.pa_currency                                        AS currency,
          NULL                                                   AS phase_number,
          NULL                                                   AS phase_description,
          NULL                                                   AS expense_type_desc,
          NULL                                                   AS rate_table_edition_id,
          rte.name                                               AS rate_table_name,
          ru.description                                         AS rate_table_type,
          sr.lower_rate                                          AS rate_table_rate,
          prd.adjusted_rate                                      AS adjustable_rate,
          prdp.description                                       AS resource_phase_desc,
          prd.user_defined_order                                 AS resource_phase_number,
          CASE
            WHEN prd.is_rate_ngotble_on_pmnt_reqsts = 0 THEN ''No''
            WHEN prd.is_rate_ngotble_on_pmnt_reqsts = 1 THEN ''Yes''
            ELSE NULL
          END                                                      AS is_rate_table_res_rate_neg,
          prd.number_of_resources                                  AS number_of_resources,
          sc.shift_label                                           AS shift_label,
          prd.duration                                             AS resource_est_units,
          prd.estimated_cost                                       AS resource_est_cost,
          NULL                                                     AS payment_amount,
          NULL                                                     AS supplier_reimbursement_amount,
          NULL                                                     AS management_fee,
          NULL                                                     AS contracted_fee,
          prd.comments                                             AS comments,
          ''Resource Rate Table Payment Request''                  AS payment_request_type
     FROM '||v_refreshing_tab||' lpa,
          project_resource_description AS OF SCN lego_refresh_mgr_pkg.get_scn() prd,
          project_res_desc_phase       AS OF SCN lego_refresh_mgr_pkg.get_scn() prdp,
          rate_table_edition           AS OF SCN lego_refresh_mgr_pkg.get_scn() rte,
          service_rate                 AS OF SCN lego_refresh_mgr_pkg.get_scn() sr,
          shift_configuration          AS OF SCN lego_refresh_mgr_pkg.get_scn() sc,
          job                          AS OF SCN lego_refresh_mgr_pkg.get_scn() j,
          rate_unit                    ru
    WHERE lpa.project_agreement_version_id             = prdp.project_agreement_version_fk
      AND prdp.phase_id                 = prd.phase_fk
      AND prd.rate_table_edition_fk     = rte.rate_table_edition_id
      AND prd.service_rate_fk           = sr.service_rate_id
      AND prd.shift_configuration_fk    = sc.shift_configuration_id(+)
      AND sr.job_template_fk            = j.job_id
      AND prd.rate_unit_fk              = ru.value(+)
    ORDER BY buyer_org_id, supplier_org_id, project_agreement_id, project_agreement_version_id';

   logger_pkg.debug (v_sql);
   EXECUTE IMMEDIATE v_sql;

EXCEPTION
   WHEN OTHERS THEN
      logger_pkg.fatal(pi_transaction_result => NULL,
                       pi_error_code         => SQLCODE,
                       pi_message            => SQLERRM);
      RAISE;
      
END load_lego_proj_agreement_pay;

------------------------

PROCEDURE load_lego_pa_geo_desc (p_table_name IN VARCHAR2)
AS

   /*---------------------------------------------------------------------------*\
   || PROCEDURE NAME       : load_lego_pa_geo_desc
   || AUTHOR               : Erik Clark
   || DATE CREATED         : 03/18/2014
   || PURPOSE              : This builds the LOAD_LEGO_PA_GEO_DESC lego for use with PROJECTS 
   || MODIFICATION HISTORY : IQN - 14764 - Released 12.0.2
   ||                      : 08/18/2014 - pmuller - IQN-19497 - convert all logging 
   ||                        to use LOGGER_PKG - 12.2
   \*---------------------------------------------------------------------------*/

   v_sql                   CLOB;
   v_curr_table_num        NUMBER;
   v_refreshing_tab        VARCHAR2(30);
   v_refresh_object_name_1 VARCHAR2(30);
   v_refresh_object_name_2 VARCHAR2(30);
   v_storage               lego_refresh.exadata_storage_clause%type;

BEGIN

   logger_pkg.set_code_location('LEGO_PA_GEO_DESC refresh');
   BEGIN
      SELECT NVL(SUBSTR(curr_table_name,-1),2), refresh_object_name_1, refresh_object_name_2
        INTO v_curr_table_num, v_refresh_object_name_1, v_refresh_object_name_2
        FROM lego_refresh_object_state_vw
       WHERE object_name = 'LEGO_PROJECT_AGREEMENT';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_curr_table_num := 2;
         v_refresh_object_name_2 := 'LEGO_PROJECT_AGREEMENT'||v_curr_table_num;
   END;

   SELECT exadata_storage_clause
     INTO v_storage
     FROM lego_refresh
    WHERE object_name = 'LEGO_PA_GEO_DESC';

   IF v_curr_table_num = 1 THEN
      v_refreshing_tab := v_refresh_object_name_2;
   ELSE
      v_refreshing_tab := v_refresh_object_name_1;
   END IF;

   logger_pkg.debug ('Dependency table used: '||v_refreshing_tab||', Table being built: '|| p_table_name);

   v_sql := 'CREATE TABLE '||p_table_name|| ' ' || v_storage ||' AS
              SELECT px.project_agmt_version_fk  AS project_agreement_version_id,
                     loc.constant_description    AS pa_geo_desc,
                     p.value                     AS place_id
                FROM place p, 
                     project_agmt_version_place_x px,
                     '||v_refreshing_tab||' lpa,
                     (SELECT constant_value, constant_description
                        FROM java_constant_lookup 
                       WHERE constant_type    = ''PLACE''
                         AND UPPER(locale_fk) = ''EN_US'') loc
               WHERE px.project_agmt_version_fk = lpa.project_agreement_version_id
                 AND px.place_fk = p.value
                 AND p.value     = loc.constant_value
               ORDER BY px.project_agmt_version_fk';

   logger_pkg.debug (v_sql);
   logger_pkg.info('building table ' || p_table_name);
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.info('building table ' || p_table_name || ' - complete', TRUE);

EXCEPTION
   WHEN OTHERS THEN
      logger_pkg.fatal(pi_transaction_result => NULL,
                       pi_error_code         => SQLCODE,
                       pi_message            => SQLERRM);
      RAISE;

END load_lego_pa_geo_desc;

-----------------------------------

PROCEDURE load_lego_payment_request (p_table_name IN VARCHAR2)
AS

/*---------------------------------------------------------------------------*\
|| PROCEDURE NAME       : load_lego_payment_request
|| AUTHOR               : Joe Pullifrone
|| DATE CREATED         : October 25, 2012
|| PURPOSE              : This procedure is used to load data into the
||                        LEGO_PAYMENT_REQUEST_1 or
||                        LEGO_PAYMENT_REQUEST_2
|| MODIFICATION
|| HISTORY :     18 Mar 2013 J.Pullifrone changed jcl.contant_type to
||                           MilestoneStatus.  Also added additional columns in
||                           ORDER BY. Rel 11.2
||               19 Mar 2013 J.Pullifrone for Resource Rate Table
||                           Payment Requests, created a separate in-line view for
||                           project_resource_description, project_res_desc_phase,
||                           service_rate, job, and rate_table_edition in order to
||                           OUTER JOIN to the other tables. RJ-492.  Rel 11.2
||               03 Apr 2014 J.Pullifrone added () after call to get SCN. Rel 11.2.
||               15 May 2013 - IQN-3123 - Rel 11.2.2
||                             In base_pr WITH clause, selecting mileston_invoice_detail_id
||                             from mid2 instead of mid1 and joining on mid2.expenditure_fk
||                             instead of mid1.expenditure_fk.  Also, removed quantity as
||                             a column.  Quantity is at the parent MS INV Det level but
||                             we are showing data at the child level so that value
||                             does not make sense.
||               25 Jul 2013 - E.Clark - IQN-6268 - Add "Invoiced" fields - Release 11.3.1
||               08 Aug 2013 - E.Clark - IQN-6268 - changed "Invoiced" fields for approved only - Release 11.3.2
||               17 Aug 2013 - J.Pullifrone - IQN-6275 - Added Currency ID - Rel 11.3.2
||               16 Sep 2013 - J.Pullifrone - IQN-7723 - Changes to Currency - Rel 11.4
||               26 Sep 2013 - J.Pullifrone - IQN-8486 - Adding REJECT_REASON - Rel 11.4.1
||               01 Nov 2013 - E.Clark - IQN-9062 - Added mi_approved_date - Release 11.4.2
||               12 Feb 2014 - J.Pullifrone - IQN-13096 - Removed 2 main WITH clauses base_pr and base_pr2 to 
||                                            make them physical tables. Rel 12.0.1
||               11 Apr 2014 - E.Clark - IQN-15396 - localize Payment_Request_Type and Billable_event - Release 12.0.3
||               18 Apr 2014 - J.Pullifrone - IQN-16145 - changed join to project_payment_milestone for Milestone Payment Request - Release 12.0.3
||               20 Aug 2014 - J.Pullifrone - IQN-18776 - removed invoice_id and added invoiced_amount - Release 12.2.0
||        
\*---------------------------------------------------------------------------*/

   v_source                VARCHAR2(61) := 'load_lego_payment_request';
   v_pr_sql                CLOB;
   v_base_pr_sql           CLOB;
   v_base_pr_child_sql     CLOB;
   v_curr_table_num        NUMBER;
   v_refreshing_tab        VARCHAR2(30);
   v_refresh_object_name_1 VARCHAR2(30);
   v_refresh_object_name_2 VARCHAR2(30);
   v_loc                   VARCHAR2(30);
   v_storage               lego_refresh.exadata_storage_clause%type;
   v_err_msg               VARCHAR2(2000);

BEGIN

   logger_pkg.set_source(v_source);
   logger_pkg.set_code_location('Get last refreshed LEGO_PROJECT_AGREEMENT table'); 
   
   v_refreshing_tab := most_recently_loaded_table('LEGO_PROJECT_AGREEMENT');  

   logger_pkg.debug ('Dependency table used: '||v_refreshing_tab||', Table being built: '|| p_table_name);

   logger_pkg.set_code_location('Get Exadata Storage Clause'); 
   SELECT exadata_storage_clause
     INTO v_storage
     FROM lego_refresh
    WHERE object_name = 'LEGO_PAYMENT_REQUEST';
   
   logger_pkg.debug ('Exadata Storage is '||v_storage);
   
   logger_pkg.set_code_location('Drop Temporary Tables'); 
   logger_pkg.debug ('Temporary Tables being dropped are: lego_base_pr_tmp AND lego_base_pr_child_tmp');
   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_base_pr_tmp PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;
   
   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_base_pr_child_tmp PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END; 
   logger_pkg.debug ('Temporary Tables successfully dropped',TRUE);  
   
   logger_pkg.set_code_location('Build Dynamic SQL for Temporary Table, lego_base_pr_tmp');
   v_base_pr_sql := q'{
   SELECT /*+parallel(4)*/
          lpa.buyer_org_id                       AS buyer_org_id,
          lpa.supplier_org_id                    AS supplier_org_id,
          lpa.project_id                         AS project_id,
          lpa.project_agreement_id               AS project_agreement_id,
          lpa.project_agreement_version_id       AS project_agreement_version_id,
          mi.identifier                          AS milestone_invoice_id,
          mi.start_date                          AS deliverable_start_date,
          mi.end_date                            AS deliverable_end_date,
          mi.create_date                         AS submitted_date,
          mi.udf_collection_fk                   AS mi_udf_collection_id,
          mi.fixed_payment_milestone_fk          AS fixed_payment_milestone_fk,
          mi.milestone_number                    AS milestone_number,
          mi.title                               AS milestone_invoice_description,
          mi.ad_hoc_payment_type_fk              AS ad_hoc_payment_type_fk,
          mi.res_payment_request_type            AS res_payment_request_type,
          mid.udf_collection_fk                  AS mid_udf_collection_id,
          mid.expenditure_fk                     AS expenditure_fk,
          mid.fixed_proj_resource_desc_fk        AS fixed_proj_resource_desc_fk,
          mid.milestone_invoice_detail_id        AS milestone_invoice_detail_id,
          ies.invoiced_amount                    AS invoiced_amount,
          mid.timecard_fk                        AS timecard_fk,
          cu.value                               AS currency_id,
          cu.description                         AS currency,
          lcc1.cac_id                            AS cac_id_1,
          lcc2.cac_id                            AS cac_id_2,
          lcc1.cac_guid                          AS cac1_guid,
          lcc1.start_date                        AS cac1_start_date,
          lcc1.end_date                          AS cac1_end_date,
          lcc2.cac_guid                          AS cac2_guid,
          lcc2.start_date                        AS cac2_start_date,
          lcc2.end_date                          AS cac2_end_date,
          mi.comments                            AS invoice_comments,
          mi.state_code                          AS payment_request_status_id,
          jcl.constant_description               AS payment_request_status
     FROM }'||v_refreshing_tab||q'{                                         lpa,
          milestone_invoice         AS OF SCN lego_refresh_mgr_pkg.get_scn() mi,
          milestone_invoice_detail  AS OF SCN lego_refresh_mgr_pkg.get_scn() mid,
          lego_cac_collection                                                lcc1,
          lego_cac_collection                                                lcc2,
          currency_unit                                                      cu,
          lego_invcd_expenditure_sum                                         ies,
          (SELECT constant_value, constant_description
             FROM java_constant_lookup
            WHERE constant_type    = 'MilestoneStatus'
              AND UPPER(locale_fk) = 'EN_US') jcl
    WHERE lpa.project_agreement_id        = mi.project_agreement_fk
      AND mi.identifier                   = mid.milestone_invoice_fk
      AND mid.cac_one_fk                  = lcc1.cac_id(+)
      AND mid.cac_two_fk                  = lcc2.cac_id(+)
      AND lpa.pa_currency_id              = cu.value(+)
      AND mi.state_code                   = jcl.constant_value(+)
      AND mid.milestone_invoice_detail_id = ies.expenditure_id(+)
      AND ies.expenditure_type(+)         = 'Milestones' }';
   
   logger_pkg.debug (v_base_pr_sql);
   
   logger_pkg.set_code_location('Build Dynamic SQL for Temporary Table, lego_base_pr_child_tmp');   
   v_base_pr_child_sql := q'{  
   SELECT /*+parallel(4)*/
          lpa.buyer_org_id                       AS buyer_org_id,
          lpa.supplier_org_id                    AS supplier_org_id,
          lpa.project_id                         AS project_id,
          lpa.project_agreement_id               AS project_agreement_id,
          mi.identifier                          AS milestone_invoice_id,
          mi.start_date                          AS deliverable_start_date,
          mi.end_date                            AS deliverable_end_date,
          mi.create_date                         AS submitted_date,
          mi.udf_collection_fk                   AS mi_udf_collection_id,
          mi.fixed_payment_milestone_fk          AS fixed_payment_milestone_fk,
          mi.milestone_number                    AS milestone_number,
          mi.title                               AS milestone_invoice_description,
          mi.ad_hoc_payment_type_fk              AS ad_hoc_payment_type_fk,
          mi.res_payment_request_type            AS res_payment_request_type,
          mi.rate_table_edition_fk               AS rate_table_edition_fk,
          mid1.udf_collection_fk                 AS mid_udf_collection_id,
          mid1.expenditure_fk                    AS expenditure_fk,
          mid1.fixed_proj_resource_desc_fk       AS fixed_proj_resource_desc_fk,
          mid2.milestone_invoice_detail_id       AS milestone_invoice_detail_id,
          mid1.timecard_fk                       AS timecard_fk,
          mid1.standard_service_rate_fk          AS standard_service_rate_fk,
          mid1.service_fk                        AS service_fk,
          ex.rate                                AS rate_table_rate,
          ex.payment_amount                      AS payment_amount,
          ex.supplier_reimbursement_amt          AS supplier_reimbursement_amount,
          ex.buyer_adjusted_amt                  AS buyer_adjusted_amount,
          ies.invoiced_amount                    AS invoiced_amount,
          DECODE(ex.is_billable_event,1,1,2)     AS billable_event_id,
          DECODE(ex.is_billable_event,1,'Yes','No') AS billable_event,
          silt.amount                            AS management_fee,
          bilt.amount                            AS contracted_fee,
          cu.value                               AS currency_id,
          cu.description                         AS currency,
          lcc1.cac_id                            AS cac_id_1,
          lcc2.cac_id                            AS cac_id_2,
          lcc1.cac_guid                          AS cac1_guid,
          lcc1.start_date                        AS cac1_start_date,
          lcc1.end_date                          AS cac1_end_date,
          lcc2.cac_guid                          AS cac2_guid,
          lcc2.start_date                        AS cac2_start_date,
          lcc2.end_date                          AS cac2_end_date,
          mi.comments                            AS invoice_comments,
          mi.state_code                          AS payment_request_status_id,
          jcl.constant_description               AS payment_request_status
     FROM }'||v_refreshing_tab||q'{                                           lpa,
          milestone_invoice         AS OF SCN lego_refresh_mgr_pkg.get_scn()  mi,
          milestone_invoice_detail  AS OF SCN lego_refresh_mgr_pkg.get_scn()  mid1,
          milestone_invoice_detail  AS OF SCN lego_refresh_mgr_pkg.get_scn()  mid2,
          expenditure               AS OF SCN lego_refresh_mgr_pkg.get_scn()  ex,
          invoice_line_item         AS OF SCN lego_refresh_mgr_pkg.get_scn()  silt,
          invoice_line_item         AS OF SCN lego_refresh_mgr_pkg.get_scn()  bilt,
          lego_cac_collection                                                 lcc1,
          lego_cac_collection                                                 lcc2,
          currency_unit                                                       cu,
          lego_invcd_expenditure_sum                                          ies, 
          (SELECT constant_value, constant_description
             FROM java_constant_lookup
            WHERE constant_type    = 'MilestoneStatus'
              AND UPPER(locale_fk) = 'EN_US') jcl
    WHERE lpa.project_agreement_id         = mi.project_agreement_fk
      AND mi.identifier                    = mid1.milestone_invoice_fk
      AND mid1.milestone_invoice_detail_id = mid2.parent_milestone_inv_detail_fk
      AND mid2.expenditure_fk              = ex.identifier
      AND ex.supplier_trx_fee_fk           = silt.identifier(+)
      AND ex.buyer_trx_fee_fk              = bilt.identifier(+)
      AND mid2.cac_one_fk                  = lcc1.cac_id(+)
      AND mid2.cac_two_fk                  = lcc2.cac_id(+)
      AND lpa.pa_currency_id               = cu.value(+)
      AND mi.state_code                    = jcl.constant_value(+)
      AND mid2.milestone_invoice_detail_id = ies.expenditure_id(+)
      AND ies.expenditure_type(+)          = 'Milestones' }';
      
     
     logger_pkg.debug (v_base_pr_sql); 
          
     lego_refresh_mgr_pkg.ctas(pi_table_name             => 'lego_base_pr_tmp',
                               pi_stmt_clob              => v_base_pr_sql,
                               pi_exadata_storage_clause => v_storage,
                               pi_partition_clause       => NULL);                                 
                                                              
     lego_refresh_mgr_pkg.ctas(pi_table_name             => 'lego_base_pr_child_tmp',
                               pi_stmt_clob              => v_base_pr_child_sql,
                               pi_exadata_storage_clause => v_storage,
                               pi_partition_clause       => NULL);                                    
      
     logger_pkg.set_code_location('Gather Stats on Temporary Tables');     
     dbms_stats.gather_table_stats(ownname              =>  gc_curr_schema,
                                       tabname          => 'LEGO_BASE_PR_TMP',
                                       estimate_percent => dbms_stats.auto_sample_size,
                                       granularity      => 'ALL',
                                       cascade          => TRUE,
                                       method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
                                       degree           => 4);

     dbms_stats.gather_table_stats(ownname              =>  gc_curr_schema,
                                       tabname          => 'LEGO_BASE_PR_CHILD_TMP',
                                       estimate_percent => dbms_stats.auto_sample_size,
                                       granularity      => 'ALL',
                                       cascade          => TRUE,
                                       method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
                                       degree           => 4);
   
      
   logger_pkg.set_code_location('Build Dynamic SQL for '||p_table_name); 
   v_pr_sql := q'{      
   WITH res_rt AS
  (SELECT /*+parallel(4)*/
          rte.name                     AS rate_table_name,
          prd.project_resource_desc_id AS project_resource_desc_id,
          prd.rate_table_edition_fk    AS rate_table_edition_fk,
          prd.estimated_start_date     AS estimated_start_date,
          prd.estimated_end_date       AS estimated_end_date,
          j.position_title             AS position_title,
          prdp.user_defined_order      AS user_defined_order,
          cu.value                     AS currency_id,
          cu.description               AS currency
     FROM project_resource_description AS OF SCN lego_refresh_mgr_pkg.get_scn() prd,
          project_res_desc_phase       AS OF SCN lego_refresh_mgr_pkg.get_scn() prdp,
          service_rate                 AS OF SCN lego_refresh_mgr_pkg.get_scn() sr,
          job                          AS OF SCN lego_refresh_mgr_pkg.get_scn() j,
          rate_table_edition           AS OF SCN lego_refresh_mgr_pkg.get_scn() rte,
          currency_unit                cu
    WHERE prdp.phase_id                = prd.phase_fk
      AND prd.service_rate_fk          = sr.service_rate_id
      AND sr.job_template_fk           = j.job_id
      AND prd.rate_table_edition_fk    = rte.rate_table_edition_id
      AND sr.currency_unit_fk          = cu.value(+)),
pr_rr_event AS
  (SELECT milestone_invoice_fk                                       AS milestone_invoice_id,
          LISTAGG(description,', ') WITHIN GROUP (ORDER BY NULL)     AS reject_reason
     FROM (SELECT DISTINCT er.description, med.milestone_invoice_fk
             FROM milestone_invoice_event_desc med,
                  event_description             ed,
                  event_name                    en,
                  event_desc_event_reason_x      x,
                  event_reason                  er
            WHERE med.identifier           = ed.identifier
              AND ed.event_name_fk         = en.VALUE
              AND en.value                 = 12003  --en.event_name = 'MilestoneInvoiceBuyerRejected'
              AND med.identifier           = x.event_desc_id
              AND x.event_reason_id        = er.value
              AND x.event_reason_type      = 'E'
              AND med.milestone_invoice_fk IS NOT NULL
            UNION ALL
           SELECT DISTINCT oe.description, med.milestone_invoice_fk
             FROM milestone_invoice_event_desc med,
                  event_description             ed,
                  event_name                    en,
                  event_desc_event_reason_x      x,
                  other_event_reason            oe
            WHERE med.identifier           = ed.identifier
              AND ed.event_name_fk         = en.VALUE
              AND en.value                 = 12003  --en.event_name = 'MilestoneInvoiceBuyerRejected'
              AND med.identifier           = x.event_desc_id
              AND x.event_reason_id        = oe.value
              AND x.event_reason_type      = 'O'
              AND med.milestone_invoice_fk IS NOT NULL
            UNION ALL
           SELECT DISTINCT ce.description, med.milestone_invoice_fk
             FROM milestone_invoice_event_desc med,
                  event_description             ed,
                  event_name                    en,
                  event_desc_event_reason_x      x,
                  custom_event_reason           ce
            WHERE med.identifier           = ed.identifier
              AND ed.event_name_fk         = en.VALUE
              AND en.value                 = 12003  --en.event_name = 'MilestoneInvoiceBuyerRejected'
              AND med.identifier           = x.event_desc_id
              AND x.event_reason_id        = ce.identifier
              AND x.event_reason_type      = 'C'
              AND med.milestone_invoice_fk IS NOT NULL)
    GROUP BY milestone_invoice_fk)
   SELECT /*+ PARALLEL(4) */ d.*, ap_date.completed_date AS mi_approved_date
     FROM ( SELECT
          base_pr.buyer_org_id                   AS buyer_org_id,
          base_pr.supplier_org_id                AS supplier_org_id,
          base_pr.project_id                     AS project_id,
          base_pr.project_agreement_id           AS project_agreement_id,
          base_pr.milestone_invoice_id           AS milestone_invoice_id,
          base_pr.milestone_invoice_detail_id    AS milestone_invoice_detail_id,
          base_pr.invoiced_amount,
          NULL                                   AS contractor_person_id,
          NULL                                   AS timecard_id,
          ppm.title                              AS milestone_invoice_description,
          NULL                                   AS adhoc_payment_type,
          base_pr.deliverable_start_date         AS deliverable_start_date,
          base_pr.deliverable_end_date           AS deliverable_end_date,
          base_pr.submitted_date                 AS submitted_date,
          base_pr.mi_udf_collection_id           AS mi_udf_collection_id,
          base_pr.mid_udf_collection_id          AS mid_udf_collection_id,
          base_pr.currency_id                    AS currency_id,
          base_pr.currency                       AS currency,
          DECODE(ex.is_billable_event,1,1,2) AS billable_event_id,
          DECODE(ex.is_billable_event,1,'Yes','No') AS billable_event,
          ex.payment_amount,
          ex.supplier_reimbursement_amt          AS supplier_reimbursement_amount,
          ex.buyer_adjusted_amt                  AS buyer_adjusted_amount,
          silt.amount                            AS management_fee,
          bilt.amount                            AS contracted_fee,
          NULL                                   AS rate_table_rate,
          NULL                                   AS rate_table_name,
          NULL                                   AS service_name,
          NULL                                   AS rate_table_edition_id,
          NULL                                   AS project_resource_request,
          base_pr.cac1_guid                      AS cac1_guid,
          base_pr.cac1_start_date                AS cac1_start_date,
          base_pr.cac1_end_date                  AS cac1_end_date,
          base_pr.cac2_guid                      AS cac2_guid,
          base_pr.cac2_start_date                AS cac2_start_date,
          base_pr.cac2_end_date                  AS cac2_end_date,
          pr_rr_event.reject_reason              AS reject_reason,
          base_pr.invoice_comments               AS invoice_comments,
          base_pr.payment_request_status_id      AS payment_request_status_id,
          base_pr.payment_request_status         AS payment_request_status,
          'Milestone Payment Request'            AS payment_request_type
     FROM lego_base_pr_tmp                                                                base_pr,
          expenditure                            AS OF SCN lego_refresh_mgr_pkg.get_scn() ex,
          invoice_line_item                      AS OF SCN lego_refresh_mgr_pkg.get_scn() silt,
          invoice_line_item                      AS OF SCN lego_refresh_mgr_pkg.get_scn() bilt,
          project_payment_milestone              AS OF SCN lego_refresh_mgr_pkg.get_scn() ppm,
          pr_rr_event
    WHERE base_pr.expenditure_fk               = ex.identifier
      AND base_pr.project_agreement_version_id = ppm.project_agreement_version_fk
      AND base_pr.milestone_number             = ppm.milestone_number
      AND ex.supplier_trx_fee_fk               = silt.identifier(+)
      AND ex.buyer_trx_fee_fk                  = bilt.identifier(+)
      AND base_pr.milestone_number             IS NOT NULL
      AND base_pr.milestone_invoice_id         = pr_rr_event.milestone_invoice_id(+)
UNION ALL
   SELECT base_pr.buyer_org_id                   AS buyer_org_id,
          base_pr.supplier_org_id                AS supplier_org_id,
          base_pr.project_id                     AS project_id,
          base_pr.project_agreement_id           AS project_agreement_id,
          base_pr.milestone_invoice_id           AS milestone_invoice_id,
          base_pr.milestone_invoice_detail_id    AS milestone_invoice_detail_id,
          base_pr.invoiced_amount,
          NULL                                   AS contractor_person_id,
          NULL                                   AS timecard_id,
          base_pr.milestone_invoice_description  AS milestone_invoice_description,
          pt.description                         AS adhoc_payment_type,
          base_pr.deliverable_start_date         AS deliverable_start_date,
          base_pr.deliverable_end_date           AS deliverable_end_date,
          base_pr.submitted_date                 AS submitted_date,
          base_pr.mi_udf_collection_id           AS mi_udf_collection_id,
          base_pr.mid_udf_collection_id          AS mid_udf_collection_id,
          base_pr.currency_id                    AS currency_id,
          base_pr.currency                       AS currency,
          DECODE(ex.is_billable_event,1,1,2) AS billable_event_id,
          DECODE(ex.is_billable_event,1,'Yes','No') AS billable_event,
          ex.payment_amount,
          ex.supplier_reimbursement_amt          AS supplier_reimbursement_amount,
          ex.buyer_adjusted_amt                  AS buyer_adjusted_amount,
          silt.amount                            AS management_fee,
          bilt.amount                            AS contracted_fee,
          NULL                                   AS rate_table_rate,
          NULL                                   AS rate_table_name,
          NULL                                   AS service_name,
          NULL                                   AS rate_table_edition_id,
          NULL                                   AS project_resource_request,
          base_pr.cac1_guid                      AS cac1_guid,
          base_pr.cac1_start_date                AS cac1_start_date,
          base_pr.cac1_end_date                  AS cac1_end_date,
          base_pr.cac2_guid                      AS cac2_guid,
          base_pr.cac2_start_date                AS cac2_start_date,
          base_pr.cac2_end_date                  AS cac2_end_date,
          pr_rr_event.reject_reason              AS reject_reason,
          base_pr.invoice_comments               AS invoice_comments,
          base_pr.payment_request_status_id      AS payment_request_status_id,
          base_pr.payment_request_status         AS payment_request_status,
         'Ad-Hoc Payment Request'                AS payment_request_type
     FROM lego_base_pr_tmp                                                   base_pr,
          expenditure               AS OF SCN lego_refresh_mgr_pkg.get_scn() ex,
          invoice_line_item         AS OF SCN lego_refresh_mgr_pkg.get_scn() silt,
          invoice_line_item         AS OF SCN lego_refresh_mgr_pkg.get_scn() bilt,
          payment_type              AS OF SCN lego_refresh_mgr_pkg.get_scn() pt,
          pr_rr_event
    WHERE base_pr.expenditure_fk         = ex.identifier
      AND base_pr.ad_hoc_payment_type_fk = pt.identifier
      AND ex.supplier_trx_fee_fk         = silt.identifier(+)
      AND ex.buyer_trx_fee_fk            = bilt.identifier(+)
      AND base_pr.ad_hoc_payment_type_fk IS NOT NULL
      AND base_pr.milestone_invoice_id   = pr_rr_event.milestone_invoice_id(+)
UNION ALL
     SELECT base_pr2.buyer_org_id                   AS buyer_org_id,
            base_pr2.supplier_org_id                AS supplier_org_id,
            base_pr2.project_id                     AS project_id,
            base_pr2.project_agreement_id           AS project_agreement_id,
            base_pr2.milestone_invoice_id           AS milestone_invoice_id,
            base_pr2.milestone_invoice_detail_id    AS milestone_invoice_detail_id,
            base_pr2.invoiced_amount,
            NULL                                    AS contractor_person_id,
            NULL                                    AS timecard_id,
            base_pr2.milestone_invoice_description  AS milestone_invoice_description,
            NULL                                    AS adhoc_payment_type,
            base_pr2.deliverable_start_date         AS deliverable_start_date,
            base_pr2.deliverable_end_date           AS deliverable_end_date,
            base_pr2.submitted_date                 AS submitted_date,
            base_pr2.mi_udf_collection_id           AS mi_udf_collection_id,
            base_pr2.mid_udf_collection_id          AS mid_udf_collection_id,
            base_pr2.currency_id                    AS currency_id,
            base_pr2.currency                       AS currency,
            base_pr2.billable_event_id              AS billable_event_id,
            base_pr2.billable_event                 AS billable_event,
            base_pr2.payment_amount                 AS payment_amount,
            base_pr2.supplier_reimbursement_amount  AS supplier_reimbursement_amount,
            base_pr2.buyer_adjusted_amount          AS buyer_adjusted_amount,
            base_pr2.management_fee                 AS management_fee,
            base_pr2.contracted_fee                 AS contracted_fee,
            base_pr2.rate_table_rate                AS rate_table_rate,
            res_rt.rate_table_name                  AS rate_table_name,
            NULL                                    AS service_name,
            NULL                                    AS rate_table_edition_id,
            'Phase # '
            || res_rt.user_defined_order
            || ' - Line # '
            || res_rt.user_defined_order
            || ' - '
            || res_rt.rate_table_name
            || ' -  '
            || res_rt.position_title
            || ' ('
            || TO_CHAR(res_rt.estimated_start_date,'MM/DD/YY')
            || ' - '
            || TO_CHAR(res_rt.estimated_end_date,'MM/DD/YY')
            || ') '
            || base_pr2.currency
            || ' '
            || LTRIM(TO_CHAR(base_pr2.rate_table_rate,'999999999.99'))      AS project_resource_request,
            base_pr2.cac1_guid                      AS cac1_guid,
            base_pr2.cac1_start_date                AS cac1_start_date,
            base_pr2.cac1_end_date                  AS cac1_end_date,
            base_pr2.cac2_guid                      AS cac2_guid,
            base_pr2.cac2_start_date                AS cac2_start_date,
            base_pr2.cac2_end_date                  AS cac2_end_date,
            pr_rr_event.reject_reason               AS reject_reason,
            base_pr2.invoice_comments               AS invoice_comments,
            base_pr2.payment_request_status_id      AS payment_request_status_id,
            base_pr2.payment_request_status         AS payment_request_status,
            'Resource Rate Table Payment Request'   AS payment_request_type
       FROM lego_base_pr_child_tmp base_pr2,
            res_rt,
            pr_rr_event
      WHERE base_pr2.fixed_proj_resource_desc_fk = res_rt.project_resource_desc_id(+)
        AND base_pr2.timecard_fk                 IS NULL
        AND base_pr2.res_payment_request_type    IS NOT NULL
        AND base_pr2.milestone_invoice_id        = pr_rr_event.milestone_invoice_id(+)
UNION ALL
   SELECT base_pr2.buyer_org_id                   AS buyer_org_id,
          base_pr2.supplier_org_id                AS supplier_org_id,
          base_pr2.project_id                     AS project_id,
          base_pr2.project_agreement_id           AS project_agreement_id,
          base_pr2.milestone_invoice_id           AS milestone_invoice_id,
          base_pr2.milestone_invoice_detail_id    AS milestone_invoice_detail_id,
          base_pr2.invoiced_amount,
          NULL                                    AS contractor_person_id,
          NULL                                    AS timecard_id,
          base_pr2.milestone_invoice_description  AS milestone_invoice_description,
          NULL                                    AS adhoc_payment_type,
          base_pr2.deliverable_start_date         AS deliverable_start_date,
          base_pr2.deliverable_end_date           AS deliverable_end_date,
          base_pr2.submitted_date                 AS submitted_date,
          base_pr2.mi_udf_collection_id           AS mi_udf_collection_id,
          base_pr2.mid_udf_collection_id          AS mid_udf_collection_id,
          base_pr2.currency_id                    AS currency_id,
          base_pr2.currency                       AS currency,
          base_pr2.billable_event_id              AS billable_event_id,
          base_pr2.billable_event                 AS billable_event,
          base_pr2.payment_amount                 AS payment_amount,
          base_pr2.supplier_reimbursement_amount  AS supplier_reimbursement_amount,
          base_pr2.buyer_adjusted_amount          AS buyer_adjusted_amount,
          base_pr2.management_fee                 AS management_fee,
          base_pr2.contracted_fee                 AS contracted_fee,
          sr.lower_rate                           AS rate_table_rate,
          rte.name                                AS rate_table_name,
          s.identifier                            AS service_name,
          rte.rate_table_edition_id               AS rate_table_edition_id,
          NULL                                    AS project_resource_request,
          base_pr2.cac1_guid                      AS cac1_guid,
          base_pr2.cac1_start_date                AS cac1_start_date,
          base_pr2.cac1_end_date                  AS cac1_end_date,
          base_pr2.cac2_guid                      AS cac2_guid,
          base_pr2.cac2_start_date                AS cac2_start_date,
          base_pr2.cac2_end_date                  AS cac2_end_date,
          pr_rr_event.reject_reason               AS reject_reason,
          base_pr2.invoice_comments               AS invoice_comments,
          base_pr2.payment_request_status_id      AS payment_request_status_id,
          base_pr2.payment_request_status         AS payment_request_status,
          'Rate Table Payment Request'            AS payment_request_type
     FROM lego_base_pr_child_tmp                                                           base_pr2,
          service_rate                            AS OF SCN lego_refresh_mgr_pkg.get_scn() sr,
          service                                 AS OF SCN lego_refresh_mgr_pkg.get_scn() s,
          rate_table_edition                      AS OF SCN lego_refresh_mgr_pkg.get_scn() rte,
          pr_rr_event
    WHERE base_pr2.standard_service_rate_fk  = sr.service_rate_id
      AND base_pr2.service_fk                = s.service_id
      AND base_pr2.rate_table_edition_fk     = rte.rate_table_edition_id
      AND base_pr2.rate_table_edition_fk     IS NOT NULL
      AND base_pr2.milestone_invoice_id      = pr_rr_event.milestone_invoice_id(+)
UNION ALL
   SELECT base_pr2.buyer_org_id                   AS buyer_org_id,
          base_pr2.supplier_org_id                AS supplier_org_id,
          base_pr2.project_id                     AS project_id,
          base_pr2.project_agreement_id           AS project_agreement_id,
          base_pr2.milestone_invoice_id           AS milestone_invoice_id,
          base_pr2.milestone_invoice_detail_id    AS milestone_invoice_detail_id,
          base_pr2.invoiced_amount,
          c.person_fk                             AS contractor_person_id,
          base_pr2.timecard_fk                    AS timecard_id,
          base_pr2.milestone_invoice_description  AS milestone_invoice_description,
          NULL                                    AS adhoc_payment_type,
          base_pr2.deliverable_start_date         AS deliverable_start_date,
          base_pr2.deliverable_end_date           AS deliverable_end_date,
          base_pr2.submitted_date                 AS submitted_date,
          base_pr2.mi_udf_collection_id           AS mi_udf_collection_id,
          base_pr2.mid_udf_collection_id          AS mid_udf_collection_id,
          NVL(res_rt.currency_id,base_pr2.currency_id)    AS currency_id,
          NVL(res_rt.currency,base_pr2.currency)          AS currency,
          base_pr2.billable_event_id              AS billable_event_id,
          base_pr2.billable_event                 AS billable_event,
          base_pr2.payment_amount                 AS payment_amount,
          base_pr2.supplier_reimbursement_amount  AS supplier_reimbursement_amount,
          base_pr2.buyer_adjusted_amount          AS buyer_adjusted_amount,
          base_pr2.management_fee                 AS management_fee,
          base_pr2.contracted_fee                 AS contracted_fee,
          base_pr2.rate_table_rate                AS rate_table_rate,
          res_rt.rate_table_name                  AS rate_table_name,
          NULL                                    AS service_name,
          res_rt.rate_table_edition_fk            AS rate_table_edition_id,
          'Phase # '
          || res_rt.user_defined_order
          || ' - Line # '
          || res_rt.user_defined_order
          || ' - '
          || res_rt.rate_table_name
          || ' -  '
          || res_rt.position_title
          || ' ('
          || TO_CHAR(res_rt.estimated_start_date,'MM/DD/YY')
          || ' - '
          || TO_CHAR(res_rt.estimated_end_date,'MM/DD/YY')
          || ') '
          || base_pr2.currency
          || ' '
          || LTRIM(TO_CHAR(base_pr2.rate_table_rate,'999999999.99'))  AS project_resource_request,
          base_pr2.cac1_guid                                          AS cac1_guid,
          base_pr2.cac1_start_date                                    AS cac1_start_date,
          base_pr2.cac1_end_date                                      AS cac1_end_date,
          base_pr2.cac2_guid                                          AS cac2_guid,
          base_pr2.cac2_start_date                                    AS cac2_start_date,
          base_pr2.cac2_end_date                                      AS cac2_end_date,
          pr_rr_event.reject_reason                                   AS reject_reason,
          base_pr2.invoice_comments                                   AS invoice_comments,
          base_pr2.payment_request_status_id                          AS payment_request_status_id,
          base_pr2.payment_request_status                             AS payment_request_status,
         'Resource Rate Table Payment Request'                        AS payment_request_type
     FROM lego_base_pr_child_tmp                                                   base_pr2,
          res_rt,
          timecard                        AS OF SCN lego_refresh_mgr_pkg.get_scn() tc,
          assignment_continuity           AS OF SCN lego_refresh_mgr_pkg.get_scn() ac,
          candidate                       AS OF SCN lego_refresh_mgr_pkg.get_scn() c,
          pr_rr_event
    WHERE base_pr2.fixed_proj_resource_desc_fk = res_rt.project_resource_desc_id(+)
      AND base_pr2.timecard_fk                 = tc.timecard_id
      AND tc.assignment_continuity_fk          = ac.assignment_continuity_id
      AND ac.candidate_fk                      = c.candidate_id
      AND base_pr2.timecard_fk                 IS NOT NULL
      AND base_pr2.res_payment_request_type    IS NOT NULL
      AND base_pr2.milestone_invoice_id        = pr_rr_event.milestone_invoice_id(+)) d,
      (SELECT approvable_id AS milestone_invoice_id, completed_date
          FROM approval_process
         WHERE approvable_type = 'MilestoneInvoice'
           AND state_code      = 3) ap_date
WHERE d.milestone_invoice_id = ap_date.milestone_invoice_id(+)
ORDER BY buyer_org_id, supplier_org_id, project_id, project_agreement_id, d.milestone_invoice_id, milestone_invoice_detail_id}';

   logger_pkg.debug (v_pr_sql);
      
   lego_refresh_mgr_pkg.ctas(pi_table_name             => p_table_name,
                             pi_stmt_clob              => v_pr_sql,
                             pi_exadata_storage_clause => v_storage,
                             pi_partition_clause       => NULL);   
                             
   logger_pkg.unset_source(v_source);                             
   
EXCEPTION
  WHEN OTHERS THEN
    v_err_msg := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
    logger_pkg.fatal('There has been a failure in load_lego_payment_request.  Check DBMS_SCHEDULER_JOB_RUN_DETAILS or PROCESSING_LOG');
    logger_pkg.unset_source(v_source);
    RAISE;

END load_lego_payment_request;

-----------------------------------

PROCEDURE load_lego_missing_time (p_table_name IN VARCHAR2)
AS

/*---------------------------------------------------------------------------*\
|| PROCEDURE NAME       : load_lego_missing_time
|| AUTHOR               : Joe Pullifrone
|| DATE CREATED         : December 10, 2012
|| PURPOSE              : This procedure is used to load data into the
||                        LEGO_MISSING_TIME_1 or
||                        LEGO_MISSING_TIME_2
|| MODIFICATION HISTORY : 02/17/2013 - J.Pullifrone - added logic to account
||                        for dates with year 9999.  Also added Order by 
||                        Release 11.2.
||                        03 Apr 2014 J.Pullifrone added () after call to get 
||                        SCN. Rel 11.2.
||                      : 08/18/2014 - pmuller - IQN-19497 - convert all logging 
||                        to use LOGGER_PKG - 12.2
\*---------------------------------------------------------------------------*/

   v_sql                         CLOB;
   v_curr_table_num_ea           NUMBER;
   v_curr_table_num_wo           NUMBER;
   v_refreshing_tab_ea           VARCHAR2(30);
   v_refreshing_tab_wo           VARCHAR2(30);
   v_refresh_object_name_1_ea    VARCHAR2(30);
   v_refresh_object_name_1_wo    VARCHAR2(30);
   v_refresh_object_name_2_ea    VARCHAR2(30);
   v_refresh_object_name_2_wo    VARCHAR2(30);
   v_storage                     lego_refresh.exadata_storage_clause%type;

BEGIN

   logger_pkg.set_code_location('lego_missing_time refresh');

   --these are the lego base tables upon which lego_missing_time relies
   --we need to figure out which of the 1 or 2 base tables was just refreshed
   BEGIN
      SELECT NVL(SUBSTR(curr_table_name,-1),2), refresh_object_name_1, refresh_object_name_2
        INTO v_curr_table_num_ea, v_refresh_object_name_1_ea, v_refresh_object_name_2_ea
        FROM lego_refresh_object_state_vw
       WHERE object_name = 'LEGO_ASSIGNMENT_EA';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_curr_table_num_ea := 2;
         v_refresh_object_name_2_ea := 'LEGO_ASSIGNMENT_EA'||v_curr_table_num_ea;
   END;

   BEGIN
      SELECT NVL(SUBSTR(curr_table_name,-1),2), refresh_object_name_1, refresh_object_name_2
        INTO v_curr_table_num_wo, v_refresh_object_name_1_wo, v_refresh_object_name_2_wo
        FROM lego_refresh_object_state_vw
       WHERE object_name = 'LEGO_ASSIGNMENT_WO';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_curr_table_num_wo := 2;
         v_refresh_object_name_2_wo := 'LEGO_ASSIGNMENT_WO'||v_curr_table_num_wo;
   END;

   SELECT exadata_storage_clause
     INTO v_storage
     FROM lego_refresh
    WHERE object_name = 'LEGO_MISSING_TIME';

   IF v_curr_table_num_ea = 1 THEN
      v_refreshing_tab_ea := v_refresh_object_name_2_ea;
   ELSE
      v_refreshing_tab_ea := v_refresh_object_name_1_ea;
   END IF;

   IF v_curr_table_num_wo = 1 THEN
      v_refreshing_tab_wo := v_refresh_object_name_2_wo;
   ELSE
      v_refreshing_tab_wo := v_refresh_object_name_1_wo;
   END IF;

   logger_pkg.debug ('Dependency tables used: ' || v_refreshing_tab_ea || ' and ' ||
                      v_refreshing_tab_wo || ', Table being built: ' || p_table_name);

   v_sql := 'CREATE TABLE '||p_table_name|| ' ' || v_storage ||' AS
    SELECT /*+parallel(4)*/
          lav.assignment_continuity_id,
          lav.buyer_org_id,
          lav.supplier_org_id,
          we_dates.this_date                     AS week_ending_date
     FROM (SELECT ea.buyer_org_id, ea.supplier_org_id, ea.assignment_continuity_id, ea.assignment_start_dt,
                  ea.assignment_end_dt, ea.assignment_actual_end_dt
             FROM '||v_refreshing_tab_ea||' ea
           UNION ALL
           SELECT wo.buyer_org_id, wo.supplier_org_id, wo.assignment_continuity_id, wo.assignment_start_dt,
                  wo.assignment_end_dt, wo.assignment_actual_end_dt
             FROM '||v_refreshing_tab_wo||' wo) lav,
          buyer_firm bf,
          firm_role fr,
          iqn_date_dimension we_dates
    WHERE bf.firm_id = fr.firm_id
      AND fr.business_org_fk = lav.buyer_org_id
      AND we_dates.this_date BETWEEN lav.assignment_start_dt AND       
                             CASE 
                               WHEN lav.assignment_end_dt <= TO_DATE(''25-DEC-9999'',''DD-MON-YYYY'') THEN lav.assignment_end_dt + 6 
                               ELSE lav.assignment_end_dt 
                             END       
      AND (lav.assignment_actual_end_dt IS NULL OR       
                             CASE 
                               WHEN lav.assignment_actual_end_dt <= TO_DATE(''25-DEC-9999'',''DD-MON-YYYY'') THEN lav.assignment_actual_end_dt + 6 
                               ELSE lav.assignment_actual_end_dt 
                             END >= we_dates.this_date)        
      AND TO_NUMBER(TO_CHAR (we_dates.this_date, ''D'')) = bf.fo_te_week_ending_day
      AND NOT EXISTS  (SELECT NULL
                         FROM timecard AS OF SCN lego_refresh_mgr_pkg.get_scn() t
                        WHERE t.assignment_continuity_fk = lav.assignment_continuity_id
                          AND t.week_ending_date = we_dates.this_date
                          AND t.state_code IN  (2,3,4))
    ORDER BY lav.buyer_org_id, lav.supplier_org_id, week_ending_date, lav.assignment_continuity_id';

   logger_pkg.debug (v_sql);
   logger_pkg.info ('building table ' || p_table_name);
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.info ('building table ' || p_table_name || ' - complete', TRUE);

EXCEPTION
   WHEN OTHERS THEN
      logger_pkg.fatal(pi_transaction_result => NULL,
                       pi_error_code         => SQLCODE,
                       pi_message            => SQLERRM);
      RAISE;

END load_lego_missing_time;

---------------

PROCEDURE load_lego_timecard_init
AS

   /*---------------------------------------------------------------------------*\
   || PROCEDURE NAME       : load_lego_timecard_init
   || AUTHOR               : Erik Clark
   || DATE CREATED         : December 05, 2012
   || PURPOSE              : This procedure is a one-time script/run that should execute
   ||                      : during the initial lego creation. It creates the table LEGO_TIMECARD,
   ||                      : and loads the table with historical data, one month at a time.
   || MODIFICATION HISTORY : 02/15/2013 - E.Clark - fixed insert to include UDFs - Release 11.2
   ||                        03/15/2013 - J.Pullifrone removed references to USER - replace with sys_context constant
   ||                        gc_curr_schema - Rel 11.2.
   ||                      : 04/10/2013 - E.Clark - complete re-write for new Timecard changes - Release 11.2.1
   ||                      : 05/20/2013 - E.Clark - adding timecard_currency_id for Currency Conversion, Jira # IQN-1008 - Release 11.2.20
   ||                      : 05/22/2013 - E.Clark - address code issue in wo.3 - Release 11.2.2
   ||                      : 05/23/2013 - E.Clark - fix defect with RATE_TRMT_RATES in WO.3 and EA.2 that were using reimb. rates - Release 11.2.2
   ||                      : 08/09/2013 - E.Clark - updated to load invoice information - IQN-6268 - Release 11.3.2
   ||                      : 09/12/2013 - E.Clark - defect on hours - IQN-6268 - Release 11.3.2
   ||                      : 02/24/2014 - E.Clark - IQN-12543 - fix for RATE_TYPE_DESC = Hourly, when they are actually Daily. - Release 12.0.1
   ||                      :                      - IQN-12543 - fix EA rates when current edition does not match ald.from-thru dates - Release 12.0.1
   ||                      :                      - Add handling to correctly calculate hourly rates when the rate_type_desc = Monthly. Rate / 160. Release 12.0.1
   ||                      : 04/02/2014 - E.Clark - IQN-14482 - only load data within the past X months based on LEGO_PARAMETER - Release 12.0.2
   ||                      : 06/13/2014 - J.Pullifrone - IQN-18002 - Instead of capturing INVOICE_ID, capture is_on_invoice instead - Release 12.1.1
   ||                      : 07/23/2014 - J.Pullifrone - IQN-19603 - Load timecards by week_ending_date instead of monthly to avoid overuse of TEMP space - Release 12.1.1 HF 
   ||                      : 08/18/2014 - pmuller - IQN-19497 - convert all logging to use LOGGER_PKG - 12.2
   ||                      : 08/26/2014 - J.Pullifrone - IQN-18776 - adding invoiced_amount based on actual invoiced_amount from lego_invoice_detail.  Invoiced amount will
   ||                      :                                         be used in expenditure summary lego.  Also removing is_on_invoice.  Release 12.2.0                                   
   \*---------------------------------------------------------------------------*/

   v_sql                   CLOB;
   v_storage               lego_refresh.exadata_storage_clause%type;

   CURSOR load_cur IS
     SELECT DISTINCT week_ending_date
       FROM timecard
      WHERE week_ending_date BETWEEN ADD_MONTHS(TRUNC(SYSDATE),-1 * gv_months_in_refresh) AND SYSDATE
     MINUS
     SELECT DISTINCT week_ending_date
       FROM lego_timecard
      ORDER BY week_ending_date DESC;

BEGIN
   /* We don't need these three logger setup steps if this is run through the refresh manager (which would be the 
      case in a from-scratch environment).  But I'm including them here since in PROD and QA databases, this is most 
      often run via a migration script.  These commands should not prevent this from working in a from-scratch database.   */
   logger_pkg.instantiate_logger;
   logger_pkg.set_level('DEBUG');  --to ensure maximum messages
   logger_pkg.set_source('Timcard Lego init/reload');

   SELECT exadata_storage_clause
     INTO v_storage
     FROM lego_refresh
    WHERE object_name = 'LEGO_TIMECARD';

   logger_pkg.set_code_location('Timecard week_ending_day loop');
      FOR load_rec IN load_cur LOOP
         logger_pkg.info('Starting timecard init load for week_ending_date: ' || TO_CHAR(load_rec.week_ending_date,'YYYY-Mon-DD'));

         logger_pkg.debug('dropping tables');
         BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE lego_tc_events PURGE';
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;

         BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_effective_rates PURGE';
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;

         BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_rates PURGE';
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;

         BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_rate_trmt_rates PURGE';
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;

         BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_tmp PURGE';
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;

         BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE lego_tc_ea_rates PURGE';
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;

         BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE lego_tc_ea_rate_trmt_rates PURGE';
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;

         BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE lego_tc_ea_tmp PURGE';
         EXCEPTION
            WHEN OTHERS THEN
               NULL;
         END;
         logger_pkg.debug('dropping tables - complete', TRUE);

         v_sql :=
             'CREATE TABLE lego_tc_events ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (8) */
                       ted.timecard_fk AS timecard_id,
                       MAX(CASE WHEN ed.event_name_fk = 22000 THEN ed.timestamp ELSE NULL END) tc_buyer_approved_date,
                       MAX(CASE WHEN ed.event_name_fk = 22001 THEN ed.timestamp ELSE NULL END) tc_buyer_rejected_date,
                       MAX(CASE WHEN ed.event_name_fk = 22003 THEN ed.timestamp ELSE NULL END) tc_created_date,
                       MAX(CASE WHEN ed.event_name_fk = 22004 THEN ed.timestamp ELSE NULL END) tc_saved_date,
                       MAX(CASE WHEN ed.event_name_fk = 22005 THEN ed.timestamp ELSE NULL END) tc_adjusted_date,
                       MAX(CASE WHEN ed.event_name_fk = 22006 THEN ed.timestamp ELSE NULL END) tc_rerated_date,
                       MAX(CASE WHEN ed.event_name_fk = 22007 THEN ed.timestamp ELSE NULL END) tc_approve_req_retract_date,
                       MAX(CASE WHEN ed.event_name_fk = 22008 THEN ed.timestamp ELSE NULL END) tc_submit_approval_date,
                       MAX(CASE WHEN ed.event_name_fk = 22011 THEN ed.timestamp ELSE NULL END) tc_archived_date,
                       MAX(CASE WHEN ed.event_name_fk = 22012 THEN ed.timestamp ELSE NULL END) tc_sar_approved_date,
                       MAX(CASE WHEN ed.event_name_fk = 22013 THEN ed.timestamp ELSE NULL END) tc_sar_rejected_date
                  FROM timecard_event_description ted,
                       event_description          ed,
                       timecard                   t
                 WHERE ted.identifier  = ed.identifier
                   AND ted.timecard_fk = t.timecard_id  
                   AND t.week_ending_date = TO_DATE('}' ||TO_CHAR(load_rec.week_ending_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')
                   AND ed.event_name_fk IN (22000, 22001, 22003, 22004, 22005, 22006, 22007, 22008, 22011, 22012, 22013)
                 GROUP BY ted.timecard_fk
                 ORDER BY ted.timecard_fk }';
         logger_pkg.debug('events for ' || TO_CHAR(load_rec.week_ending_date,'YYYY-Mon-DD'));
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('events for ' || TO_CHAR(load_rec.week_ending_date,'YYYY-Mon-DD') || ' - complete',TRUE);

         logger_pkg.debug('gather events stats');
         DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                        tabname          => 'LEGO_TC_EVENTS',
                                        estimate_percent => 10,
                                        degree           => 6);
         logger_pkg.debug('gather events stats - complete', TRUE);

         v_sql :=
             'CREATE TABLE lego_tc_wo_effective_rates ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (2,2) */
                       te1.timecard_entry_id,
                       te1.wk_date,
                       t1.week_ending_date,
                       ac1.assignment_continuity_id,
                       te1.rate_treatment_identifier_fk,
                       ac1.current_edition_fk AS assignment_edition_id,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_effective_date        ELSE NULL END AS effct_rte_effective_date,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_termination_date      ELSE NULL END AS effct_rte_termination_date,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_contract_id           ELSE NULL END AS effct_rte_contract_id,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_create_date           ELSE NULL END AS effct_rte_create_date,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_currency              ELSE NULL END AS effct_rte_currency,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_bill_rate        ELSE NULL END AS effct_rte_supp_bill_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_buyer_bill_rate       ELSE NULL END AS effct_rte_buyer_bill_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_ot_rate          ELSE NULL END AS effct_rte_supp_ot_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_buyer_ot_rate         ELSE NULL END AS effct_rte_buyer_ot_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_dt_rate          ELSE NULL END AS effct_rte_supp_dt_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_buyer_dt_rate         ELSE NULL END AS effct_rte_buyer_dt_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_adj_custom_bill_rate  ELSE NULL END AS effct_rte_adj_custom_bill_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_pay_rate              ELSE NULL END AS effct_rte_pay_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_ot_pay_rate           ELSE NULL END AS effct_rte_ot_pay_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_dt_pay_rate           ELSE NULL END AS effct_rte_dt_pay_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_rate_unit_fk          ELSE NULL END AS effct_rte_rate_unit_fk,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_rate_id_rate_set_fk   ELSE NULL END AS effct_rte_rate_id_rate_set_fk,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_markup                ELSE NULL END AS effct_rte_markup,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_ot_markup             ELSE NULL END AS effct_rte_ot_markup,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_dt_markup             ELSE NULL END AS effct_rte_dt_markup,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_rg_reim_rate     ELSE NULL END AS effct_rte_supp_rg_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_ot_reim_rate     ELSE NULL END AS effct_rte_supp_ot_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_dt_reim_rate     ELSE NULL END AS effct_rte_supp_dt_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_cs_reim_rate     ELSE NULL END AS effct_rte_supp_cs_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_rate_type_id          ELSE NULL END AS effct_rte_rate_type_id
                  FROM timecard  t1,
                       timecard_entry  te1,
                       assignment_continuity  ac1,
                       ( --get_effective_rate
                         SELECT cv1.effective_date                 AS  effct_rte_effective_date,
                                cv1.termination_date               AS  effct_rte_termination_date,
                                cv1.contract_fk                    AS  effct_rte_contract_id, --assignment_continuity_id
                                cv1.create_date                    AS  effct_rte_create_date,
                                fet_cu1.description                AS  effct_rte_currency,
                                fet1.supplier_bill_rate            AS  effct_rte_supp_bill_rate,
                                fet1.buyer_bill_rate               AS  effct_rte_buyer_bill_rate,
                                fet1.supplier_ot_rate              AS  effct_rte_supp_ot_rate,
                                fet1.buyer_ot_rate                 AS  effct_rte_buyer_ot_rate,
                                fet1.supplier_dt_rate              AS  effct_rte_supp_dt_rate,
                                fet1.buyer_dt_rate                 AS  effct_rte_buyer_dt_rate,
                                fet1.buyer_adj_bill_rate_rt_idntfr AS  effct_rte_adj_custom_bill_rate,
                                fet1.pay_rate                      AS  effct_rte_pay_rate,
                                fet1.ot_pay_rate                   AS  effct_rte_ot_pay_rate,
                                fet1.dt_pay_rate                   AS  effct_rte_dt_pay_rate,
                                fet1.buyer_bill_rate_unit_fk       AS  effct_rte_rate_unit_fk,
                                fet1.rate_identifier_rate_set_fk   AS  effct_rte_rate_id_rate_set_fk,
                                fet1.mark_up                       AS  effct_rte_markup,
                                fet1.ot_mark_up                    AS  effct_rte_ot_markup,
                                fet1.dt_mark_up                    AS  effct_rte_dt_markup,
                                NVL(fet1.supplier_reimbursement_rate,0)    AS  effct_rte_supp_rg_reim_rate,
                                NVL(fet1.supplier_ot_reimbursement_rate,0) AS  effct_rte_supp_ot_reim_rate,
                                NVL(fet1.supplier_dt_reimbursement_rate,0) AS  effct_rte_supp_dt_reim_rate,
                                NVL(fet1.supplier_reimburse_rt_idntfr,0)   AS  effct_rte_supp_cs_reim_rate,
                                fet1.buyer_bill_rate_unit_fk               AS  effct_rte_rate_type_id
                           FROM currency_unit        fet_cu1,
                                fee_expense_term     fet1,
                                contract_term        fet_ct1,
                                work_order_version   wov1,
                                contract_version     cv1
                          WHERE cv1.contract_version_id          = wov1.contract_version_id
                            AND wov1.contract_version_id         = fet_ct1.contract_version_fk
                            AND wov1.work_order_version_state NOT IN (7,8,22,23,21,15,16,24) -- Get rid of Cancels; SFI# 110302-342903 21,15,16,24 are excluded
                            AND fet_ct1.contract_term_id         = fet1.contract_term_id
                            AND fet1.currency_unit_fk            = fet_cu1.value
                            AND fet_ct1.type                     = 'FeeAndExpenseTerm'
                            AND wov1.approval_status in (5,6)    -- Only 'Approved' or 'Approval Not Required'
                          ) effective_rates
                 WHERE t1.week_ending_date = TO_DATE('}' ||TO_CHAR(load_rec.week_ending_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')
                   AND t1.assignment_continuity_fk  = ac1.assignment_continuity_id
                   AND ac1.assignment_continuity_id = effective_rates.effct_rte_contract_id (+)
                   AND t1.timecard_id               = te1.timecard_fk
                   AND ac1.work_order_fk IS NOT NULL
                   AND ABS(NVL(te1.hours,0)) + ABS(NVL(te1.change_to_hours,0)) != 0 }';

         logger_pkg.debug('create table tc_wo_effective_rates');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('create table tc_wo_effective_rates - complete', TRUE);

         logger_pkg.debug('tc_wo_effective_rates stats');
         DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                        tabname          => 'LEGO_TC_WO_EFFECTIVE_RATES',
                                        estimate_percent => 10,
                                        degree           => 6);
         logger_pkg.debug('tc_wo_effective_rates stats - complete', TRUE);

         v_sql :=
             'CREATE TABLE lego_tc_wo_rates ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (2,2) */
                       t1.timecard_entry_id,
                       t1.wk_date,
                       t1.assignment_continuity_id,
                       rates.effective_date,
                       rates.termination_date,
                       rates.contract_id,
                       rates.currency_code,
                       rates.supplier_bill_rate,
                       rates.buyer_bill_rate,
                       rates.supplier_ot_rate,
                       rates.buyer_ot_rate,
                       rates.supplier_dt_rate,
                       rates.buyer_dt_rate,
                       rates.buyer_custom_bill_rate,
                       rates.rate_type_id
                  FROM (SELECT DISTINCT timecard_entry_id, wk_date, assignment_continuity_id
                          FROM lego_tc_wo_effective_rates) t1,
                       ( --get_rate_info
                        SELECT cv.contract_fk                  AS contract_id, --assignment_continuity_id
                               cv.contract_version_name        AS contract_version_name,
                               cv.contract_version_number      AS contract_version_number,
                               cv.effective_date,
                               cv.termination_date             AS termination_date,
                               fet_cu.description              AS currency_code,
                               NVL(fet.supplier_bill_rate, 0)  AS supplier_bill_rate,
                               NVL(fet.buyer_bill_rate, 0)     AS buyer_bill_rate,
                               NVL(fet.supplier_ot_rate, 0)    AS supplier_ot_rate,
                               NVL(fet.buyer_ot_rate, 0)       AS buyer_ot_rate,
                               NVL(fet.supplier_dt_rate, 0)    AS supplier_dt_rate,
                               NVL(fet.buyer_dt_rate, 0)       AS buyer_dt_rate,
                               NVL(fet.buyer_adj_bill_rate_rt_idntfr, 0)   AS buyer_custom_bill_rate,
                               fet.buyer_bill_rate_unit_fk     AS rate_type_id
                          FROM contract_version     cv,
                               work_order_version   wov,
                               fee_expense_term     fet,
                               contract_term        fet_ct,
                               currency_unit        fet_cu
                         WHERE cv.contract_version_id           = wov.contract_version_id
                           AND wov.contract_version_id          = fet_ct.contract_version_fk
                           AND wov.work_order_version_state NOT IN (7, 8, 22, 23)
                           AND fet_ct.contract_term_id          = fet.contract_term_id
                           AND fet.currency_unit_fk             = fet_cu.value
                           AND fet_ct.type                      = 'FeeAndExpenseTerm' ) rates
                 WHERE t1.assignment_continuity_id  = rates.contract_id (+)
                   AND rates.contract_version_name  =
                                NVL
                                   ( (SELECT MAX(TO_NUMBER(cv1.contract_version_name))
                                       FROM contract_version cv1
                                       WHERE cv1.contract_fk = contract_id
                                         AND CASE WHEN t1.wk_date IS NOT NULL THEN t1.wk_date
                                             ELSE TO_DATE ('31-JAN-1950','DD-MON-YYYY')
                                             END BETWEEN DECODE (t1.wk_date, NULL, TO_DATE('31-JAN-1950','DD-MON-YYYY'), cv1.effective_date)
                                                     AND DECODE (t1.wk_date, NULL, TO_DATE('31-JAN-1950','DD-MON-YYYY'), cv1.termination_date)
                                          AND EXISTS
                                          ( SELECT 'FOUND'
                                              FROM work_order_version wov1
                                             WHERE wov1.contract_version_id = cv1.contract_version_id
                                               AND wov1.work_order_version_state NOT IN (7, 8, 22, 23))
                                          ),
                                    (SELECT MAX(TO_NUMBER(cv1.contract_version_name))
                                       FROM contract_version cv1
                                      WHERE cv1.contract_fk = contract_id)
                                   )}';

         logger_pkg.debug('create lego_tc_wo_rates');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('create lego_tc_wo_rates - complete',TRUE);

         logger_pkg.debug('stats on lego_tc_wo_rates');
         DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                        tabname          => 'LEGO_TC_WO_RATES',
                                        estimate_percent => 10,
                                        degree           => 6);
         logger_pkg.debug('stats on lego_tc_wo_rates - complete',TRUE);

         v_sql :=
             'CREATE TABLE lego_tc_wo_rate_trmt_rates ' ||
                 v_storage ||
              q'{ AS
                  SELECT /*+ PARALLEL (12) */
                         t1.timecard_entry_id,
                         t1.wk_date,
                         t1.assignment_continuity_id,
                         wo_rate_trmt_rates.effective_date,
                         wo_rate_trmt_rates.termination_date,
                         rate_trmt_reg_bill_rate,
                         rate_trmt_ot_bill_rate,
                         rate_trmt_dt_bill_rate,
                         wo_rate_trmt_rates.rate_trmt_cust_bill_rate,
                         rate_trmt_adj_reg_bill_rate,
                         rate_trmt_adj_ot_bill_rate,
                         rate_trmt_adj_dt_bill_rate,
                         rt_trmt_cust_rates.rate_trmt_adj_cust_bill_rate,
                         rate_trmt_rate_type_id
                      FROM (SELECT DISTINCT
                                   timecard_entry_id,
                                   wk_date,
                                   assignment_continuity_id,
                                   rate_treatment_identifier_fk, assignment_edition_id
                              FROM lego_tc_wo_effective_rates
                             WHERE rate_treatment_identifier_fk IS NOT NULL) t1,
                         ( --get_wo_rate_trmt
                          SELECT ae.assignment_edition_id,
                                 te.timecard_entry_id,
                                 cv.contract_version_number,
                                 cv.effective_date,
                                 cv.termination_date,
                                 rate_trmt_rs1.bill_rate              AS rate_trmt_reg_bill_rate,
                                 rate_trmt_rs1.ot_bill_rate           AS rate_trmt_ot_bill_rate,
                                 rate_trmt_rs1.dt_bill_rate           AS rate_trmt_dt_bill_rate,
                                 cust_rate.rate                       AS rate_trmt_cust_bill_rate,
                                 aart.buyer_adj_bill_rate             AS rate_trmt_adj_reg_bill_rate,
                                 aart.buyer_adj_bill_rate_ot          AS rate_trmt_adj_ot_bill_rate,
                                 aart.buyer_adj_bill_rate_dt          AS rate_trmt_adj_dt_bill_rate,
                                 aart.supplier_reimbursement_rate     AS rate_trmt_reg_reimb_rate,
                                 aart.supplier_reimbursement_rate_ot  AS rate_trmt_ot_reimb_rate,
                                 aart.supplier_reimbursement_rate_dt  AS rate_trmt_dt_reimb_rate,
                                 fet.buyer_bill_rate_unit_fk          AS rate_trmt_rate_type_id
                            FROM contract_term                  fet_ct,
                                 fee_expense_term               fet,
                                 work_order                     wo,
                                 contract                       c,
                                 contract_version               cv,
                                 work_order_version             wov,
                                 rate_card_identifier           rci,
                                 assignment_agreement_rate_trmt aart,
                                 rate_set                       rate_trmt_rs1,
                                 assignment_continuity          ac,
                                 assignment_edition             ae,
                                 timecard_entry                 te,
                                 (SELECT *
                                    FROM rate_category_rate
                                   WHERE rate_category_fk = 3)  cust_rate
                           WHERE ac.work_order_fk IS NOT NULL
                             AND ae.assignment_edition_id        = ac.current_edition_fk
                             AND wo.contract_id                  = ac.assignment_continuity_id
                             AND wo.contract_id                  = c.contract_id
                             AND cv.contract_fk                  = c.contract_id
                             AND cv.contract_version_id          = wov.contract_version_id
                             AND cv.contract_version_id          = fet_ct.contract_version_fk
                             AND fet_ct.type                     = 'FeeAndExpenseTerm'
                             AND fet_ct.contract_term_id         = fet.contract_term_id
                             AND fet.contract_term_id            = aart.fee_expense_term_fk(+)
                             AND aart.rate_trmt_identifier_fk    = rci.rate_card_identifier_id(+)
                             AND rate_trmt_rs1.rate_set_id       = aart.treatment_rate_set_fk
                             AND te.rate_treatment_identifier_fk = aart.rate_trmt_identifier_fk
                             AND rate_trmt_rs1.rate_identifier_rate_set_fk = cust_rate.rate_identifier_rate_set_fk(+)
                          )  wo_rate_trmt_rates,
                         (--get rate treatment CUSTOM rates
                          SELECT aart.rate_trmt_identifier_fk,
                                 NVL(MAX(aart.buyer_adj_bill_rate_rt_idntfr),0) AS rate_trmt_adj_cust_bill_rate
                            FROM assignment_agreement_rate_trmt aart,
                                 fee_expense_term               fet
                           WHERE fet.contract_term_id = aart.fee_expense_term_fk(+)
                           GROUP BY aart.rate_trmt_identifier_fk) rt_trmt_cust_rates
                   WHERE t1.assignment_edition_id = wo_rate_trmt_rates.assignment_edition_id
                     AND t1.timecard_entry_id     = wo_rate_trmt_rates.timecard_entry_id
                     AND wo_rate_trmt_rates.contract_version_number = (SELECT MAX(cv1.contract_version_number)
                                                                        FROM contract_version   cv1,
                                                                             work_order_version wov1
                                                                       WHERE cv1.contract_fk         = t1.assignment_continuity_id--cv.contract_fk
                                                                         AND cv1.contract_version_id = wov1.contract_version_id
                                                                         AND (cv1.object_version_state <> 4
                                                                              OR cv1.contract_type = 'WO')
                                                                         AND t1.wk_date BETWEEN cv1.effective_date AND NVL(cv1.termination_date, SYSDATE))
                     AND t1.rate_treatment_identifier_fk = rt_trmt_cust_rates.rate_trmt_identifier_fk(+)}';
         logger_pkg.debug('create lego_tc_wo_rate_trmt_rates');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('create lego_tc_wo_rate_trmt_rates - complete', TRUE);

         logger_pkg.debug('stats on lego_tc_wo_rate_trmt_rates');
         DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                        tabname          => 'LEGO_TC_WO_RATE_TRMT_RATES',
                                        estimate_percent => 10,
                                        degree           => 6);
         logger_pkg.debug('stats on lego_tc_wo_rate_trmt_rates - complete', TRUE);

         v_sql :=
             'CREATE TABLE lego_tc_wo_tmp ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (10) */
                       point1.timecard_entry_id,
                       point1.timecard_id,
                       point1.buyer_org_id,
                       point1.supplier_org_id,
                       point1.contractor_person_id,
                       point1.hiring_mgr_person_id,
                       point1.candidate_id,
                       point1.wk_date,
                       point1.week_ending_date,
                       point1.timecard_number,
                       point1.timecard_type,
                       point1.cac1_identifier,
                       point1.cac2_identifier,
                       point1.job_id,
                       point1.assignment_continuity_id,
                       point1.work_order_id,
                       point1.assignment_edition_id,
                       point1.timecard_approval_workflow_id,
                       point1.te_udf_collection_id,
                       point1.t_udf_collection_id,
                       SUM(point1.reg_fo_hours)     AS reg_hours,
                       SUM(point1.ot_fo_hours)      AS ot_hours,
                       SUM(point1.dt_fo_hours)      AS dt_hours,
                       SUM(point1.custom_fo_hours)  AS custom_hours,
                       SUM(point1.reg_fo_hours)+
                          SUM(point1.ot_fo_hours)+
                          SUM(point1.dt_fo_hours)+
                          SUM(point1.custom_fo_hours)  AS total_hours_day,
                       point1.change_to_hours       AS total_change_to_hours_day,
                       point1.timecard_state_id,
                       point1.timecard_state,
                       point1.rate_trmt_id,
                       CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id) 
                          WHEN 0 THEN 0 --Hourly
                          WHEN 1 THEN 1 --Daily
                          WHEN 4 THEN 4 --Weekly
                          WHEN 3 THEN 3 --Monthly
                          ELSE NULL
                       END AS rate_type,
                       CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id)
                          WHEN 0 THEN 'Hourly'
                          WHEN 1 THEN 'Daily'
                          WHEN 2 THEN 'Annual'
                          WHEN 3 THEN 'Monthly'
                          WHEN 4 THEN 'Weekly'
                          ELSE 'N/A'
                       END AS rate_type_desc,
                       point1.hours_per_day,
                       point1.is_break,
                       point1.tc_buyer_approved_date,
                       point1.tc_buyer_rejected_date,
                       point1.tc_created_date,
                       point1.tc_saved_date,
                       point1.tc_adjusted_date,
                       point1.tc_rerated_date,
                       point1.tc_approve_req_retract_date,
                       point1.tc_submit_approval_date,
                       point1.tc_archived_date,
                       point1.tc_sar_approved_date,
                       point1.tc_sar_rejected_date,
                       point1.cac1_start_date,
                       point1.cac1_end_date,
                       point1.cac1_guid,
                       point1.cac2_start_date,
                       point1.cac2_end_date,
                       point1.cac2_guid,
                       point1.timecard_currency_id,
                       point1.timecard_currency,
                       ---RATES---
                       COALESCE(point1.effct_rte_supp_bill_rate, rates.supplier_bill_rate, 0) AS reg_bill_rate,
                       COALESCE(point1.effct_rte_supp_ot_rate, rates.supplier_ot_rate, 0)     AS ot_bill_rate,
                       COALESCE(point1.effct_rte_supp_dt_rate, rates.supplier_dt_rate, 0)     AS dt_bill_rate,
                       NVL(c_rate.custom_bill_rate, 0)                                        AS custom_bill_rate,
                       COALESCE(point1.effct_rte_buyer_bill_rate, rates.buyer_bill_rate, 0)   AS adj_reg_bill_rate,
                       COALESCE(point1.effct_rte_buyer_ot_rate, rates.buyer_ot_rate, 0)       AS adj_ot_bill_rate,
                       COALESCE(point1.effct_rte_buyer_dt_rate, rates.buyer_dt_rate, 0)       AS adj_dt_bill_rate,
                       NVL(rates.buyer_custom_bill_rate, 0)                                   AS adj_custom_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_reg_bill_rate,0)                         AS rate_trmt_reg_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_ot_bill_rate,0)                          AS rate_trmt_ot_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_dt_bill_rate,0)                          AS rate_trmt_dt_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_cust_bill_rate,0)                        AS rate_trmt_cust_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_reg_bill_rate,0)                     AS rate_trmt_adj_reg_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_ot_bill_rate,0)                      AS rate_trmt_adj_ot_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_dt_bill_rate,0)                      AS rate_trmt_adj_dt_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_cust_bill_rate,0)                    AS rate_trmt_adj_cust_bill_rate
                  FROM (
                  SELECT DISTINCT
                         lt.timecard_entry_id,
                         lt.timecard_id,
                         lt.buyer_org_id,
                         lt.supplier_org_id,
                         lt.contractor_person_id,
                         lt.hiring_mgr_person_id,
                         lt.candidate_id,
                         lt.wk_date,
                         lt.week_ending_date,
                         lt.timecard_number,
                         lt.timecard_type,
                         lt.cac1_identifier,
                         lt.cac2_identifier,
                         lt.job_id,
                         lt.assignment_continuity_id,
                         lt.work_order_id,
                         lt.assignment_edition_id,
                         lt.timecard_approval_workflow_id,
                         lt.te_udf_collection_id,
                         lt.t_udf_collection_id,
                         lt.reg_fo_hours,    --sum above to flatten into 1 row
                         lt.ot_fo_hours,     --sum above to flatten into 1 row
                         lt.dt_fo_hours,     --sum above to flatten into 1 row
                         lt.custom_fo_hours, --sum above to flatten into 1 row
                         lt.hours,
                         lt.change_to_hours,
                         lt.timecard_state_id,
                         lt.timecard_state,
                         lt.rate_trmt_id,
                         lt.hours_per_day,
                         lt.is_break,
                         lt.tc_buyer_approved_date,
                         lt.tc_buyer_rejected_date,
                         lt.tc_created_date,
                         lt.tc_saved_date,
                         lt.tc_adjusted_date,
                         lt.tc_rerated_date,
                         lt.tc_approve_req_retract_date,
                         lt.tc_submit_approval_date,
                         lt.tc_archived_date,
                         lt.tc_sar_approved_date,
                         lt.tc_sar_rejected_date,
                         lt.cac1_start_date,
                         lt.cac1_end_date,
                         lt.cac1_guid,
                         lt.cac2_start_date,
                         lt.cac2_end_date,
                         lt.cac2_guid,
                         lt.timecard_currency_id,
                         lt.timecard_currency,
                         ---EFFECTIVE RATES----
                         wo_effct_rates.effct_rte_effective_date,
                         wo_effct_rates.effct_rte_termination_date,
                         wo_effct_rates.effct_rte_contract_id,
                         wo_effct_rates.effct_rte_create_date,
                         wo_effct_rates.effct_rte_currency,
                         wo_effct_rates.effct_rte_supp_bill_rate,
                         wo_effct_rates.effct_rte_buyer_bill_rate,
                         wo_effct_rates.effct_rte_supp_ot_rate,
                         wo_effct_rates.effct_rte_buyer_ot_rate,
                         wo_effct_rates.effct_rte_supp_dt_rate,
                         wo_effct_rates.effct_rte_buyer_dt_rate,
                         wo_effct_rates.effct_rte_adj_custom_bill_rate,
                         wo_effct_rates.effct_rte_pay_rate,
                         wo_effct_rates.effct_rte_ot_pay_rate,
                         wo_effct_rates.effct_rte_dt_pay_rate,
                         wo_effct_rates.effct_rte_rate_unit_fk,
                         wo_effct_rates.effct_rte_rate_id_rate_set_fk,
                         wo_effct_rates.effct_rte_markup,
                         wo_effct_rates.effct_rte_ot_markup,
                         wo_effct_rates.effct_rte_dt_markup,
                         wo_effct_rates.effct_rte_supp_rg_reim_rate,
                         wo_effct_rates.effct_rte_supp_ot_reim_rate,
                         wo_effct_rates.effct_rte_supp_dt_reim_rate,
                         wo_effct_rates.effct_rte_supp_cs_reim_rate,
                         wo_effct_rates.effct_rte_rate_type_id,
                         RANK() OVER (PARTITION BY lt.timecard_entry_id ORDER BY wo_effct_rates.effct_rte_create_date DESC NULLS LAST ) rates_rk
                   FROM
                       (SELECT
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 1 THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 1 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS reg_fo_hours,
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 2 THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 2 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS ot_fo_hours,
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 3 THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 3 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS dt_fo_hours,
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk  NOT IN (1,2,3) THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id  NOT IN (1,2,3) AND ri.is_billable = 1 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS custom_fo_hours,
                               te.timecard_entry_id,
                               t.timecard_id,
                               fr.business_org_fk                 AS buyer_org_id,
                               frs.business_org_fk                AS supplier_org_id,
                               c.person_fk                        AS contractor_person_id,
                               hfw.user_fk                        AS hiring_mgr_person_id,
                               c.candidate_id                     AS candidate_id,
                               te.wk_date                         AS wk_date,
                               t.week_ending_date                 AS week_ending_date,
                               t.timecard_number                  AS timecard_number,
                               t.timecard_type                    AS timecard_type,
                               te.cac1_fk                         AS cac1_identifier,
                               te.cac2_fk                         AS cac2_identifier,
                               ac.job_fk                          AS job_id,
                               ac.assignment_continuity_id        AS assignment_continuity_id,
                               ac.work_order_fk                   AS work_order_id,
                               ac.currency_unit_fk                AS timecard_currency_id,
                               cu.description                     AS timecard_currency,
                               ae.assignment_edition_id           AS assignment_edition_id,
                               ae.timecard_approval_workflow_fk   AS timecard_approval_workflow_id,
                               te.udf_collection_fk               AS te_udf_collection_id,
                               t.udf_collection_fk                AS t_udf_collection_id,
                               NVL(te.hours,0)                    AS hours,
                               NVL(te.change_to_hours,0)          AS change_to_hours,
                               t.state_code                       AS timecard_state_id,
                               NVL(timecard_state.constant_description, 'Unknown')  AS timecard_state,
                               rci.description                    AS rate_trmt_id,
                               NVL(hpd.hours_per_day,8)           AS hours_per_day,
                               te.is_break,
                               event_dates.tc_buyer_approved_date,
                               event_dates.tc_buyer_rejected_date,
                               event_dates.tc_created_date,
                               event_dates.tc_saved_date,
                               event_dates.tc_adjusted_date,
                               event_dates.tc_rerated_date,
                               event_dates.tc_approve_req_retract_date,
                               event_dates.tc_submit_approval_date,
                               event_dates.tc_archived_date,
                               event_dates.tc_sar_approved_date,
                               event_dates.tc_sar_rejected_date,
                               cac1.start_date AS cac1_start_date,
                               cac1.end_date   AS cac1_end_date,
                               cac1.cac_guid   AS cac1_guid,
                               cac2.start_date AS cac2_start_date,
                               cac2.end_date   AS cac2_end_date,
                               cac2.cac_guid   AS cac2_guid
                          FROM timecard        t,
                               timecard_entry  te,
                               (SELECT * FROM time_expenditure WHERE is_current = 1) tx,
                               assignment_continuity  ac,
                               assignment_edition     ae,
                               firm_role              fr,
                               firm_role              frs,
                               candidate              c,
                               firm_worker            hfw,
                               rate_identifier        ri,
                               currency_unit          cu,
                               (SELECT constant_value, constant_description
                                  FROM java_constant_lookup
                                 WHERE constant_type    = 'TIMECARD_STATE'
                                   AND UPPER(locale_fk) = 'EN_US') timecard_state,
                               (SELECT lcc.cac_id,
                                       lcc.start_date,
                                       lcc.end_date,
                                       lcc.cac_guid
                                  FROM lego_cac_collection lcc ) cac1,
                               (SELECT lcc.cac_id,
                                       lcc.start_date,
                                       lcc.end_date,
                                       lcc.cac_guid
                                  FROM lego_cac_collection lcc ) cac2,
                               lego_tc_events event_dates,
                               (SELECT pwe.procurement_wkfl_edition_id, wpd.hours_per_day
                                  FROM work_period_definition wpd, procurement_wkfl_edition pwe
                                 WHERE pwe.work_period_definition_fk = wpd.work_period_definition_id)  hpd,
                               (SELECT rate_card_identifier_id, description
                                  FROM rate_card_identifier) rci
                         WHERE t.week_ending_date = TO_DATE('}' ||TO_CHAR(load_rec.week_ending_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')
                           AND t.assignment_continuity_fk      = ac.assignment_continuity_id
                           AND ac.assignment_continuity_id     = ae.assignment_continuity_fk
                           AND ac.current_edition_fk           = ae.assignment_edition_id
                           AND ac.work_order_fk IS NOT NULL
                           AND ac.candidate_fk                 = c.candidate_id(+)
                           AND ac.currency_unit_fk             = cu.value
                           AND ae.hiring_mgr_fk                = hfw.firm_worker_id(+)
                           AND t.timecard_id                   = te.timecard_fk
                           AND t.procurement_wkfl_edition_fk   = hpd.procurement_wkfl_edition_id (+)
                           AND te.timecard_entry_id            = tx.timecard_entry_fk (+)
                           AND te.rate_identifier_fk           = ri.rate_identifier_id
                           AND te.rate_treatment_identifier_fk = rci.rate_card_identifier_id (+)
                           AND ac.owning_buyer_firm_fk         = fr.firm_id
                           AND ac.owning_supply_firm_fk        = frs.firm_id
                           AND t.state_code                    = timecard_state.constant_value(+)
                           AND te.cac1_fk                      = cac1.cac_id(+)
                           AND te.cac2_fk                      = cac2.cac_id(+)
                           AND t.state_code != 7
                           AND ABS(NVL(te.hours,0)) + ABS(NVL(te.change_to_hours,0)) != 0
                           AND CASE WHEN te.change_to_hours <= 0 THEN 1
                               ELSE NVL (te.change_to_hours, 0) END
                               >
                               CASE WHEN timecard_type = 'Timecard Adjustment' THEN 0
                               ELSE -1 END
                           AND t.timecard_id                   = event_dates.timecard_id(+) ) lt,
                       lego_tc_wo_effective_rates wo_effct_rates
                  WHERE lt.timecard_entry_id = wo_effct_rates.timecard_entry_id
                    AND lt.week_ending_date = TO_DATE('}' ||TO_CHAR(load_rec.week_ending_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')
                    AND lt.wk_date BETWEEN NVL(wo_effct_rates.effct_rte_effective_date,TO_DATE('25-OCT-1971','DD-MON-YYYY')) AND NVL(wo_effct_rates.effct_rte_termination_date, SYSDATE)
                       ) point1,
                       lego_tc_wo_rates rates, --use when effective rates are null
                  (SELECT rate_identifier_rate_set_fk, rate AS custom_bill_rate
                     FROM rate_category_rate
                    WHERE rate_category_fk = 3) c_rate, --used to get wo custom supplier bill rate
                  lego_tc_wo_rate_trmt_rates rate_trmt_rates
                WHERE point1.rates_rk                       = 1
                  AND point1.timecard_entry_id              = rates.timecard_entry_id (+)
                  AND point1.effct_rte_rate_id_rate_set_fk  = c_rate.rate_identifier_rate_set_fk (+)
                  AND point1.timecard_entry_id              = rate_trmt_rates.timecard_entry_id (+)
                  GROUP BY
                         point1.timecard_entry_id,
                         point1.timecard_id,
                         point1.buyer_org_id,
                         point1.supplier_org_id,
                         point1.contractor_person_id,
                         point1.hiring_mgr_person_id,
                         point1.candidate_id,
                         point1.wk_date,
                         point1.week_ending_date,
                         point1.timecard_number,
                         point1.timecard_type,
                         point1.cac1_identifier,
                         point1.cac2_identifier,
                         point1.job_id,
                         point1.assignment_continuity_id,
                         point1.work_order_id,
                         point1.assignment_edition_id,
                         point1.timecard_approval_workflow_id,
                         point1.te_udf_collection_id,
                         point1.t_udf_collection_id,
                         point1.hours,
                         point1.change_to_hours,
                         point1.timecard_state_id,
                         point1.timecard_state,
                         point1.rate_trmt_id,
                         CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id) 
                            WHEN 0 THEN 0 --Hourly
                            WHEN 1 THEN 1 --Daily
                            WHEN 4 THEN 4 --Weekly
                            WHEN 3 THEN 3 --Monthly
                            ELSE NULL
                         END,
                         CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id)
                            WHEN 0 THEN 'Hourly'
                            WHEN 1 THEN 'Daily'
                            WHEN 2 THEN 'Annual'
                            WHEN 3 THEN 'Monthly'
                            WHEN 4 THEN 'Weekly'
                            ELSE 'N/A'
                         END,
                         point1.hours_per_day,
                         point1.is_break,
                         point1.tc_buyer_approved_date,
                         point1.tc_buyer_rejected_date,
                         point1.tc_created_date,
                         point1.tc_saved_date,
                         point1.tc_adjusted_date,
                         point1.tc_rerated_date,
                         point1.tc_approve_req_retract_date,
                         point1.tc_submit_approval_date,
                         point1.tc_archived_date,
                         point1.tc_sar_approved_date,
                         point1.tc_sar_rejected_date,
                         point1.cac1_start_date,
                         point1.cac1_end_date,
                         point1.cac1_guid,
                         point1.cac2_start_date,
                         point1.cac2_end_date,
                         point1.cac2_guid,
                         point1.timecard_currency_id,
                         point1.timecard_currency,
                         COALESCE(point1.effct_rte_supp_bill_rate, rates.supplier_bill_rate, 0),
                         COALESCE(point1.effct_rte_supp_ot_rate, rates.supplier_ot_rate, 0),
                         COALESCE(point1.effct_rte_supp_dt_rate, rates.supplier_dt_rate, 0),
                         NVL(c_rate.custom_bill_rate, 0),
                         COALESCE(point1.effct_rte_buyer_bill_rate, rates.buyer_bill_rate, 0),
                         COALESCE(point1.effct_rte_buyer_ot_rate, rates.buyer_ot_rate, 0),
                         COALESCE(point1.effct_rte_buyer_dt_rate, rates.buyer_dt_rate, 0),
                         NVL(rates.buyer_custom_bill_rate, 0),
                         point1.effct_rte_rate_id_rate_set_fk,
                         NVL(rate_trmt_rates.rate_trmt_reg_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_ot_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_dt_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_cust_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_reg_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_ot_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_dt_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_cust_bill_rate,0)}';
         logger_pkg.debug('create lego_tc_wo_tmp');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('create lego_tc_wo_tmp - complete', TRUE);

         --Start EA!
         v_sql :=
             'CREATE TABLE lego_tc_ea_rates ' ||
                 v_storage ||
              q'{ AS
                  SELECT /*+ PARALLEL (2,2) */
                         timecard_entry_id,
                         timecard_id,
                         wk_date,
                         week_ending_date,
                         assignment_continuity_id,
                         rate_treatment_identifier_fk,
                         assignment_edition_id,
                         rates_effective_date,
                         rates_termination_date,
                         currency_code,
                         NVL(supplier_bill_rate,0)        AS supplier_bill_rate,
                         NVL(buyer_bill_rate,0)           AS buyer_bill_rate,
                         NVL(supplier_ot_rate,0)          AS supplier_ot_rate,
                         NVL(buyer_ot_rate,0)             AS buyer_ot_rate,
                         NVL(supplier_dt_rate,0)          AS supplier_dt_rate,
                         NVL(buyer_dt_rate,0)             AS buyer_dt_rate,
                         NVL(custom_rate.rate,0)          AS custom_bill_rate,
                         NVL(adjusted_custom_bill_rate,0) AS adjusted_custom_bill_rate,
                         rates.rate_identifier_rate_set_fk,
                         rate_type_id
                    FROM (SELECT timecard_entry_id,
                                 timecard_id,
                                 wk_date,
                                 week_ending_date,
                                 assignment_continuity_id,
                                 rate_treatment_identifier_fk,
                                 assignment_edition_id,
                                 rates_effective_date,
                                 rates_termination_date,
                                 currency_code,
                                 supplier_bill_rate,
                                 buyer_bill_rate,
                                 supplier_ot_rate,
                                 buyer_ot_rate,
                                 supplier_dt_rate,
                                 buyer_dt_rate,
                                 adjusted_custom_bill_rate,
                                 rate_identifier_rate_set_fk,
                                 rate_type_id,
                                 RANK () OVER (PARTITION BY timecard_entry_id ORDER BY rates_effective_date DESC NULLS LAST, rownum DESC) rk
                            FROM (SELECT te1.timecard_entry_id,
                                         t1.timecard_id,
                                         te1.wk_date,
                                         t1.week_ending_date,
                                         ac1.assignment_continuity_id,
                                         te1.rate_treatment_identifier_fk,
                                         ac1.current_edition_fk AS assignment_edition_id,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN effective_date        ELSE NULL END AS rates_effective_date,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN termination_date      ELSE NULL END AS rates_termination_date,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN currency_code         ELSE NULL END AS currency_code,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN supplier_bill_rate    ELSE NULL END AS supplier_bill_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN buyer_bill_rate       ELSE NULL END AS buyer_bill_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN supplier_ot_rate      ELSE NULL END AS supplier_ot_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN buyer_ot_rate         ELSE NULL END AS buyer_ot_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN supplier_dt_rate      ELSE NULL END AS supplier_dt_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN buyer_dt_rate         ELSE NULL END AS buyer_dt_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN adjusted_custom_bill_rate  ELSE NULL END AS adjusted_custom_bill_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN rate_identifier_rate_set_fk   ELSE NULL END AS rate_identifier_rate_set_fk,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN rate_type_id                  ELSE NULL END AS rate_type_id
                                    FROM timecard  t1,
                                         timecard_entry  te1,
                                         assignment_continuity  ac1,
                                         assignment_edition     ae1,
                                         ( --get_rates
                                          SELECT ald.valid_from                  AS effective_date,
                                                 ald.valid_to                    AS termination_date,
                                                 ald.assignment_edition_fk       AS assignment_edition_id,
                                                 rs_cu.description               AS currency_code,
                                                 rs.bill_rate                    AS supplier_bill_rate,
                                                 ald.buyer_adj_bill_rate         AS buyer_bill_rate,
                                                 rs.ot_bill_rate                 AS supplier_ot_rate,
                                                 ald.buyer_adj_bill_rate_ot      AS buyer_ot_rate,
                                                 rs.dt_bill_rate                 AS supplier_dt_rate,
                                                 ald.buyer_adj_bill_rate_dt      AS buyer_dt_rate,
                                                 ili_buyer_fee_adj.amount        AS adjusted_custom_bill_rate,
                                                 rs.rate_identifier_rate_set_fk  AS rate_identifier_rate_set_fk,
                                                 ald.rate_unit_fk                AS rate_type_id
                                            FROM assignment_line_detail   ald,
                                                 rate_set                 rs,
                                                 currency_unit            rs_cu,
                                                 invoice_line_item        ili_buyer_fee_adj
                                           WHERE ald.rate_set_fk                   = rs.rate_set_id
                                             AND ald.buyer_adj_bill_rate_rt_idntfr = ili_buyer_fee_adj.identifier(+)
                                             AND rs.currency_unit_fk               = rs_cu.value
                                         ) get_rates
                                   WHERE t1.week_ending_date = TO_DATE('}' ||TO_CHAR(load_rec.week_ending_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')
                                     AND t1.assignment_continuity_fk  = ac1.assignment_continuity_id
                                     AND ac1.assignment_continuity_id = ae1.assignment_continuity_fk --12.0
                                     AND ae1.assignment_edition_id    = get_rates.assignment_edition_id(+) --12.0
                                     AND ac1.work_order_fk IS NULL --EA and TA only
                                     AND t1.timecard_id               = te1.timecard_fk
                                     AND ABS(NVL(te1.hours,0)) + ABS(NVL(te1.change_to_hours,0)) != 0)) rates,
                          --get_custom_rate
                         (SELECT rate_identifier_rate_set_fk, rate
                            FROM rate_category_rate
                           WHERE rate_category_fk = 3) custom_rate
                   WHERE rates.rate_identifier_rate_set_fk = custom_rate.rate_identifier_rate_set_fk(+)
                     AND rates.rk = 1}';
         logger_pkg.debug('create table lego_tc_ea_rates');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('create table lego_tc_ea_rates - complete', TRUE);
         
         logger_pkg.debug('status for table lego_tc_ea_rates');
         DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                        tabname          => 'LEGO_TC_EA_RATES',
                                        estimate_percent => 10,
                                        degree           => 6);
         logger_pkg.debug('status for table lego_tc_ea_rates - complete', TRUE);

         v_sql :=
             'CREATE TABLE lego_tc_ea_rate_trmt_rates ' ||
                 v_storage ||
              q'{ AS
              SELECT /*+ PARALLEL (2,2) */
                     l.timecard_entry_id,
                     l.wk_date,
                     l.assignment_continuity_id,
                     ald.valid_from  AS effective_date,
                     ald.valid_to    AS termination_date,
                     NVL(rate_trmt_rs1.bill_rate,0)                      AS rate_trmt_reg_bill_rate,
                     NVL(rate_trmt_rs1.ot_bill_rate,0)                   AS rate_trmt_ot_bill_rate,
                     NVL(rate_trmt_rs1.dt_bill_rate,0)                   AS rate_trmt_dt_bill_rate,
                     NVL(cust_rate.rate,0)                               AS rate_trmt_cust_bill_rate,
                     NVL(aart.buyer_adj_bill_rate,0)                     AS rate_trmt_adj_reg_bill_rate,
                     NVL(aart.buyer_adj_bill_rate_ot,0)                  AS rate_trmt_adj_ot_bill_rate,
                     NVL(aart.buyer_adj_bill_rate_dt,0)                  AS rate_trmt_adj_dt_bill_rate,
                     NVL(aart.buyer_adj_bill_rate_rt_idntfr,0)           AS rate_trmt_adj_cust_bill_rate,
                     ald.rate_unit_fk                                    AS rate_trmt_rate_type_id
                FROM lego_tc_ea_rates l,
                     assignment_line_detail ald,
                     assignment_agreement_rate_trmt aart,
                     rate_set rate_trmt_rs1,
                     (SELECT *
                        FROM rate_category_rate
                       WHERE rate_category_fk = 3)  cust_rate
               WHERE l.rate_treatment_identifier_fk IS NOT NULL
                 AND ald.assignment_edition_fk        = l.assignment_edition_id
                 AND l.wk_date BETWEEN ald.valid_from AND ald.valid_to
                 AND aart.assignment_line_detail_fk   = ald.assignment_line_detail_id
                 AND aart.rate_trmt_identifier_fk     = l.rate_treatment_identifier_fk
                 AND aart.treatment_rate_set_fk       = rate_trmt_rs1.rate_set_id
                 AND rate_trmt_rs1.rate_identifier_rate_set_fk = cust_rate.rate_identifier_rate_set_fk(+)}';
         logger_pkg.debug('create table lego_tc_ea_rate_trmt_rates');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('create table lego_tc_ea_rate_trmt_rates - complete', TRUE);

         logger_pkg.debug('stats for lego_tc_ea_rate_trmt_rates');
         DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                        tabname          => 'LEGO_TC_EA_RATE_TRMT_RATES',
                                        estimate_percent => 10,
                                        degree           => 6);
         logger_pkg.debug('stats for lego_tc_ea_rate_trmt_rates - complete', TRUE);

         v_sql :=
             'CREATE TABLE lego_tc_ea_tmp ' ||
                 v_storage ||
              q'{ AS
                  SELECT /*+ PARALLEL (12) */
                         point1.timecard_entry_id,
                         point1.timecard_id,
                         point1.buyer_org_id,
                         point1.supplier_org_id,
                         point1.contractor_person_id,
                         point1.hiring_mgr_person_id,
                         point1.candidate_id,
                         point1.wk_date,
                         point1.week_ending_date,
                         point1.timecard_number,
                         point1.timecard_type,
                         point1.cac1_identifier,
                         point1.cac2_identifier,
                         point1.job_id,
                         point1.assignment_continuity_id,
                         point1.work_order_id,
                         point1.assignment_edition_id,
                         point1.timecard_approval_workflow_id,
                         point1.te_udf_collection_id,
                         point1.t_udf_collection_id,
                         SUM(point1.reg_fo_hours)     AS reg_hours,
                         SUM(point1.ot_fo_hours)      AS ot_hours,
                         SUM(point1.dt_fo_hours)      AS dt_hours,
                         SUM(point1.custom_fo_hours)  AS custom_hours,
                         SUM(point1.reg_fo_hours)+
                         SUM(point1.ot_fo_hours)+
                         SUM(point1.dt_fo_hours)+
                         SUM(point1.custom_fo_hours)  AS total_hours_day,
                         point1.change_to_hours       AS total_change_to_hours_day,
                         point1.timecard_state_id,
                         point1.timecard_state,
                         point1.rate_trmt_id,
                         CASE point1.rate_type_id 
                            WHEN 0 THEN 0 --Hourly
                            WHEN 1 THEN 1 --Daily
                            WHEN 4 THEN 4 --Weekly
                            WHEN 3 THEN 3 --Monthly
                            ELSE NULL
                         END AS rate_type,
                         CASE point1.rate_type_id
                            WHEN 0 THEN 'Hourly'
                            WHEN 1 THEN 'Daily'
                            WHEN 2 THEN 'Annual'
                            WHEN 3 THEN 'Monthly'
                            WHEN 4 THEN 'Weekly'
                            ELSE 'N/A'
                         END AS rate_type_desc,
                         point1.hours_per_day,
                         point1.is_break,
                         point1.tc_buyer_approved_date,
                         point1.tc_buyer_rejected_date,
                         point1.tc_created_date,
                         point1.tc_saved_date,
                         point1.tc_adjusted_date,
                         point1.tc_rerated_date,
                         point1.tc_approve_req_retract_date,
                         point1.tc_submit_approval_date,
                         point1.tc_archived_date,
                         point1.tc_sar_approved_date,
                         point1.tc_sar_rejected_date,
                         point1.cac1_start_date,
                         point1.cac1_end_date,
                         point1.cac1_guid,
                         point1.cac2_start_date,
                         point1.cac2_end_date,
                         point1.cac2_guid,
                         point1.timecard_currency_id,
                         point1.timecard_currency,
                         --RATES--
                         reg_bill_rate,
                         ot_bill_rate,
                         dt_bill_rate,
                         custom_bill_rate,
                         adj_reg_bill_rate,
                         adj_ot_bill_rate,
                         adj_dt_bill_rate,
                         adj_custom_bill_rate,
                         rate_trmt_reg_bill_rate,
                         rate_trmt_ot_bill_rate,
                         rate_trmt_dt_bill_rate,
                         rate_trmt_cust_bill_rate,
                         rate_trmt_adj_reg_bill_rate,
                         rate_trmt_adj_ot_bill_rate,
                         rate_trmt_adj_dt_bill_rate,
                         rate_trmt_adj_cust_bill_rate
                    FROM (SELECT lt.timecard_entry_id,
                                 lt.timecard_id,
                                 lt.buyer_org_id,
                                 lt.supplier_org_id,
                                 lt.contractor_person_id,
                                 lt.hiring_mgr_person_id,
                                 lt.candidate_id,
                                 lt.wk_date,
                                 lt.week_ending_date,
                                 lt.timecard_number,
                                 lt.timecard_type,
                                 lt.cac1_identifier,
                                 lt.cac2_identifier,
                                 lt.job_id,
                                 lt.assignment_continuity_id,
                                 lt.work_order_id,
                                 lt.assignment_edition_id,
                                 lt.timecard_approval_workflow_id,
                                 lt.te_udf_collection_id,
                                 lt.t_udf_collection_id,
                                 lt.reg_fo_hours,    --sum above to flatten into 1 row
                                 lt.ot_fo_hours,     --sum above to flatten into 1 row
                                 lt.dt_fo_hours,     --sum above to flatten into 1 row
                                 lt.custom_fo_hours, --sum above to flatten into 1 row
                                 lt.hours,
                                 lt.change_to_hours,
                                 lt.timecard_state_id,
                                 lt.timecard_state,
                                 lt.rate_trmt_id,
                                 lt.hours_per_day,
                                 lt.is_break,
                                 lt.tc_buyer_approved_date,
                                 lt.tc_buyer_rejected_date,
                                 lt.tc_created_date,
                                 lt.tc_saved_date,
                                 lt.tc_adjusted_date,
                                 lt.tc_rerated_date,
                                 lt.tc_approve_req_retract_date,
                                 lt.tc_submit_approval_date,
                                 lt.tc_archived_date,
                                 lt.tc_sar_approved_date,
                                 lt.tc_sar_rejected_date,
                                 lt.cac1_start_date,
                                 lt.cac1_end_date,
                                 lt.cac1_guid,
                                 lt.cac2_start_date,
                                 lt.cac2_end_date,
                                 lt.cac2_guid,
                                 lt.timecard_currency_id,
                                 lt.timecard_currency,
                                 ---RATES----
                                 ea_rates.supplier_bill_rate   AS reg_bill_rate,
                                 ea_rates.supplier_ot_rate     AS ot_bill_rate,
                                 ea_rates.supplier_dt_rate     AS dt_bill_rate,
                                 ea_rates.custom_bill_rate     AS custom_bill_rate,
                                 ea_rates.buyer_bill_rate      AS adj_reg_bill_rate,
                                 ea_rates.buyer_ot_rate        AS adj_ot_bill_rate,
                                 ea_rates.buyer_dt_rate        AS adj_dt_bill_rate,
                                 ea_rates.adjusted_custom_bill_rate AS adj_custom_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_reg_bill_rate,0)      AS rate_trmt_reg_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_ot_bill_rate,0)       AS rate_trmt_ot_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_dt_bill_rate,0)       AS rate_trmt_dt_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_cust_bill_rate,0)     AS rate_trmt_cust_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_reg_bill_rate,0)  AS rate_trmt_adj_reg_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_ot_bill_rate,0)   AS rate_trmt_adj_ot_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_dt_bill_rate,0)   AS rate_trmt_adj_dt_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_cust_bill_rate,0) AS rate_trmt_adj_cust_bill_rate,
                                 NVL(ea_rates.rate_type_id, trmt_ea_rates.rate_trmt_rate_type_id) AS rate_type_id
                            FROM
                                (SELECT
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 1 THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 1 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS reg_fo_hours,
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 2 THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 2 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS OT_fo_hours,
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 3 THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 3 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS DT_fo_hours,
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk NOT IN (1,2,3) THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id  NOT IN (1,2,3) AND ri.is_billable = 1 AND te.is_break=0 THEN nvl(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS CUSTOM_fo_hours,
                                       te.timecard_entry_id,
                                       t.timecard_id,
                                       fr.business_org_fk    AS buyer_org_id,
                                       frs.business_org_fk   AS supplier_org_id,
                                       c.person_fk           AS contractor_person_id,
                                       hfw.user_fk           AS hiring_mgr_person_id,
                                       c.candidate_id        AS candidate_id,
                                       te.wk_date            AS wk_date,
                                       t.week_ending_date    AS week_ending_date,
                                       t.timecard_number     AS timecard_number,
                                       t.timecard_type       AS timecard_type,
                                       te.cac1_fk            AS cac1_identifier,
                                       te.cac2_fk            AS cac2_identifier,
                                       ac.job_fk             AS job_id,
                                       ac.currency_unit_fk   AS timecard_currency_id,
                                       cu.description        AS timecard_currency,
                                       ac.assignment_continuity_id        AS assignment_continuity_id,
                                       ac.work_order_fk                   AS work_order_id,
                                       ae.assignment_edition_id           AS assignment_edition_id,
                                       ae.timecard_approval_workflow_fk   AS timecard_approval_workflow_id,
                                       te.udf_collection_fk               AS te_udf_collection_id,
                                       t.udf_collection_fk                AS t_udf_collection_id,
                                       NVL(te.hours,0)                    AS hours,
                                       NVL(te.change_to_hours,0)          AS change_to_hours,
                                       t.state_code                       AS timecard_state_id,
                                       NVL(timecard_state.constant_description, 'Unknown')  AS timecard_state,
                                       rci.description                    AS rate_trmt_id,
                                       NVL(hpd.hours_per_day,8)           AS hours_per_day,
                                       te.is_break,
                                       event_dates.tc_buyer_approved_date,
                                       event_dates.tc_buyer_rejected_date,
                                       event_dates.tc_created_date,
                                       event_dates.tc_saved_date,
                                       event_dates.tc_adjusted_date,
                                       event_dates.tc_rerated_date,
                                       event_dates.tc_approve_req_retract_date,
                                       event_dates.tc_submit_approval_date,
                                       event_dates.tc_archived_date,
                                       event_dates.tc_sar_approved_date,
                                       event_dates.tc_sar_rejected_date,
                                       cac1.start_date AS cac1_start_date,
                                       cac1.end_date   AS cac1_end_date,
                                       cac1.cac_guid   AS cac1_guid,
                                       cac2.start_date AS cac2_start_date,
                                       cac2.end_date   AS cac2_end_date,
                                       cac2.cac_guid   AS cac2_guid
                                  FROM timecard        t,
                                       timecard_entry  te,
                                       (SELECT * FROM time_expenditure WHERE is_current = 1) tx,
                                       assignment_continuity  ac,
                                       currency_unit          cu,
                                       assignment_edition     ae,
                                       firm_role              fr,
                                       firm_role              frs,
                                       candidate              c,
                                       firm_worker            hfw,
                                       rate_identifier        ri,
                                       (SELECT constant_value, constant_description
                                          FROM java_constant_lookup
                                         WHERE constant_type    = 'TIMECARD_STATE'
                                           AND UPPER(locale_fk) = 'EN_US') timecard_state,
                                       (SELECT lcc.cac_id,
                                               lcc.start_date,
                                               lcc.end_date,
                                               lcc.cac_guid
                                          FROM lego_cac_collection lcc ) cac1,
                                       (SELECT lcc.cac_id,
                                               lcc.start_date,
                                               lcc.end_date,
                                               lcc.cac_guid
                                          FROM lego_cac_collection lcc ) cac2,
                                       lego_tc_events event_dates,
                                       (SELECT pwe.procurement_wkfl_edition_id, wpd.hours_per_day
                                          FROM work_period_definition wpd, procurement_wkfl_edition pwe
                                         WHERE pwe.work_period_definition_fk = wpd.work_period_definition_id)  hpd,
                                       (SELECT rate_card_identifier_id, description
                                          FROM rate_card_identifier) rci
                                 WHERE t.week_ending_date = TO_DATE('}' ||TO_CHAR(load_rec.week_ending_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')
                                   AND t.assignment_continuity_fk      = ac.assignment_continuity_id
                                   AND ac.assignment_continuity_id     = ae.assignment_continuity_fk
                                   AND ac.current_edition_fk           = ae.assignment_edition_id
                                   AND ac.work_order_fk IS NULL
                                   AND ac.currency_unit_fk             = cu.value
                                   AND ac.candidate_fk                 = c.candidate_id(+)
                                   AND ae.hiring_mgr_fk                = hfw.firm_worker_id(+)
                                   AND t.timecard_id                   = te.timecard_fk
                                   AND t.procurement_wkfl_edition_fk   = hpd.procurement_wkfl_edition_id (+)
                                   AND te.timecard_entry_id            = tx.timecard_entry_fk (+)
                                   AND te.rate_identifier_fk           = ri.rate_identifier_id
                                   AND te.rate_treatment_identifier_fk = rci.rate_card_identifier_id (+)
                                   AND ac.owning_buyer_firm_fk         = fr.firm_id
                                   AND ac.owning_supply_firm_fk        = frs.firm_id
                                   AND t.state_code                    = timecard_state.constant_value(+)
                                   AND te.cac1_fk                      = cac1.cac_id(+)
                                   AND te.cac2_fk                      = cac2.cac_id(+)
                                   AND t.state_code != 7
                                   AND ABS(NVL(te.hours,0)) + ABS(NVL(te.change_to_hours,0)) != 0
                                   AND CASE WHEN te.change_to_hours <= 0 THEN 1
                                       ELSE NVL (te.change_to_hours, 0) END
                                       >
                                       CASE WHEN timecard_type = 'Timecard Adjustment' THEN 0
                                       ELSE -1 END
                                   AND t.timecard_id                   = event_dates.timecard_id(+) ) lt,
                                lego_tc_ea_rates   ea_rates,
                                lego_tc_ea_rate_trmt_rates trmt_ea_rates
                        WHERE lt.timecard_entry_id = ea_rates.timecard_entry_id
                          AND lt.timecard_entry_id = trmt_ea_rates.timecard_entry_id (+)
                         ) point1
                  GROUP BY
                           point1.timecard_entry_id,
                           point1.timecard_id,
                           point1.buyer_org_id,
                           point1.supplier_org_id,
                           point1.contractor_person_id,
                           point1.hiring_mgr_person_id,
                           point1.candidate_id,
                           point1.wk_date,
                           point1.week_ending_date,
                           point1.timecard_number,
                           point1.timecard_type,
                           point1.cac1_identifier,
                           point1.cac2_identifier,
                           point1.job_id,
                           point1.assignment_continuity_id,
                           point1.work_order_id,
                           point1.assignment_edition_id,
                           point1.timecard_approval_workflow_id,
                           point1.te_udf_collection_id,
                           point1.t_udf_collection_id,
                           point1.hours,
                           point1.change_to_hours,
                           point1.timecard_state_id,
                           point1.timecard_state,
                           point1.rate_trmt_id,
                           CASE point1.rate_type_id
                              WHEN 0 THEN 0 --Hourly
                              WHEN 1 THEN 1 --Daily
                              WHEN 4 THEN 4 --Weekly
                              WHEN 3 THEN 3 --Monthly
                              ELSE NULL
                           END,
                           CASE point1.rate_type_id
                              WHEN 0 THEN 'Hourly'
                              WHEN 1 THEN 'Daily'
                              WHEN 2 THEN 'Annual'
                              WHEN 3 THEN 'Monthly'
                              WHEN 4 THEN 'Weekly'
                              ELSE 'N/A'
                           END,
                           point1.hours_per_day,
                           point1.is_break,
                           point1.tc_buyer_approved_date,
                           point1.tc_buyer_rejected_date,
                           point1.tc_created_date,
                           point1.tc_saved_date,
                           point1.tc_adjusted_date,
                           point1.tc_rerated_date,
                           point1.tc_approve_req_retract_date,
                           point1.tc_submit_approval_date,
                           point1.tc_archived_date,
                           point1.tc_sar_approved_date,
                           point1.tc_sar_rejected_date,
                           point1.cac1_start_date,
                           point1.cac1_end_date,
                           point1.cac1_guid,
                           point1.cac2_start_date,
                           point1.cac2_end_date,
                           point1.cac2_guid,
                           point1.timecard_currency_id,
                           point1.timecard_currency,
                           reg_bill_rate,
                           ot_bill_rate,
                           dt_bill_rate,
                           custom_bill_rate,
                           adj_reg_bill_rate,
                           adj_ot_bill_rate,
                           adj_dt_bill_rate,
                           adj_custom_bill_rate,
                           rate_trmt_reg_bill_rate,
                           rate_trmt_ot_bill_rate,
                           rate_trmt_dt_bill_rate,
                           rate_trmt_cust_bill_rate,
                           rate_trmt_adj_reg_bill_rate,
                           rate_trmt_adj_ot_bill_rate,
                           rate_trmt_adj_dt_bill_rate,
                           rate_trmt_adj_cust_bill_rate}';
         logger_pkg.debug('create table lego_tc_ea_tmp');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('create table lego_tc_ea_tmp - complete', TRUE);
         
         COMMIT;

         v_sql :=
         q'{INSERT /*+ APPEND */
              INTO lego_timecard
           (timecard_entry_id, timecard_id, buyer_org_id, supplier_org_id, contractor_person_id,
            hiring_mgr_person_id, candidate_id, wk_date, week_ending_date, timecard_number,
            timecard_type, cac1_identifier, cac2_identifier, job_id, assignment_continuity_id,
            assignment_edition_id, timecard_approval_workflow_id, te_udf_collection_id,
            t_udf_collection_id, reg_hours, ot_hours, dt_hours, custom_hours, total_hours_day,
            total_change_to_hours_day, timecard_state_id, timecard_state, rate_trmt_id, rate_type_desc,
            hours_per_day, is_break, tc_buyer_approved_date, tc_buyer_rejected_date, tc_created_date,
            tc_saved_date, tc_adjusted_date, tc_rerated_date, tc_approve_req_retract_date,
            tc_submit_approval_date, tc_archived_date, tc_sar_approved_date, tc_sar_rejected_date,
            cac1_start_date, cac1_end_date, cac1_guid, cac2_start_date, cac2_end_date, cac2_guid,
            timecard_currency, reg_bill_rate, ot_bill_rate, dt_bill_rate, custom_bill_rate, adj_reg_bill_rate,
            adj_ot_bill_rate, adj_dt_bill_rate, adj_custom_bill_rate, rate_trmt_reg_bill_rate,
            rate_trmt_ot_bill_rate, rate_trmt_dt_bill_rate, rate_trmt_cust_bill_rate, rate_trmt_adj_reg_bill_rate,
            rate_trmt_adj_ot_bill_rate, rate_trmt_adj_dt_bill_rate, rate_trmt_adj_cust_bill_rate,
            contractor_spend, cont_spend_amount_adj, timecard_currency_id, invoiced_amount)
        SELECT /*+ PARALLEL (6) */
               CAST(t.timecard_entry_id AS NUMBER)           AS timecard_entry_id,
               CAST(timecard_id AS NUMBER)                   AS timecard_id,
               CAST(t.buyer_org_id AS NUMBER)                AS buyer_org_id,
               CAST(supplier_org_id AS NUMBER)               AS supplier_org_id,
               CAST(contractor_person_id AS NUMBER)          AS contractor_person_id,
               CAST(hiring_mgr_person_id AS NUMBER)          AS hiring_mgr_person_id,
               CAST(candidate_id AS NUMBER)                  AS candidate_id,
               CAST(wk_date AS DATE)                         AS wk_date,
               CAST(week_ending_date AS DATE)                AS week_ending_date,
               CAST(timecard_number AS VARCHAR2(256))        AS timecard_number,
               CAST(timecard_type AS VARCHAR2(20))           AS timecard_type,
               CAST(cac1_identifier AS NUMBER)               AS cac1_identifier,
               CAST(cac2_identifier AS NUMBER)               AS cac2_identifier,
               CAST(job_id AS NUMBER)                        AS job_id,
               CAST(assignment_continuity_id AS NUMBER)      AS assignment_continuity_id,
               CAST(assignment_edition_id AS NUMBER)         AS assignment_edition_id,
               CAST(timecard_approval_workflow_id AS NUMBER) AS timecard_approval_workflow_id,
               CAST(te_udf_collection_id AS NUMBER)          AS te_udf_collection_id,
               CAST(t_udf_collection_id AS NUMBER)           AS t_udf_collection_id,
               CAST(reg_hours AS NUMBER)                     AS reg_hours,
               CAST(ot_hours AS NUMBER)                      AS ot_hours,
               CAST(dt_hours AS NUMBER)                      AS dt_hours,
               CAST(custom_hours AS NUMBER)                  AS custom_hours,
               CAST(total_hours_day AS NUMBER)               AS total_hours_day,
               CAST(total_change_to_hours_day AS NUMBER)     AS total_change_to_hours_day,
               CAST(timecard_state_id AS NUMBER)             AS timecard_state_id,
               CAST(timecard_state AS VARCHAR2(4000))        AS timecard_state,
               CAST(rate_trmt_id AS VARCHAR2(4000))          AS rate_trmt_id,
               CAST(rate_type_desc AS VARCHAR2(7))           AS rate_type,
               CAST(hours_per_day AS NUMBER)                 AS hours_per_day,
               CAST(is_break AS NUMBER(1))                   AS is_break,
               CAST(tc_buyer_approved_date AS DATE)          AS tc_buyer_approved_date,
               CAST(tc_buyer_rejected_date AS DATE)          AS tc_buyer_rejected_date,
               CAST(tc_created_date AS DATE)                 AS tc_created_date,
               CAST(tc_saved_date AS DATE)                   AS tc_saved_date,
               CAST(tc_adjusted_date AS DATE)                AS tc_adjusted_date,
               CAST(tc_rerated_date AS DATE)                 AS tc_rerated_date,
               CAST(tc_approve_req_retract_date AS DATE)     AS tc_approve_req_retract_date,
               CAST(tc_submit_approval_date AS DATE)         AS tc_submit_approval_date,
               CAST(tc_archived_date AS DATE)                AS tc_archived_date,
               CAST(tc_sar_approved_date AS DATE)            AS tc_sar_approved_date,
               CAST(tc_sar_rejected_date AS DATE)            AS tc_sar_rejected_date,
               CAST(cac1_start_date AS DATE)                 AS cac1_start_date,
               CAST(cac1_end_date AS DATE)                   AS cac1_end_date,
               cac1_guid,
               CAST(cac2_start_date AS DATE)                 AS cac2_start_date,
               CAST(cac2_end_date AS DATE)                   AS cac2_end_date,
               cac2_guid,
               CAST(timecard_currency AS VARCHAR2(50))       AS timecard_currency,
               CAST(reg_bill_rate AS NUMBER)                 AS reg_bill_rate,
               CAST(ot_bill_rate AS NUMBER)                  AS ot_bill_rate,
               CAST(dt_bill_rate AS NUMBER)                  AS dt_bill_rate,
               CAST(custom_bill_rate AS NUMBER)              AS custom_bill_rate,
               CAST(adj_reg_bill_rate AS NUMBER)             AS adj_reg_bill_rate,
               CAST(adj_ot_bill_rate AS NUMBER)              AS adj_ot_bill_rate,
               CAST(adj_dt_bill_rate AS NUMBER)              AS adj_dt_bill_rate,
               CAST(adj_custom_bill_rate AS NUMBER)          AS adj_custom_bill_rate,
               CAST(rate_trmt_reg_bill_rate AS NUMBER)       AS rate_trmt_reg_bill_rate,
               CAST(rate_trmt_ot_bill_rate AS NUMBER)        AS rate_trmt_ot_bill_rate,
               CAST(rate_trmt_dt_bill_rate AS NUMBER)        AS rate_trmt_dt_bill_rate,
               CAST(rate_trmt_cust_bill_rate AS NUMBER)      AS rate_trmt_cust_bill_rate,
               CAST(rate_trmt_adj_reg_bill_rate AS NUMBER)   AS rate_trmt_adj_reg_bill_rate,
               CAST(rate_trmt_adj_ot_bill_rate AS NUMBER)    AS rate_trmt_adj_ot_bill_rate,
               CAST(rate_trmt_adj_dt_bill_rate AS NUMBER)    AS rate_trmt_adj_dt_bill_rate,
               CAST(rate_trmt_adj_cust_bill_rate AS NUMBER)  AS rate_trmt_adj_cust_bill_rate,
               CAST(
               CASE
                  WHEN t.rate_trmt_id IS NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.reg_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.reg_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.reg_bill_rate / 160
                              ELSE
                                 t.reg_bill_rate
                              END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.dt_bill_rate / 160
                             ELSE
                                t.dt_bill_rate
                             END )
                           * t.dt_hours)
                            +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.ot_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.ot_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.ot_bill_rate / 160
                              ELSE
                                 t.ot_bill_rate
                              END)
                           * t.ot_hours)
                             +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.custom_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.custom_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.custom_bill_rate / 160
                              ELSE
                                 t.custom_bill_rate
                              END)
                           * t.custom_hours)
                          )
                  WHEN t.rate_trmt_id IS NOT NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.rate_trmt_reg_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.rate_trmt_reg_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.rate_trmt_reg_bill_rate / 160
                              ELSE
                                 t.rate_trmt_reg_bill_rate
                              END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_dt_bill_rate / 160
                             ELSE
                                t.rate_trmt_dt_bill_rate
                             END )
                           * t.dt_hours)
                            +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.rate_trmt_ot_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.rate_trmt_ot_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.rate_trmt_ot_bill_rate / 160
                              ELSE
                                 t.rate_trmt_ot_bill_rate
                              END)
                           * t.ot_hours)
                             +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.rate_trmt_cust_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.rate_trmt_cust_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.rate_trmt_cust_bill_rate / 160
                              ELSE
                                 t.rate_trmt_cust_bill_rate
                              END)
                           * t.custom_hours)
                          )
                  END AS NUMBER ) AS contractor_spend,
               CAST(
               CASE
                  WHEN t.rate_trmt_id IS NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.adj_reg_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.adj_reg_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.adj_reg_bill_rate / 160
                              ELSE
                                 t.adj_reg_bill_rate
                              END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.adj_dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.adj_dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.adj_dt_bill_rate / 160
                             ELSE
                                t.adj_dt_bill_rate
                             END)
                           * t.dt_hours)
                            +
                         (  (CASE
                                 WHEN t.rate_type =1 THEN t.adj_ot_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.adj_ot_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.adj_ot_bill_rate / 160
                             ELSE
                                t.adj_ot_bill_rate
                             END)
                           * t.ot_hours)
                            +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.adj_custom_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.adj_custom_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.adj_custom_bill_rate / 160
                             ELSE
                                t.adj_custom_bill_rate
                             END)
                           * t.custom_hours)
                          )
                  WHEN t.rate_trmt_id IS NOT NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                        (   (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_reg_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_reg_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_reg_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_reg_bill_rate
                             END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_dt_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_dt_bill_rate
                             END )
                           * t.dt_hours)
                            +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_ot_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_ot_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_ot_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_ot_bill_rate
                             END)
                           * t.ot_hours)
                             +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_cust_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_cust_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_cust_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_cust_bill_rate
                             END)
                           * t.custom_hours)
                          )  END AS NUMBER ) AS cont_spend_amount_adj,
               CAST(timecard_currency_id AS NUMBER)          AS timecard_currency_id,
               CAST(inv.invoiced_amount AS NUMBER)           AS invoiced_amount
        FROM (
        SELECT timecard_entry_id,
               timecard_id,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               hiring_mgr_person_id,
               candidate_id,
               wk_date,
               week_ending_date,
               timecard_number,
               timecard_type,
               cac1_identifier,
               cac2_identifier,
               job_id,
               assignment_continuity_id,
               assignment_edition_id,
               timecard_approval_workflow_id,
               te_udf_collection_id,
               t_udf_collection_id,
               reg_hours,
               ot_hours,
               dt_hours,
               custom_hours,
               total_hours_day,
               total_change_to_hours_day,
               timecard_state_id,
               timecard_state,
               rate_trmt_id,
               rate_type,
               rate_type_desc,
               hours_per_day,
               is_break,
               tc_buyer_approved_date,
               tc_buyer_rejected_date,
               tc_created_date,
               tc_saved_date,
               tc_adjusted_date,
               tc_rerated_date,
               tc_approve_req_retract_date,
               tc_submit_approval_date,
               tc_archived_date,
               tc_sar_approved_date,
               tc_sar_rejected_date,
               cac1_start_date,
               cac1_end_date,
               cac1_guid,
               cac2_start_date,
               cac2_end_date,
               cac2_guid,
               timecard_currency_id,
               timecard_currency,
               reg_bill_rate,
               ot_bill_rate,
               dt_bill_rate,
               custom_bill_rate,
               adj_reg_bill_rate,
               adj_ot_bill_rate,
               adj_dt_bill_rate,
               adj_custom_bill_rate,
               rate_trmt_reg_bill_rate,
               rate_trmt_ot_bill_rate,
               rate_trmt_dt_bill_rate,
               rate_trmt_cust_bill_rate,
               rate_trmt_adj_reg_bill_rate,
               rate_trmt_adj_ot_bill_rate,
               rate_trmt_adj_dt_bill_rate,
               rate_trmt_adj_cust_bill_rate
          FROM lego_tc_wo_tmp
         UNION ALL
        SELECT timecard_entry_id,
               timecard_id,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               hiring_mgr_person_id,
               candidate_id,
               wk_date,
               week_ending_date,
               timecard_number,
               timecard_type,
               cac1_identifier,
               cac2_identifier,
               job_id,
               assignment_continuity_id,
               assignment_edition_id,
               timecard_approval_workflow_id,
               te_udf_collection_id,
               t_udf_collection_id,
               reg_hours,
               ot_hours,
               dt_hours,
               custom_hours,
               total_hours_day,
               total_change_to_hours_day,
               timecard_state_id,
               timecard_state,
               rate_trmt_id,
               rate_type,
               rate_type_desc,
               hours_per_day,
               is_break,
               tc_buyer_approved_date,
               tc_buyer_rejected_date,
               tc_created_date,
               tc_saved_date,
               tc_adjusted_date,
               tc_rerated_date,
               tc_approve_req_retract_date,
               tc_submit_approval_date,
               tc_archived_date,
               tc_sar_approved_date,
               tc_sar_rejected_date,
               cac1_start_date,
               cac1_end_date,
               cac1_guid,
               cac2_start_date,
               cac2_end_date,
               cac2_guid,
               timecard_currency_id,
               timecard_currency,
               reg_bill_rate,
               ot_bill_rate,
               dt_bill_rate,
               custom_bill_rate,
               adj_reg_bill_rate,
               adj_ot_bill_rate,
               adj_dt_bill_rate,
               adj_custom_bill_rate,
               rate_trmt_reg_bill_rate,
               rate_trmt_ot_bill_rate,
               rate_trmt_dt_bill_rate,
               rate_trmt_cust_bill_rate,
               rate_trmt_adj_reg_bill_rate,
               rate_trmt_adj_ot_bill_rate,
               rate_trmt_adj_dt_bill_rate,
               rate_trmt_adj_cust_bill_rate
          FROM lego_tc_ea_tmp) t,
               lego_invcd_expenditure_sum inv
         WHERE t.timecard_entry_id     = inv.expenditure_id(+)
           AND inv.expenditure_type(+) = 'Time'
         ORDER BY t.buyer_org_id, supplier_org_id, hiring_mgr_person_id, contractor_person_id, week_ending_date, t.timecard_entry_id}';
         logger_pkg.info('insert into lego_timecard');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.info('insert into lego_timecard - complete - ' || to_char(SQL%ROWCOUNT) || 
                         ' rows inserted.', TRUE);
         
         COMMIT;

      END LOOP;

      logger_pkg.set_code_location('Timecard timecard future');
      logger_pkg.info('starting load_lego_timecard_future');
      load_lego_timecard_future;

      --Gather Stats
      logger_pkg.debug('gather stats on lego_timecard table');
      DBMS_STATS.gather_table_stats
         (ownname          => gc_curr_schema,
          tabname          => 'LEGO_TIMECARD',
          estimate_percent => 5,
          degree           => 6);
      logger_pkg.debug('gather stats on lego_timecard table - complete', TRUE);

      --update lego_refresh table so that normal refresh loads will begin for LEGO_TIMECARD
      UPDATE lego_refresh
         SET next_refresh_time = SYSDATE
       WHERE object_name       = 'LEGO_TIMECARD';
      COMMIT;
      logger_pkg.unset_source('Timcard Lego init/reload');

EXCEPTION
   WHEN OTHERS THEN
     ROLLBACK;
     logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                      pi_error_code         => SQLCODE,
                      pi_message            => SQLERRM);
     logger_pkg.unset_source('Timcard Lego init/reload');
     RAISE;

END load_lego_timecard_init;

---------------

PROCEDURE load_lego_timecard_future
AS

   /*---------------------------------------------------------------------------*\
   || PROCEDURE NAME       : load_lego_timecard_future
   || AUTHOR               : Erik Clark
   || DATE CREATED         : December 12, 2012
   || PURPOSE              : This procedure deletes timecard data in the +1 months into the
   ||                      : the future, and then reloads it.
   || MODIFICATION HISTORY : 02/15/2013 - E.Clark - fixed insert to include UDFs - Release 11.2
   ||                      : 04/10/2013 - E.Clark - re-write for TIMECARD overhaul - Release 11.2.1
   ||                      : 05/20/2013 - E.Clark - adding timecard_currency_id for Currency Conversion, Jira # IQN-1008 - Release 11.2.2
   ||                      : 05/22/2013 - E.Clark - address code issue in wo.3 - Release 11.2.2
   ||                      : 05/23/2013 - E.Clark - fix defect with RATE_TRMT_RATES in WO.3 and EA.2 that were using reimb. rates - Release 11.2.2
   ||                      : 08/09/2013 - E.Clark - updated to load invoice information - IQN-6268 - Release 11.3.2
   ||                      : 09/12/2013 - E.Clark - defect on hours - IQN-6268 - Release 11.3.2
   ||                      : 02/24/2014 - E.Clark - IQN-12543 - fix for RATE_TYPE_DESC = Hourly, when they are actually Daily. - Release 12.0.1
   ||                      :                      - IQN-12543 - fix EA rates when current edition does not match ald.from-thru dates - Release 12.0.1
   ||                      :                      - Add handling to correctly calculate hourly rates when the rate_type_desc = Monthly. Rate / 160. Release 12.0.1
   ||                      : 06/13/2014 - J.Pullifrone - IQN-18002 - Instead of capturing INVOICE_ID, capture is_on_invoice instead - Release 12.1.1
   ||                      : 08/18/2014 - pmuller - IQN-19497 - convert all logging to use LOGGER_PKG - 12.2
   ||                      : 08/26/2014 - J.Pullifrone - IQN-18776 - adding invoiced_amount based on actual invoiced_amount from lego_invoice_detail.  Invoiced amount will
   ||                      :                                         be used in expenditure summary lego.  Also removing is_on_invoice.  Release 12.2.0    
   \*---------------------------------------------------------------------------*/

   v_sql                   CLOB;
   v_storage               lego_refresh.exadata_storage_clause%type;
   v_start_date            DATE;

BEGIN

   logger_pkg.set_code_location('lego timecard future');
   EXECUTE IMMEDIATE 'DELETE FROM lego_timecard_future_gtt';
   COMMIT;

   SELECT exadata_storage_clause
     INTO v_storage
     FROM lego_refresh
    WHERE object_name = 'LEGO_TIMECARD';

   v_start_date := TO_DATE('01-' || TO_CHAR(ADD_MONTHS(SYSDATE,1),'MON-YYYY'),'DD-MON-YYYY');
   logger_pkg.info('starting lego_timecard_future with start_date: ' || to_char(v_start_date, 'YYYY-Mon-DD'));
----------------------

   logger_pkg.debug('dropping tables');
   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_tc_events PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_effective_rates PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_rates PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_rate_trmt_rates PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_tmp PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_tc_ea_rates PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_tc_ea_rate_trmt_rates PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_tc_ea_tmp PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;
   logger_pkg.debug('dropping tables - complete',TRUE);

   v_sql :=
             'CREATE TABLE lego_tc_events ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (8) */
                       ted.timecard_fk AS timecard_id,
                       MAX(CASE WHEN ed.event_name_fk = 22000 THEN ed.timestamp ELSE NULL END) tc_buyer_approved_date,
                       MAX(CASE WHEN ed.event_name_fk = 22001 THEN ed.timestamp ELSE NULL END) tc_buyer_rejected_date,
                       MAX(CASE WHEN ed.event_name_fk = 22003 THEN ed.timestamp ELSE NULL END) tc_created_date,
                       MAX(CASE WHEN ed.event_name_fk = 22004 THEN ed.timestamp ELSE NULL END) tc_saved_date,
                       MAX(CASE WHEN ed.event_name_fk = 22005 THEN ed.timestamp ELSE NULL END) tc_adjusted_date,
                       MAX(CASE WHEN ed.event_name_fk = 22006 THEN ed.timestamp ELSE NULL END) tc_rerated_date,
                       MAX(CASE WHEN ed.event_name_fk = 22007 THEN ed.timestamp ELSE NULL END) tc_approve_req_retract_date,
                       MAX(CASE WHEN ed.event_name_fk = 22008 THEN ed.timestamp ELSE NULL END) tc_submit_approval_date,
                       MAX(CASE WHEN ed.event_name_fk = 22011 THEN ed.timestamp ELSE NULL END) tc_archived_date,
                       MAX(CASE WHEN ed.event_name_fk = 22012 THEN ed.timestamp ELSE NULL END) tc_sar_approved_date,
                       MAX(CASE WHEN ed.event_name_fk = 22013 THEN ed.timestamp ELSE NULL END) tc_sar_rejected_date
                  FROM timecard_event_description AS OF SCN lego_refresh_mgr_pkg.get_scn() ted,
                       event_description          AS OF SCN lego_refresh_mgr_pkg.get_scn() ed,
                       timecard                   AS OF SCN lego_refresh_mgr_pkg.get_scn() t
                 WHERE ted.identifier  = ed.identifier
                   AND ted.timecard_fk = t.timecard_id
                   AND t.week_ending_date >= TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || q'{
                   AND ed.event_name_fk IN (22000, 22001, 22003, 22004, 22005, 22006, 22007, 22008, 22011, 22012, 22013)
                 GROUP BY ted.timecard_fk
                 ORDER BY ted.timecard_fk }';
   logger_pkg.debug('create lego_tc_events');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.debug('create lego_tc_events - complete', TRUE);

   --Gather Stats
   logger_pkg.debug('stats on lego_tc_events');
   DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                  tabname          => 'LEGO_TC_EVENTS',
                                  estimate_percent => 10,
                                  degree           => 6);
   logger_pkg.debug('stats on lego_tc_events - complete', TRUE);

   v_sql :=
             'CREATE TABLE lego_tc_wo_effective_rates ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (2,2) */
                       te1.timecard_entry_id,
                       te1.wk_date,
                       t1.week_ending_date,
                       ac1.assignment_continuity_id,
                       te1.rate_treatment_identifier_fk,
                       ac1.current_edition_fk AS assignment_edition_id,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_effective_date        ELSE NULL END AS effct_rte_effective_date,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_termination_date      ELSE NULL END AS effct_rte_termination_date,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_contract_id           ELSE NULL END AS effct_rte_contract_id,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_create_date           ELSE NULL END AS effct_rte_create_date,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_currency              ELSE NULL END AS effct_rte_currency,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_bill_rate        ELSE NULL END AS effct_rte_supp_bill_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_buyer_bill_rate       ELSE NULL END AS effct_rte_buyer_bill_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_ot_rate          ELSE NULL END AS effct_rte_supp_ot_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_buyer_ot_rate         ELSE NULL END AS effct_rte_buyer_ot_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_dt_rate          ELSE NULL END AS effct_rte_supp_dt_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_buyer_dt_rate         ELSE NULL END AS effct_rte_buyer_dt_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_adj_custom_bill_rate  ELSE NULL END AS effct_rte_adj_custom_bill_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_pay_rate              ELSE NULL END AS effct_rte_pay_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_ot_pay_rate           ELSE NULL END AS effct_rte_ot_pay_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_dt_pay_rate           ELSE NULL END AS effct_rte_dt_pay_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_rate_unit_fk          ELSE NULL END AS effct_rte_rate_unit_fk,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_rate_id_rate_set_fk   ELSE NULL END AS effct_rte_rate_id_rate_set_fk,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_markup                ELSE NULL END AS effct_rte_markup,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_ot_markup             ELSE NULL END AS effct_rte_ot_markup,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_dt_markup             ELSE NULL END AS effct_rte_dt_markup,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_rg_reim_rate     ELSE NULL END AS effct_rte_supp_rg_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_ot_reim_rate     ELSE NULL END AS effct_rte_supp_ot_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_dt_reim_rate     ELSE NULL END AS effct_rte_supp_dt_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_cs_reim_rate     ELSE NULL END AS effct_rte_supp_cs_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_rate_type_id          ELSE NULL END AS effct_rte_rate_type_id
                  FROM timecard  AS OF SCN lego_refresh_mgr_pkg.get_scn() t1,
                       timecard_entry  AS OF SCN lego_refresh_mgr_pkg.get_scn() te1,
                       assignment_continuity  AS OF SCN lego_refresh_mgr_pkg.get_scn() ac1,
                       ( --get_effective_rate
                         SELECT cv1.effective_date                 AS  effct_rte_effective_date,
                                cv1.termination_date               AS  effct_rte_termination_date,
                                cv1.contract_fk                    AS  effct_rte_contract_id, --assignment_continuity_id
                                cv1.create_date                    AS  effct_rte_create_date,
                                fet_cu1.description                AS  effct_rte_currency,
                                fet1.supplier_bill_rate            AS  effct_rte_supp_bill_rate,
                                fet1.buyer_bill_rate               AS  effct_rte_buyer_bill_rate,
                                fet1.supplier_ot_rate              AS  effct_rte_supp_ot_rate,
                                fet1.buyer_ot_rate                 AS  effct_rte_buyer_ot_rate,
                                fet1.supplier_dt_rate              AS  effct_rte_supp_dt_rate,
                                fet1.buyer_dt_rate                 AS  effct_rte_buyer_dt_rate,
                                fet1.buyer_adj_bill_rate_rt_idntfr AS  effct_rte_adj_custom_bill_rate,
                                fet1.pay_rate                      AS  effct_rte_pay_rate,
                                fet1.ot_pay_rate                   AS  effct_rte_ot_pay_rate,
                                fet1.dt_pay_rate                   AS  effct_rte_dt_pay_rate,
                                fet1.buyer_bill_rate_unit_fk       AS  effct_rte_rate_unit_fk,
                                fet1.rate_identifier_rate_set_fk   AS  effct_rte_rate_id_rate_set_fk,
                                fet1.mark_up                       AS  effct_rte_markup,
                                fet1.ot_mark_up                    AS  effct_rte_ot_markup,
                                fet1.dt_mark_up                    AS  effct_rte_dt_markup,
                                NVL(fet1.supplier_reimbursement_rate,0)    AS  effct_rte_supp_rg_reim_rate,
                                NVL(fet1.supplier_ot_reimbursement_rate,0) AS  effct_rte_supp_ot_reim_rate,
                                NVL(fet1.supplier_dt_reimbursement_rate,0) AS  effct_rte_supp_dt_reim_rate,
                                NVL(fet1.supplier_reimburse_rt_idntfr,0)   AS  effct_rte_supp_cs_reim_rate,
                                fet1.buyer_bill_rate_unit_fk               AS  effct_rte_rate_type_id
                           FROM currency_unit        fet_cu1,
                                fee_expense_term     AS OF SCN lego_refresh_mgr_pkg.get_scn() fet1,
                                contract_term        AS OF SCN lego_refresh_mgr_pkg.get_scn() fet_ct1,
                                work_order_version   AS OF SCN lego_refresh_mgr_pkg.get_scn() wov1,
                                contract_version     AS OF SCN lego_refresh_mgr_pkg.get_scn() cv1
                          WHERE cv1.contract_version_id          = wov1.contract_version_id
                            AND wov1.contract_version_id         = fet_ct1.contract_version_fk
                            AND wov1.work_order_version_state NOT IN (7,8,22,23,21,15,16,24) -- Get rid of Cancels; SFI# 110302-342903 21,15,16,24 are excluded
                            AND fet_ct1.contract_term_id         = fet1.contract_term_id
                            AND fet1.currency_unit_fk            = fet_cu1.value
                            AND fet_ct1.type                     = 'FeeAndExpenseTerm'
                            AND wov1.approval_status in (5,6)    -- Only 'Approved' or 'Approval Not Required'
                          ) effective_rates
                 WHERE t1.week_ending_date >= TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || q'{
                   AND t1.assignment_continuity_fk  = ac1.assignment_continuity_id
                   AND ac1.assignment_continuity_id = effective_rates.effct_rte_contract_id (+)
                   AND t1.timecard_id               = te1.timecard_fk
                   AND ac1.work_order_fk IS NOT NULL
                   AND ABS(NVL(te1.hours,0)) + ABS(NVL(te1.change_to_hours,0)) != 0 }';
   logger_pkg.debug('create table lego_tc_wo_effective_rates');  
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.debug('create table lego_tc_wo_effective_rates - complete', TRUE);  

   --Gather Stats
   logger_pkg.debug('stats on lego_tc_wo_effective_rates');  
   DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                  tabname          => 'LEGO_TC_WO_EFFECTIVE_RATES',
                                  estimate_percent => 10,
                                  degree           => 6);
   logger_pkg.debug('stats on lego_tc_wo_effective_rates - complete', TRUE);  


   v_sql :=
             'CREATE TABLE lego_tc_wo_rates ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (2,2) */
                       t1.timecard_entry_id,
                       t1.wk_date,
                       t1.assignment_continuity_id,
                       rates.effective_date,
                       rates.termination_date,
                       rates.contract_id,
                       rates.currency_code,
                       rates.supplier_bill_rate,
                       rates.buyer_bill_rate,
                       rates.supplier_ot_rate,
                       rates.buyer_ot_rate,
                       rates.supplier_dt_rate,
                       rates.buyer_dt_rate,
                       rates.buyer_custom_bill_rate,
                       rates.rate_type_id
                  FROM (SELECT DISTINCT timecard_entry_id, wk_date, assignment_continuity_id
                          FROM lego_tc_wo_effective_rates) t1,
                       ( --get_rate_info
                        SELECT cv.contract_fk                  AS contract_id, --assignment_continuity_id
                               cv.contract_version_name        AS contract_version_name,
                               cv.contract_version_number      AS contract_version_number,
                               cv.effective_date,
                               cv.termination_date             AS termination_date,
                               fet_cu.description              AS currency_code,
                               NVL(fet.supplier_bill_rate, 0)  AS supplier_bill_rate,
                               NVL(fet.buyer_bill_rate, 0)     AS buyer_bill_rate,
                               NVL(fet.supplier_ot_rate, 0)    AS supplier_ot_rate,
                               NVL(fet.buyer_ot_rate, 0)       AS buyer_ot_rate,
                               NVL(fet.supplier_dt_rate, 0)    AS supplier_dt_rate,
                               NVL(fet.buyer_dt_rate, 0)       AS buyer_dt_rate,
                               NVL(fet.buyer_adj_bill_rate_rt_idntfr, 0)   AS buyer_custom_bill_rate,
                               fet.buyer_bill_rate_unit_fk     AS rate_type_id
                          FROM contract_version     AS OF SCN lego_refresh_mgr_pkg.get_scn() cv,
                               work_order_version   AS OF SCN lego_refresh_mgr_pkg.get_scn() wov,
                               fee_expense_term     AS OF SCN lego_refresh_mgr_pkg.get_scn() fet,
                               contract_term        AS OF SCN lego_refresh_mgr_pkg.get_scn() fet_ct,
                               currency_unit        fet_cu
                         WHERE cv.contract_version_id           = wov.contract_version_id
                           AND wov.contract_version_id          = fet_ct.contract_version_fk
                           AND wov.work_order_version_state NOT IN (7, 8, 22, 23)
                           AND fet_ct.contract_term_id          = fet.contract_term_id
                           AND fet.currency_unit_fk             = fet_cu.value
                           AND fet_ct.type                      = 'FeeAndExpenseTerm' ) rates
                 WHERE t1.assignment_continuity_id  = rates.contract_id (+)
                   AND rates.contract_version_name  =
                                NVL
                                   ( (SELECT MAX(TO_NUMBER(cv1.contract_version_name))
                                       FROM contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn() cv1
                                       WHERE cv1.contract_fk = contract_id
                                         AND CASE WHEN t1.wk_date IS NOT NULL THEN t1.wk_date
                                             ELSE TO_DATE ('31-JAN-1950','DD-MON-YYYY')
                                             END BETWEEN DECODE (t1.wk_date, NULL, TO_DATE('31-JAN-1950','DD-MON-YYYY'), cv1.effective_date)
                                                     AND DECODE (t1.wk_date, NULL, TO_DATE('31-JAN-1950','DD-MON-YYYY'), cv1.termination_date)
                                          AND EXISTS
                                          ( SELECT 'FOUND'
                                              FROM work_order_version AS OF SCN lego_refresh_mgr_pkg.get_scn() wov1
                                             WHERE wov1.contract_version_id = cv1.contract_version_id
                                               AND wov1.work_order_version_state NOT IN (7, 8, 22, 23))
                                          ),
                                    (SELECT MAX(TO_NUMBER(cv1.contract_version_name))
                                       FROM contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn() cv1
                                      WHERE cv1.contract_fk = contract_id)
                                   )}';
   logger_pkg.debug('create table lego_tc_wo_rates');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.debug('create table lego_tc_wo_rates - complete', TRUE);

   logger_pkg.debug('stats on lego_tc_wo_rates');
   DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                  tabname          => 'LEGO_TC_WO_RATES',
                                  estimate_percent => 10,
                                  degree           => 6);
   logger_pkg.debug('stats on lego_tc_wo_rates - complete', TRUE);

   v_sql :=
             'CREATE TABLE lego_tc_wo_rate_trmt_rates ' ||
                 v_storage ||
              q'{ AS
                  SELECT /*+ PARALLEL (12) */
                         t1.timecard_entry_id,
                         t1.wk_date,
                         t1.assignment_continuity_id,
                         wo_rate_trmt_rates.effective_date,
                         wo_rate_trmt_rates.termination_date,
                         rate_trmt_reg_bill_rate,
                         rate_trmt_ot_bill_rate,
                         rate_trmt_dt_bill_rate,
                         wo_rate_trmt_rates.rate_trmt_cust_bill_rate,
                         rate_trmt_adj_reg_bill_rate,
                         rate_trmt_adj_ot_bill_rate,
                         rate_trmt_adj_dt_bill_rate,
                         rt_trmt_cust_rates.rate_trmt_adj_cust_bill_rate,
                         rate_trmt_rate_type_id
                      FROM (SELECT DISTINCT
                                   timecard_entry_id,
                                   wk_date,
                                   assignment_continuity_id,
                                   rate_treatment_identifier_fk, assignment_edition_id
                              FROM lego_tc_wo_effective_rates
                             WHERE rate_treatment_identifier_fk IS NOT NULL) t1,
                         ( --get_wo_rate_trmt
                          SELECT ae.assignment_edition_id,
                                 te.timecard_entry_id,
                                 cv.contract_version_number,
                                 cv.effective_date,
                                 cv.termination_date,
                                 rate_trmt_rs1.bill_rate              AS rate_trmt_reg_bill_rate,
                                 rate_trmt_rs1.ot_bill_rate           AS rate_trmt_ot_bill_rate,
                                 rate_trmt_rs1.dt_bill_rate           AS rate_trmt_dt_bill_rate,
                                 cust_rate.rate                       AS rate_trmt_cust_bill_rate,
                                 aart.buyer_adj_bill_rate             AS rate_trmt_adj_reg_bill_rate,
                                 aart.buyer_adj_bill_rate_ot          AS rate_trmt_adj_ot_bill_rate,
                                 aart.buyer_adj_bill_rate_dt          AS rate_trmt_adj_dt_bill_rate,
                                 aart.supplier_reimbursement_rate     AS rate_trmt_reg_reimb_rate,
                                 aart.supplier_reimbursement_rate_ot  AS rate_trmt_ot_reimb_rate,
                                 aart.supplier_reimbursement_rate_dt  AS rate_trmt_dt_reimb_rate,
                                 fet.buyer_bill_rate_unit_fk          AS rate_trmt_rate_type_id
                            FROM contract_term                  fet_ct,
                                 fee_expense_term               fet,
                                 work_order                     wo,
                                 contract                       c,
                                 contract_version               cv,
                                 work_order_version             wov,
                                 rate_card_identifier           rci,
                                 assignment_agreement_rate_trmt aart,
                                 rate_set                       rate_trmt_rs1,
                                 assignment_continuity          ac,
                                 assignment_edition             ae,
                                 timecard_entry                 te,
                                 (SELECT *
                                    FROM rate_category_rate
                                   WHERE rate_category_fk = 3)  cust_rate
                           WHERE ac.work_order_fk IS NOT NULL
                             AND ae.assignment_edition_id        = ac.current_edition_fk
                             AND wo.contract_id                  = ac.assignment_continuity_id
                             AND wo.contract_id                  = c.contract_id
                             AND cv.contract_fk                  = c.contract_id
                             AND cv.contract_version_id          = wov.contract_version_id
                             AND cv.contract_version_id          = fet_ct.contract_version_fk
                             AND fet_ct.type                     = 'FeeAndExpenseTerm'
                             AND fet_ct.contract_term_id         = fet.contract_term_id
                             AND fet.contract_term_id            = aart.fee_expense_term_fk(+)
                             AND aart.rate_trmt_identifier_fk    = rci.rate_card_identifier_id(+)
                             AND rate_trmt_rs1.rate_set_id       = aart.treatment_rate_set_fk
                             AND te.rate_treatment_identifier_fk = aart.rate_trmt_identifier_fk
                             AND rate_trmt_rs1.rate_identifier_rate_set_fk = cust_rate.rate_identifier_rate_set_fk(+)
                             )  wo_rate_trmt_rates,
                         (--get rate treatment CUSTOM rates
                          SELECT aart.rate_trmt_identifier_fk,
                                 NVL(MAX(aart.buyer_adj_bill_rate_rt_idntfr),0) AS rate_trmt_adj_cust_bill_rate
                            FROM assignment_agreement_rate_trmt aart,
                                 fee_expense_term               fet
                           WHERE fet.contract_term_id = aart.fee_expense_term_fk(+)
                           GROUP BY aart.rate_trmt_identifier_fk) rt_trmt_cust_rates
                   WHERE t1.assignment_edition_id = wo_rate_trmt_rates.assignment_edition_id
                     AND t1.timecard_entry_id     = wo_rate_trmt_rates.timecard_entry_id
                     AND wo_rate_trmt_rates.contract_version_number = (SELECT MAX(cv1.contract_version_number)
                                                                        FROM contract_version   cv1,
                                                                             work_order_version wov1
                                                                       WHERE cv1.contract_fk         = t1.assignment_continuity_id--cv.contract_fk
                                                                         AND cv1.contract_version_id = wov1.contract_version_id
                                                                         AND (cv1.object_version_state <> 4
                                                                              OR cv1.contract_type = 'WO')
                                                                         AND t1.wk_date BETWEEN cv1.effective_date AND NVL(cv1.termination_date, SYSDATE))
                     AND t1.rate_treatment_identifier_fk = rt_trmt_cust_rates.rate_trmt_identifier_fk(+)}';
   logger_pkg.debug('create table lego_tc_wo_rate_trmt_rates');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.debug('create table lego_tc_wo_rate_trmt_rates - complete', TRUE);
   
   logger_pkg.debug('stats on lego_tc_wo_rate_trmt_rates');
   DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                  tabname          => 'LEGO_TC_WO_RATE_TRMT_RATES',
                                  estimate_percent => 10,
                                  degree           => 6);
   logger_pkg.debug('stats on lego_tc_wo_rate_trmt_rates - complete', TRUE);

   v_sql :=
             'CREATE TABLE lego_tc_wo_tmp ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (10) */
                       point1.timecard_entry_id,
                       point1.timecard_id,
                       point1.buyer_org_id,
                       point1.supplier_org_id,
                       point1.contractor_person_id,
                       point1.hiring_mgr_person_id,
                       point1.candidate_id,
                       point1.wk_date,
                       point1.week_ending_date,
                       point1.timecard_number,
                       point1.timecard_type,
                       point1.cac1_identifier,
                       point1.cac2_identifier,
                       point1.job_id,
                       point1.assignment_continuity_id,
                       point1.work_order_id,
                       point1.assignment_edition_id,
                       point1.timecard_approval_workflow_id,
                       point1.te_udf_collection_id,
                       point1.t_udf_collection_id,
                       SUM(point1.reg_fo_hours)     AS reg_hours,
                       SUM(point1.ot_fo_hours)      AS ot_hours,
                       SUM(point1.dt_fo_hours)      AS dt_hours,
                       SUM(point1.custom_fo_hours)  AS custom_hours,
                       SUM(point1.reg_fo_hours)+
                       SUM(point1.ot_fo_hours)+
                       SUM(point1.dt_fo_hours)+
                       SUM(point1.custom_fo_hours)  AS total_hours_day,
                       point1.change_to_hours       AS total_change_to_hours_day,
                       point1.timecard_state_id,
                       point1.timecard_state,
                       point1.rate_trmt_id,
                       CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id) 
                          WHEN 0 THEN 0 --Hourly
                          WHEN 1 THEN 1 --Daily
                          WHEN 4 THEN 4 --Weekly
                          WHEN 3 THEN 3 --Monthly
                          ELSE NULL
                       END AS rate_type,
                       CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id)
                          WHEN 0 THEN 'Hourly'
                          WHEN 1 THEN 'Daily'
                          WHEN 2 THEN 'Annual'
                          WHEN 3 THEN 'Monthly'
                          WHEN 4 THEN 'Weekly'
                          ELSE 'N/A'
                       END AS rate_type_desc,
                       point1.hours_per_day,
                       point1.is_break,
                       point1.tc_buyer_approved_date,
                       point1.tc_buyer_rejected_date,
                       point1.tc_created_date,
                       point1.tc_saved_date,
                       point1.tc_adjusted_date,
                       point1.tc_rerated_date,
                       point1.tc_approve_req_retract_date,
                       point1.tc_submit_approval_date,
                       point1.tc_archived_date,
                       point1.tc_sar_approved_date,
                       point1.tc_sar_rejected_date,
                       point1.cac1_start_date,
                       point1.cac1_end_date,
                       point1.cac1_guid,
                       point1.cac2_start_date,
                       point1.cac2_end_date,
                       point1.cac2_guid,
                       point1.timecard_currency_id,
                       point1.timecard_currency,
                       ---RATES---
                       COALESCE(point1.effct_rte_supp_bill_rate, rates.supplier_bill_rate, 0) AS reg_bill_rate,
                       COALESCE(point1.effct_rte_supp_ot_rate, rates.supplier_ot_rate, 0)     AS ot_bill_rate,
                       COALESCE(point1.effct_rte_supp_dt_rate, rates.supplier_dt_rate, 0)     AS dt_bill_rate,
                       NVL(c_rate.custom_bill_rate, 0)                                        AS custom_bill_rate,
                       COALESCE(point1.effct_rte_buyer_bill_rate, rates.buyer_bill_rate, 0)   AS adj_reg_bill_rate,
                       COALESCE(point1.effct_rte_buyer_ot_rate, rates.buyer_ot_rate, 0)       AS adj_ot_bill_rate,
                       COALESCE(point1.effct_rte_buyer_dt_rate, rates.buyer_dt_rate, 0)       AS adj_dt_bill_rate,
                       NVL(rates.buyer_custom_bill_rate, 0)                                   AS adj_custom_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_reg_bill_rate,0)                         AS rate_trmt_reg_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_ot_bill_rate,0)                          AS rate_trmt_ot_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_dt_bill_rate,0)                          AS rate_trmt_dt_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_cust_bill_rate,0)                        AS rate_trmt_cust_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_reg_bill_rate,0)                     AS rate_trmt_adj_reg_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_ot_bill_rate,0)                      AS rate_trmt_adj_ot_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_dt_bill_rate,0)                      AS rate_trmt_adj_dt_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_cust_bill_rate,0)                    AS rate_trmt_adj_cust_bill_rate
                  FROM (
                  SELECT DISTINCT
                         lt.timecard_entry_id,
                         lt.timecard_id,
                         lt.buyer_org_id,
                         lt.supplier_org_id,
                         lt.contractor_person_id,
                         lt.hiring_mgr_person_id,
                         lt.candidate_id,
                         lt.wk_date,
                         lt.week_ending_date,
                         lt.timecard_number,
                         lt.timecard_type,
                         lt.cac1_identifier,
                         lt.cac2_identifier,
                         lt.job_id,
                         lt.assignment_continuity_id,
                         lt.work_order_id,
                         lt.assignment_edition_id,
                         lt.timecard_approval_workflow_id,
                         lt.te_udf_collection_id,
                         lt.t_udf_collection_id,
                         lt.reg_fo_hours,    --sum above to flatten into 1 row
                         lt.ot_fo_hours,     --sum above to flatten into 1 row
                         lt.dt_fo_hours,     --sum above to flatten into 1 row
                         lt.custom_fo_hours, --sum above to flatten into 1 row
                         lt.hours,
                         lt.change_to_hours,
                         lt.timecard_state_id,
                         lt.timecard_state,
                         lt.rate_trmt_id,
                         lt.hours_per_day,
                         lt.is_break,
                         lt.tc_buyer_approved_date,
                         lt.tc_buyer_rejected_date,
                         lt.tc_created_date,
                         lt.tc_saved_date,
                         lt.tc_adjusted_date,
                         lt.tc_rerated_date,
                         lt.tc_approve_req_retract_date,
                         lt.tc_submit_approval_date,
                         lt.tc_archived_date,
                         lt.tc_sar_approved_date,
                         lt.tc_sar_rejected_date,
                         lt.cac1_start_date,
                         lt.cac1_end_date,
                         lt.cac1_guid,
                         lt.cac2_start_date,
                         lt.cac2_end_date,
                         lt.cac2_guid,
                         lt.timecard_currency_id,
                         lt.timecard_currency,
                         ---EFFECTIVE RATES----
                         wo_effct_rates.effct_rte_effective_date,
                         wo_effct_rates.effct_rte_termination_date,
                         wo_effct_rates.effct_rte_contract_id,
                         wo_effct_rates.effct_rte_create_date,
                         wo_effct_rates.effct_rte_currency,
                         wo_effct_rates.effct_rte_supp_bill_rate,
                         wo_effct_rates.effct_rte_buyer_bill_rate,
                         wo_effct_rates.effct_rte_supp_ot_rate,
                         wo_effct_rates.effct_rte_buyer_ot_rate,
                         wo_effct_rates.effct_rte_supp_dt_rate,
                         wo_effct_rates.effct_rte_buyer_dt_rate,
                         wo_effct_rates.effct_rte_adj_custom_bill_rate,
                         wo_effct_rates.effct_rte_pay_rate,
                         wo_effct_rates.effct_rte_ot_pay_rate,
                         wo_effct_rates.effct_rte_dt_pay_rate,
                         wo_effct_rates.effct_rte_rate_unit_fk,
                         wo_effct_rates.effct_rte_rate_id_rate_set_fk,
                         wo_effct_rates.effct_rte_markup,
                         wo_effct_rates.effct_rte_ot_markup,
                         wo_effct_rates.effct_rte_dt_markup,
                         wo_effct_rates.effct_rte_supp_rg_reim_rate,
                         wo_effct_rates.effct_rte_supp_ot_reim_rate,
                         wo_effct_rates.effct_rte_supp_dt_reim_rate,
                         wo_effct_rates.effct_rte_supp_cs_reim_rate,
                         wo_effct_rates.effct_rte_rate_type_id,
                         RANK() OVER (PARTITION BY lt.timecard_entry_id ORDER BY wo_effct_rates.effct_rte_create_date DESC NULLS LAST ) rates_rk
                   FROM
                       (SELECT
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 1 THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 1 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS reg_fo_hours,
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 2 THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 2 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS ot_fo_hours,
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 3 THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 3 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS dt_fo_hours,
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk  NOT IN (1,2,3) THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id  NOT IN (1,2,3) AND ri.is_billable = 1 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS custom_fo_hours,
                               te.timecard_entry_id,
                               t.timecard_id,
                               fr.business_org_fk                 AS buyer_org_id,
                               frs.business_org_fk                AS supplier_org_id,
                               c.person_fk                        AS contractor_person_id,
                               hfw.user_fk                        AS hiring_mgr_person_id,
                               c.candidate_id                     AS candidate_id,
                               te.wk_date                         AS wk_date,
                               t.week_ending_date                 AS week_ending_date,
                               t.timecard_number                  AS timecard_number,
                               t.timecard_type                    AS timecard_type,
                               te.cac1_fk                         AS cac1_identifier,
                               te.cac2_fk                         AS cac2_identifier,
                               ac.job_fk                          AS job_id,
                               ac.assignment_continuity_id        AS assignment_continuity_id,
                               ac.work_order_fk                   AS work_order_id,
                               ac.currency_unit_fk                AS timecard_currency_id,
                               cu.description                     AS timecard_currency,
                               ae.assignment_edition_id           AS assignment_edition_id,
                               ae.timecard_approval_workflow_fk   AS timecard_approval_workflow_id,
                               te.udf_collection_fk               AS te_udf_collection_id,
                               t.udf_collection_fk                AS t_udf_collection_id,
                               NVL(te.hours,0)                    AS hours,
                               NVL(te.change_to_hours,0)          AS change_to_hours,
                               t.state_code                       AS timecard_state_id,
                               NVL(timecard_state.constant_description, 'Unknown')  AS timecard_state,
                               rci.description                    AS rate_trmt_id,
                               NVL(hpd.hours_per_day,8)           AS hours_per_day,
                               te.is_break,
                               event_dates.tc_buyer_approved_date,
                               event_dates.tc_buyer_rejected_date,
                               event_dates.tc_created_date,
                               event_dates.tc_saved_date,
                               event_dates.tc_adjusted_date,
                               event_dates.tc_rerated_date,
                               event_dates.tc_approve_req_retract_date,
                               event_dates.tc_submit_approval_date,
                               event_dates.tc_archived_date,
                               event_dates.tc_sar_approved_date,
                               event_dates.tc_sar_rejected_date,
                               cac1.start_date AS cac1_start_date,
                               cac1.end_date   AS cac1_end_date,
                               cac1.cac_guid   AS cac1_guid,
                               cac2.start_date AS cac2_start_date,
                               cac2.end_date   AS cac2_end_date,
                               cac2.cac_guid   AS cac2_guid
                          FROM timecard        AS OF SCN lego_refresh_mgr_pkg.get_scn() t,
                               timecard_entry  AS OF SCN lego_refresh_mgr_pkg.get_scn() te,
                               (SELECT * FROM time_expenditure AS OF SCN lego_refresh_mgr_pkg.get_scn() WHERE is_current = 1) tx,
                               assignment_continuity  AS OF SCN lego_refresh_mgr_pkg.get_scn() ac,
                               assignment_edition     AS OF SCN lego_refresh_mgr_pkg.get_scn() ae,
                               firm_role              AS OF SCN lego_refresh_mgr_pkg.get_scn() fr,
                               firm_role              AS OF SCN lego_refresh_mgr_pkg.get_scn() frs,
                               candidate              AS OF SCN lego_refresh_mgr_pkg.get_scn() c,
                               firm_worker            AS OF SCN lego_refresh_mgr_pkg.get_scn() hfw,
                               rate_identifier        AS OF SCN lego_refresh_mgr_pkg.get_scn() ri,
                               currency_unit          cu,
                               (SELECT constant_value, constant_description
                                  FROM java_constant_lookup
                                 WHERE constant_type    = 'TIMECARD_STATE'
                                   AND UPPER(locale_fk) = 'EN_US') timecard_state,
                               (SELECT lcc.cac_id,
                                       lcc.start_date,
                                       lcc.end_date,
                                       lcc.cac_guid
                                  FROM lego_cac_collection lcc ) cac1,
                               (SELECT lcc.cac_id,
                                       lcc.start_date,
                                       lcc.end_date,
                                       lcc.cac_guid
                                  FROM lego_cac_collection lcc ) cac2,
                               lego_tc_events event_dates,
                               (SELECT pwe.procurement_wkfl_edition_id, wpd.hours_per_day
                                  FROM work_period_definition AS OF SCN lego_refresh_mgr_pkg.get_scn() wpd,
                                       procurement_wkfl_edition AS OF SCN lego_refresh_mgr_pkg.get_scn() pwe
                                 WHERE pwe.work_period_definition_fk = wpd.work_period_definition_id)  hpd,
                               (SELECT rate_card_identifier_id, description
                                  FROM rate_card_identifier) rci
                         WHERE t.week_ending_date >= TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || q'{
                           AND t.assignment_continuity_fk      = ac.assignment_continuity_id
                           AND ac.assignment_continuity_id     = ae.assignment_continuity_fk
                           AND ac.current_edition_fk           = ae.assignment_edition_id
                           AND ac.work_order_fk IS NOT NULL
                           AND ac.candidate_fk                 = c.candidate_id(+)
                           AND ac.currency_unit_fk             = cu.value
                           AND ae.hiring_mgr_fk                = hfw.firm_worker_id(+)
                           AND t.timecard_id                   = te.timecard_fk
                           AND t.procurement_wkfl_edition_fk   = hpd.procurement_wkfl_edition_id (+)
                           AND te.timecard_entry_id            = tx.timecard_entry_fk (+)
                           AND te.rate_identifier_fk           = ri.rate_identifier_id
                           AND te.rate_treatment_identifier_fk = rci.rate_card_identifier_id (+)
                           AND ac.owning_buyer_firm_fk         = fr.firm_id
                           AND ac.owning_supply_firm_fk        = frs.firm_id
                           AND t.state_code                    = timecard_state.constant_value(+)
                           AND te.cac1_fk                      = cac1.cac_id(+)
                           AND te.cac2_fk                      = cac2.cac_id(+)
                           AND t.state_code != 7
                           AND ABS(NVL(te.hours,0)) + ABS(NVL(te.change_to_hours,0)) != 0
                           AND CASE WHEN te.change_to_hours <= 0 THEN 1
                               ELSE NVL (te.change_to_hours, 0) END
                               >
                               CASE WHEN timecard_type = 'Timecard Adjustment' THEN 0
                               ELSE -1 END
                           AND t.timecard_id                   = event_dates.timecard_id(+) ) lt,
                       lego_tc_wo_effective_rates wo_effct_rates
                  WHERE lt.timecard_entry_id = wo_effct_rates.timecard_entry_id
                    AND lt.week_ending_date >= TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || q'{
                    AND lt.wk_date BETWEEN NVL(wo_effct_rates.effct_rte_effective_date,TO_DATE('25-OCT-1971','DD-MON-YYYY')) AND NVL(wo_effct_rates.effct_rte_termination_date, SYSDATE)
                       ) point1,
                       lego_tc_wo_rates rates, --use when effective rates are null
                  (SELECT rate_identifier_rate_set_fk, rate AS custom_bill_rate
                     FROM rate_category_rate AS OF SCN lego_refresh_mgr_pkg.get_scn()
                    WHERE rate_category_fk = 3) c_rate, --used to get wo custom supplier bill rate
                  lego_tc_wo_rate_trmt_rates rate_trmt_rates
                WHERE point1.rates_rk                       = 1
                  AND point1.timecard_entry_id              = rates.timecard_entry_id (+)
                  AND point1.effct_rte_rate_id_rate_set_fk  = c_rate.rate_identifier_rate_set_fk (+)
                  AND point1.timecard_entry_id              = rate_trmt_rates.timecard_entry_id (+)
                  GROUP BY
                         point1.timecard_entry_id,
                         point1.timecard_id,
                         point1.buyer_org_id,
                         point1.supplier_org_id,
                         point1.contractor_person_id,
                         point1.hiring_mgr_person_id,
                         point1.candidate_id,
                         point1.wk_date,
                         point1.week_ending_date,
                         point1.timecard_number,
                         point1.timecard_type,
                         point1.cac1_identifier,
                         point1.cac2_identifier,
                         point1.job_id,
                         point1.assignment_continuity_id,
                         point1.work_order_id,
                         point1.assignment_edition_id,
                         point1.timecard_approval_workflow_id,
                         point1.te_udf_collection_id,
                         point1.t_udf_collection_id,
                         point1.hours,
                         point1.change_to_hours,
                         point1.timecard_state_id,
                         point1.timecard_state,
                         point1.rate_trmt_id,
                         CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id) 
                            WHEN 0 THEN 0 --Hourly
                            WHEN 1 THEN 1 --Daily
                            WHEN 4 THEN 4 --Weekly
                            WHEN 3 THEN 3 --Monthly
                            ELSE NULL
                         END,
                         CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id)
                            WHEN 0 THEN 'Hourly'
                            WHEN 1 THEN 'Daily'
                            WHEN 2 THEN 'Annual'
                            WHEN 3 THEN 'Monthly'
                            WHEN 4 THEN 'Weekly'
                            ELSE 'N/A'
                         END,
                         point1.hours_per_day,
                         point1.is_break,
                         point1.tc_buyer_approved_date,
                         point1.tc_buyer_rejected_date,
                         point1.tc_created_date,
                         point1.tc_saved_date,
                         point1.tc_adjusted_date,
                         point1.tc_rerated_date,
                         point1.tc_approve_req_retract_date,
                         point1.tc_submit_approval_date,
                         point1.tc_archived_date,
                         point1.tc_sar_approved_date,
                         point1.tc_sar_rejected_date,
                         point1.cac1_start_date,
                         point1.cac1_end_date,
                         point1.cac1_guid,
                         point1.cac2_start_date,
                         point1.cac2_end_date,
                         point1.cac2_guid,
                         point1.timecard_currency_id,
                         point1.timecard_currency,
                         COALESCE(point1.effct_rte_supp_bill_rate, rates.supplier_bill_rate, 0),
                         COALESCE(point1.effct_rte_supp_ot_rate, rates.supplier_ot_rate, 0),
                         COALESCE(point1.effct_rte_supp_dt_rate, rates.supplier_dt_rate, 0),
                         NVL(c_rate.custom_bill_rate, 0),
                         COALESCE(point1.effct_rte_buyer_bill_rate, rates.buyer_bill_rate, 0),
                         COALESCE(point1.effct_rte_buyer_ot_rate, rates.buyer_ot_rate, 0),
                         COALESCE(point1.effct_rte_buyer_dt_rate, rates.buyer_dt_rate, 0),
                         NVL(rates.buyer_custom_bill_rate, 0),
                         point1.effct_rte_rate_id_rate_set_fk,
                         NVL(rate_trmt_rates.rate_trmt_reg_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_ot_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_dt_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_cust_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_reg_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_ot_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_dt_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_cust_bill_rate,0)}';
   logger_pkg.debug('create table lego_tc_wo_tmp');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.debug('create table lego_tc_wo_tmp - complete',TRUE);

   --Start EA!
   v_sql :=
             'CREATE TABLE lego_tc_ea_rates ' ||
                 v_storage ||
              q'{ AS
                  SELECT /*+ PARALLEL (2,2) */
                         timecard_entry_id,
                         timecard_id,
                         wk_date,
                         week_ending_date,
                         assignment_continuity_id,
                         rate_treatment_identifier_fk,
                         assignment_edition_id,
                         rates_effective_date,
                         rates_termination_date,
                         currency_code,
                         NVL(supplier_bill_rate,0)        AS supplier_bill_rate,
                         NVL(buyer_bill_rate,0)           AS buyer_bill_rate,
                         NVL(supplier_ot_rate,0)          AS supplier_ot_rate,
                         NVL(buyer_ot_rate,0)             AS buyer_ot_rate,
                         NVL(supplier_dt_rate,0)          AS supplier_dt_rate,
                         NVL(buyer_dt_rate,0)             AS buyer_dt_rate,
                         NVL(custom_rate.rate,0)          AS custom_bill_rate,
                         NVL(adjusted_custom_bill_rate,0) AS adjusted_custom_bill_rate,
                         rates.rate_identifier_rate_set_fk,
                         rate_type_id
                    FROM (SELECT timecard_entry_id,
                                 timecard_id,
                                 wk_date,
                                 week_ending_date,
                                 assignment_continuity_id,
                                 rate_treatment_identifier_fk,
                                 assignment_edition_id,
                                 rates_effective_date,
                                 rates_termination_date,
                                 currency_code,
                                 supplier_bill_rate,
                                 buyer_bill_rate,
                                 supplier_ot_rate,
                                 buyer_ot_rate,
                                 supplier_dt_rate,
                                 buyer_dt_rate,
                                 adjusted_custom_bill_rate,
                                 rate_identifier_rate_set_fk,
                                 rate_type_id,
                                 RANK () OVER (PARTITION BY timecard_entry_id ORDER BY rates_effective_date DESC NULLS LAST, rownum DESC) rk
                            FROM (SELECT te1.timecard_entry_id,
                                         t1.timecard_id,
                                         te1.wk_date,
                                         t1.week_ending_date,
                                         ac1.assignment_continuity_id,
                                         te1.rate_treatment_identifier_fk,
                                         ac1.current_edition_fk AS assignment_edition_id,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN effective_date        ELSE NULL END AS rates_effective_date,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN termination_date      ELSE NULL END AS rates_termination_date,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN currency_code         ELSE NULL END AS currency_code,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN supplier_bill_rate    ELSE NULL END AS supplier_bill_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN buyer_bill_rate       ELSE NULL END AS buyer_bill_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN supplier_ot_rate      ELSE NULL END AS supplier_ot_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN buyer_ot_rate         ELSE NULL END AS buyer_ot_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN supplier_dt_rate      ELSE NULL END AS supplier_dt_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN buyer_dt_rate         ELSE NULL END AS buyer_dt_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN adjusted_custom_bill_rate  ELSE NULL END AS adjusted_custom_bill_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN rate_identifier_rate_set_fk   ELSE NULL END AS rate_identifier_rate_set_fk,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN rate_type_id                  ELSE NULL END AS rate_type_id
                                    FROM timecard  AS OF SCN lego_refresh_mgr_pkg.get_scn() t1,
                                         timecard_entry  AS OF SCN lego_refresh_mgr_pkg.get_scn() te1,
                                         assignment_continuity  AS OF SCN lego_refresh_mgr_pkg.get_scn() ac1,
                                         assignment_edition     AS OF SCN lego_refresh_mgr_pkg.get_scn() ae1,
                                         ( --get_rates
                                          SELECT ald.valid_from                  AS effective_date,
                                                 ald.valid_to                    AS termination_date,
                                                 ald.assignment_edition_fk       AS assignment_edition_id,
                                                 rs_cu.description               AS currency_code,
                                                 rs.bill_rate                    AS supplier_bill_rate,
                                                 ald.buyer_adj_bill_rate         AS buyer_bill_rate,
                                                 rs.ot_bill_rate                 AS supplier_ot_rate,
                                                 ald.buyer_adj_bill_rate_ot      AS buyer_ot_rate,
                                                 rs.dt_bill_rate                 AS supplier_dt_rate,
                                                 ald.buyer_adj_bill_rate_dt      AS buyer_dt_rate,
                                                 ili_buyer_fee_adj.amount        AS adjusted_custom_bill_rate,
                                                 rs.rate_identifier_rate_set_fk  AS rate_identifier_rate_set_fk,
                                                 ald.rate_unit_fk                AS rate_type_id
                                            FROM assignment_line_detail   AS OF SCN lego_refresh_mgr_pkg.get_scn() ald,
                                                 rate_set                 AS OF SCN lego_refresh_mgr_pkg.get_scn() rs,
                                                 currency_unit            rs_cu,
                                                 invoice_line_item        AS OF SCN lego_refresh_mgr_pkg.get_scn() ili_buyer_fee_adj
                                           WHERE ald.rate_set_fk                   = rs.rate_set_id
                                             AND ald.buyer_adj_bill_rate_rt_idntfr = ili_buyer_fee_adj.identifier(+)
                                             AND rs.currency_unit_fk               = rs_cu.value
                                         ) get_rates
                                   WHERE t1.week_ending_date >= TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || q'{
                                     AND t1.assignment_continuity_fk  = ac1.assignment_continuity_id
                                     AND ac1.assignment_continuity_id = ae1.assignment_continuity_fk --12.0
                                     AND ae1.assignment_edition_id    = get_rates.assignment_edition_id(+) --12.0
                                     AND ac1.work_order_fk IS NULL --EA and TA only
                                     AND t1.timecard_id               = te1.timecard_fk
                                     AND ABS(NVL(te1.hours,0)) + ABS(NVL(te1.change_to_hours,0)) != 0)) rates,
                          --get_custom_rate
                         (SELECT rate_identifier_rate_set_fk, rate
                            FROM rate_category_rate AS OF SCN lego_refresh_mgr_pkg.get_scn()
                           WHERE rate_category_fk = 3) custom_rate
                   WHERE rates.rate_identifier_rate_set_fk = custom_rate.rate_identifier_rate_set_fk(+)
                     AND rates.rk = 1}';
   logger_pkg.debug('create table lego_tc_ea_rates');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.debug('create table lego_tc_ea_rates - complete', TRUE);

   logger_pkg.debug('stats on lego_tc_ea_rates');
   DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                  tabname          => 'LEGO_TC_EA_RATES',
                                  estimate_percent => 10,
                                  degree           => 6);
   logger_pkg.debug('stats on lego_tc_ea_rates - complete', TRUE);

   v_sql :=
             'CREATE TABLE lego_tc_ea_rate_trmt_rates ' ||
                 v_storage ||
              q'{ AS
              SELECT /*+ PARALLEL (2,2) */
                     l.timecard_entry_id,
                     l.wk_date,
                     l.assignment_continuity_id,
                     ald.valid_from  AS effective_date,
                     ald.valid_to    AS termination_date,
                     NVL(rate_trmt_rs1.bill_rate,0)                      AS rate_trmt_reg_bill_rate,
                     NVL(rate_trmt_rs1.ot_bill_rate,0)                   AS rate_trmt_ot_bill_rate,
                     NVL(rate_trmt_rs1.dt_bill_rate,0)                   AS rate_trmt_dt_bill_rate,
                     NVL(cust_rate.rate,0)                               AS rate_trmt_cust_bill_rate,
                     NVL(aart.buyer_adj_bill_rate,0)                     AS rate_trmt_adj_reg_bill_rate,
                     NVL(aart.buyer_adj_bill_rate_ot,0)                  AS rate_trmt_adj_ot_bill_rate,
                     NVL(aart.buyer_adj_bill_rate_dt,0)                  AS rate_trmt_adj_dt_bill_rate,
                     NVL(aart.buyer_adj_bill_rate_rt_idntfr,0)           AS rate_trmt_adj_cust_bill_rate,
                     ald.rate_unit_fk                                    AS rate_trmt_rate_type_id
                FROM lego_tc_ea_rates l,
                     assignment_line_detail AS OF SCN lego_refresh_mgr_pkg.get_scn() ald,
                     assignment_agreement_rate_trmt AS OF SCN lego_refresh_mgr_pkg.get_scn() aart,
                     rate_set AS OF SCN lego_refresh_mgr_pkg.get_scn() rate_trmt_rs1,
                     (SELECT *
                        FROM rate_category_rate AS OF SCN lego_refresh_mgr_pkg.get_scn()
                       WHERE rate_category_fk = 3)  cust_rate
               WHERE l.rate_treatment_identifier_fk IS NOT NULL
                 AND ald.assignment_edition_fk        = l.assignment_edition_id
                 AND l.wk_date BETWEEN ald.valid_from AND ald.valid_to
                 AND aart.assignment_line_detail_fk   = ald.assignment_line_detail_id
                 AND aart.rate_trmt_identifier_fk     = l.rate_treatment_identifier_fk
                 AND aart.treatment_rate_set_fk       = rate_trmt_rs1.rate_set_id
                 AND rate_trmt_rs1.rate_identifier_rate_set_fk = cust_rate.rate_identifier_rate_set_fk(+)}';
   logger_pkg.debug('create table lego_tc_ea_rate_trmt_rates');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.debug('create table lego_tc_ea_rate_trmt_rates - complete', TRUE);

   logger_pkg.debug('stats on lego_tc_ea_rate_trmt_rates');
   DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                  tabname          => 'LEGO_TC_EA_RATE_TRMT_RATES',
                                  estimate_percent => 10,
                                  degree           => 6);
   logger_pkg.debug('stats on lego_tc_ea_rate_trmt_rates - complete', TRUE);

   v_sql :=
             'CREATE TABLE lego_tc_ea_tmp ' ||
                 v_storage ||
              q'{ AS
                  SELECT /*+ PARALLEL (12) */
                         point1.timecard_entry_id,
                         point1.timecard_id,
                         point1.buyer_org_id,
                         point1.supplier_org_id,
                         point1.contractor_person_id,
                         point1.hiring_mgr_person_id,
                         point1.candidate_id,
                         point1.wk_date,
                         point1.week_ending_date,
                         point1.timecard_number,
                         point1.timecard_type,
                         point1.cac1_identifier,
                         point1.cac2_identifier,
                         point1.job_id,
                         point1.assignment_continuity_id,
                         point1.work_order_id,
                         point1.assignment_edition_id,
                         point1.timecard_approval_workflow_id,
                         point1.te_udf_collection_id,
                         point1.t_udf_collection_id,
                         SUM(point1.reg_fo_hours)     AS reg_hours,
                         SUM(point1.ot_fo_hours)      AS ot_hours,
                         SUM(point1.dt_fo_hours)      AS dt_hours,
                         SUM(point1.custom_fo_hours)  AS custom_hours,
                         SUM(point1.reg_fo_hours)+
                            SUM(point1.ot_fo_hours)+
                            SUM(point1.dt_fo_hours)+
                            SUM(point1.custom_fo_hours)  AS total_hours_day,
                         point1.change_to_hours       AS total_change_to_hours_day,
                         point1.timecard_state_id,
                         point1.timecard_state,
                         point1.rate_trmt_id,
                         CASE point1.rate_type_id 
                            WHEN 0 THEN 0 --Hourly
                            WHEN 1 THEN 1 --Daily
                            WHEN 4 THEN 4 --Weekly
                            WHEN 3 THEN 3 --Monthly
                            ELSE NULL
                         END AS rate_type,
                         CASE point1.rate_type_id
                            WHEN 0 THEN 'Hourly'
                            WHEN 1 THEN 'Daily'
                            WHEN 2 THEN 'Annual'
                            WHEN 3 THEN 'Monthly'
                            WHEN 4 THEN 'Weekly'
                            ELSE 'N/A'
                         END AS rate_type_desc,
                         point1.hours_per_day,
                         point1.is_break,
                         point1.tc_buyer_approved_date,
                         point1.tc_buyer_rejected_date,
                         point1.tc_created_date,
                         point1.tc_saved_date,
                         point1.tc_adjusted_date,
                         point1.tc_rerated_date,
                         point1.tc_approve_req_retract_date,
                         point1.tc_submit_approval_date,
                         point1.tc_archived_date,
                         point1.tc_sar_approved_date,
                         point1.tc_sar_rejected_date,
                         point1.cac1_start_date,
                         point1.cac1_end_date,
                         point1.cac1_guid,
                         point1.cac2_start_date,
                         point1.cac2_end_date,
                         point1.cac2_guid,
                         point1.timecard_currency_id,
                         point1.timecard_currency,
                         --RATES--
                         reg_bill_rate,
                         ot_bill_rate,
                         dt_bill_rate,
                         custom_bill_rate,
                         adj_reg_bill_rate,
                         adj_ot_bill_rate,
                         adj_dt_bill_rate,
                         adj_custom_bill_rate,
                         rate_trmt_reg_bill_rate,
                         rate_trmt_ot_bill_rate,
                         rate_trmt_dt_bill_rate,
                         rate_trmt_cust_bill_rate,
                         rate_trmt_adj_reg_bill_rate,
                         rate_trmt_adj_ot_bill_rate,
                         rate_trmt_adj_dt_bill_rate,
                         rate_trmt_adj_cust_bill_rate
                    FROM (SELECT lt.timecard_entry_id,
                                 lt.timecard_id,
                                 lt.buyer_org_id,
                                 lt.supplier_org_id,
                                 lt.contractor_person_id,
                                 lt.hiring_mgr_person_id,
                                 lt.candidate_id,
                                 lt.wk_date,
                                 lt.week_ending_date,
                                 lt.timecard_number,
                                 lt.timecard_type,
                                 lt.cac1_identifier,
                                 lt.cac2_identifier,
                                 lt.job_id,
                                 lt.assignment_continuity_id,
                                 lt.work_order_id,
                                 lt.assignment_edition_id,
                                 lt.timecard_approval_workflow_id,
                                 lt.te_udf_collection_id,
                                 lt.t_udf_collection_id,
                                 lt.reg_fo_hours,    --sum above to flatten into 1 row
                                 lt.ot_fo_hours,     --sum above to flatten into 1 row
                                 lt.dt_fo_hours,     --sum above to flatten into 1 row
                                 lt.custom_fo_hours, --sum above to flatten into 1 row
                                 lt.hours,
                                 lt.change_to_hours,
                                 lt.timecard_state_id,
                                 lt.timecard_state,
                                 lt.rate_trmt_id,
                                 lt.hours_per_day,
                                 lt.is_break,
                                 lt.tc_buyer_approved_date,
                                 lt.tc_buyer_rejected_date,
                                 lt.tc_created_date,
                                 lt.tc_saved_date,
                                 lt.tc_adjusted_date,
                                 lt.tc_rerated_date,
                                 lt.tc_approve_req_retract_date,
                                 lt.tc_submit_approval_date,
                                 lt.tc_archived_date,
                                 lt.tc_sar_approved_date,
                                 lt.tc_sar_rejected_date,
                                 lt.cac1_start_date,
                                 lt.cac1_end_date,
                                 lt.cac1_guid,
                                 lt.cac2_start_date,
                                 lt.cac2_end_date,
                                 lt.cac2_guid,
                                 lt.timecard_currency_id,
                                 lt.timecard_currency,
                                 ---RATES----
                                 ea_rates.supplier_bill_rate   AS reg_bill_rate,
                                 ea_rates.supplier_ot_rate     AS ot_bill_rate,
                                 ea_rates.supplier_dt_rate     AS dt_bill_rate,
                                 ea_rates.custom_bill_rate     AS custom_bill_rate,
                                 ea_rates.buyer_bill_rate      AS adj_reg_bill_rate,
                                 ea_rates.buyer_ot_rate        AS adj_ot_bill_rate,
                                 ea_rates.buyer_dt_rate        AS adj_dt_bill_rate,
                                 ea_rates.adjusted_custom_bill_rate AS adj_custom_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_reg_bill_rate,0)      AS rate_trmt_reg_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_ot_bill_rate,0)       AS rate_trmt_ot_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_dt_bill_rate,0)       AS rate_trmt_dt_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_cust_bill_rate,0)     AS rate_trmt_cust_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_reg_bill_rate,0)  AS rate_trmt_adj_reg_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_ot_bill_rate,0)   AS rate_trmt_adj_ot_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_dt_bill_rate,0)   AS rate_trmt_adj_dt_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_cust_bill_rate,0) AS rate_trmt_adj_cust_bill_rate,
                                 NVL(ea_rates.rate_type_id, trmt_ea_rates.rate_trmt_rate_type_id) AS rate_type_id
                            FROM
                                (SELECT
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 1 THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 1 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS reg_fo_hours,
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 2 THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 2 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS OT_fo_hours,
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 3 THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 3 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS DT_fo_hours,
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk NOT IN (1,2,3) THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id  NOT IN (1,2,3) AND ri.is_billable = 1 AND te.is_break=0 THEN nvl(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS CUSTOM_fo_hours,
                                       te.timecard_entry_id,
                                       t.timecard_id,
                                       fr.business_org_fk    AS buyer_org_id,
                                       frs.business_org_fk   AS supplier_org_id,
                                       c.person_fk           AS contractor_person_id,
                                       hfw.user_fk           AS hiring_mgr_person_id,
                                       c.candidate_id        AS candidate_id,
                                       te.wk_date            AS wk_date,
                                       t.week_ending_date    AS week_ending_date,
                                       t.timecard_number     AS timecard_number,
                                       t.timecard_type       AS timecard_type,
                                       te.cac1_fk            AS cac1_identifier,
                                       te.cac2_fk            AS cac2_identifier,
                                       ac.job_fk             AS job_id,
                                       ac.currency_unit_fk   AS timecard_currency_id,
                                       cu.description        AS timecard_currency,
                                       ac.assignment_continuity_id        AS assignment_continuity_id,
                                       ac.work_order_fk                   AS work_order_id,
                                       ae.assignment_edition_id           AS assignment_edition_id,
                                       ae.timecard_approval_workflow_fk   AS timecard_approval_workflow_id,
                                       te.udf_collection_fk               AS te_udf_collection_id,
                                       t.udf_collection_fk                AS t_udf_collection_id,
                                       NVL(te.hours,0)                    AS hours,
                                       NVL(te.change_to_hours,0)          AS change_to_hours,
                                       t.state_code                       AS timecard_state_id,
                                       NVL(timecard_state.constant_description, 'Unknown')  AS timecard_state,
                                       rci.description                    AS rate_trmt_id,
                                       NVL(hpd.hours_per_day,8)           AS hours_per_day,
                                       te.is_break,
                                       event_dates.tc_buyer_approved_date,
                                       event_dates.tc_buyer_rejected_date,
                                       event_dates.tc_created_date,
                                       event_dates.tc_saved_date,
                                       event_dates.tc_adjusted_date,
                                       event_dates.tc_rerated_date,
                                       event_dates.tc_approve_req_retract_date,
                                       event_dates.tc_submit_approval_date,
                                       event_dates.tc_archived_date,
                                       event_dates.tc_sar_approved_date,
                                       event_dates.tc_sar_rejected_date,
                                       cac1.start_date AS cac1_start_date,
                                       cac1.end_date   AS cac1_end_date,
                                       cac1.cac_guid   AS cac1_guid,
                                       cac2.start_date AS cac2_start_date,
                                       cac2.end_date   AS cac2_end_date,
                                       cac2.cac_guid   AS cac2_guid
                                  FROM timecard        AS OF SCN lego_refresh_mgr_pkg.get_scn() t,
                                       timecard_entry  AS OF SCN lego_refresh_mgr_pkg.get_scn() te,
                                       (SELECT * FROM time_expenditure AS OF SCN lego_refresh_mgr_pkg.get_scn() WHERE is_current = 1) tx,
                                       assignment_continuity  AS OF SCN lego_refresh_mgr_pkg.get_scn() ac,
                                       currency_unit          cu,
                                       assignment_edition     AS OF SCN lego_refresh_mgr_pkg.get_scn() ae,
                                       firm_role              AS OF SCN lego_refresh_mgr_pkg.get_scn() fr,
                                       firm_role              AS OF SCN lego_refresh_mgr_pkg.get_scn() frs,
                                       candidate              AS OF SCN lego_refresh_mgr_pkg.get_scn() c,
                                       firm_worker            AS OF SCN lego_refresh_mgr_pkg.get_scn() hfw,
                                       rate_identifier        AS OF SCN lego_refresh_mgr_pkg.get_scn() ri,
                                       (SELECT constant_value, constant_description
                                          FROM java_constant_lookup
                                         WHERE constant_type    = 'TIMECARD_STATE'
                                           AND UPPER(locale_fk) = 'EN_US') timecard_state,
                                       (SELECT lcc.cac_id,
                                               lcc.start_date,
                                               lcc.end_date,
                                               lcc.cac_guid
                                          FROM lego_cac_collection lcc ) cac1,
                                       (SELECT lcc.cac_id,
                                               lcc.start_date,
                                               lcc.end_date,
                                               lcc.cac_guid
                                          FROM lego_cac_collection lcc ) cac2,
                                       lego_tc_events event_dates,
                                       (SELECT pwe.procurement_wkfl_edition_id, wpd.hours_per_day
                                          FROM work_period_definition AS OF SCN lego_refresh_mgr_pkg.get_scn() wpd,
                                               procurement_wkfl_edition AS OF SCN lego_refresh_mgr_pkg.get_scn() pwe
                                         WHERE pwe.work_period_definition_fk = wpd.work_period_definition_id)  hpd,
                                       (SELECT rate_card_identifier_id, description
                                          FROM rate_card_identifier AS OF SCN lego_refresh_mgr_pkg.get_scn()) rci
                                 WHERE t.week_ending_date >= TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || q'{
                                   AND t.assignment_continuity_fk      = ac.assignment_continuity_id
                                   AND ac.assignment_continuity_id     = ae.assignment_continuity_fk
                                   AND ac.current_edition_fk           = ae.assignment_edition_id
                                   AND ac.work_order_fk IS NULL
                                   AND ac.currency_unit_fk             = cu.value
                                   AND ac.candidate_fk                 = c.candidate_id(+)
                                   AND ae.hiring_mgr_fk                = hfw.firm_worker_id(+)
                                   AND t.timecard_id                   = te.timecard_fk
                                   AND t.procurement_wkfl_edition_fk   = hpd.procurement_wkfl_edition_id (+)
                                   AND te.timecard_entry_id            = tx.timecard_entry_fk (+)
                                   AND te.rate_identifier_fk           = ri.rate_identifier_id
                                   AND te.rate_treatment_identifier_fk = rci.rate_card_identifier_id (+)
                                   AND ac.owning_buyer_firm_fk         = fr.firm_id
                                   AND ac.owning_supply_firm_fk        = frs.firm_id
                                   AND t.state_code                    = timecard_state.constant_value(+)
                                   AND te.cac1_fk                      = cac1.cac_id(+)
                                   AND te.cac2_fk                      = cac2.cac_id(+)
                                   AND t.state_code != 7
                                   AND ABS(NVL(te.hours,0)) + ABS(NVL(te.change_to_hours,0)) != 0
                                   AND CASE WHEN te.change_to_hours <= 0 THEN 1
                                       ELSE NVL (te.change_to_hours, 0) END
                                       >
                                       CASE WHEN timecard_type = 'Timecard Adjustment' THEN 0
                                       ELSE -1 END
                                   AND t.timecard_id                   = event_dates.timecard_id(+) ) lt,
                                lego_tc_ea_rates   ea_rates,
                                lego_tc_ea_rate_trmt_rates trmt_ea_rates
                        WHERE lt.timecard_entry_id = ea_rates.timecard_entry_id
                          AND lt.timecard_entry_id = trmt_ea_rates.timecard_entry_id (+)
                         ) point1
                  GROUP BY
                           point1.timecard_entry_id,
                           point1.timecard_id,
                           point1.buyer_org_id,
                           point1.supplier_org_id,
                           point1.contractor_person_id,
                           point1.hiring_mgr_person_id,
                           point1.candidate_id,
                           point1.wk_date,
                           point1.week_ending_date,
                           point1.timecard_number,
                           point1.timecard_type,
                           point1.cac1_identifier,
                           point1.cac2_identifier,
                           point1.job_id,
                           point1.assignment_continuity_id,
                           point1.work_order_id,
                           point1.assignment_edition_id,
                           point1.timecard_approval_workflow_id,
                           point1.te_udf_collection_id,
                           point1.t_udf_collection_id,
                           point1.hours,
                           point1.change_to_hours,
                           point1.timecard_state_id,
                           point1.timecard_state,
                           point1.rate_trmt_id,
                           CASE point1.rate_type_id
                              WHEN 0 THEN 0 --Hourly
                              WHEN 1 THEN 1 --Daily
                              WHEN 4 THEN 4 --Weekly
                              WHEN 3 THEN 3 --Monthly
                              ELSE NULL
                           END,
                           CASE point1.rate_type_id
                              WHEN 0 THEN 'Hourly'
                              WHEN 1 THEN 'Daily'
                              WHEN 2 THEN 'Annual'
                              WHEN 3 THEN 'Monthly'
                              WHEN 4 THEN 'Weekly'
                              ELSE 'N/A'
                           END,
                           point1.hours_per_day,
                           point1.is_break,
                           point1.tc_buyer_approved_date,
                           point1.tc_buyer_rejected_date,
                           point1.tc_created_date,
                           point1.tc_saved_date,
                           point1.tc_adjusted_date,
                           point1.tc_rerated_date,
                           point1.tc_approve_req_retract_date,
                           point1.tc_submit_approval_date,
                           point1.tc_archived_date,
                           point1.tc_sar_approved_date,
                           point1.tc_sar_rejected_date,
                           point1.cac1_start_date,
                           point1.cac1_end_date,
                           point1.cac1_guid,
                           point1.cac2_start_date,
                           point1.cac2_end_date,
                           point1.cac2_guid,
                           point1.timecard_currency_id,
                           point1.timecard_currency,
                           reg_bill_rate,
                           ot_bill_rate,
                           dt_bill_rate,
                           custom_bill_rate,
                           adj_reg_bill_rate,
                           adj_ot_bill_rate,
                           adj_dt_bill_rate,
                           adj_custom_bill_rate,
                           rate_trmt_reg_bill_rate,
                           rate_trmt_ot_bill_rate,
                           rate_trmt_dt_bill_rate,
                           rate_trmt_cust_bill_rate,
                           rate_trmt_adj_reg_bill_rate,
                           rate_trmt_adj_ot_bill_rate,
                           rate_trmt_adj_dt_bill_rate,
                           rate_trmt_adj_cust_bill_rate}';
   logger_pkg.debug('create table lego_tc_ea_tmp');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.debug('create table lego_tc_ea_tmp - complete', TRUE);

   v_sql :=
         q'{INSERT
              INTO lego_timecard_future_gtt
           (timecard_entry_id, timecard_id, buyer_org_id, supplier_org_id, contractor_person_id,
            hiring_mgr_person_id, candidate_id, wk_date, week_ending_date, timecard_number,
            timecard_type, cac1_identifier, cac2_identifier, job_id, assignment_continuity_id,
            assignment_edition_id, timecard_approval_workflow_id, te_udf_collection_id,
            t_udf_collection_id, reg_hours, ot_hours, dt_hours, custom_hours, total_hours_day,
            total_change_to_hours_day, timecard_state_id, timecard_state, rate_trmt_id, rate_type_desc,
            hours_per_day, is_break, tc_buyer_approved_date, tc_buyer_rejected_date, tc_created_date,
            tc_saved_date, tc_adjusted_date, tc_rerated_date, tc_approve_req_retract_date,
            tc_submit_approval_date, tc_archived_date, tc_sar_approved_date, tc_sar_rejected_date,
            cac1_start_date, cac1_end_date, cac1_guid, cac2_start_date, cac2_end_date, cac2_guid,
            timecard_currency, reg_bill_rate, ot_bill_rate, dt_bill_rate, custom_bill_rate, adj_reg_bill_rate,
            adj_ot_bill_rate, adj_dt_bill_rate, adj_custom_bill_rate, rate_trmt_reg_bill_rate,
            rate_trmt_ot_bill_rate, rate_trmt_dt_bill_rate, rate_trmt_cust_bill_rate, rate_trmt_adj_reg_bill_rate,
            rate_trmt_adj_ot_bill_rate, rate_trmt_adj_dt_bill_rate, rate_trmt_adj_cust_bill_rate,
            contractor_spend, cont_spend_amount_adj, timecard_currency_id, invoiced_amount)
        SELECT /*+ PARALLEL (6) */
               CAST(t.timecard_entry_id AS NUMBER)           AS timecard_entry_id,
               CAST(timecard_id AS NUMBER)                   AS timecard_id,
               CAST(buyer_org_id AS NUMBER)                  AS buyer_org_id,
               CAST(supplier_org_id AS NUMBER)               AS supplier_org_id,
               CAST(contractor_person_id AS NUMBER)          AS contractor_person_id,
               CAST(hiring_mgr_person_id AS NUMBER)          AS hiring_mgr_person_id,
               CAST(candidate_id AS NUMBER)                  AS candidate_id,
               CAST(wk_date AS DATE)                         AS wk_date,
               CAST(week_ending_date AS DATE)                AS week_ending_date,
               CAST(timecard_number AS VARCHAR2(256))        AS timecard_number,
               CAST(timecard_type AS VARCHAR2(20))           AS timecard_type,
               CAST(cac1_identifier AS NUMBER)               AS cac1_identifier,
               CAST(cac2_identifier AS NUMBER)               AS cac2_identifier,
               CAST(job_id AS NUMBER)                        AS job_id,
               CAST(assignment_continuity_id AS NUMBER)      AS assignment_continuity_id,
               CAST(assignment_edition_id AS NUMBER)         AS assignment_edition_id,
               CAST(timecard_approval_workflow_id AS NUMBER) AS timecard_approval_workflow_id,
               CAST(te_udf_collection_id AS NUMBER)          AS te_udf_collection_id,
               CAST(t_udf_collection_id AS NUMBER)           AS t_udf_collection_id,
               CAST(reg_hours AS NUMBER)                     AS reg_hours,
               CAST(ot_hours AS NUMBER)                      AS ot_hours,
               CAST(dt_hours AS NUMBER)                      AS dt_hours,
               CAST(custom_hours AS NUMBER)                  AS custom_hours,
               CAST(total_hours_day AS NUMBER)               AS total_hours_day,
               CAST(total_change_to_hours_day AS NUMBER)     AS total_change_to_hours_day,
               CAST(timecard_state_id AS NUMBER)             AS timecard_state_id,
               CAST(timecard_state AS VARCHAR2(4000))        AS timecard_state,
               CAST(rate_trmt_id AS VARCHAR2(4000))          AS rate_trmt_id,
               CAST(rate_type_desc AS VARCHAR2(7))           AS rate_type,
               CAST(hours_per_day AS NUMBER)                 AS hours_per_day,
               CAST(is_break AS NUMBER(1))                   AS is_break,
               CAST(tc_buyer_approved_date AS DATE)          AS tc_buyer_approved_date,
               CAST(tc_buyer_rejected_date AS DATE)          AS tc_buyer_rejected_date,
               CAST(tc_created_date AS DATE)                 AS tc_created_date,
               CAST(tc_saved_date AS DATE)                   AS tc_saved_date,
               CAST(tc_adjusted_date AS DATE)                AS tc_adjusted_date,
               CAST(tc_rerated_date AS DATE)                 AS tc_rerated_date,
               CAST(tc_approve_req_retract_date AS DATE)     AS tc_approve_req_retract_date,
               CAST(tc_submit_approval_date AS DATE)         AS tc_submit_approval_date,
               CAST(tc_archived_date AS DATE)                AS tc_archived_date,
               CAST(tc_sar_approved_date AS DATE)            AS tc_sar_approved_date,
               CAST(tc_sar_rejected_date AS DATE)            AS tc_sar_rejected_date,
               CAST(cac1_start_date AS DATE)                 AS cac1_start_date,
               CAST(cac1_end_date AS DATE)                   AS cac1_end_date,
               cac1_guid,
               CAST(cac2_start_date AS DATE)                 AS cac2_start_date,
               CAST(cac2_end_date AS DATE)                   AS cac2_end_date,
               cac2_guid,
               CAST(timecard_currency AS VARCHAR2(50))       AS timecard_currency,
               CAST(reg_bill_rate AS NUMBER)                 AS reg_bill_rate,
               CAST(ot_bill_rate AS NUMBER)                  AS ot_bill_rate,
               CAST(dt_bill_rate AS NUMBER)                  AS dt_bill_rate,
               CAST(custom_bill_rate AS NUMBER)              AS custom_bill_rate,
               CAST(adj_reg_bill_rate AS NUMBER)             AS adj_reg_bill_rate,
               CAST(adj_ot_bill_rate AS NUMBER)              AS adj_ot_bill_rate,
               CAST(adj_dt_bill_rate AS NUMBER)              AS adj_dt_bill_rate,
               CAST(adj_custom_bill_rate AS NUMBER)          AS adj_custom_bill_rate,
               CAST(rate_trmt_reg_bill_rate AS NUMBER)       AS rate_trmt_reg_bill_rate,
               CAST(rate_trmt_ot_bill_rate AS NUMBER)        AS rate_trmt_ot_bill_rate,
               CAST(rate_trmt_dt_bill_rate AS NUMBER)        AS rate_trmt_dt_bill_rate,
               CAST(rate_trmt_cust_bill_rate AS NUMBER)      AS rate_trmt_cust_bill_rate,
               CAST(rate_trmt_adj_reg_bill_rate AS NUMBER)   AS rate_trmt_adj_reg_bill_rate,
               CAST(rate_trmt_adj_ot_bill_rate AS NUMBER)    AS rate_trmt_adj_ot_bill_rate,
               CAST(rate_trmt_adj_dt_bill_rate AS NUMBER)    AS rate_trmt_adj_dt_bill_rate,
               CAST(rate_trmt_adj_cust_bill_rate AS NUMBER)  AS rate_trmt_adj_cust_bill_rate,
               CAST(
               CASE
                  WHEN t.rate_trmt_id IS NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.reg_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.reg_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.reg_bill_rate / 160
                              ELSE
                                 t.reg_bill_rate
                              END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.dt_bill_rate / 160
                             ELSE
                                t.dt_bill_rate
                             END )
                           * t.dt_hours)
                            +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.ot_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.ot_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.ot_bill_rate / 160
                              ELSE
                                 t.ot_bill_rate
                              END)
                           * t.ot_hours)
                             +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.custom_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.custom_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.custom_bill_rate / 160
                              ELSE
                                 t.custom_bill_rate
                              END)
                           * t.custom_hours)
                          )
                  WHEN t.rate_trmt_id IS NOT NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.rate_trmt_reg_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.rate_trmt_reg_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.rate_trmt_reg_bill_rate / 160
                              ELSE
                                 t.rate_trmt_reg_bill_rate
                              END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_dt_bill_rate / 160
                             ELSE
                                t.rate_trmt_dt_bill_rate
                             END )
                           * t.dt_hours)
                            +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.rate_trmt_ot_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.rate_trmt_ot_bill_rate / 40 --12.0
                                 WHEN t.rate_type =3 THEN t.rate_trmt_ot_bill_rate / 160
                              ELSE
                                 t.rate_trmt_ot_bill_rate
                              END)
                           * t.ot_hours)
                             +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.rate_trmt_cust_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.rate_trmt_cust_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.rate_trmt_cust_bill_rate / 160
                              ELSE
                                 t.rate_trmt_cust_bill_rate
                              END)
                           * t.custom_hours)
                          )
                  END AS NUMBER ) AS contractor_spend,
               CAST(
               CASE
                  WHEN t.rate_trmt_id IS NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.adj_reg_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.adj_reg_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.adj_reg_bill_rate / 160
                              ELSE
                                 t.adj_reg_bill_rate
                              END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.adj_dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.adj_dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.adj_dt_bill_rate / 160
                             ELSE
                                t.adj_dt_bill_rate
                             END)
                           * t.dt_hours)
                            +
                         (  (CASE
                                 WHEN t.rate_type =1 THEN t.adj_ot_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.adj_ot_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.adj_ot_bill_rate / 160
                             ELSE
                                t.adj_ot_bill_rate
                             END)
                           * t.ot_hours)
                            +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.adj_custom_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.adj_custom_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.adj_custom_bill_rate / 160
                             ELSE
                                t.adj_custom_bill_rate
                             END)
                           * t.custom_hours)
                          )
                  WHEN t.rate_trmt_id IS NOT NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                        (   (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_reg_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_reg_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_reg_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_reg_bill_rate
                             END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_dt_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_dt_bill_rate
                             END )
                           * t.dt_hours)
                            +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_ot_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_ot_bill_rate / 40 --12.0
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_ot_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_ot_bill_rate
                             END)
                           * t.ot_hours)
                             +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_cust_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_cust_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_cust_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_cust_bill_rate
                             END)
                           * t.custom_hours)
                          )  END AS NUMBER ) AS cont_spend_amount_adj,
               CAST(timecard_currency_id AS NUMBER)          AS timecard_currency_id,
               CAST(inv.invoiced_amount AS NUMBER)           AS invoiced_amount
        FROM (
        SELECT timecard_entry_id,
               timecard_id,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               hiring_mgr_person_id,
               candidate_id,
               wk_date,
               week_ending_date,
               timecard_number,
               timecard_type,
               cac1_identifier,
               cac2_identifier,
               job_id,
               assignment_continuity_id,
               assignment_edition_id,
               timecard_approval_workflow_id,
               te_udf_collection_id,
               t_udf_collection_id,
               reg_hours,
               ot_hours,
               dt_hours,
               custom_hours,
               total_hours_day,
               total_change_to_hours_day,
               timecard_state_id,
               timecard_state,
               rate_trmt_id,
               rate_type,
               rate_type_desc,
               hours_per_day,
               is_break,
               tc_buyer_approved_date,
               tc_buyer_rejected_date,
               tc_created_date,
               tc_saved_date,
               tc_adjusted_date,
               tc_rerated_date,
               tc_approve_req_retract_date,
               tc_submit_approval_date,
               tc_archived_date,
               tc_sar_approved_date,
               tc_sar_rejected_date,
               cac1_start_date,
               cac1_end_date,
               cac1_guid,
               cac2_start_date,
               cac2_end_date,
               cac2_guid,
               timecard_currency_id,
               timecard_currency,
               reg_bill_rate,
               ot_bill_rate,
               dt_bill_rate,
               custom_bill_rate,
               adj_reg_bill_rate,
               adj_ot_bill_rate,
               adj_dt_bill_rate,
               adj_custom_bill_rate,
               rate_trmt_reg_bill_rate,
               rate_trmt_ot_bill_rate,
               rate_trmt_dt_bill_rate,
               rate_trmt_cust_bill_rate,
               rate_trmt_adj_reg_bill_rate,
               rate_trmt_adj_ot_bill_rate,
               rate_trmt_adj_dt_bill_rate,
               rate_trmt_adj_cust_bill_rate
          FROM lego_tc_wo_tmp
         UNION ALL
        SELECT timecard_entry_id,
               timecard_id,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               hiring_mgr_person_id,
               candidate_id,
               wk_date,
               week_ending_date,
               timecard_number,
               timecard_type,
               cac1_identifier,
               cac2_identifier,
               job_id,
               assignment_continuity_id,
               assignment_edition_id,
               timecard_approval_workflow_id,
               te_udf_collection_id,
               t_udf_collection_id,
               reg_hours,
               ot_hours,
               dt_hours,
               custom_hours,
               total_hours_day,
               total_change_to_hours_day,
               timecard_state_id,
               timecard_state,
               rate_trmt_id,
               rate_type,
               rate_type_desc,
               hours_per_day,
               is_break,
               tc_buyer_approved_date,
               tc_buyer_rejected_date,
               tc_created_date,
               tc_saved_date,
               tc_adjusted_date,
               tc_rerated_date,
               tc_approve_req_retract_date,
               tc_submit_approval_date,
               tc_archived_date,
               tc_sar_approved_date,
               tc_sar_rejected_date,
               cac1_start_date,
               cac1_end_date,
               cac1_guid,
               cac2_start_date,
               cac2_end_date,
               cac2_guid,
               timecard_currency_id,
               timecard_currency,
               reg_bill_rate,
               ot_bill_rate,
               dt_bill_rate,
               custom_bill_rate,
               adj_reg_bill_rate,
               adj_ot_bill_rate,
               adj_dt_bill_rate,
               adj_custom_bill_rate,
               rate_trmt_reg_bill_rate,
               rate_trmt_ot_bill_rate,
               rate_trmt_dt_bill_rate,
               rate_trmt_cust_bill_rate,
               rate_trmt_adj_reg_bill_rate,
               rate_trmt_adj_ot_bill_rate,
               rate_trmt_adj_dt_bill_rate,
               rate_trmt_adj_cust_bill_rate
          FROM lego_tc_ea_tmp) t,
               lego_invcd_expenditure_sum inv
         WHERE t.timecard_entry_id     = inv.expenditure_id(+)
           AND inv.expenditure_type(+) = 'Time'
         ORDER BY t.buyer_org_id, t.supplier_org_id, t.hiring_mgr_person_id, t.contractor_person_id, t.week_ending_date, t.timecard_entry_id}';
   logger_pkg.info('insert into lego_timecard_future_gtt');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.info('insert into lego_timecard_future_gtt - complete. ' || to_char(SQL%ROWCOUNT) ||
                   ' rows inserted', TRUE);
   COMMIT;
----------------------

   v_sql := 'DELETE
               FROM lego_timecard
              WHERE week_ending_date >= :1';
   logger_pkg.info('delete from lego_timecard');              
   EXECUTE IMMEDIATE v_sql USING v_start_date;
   logger_pkg.info('delete from lego_timecard - complete. ' || to_char(SQL%ROWCOUNT) ||
                   ' rows deleted.', TRUE);              

   v_sql := 'INSERT INTO lego_timecard
               (timecard_entry_id, timecard_id, buyer_org_id, supplier_org_id, contractor_person_id,
                hiring_mgr_person_id, candidate_id, wk_date, week_ending_date, timecard_number,
                timecard_type, cac1_identifier, cac2_identifier, job_id, assignment_continuity_id,
                assignment_edition_id, timecard_approval_workflow_id, te_udf_collection_id,
                t_udf_collection_id, reg_hours, ot_hours, dt_hours, custom_hours, total_hours_day,
                total_change_to_hours_day, timecard_state_id, timecard_state, rate_trmt_id, rate_type_desc,
                hours_per_day, is_break, tc_buyer_approved_date, tc_buyer_rejected_date, tc_created_date,
                tc_saved_date, tc_adjusted_date, tc_rerated_date, tc_approve_req_retract_date,
                tc_submit_approval_date, tc_archived_date, tc_sar_approved_date, tc_sar_rejected_date,
                cac1_start_date, cac1_end_date, cac1_guid, cac2_start_date, cac2_end_date, cac2_guid,
                timecard_currency, reg_bill_rate, ot_bill_rate, dt_bill_rate, custom_bill_rate, adj_reg_bill_rate,
                adj_ot_bill_rate, adj_dt_bill_rate, adj_custom_bill_rate, rate_trmt_reg_bill_rate,
                rate_trmt_ot_bill_rate, rate_trmt_dt_bill_rate, rate_trmt_cust_bill_rate, rate_trmt_adj_reg_bill_rate,
                rate_trmt_adj_ot_bill_rate, rate_trmt_adj_dt_bill_rate, rate_trmt_adj_cust_bill_rate,
                contractor_spend, cont_spend_amount_adj, timecard_currency_id, invoiced_amount)
             (SELECT timecard_entry_id, timecard_id, buyer_org_id, supplier_org_id, contractor_person_id,
                     hiring_mgr_person_id, candidate_id, wk_date, week_ending_date, timecard_number,
                     timecard_type, cac1_identifier, cac2_identifier, job_id, assignment_continuity_id,
                     assignment_edition_id, timecard_approval_workflow_id, te_udf_collection_id,
                     t_udf_collection_id, reg_hours, ot_hours, dt_hours, custom_hours, total_hours_day,
                     total_change_to_hours_day, timecard_state_id, timecard_state, rate_trmt_id, rate_type_desc,
                     hours_per_day, is_break, tc_buyer_approved_date, tc_buyer_rejected_date, tc_created_date,
                     tc_saved_date, tc_adjusted_date, tc_rerated_date, tc_approve_req_retract_date,
                     tc_submit_approval_date, tc_archived_date, tc_sar_approved_date, tc_sar_rejected_date,
                     cac1_start_date, cac1_end_date, cac1_guid, cac2_start_date, cac2_end_date, cac2_guid,
                     timecard_currency, reg_bill_rate, ot_bill_rate, dt_bill_rate, custom_bill_rate, adj_reg_bill_rate,
                     adj_ot_bill_rate, adj_dt_bill_rate, adj_custom_bill_rate, rate_trmt_reg_bill_rate,
                     rate_trmt_ot_bill_rate, rate_trmt_dt_bill_rate, rate_trmt_cust_bill_rate, rate_trmt_adj_reg_bill_rate,
                     rate_trmt_adj_ot_bill_rate, rate_trmt_adj_dt_bill_rate, rate_trmt_adj_cust_bill_rate,
                     contractor_spend, cont_spend_amount_adj, timecard_currency_id, invoiced_amount
                FROM lego_timecard_future_gtt)';
   logger_pkg.info('insert into lego_timecard');
   EXECUTE IMMEDIATE v_sql;
   logger_pkg.info('insert into lego_timecard - complete. ' || to_char(SQL%ROWCOUNT) || 
                   ' rows insertetd.', TRUE);
   COMMIT;
   logger_pkg.info('ending lego_timecard_future for start_date: ' || to_char(v_start_date, 'YYYY-Mon-DD'));
   
EXCEPTION
   WHEN OTHERS THEN
     ROLLBACK;
     logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                      pi_error_code         => SQLCODE,
                      pi_message            => SQLERRM);
     logger_pkg.unset_source('Timcard Lego init/reload');
     RAISE;

END load_lego_timecard_future;

-------------------------

PROCEDURE load_lego_timecard (p_release_sql OUT VARCHAR2)
AS

   /*---------------------------------------------------------------------------*\
   || PROCEDURE NAME       : load_lego_timecard
   || AUTHOR               : Erik Clark
   || DATE CREATED         : April 10, 2013
   || PURPOSE              : This procedure loads data for X many LEGO_TIMECARD partitions, then
   ||                      : creates the p_release_sql for Release manager to swap the partitions.
   || MODIFICATION HISTORY : 04/10/2013 - E.Clark - new "PROCEDURE ONLY RELEASE" program for re-write for TIMECARD overhaul - Release 11.2.1
   ||                      : 05/20/2013 - E.Clark - adding timecard_currency_id for Currency Conversion, Jira # IQN-1008 - Release 11.2.2
   ||                      : 05/22/2013 - E.Clark - address code issue in wo.3 - Release 11.2.2
   ||                      : 05/23/2013 - E.Clark - fix defect with RATE_TRMT_RATES in WO.3 and EA.2 that were using reimb. rates - Release 11.2.2
   ||                      : 05/24/2013 - E.Clark - fix issue with number of partitions to refresh - Release 11.2.2
   ||                      : 08/06/2013 - E.Clark - updated to load invoice information - IQN-6268 - Release 11.3.2
   ||                      : 09/12/2013 - E.Clark - defect on hours - IQN-6268 - Release 11.3.2
   ||                      : 09/24/2013 - E.Clark - turn down Parallel in wo.4 and ea.3 from (2,2) to (12) - HF to 11.3.2
   ||                      : 12/19/2013 - E.Clark - adding conditional indexing for TMP and Partition Exchaging - Release 12.0.0
   ||                      : 01/24/2014 - E.Clark - IQN-12543 - fix for RATE_TYPE_DESC = Hourly, when they are actually Daily. - Release 12.0
   ||                      : 02/04/2014 - E.Clark - IQN-12543 - fix EA rates when current edition does not match ald.from-thru dates - Release 12.0
   ||                      :                      - Add handling to correctly calculate hourly rates when the rate_type_desc = Monthly. Rate / 160. Release 12.0
   ||                      : 04/02/2014 - E.Clark - IQN-14482 - drop old partitions older than the past X months based on LEGO_PARAMETER - Release 12.0.2
   ||                      : 06/13/2014 - J.Pullifrone - IQN-18002 - Instead of capturing INVOICE_ID, capture is_on_invoice instead - Release 12.1.1
   ||                      : 08/18/2014 - pmuller - IQN-19497 - convert all logging to use LOGGER_PKG - 12.2
   ||                      : 08/26/2014 - J.Pullifrone - IQN-18776 - adding invoiced_amount based on actual invoiced_amount from lego_invoice_detail.  Invoiced amount will
   ||                      :                                         be used in expenditure summary lego.  Also removing is_on_invoice.  Release 12.2.0    
   ||                      : 08/24/2015 - pmuller - IQN-28112 - removed code which drops old partitions.  
   \*---------------------------------------------------------------------------*/

   v_sql                   CLOB;
   v_storage               lego_refresh.exadata_storage_clause%type;
   v_num_parts_to_swap     lego_refresh.num_partitions_to_swap%type;
   i                       PLS_INTEGER := 0;
   v_sql_index             VARCHAR2(30000);
   v_release_sql           VARCHAR2(30000);
   ---
   v_start_date            DATE;
   v_end_date              DATE;

   CURSOR load_cur (p_partitions IN NUMBER) IS
      SELECT /*+ PARALLEL (2) */ load_date
        FROM (SELECT DISTINCT TO_CHAR(TRUNC(week_ending_date, 'MM'),'DD-MON-YYYY') load_date
                FROM timecard
               WHERE week_ending_date BETWEEN ADD_MONTHS(TO_DATE('01-'||TO_CHAR(SYSDATE,'MON-YYYY'),'DD-MON-YYYY'),- (p_partitions -1)) AND SYSDATE) 
       ORDER BY TO_DATE(load_date,'DD-MON-YYYY') DESC;

BEGIN

   logger_pkg.set_code_location('LEGO_TIMECARD - creating new tables for part_swap');
   SELECT exadata_storage_clause, num_partitions_to_swap
     INTO v_storage, v_num_parts_to_swap
     FROM lego_refresh
    WHERE object_name = 'LEGO_TIMECARD';

   v_release_sql :=  'LOCK TABLE lego_timecard PARTITION FOR (' ||
                      'TO_DATE(''01-' || TO_CHAR(SYSDATE,'MON-YYYY')
                      || ''',''DD-MON-YYYY'')) IN SHARE MODE; ';

   logger_pkg.info('starting loop to swap ' || to_char(v_num_parts_to_swap) || ' partitions');
   FOR load_rec IN load_cur (v_num_parts_to_swap) LOOP
      i := i + 1;

      v_start_date := TO_DATE(load_rec.load_date,'DD-MON-YYYY');
      v_end_date   := LAST_DAY(TO_DATE(load_rec.load_date,'DD-MON-YYYY')) +.99999;
      
      logger_pkg.info('inside loop - iteration: ' || to_char(i) ||
                      ' start date: ' || to_char(v_start_date, 'YYYY-Mon-DD hh24:mi:ss') ||
                      ' end date: ' || to_char(v_end_date, 'YYYY-Mon-DD hh24:mi:ss'));

      BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE lego_tc_events PURGE';
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_effective_rates PURGE';
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_rates PURGE';
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_rate_trmt_rates PURGE';
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE lego_tc_wo_tmp PURGE';
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE lego_tc_ea_rates PURGE';
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE lego_tc_ea_rate_trmt_rates PURGE';
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE lego_tc_ea_tmp PURGE';
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      v_sql :=
             'CREATE TABLE lego_tc_events ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (8) */
                       ted.timecard_fk AS timecard_id,
                       MAX(CASE WHEN ed.event_name_fk = 22000 THEN ed.timestamp ELSE NULL END) tc_buyer_approved_date,
                       MAX(CASE WHEN ed.event_name_fk = 22001 THEN ed.timestamp ELSE NULL END) tc_buyer_rejected_date,
                       MAX(CASE WHEN ed.event_name_fk = 22003 THEN ed.timestamp ELSE NULL END) tc_created_date,
                       MAX(CASE WHEN ed.event_name_fk = 22004 THEN ed.timestamp ELSE NULL END) tc_saved_date,
                       MAX(CASE WHEN ed.event_name_fk = 22005 THEN ed.timestamp ELSE NULL END) tc_adjusted_date,
                       MAX(CASE WHEN ed.event_name_fk = 22006 THEN ed.timestamp ELSE NULL END) tc_rerated_date,
                       MAX(CASE WHEN ed.event_name_fk = 22007 THEN ed.timestamp ELSE NULL END) tc_approve_req_retract_date,
                       MAX(CASE WHEN ed.event_name_fk = 22008 THEN ed.timestamp ELSE NULL END) tc_submit_approval_date,
                       MAX(CASE WHEN ed.event_name_fk = 22011 THEN ed.timestamp ELSE NULL END) tc_archived_date,
                       MAX(CASE WHEN ed.event_name_fk = 22012 THEN ed.timestamp ELSE NULL END) tc_sar_approved_date,
                       MAX(CASE WHEN ed.event_name_fk = 22013 THEN ed.timestamp ELSE NULL END) tc_sar_rejected_date
                  FROM timecard_event_description AS OF SCN lego_refresh_mgr_pkg.get_scn() ted,
                       event_description          AS OF SCN lego_refresh_mgr_pkg.get_scn() ed,
                       timecard                   AS OF SCN lego_refresh_mgr_pkg.get_scn() t
                 WHERE ted.identifier  = ed.identifier
                   AND ted.timecard_fk = t.timecard_id
                   AND t.week_ending_date BETWEEN TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || ' AND ' || q'{ TO_DATE('}' ||TO_CHAR(v_end_date,'DD-MON-YYYY hh24:mi:ss') || q'{','DD-MON-YYYY  hh24:mi:ss')}' || q'{
                   AND ed.event_name_fk IN (22000, 22001, 22003, 22004, 22005, 22006, 22007, 22008, 22011, 22012, 22013)
                 GROUP BY ted.timecard_fk
                 ORDER BY ted.timecard_fk }';
      logger_pkg.debug('create table lego_tc_events');
      EXECUTE IMMEDIATE v_sql;
      logger_pkg.debug('create table lego_tc_events - complete', TRUE);

      logger_pkg.debug('stats for lego_tc_events');
      DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                     tabname          => 'LEGO_TC_EVENTS',
                                     estimate_percent => 10,
                                     degree           => 6);
      logger_pkg.debug('stats for lego_tc_events - complete', TRUE);

      v_sql :=
             'CREATE TABLE lego_tc_wo_effective_rates ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (2,2) */
                       te1.timecard_entry_id,
                       te1.wk_date,
                       t1.week_ending_date,
                       ac1.assignment_continuity_id,
                       te1.rate_treatment_identifier_fk,
                       ac1.current_edition_fk AS assignment_edition_id,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_effective_date        ELSE NULL END AS effct_rte_effective_date,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_termination_date      ELSE NULL END AS effct_rte_termination_date,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_contract_id           ELSE NULL END AS effct_rte_contract_id,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_create_date           ELSE NULL END AS effct_rte_create_date,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_currency              ELSE NULL END AS effct_rte_currency,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_bill_rate        ELSE NULL END AS effct_rte_supp_bill_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_buyer_bill_rate       ELSE NULL END AS effct_rte_buyer_bill_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_ot_rate          ELSE NULL END AS effct_rte_supp_ot_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_buyer_ot_rate         ELSE NULL END AS effct_rte_buyer_ot_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_dt_rate          ELSE NULL END AS effct_rte_supp_dt_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_buyer_dt_rate         ELSE NULL END AS effct_rte_buyer_dt_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_adj_custom_bill_rate  ELSE NULL END AS effct_rte_adj_custom_bill_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_pay_rate              ELSE NULL END AS effct_rte_pay_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_ot_pay_rate           ELSE NULL END AS effct_rte_ot_pay_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_dt_pay_rate           ELSE NULL END AS effct_rte_dt_pay_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_rate_unit_fk          ELSE NULL END AS effct_rte_rate_unit_fk,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_rate_id_rate_set_fk   ELSE NULL END AS effct_rte_rate_id_rate_set_fk,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_markup                ELSE NULL END AS effct_rte_markup,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_ot_markup             ELSE NULL END AS effct_rte_ot_markup,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_dt_markup             ELSE NULL END AS effct_rte_dt_markup,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_rg_reim_rate     ELSE NULL END AS effct_rte_supp_rg_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_ot_reim_rate     ELSE NULL END AS effct_rte_supp_ot_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_dt_reim_rate     ELSE NULL END AS effct_rte_supp_dt_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_supp_cs_reim_rate     ELSE NULL END AS effct_rte_supp_cs_reim_rate,
                       CASE WHEN te1.wk_date BETWEEN effct_rte_effective_date AND NVL(effct_rte_termination_date, SYSDATE) THEN effct_rte_rate_type_id          ELSE NULL END AS effct_rte_rate_type_id
                  FROM timecard AS OF SCN lego_refresh_mgr_pkg.get_scn() t1,
                       timecard_entry AS OF SCN lego_refresh_mgr_pkg.get_scn() te1,
                       assignment_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn() ac1,
                       ( --get_effective_rate
                         SELECT cv1.effective_date                 AS  effct_rte_effective_date,
                                cv1.termination_date               AS  effct_rte_termination_date,
                                cv1.contract_fk                    AS  effct_rte_contract_id, --assignment_continuity_id
                                cv1.create_date                    AS  effct_rte_create_date,
                                fet_cu1.description                AS  effct_rte_currency,
                                fet1.supplier_bill_rate            AS  effct_rte_supp_bill_rate,
                                fet1.buyer_bill_rate               AS  effct_rte_buyer_bill_rate,
                                fet1.supplier_ot_rate              AS  effct_rte_supp_ot_rate,
                                fet1.buyer_ot_rate                 AS  effct_rte_buyer_ot_rate,
                                fet1.supplier_dt_rate              AS  effct_rte_supp_dt_rate,
                                fet1.buyer_dt_rate                 AS  effct_rte_buyer_dt_rate,
                                fet1.buyer_adj_bill_rate_rt_idntfr AS  effct_rte_adj_custom_bill_rate,
                                fet1.pay_rate                      AS  effct_rte_pay_rate,
                                fet1.ot_pay_rate                   AS  effct_rte_ot_pay_rate,
                                fet1.dt_pay_rate                   AS  effct_rte_dt_pay_rate,
                                fet1.buyer_bill_rate_unit_fk       AS  effct_rte_rate_unit_fk,
                                fet1.rate_identifier_rate_set_fk   AS  effct_rte_rate_id_rate_set_fk,
                                fet1.mark_up                       AS  effct_rte_markup,
                                fet1.ot_mark_up                    AS  effct_rte_ot_markup,
                                fet1.dt_mark_up                    AS  effct_rte_dt_markup,
                                NVL(fet1.supplier_reimbursement_rate,0)    AS  effct_rte_supp_rg_reim_rate,
                                NVL(fet1.supplier_ot_reimbursement_rate,0) AS  effct_rte_supp_ot_reim_rate,
                                NVL(fet1.supplier_dt_reimbursement_rate,0) AS  effct_rte_supp_dt_reim_rate,
                                NVL(fet1.supplier_reimburse_rt_idntfr,0)   AS  effct_rte_supp_cs_reim_rate,
                                fet1.buyer_bill_rate_unit_fk               AS  effct_rte_rate_type_id
                           FROM currency_unit        fet_cu1,
                                fee_expense_term   AS OF SCN lego_refresh_mgr_pkg.get_scn()  fet1,
                                contract_term      AS OF SCN lego_refresh_mgr_pkg.get_scn()  fet_ct1,
                                work_order_version AS OF SCN lego_refresh_mgr_pkg.get_scn()  wov1,
                                contract_version   AS OF SCN lego_refresh_mgr_pkg.get_scn()  cv1
                          WHERE cv1.contract_version_id          = wov1.contract_version_id
                            AND wov1.contract_version_id         = fet_ct1.contract_version_fk
                            AND wov1.work_order_version_state NOT IN (7,8,22,23,21,15,16,24) -- Get rid of Cancels; SFI# 110302-342903 21,15,16,24 are excluded
                            AND fet_ct1.contract_term_id         = fet1.contract_term_id
                            AND fet1.currency_unit_fk            = fet_cu1.value
                            AND fet_ct1.type                     = 'FeeAndExpenseTerm'
                            AND wov1.approval_status in (5,6)    -- Only 'Approved' or 'Approval Not Required'
                          ) effective_rates
                 WHERE t1.week_ending_date BETWEEN TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || ' AND ' || q'{ TO_DATE('}' ||TO_CHAR(v_end_date,'DD-MON-YYYY hh24:mi:ss') || q'{','DD-MON-YYYY  hh24:mi:ss')}' || q'{
                   AND t1.assignment_continuity_fk  = ac1.assignment_continuity_id
                   AND ac1.assignment_continuity_id = effective_rates.effct_rte_contract_id (+)
                   AND t1.timecard_id               = te1.timecard_fk
                   AND ac1.work_order_fk IS NOT NULL
                   AND ABS(NVL(te1.hours,0)) + ABS(NVL(te1.change_to_hours,0)) != 0 }';
      logger_pkg.debug('create table lego_tc_wo_effective_rates');
      EXECUTE IMMEDIATE v_sql;
      logger_pkg.debug('create table lego_tc_wo_effective_rates - complete', TRUE);

      logger_pkg.debug('stats for lego_tc_wo_effective_rates');
      DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                     tabname          => 'LEGO_TC_WO_EFFECTIVE_RATES',
                                     estimate_percent => 10,
                                     degree           => 6);
      logger_pkg.debug('stats for lego_tc_wo_effective_rates - complete', TRUE);

      v_sql :=
             'CREATE TABLE lego_tc_wo_rates ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (2,2) */
                       t1.timecard_entry_id,
                       t1.wk_date,
                       t1.assignment_continuity_id,
                       rates.effective_date,
                       rates.termination_date,
                       rates.contract_id,
                       rates.currency_code,
                       rates.supplier_bill_rate,
                       rates.buyer_bill_rate,
                       rates.supplier_ot_rate,
                       rates.buyer_ot_rate,
                       rates.supplier_dt_rate,
                       rates.buyer_dt_rate,
                       rates.buyer_custom_bill_rate,
                       rates.rate_type_id
                  FROM (SELECT DISTINCT timecard_entry_id, wk_date, assignment_continuity_id
                          FROM lego_tc_wo_effective_rates) t1,
                       ( --get_rate_info
                        SELECT cv.contract_fk                  AS contract_id, --assignment_continuity_id
                               cv.contract_version_name        AS contract_version_name,
                               cv.contract_version_number      AS contract_version_number,
                               cv.effective_date,
                               cv.termination_date             AS termination_date,
                               fet_cu.description              AS currency_code,
                               NVL(fet.supplier_bill_rate, 0)  AS supplier_bill_rate,
                               NVL(fet.buyer_bill_rate, 0)     AS buyer_bill_rate,
                               NVL(fet.supplier_ot_rate, 0)    AS supplier_ot_rate,
                               NVL(fet.buyer_ot_rate, 0)       AS buyer_ot_rate,
                               NVL(fet.supplier_dt_rate, 0)    AS supplier_dt_rate,
                               NVL(fet.buyer_dt_rate, 0)       AS buyer_dt_rate,
                               NVL(fet.buyer_adj_bill_rate_rt_idntfr, 0)   AS buyer_custom_bill_rate,
                               fet.buyer_bill_rate_unit_fk     AS rate_type_id
                          FROM contract_version    AS OF SCN lego_refresh_mgr_pkg.get_scn() cv,
                               work_order_version  AS OF SCN lego_refresh_mgr_pkg.get_scn() wov,
                               fee_expense_term    AS OF SCN lego_refresh_mgr_pkg.get_scn() fet,
                               contract_term       AS OF SCN lego_refresh_mgr_pkg.get_scn() fet_ct,
                               currency_unit        fet_cu
                         WHERE cv.contract_version_id           = wov.contract_version_id
                           AND wov.contract_version_id          = fet_ct.contract_version_fk
                           AND wov.work_order_version_state NOT IN (7, 8, 22, 23)
                           AND fet_ct.contract_term_id          = fet.contract_term_id
                           AND fet.currency_unit_fk             = fet_cu.value
                           AND fet_ct.type                      = 'FeeAndExpenseTerm' ) rates
                 WHERE t1.assignment_continuity_id  = rates.contract_id (+)
                   AND rates.contract_version_name  =
                                NVL
                                   ( (SELECT MAX(TO_NUMBER(cv1.contract_version_name))
                                       FROM contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn() cv1
                                       WHERE cv1.contract_fk = contract_id
                                         AND CASE WHEN t1.wk_date IS NOT NULL THEN t1.wk_date
                                             ELSE TO_DATE ('31-JAN-1950','DD-MON-YYYY')
                                             END BETWEEN DECODE (t1.wk_date, NULL, TO_DATE('31-JAN-1950','DD-MON-YYYY'), cv1.effective_date)
                                                     AND DECODE (t1.wk_date, NULL, TO_DATE('31-JAN-1950','DD-MON-YYYY'), cv1.termination_date)
                                          AND EXISTS
                                          ( SELECT 'FOUND'
                                              FROM work_order_version AS OF SCN lego_refresh_mgr_pkg.get_scn() wov1
                                             WHERE wov1.contract_version_id = cv1.contract_version_id
                                               AND wov1.work_order_version_state NOT IN (7, 8, 22, 23))
                                          ),
                                    (SELECT MAX(TO_NUMBER(cv1.contract_version_name))
                                       FROM contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn() cv1
                                      WHERE cv1.contract_fk = contract_id)
                                   )}';
      logger_pkg.debug('creating table lego_tc_wo_rates');
      EXECUTE IMMEDIATE v_sql;
      logger_pkg.debug('creating table lego_tc_wo_rates - complete',TRUE);

      logger_pkg.debug('stats on lego_tc_wo_rates');
      DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                     tabname          => 'LEGO_TC_WO_RATES',
                                     estimate_percent => 10,
                                     degree           => 6);
      logger_pkg.debug('stats on lego_tc_wo_rates - complete', TRUE);

      v_sql :=
             'CREATE TABLE lego_tc_wo_rate_trmt_rates ' ||
                 v_storage ||
              q'{ AS
                  SELECT /*+ PARALLEL (12) */
                         t1.timecard_entry_id,
                         t1.wk_date,
                         t1.assignment_continuity_id,
                         wo_rate_trmt_rates.effective_date,
                         wo_rate_trmt_rates.termination_date,
                         rate_trmt_reg_bill_rate,
                         rate_trmt_ot_bill_rate,
                         rate_trmt_dt_bill_rate,
                         wo_rate_trmt_rates.rate_trmt_cust_bill_rate,
                         rate_trmt_adj_reg_bill_rate,
                         rate_trmt_adj_ot_bill_rate,
                         rate_trmt_adj_dt_bill_rate,
                         rt_trmt_cust_rates.rate_trmt_adj_cust_bill_rate,
                         rate_trmt_rate_type_id
                      FROM (SELECT DISTINCT
                                   timecard_entry_id,
                                   wk_date,
                                   assignment_continuity_id,
                                   rate_treatment_identifier_fk, assignment_edition_id
                              FROM lego_tc_wo_effective_rates
                             WHERE rate_treatment_identifier_fk IS NOT NULL) t1,
                         ( --get_wo_rate_trmt
                          SELECT ae.assignment_edition_id,
                                 te.timecard_entry_id,
                                 cv.contract_version_number,
                                 cv.effective_date,
                                 cv.termination_date,
                                 rate_trmt_rs1.bill_rate              AS rate_trmt_reg_bill_rate,
                                 rate_trmt_rs1.ot_bill_rate           AS rate_trmt_ot_bill_rate,
                                 rate_trmt_rs1.dt_bill_rate           AS rate_trmt_dt_bill_rate,
                                 cust_rate.rate                       AS rate_trmt_cust_bill_rate,
                                 aart.buyer_adj_bill_rate             AS rate_trmt_adj_reg_bill_rate,
                                 aart.buyer_adj_bill_rate_ot          AS rate_trmt_adj_ot_bill_rate,
                                 aart.buyer_adj_bill_rate_dt          AS rate_trmt_adj_dt_bill_rate,
                                 aart.supplier_reimbursement_rate     AS rate_trmt_reg_reimb_rate,
                                 aart.supplier_reimbursement_rate_ot  AS rate_trmt_ot_reimb_rate,
                                 aart.supplier_reimbursement_rate_dt  AS rate_trmt_dt_reimb_rate,
                                 fet.buyer_bill_rate_unit_fk          AS rate_trmt_rate_type_id
                            FROM contract_term                 fet_ct,
                                 fee_expense_term              fet,
                                 work_order                    wo,
                                 contract                      c,
                                 contract_version              cv,
                                 work_order_version            wov,
                                 rate_card_identifier          rci,
                                 assignment_agreement_rate_trmt aart,
                                 rate_set                      rate_trmt_rs1,
                                 assignment_continuity         ac,
                                 assignment_edition            ae,
                                 timecard_entry                te,
                                 (SELECT *
                                    FROM rate_category_rate
                                   WHERE rate_category_fk = 3)  cust_rate
                           WHERE ac.work_order_fk IS NOT NULL
                             AND ae.assignment_edition_id        = ac.current_edition_fk
                             AND wo.contract_id                  = ac.assignment_continuity_id
                             AND wo.contract_id                  = c.contract_id
                             AND cv.contract_fk                  = c.contract_id
                             AND cv.contract_version_id          = wov.contract_version_id
                             AND cv.contract_version_id          = fet_ct.contract_version_fk
                             AND fet_ct.type                     = 'FeeAndExpenseTerm'
                             AND fet_ct.contract_term_id         = fet.contract_term_id
                             AND fet.contract_term_id            = aart.fee_expense_term_fk(+)
                             AND aart.rate_trmt_identifier_fk    = rci.rate_card_identifier_id(+)
                             AND rate_trmt_rs1.rate_set_id       = aart.treatment_rate_set_fk
                             AND te.rate_treatment_identifier_fk = aart.rate_trmt_identifier_fk
                             AND rate_trmt_rs1.rate_identifier_rate_set_fk = cust_rate.rate_identifier_rate_set_fk(+)
                             )  wo_rate_trmt_rates,
                         (--get rate treatment CUSTOM rates
                          SELECT aart.rate_trmt_identifier_fk,
                                 NVL(MAX(aart.supplier_reimburse_rt_idntfr),0)  AS rate_trmt_cust_bill_rate,
                                 NVL(MAX(aart.buyer_adj_bill_rate_rt_idntfr),0) AS rate_trmt_adj_cust_bill_rate
                            FROM assignment_agreement_rate_trmt aart,
                                 fee_expense_term               fet
                           WHERE fet.contract_term_id = aart.fee_expense_term_fk(+)
                           GROUP BY aart.rate_trmt_identifier_fk) rt_trmt_cust_rates
                   WHERE t1.assignment_edition_id = wo_rate_trmt_rates.assignment_edition_id
                     AND t1.timecard_entry_id     = wo_rate_trmt_rates.timecard_entry_id
                     AND wo_rate_trmt_rates.contract_version_number = (SELECT MAX(cv1.contract_version_number)
                                                                        FROM contract_version   cv1,
                                                                             work_order_version wov1
                                                                       WHERE cv1.contract_fk         = t1.assignment_continuity_id--cv.contract_fk
                                                                         AND cv1.contract_version_id = wov1.contract_version_id
                                                                         AND (cv1.object_version_state <> 4
                                                                              OR cv1.contract_type = 'WO')
                                                                         AND t1.wk_date BETWEEN cv1.effective_date AND NVL(cv1.termination_date, SYSDATE))
                     AND t1.rate_treatment_identifier_fk = rt_trmt_cust_rates.rate_trmt_identifier_fk(+)}';
      logger_pkg.debug('create table lego_tc_wo_rate_trmt_rates');
      EXECUTE IMMEDIATE v_sql;
      logger_pkg.debug('create table lego_tc_wo_rate_trmt_rates - complete', TRUE);

      logger_pkg.debug('stats on lego_tc_wo_rate_trmt_rates');
      DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                     tabname          => 'LEGO_TC_WO_RATE_TRMT_RATES',
                                     estimate_percent => 10,
                                     degree           => 6);
      logger_pkg.debug('stats on lego_tc_wo_rate_trmt_rates - complete', TRUE);

      v_sql :=
             'CREATE TABLE lego_tc_wo_tmp ' ||
                 v_storage ||
              q'{ AS
                SELECT /*+ PARALLEL (10) */
                       point1.timecard_entry_id,
                       point1.timecard_id,
                       point1.buyer_org_id,
                       point1.supplier_org_id,
                       point1.contractor_person_id,
                       point1.hiring_mgr_person_id,
                       point1.candidate_id,
                       point1.wk_date,
                       point1.week_ending_date,
                       point1.timecard_number,
                       point1.timecard_type,
                       point1.cac1_identifier,
                       point1.cac2_identifier,
                       point1.job_id,
                       point1.assignment_continuity_id,
                       point1.work_order_id,
                       point1.assignment_edition_id,
                       point1.timecard_approval_workflow_id,
                       point1.te_udf_collection_id,
                       point1.t_udf_collection_id,
                       SUM(point1.reg_fo_hours)     AS reg_hours,
                       SUM(point1.ot_fo_hours)      AS ot_hours,
                       SUM(point1.dt_fo_hours)      AS dt_hours,
                       SUM(point1.custom_fo_hours)  AS custom_hours,
                       SUM(point1.reg_fo_hours)+
                          SUM(point1.ot_fo_hours)+
                          SUM(point1.dt_fo_hours)+
                          SUM(point1.custom_fo_hours)  AS total_hours_day,
                       point1.change_to_hours       AS total_change_to_hours_day,
                       point1.timecard_state_id,
                       point1.timecard_state,
                       point1.rate_trmt_id,
                       CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id) 
                          WHEN 0 THEN 0 --Hourly
                          WHEN 1 THEN 1 --Daily
                          WHEN 4 THEN 4 --Weekly
                          WHEN 3 THEN 3 --Monthly
                          ELSE NULL
                       END AS rate_type,
                       CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id)
                          WHEN 0 THEN 'Hourly'
                          WHEN 1 THEN 'Daily'
                          WHEN 2 THEN 'Annual'
                          WHEN 3 THEN 'Monthly'
                          WHEN 4 THEN 'Weekly'
                          ELSE 'N/A'
                       END AS rate_type_desc,
                       point1.hours_per_day,
                       point1.is_break,
                       point1.tc_buyer_approved_date,
                       point1.tc_buyer_rejected_date,
                       point1.tc_created_date,
                       point1.tc_saved_date,
                       point1.tc_adjusted_date,
                       point1.tc_rerated_date,
                       point1.tc_approve_req_retract_date,
                       point1.tc_submit_approval_date,
                       point1.tc_archived_date,
                       point1.tc_sar_approved_date,
                       point1.tc_sar_rejected_date,
                       point1.cac1_start_date,
                       point1.cac1_end_date,
                       point1.cac1_guid,
                       point1.cac2_start_date,
                       point1.cac2_end_date,
                       point1.cac2_guid,
                       point1.timecard_currency_id,
                       point1.timecard_currency,
                       ---RATES---
                       --NVL(point1.effct_rte_currency, rates.currency_code)                    AS currency_code,
                       COALESCE(point1.effct_rte_supp_bill_rate, rates.supplier_bill_rate, 0) AS reg_bill_rate,
                       COALESCE(point1.effct_rte_supp_ot_rate, rates.supplier_ot_rate, 0)     AS ot_bill_rate,
                       COALESCE(point1.effct_rte_supp_dt_rate, rates.supplier_dt_rate, 0)     AS dt_bill_rate,
                       NVL(c_rate.custom_bill_rate, 0)                                        AS custom_bill_rate,
                       COALESCE(point1.effct_rte_buyer_bill_rate, rates.buyer_bill_rate, 0)   AS adj_reg_bill_rate,
                       COALESCE(point1.effct_rte_buyer_ot_rate, rates.buyer_ot_rate, 0)       AS adj_ot_bill_rate,
                       COALESCE(point1.effct_rte_buyer_dt_rate, rates.buyer_dt_rate, 0)       AS adj_dt_bill_rate,
                       NVL(rates.buyer_custom_bill_rate, 0)                                   AS adj_custom_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_reg_bill_rate,0)                         AS rate_trmt_reg_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_ot_bill_rate,0)                          AS rate_trmt_ot_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_dt_bill_rate,0)                          AS rate_trmt_dt_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_cust_bill_rate,0)                        AS rate_trmt_cust_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_reg_bill_rate,0)                     AS rate_trmt_adj_reg_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_ot_bill_rate,0)                      AS rate_trmt_adj_ot_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_dt_bill_rate,0)                      AS rate_trmt_adj_dt_bill_rate,
                       NVL(rate_trmt_rates.rate_trmt_adj_cust_bill_rate,0)                    AS rate_trmt_adj_cust_bill_rate
                  FROM (
                  SELECT DISTINCT
                         lt.timecard_entry_id,
                         lt.timecard_id,
                         lt.buyer_org_id,
                         lt.supplier_org_id,
                         lt.contractor_person_id,
                         lt.hiring_mgr_person_id,
                         lt.candidate_id,
                         lt.wk_date,
                         lt.week_ending_date,
                         lt.timecard_number,
                         lt.timecard_type,
                         lt.cac1_identifier,
                         lt.cac2_identifier,
                         lt.job_id,
                         lt.assignment_continuity_id,
                         lt.work_order_id,
                         lt.assignment_edition_id,
                         lt.timecard_approval_workflow_id,
                         lt.te_udf_collection_id,
                         lt.t_udf_collection_id,
                         lt.reg_fo_hours,    --sum above to flatten into 1 row
                         lt.ot_fo_hours,     --sum above to flatten into 1 row
                         lt.dt_fo_hours,     --sum above to flatten into 1 row
                         lt.custom_fo_hours, --sum above to flatten into 1 row
                         lt.hours,
                         lt.change_to_hours,
                         lt.timecard_state_id,
                         lt.timecard_state,
                         lt.rate_trmt_id,
                         lt.hours_per_day,
                         lt.is_break,
                         lt.tc_buyer_approved_date,
                         lt.tc_buyer_rejected_date,
                         lt.tc_created_date,
                         lt.tc_saved_date,
                         lt.tc_adjusted_date,
                         lt.tc_rerated_date,
                         lt.tc_approve_req_retract_date,
                         lt.tc_submit_approval_date,
                         lt.tc_archived_date,
                         lt.tc_sar_approved_date,
                         lt.tc_sar_rejected_date,
                         lt.cac1_start_date,
                         lt.cac1_end_date,
                         lt.cac1_guid,
                         lt.cac2_start_date,
                         lt.cac2_end_date,
                         lt.cac2_guid,
                         lt.timecard_currency_id,
                         lt.timecard_currency,
                         ---EFFECTIVE RATES----
                         wo_effct_rates.effct_rte_effective_date,
                         wo_effct_rates.effct_rte_termination_date,
                         wo_effct_rates.effct_rte_contract_id,
                         wo_effct_rates.effct_rte_create_date,
                         wo_effct_rates.effct_rte_currency,
                         wo_effct_rates.effct_rte_supp_bill_rate,
                         wo_effct_rates.effct_rte_buyer_bill_rate,
                         wo_effct_rates.effct_rte_supp_ot_rate,
                         wo_effct_rates.effct_rte_buyer_ot_rate,
                         wo_effct_rates.effct_rte_supp_dt_rate,
                         wo_effct_rates.effct_rte_buyer_dt_rate,
                         wo_effct_rates.effct_rte_adj_custom_bill_rate,
                         wo_effct_rates.effct_rte_pay_rate,
                         wo_effct_rates.effct_rte_ot_pay_rate,
                         wo_effct_rates.effct_rte_dt_pay_rate,
                         wo_effct_rates.effct_rte_rate_unit_fk,
                         wo_effct_rates.effct_rte_rate_id_rate_set_fk,
                         wo_effct_rates.effct_rte_markup,
                         wo_effct_rates.effct_rte_ot_markup,
                         wo_effct_rates.effct_rte_dt_markup,
                         wo_effct_rates.effct_rte_supp_rg_reim_rate,
                         wo_effct_rates.effct_rte_supp_ot_reim_rate,
                         wo_effct_rates.effct_rte_supp_dt_reim_rate,
                         wo_effct_rates.effct_rte_supp_cs_reim_rate,
                         wo_effct_rates.effct_rte_rate_type_id,
                         RANK() OVER (PARTITION BY lt.timecard_entry_id ORDER BY wo_effct_rates.effct_rte_create_date DESC NULLS LAST ) rates_rk
                   FROM
                       (SELECT
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 1 THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 1 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS reg_fo_hours,
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 2 THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 2 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS ot_fo_hours,
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 3 THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 3 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS dt_fo_hours,
                               CASE
                                  WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk  NOT IN (1,2,3) THEN tx.hours
                                  WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id  NOT IN (1,2,3) AND ri.is_billable = 1 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                  ELSE 0
                               END AS custom_fo_hours,
                               te.timecard_entry_id,
                               t.timecard_id,
                               fr.business_org_fk                 AS buyer_org_id,
                               frs.business_org_fk                AS supplier_org_id,
                               c.person_fk                        AS contractor_person_id,
                               hfw.user_fk                        AS hiring_mgr_person_id,
                               c.candidate_id                     AS candidate_id,
                               te.wk_date                         AS wk_date,
                               t.week_ending_date                 AS week_ending_date,
                               t.timecard_number                  AS timecard_number,
                               t.timecard_type                    AS timecard_type,
                               te.cac1_fk                         AS cac1_identifier,
                               te.cac2_fk                         AS cac2_identifier,
                               ac.job_fk                          AS job_id,
                               ac.assignment_continuity_id        AS assignment_continuity_id,
                               ac.work_order_fk                   AS work_order_id,
                               ac.currency_unit_fk                AS timecard_currency_id,
                               cu.description                     AS timecard_currency,
                               ae.assignment_edition_id           AS assignment_edition_id,
                               ae.timecard_approval_workflow_fk   AS timecard_approval_workflow_id,
                               te.udf_collection_fk               AS te_udf_collection_id,
                               t.udf_collection_fk                AS t_udf_collection_id,
                               NVL(te.hours,0)                    AS hours,
                               NVL(te.change_to_hours,0)          AS change_to_hours,
                               t.state_code                       AS timecard_state_id,
                               NVL(timecard_state.constant_description, 'Unknown')  AS timecard_state,
                               rci.description                    AS rate_trmt_id,
                               --NVL(rate_type.rate_type_id,0)      AS rate_type,
                               NVL(hpd.hours_per_day,8)           AS hours_per_day,
                               te.is_break,
                               event_dates.tc_buyer_approved_date,
                               event_dates.tc_buyer_rejected_date,
                               event_dates.tc_created_date,
                               event_dates.tc_saved_date,
                               event_dates.tc_adjusted_date,
                               event_dates.tc_rerated_date,
                               event_dates.tc_approve_req_retract_date,
                               event_dates.tc_submit_approval_date,
                               event_dates.tc_archived_date,
                               event_dates.tc_sar_approved_date,
                               event_dates.tc_sar_rejected_date,
                               cac1.start_date AS cac1_start_date,
                               cac1.end_date   AS cac1_end_date,
                               cac1.cac_guid   AS cac1_guid,
                               cac2.start_date AS cac2_start_date,
                               cac2.end_date   AS cac2_end_date,
                               cac2.cac_guid   AS cac2_guid
                          FROM timecard        AS OF SCN lego_refresh_mgr_pkg.get_scn() t,
                               timecard_entry  AS OF SCN lego_refresh_mgr_pkg.get_scn() te,
                               (SELECT time_expenditure_id,
                                       rate_identifier_fk,
                                       hours,
                                       timecard_entry_fk
                                  FROM time_expenditure AS OF SCN lego_refresh_mgr_pkg.get_scn()
                                 WHERE is_current = 1) tx,
                               assignment_continuity  AS OF SCN lego_refresh_mgr_pkg.get_scn() ac,
                               assignment_edition     AS OF SCN lego_refresh_mgr_pkg.get_scn() ae,
                               firm_role              AS OF SCN lego_refresh_mgr_pkg.get_scn() fr,
                               firm_role              AS OF SCN lego_refresh_mgr_pkg.get_scn() frs,
                               candidate              AS OF SCN lego_refresh_mgr_pkg.get_scn() c,
                               firm_worker            AS OF SCN lego_refresh_mgr_pkg.get_scn() hfw,
                               rate_identifier        AS OF SCN lego_refresh_mgr_pkg.get_scn() ri,
                               currency_unit          cu,
                               (SELECT constant_value, constant_description
                                  FROM java_constant_lookup
                                 WHERE constant_type    = 'TIMECARD_STATE'
                                   AND UPPER(locale_fk) = 'EN_US') timecard_state,
                               (SELECT lcc.cac_id,
                                       lcc.start_date,
                                       lcc.end_date,
                                       lcc.cac_guid
                                  FROM lego_cac_collection lcc ) cac1,
                               (SELECT lcc.cac_id,
                                       lcc.start_date,
                                       lcc.end_date,
                                       lcc.cac_guid
                                  FROM lego_cac_collection lcc ) cac2,
                               lego_tc_events event_dates,
                               (SELECT pwe.procurement_wkfl_edition_id, wpd.hours_per_day
                                  FROM work_period_definition   AS OF SCN lego_refresh_mgr_pkg.get_scn() wpd,
                                       procurement_wkfl_edition AS OF SCN lego_refresh_mgr_pkg.get_scn() pwe
                                 WHERE pwe.work_period_definition_fk = wpd.work_period_definition_id)  hpd,
                              -- (SELECT timecard_template_edition_id, rate_type
                              --    FROM timecard_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn()) rate_type,
                               (SELECT rate_card_identifier_id, description
                                  FROM rate_card_identifier AS OF SCN lego_refresh_mgr_pkg.get_scn()) rci
                         WHERE t.week_ending_date BETWEEN TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || ' AND ' || q'{ TO_DATE('}' ||TO_CHAR(v_end_date,'DD-MON-YYYY hh24:mi:ss') || q'{','DD-MON-YYYY hh24:mi:ss')}' || q'{
                           AND t.assignment_continuity_fk      = ac.assignment_continuity_id
                           AND ac.assignment_continuity_id     = ae.assignment_continuity_fk
                           AND ac.current_edition_fk           = ae.assignment_edition_id
                           AND ac.work_order_fk IS NOT NULL
                           AND ac.candidate_fk                 = c.candidate_id(+)
                           AND ac.currency_unit_fk             = cu.value
                           AND ae.hiring_mgr_fk                = hfw.firm_worker_id(+)
                           AND t.timecard_id                   = te.timecard_fk
                           AND t.procurement_wkfl_edition_fk   = hpd.procurement_wkfl_edition_id (+)
                           --AND t.timecard_template_edition_fk  = rate_type.timecard_template_edition_id (+)
                           AND te.timecard_entry_id            = tx.timecard_entry_fk (+)
                           AND te.rate_identifier_fk           = ri.rate_identifier_id
                           AND te.rate_treatment_identifier_fk = rci.rate_card_identifier_id (+)
                           AND ac.owning_buyer_firm_fk         = fr.firm_id
                           AND ac.owning_supply_firm_fk        = frs.firm_id
                           AND t.state_code                    = timecard_state.constant_value(+)
                           AND te.cac1_fk                      = cac1.cac_id(+)
                           AND te.cac2_fk                      = cac2.cac_id(+)
                           AND t.state_code != 7
                           AND ABS(NVL(te.hours,0)) + ABS(NVL(te.change_to_hours,0)) != 0
                           AND CASE WHEN te.change_to_hours <= 0 THEN 1
                               ELSE NVL (te.change_to_hours, 0) END
                               >
                               CASE WHEN timecard_type = 'Timecard Adjustment' THEN 0
                               ELSE -1 END
                           AND t.timecard_id                   = event_dates.timecard_id(+) ) lt,
                       lego_tc_wo_effective_rates wo_effct_rates
                  WHERE lt.timecard_entry_id = wo_effct_rates.timecard_entry_id
                    AND lt.week_ending_date BETWEEN TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || ' AND ' || q'{ TO_DATE('}' ||TO_CHAR(v_end_date,'DD-MON-YYYY hh24:mi:ss') || q'{','DD-MON-YYYY hh24:mi:ss')}' || q'{
                    AND lt.wk_date BETWEEN NVL(wo_effct_rates.effct_rte_effective_date,TO_DATE('25-OCT-1971','DD-MON-YYYY')) AND NVL(wo_effct_rates.effct_rte_termination_date, SYSDATE)
                       ) point1,
                       lego_tc_wo_rates rates, --use when effective rates are null
                  (SELECT rate_identifier_rate_set_fk, rate AS custom_bill_rate
                     FROM rate_category_rate
                    WHERE rate_category_fk = 3) c_rate, --used to get wo custom supplier bill rate
                  lego_tc_wo_rate_trmt_rates rate_trmt_rates
                WHERE point1.rates_rk                       = 1
                  AND point1.timecard_entry_id              = rates.timecard_entry_id (+)
                  AND point1.effct_rte_rate_id_rate_set_fk  = c_rate.rate_identifier_rate_set_fk (+)
                  AND point1.timecard_entry_id              = rate_trmt_rates.timecard_entry_id (+)
                  GROUP BY
                         point1.timecard_entry_id,
                         point1.timecard_id,
                         point1.buyer_org_id,
                         point1.supplier_org_id,
                         point1.contractor_person_id,
                         point1.hiring_mgr_person_id,
                         point1.candidate_id,
                         point1.wk_date,
                         point1.week_ending_date,
                         point1.timecard_number,
                         point1.timecard_type,
                         point1.cac1_identifier,
                         point1.cac2_identifier,
                         point1.job_id,
                         point1.assignment_continuity_id,
                         point1.work_order_id,
                         point1.assignment_edition_id,
                         point1.timecard_approval_workflow_id,
                         point1.te_udf_collection_id,
                         point1.t_udf_collection_id,
                         point1.hours,
                         point1.change_to_hours,
                         point1.timecard_state_id,
                         point1.timecard_state,
                         point1.rate_trmt_id,
                         CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id) 
                            WHEN 0 THEN 0 --Hourly
                            WHEN 1 THEN 1 --Daily
                            WHEN 4 THEN 4 --Weekly
                            WHEN 3 THEN 3 --Monthly
                            ELSE NULL
                         END,
                         CASE COALESCE(point1.effct_rte_rate_type_id, rates.rate_type_id, rate_trmt_rates.rate_trmt_rate_type_id)
                            WHEN 0 THEN 'Hourly'
                            WHEN 1 THEN 'Daily'
                            WHEN 2 THEN 'Annual'
                            WHEN 3 THEN 'Monthly'
                            WHEN 4 THEN 'Weekly'
                            ELSE 'N/A'
                         END,
                         point1.hours_per_day,
                         point1.is_break,
                         point1.tc_buyer_approved_date,
                         point1.tc_buyer_rejected_date,
                         point1.tc_created_date,
                         point1.tc_saved_date,
                         point1.tc_adjusted_date,
                         point1.tc_rerated_date,
                         point1.tc_approve_req_retract_date,
                         point1.tc_submit_approval_date,
                         point1.tc_archived_date,
                         point1.tc_sar_approved_date,
                         point1.tc_sar_rejected_date,
                         point1.cac1_start_date,
                         point1.cac1_end_date,
                         point1.cac1_guid,
                         point1.cac2_start_date,
                         point1.cac2_end_date,
                         point1.cac2_guid,
                         point1.timecard_currency_id,
                         point1.timecard_currency,
                         --NVL(point1.effct_rte_currency, rates.currency_code),
                         COALESCE(point1.effct_rte_supp_bill_rate, rates.supplier_bill_rate, 0),
                         COALESCE(point1.effct_rte_supp_ot_rate, rates.supplier_ot_rate, 0),
                         COALESCE(point1.effct_rte_supp_dt_rate, rates.supplier_dt_rate, 0),
                         NVL(c_rate.custom_bill_rate, 0),
                         COALESCE(point1.effct_rte_buyer_bill_rate, rates.buyer_bill_rate, 0),
                         COALESCE(point1.effct_rte_buyer_ot_rate, rates.buyer_ot_rate, 0),
                         COALESCE(point1.effct_rte_buyer_dt_rate, rates.buyer_dt_rate, 0),
                         NVL(rates.buyer_custom_bill_rate, 0),
                         point1.effct_rte_rate_id_rate_set_fk,
                         NVL(rate_trmt_rates.rate_trmt_reg_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_ot_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_dt_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_cust_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_reg_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_ot_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_dt_bill_rate,0),
                         NVL(rate_trmt_rates.rate_trmt_adj_cust_bill_rate,0)}';
      logger_pkg.debug('create table lego_tc_wo_tmp');
      EXECUTE IMMEDIATE v_sql;
      logger_pkg.debug('create table lego_tc_wo_tmp -complete',TRUE);

      --Start EA!
      v_sql :=
             'CREATE TABLE lego_tc_ea_rates ' ||
                 v_storage ||
              q'{ AS
                  SELECT /*+ PARALLEL (2,2) */
                         timecard_entry_id,
                         timecard_id,
                         wk_date,
                         week_ending_date,
                         assignment_continuity_id,
                         rate_treatment_identifier_fk,
                         assignment_edition_id,
                         rates_effective_date,
                         rates_termination_date,
                         currency_code,
                         NVL(supplier_bill_rate,0)        AS supplier_bill_rate,
                         NVL(buyer_bill_rate,0)           AS buyer_bill_rate,
                         NVL(supplier_ot_rate,0)          AS supplier_ot_rate,
                         NVL(buyer_ot_rate,0)             AS buyer_ot_rate,
                         NVL(supplier_dt_rate,0)          AS supplier_dt_rate,
                         NVL(buyer_dt_rate,0)             AS buyer_dt_rate,
                         NVL(custom_rate.rate,0)          AS custom_bill_rate,
                         NVL(adjusted_custom_bill_rate,0) AS adjusted_custom_bill_rate,
                         rates.rate_identifier_rate_set_fk,
                         rate_type_id
                    FROM (SELECT timecard_entry_id,
                                 timecard_id,
                                 wk_date,
                                 week_ending_date,
                                 assignment_continuity_id,
                                 rate_treatment_identifier_fk,
                                 assignment_edition_id,
                                 rates_effective_date,
                                 rates_termination_date,
                                 currency_code,
                                 supplier_bill_rate,
                                 buyer_bill_rate,
                                 supplier_ot_rate,
                                 buyer_ot_rate,
                                 supplier_dt_rate,
                                 buyer_dt_rate,
                                 adjusted_custom_bill_rate,
                                 rate_identifier_rate_set_fk,
                                 rate_type_id,
                                 RANK () OVER (PARTITION BY timecard_entry_id ORDER BY rates_effective_date DESC NULLS LAST, rownum DESC) rk
                            FROM (SELECT te1.timecard_entry_id,
                                         t1.timecard_id,
                                         te1.wk_date,
                                         t1.week_ending_date,
                                         ac1.assignment_continuity_id,
                                         te1.rate_treatment_identifier_fk,
                                         ac1.current_edition_fk AS assignment_edition_id,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN effective_date        ELSE NULL END AS rates_effective_date,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN termination_date      ELSE NULL END AS rates_termination_date,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN currency_code         ELSE NULL END AS currency_code,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN supplier_bill_rate    ELSE NULL END AS supplier_bill_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN buyer_bill_rate       ELSE NULL END AS buyer_bill_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN supplier_ot_rate      ELSE NULL END AS supplier_ot_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN buyer_ot_rate         ELSE NULL END AS buyer_ot_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN supplier_dt_rate      ELSE NULL END AS supplier_dt_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN buyer_dt_rate         ELSE NULL END AS buyer_dt_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN adjusted_custom_bill_rate  ELSE NULL END AS adjusted_custom_bill_rate,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN rate_identifier_rate_set_fk   ELSE NULL END AS rate_identifier_rate_set_fk,
                                         CASE WHEN te1.wk_date BETWEEN get_rates.effective_date AND get_rates.termination_date THEN rate_type_id                  ELSE NULL END AS rate_type_id                                         
                                    FROM timecard  AS OF SCN lego_refresh_mgr_pkg.get_scn() t1,
                                         timecard_entry  AS OF SCN lego_refresh_mgr_pkg.get_scn() te1,
                                         assignment_continuity  AS OF SCN lego_refresh_mgr_pkg.get_scn() ac1,
                                         assignment_edition     AS OF SCN lego_refresh_mgr_pkg.get_scn() ae1,
                                         ( --get_rates
                                          SELECT ald.valid_from                  AS effective_date,
                                                 ald.valid_to                    AS termination_date,
                                                 ald.assignment_edition_fk       AS assignment_edition_id,
                                                 rs_cu.description               AS currency_code,
                                                 rs.bill_rate                    AS supplier_bill_rate,
                                                 ald.buyer_adj_bill_rate         AS buyer_bill_rate,
                                                 rs.ot_bill_rate                 AS supplier_ot_rate,
                                                 ald.buyer_adj_bill_rate_ot      AS buyer_ot_rate,
                                                 rs.dt_bill_rate                 AS supplier_dt_rate,
                                                 ald.buyer_adj_bill_rate_dt      AS buyer_dt_rate,
                                                 ili_buyer_fee_adj.amount        AS adjusted_custom_bill_rate,
                                                 rs.rate_identifier_rate_set_fk  AS rate_identifier_rate_set_fk,
                                                 ald.rate_unit_fk                AS rate_type_id
                                            FROM assignment_line_detail   AS OF SCN lego_refresh_mgr_pkg.get_scn() ald,
                                                 rate_set                 AS OF SCN lego_refresh_mgr_pkg.get_scn() rs,
                                                 currency_unit            rs_cu,
                                                 invoice_line_item        AS OF SCN lego_refresh_mgr_pkg.get_scn() ili_buyer_fee_adj
                                           WHERE ald.rate_set_fk                   = rs.rate_set_id
                                             AND ald.buyer_adj_bill_rate_rt_idntfr = ili_buyer_fee_adj.identifier(+)
                                             AND rs.currency_unit_fk               = rs_cu.value
                                         ) get_rates
                                   WHERE t1.week_ending_date BETWEEN TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || ' AND ' || q'{ TO_DATE('}' ||TO_CHAR(v_end_date,'DD-MON-YYYY hh24:mi:ss') || q'{','DD-MON-YYYY hh24:mi:ss')}' || q'{
                                     AND t1.assignment_continuity_fk  = ac1.assignment_continuity_id
                                     AND ac1.assignment_continuity_id = ae1.assignment_continuity_fk
                                     AND ae1.assignment_edition_id    = get_rates.assignment_edition_id(+)
                                     AND ac1.work_order_fk IS NULL --EA and TA only
                                     AND t1.timecard_id               = te1.timecard_fk
                                     AND ABS(NVL(te1.hours,0)) + ABS(NVL(te1.change_to_hours,0)) != 0)) rates,
                          --get_custom_rate
                         (SELECT rate_identifier_rate_set_fk, rate
                            FROM rate_category_rate AS OF SCN lego_refresh_mgr_pkg.get_scn()
                           WHERE rate_category_fk = 3) custom_rate
                   WHERE rates.rate_identifier_rate_set_fk = custom_rate.rate_identifier_rate_set_fk(+)
                     AND rates.rk = 1}';
      logger_pkg.debug('create table lego_tc_ea_rates');
      EXECUTE IMMEDIATE v_sql;
      logger_pkg.debug('create table lego_tc_ea_rates - complete', TRUE);
      
      logger_pkg.debug('stats on lego_tc_ea_rates');
      DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                     tabname          => 'LEGO_TC_EA_RATES',
                                     estimate_percent => 10,
                                     degree           => 6);
      logger_pkg.debug('stats on lego_tc_ea_rates - complete', TRUE);

      v_sql :=
             'CREATE TABLE lego_tc_ea_rate_trmt_rates ' ||
                 v_storage ||
              q'{ AS
              SELECT /*+ PARALLEL (2,2) */
                     l.timecard_entry_id,
                     l.wk_date,
                     l.assignment_continuity_id,
                     ald.valid_from  AS effective_date,
                     ald.valid_to    AS termination_date,
                     NVL(rate_trmt_rs1.bill_rate,0)                      AS rate_trmt_reg_bill_rate,
                     NVL(rate_trmt_rs1.ot_bill_rate,0)                   AS rate_trmt_ot_bill_rate,
                     NVL(rate_trmt_rs1.dt_bill_rate,0)                   AS rate_trmt_dt_bill_rate,
                     NVL(cust_rate.rate,0)                               AS rate_trmt_cust_bill_rate,
                     NVL(aart.buyer_adj_bill_rate,0)                     AS rate_trmt_adj_reg_bill_rate,
                     NVL(aart.buyer_adj_bill_rate_ot,0)                  AS rate_trmt_adj_ot_bill_rate,
                     NVL(aart.buyer_adj_bill_rate_dt,0)                  AS rate_trmt_adj_dt_bill_rate,
                     NVL(aart.buyer_adj_bill_rate_rt_idntfr,0)           AS rate_trmt_adj_cust_bill_rate,
                     ald.rate_unit_fk                                    AS rate_trmt_rate_type_id
                FROM lego_tc_ea_rates l,
                     assignment_line_detail AS OF SCN lego_refresh_mgr_pkg.get_scn() ald,
                     assignment_agreement_rate_trmt AS OF SCN lego_refresh_mgr_pkg.get_scn() aart,
                     rate_set AS OF SCN lego_refresh_mgr_pkg.get_scn() rate_trmt_rs1,
                     (SELECT *
                        FROM rate_category_rate AS OF SCN lego_refresh_mgr_pkg.get_scn()
                       WHERE rate_category_fk = 3)  cust_rate
               WHERE l.rate_treatment_identifier_fk IS NOT NULL
                 AND ald.assignment_edition_fk        = l.assignment_edition_id
                 AND l.wk_date BETWEEN ald.valid_from AND ald.valid_to
                 AND aart.assignment_line_detail_fk   = ald.assignment_line_detail_id
                 AND aart.rate_trmt_identifier_fk     = l.rate_treatment_identifier_fk
                 AND aart.treatment_rate_set_fk       = rate_trmt_rs1.rate_set_id
                 AND rate_trmt_rs1.rate_identifier_rate_set_fk = cust_rate.rate_identifier_rate_set_fk(+)}';
      logger_pkg.debug('create table lego_tc_ea_rate_trmt_rates');
      EXECUTE IMMEDIATE v_sql;
      logger_pkg.debug('create table lego_tc_ea_rate_trmt_rates - complete', TRUE);

      logger_pkg.debug('stats on lego_tc_ea_rate_trmt_rates');
      DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                     tabname          => 'LEGO_TC_EA_RATE_TRMT_RATES',
                                     estimate_percent => 10,
                                     degree           => 6);
      logger_pkg.debug('stats on lego_tc_ea_rate_trmt_rates - complete', TRUE);

      v_sql :=
             'CREATE TABLE lego_tc_ea_tmp ' ||
                 v_storage ||
              q'{ AS
                  SELECT /*+ PARALLEL (12) */
                         point1.timecard_entry_id,
                         point1.timecard_id,
                         point1.buyer_org_id,
                         point1.supplier_org_id,
                         point1.contractor_person_id,
                         point1.hiring_mgr_person_id,
                         point1.candidate_id,
                         point1.wk_date,
                         point1.week_ending_date,
                         point1.timecard_number,
                         point1.timecard_type,
                         point1.cac1_identifier,
                         point1.cac2_identifier,
                         point1.job_id,
                         point1.assignment_continuity_id,
                         point1.work_order_id,
                         point1.assignment_edition_id,
                         point1.timecard_approval_workflow_id,
                         point1.te_udf_collection_id,
                         point1.t_udf_collection_id,
                         SUM(point1.reg_fo_hours)     AS reg_hours,
                         SUM(point1.ot_fo_hours)      AS ot_hours,
                         SUM(point1.dt_fo_hours)      AS dt_hours,
                         SUM(point1.custom_fo_hours)  AS custom_hours,
                         SUM(point1.reg_fo_hours)+
                            SUM(point1.ot_fo_hours)+
                            SUM(point1.dt_fo_hours)+
                            SUM(point1.custom_fo_hours)  AS total_hours_day,
                         point1.change_to_hours       AS total_change_to_hours_day,
                         point1.timecard_state_id,
                         point1.timecard_state,
                         point1.rate_trmt_id,
                         CASE point1.rate_type_id 
                            WHEN 0 THEN 0 --Hourly
                            WHEN 1 THEN 1 --Daily
                            WHEN 4 THEN 4 --Weekly
                            WHEN 3 THEN 3 --Monthly
                            ELSE NULL
                         END AS rate_type,
                         CASE point1.rate_type_id
                            WHEN 0 THEN 'Hourly'
                            WHEN 1 THEN 'Daily'
                            WHEN 2 THEN 'Annual'
                            WHEN 3 THEN 'Monthly'
                            WHEN 4 THEN 'Weekly'
                            ELSE 'N/A'
                         END AS rate_type_desc,
                         point1.hours_per_day,
                         point1.is_break,
                         point1.tc_buyer_approved_date,
                         point1.tc_buyer_rejected_date,
                         point1.tc_created_date,
                         point1.tc_saved_date,
                         point1.tc_adjusted_date,
                         point1.tc_rerated_date,
                         point1.tc_approve_req_retract_date,
                         point1.tc_submit_approval_date,
                         point1.tc_archived_date,
                         point1.tc_sar_approved_date,
                         point1.tc_sar_rejected_date,
                         point1.cac1_start_date,
                         point1.cac1_end_date,
                         point1.cac1_guid,
                         point1.cac2_start_date,
                         point1.cac2_end_date,
                         point1.cac2_guid,
                         point1.timecard_currency_id,
                         point1.timecard_currency,
                         --RATES--
                         --currency_code,
                         reg_bill_rate,
                         ot_bill_rate,
                         dt_bill_rate,
                         custom_bill_rate,
                         adj_reg_bill_rate,
                         adj_ot_bill_rate,
                         adj_dt_bill_rate,
                         adj_custom_bill_rate,
                         rate_trmt_reg_bill_rate,
                         rate_trmt_ot_bill_rate,
                         rate_trmt_dt_bill_rate,
                         rate_trmt_cust_bill_rate,
                         rate_trmt_adj_reg_bill_rate,
                         rate_trmt_adj_ot_bill_rate,
                         rate_trmt_adj_dt_bill_rate,
                         rate_trmt_adj_cust_bill_rate
                    FROM (SELECT lt.timecard_entry_id,
                                 lt.timecard_id,
                                 lt.buyer_org_id,
                                 lt.supplier_org_id,
                                 lt.contractor_person_id,
                                 lt.hiring_mgr_person_id,
                                 lt.candidate_id,
                                 lt.wk_date,
                                 lt.week_ending_date,
                                 lt.timecard_number,
                                 lt.timecard_type,
                                 lt.cac1_identifier,
                                 lt.cac2_identifier,
                                 lt.job_id,
                                 lt.assignment_continuity_id,
                                 lt.work_order_id,
                                 lt.assignment_edition_id,
                                 lt.timecard_approval_workflow_id,
                                 lt.te_udf_collection_id,
                                 lt.t_udf_collection_id,
                                 lt.reg_fo_hours,    --sum above to flatten into 1 row
                                 lt.ot_fo_hours,     --sum above to flatten into 1 row
                                 lt.dt_fo_hours,     --sum above to flatten into 1 row
                                 lt.custom_fo_hours, --sum above to flatten into 1 row
                                 lt.hours,
                                 lt.change_to_hours,
                                 lt.timecard_state_id,
                                 lt.timecard_state,
                                 lt.rate_trmt_id,
                                 lt.hours_per_day,
                                 lt.is_break,
                                 lt.tc_buyer_approved_date,
                                 lt.tc_buyer_rejected_date,
                                 lt.tc_created_date,
                                 lt.tc_saved_date,
                                 lt.tc_adjusted_date,
                                 lt.tc_rerated_date,
                                 lt.tc_approve_req_retract_date,
                                 lt.tc_submit_approval_date,
                                 lt.tc_archived_date,
                                 lt.tc_sar_approved_date,
                                 lt.tc_sar_rejected_date,
                                 lt.cac1_start_date,
                                 lt.cac1_end_date,
                                 lt.cac1_guid,
                                 lt.cac2_start_date,
                                 lt.cac2_end_date,
                                 lt.cac2_guid,
                                 lt.timecard_currency_id,
                                 lt.timecard_currency,
                                 ---RATES----
                                 --ea_rates.currency_code,
                                 ea_rates.supplier_bill_rate   AS reg_bill_rate,
                                 ea_rates.supplier_ot_rate     AS ot_bill_rate,
                                 ea_rates.supplier_dt_rate     AS dt_bill_rate,
                                 ea_rates.custom_bill_rate     AS custom_bill_rate,
                                 ea_rates.buyer_bill_rate      AS adj_reg_bill_rate,
                                 ea_rates.buyer_ot_rate        AS adj_ot_bill_rate,
                                 ea_rates.buyer_dt_rate        AS adj_dt_bill_rate,
                                 ea_rates.adjusted_custom_bill_rate AS adj_custom_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_reg_bill_rate,0)      AS rate_trmt_reg_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_ot_bill_rate,0)       AS rate_trmt_ot_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_dt_bill_rate,0)       AS rate_trmt_dt_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_cust_bill_rate,0)     AS rate_trmt_cust_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_reg_bill_rate,0)  AS rate_trmt_adj_reg_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_ot_bill_rate,0)   AS rate_trmt_adj_ot_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_dt_bill_rate,0)   AS rate_trmt_adj_dt_bill_rate,
                                 NVL(trmt_ea_rates.rate_trmt_adj_cust_bill_rate,0) AS rate_trmt_adj_cust_bill_rate,
                                 NVL(ea_rates.rate_type_id, trmt_ea_rates.rate_trmt_rate_type_id) AS rate_type_id
                            FROM
                                (SELECT
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 1 THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 1 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS reg_fo_hours,
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 2 THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 2 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS OT_fo_hours,
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk = 3 THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id = 3 AND te.is_break=0 THEN NVL(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS DT_fo_hours,
                                       CASE
                                          WHEN tx.time_expenditure_id IS NOT NULL AND tx.rate_identifier_fk NOT IN (1,2,3) THEN tx.hours
                                          WHEN tx.time_expenditure_id IS     NULL AND ri.rate_identifier_id  NOT IN (1,2,3) AND ri.is_billable = 1 AND te.is_break=0 THEN nvl(te.change_to_hours, te.hours)
                                          ELSE 0
                                       END AS CUSTOM_fo_hours,
                                       te.timecard_entry_id,
                                       t.timecard_id,
                                       fr.business_org_fk    AS buyer_org_id,
                                       frs.business_org_fk   AS supplier_org_id,
                                       c.person_fk           AS contractor_person_id,
                                       hfw.user_fk           AS hiring_mgr_person_id,
                                       c.candidate_id        AS candidate_id,
                                       te.wk_date            AS wk_date,
                                       t.week_ending_date    AS week_ending_date,
                                       t.timecard_number     AS timecard_number,
                                       t.timecard_type       AS timecard_type,
                                       te.cac1_fk            AS cac1_identifier,
                                       te.cac2_fk            AS cac2_identifier,
                                       ac.job_fk             AS job_id,
                                       ac.currency_unit_fk   AS timecard_currency_id,
                                       cu.description        AS timecard_currency,
                                       ac.assignment_continuity_id        AS assignment_continuity_id,
                                       ac.work_order_fk                   AS work_order_id,
                                       ae.assignment_edition_id           AS assignment_edition_id,
                                       ae.timecard_approval_workflow_fk   AS timecard_approval_workflow_id,
                                       te.udf_collection_fk               AS te_udf_collection_id,
                                       t.udf_collection_fk                AS t_udf_collection_id,
                                       NVL(te.hours,0)                    AS hours,
                                       NVL(te.change_to_hours,0)          AS change_to_hours,
                                       t.state_code                       AS timecard_state_id,
                                       NVL(timecard_state.constant_description, 'Unknown')  AS timecard_state,
                                       rci.description                    AS rate_trmt_id,
                                       --NVL(rate_type.rate_type,0)         AS rate_type,
                                       NVL(hpd.hours_per_day,8)           AS hours_per_day,
                                       te.is_break,
                                       event_dates.tc_buyer_approved_date,
                                       event_dates.tc_buyer_rejected_date,
                                       event_dates.tc_created_date,
                                       event_dates.tc_saved_date,
                                       event_dates.tc_adjusted_date,
                                       event_dates.tc_rerated_date,
                                       event_dates.tc_approve_req_retract_date,
                                       event_dates.tc_submit_approval_date,
                                       event_dates.tc_archived_date,
                                       event_dates.tc_sar_approved_date,
                                       event_dates.tc_sar_rejected_date,
                                       cac1.start_date AS cac1_start_date,
                                       cac1.end_date   AS cac1_end_date,
                                       cac1.cac_guid   AS cac1_guid,
                                       cac2.start_date AS cac2_start_date,
                                       cac2.end_date   AS cac2_end_date,
                                       cac2.cac_guid   AS cac2_guid
                                  FROM timecard        AS OF SCN lego_refresh_mgr_pkg.get_scn() t,
                                       timecard_entry  AS OF SCN lego_refresh_mgr_pkg.get_scn() te,
                                       (SELECT time_expenditure_id,
                                               rate_identifier_fk,
                                               hours,
                                               timecard_entry_fk
                                          FROM time_expenditure AS OF SCN lego_refresh_mgr_pkg.get_scn()
                                         WHERE is_current = 1) tx,
                                       assignment_continuity  AS OF SCN lego_refresh_mgr_pkg.get_scn() ac,
                                       currency_unit          cu,
                                       assignment_edition     AS OF SCN lego_refresh_mgr_pkg.get_scn() ae,
                                       firm_role              AS OF SCN lego_refresh_mgr_pkg.get_scn() fr,
                                       firm_role              AS OF SCN lego_refresh_mgr_pkg.get_scn() frs,
                                       candidate              AS OF SCN lego_refresh_mgr_pkg.get_scn() c,
                                       firm_worker            AS OF SCN lego_refresh_mgr_pkg.get_scn() hfw,
                                       rate_identifier        AS OF SCN lego_refresh_mgr_pkg.get_scn() ri,
                                       (SELECT constant_value, constant_description
                                          FROM java_constant_lookup
                                         WHERE constant_type    = 'TIMECARD_STATE'
                                           AND UPPER(locale_fk) = 'EN_US') timecard_state,
                                       (SELECT lcc.cac_id,
                                               lcc.start_date,
                                               lcc.end_date,
                                               lcc.cac_guid
                                          FROM lego_cac_collection lcc ) cac1,
                                       (SELECT lcc.cac_id,
                                               lcc.start_date,
                                               lcc.end_date,
                                               lcc.cac_guid
                                          FROM lego_cac_collection lcc ) cac2,
                                       lego_tc_events event_dates,
                                       (SELECT pwe.procurement_wkfl_edition_id, wpd.hours_per_day
                                          FROM work_period_definition AS OF SCN lego_refresh_mgr_pkg.get_scn() wpd,
                                               procurement_wkfl_edition AS OF SCN lego_refresh_mgr_pkg.get_scn() pwe
                                         WHERE pwe.work_period_definition_fk = wpd.work_period_definition_id)  hpd,
                                       --(SELECT timecard_template_edition_id, rate_type
                                       --   FROM timecard_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn()) rate_type,
                                       (SELECT rate_card_identifier_id, description
                                          FROM rate_card_identifier AS OF SCN lego_refresh_mgr_pkg.get_scn()) rci
                                 WHERE t.week_ending_date BETWEEN TO_DATE('}' ||TO_CHAR(v_start_date,'DD-MON-YYYY') || q'{','DD-MON-YYYY')}' || ' AND ' || q'{ TO_DATE('}' ||TO_CHAR(v_end_date,'DD-MON-YYYY hh24:mi:ss') || q'{','DD-MON-YYYY hh24:mi:ss')}' || q'{
                                   AND t.assignment_continuity_fk      = ac.assignment_continuity_id
                                   AND ac.assignment_continuity_id     = ae.assignment_continuity_fk
                                   AND ac.current_edition_fk           = ae.assignment_edition_id
                                   AND ac.work_order_fk IS NULL
                                   AND ac.currency_unit_fk             = cu.value
                                   AND ac.candidate_fk                 = c.candidate_id(+)
                                   AND ae.hiring_mgr_fk                = hfw.firm_worker_id(+)
                                   AND t.timecard_id                   = te.timecard_fk
                                   AND t.procurement_wkfl_edition_fk   = hpd.procurement_wkfl_edition_id (+)
                                   --AND t.timecard_template_edition_fk  = rate_type.timecard_template_edition_id (+)
                                   AND te.timecard_entry_id            = tx.timecard_entry_fk (+)
                                   AND te.rate_identifier_fk           = ri.rate_identifier_id
                                   AND te.rate_treatment_identifier_fk = rci.rate_card_identifier_id (+)
                                   AND ac.owning_buyer_firm_fk         = fr.firm_id
                                   AND ac.owning_supply_firm_fk        = frs.firm_id
                                   AND t.state_code                    = timecard_state.constant_value(+)
                                   AND te.cac1_fk                      = cac1.cac_id(+)
                                   AND te.cac2_fk                      = cac2.cac_id(+)
                                   AND t.state_code != 7
                                   AND ABS(NVL(te.hours,0)) + ABS(NVL(te.change_to_hours,0)) != 0
                                   AND CASE WHEN te.change_to_hours <= 0 THEN 1
                                       ELSE NVL (te.change_to_hours, 0) END
                                       >
                                       CASE WHEN timecard_type = 'Timecard Adjustment' THEN 0
                                       ELSE -1 END
                                   AND t.timecard_id                   = event_dates.timecard_id(+) ) lt,
                                lego_tc_ea_rates   ea_rates,
                                lego_tc_ea_rate_trmt_rates trmt_ea_rates
                        WHERE lt.timecard_entry_id = ea_rates.timecard_entry_id
                          AND lt.timecard_entry_id = trmt_ea_rates.timecard_entry_id (+)
                         ) point1
                  GROUP BY
                           point1.timecard_entry_id,
                           point1.timecard_id,
                           point1.buyer_org_id,
                           point1.supplier_org_id,
                           point1.contractor_person_id,
                           point1.hiring_mgr_person_id,
                           point1.candidate_id,
                           point1.wk_date,
                           point1.week_ending_date,
                           point1.timecard_number,
                           point1.timecard_type,
                           point1.cac1_identifier,
                           point1.cac2_identifier,
                           point1.job_id,
                           point1.assignment_continuity_id,
                           point1.work_order_id,
                           point1.assignment_edition_id,
                           point1.timecard_approval_workflow_id,
                           point1.te_udf_collection_id,
                           point1.t_udf_collection_id,
                           point1.hours,
                           point1.change_to_hours,
                           point1.timecard_state_id,
                           point1.timecard_state,
                           point1.rate_trmt_id,
                           CASE point1.rate_type_id
                              WHEN 0 THEN 0 --Hourly
                              WHEN 1 THEN 1 --Daily
                              WHEN 4 THEN 4 --Weekly
                              WHEN 3 THEN 3 --Monthly
                              ELSE NULL
                           END,
                           CASE point1.rate_type_id
                              WHEN 0 THEN 'Hourly'
                              WHEN 1 THEN 'Daily'
                              WHEN 2 THEN 'Annual'
                              WHEN 3 THEN 'Monthly'
                              WHEN 4 THEN 'Weekly'
                              ELSE 'N/A'
                           END,
                           point1.hours_per_day,
                           point1.is_break,
                           point1.tc_buyer_approved_date,
                           point1.tc_buyer_rejected_date,
                           point1.tc_created_date,
                           point1.tc_saved_date,
                           point1.tc_adjusted_date,
                           point1.tc_rerated_date,
                           point1.tc_approve_req_retract_date,
                           point1.tc_submit_approval_date,
                           point1.tc_archived_date,
                           point1.tc_sar_approved_date,
                           point1.tc_sar_rejected_date,
                           point1.cac1_start_date,
                           point1.cac1_end_date,
                           point1.cac1_guid,
                           point1.cac2_start_date,
                           point1.cac2_end_date,
                           point1.cac2_guid,
                           point1.timecard_currency_id,
                           point1.timecard_currency,
                           --currency_code,
                           reg_bill_rate,
                           ot_bill_rate,
                           dt_bill_rate,
                           custom_bill_rate,
                           adj_reg_bill_rate,
                           adj_ot_bill_rate,
                           adj_dt_bill_rate,
                           adj_custom_bill_rate,
                           rate_trmt_reg_bill_rate,
                           rate_trmt_ot_bill_rate,
                           rate_trmt_dt_bill_rate,
                           rate_trmt_cust_bill_rate,
                           rate_trmt_adj_reg_bill_rate,
                           rate_trmt_adj_ot_bill_rate,
                           rate_trmt_adj_dt_bill_rate,
                           rate_trmt_adj_cust_bill_rate}';
      logger_pkg.debug('create table lego_tc_ea_tmp');
      EXECUTE IMMEDIATE v_sql;
      logger_pkg.debug('create table lego_tc_ea_tmp - complete', TRUE);

      BEGIN
         EXECUTE IMMEDIATE 'DROP TABLE lego_timecard_tmp'|| i || ' PURGE';
      EXCEPTION
         WHEN OTHERS THEN
            NULL;
      END;

      v_sql :=
         'CREATE TABLE lego_timecard_tmp'|| i || ' ' || v_storage || q'{
            AS
        SELECT /*+ PARALLEL (6) */
               CAST(t.timecard_entry_id AS NUMBER)           AS timecard_entry_id,
               CAST(timecard_id AS NUMBER)                   AS timecard_id,
               CAST(buyer_org_id AS NUMBER)                  AS buyer_org_id,
               CAST(supplier_org_id AS NUMBER)               AS supplier_org_id,
               CAST(contractor_person_id AS NUMBER)          AS contractor_person_id,
               CAST(hiring_mgr_person_id AS NUMBER)          AS hiring_mgr_person_id,
               CAST(candidate_id AS NUMBER)                  AS candidate_id,
               CAST(wk_date AS DATE)                         AS wk_date,
               CAST(week_ending_date AS DATE)                AS week_ending_date,
               CAST(timecard_number AS VARCHAR2(256))        AS timecard_number,
               CAST(timecard_type AS VARCHAR2(20))           AS timecard_type,
               CAST(cac1_identifier AS NUMBER)               AS cac1_identifier,
               CAST(cac2_identifier AS NUMBER)               AS cac2_identifier,
               CAST(job_id AS NUMBER)                        AS job_id,
               CAST(assignment_continuity_id AS NUMBER)      AS assignment_continuity_id,
               CAST(assignment_edition_id AS NUMBER)         AS assignment_edition_id,
               CAST(timecard_approval_workflow_id AS NUMBER) AS timecard_approval_workflow_id,
               CAST(te_udf_collection_id AS NUMBER)          AS te_udf_collection_id,
               CAST(t_udf_collection_id AS NUMBER)           AS t_udf_collection_id,
               CAST(reg_hours AS NUMBER)                     AS reg_hours,
               CAST(ot_hours AS NUMBER)                      AS ot_hours,
               CAST(dt_hours AS NUMBER)                      AS dt_hours,
               CAST(custom_hours AS NUMBER)                  AS custom_hours,
               CAST(total_hours_day AS NUMBER)               AS total_hours_day,
               CAST(total_change_to_hours_day AS NUMBER)     AS total_change_to_hours_day,
               CAST(timecard_state_id AS NUMBER)             AS timecard_state_id,
               CAST(timecard_state AS VARCHAR2(4000))        AS timecard_state,
               CAST(rate_trmt_id AS VARCHAR2(4000))          AS rate_trmt_id,
               CAST(rate_type_desc AS VARCHAR2(7))           AS rate_type,
               CAST(hours_per_day AS NUMBER)                 AS hours_per_day,
               CAST(is_break AS NUMBER(1))                   AS is_break,
               CAST(tc_buyer_approved_date AS DATE)          AS tc_buyer_approved_date,
               CAST(tc_buyer_rejected_date AS DATE)          AS tc_buyer_rejected_date,
               CAST(tc_created_date AS DATE)                 AS tc_created_date,
               CAST(tc_saved_date AS DATE)                   AS tc_saved_date,
               CAST(tc_adjusted_date AS DATE)                AS tc_adjusted_date,
               CAST(tc_rerated_date AS DATE)                 AS tc_rerated_date,
               CAST(tc_approve_req_retract_date AS DATE)     AS tc_approve_req_retract_date,
               CAST(tc_submit_approval_date AS DATE)         AS tc_submit_approval_date,
               CAST(tc_archived_date AS DATE)                AS tc_archived_date,
               CAST(tc_sar_approved_date AS DATE)            AS tc_sar_approved_date,
               CAST(tc_sar_rejected_date AS DATE)            AS tc_sar_rejected_date,
               CAST(cac1_start_date AS DATE)                 AS cac1_start_date,
               CAST(cac1_end_date AS DATE)                   AS cac1_end_date,
               cac1_guid,
               CAST(cac2_start_date AS DATE)                 AS cac2_start_date,
               CAST(cac2_end_date AS DATE)                   AS cac2_end_date,
               cac2_guid,
               CAST(timecard_currency AS VARCHAR2(50))       AS timecard_currency,
               CAST(reg_bill_rate AS NUMBER)                 AS reg_bill_rate,
               CAST(ot_bill_rate AS NUMBER)                  AS ot_bill_rate,
               CAST(dt_bill_rate AS NUMBER)                  AS dt_bill_rate,
               CAST(custom_bill_rate AS NUMBER)              AS custom_bill_rate,
               CAST(adj_reg_bill_rate AS NUMBER)             AS adj_reg_bill_rate,
               CAST(adj_ot_bill_rate AS NUMBER)              AS adj_ot_bill_rate,
               CAST(adj_dt_bill_rate AS NUMBER)              AS adj_dt_bill_rate,
               CAST(adj_custom_bill_rate AS NUMBER)          AS adj_custom_bill_rate,
               CAST(rate_trmt_reg_bill_rate AS NUMBER)       AS rate_trmt_reg_bill_rate,
               CAST(rate_trmt_ot_bill_rate AS NUMBER)        AS rate_trmt_ot_bill_rate,
               CAST(rate_trmt_dt_bill_rate AS NUMBER)        AS rate_trmt_dt_bill_rate,
               CAST(rate_trmt_cust_bill_rate AS NUMBER)      AS rate_trmt_cust_bill_rate,
               CAST(rate_trmt_adj_reg_bill_rate AS NUMBER)   AS rate_trmt_adj_reg_bill_rate,
               CAST(rate_trmt_adj_ot_bill_rate AS NUMBER)    AS rate_trmt_adj_ot_bill_rate,
               CAST(rate_trmt_adj_dt_bill_rate AS NUMBER)    AS rate_trmt_adj_dt_bill_rate,
               CAST(rate_trmt_adj_cust_bill_rate AS NUMBER)  AS rate_trmt_adj_cust_bill_rate,
               CAST(
               CASE
                  WHEN t.rate_trmt_id IS NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.reg_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.reg_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.reg_bill_rate / 160
                              ELSE
                                 t.reg_bill_rate
                              END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.dt_bill_rate / 160
                             ELSE
                                t.dt_bill_rate
                             END )
                           * t.dt_hours)
                            +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.ot_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.ot_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.ot_bill_rate / 160
                              ELSE
                                 t.ot_bill_rate
                              END)
                           * t.ot_hours)
                             +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.custom_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.custom_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.custom_bill_rate / 160
                              ELSE
                                 t.custom_bill_rate
                              END)
                           * t.custom_hours)
                          )
                  WHEN t.rate_trmt_id IS NOT NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.rate_trmt_reg_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.rate_trmt_reg_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.rate_trmt_reg_bill_rate / 160
                              ELSE
                                 t.rate_trmt_reg_bill_rate
                              END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_dt_bill_rate / 160
                             ELSE
                                t.rate_trmt_dt_bill_rate
                             END )
                           * t.dt_hours)
                            +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.rate_trmt_ot_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.rate_trmt_ot_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.rate_trmt_ot_bill_rate / 160
                              ELSE
                                 t.rate_trmt_ot_bill_rate
                              END)
                           * t.ot_hours)
                             +
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.rate_trmt_cust_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.rate_trmt_cust_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.rate_trmt_cust_bill_rate / 160
                              ELSE
                                 t.rate_trmt_cust_bill_rate
                              END)
                           * t.custom_hours)
                          )
                  END AS NUMBER ) AS contractor_spend,
               CAST(
               CASE
                  WHEN t.rate_trmt_id IS NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                          (  (CASE
                                 WHEN t.rate_type =1 THEN t.adj_reg_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.adj_reg_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.adj_reg_bill_rate / 160
                              ELSE
                                 t.adj_reg_bill_rate
                              END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.adj_dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.adj_dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.adj_dt_bill_rate / 160
                             ELSE
                                t.adj_dt_bill_rate
                             END)
                           * t.dt_hours)
                            +
                         (  (CASE
                                 WHEN t.rate_type =1 THEN t.adj_ot_bill_rate / t.hours_per_day
                                 WHEN t.rate_type =4 THEN t.adj_ot_bill_rate / 40
                                 WHEN t.rate_type =3 THEN t.adj_ot_bill_rate / 160
                             ELSE
                                t.adj_ot_bill_rate
                             END)
                           * t.ot_hours)
                            +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.adj_custom_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.adj_custom_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.adj_custom_bill_rate / 160
                             ELSE
                                t.adj_custom_bill_rate
                             END)
                           * t.custom_hours)
                          )
                  WHEN t.rate_trmt_id IS NOT NULL  THEN
                     DECODE (
                        t.timecard_state_id,
                        5, 0,
                        (   (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_reg_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_reg_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_reg_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_reg_bill_rate
                             END)
                           * t.reg_hours)
                        +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_dt_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_dt_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_dt_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_dt_bill_rate
                             END )
                           * t.dt_hours)
                            +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_ot_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_ot_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_ot_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_ot_bill_rate
                             END)
                           * t.ot_hours)
                             +
                         (  (CASE
                                WHEN t.rate_type =1 THEN t.rate_trmt_adj_cust_bill_rate / t.hours_per_day
                                WHEN t.rate_type =4 THEN t.rate_trmt_adj_cust_bill_rate / 40
                                WHEN t.rate_type =3 THEN t.rate_trmt_adj_cust_bill_rate / 160
                             ELSE
                                t.rate_trmt_adj_cust_bill_rate
                             END)
                           * t.custom_hours)
                          )  END AS NUMBER ) AS cont_spend_amount_adj,
               CAST(t.timecard_currency_id AS NUMBER)        AS timecard_currency_id,
               CAST(inv.invoiced_amount AS NUMBER)           AS invoiced_amount
        FROM (
        SELECT timecard_entry_id,
               timecard_id,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               hiring_mgr_person_id,
               candidate_id,
               wk_date,
               week_ending_date,
               timecard_number,
               timecard_type,
               cac1_identifier,
               cac2_identifier,
               job_id,
               assignment_continuity_id,
               assignment_edition_id,
               timecard_approval_workflow_id,
               te_udf_collection_id,
               t_udf_collection_id,
               reg_hours,
               ot_hours,
               dt_hours,
               custom_hours,
               total_hours_day,
               total_change_to_hours_day,
               timecard_state_id,
               timecard_state,
               rate_trmt_id,
               rate_type,
               rate_type_desc,
               hours_per_day,
               is_break,
               tc_buyer_approved_date,
               tc_buyer_rejected_date,
               tc_created_date,
               tc_saved_date,
               tc_adjusted_date,
               tc_rerated_date,
               tc_approve_req_retract_date,
               tc_submit_approval_date,
               tc_archived_date,
               tc_sar_approved_date,
               tc_sar_rejected_date,
               cac1_start_date,
               cac1_end_date,
               cac1_guid,
               cac2_start_date,
               cac2_end_date,
               cac2_guid,
               timecard_currency_id,
               timecard_currency,
               reg_bill_rate,
               ot_bill_rate,
               dt_bill_rate,
               custom_bill_rate,
               adj_reg_bill_rate,
               adj_ot_bill_rate,
               adj_dt_bill_rate,
               adj_custom_bill_rate,
               rate_trmt_reg_bill_rate,
               rate_trmt_ot_bill_rate,
               rate_trmt_dt_bill_rate,
               rate_trmt_cust_bill_rate,
               rate_trmt_adj_reg_bill_rate,
               rate_trmt_adj_ot_bill_rate,
               rate_trmt_adj_dt_bill_rate,
               rate_trmt_adj_cust_bill_rate
          FROM lego_tc_wo_tmp
         UNION ALL
        SELECT timecard_entry_id,
               timecard_id,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               hiring_mgr_person_id,
               candidate_id,
               wk_date,
               week_ending_date,
               timecard_number,
               timecard_type,
               cac1_identifier,
               cac2_identifier,
               job_id,
               assignment_continuity_id,
               assignment_edition_id,
               timecard_approval_workflow_id,
               te_udf_collection_id,
               t_udf_collection_id,
               reg_hours,
               ot_hours,
               dt_hours,
               custom_hours,
               total_hours_day,
               total_change_to_hours_day,
               timecard_state_id,
               timecard_state,
               rate_trmt_id,
               rate_type,
               rate_type_desc,
               hours_per_day,
               is_break,
               tc_buyer_approved_date,
               tc_buyer_rejected_date,
               tc_created_date,
               tc_saved_date,
               tc_adjusted_date,
               tc_rerated_date,
               tc_approve_req_retract_date,
               tc_submit_approval_date,
               tc_archived_date,
               tc_sar_approved_date,
               tc_sar_rejected_date,
               cac1_start_date,
               cac1_end_date,
               cac1_guid,
               cac2_start_date,
               cac2_end_date,
               cac2_guid,
               timecard_currency_id,
               timecard_currency,
               reg_bill_rate,
               ot_bill_rate,
               dt_bill_rate,
               custom_bill_rate,
               adj_reg_bill_rate,
               adj_ot_bill_rate,
               adj_dt_bill_rate,
               adj_custom_bill_rate,
               rate_trmt_reg_bill_rate,
               rate_trmt_ot_bill_rate,
               rate_trmt_dt_bill_rate,
               rate_trmt_cust_bill_rate,
               rate_trmt_adj_reg_bill_rate,
               rate_trmt_adj_ot_bill_rate,
               rate_trmt_adj_dt_bill_rate,
               rate_trmt_adj_cust_bill_rate
          FROM lego_tc_ea_tmp) t,
               lego_invcd_expenditure_sum inv
         WHERE t.timecard_entry_id     = inv.expenditure_id(+)
           AND inv.expenditure_type(+) = 'Time'
         ORDER BY t.buyer_org_id, t.supplier_org_id, t.hiring_mgr_person_id, t.contractor_person_id, t.week_ending_date, t.timecard_entry_id}';
         logger_pkg.debug('create final table lego_timecard_tmp' || to_char(i));
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('create final table lego_timecard_tmp' || to_char(i) || 
                          ' - complete', TRUE);

         BEGIN
            SELECT 'CREATE INDEX ' || index_name || '_tmp' || i || ' ON lego_timecard_tmp' || i || '(' ||
                   LISTAGG(column_name, ', ')  WITHIN GROUP (ORDER BY column_position) || ') TABLESPACE '||
                   (SELECT tablespace_name
                      FROM all_ind_partitions
                     WHERE index_name = c.index_name
                       AND rownum = 1) || -- ' PARALLEL 6 ' || --commented out for IQN-19496
                   CASE WHEN (SELECT compression
                                FROM all_ind_partitions
                               WHERE index_name = c.index_name
                                 AND rownum = 1) = 'ENABLED' THEN ' COMPRESS' ELSE NULL END ||
                   ' NOLOGGING COMPUTE STATISTICS'
              INTO v_sql_index
              FROM all_ind_columns c
             WHERE table_name = 'LEGO_TIMECARD'
             GROUP BY index_name;
             logger_pkg.debug('creating index');
             EXECUTE IMMEDIATE v_sql_index;
             logger_pkg.debug('creating index - complete', TRUE);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
         END;

         v_release_sql := v_release_sql ||
                          'ALTER TABLE lego_timecard EXCHANGE PARTITION FOR (TO_DATE('''||TO_CHAR(v_start_date,'DD-MON-YYYY')||''',''DD-MON-YYYY'')) with table lego_timecard_tmp'|| i || CASE WHEN v_sql_index IS NOT NULL THEN ' INCLUDING INDEXES WITH VALIDATION; ' ELSE '; ' END ||
                          'DROP TABLE lego_timecard_tmp'|| i || ' PURGE; ';

      END LOOP;
      logger_pkg.debug('release sql: ' || v_release_sql);
      logger_pkg.info('exiting loop.  refresh complete.');

      p_release_sql := v_release_sql;

EXCEPTION
   WHEN OTHERS THEN
      logger_pkg.fatal(pi_transaction_result => NULL,
                       pi_error_code         => SQLCODE,
                       pi_message            => SQLERRM);
        
      RAISE;

END load_lego_timecard;

-------------------------

   PROCEDURE load_lego_address_init
   AS
      /*******************************************************************************
       *PROCEDURE NAME : load_lego_address_init
       *DATE CREATED   : December 4, 2012
       *AUTHOR         : Derek Reiner
       *PURPOSE        : This procedure creates the LEGO_ADDRESS table by finding
       *                        all the unique addresses in the system and assigning them
       *                        a GUID.  This GUID is propogated to the address table.
       *MODIFICATIONS  : January 7, 2013 - Removed the dropping of lego_address_stage_vw
       *                                   as it is needed by the maintenance proc.
       *                 Apr 3, 2013 J.Pullifrone removed references to USER - replace with sys_context constant
       *                                          gc_curr_schema.  Rel 11.2.       
       *               : April 16, 2013  - Added function index to table to improve refresh times
       ******************************************************************************/
      v_count   NUMBER;
      v_sql     VARCHAR2 (10000);
   BEGIN
      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'LEGO_ADDRESS';

      IF v_count = 0
      THEN
         v_sql :=
            q'{CREATE OR REPLACE FORCE VIEW lego_address_stage_vw AS
          SELECT a.contact_info_fk contact_info_id,
          a.address_id,
          p.standard_place_desc,
          p.buyer_org_id,
          a.name address_type,
          CASE WHEN INSTR (a.address, '&#') > 0 THEN REGEXP_REPLACE (a.address, '([&#[:digit:]]*)+;', ('\1')) ELSE a.address END address
          , CASE WHEN INSTR (a.line1, '&#') > 0 THEN REGEXP_REPLACE (NVL (a.line1, p.line1), '([&#[:digit:]]*)+;', ('\1')) ELSE NVL (a.line1, p.line1) END line1
          , CASE WHEN INSTR (a.line2, '&#') > 0 THEN REGEXP_REPLACE (NVL (a.line2, p.line2), '([&#[:digit:]]*)+;', ('\1')) ELSE NVL (a.line2, p.line2) END line2
          , CASE WHEN INSTR (a.line3, '&#') > 0 THEN REGEXP_REPLACE (NVL (a.line3, p.line3), '([&#[:digit:]]*)+;', ('\1')) ELSE NVL (a.line3, p.line3) END line3
          , CASE WHEN INSTR (a.line4, '&#') > 0 THEN REGEXP_REPLACE (NVL (a.line4, p.line4), '([&#[:digit:]]*)+;', ('\1')) ELSE NVL (a.line4, p.line4) END line4
          , NVL (TRIM (TRANSLATE (a.city, ',-', '  ')), TRIM (TRANSLATE (p.city, ',-', '  '))) city
          , p.county,
          NVL (a.providence, p.state) state,
          CASE WHEN a.line1 IS NULL AND a.line2 IS NULL AND a.line3 IS NULL AND a.line4 IS NULL AND a.city IS NULL AND a.providence IS NULL AND a.postal_code IS NULL THEN p.country_id ELSE c.VALUE END country_id
          , CASE WHEN a.line1 IS NULL AND a.line2 IS NULL AND a.line3 IS NULL AND a.line4 IS NULL AND a.city IS NULL AND a.providence IS NULL AND a.postal_code IS NULL THEN p.country ELSE c.description END country
          , CASE WHEN a.line1 IS NULL AND a.line2 IS NULL AND a.line3 IS NULL AND a.line4 IS NULL AND a.city IS NULL AND a.providence IS NULL AND a.postal_code IS NULL THEN p.country_code ELSE c.country_code END country_code
          , NVL (a.postal_code, p.postal_code) postal_code,
          a.place_fk place_id
     FROM address a, country c, lego_place_vw p
    WHERE     a.country = c.VALUE(+)
          AND address_type = 'P'
          AND a.contact_info_fk <> -1
          AND a.place_fk = p.place_id(+)
          AND (   a.line1 IS NOT NULL
               OR a.line2 IS NOT NULL
               OR a.line3 IS NOT NULL
               OR a.line4 IS NOT NULL
               OR a.city IS NOT NULL
               OR a.providence IS NOT NULL
               OR a.postal_code IS NOT NULL
               OR a.country IS NOT NULL
               OR a.place_fk IS NOT NULL)}';

         --CREATE LEGO_ADDRESS_STAGE_VW
         EXECUTE IMMEDIATE v_sql;

         v_sql :=
            q'{CREATE TABLE lego_address
                        NOLOGGING
                        TABLESPACE LEGO_USERS
                         AS
                        SELECT SYS_GUID () address_guid,
                          a.*
                          FROM (SELECT DISTINCT country_id,
                           country,
                           country_code,
                           state,
                           city,
                           postal_code,
                           P.PLACE_ID,
                           p.standard_place_desc,
                           CAST (line1 AS VARCHAR2 (100)) line1,
                           CAST (line2 AS VARCHAR2 (100)) line2,
                           CAST (line3 AS VARCHAR2 (100)) line3,
                           CAST (line4 AS VARCHAR2 (100)) line4,
                           county
             FROM lego_address_stage_vw p) a}';

         --CREATE LEGO_ADDRESS table
         EXECUTE IMMEDIATE v_sql;

         v_sql :=
            q'{ALTER TABLE lego_address ADD CONSTRAINT lego_address_pk PRIMARY KEY (address_guid) USING INDEX TABLESPACE lego_users}';

         --CREATE LEGO_ADDRESS_PK
         EXECUTE IMMEDIATE v_sql;

         v_sql :=
            q'{CREATE INDEX lego_address_ni01 ON lego_address (line1, postal_code, city, state) TABLESPACE lego_users}';

         --CREATE LEGO_ADDRESS_NI01
         EXECUTE IMMEDIATE v_sql;

         v_sql :=
            q'{CREATE INDEX LEGO_ADDRESS_FI01 ON LEGO_ADDRESS ( NVL (LINE1, 'NULL'), NVL (POSTAL_CODE, 'NULL')) TABLESPACE LEGO_USERS}';

         --CREATE LEGO_ADDRESS_FI01
         EXECUTE IMMEDIATE v_sql;

         --Gather Stats
         DBMS_STATS.gather_table_stats (ownname   => gc_curr_schema,
                                        tabname   => 'LEGO_ADDRESS',
                                        CASCADE   => TRUE);
         COMMIT;

      END IF;
   END load_lego_address_init;


PROCEDURE load_lego_contact_address_init
AS
   /*******************************************************************************
    *PROCEDURE NAME : load_lego_contact_address_init
    *DATE CREATED   : December 4, 2012
    *AUTHOR         : Derek Reiner
    *PURPOSE        : The procedure creates LEGO_CONTACT_ADDRESS.  The procedure
    *                  is complicated by the multiple routes to determine the proper
    *                  buyer org for each row.
    *MODIFICATIONS  : December 18, 2012 - Added bulk collect to a large update.
    *               : January 30, 2013 - Added function based index LEGO_CONTACT_ADDRESS_FI01
    *               : February 19, 2013 - Added the drop of temporary tables  if they exist to fix the
    *                  situation when the initi script fails and cleanup wasn't complete
    *               : March 26, 2013 -  RJ-506 - change storage clause in CREATE table to be dynamic - Release 11.2
    *                 Apr 03, 2013 J.Pullifrone removed references to USER - replace with sys_context constant
    *                                           gc_curr_schema.  Rel 11.2.                   
    ******************************************************************************/
   v_count   NUMBER;
   v_sql     VARCHAR2 (10000);
   v_storage          LEGO_REFRESH.EXADATA_STORAGE_CLAUSE%TYPE;
BEGIN
   SELECT COUNT (*)
     INTO v_count
     FROM user_tables
    WHERE table_name = 'LEGO_CONTACT_ADDRESS';

   IF v_count = 0
   THEN
   
      -- Retrieve the storage clause to allow for dynamic use of Exadata features if
      --the database allows.  
           SELECT exadata_storage_clause
           INTO v_storage
           FROM lego_refresh
          WHERE object_name = 'LEGO_PERSON';
   
      -- Check to see if temporary tables need to be dropped due to a failed init
      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'LEGO_ADDRESS_STAGE_TEMP';

      IF v_count = 1
      THEN
         v_sql := q'{DROP TABLE LEGO_ADDRESS_STAGE_TEMP CASCADE CONSTRAINTS}';

         --DROP  LEGO_ADDRESS_STAGE_TEMP
         EXECUTE IMMEDIATE v_sql;
      END IF;

      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'LEGO_CONTACT_ADDRESS_STAGE';

      IF v_count = 1
      THEN
         v_sql :=
            q'{DROP TABLE LEGO_CONTACT_ADDRESS_STAGE CASCADE CONSTRAINTS}';

         --DROP LEGO_CONTACT_ADDRESS_STAGE
         EXECUTE IMMEDIATE v_sql;
      END IF;


      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'DEREK_BUYER_ORG_VIA_BUS_ORG';

      IF v_count = 1
      THEN
         v_sql :=
            q'{DROP TABLE DEREK_BUYER_ORG_VIA_BUS_ORG CASCADE CONSTRAINTS}';

         --DROP DEREK_BUYER_ORG_VIA_BUS_ORG
         EXECUTE IMMEDIATE v_sql;
      END IF;

      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'DEREK_BUYER_ORG_VIA_ASSIGNMENT';

      IF v_count = 1
      THEN
         v_sql :=
            q'{DROP TABLE DEREK_BUYER_ORG_VIA_ASSIGNMENT CASCADE CONSTRAINTS}';

         --DROP DEREK_BUYER_ORG_VIA_ASSIGNMENT
         EXECUTE IMMEDIATE v_sql;
      END IF;

      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'DEREK_BUYER_ORG_VIA_CONTRACT';

      IF v_count = 1
      THEN
         v_sql :=
            q'{DROP TABLE DEREK_BUYER_ORG_VIA_CONTRACT CASCADE CONSTRAINTS}';

         --DROP DEREK_BUYER_ORG_VIA_CONTRACT
         EXECUTE IMMEDIATE v_sql;
      END IF;

      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'DEREK_BUYER_ORG_VIA_BUYER';

      IF v_count = 1
      THEN
         v_sql :=
            q'{DROP TABLE DEREK_BUYER_ORG_VIA_BUYER CASCADE CONSTRAINTS}';

         --DROP DEREK_BUYER_ORG_VIA_BUYER
         EXECUTE IMMEDIATE v_sql;
      END IF;

      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'DEREK_BUYER_ORG_VIA_SUPPLIER';

      IF v_count = 1
      THEN
         v_sql :=
            q'{DROP TABLE DEREK_BUYER_ORG_VIA_SUPPLIER CASCADE CONSTRAINTS}';

         --DROP DEREK_BUYER_ORG_VIA_SUPPLIER
         EXECUTE IMMEDIATE v_sql;
      END IF;

      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'DEREK_BUYER_ORG_VIA_PERSON';

      IF v_count = 1
      THEN
         v_sql :=
            q'{DROP TABLE DEREK_BUYER_ORG_VIA_PERSON CASCADE CONSTRAINTS}';

         --DROP DEREK_BUYER_ORG_VIA_PERSON
         EXECUTE IMMEDIATE v_sql;
      END IF;

      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'DEREK_BUYER_ORG_VIA_EMP_TERM';

      IF v_count = 1
      THEN
         v_sql :=
            q'{DROP TABLE DEREK_BUYER_ORG_VIA_EMP_TERM CASCADE CONSTRAINTS}';

         --DROP DEREK_BUYER_ORG_VIA_EMP_TERM
         EXECUTE IMMEDIATE v_sql;
      END IF;


      v_count := 0;

      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'DEREK_BUYER_ORG_VIA_ASGN_TERM';

      IF v_count = 1
      THEN
         v_sql :=
            q'{DROP TABLE DEREK_BUYER_ORG_VIA_ASGN_TERM CASCADE CONSTRAINTS}';

         --DROP DEREK_BUYER_ORG_VIA_ASGN_TERM
         EXECUTE IMMEDIATE v_sql;
      END IF;



      v_sql :=
         q'{CREATE TABLE 
lego_address_stage_temp
                       NOLOGGING
                        TABLESPACE LEGO_USERS AS
            SELECT  /*+parallel (a,8)*/
          a.contact_info_fk contact_info_id,
          a.address_id,
          p.standard_place_desc,
          p.buyer_org_id,
          a.name address_type,
          CASE WHEN INSTR (a.address, '&#') > 0 THEN REGEXP_REPLACE (a.address, '([&#[:digit:]]*)+;', ('\1')) ELSE a.address END address
          , CASE WHEN INSTR (a.line1, '&#') > 0 THEN REGEXP_REPLACE (NVL (a.line1, p.line1), '([&#[:digit:]]*)+;', ('\1')) ELSE NVL (a.line1, p.line1) END line1
          , CASE WHEN INSTR (a.line2, '&#') > 0 THEN REGEXP_REPLACE (NVL (a.line2, p.line2), '([&#[:digit:]]*)+;', ('\1')) ELSE NVL (a.line2, p.line2) END line2
          , CASE WHEN INSTR (a.line3, '&#') > 0 THEN REGEXP_REPLACE (NVL (a.line3, p.line3), '([&#[:digit:]]*)+;', ('\1')) ELSE NVL (a.line3, p.line3) END line3
          , CASE WHEN INSTR (a.line4, '&#') > 0 THEN REGEXP_REPLACE (NVL (a.line4, p.line4), '([&#[:digit:]]*)+;', ('\1')) ELSE NVL (a.line4, p.line4) END line4
          , NVL (TRIM (TRANSLATE (a.city, ',-', '  ')), TRIM (TRANSLATE (p.city, ',-', '  '))) city
          , p.county,
          NVL (a.providence, p.state) state,
          CASE WHEN a.line1 IS NULL AND a.line2 IS NULL AND a.line3 IS NULL AND a.line4 IS NULL AND a.city IS NULL AND a.providence IS NULL AND a.postal_code IS NULL THEN p.country_id ELSE c.VALUE END country_id
          , CASE WHEN a.line1 IS NULL AND a.line2 IS NULL AND a.line3 IS NULL AND a.line4 IS NULL AND a.city IS NULL AND a.providence IS NULL AND a.postal_code IS NULL THEN p.country ELSE c.description END country
          , CASE WHEN a.line1 IS NULL AND a.line2 IS NULL AND a.line3 IS NULL AND a.line4 IS NULL AND a.city IS NULL AND a.providence IS NULL AND a.postal_code IS NULL THEN p.country_code ELSE c.country_code END country_code
          , NVL (a.postal_code, p.postal_code) postal_code,
          a.place_fk place_id
     FROM address a, country c, lego_place_vw p
    WHERE     a.country = c.VALUE(+)
          AND address_type = 'P'
          AND a.contact_info_fk <> -1
          AND a.place_fk = p.place_id(+)
          AND (   a.line1 IS NOT NULL
               OR a.line2 IS NOT NULL
               OR a.line3 IS NOT NULL
               OR a.line4 IS NOT NULL
               OR a.city IS NOT NULL
               OR a.providence IS NOT NULL
               OR a.postal_code IS NOT NULL
               OR a.country IS NOT NULL
               OR a.place_fk IS NOT NULL)}';

      --CREATE LEGO_ADDRESS_STAGE_TEMP table
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE TABLE lego_contact_address_STAGE
                                   NOLOGGING
                        TABLESPACE LEGO_USERS AS
            SELECT /*+ parallel (a,8) */ a.buyer_org_id,
          a.contact_info_id,
          a.address_type,
          a.address_id,
          la.address_guid
     FROM lego_address_stage_temp a, lego_address la
    WHERE NVL (la.standard_place_desc, 'NULL') =
             NVL (a.standard_place_desc, 'NULL')
          AND NVL (la.city, 'NULL') = NVL (a.city, 'NULL')
          AND NVL (la.county, 'NULL') = NVL (a.county, 'NULL')
          AND NVL (la.state, 'NULL') = NVL (a.state, 'NULL')
          AND NVL (la.country_id, -1) = NVL (a.country_id, -1)
          AND NVL (la.country,  'NULL') = NVL (a.country,  'NULL')
          AND NVL (la.country_code,  'NULL') = NVL (a.country_code,  'NULL')
          AND NVL (la.line1, 'NULL') = NVL (a.line1, 'NULL')
          AND NVL (la.line2, 'NULL') = NVL (a.line2, 'NULL')
          AND NVL (la.line3, 'NULL') = NVL (a.line3, 'NULL')
          AND NVL (la.line4, 'NULL') = NVL (a.line4, 'NULL')
          AND NVL (la.postal_code, 'NULL') = NVL (a.postal_code, 'NULL')
          AND NVL (la.place_id, -1) = NVL (A.PLACE_ID, -1)}';

      --CREATE LEGO_CONTACT_ADDRESS_STAGE table
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{ALTER TABLE lego_contact_address_STAGE ADD CONSTRAINT lego_contact_address_STAGE_pk PRIMARY KEY (contact_info_id,address_type) USING INDEX TABLESPACE lego_users}';

      --CREATE LEGO_CONTACT_ADDRESS_STAGE_PK
      EXECUTE IMMEDIATE v_sql;

      --Gather Stats
      DBMS_STATS.gather_table_stats ( ownname => gc_curr_schema,
                                      tabname => 'LEGO_CONTACT_ADDRESS_STAGE',
                                      CASCADE => TRUE);
      COMMIT;

      v_sql := q'{DROP TABLE LEGO_ADDRESS_STAGE_TEMP CASCADE CONSTRAINTS}';

      --DROP  LEGO_ADDRESS_STAGE_TEMP
      EXECUTE IMMEDIATE v_sql;

      /***** CREATE TEMP TABLES TO HOLD BUYER ORGS *****/

      v_sql :=
         q'{CREATE TABLE derek_buyer_org_via_bus_org NOLOGGING TABLESPACE LEGO_USERS AS
            SELECT BO.BUSINESS_ORGANIZATION_ID,
                  ca.*
             FROM lego_contact_address_STAGE ca, BUSINESS_ORGANIZATION bo
            WHERE CA.CONTACT_INFO_ID = BO.CONTACT_INFORMATION_FK
                  AND CA.BUYER_ORG_ID IS NULL}';

      --CREATE DEREK_BUYER_ORG_VIA_BUS_ORG
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE UNIQUE INDEX derek_buyer_org_bus_org_ui01 ON derek_buyer_org_via_bus_org (contact_info_id, address_type) TABLESPACE lego_users}';

      --CREATE DEREK_BUYER_ORG_BUS_ORG_UI01
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{UPDATE (SELECT a.buyer_org_id,
                        b.business_organization_id,
                        A.CONTACT_INFO_ID,
                        A.ADDRESS_TYPE
                   FROM lego_contact_address_STAGE a,
                        derek_buyer_org_via_bus_org b
                  WHERE     a.contact_info_id = b.contact_info_id
                        AND A.ADDRESS_TYPE = b.address_type
                        AND A.BUYER_ORG_ID IS NULL)
            SET buyer_org_id = business_organization_id}';

      --UPDATE  LEGO_CONTACT_ADDRESS_STAGE
      EXECUTE IMMEDIATE v_sql;

      COMMIT;

      v_sql :=
         q'{CREATE TABLE derek_buyer_org_via_assignment NOLOGGING TABLESPACE LEGO_USERS AS
   SELECT DISTINCT BO.BUSINESS_ORGANIZATION_ID,
                   ca.*
     FROM lego_contact_address_STAGE ca,
          assignment_edition ae,
          ASSIGNMENT_CONTINUITY ac,
          FIRM_ROLE fr,
          BUSINESS_ORGANIZATION bo
    WHERE     CA.CONTACT_INFO_ID = AE.RESOURCE_ONSITE_FK
          AND AE.ASSIGNMENT_CONTINUITY_FK = AC.ASSIGNMENT_CONTINUITY_ID
          AND AC.OWNING_BUYER_FIRM_FK = FR.FIRM_ID
          AND FR.BUSINESS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
          AND CA.BUYER_ORG_ID IS NULL}';

      --CREATE DEREK_BUYER_ORG_VIA_ASSIGNMENT
      EXECUTE IMMEDIATE v_sql;



      v_sql :=
         q'{CREATE UNIQUE INDEX derek_buyer_org_via_asgn_ui01 ON derek_buyer_org_via_assignment (contact_info_id, address_type) TABLESPACE lego_users}';

      --CREATE DEREK_BUYER_ORG_VIA_ASGN_UI01
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{UPDATE (SELECT a.buyer_org_id,
                        b.business_organization_id
                   FROM lego_contact_address_STAGE a,
                        derek_buyer_org_via_assignment b
                  WHERE     a.contact_info_id = b.contact_info_id
                        AND A.ADDRESS_TYPE = b.address_type
                        AND A.BUYER_ORG_ID IS NULL)
            SET buyer_org_id = business_organization_id}';

      --UPDATE  LEGO_CONTACT_ADDRESS_STAGE
      EXECUTE IMMEDIATE v_sql;

      COMMIT;


      v_sql := q'{CREATE TABLE derek_buyer_org_via_contract NOLOGGING
                        TABLESPACE LEGO_USERS
AS
   SELECT BO.BUSINESS_ORGANIZATION_ID,
          ca.*
     FROM lego_contact_address_STAGE ca,
          contract_party_term cpt,
          CONTRACT_PARTY cp,
          business_organization bo
    WHERE     CA.CONTACT_INFO_ID = CPT.CONTACT_INFO_FK
          AND CPT.CONTRACT_PARTY_FK = CP.CONTRACT_PARTY_ID
          AND CP.LEGAL_ENTITY_FK = BO.BUSINESS_ORGANIZATION_ID
          AND CA.BUYER_ORG_ID IS NULL}';

      --CREATE DEREK_BUYER_ORG_VIA_CONTRACT
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE UNIQUE INDEX derek_buyer_org_contract_ui01 ON derek_buyer_org_via_contract (contact_info_id, address_type) TABLESPACE lego_users}';

      --CREATE DEREK_BUYER_ORG_CONTRACT_UI01
      EXECUTE IMMEDIATE v_sql;

      --Gather Stats
      DBMS_STATS.gather_table_stats ( ownname => gc_curr_schema,
                                      tabname => 'DEREK_BUYER_ORG_VIA_CONTRACT'
                                     , CASCADE => TRUE);
      COMMIT;


      v_sql :=
         q'{DECLARE CURSOR contract_cur
     IS
        SELECT b.CONTACT_INFO_ID,
               b.ADDRESS_TYPE,
               b.business_organization_id
          FROM derek_buyer_org_via_contract b;

     TYPE fetch_array IS TABLE OF contract_cur%ROWTYPE;

     s_array   fetch_array;
  BEGIN
     OPEN contract_cur;

     LOOP
        FETCH contract_cur
        BULK COLLECT INTO s_array
        LIMIT 4000;

        FORALL i IN 1 .. s_array.COUNT
           UPDATE lego_contact_address_STAGE a
              SET A.BUYER_ORG_ID = s_array (i).business_organization_id
            WHERE     a.contact_info_id = s_array (i).contact_info_id
                  AND A.ADDRESS_TYPE = s_array (i).address_type
                  AND A.BUYER_ORG_ID IS NULL;

        COMMIT;
        EXIT WHEN contract_cur%NOTFOUND;
     END LOOP;

     CLOSE contract_cur;

     COMMIT;
  END;}';

      --Update LEGO_CONTACT_ADDRESS_STAGE from DEREK_BUYER_ORG_VIA_BUS_ORG
      EXECUTE IMMEDIATE v_sql;


      COMMIT;


      v_sql :=
         q'{CREATE TABLE derek_buyer_org_via_buyer NOLOGGING
                        TABLESPACE LEGO_USERS
AS
   SELECT BO.BUSINESS_ORGANIZATION_ID,
          ca.*
     FROM lego_contact_address_STAGE ca,
          invoiced_buyer_supplier ibs,
          BUSINESS_ORGANIZATION bo
    WHERE     CA.CONTACT_INFO_ID = IBS.BUYER_BUS_ORG_BILL_TO_ADDR_FK
          AND IBS.BUYER_BUS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
          AND CA.BUYER_ORG_ID IS NULL}';

      --CREATE DEREK_BUYER_ORG_VIA_BUYER
      EXECUTE IMMEDIATE v_sql;



      v_sql :=
         q'{CREATE UNIQUE INDEX derek_buyer_org_via_buyer_ui01 ON derek_buyer_org_via_buyer (contact_info_id, address_type) TABLESPACE lego_users}';

      --CREATE DEREK_BUYER_ORG_VIA_BUYER_UI01
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{UPDATE (SELECT a.buyer_org_id,
                        b.business_organization_id
                   FROM lego_contact_address_STAGE a,
                        derek_buyer_org_via_buyer b
                  WHERE     a.contact_info_id = b.contact_info_id
                        AND A.ADDRESS_TYPE = b.address_type
                        AND A.BUYER_ORG_ID IS NULL)
            SET buyer_org_id = business_organization_id}';

      --UPDATE  LEGO_CONTACT_ADDRESS_STAGE
      EXECUTE IMMEDIATE v_sql;

      COMMIT;


      v_sql :=
         q'{CREATE TABLE derek_buyer_org_via_supplier NOLOGGING
                        TABLESPACE LEGO_USERS
AS
   SELECT BO.BUSINESS_ORGANIZATION_ID,
          ca.*
     FROM lego_contact_address_STAGE ca,
          invoiced_buyer_supplier ibs,
          BUSINESS_ORGANIZATION bo
    WHERE     CA.CONTACT_INFO_ID = IBS.SUPPLIER_BUS_ORG_PYMNT_ADDR_FK
          AND IBS.BUYER_BUS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
          AND CA.BUYER_ORG_ID IS NULL}';

      --CREATE DEREK_BUYER_ORG_VIA_SUPPLIER
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE UNIQUE INDEX derek_buyer_org_supplier_ui01 ON derek_buyer_org_via_supplier (contact_info_id, address_type) TABLESPACE lego_users}';

      --CREATE DEREK_BUYER_ORG_SUPPLIER_UI01
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{UPDATE (SELECT a.buyer_org_id,
                        b.business_organization_id
                   FROM lego_contact_address_STAGE a,
                        derek_buyer_org_via_supplier b
                  WHERE     a.contact_info_id = b.contact_info_id
                        AND A.ADDRESS_TYPE = b.address_type
                        AND A.BUYER_ORG_ID IS NULL)
            SET buyer_org_id = business_organization_id}';

      --UPDATE  LEGO_CONTACT_ADDRESS_STAGE
      EXECUTE IMMEDIATE v_sql;

      COMMIT;

      v_sql :=
         q'{CREATE TABLE derek_buyer_org_via_person NOLOGGING
                        TABLESPACE LEGO_USERS
AS
   SELECT DISTINCT BO.BUSINESS_ORGANIZATION_ID,
                   ca.*
     FROM lego_contact_address_STAGE ca, BUSINESS_ORGANIZATION bo, PERSON per
    WHERE     CA.CONTACT_INFO_ID = PER.CONTACT_INFO_FK
          AND per.BUSINESS_ORGANIZATION_FK = BO.BUSINESS_ORGANIZATION_ID
          AND CA.BUYER_ORG_ID IS NULL}';

      --CREATE DEREK_BUYER_ORG_VIA_PERSON
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE UNIQUE INDEX derek_buyer_org_person_ui01 ON derek_buyer_org_via_person (contact_info_id, address_type) TABLESPACE lego_users}';

      --CREATE DEREK_BUYER_ORG_PERSON_UI01
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{UPDATE (SELECT a.buyer_org_id,
                        b.business_organization_id
                   FROM lego_contact_address_STAGE a,
                        derek_buyer_org_via_person b
                  WHERE     a.contact_info_id = b.contact_info_id
                        AND A.ADDRESS_TYPE = b.address_type
                        AND A.BUYER_ORG_ID IS NULL)
            SET buyer_org_id = business_organization_id}';

      --UPDATE  LEGO_CONTACT_ADDRESS_STAGE
      EXECUTE IMMEDIATE v_sql;


      COMMIT;

      v_sql :=
         q'{CREATE TABLE derek_buyer_org_via_emp_term NOLOGGING TABLESPACE LEGO_USERS
AS
   SELECT BO.BUSINESS_ORGANIZATION_ID,
          ca.*
     FROM lego_contact_address_STAGE ca,
          BUSINESS_ORGANIZATION bo,
          employment_term et,
          job j,
          buyer_firm bf,
          firm_role fr
    WHERE     CA.CONTACT_INFO_ID = ET.WORK_ADDRESS_FK
          AND ET.JOB_FK = J.JOB_ID
          AND J.BUYER_FIRM_FK = BF.FIRM_ID
          AND BF.FIRM_ID = FR.FIRM_ID
          AND FR.BUSINESS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
          AND CA.BUYER_ORG_ID IS NULL}';

      --CREATE DEREK_BUYER_ORG_VIA_EMP_TERM
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE UNIQUE INDEX derek_buyer_org_emp_term_ui01 ON derek_buyer_org_via_emp_term (contact_info_id, address_type) TABLESPACE lego_users}';

      --CREATE DEREK_BUYER_ORG_EMP_TERM_UI01
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{UPDATE (SELECT a.buyer_org_id,
                        b.business_organization_id
                   FROM lego_contact_address_STAGE a,
                        derek_buyer_org_via_emp_term b
                  WHERE     a.contact_info_id = b.contact_info_id
                        AND A.ADDRESS_TYPE = b.address_type
                        AND A.BUYER_ORG_ID IS NULL)
            SET buyer_org_id = business_organization_id}';

      --UPDATE  LEGO_CONTACT_ADDRESS_STAGE
      EXECUTE IMMEDIATE v_sql;

      COMMIT;

      v_sql :=
         q'{CREATE TABLE derek_buyer_org_via_asgn_term NOLOGGING TABLESPACE LEGO_USERS
AS
   SELECT BO.BUSINESS_ORGANIZATION_ID,
          ca.*
     FROM lego_contact_address_STAGE ca,
          BUSINESS_ORGANIZATION bo,
          work_assignment_term wat,
          contract_term ct,
          contract_version CV,
          contract c,
          buyer_supplier_agreement bsa,
          buyer_firm bf,
          firm_role fr
    WHERE     CA.CONTACT_INFO_ID = wat.work_location_fk
          AND WAT.CONTRACT_TERM_ID = CT.CONTRACT_TERM_ID
          AND CT.CONTRACT_VERSION_FK = CV.CONTRACT_VERSION_ID
          AND CV.CONTRACT_FK = C.CONTRACT_ID
          AND C.CONTRACT_ID = BSA.CONTRACT_ID
          AND BSA.BUYER_FIRM_FK = BF.FIRM_ID
          AND BF.FIRM_ID = FR.FIRM_ID
          AND FR.BUSINESS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
          AND CA.BUYER_ORG_ID IS NULL}';

      --CREATE DEREK_BUYER_ORG_VIA_ASGN_TERM
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE UNIQUE INDEX derek_buyer_org_asgn_term_UI01 ON derek_buyer_org_via_asgn_term (contact_info_id, address_type) TABLESPACE lego_users}';

      --CREATE DEREK_BUYER_ORG_ASGN_TERM_UI01
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{UPDATE (SELECT a.buyer_org_id,
                        b.business_organization_id
                   FROM lego_contact_address_STAGE a,
                        derek_buyer_org_via_asgn_term b
                  WHERE     a.contact_info_id = b.contact_info_id
                        AND A.ADDRESS_TYPE = b.address_type
                        AND A.BUYER_ORG_ID IS NULL)
            SET buyer_org_id = business_organization_id}';

      --UPDATE  LEGO_CONTACT_ADDRESS_STAGE
      EXECUTE IMMEDIATE v_sql;


      COMMIT;


      v_sql := q'{UPDATE lego_contact_address_STAGE
            SET BUYER_ORG_ID = -1
          WHERE BUYER_ORG_ID IS NULL}';

      --UPDATE  LEGO_CONTACT_ADDRESS_STAGE
      EXECUTE IMMEDIATE v_sql;

      COMMIT;
      v_sql := q'{DROP TABLE DEREK_BUYER_ORG_VIA_BUS_ORG CASCADE CONSTRAINTS}';

      --DROP DEREK_BUYER_ORG_VIA_BUS_ORG
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{DROP TABLE DEREK_BUYER_ORG_VIA_ASSIGNMENT CASCADE CONSTRAINTS}';

      --DROP DEREK_BUYER_ORG_VIA_ASSIGNMENT
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{DROP TABLE DEREK_BUYER_ORG_VIA_CONTRACT CASCADE CONSTRAINTS}';

      --DROP DEREK_BUYER_ORG_VIA_CONTRACT
      EXECUTE IMMEDIATE v_sql;

      v_sql := q'{DROP TABLE DEREK_BUYER_ORG_VIA_BUYER CASCADE CONSTRAINTS}';

      --DROP DEREK_BUYER_ORG_VIA_BUYER
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{DROP TABLE DEREK_BUYER_ORG_VIA_SUPPLIER CASCADE CONSTRAINTS}';

      --DROP DEREK_BUYER_ORG_VIA_SUPPLIER
      EXECUTE IMMEDIATE v_sql;

      v_sql := q'{DROP TABLE DEREK_BUYER_ORG_VIA_PERSON CASCADE CONSTRAINTS}';

      --DROP DEREK_BUYER_ORG_VIA_PERSON
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{DROP TABLE DEREK_BUYER_ORG_VIA_EMP_TERM CASCADE CONSTRAINTS}';

      --DROP DEREK_BUYER_ORG_VIA_EMP_TERM
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{DROP TABLE DEREK_BUYER_ORG_VIA_ASGN_TERM CASCADE CONSTRAINTS}';

      --DROP DEREK_BUYER_ORG_VIA_ASGN_TERM
      EXECUTE IMMEDIATE v_sql;

         v_sql :=
            'CREATE TABLE lego_contact_address ' || v_storage ||
             q'{ AS
     SELECT buyer_org_id,
            address_type,
            contact_info_id,
            address_id,
            address_guid
       FROM lego_contact_address_STAGE
   ORDER BY buyer_org_id, address_type}';
   
      --CREATE LEGO_CONTACT_ADDRESS
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{ALTER TABLE lego_contact_address ADD CONSTRAINT lego_contact_address_pk PRIMARY KEY (contact_info_id,address_type) USING INDEX TABLESPACE lego_users}';

      --CREATE LEGO_CONTACT_ADDRESS_PK
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE INDEX lego_contact_address_ni01 ON lego_contact_address (address_guid) TABLESPACE lego_users COMPRESS}';

      --CREATE LEGO_CONTACT_ADDRESS_NI01
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE INDEX lego_contact_address_ni02 ON lego_contact_address (BUYER_ORG_ID) TABLESPACE lego_users COMPRESS}';

      --CREATE LEGO_CONTACT_ADDRESS_NI02
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE UNIQUE INDEX lego_contact_address_UI01 ON lego_contact_address (address_id) TABLESPACE lego_users}';

      --CREATE LEGO_CONTACT_ADDRESS_UI01
      EXECUTE IMMEDIATE v_sql;

      v_sql :=
         q'{CREATE INDEX LEGO_CONTACT_ADDRESS_FI01 ON LEGO_CONTACT_ADDRESS (NVL2 (ADDRESS_GUID, NULL, 1)) TABLESPACE lego_users}';

      --CREATE LEGO_CONTACT_ADDRESS_FI01
      EXECUTE IMMEDIATE v_sql;

      --Gather Stats
      DBMS_STATS.gather_table_stats ( ownname => gc_curr_schema,
                                      tabname => 'LEGO_CONTACT_ADDRESS',
                                      CASCADE => TRUE);
      COMMIT;

      v_sql := q'{DROP TABLE LEGO_CONTACT_ADDRESS_STAGE CASCADE CONSTRAINTS}';

      --DROP LEGO_CONTACT_ADDRESS_STAGE
      EXECUTE IMMEDIATE v_sql;
   END IF;
END load_lego_contact_address_init;



   PROCEDURE load_lego_contact_gtt_init
   AS
      /*******************************************************************************
       *PROCEDURE NAME : load_lego_contact_gtt_init
       *DATE CREATED   : December 4, 2012
       *AUTHOR         : Derek Reiner
       *PURPOSE        : This procedure will create the GTT used to process lego_contact_address
       *                        updates.
       *MODIFICATIONS  : January 30, 2013 - Added function based index LEGO_CONTACT_ADDRESS_GTT_FI01
       *                 Apr 03, 2013 J.Pullifrone removed references to USER - replace with sys_context constant
       *                                           gc_curr_schema.  Rel 11.2.       
       ******************************************************************************/
      v_count   NUMBER;
      v_sql     VARCHAR2 (10000);
   BEGIN
      SELECT COUNT (*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'LEGO_CONTACT_ADDRESS_GTT';

      IF v_count = 0
      THEN
         v_sql := q'{CREATE GLOBAL TEMPORARY TABLE LEGO_CONTACT_ADDRESS_GTT (
CONTACT_INFO_ID NUMBER (38), ADDRESS_TYPE VARCHAR2 (100),
ADDRESS_ID NUMBER (38) NOT NULL, ADDRESS_GUID RAW (16))
ON COMMIT PRESERVE ROWS}';

         --CREATE LEGO_CONTACT_ADDRESS_GTT
         EXECUTE IMMEDIATE v_sql;
         
         v_sql := q'{CREATE INDEX LEGO_CONTACT_ADDRESS_GTT_FI01 ON LEGO_CONTACT_ADDRESS_GTT (NVL2 (ADDRESS_GUID, NULL, 1))}';

         --CREATE LEGO_CONTACT_ADDRESS_GTT_FI01
         EXECUTE IMMEDIATE v_sql;
         
      END IF;
   END load_lego_contact_gtt_init;


   PROCEDURE load_lego_cac_init
   AS
      /*******************************************************************************
       *PROCEDURE NAME : load_lego_cac_init
       *DATE CREATED   : December 5, 2012
       *AUTHOR         : Jason Looney Derek Reiner
       *PURPOSE        : This procedure will create the Cost Allocation Code table.
       *MODIFICATIONS  : 03/13/2013 - E.Clark - changed TRIM to RTRIM, updated REGEXP_SUBSTR
                       :   function to parse correctly per Jira Defect #RJ-447 - Release 11.1.2
                       : 03/25/2013 - E.Clark - RJ-506 - change storage clause in CREATE table to be dynamic - Release 11.2
                       : 08/18/2014 - pmuller - IQN-19497 - convert all logging to use LOGGER_PKG - 12.2
       ******************************************************************************/
      v_count            NUMBER;
      v_sql              VARCHAR2 (10000);
      v_storage          LEGO_REFRESH.EXADATA_STORAGE_CLAUSE%TYPE;

   BEGIN
      logger_pkg.set_code_location('LEGO_CAC_INIT');
      SELECT COUNT(*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'LEGO_CAC';

      IF v_count = 0 THEN

         SELECT exadata_storage_clause
           INTO v_storage
           FROM lego_refresh
          WHERE object_name = 'LEGO_CAC_COLLECTION';

         v_sql :=
            'CREATE TABLE lego_cac ' || v_storage ||
             q'{ AS
                WITH cac_val AS
           (SELECT identifier, TRIM(value) AS value, TRIM(description) AS description
              FROM cac_value c)
    SELECT SYS_GUID () cac_guid,
            cac_oid,
            RTRIM (cac_segment_1.value
                        || ':'
                        || cac_segment_2.value
                        || ':'
                        || cac_segment_3.value
                        || ':'
                        || cac_segment_4.value
                        || ':'
                        || cac_segment_5.value, ':')  AS cac_value,
            RTRIM (cac_segment_1.description
                        || ':'
                        || cac_segment_2.description
                        || ':'
                        || cac_segment_3.description
                        || ':'
                        || cac_segment_4.description
                        || ':'
                        || cac_segment_5.description, ':') AS cac_desc,
            cac_segment_1_id,
            cac_segment_1.value       AS cac_segment_1_value,
            cac_segment_1.description AS cac_segment_1_desc,
            cac_segment_2_id,
            cac_segment_2.value       AS cac_segment_2_value,
            cac_segment_2.description AS cac_segment_2_desc,
            cac_segment_3_id,
            cac_segment_3.value       AS cac_segment_3_value,
            cac_segment_3.description AS cac_segment_3_desc,
            cac_segment_4_id,
            cac_segment_4.value       AS cac_segment_4_value,
            cac_segment_4.description AS cac_segment_4_desc,
            cac_segment_5_id,
            cac_segment_5.value       AS cac_segment_5_value,
            cac_segment_5.description AS cac_segment_5_desc
       FROM (SELECT /*+ PARALLEL (cac,8) */ 
                    DISTINCT RTRIM (cac.cac_oid_string,':') cac_oid,
                    TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 1, NULL,1)) AS cac_segment_1_id,
                    TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 2, NULL,1)) AS cac_segment_2_id,
                    TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 3, NULL,1)) AS cac_segment_3_id,
                    TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 4, NULL,1)) AS cac_segment_4_id,
                    TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 5, NULL,1)) AS cac_segment_5_id
               FROM cost_alloc_code cac) a,
            cac_val cac_segment_1,
            cac_val cac_segment_2,
            cac_val cac_segment_3,
            cac_val cac_segment_4,
            cac_val cac_segment_5
      WHERE a.cac_segment_1_id = cac_segment_1.identifier(+)
        AND a.cac_segment_2_id = cac_segment_2.identifier(+)
        AND a.cac_segment_3_id = cac_segment_3.identifier(+)
        AND a.cac_segment_4_id = cac_segment_4.identifier(+)
        AND a.cac_segment_5_id = cac_segment_5.identifier(+)
   ORDER BY cac_value}';
    
        logger_pkg.debug(v_sql);
        logger_pkg.debug('creating table');
        EXECUTE IMMEDIATE v_sql;
        logger_pkg.debug('creating table - complete', TRUE);

        v_sql :=
            q'{ALTER TABLE lego_cac ADD CONSTRAINT lego_cac_pk PRIMARY KEY (cac_guid) USING INDEX TABLESPACE lego_users}';

        logger_pkg.debug('ADD PK AND PK INDEX');
        EXECUTE IMMEDIATE v_sql;
        logger_pkg.debug('ADD PK AND PK INDEX - complete', TRUE);

        v_sql :=
            q'{CREATE UNIQUE INDEX lego_cac_ui01 ON lego_cac (cac_oid) TABLESPACE lego_users NOLOGGING COMPUTE STATISTICS}';

        logger_pkg.debug('adding INDX_UI01');         
        EXECUTE IMMEDIATE v_sql;
        logger_pkg.debug('adding INDX_UI01 - complete',TRUE);

        v_sql :=
            q'{CREATE INDEX lego_cac_ni01 ON lego_cac (cac_value) TABLESPACE lego_users NOLOGGING COMPUTE STATISTICS}';

        logger_pkg.debug('adding INDX_NI01');
        EXECUTE IMMEDIATE v_sql;
        logger_pkg.debug('adding INDX_NI01 - complete', TRUE);

        logger_pkg.debug('gathering STATS');
        DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema, 
                                       tabname          => 'LEGO_CAC', 
                                       estimate_percent => 10,
                                       degree           => 6);
        logger_pkg.debug('gathering STATS - complete', TRUE);

        COMMIT;

      ELSE  
        logger_pkg.warn('LEGO_CAC TABLE EXISTS - no action taken');
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
        logger_pkg.fatal(pi_transaction_result => NULL,
                         pi_error_code         => SQLCODE,
                         pi_message            => SQLERRM);
        
        RAISE;

   END load_lego_cac_init;


   PROCEDURE load_lego_cac_collection_init
   AS
      /*******************************************************************************
       *PROCEDURE NAME : load_lego_cac_collection_init
       *DATE CREATED   : December 5, 2012
       *AUTHOR         : Jason Looney Derek Reiner
       *PURPOSE        : This procedure will create the Cost Allocation Code Collection table.
       *MODIFICATIONS  : 01/14/2013 - Made the following changes to decrease run times:
                                    - removed RANK column for cac_collection_position,
                                    - Added UNION ALL
                                    - Changes to Index/PK creation, and stats
                       : 02/07/2013 - E.Clark - changed table to reflect LEGO_CAC_COLLECTION_1,
                                    - added synonym LEGO_CAC_COLLECTION creation for LEGO_CAC_COLLECTION_1  - Release 11.1.1
                       : 02/17/2013 - E.Clark - added (p_table_name IN VARCHAR2) which is needed for PROC_TOGGLE - Release 11.1.1
                       : 03/13/2013 - E.Clark - changed TRIM to RTRIM per Jira Defect #RJ-447 - Release 11.1.2
                       : 03/18/2013 - E.Clark - add NULL accounting back in per Jira Defect #RJ-447 - Relase 11.1.2          
                       : 03/25/2013 - E.Clark - RJ-507 - change storage clause in CREATE table to be dynamic - Release 11.2
                       : 04/03/2013 - J.Pullifrone removed references to USER - replace with sys_context constant gc_curr_schema - Rel 11.2
                       : 04/22/2013 - E.Clark - going back to incremental loader that focuses on only delta records; PROCEDURE ONLY 
                       :                      - LEGO_CAC_COLLECTION no longer a toggle table - Release 11.2.1
                       : 08/18/2014 - pmuller - IQN-19497 - convert all logging to use LOGGER_PKG - 12.2
       ******************************************************************************/
      v_count            NUMBER;
      v_sql              VARCHAR2 (10000);
      v_storage          LEGO_REFRESH.EXADATA_STORAGE_CLAUSE%TYPE;

   BEGIN
      SELECT COUNT(*)
        INTO v_count
        FROM user_tables
       WHERE table_name = 'LEGO_CAC_COLLECTION';

      IF v_count = 0 THEN

         SELECT exadata_storage_clause
           INTO v_storage
           FROM lego_refresh
          WHERE object_name = 'LEGO_CAC_COLLECTION';

         v_sql :=
            'CREATE TABLE lego_cac_collection ' || v_storage || 
             q'{ AS
     SELECT /*+ PARALLEL (4) */
            DISTINCT c.identifier cac_id,
            NVL(bo.business_org_fk, -1) AS bus_org_id,
            cac_collection_fk           AS cac_collection_id,
            s.cac_kind                  AS cac_kind,
            c.start_date,
            c.end_date,
            l.cac_guid
       FROM cost_alloc_code c,
            lego_cac l,
            cac_spec s,
            (SELECT bf.cac1_spec_fk AS cac_spec_id, fr.business_org_fk
               FROM buyer_firm bf, firm_role fr
              WHERE bf.firm_id = fr.firm_id 
                AND cac1_spec_fk IS NOT NULL
              UNION ALL
             SELECT bf.cac2_spec_fk AS cac_spec_id, fr.business_org_fk
               FROM buyer_firm bf, firm_role fr
              WHERE bf.firm_id          = fr.firm_id 
                AND cac2_spec_fk IS NOT NULL) bo
      WHERE c.cac_spec_fk               = bo.cac_spec_id(+)
        AND NVL(RTRIM(c.cac_oid_string,':'),'ABC') = NVL(l.cac_oid,'ABC')
        AND c.cac_spec_fk               = s.identifier(+)
   ORDER BY bus_org_id, cac_collection_id, cac_id}';

         logger_pkg.debug(v_sql);
         logger_pkg.debug('CREATE LEGO_CAC_COLLECTION');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('CREATE LEGO_CAC_COLLECTION - complete', TRUE);

         v_sql := 'CREATE UNIQUE INDEX lego_cac_collection_ui01
                      ON lego_cac_collection (cac_id)
                      TABLESPACE lego_users
                      PARALLEL 6
                      NOLOGGING
                      COMPUTE STATISTICS';
         logger_pkg.debug('Create IND UI01');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('Create IND UI01 - complete', TRUE);

         v_sql := 'ALTER TABLE lego_cac_collection
                      ADD CONSTRAINT lego_cac_collection_pk PRIMARY KEY (cac_id)
                      USING INDEX lego_cac_collection_ui01';
         logger_pkg.debug('Add PK');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('Add PK - complete', TRUE);

         v_sql := 'CREATE INDEX lego_cac_collection_ni01
                      ON lego_cac_collection (cac_collection_id)
                      TABLESPACE lego_users
                      PARALLEL 6
                      NOLOGGING
                      COMPRESS
                      COMPUTE STATISTICS';
         logger_pkg.debug('INDX_NI01');
         EXECUTE IMMEDIATE v_sql;
         logger_pkg.debug('INDX_NI01 - complete', TRUE);

         --Gather Stats
         logger_pkg.debug('STATS');
         DBMS_STATS.gather_table_stats
            (ownname          => gc_curr_schema,
             tabname          => 'LEGO_CAC_COLLECTION',
             estimate_percent => 5,
             degree           => 6);
         logger_pkg.debug('STATS - complete', TRUE);
         COMMIT;
      ELSE
        logger_pkg.warn('LEGO_CAC_COLLECTION already exists - no action taken');   
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
        logger_pkg.fatal(pi_transaction_result => NULL,
                         pi_error_code         => SQLCODE,
                         pi_message            => SQLERRM);
        
        RAISE;

   END load_lego_cac_collection_init;


PROCEDURE load_lego_cacs_refresh
AS 

   /*---------------------------------------------------------------------------*\
   || PROCEDURE NAME       : load_lego_cacs_refresh
   || AUTHOR               : Erik Clark
   || DATE CREATED         : February 06, 2013
   || PURPOSE              : This procedure is used to load data into the LEGO_CAC_COLLECTION_1 or LEGO_CAC_COLLECTION_2,
   ||                      : AND it does a delta load into LEGO_CAC table.
   ||                      : It will also perform the update to the FO table.column: cost_alloc_code.lego_cac_guid
   || MODIFICATION HISTORY : 02/27/2013 - E.Clark - in Merge2.get_list1, changed to process in groups of 100 - Release 11.1.2
   ||                      : 03/04/2013 - E.Clark - rewrote Merge2, Also updated Merge1 to use LEGO_CAC_TEMP - Release 11.1.2
   ||                      : 03/13/2013 - E.Clark - updated TRIM to RTRIM per Jira #RJ-447 - Release 11.1.2
   ||                      : 03/18/2013 - E.Clark - add NULL accounting back in per Jira Defect #RJ-447 - Relase 11.1.2
   ||                      : 03/27/2013 - E.Clark - Fix bug in Merge1 dealing with NULLS - RELEASE 11.2
   ||                      : 04/03/2013 - J.Pullifrone - removed references to USER - replace with sys_context constant gc_curr_schema - Rel 11.2
   ||                      : 04/15/2013 - E.Clark - Defect I-13045317 - fix NULL issue in Merge2 - Release 11.2
   ||                      : 04/18/2013 - E.Clark - going back to incremental loader that focuses on only delta records; 
   ||                      :                      - LEGO_CAC_COLLECTION no longer a toggle table - Release 11.2.1
   ||                      : 08/18/2014 - pmuller - IQN-19497 - convert all logging to use LOGGER_PKG - 12.2
   \*---------------------------------------------------------------------------*/

   v_sql1             clob;
   v_date             DATE;
   v_storage          LEGO_REFRESH.EXADATA_STORAGE_CLAUSE%TYPE;
   v_count            PLS_INTEGER;
   
BEGIN
   logger_pkg.set_code_location('LEGO_CAC_COLLECTION refresh');
   v_date := SYSDATE - (5/86400); --SYSDATE - 5 seconds

   SELECT exadata_storage_clause
     INTO v_storage
     FROM lego_refresh
    WHERE object_name = 'LEGO_CAC_COLLECTION';

   logger_pkg.debug('dropping temp tables lego_cac_temp and lego_cac_temp2');
   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_cac_temp PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_cac_temp2 PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;
   logger_pkg.debug('dropping temp tables lego_cac_temp and lego_cac_temp2 - complete', TRUE);

   v_sql1 := 
    'CREATE TABLE lego_cac_temp
          ' || v_storage ||  
          q'{ AS
          WITH cac_val AS
               (SELECT identifier, 
                       TRIM(value) AS value, 
                       TRIM(description) AS description
                  FROM cac_value c)
         SELECT cac_oid,
                RTRIM (        cac_segment_1.VALUE
                            || ':'
                            || cac_segment_2.VALUE
                            || ':'
                            || cac_segment_3.VALUE
                            || ':'
                            || cac_segment_4.VALUE
                            || ':'
                            || cac_segment_5.VALUE, ':')   AS cac_value,
                RTRIM (        cac_segment_1.description
                            || ':'
                            || cac_segment_2.description
                            || ':'
                            || cac_segment_3.description
                            || ':'
                            || cac_segment_4.description
                            || ':'
                            || cac_segment_5.description, ':') AS cac_desc,
                cac_segment_1_id,
                cac_segment_1.value AS cac_segment_1_value,
                cac_segment_1.description AS cac_segment_1_desc,
                cac_segment_2_id,
                cac_segment_2.value AS cac_segment_2_value,
                cac_segment_2.description AS cac_segment_2_desc,
                cac_segment_3_id,
                cac_segment_3.value AS cac_segment_3_value,
                cac_segment_3.description AS cac_segment_3_desc,
                cac_segment_4_id,
                cac_segment_4.value AS cac_segment_4_value,
                cac_segment_4.description AS cac_segment_4_desc,
                cac_segment_5_id,
                cac_segment_5.value AS cac_segment_5_value,
                cac_segment_5.description AS cac_segment_5_desc
           FROM (SELECT  /*+ PARALLEL (cac,8) */ 
                         DISTINCT RTRIM (cac.cac_oid_string,':') cac_oid,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 1, NULL,1)) AS cac_segment_1_id,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 2, NULL,1)) AS cac_segment_2_id,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 3, NULL,1)) AS cac_segment_3_id,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 4, NULL,1)) AS cac_segment_4_id,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 5, NULL,1)) AS cac_segment_5_id
                    FROM (SELECT * 
                            FROM cost_alloc_code 
                           WHERE lego_cac_guid IS NULL) cac ) a,
                cac_val cac_segment_1,
                cac_val cac_segment_2,
                cac_val cac_segment_3,
                cac_val cac_segment_4,
                cac_val cac_segment_5
          WHERE a.cac_segment_1_id = cac_segment_1.identifier(+)
            AND a.cac_segment_2_id = cac_segment_2.identifier(+)
            AND a.cac_segment_3_id = cac_segment_3.identifier(+)
            AND a.cac_segment_4_id = cac_segment_4.identifier(+)
            AND a.cac_segment_5_id = cac_segment_5.identifier(+)
       ORDER BY cac_value}';
   logger_pkg.debug(v_sql1);
   logger_pkg.debug('creating table lego_cac_temp');
   EXECUTE IMMEDIATE v_sql1;  
   logger_pkg.debug('creating table lego_cac_temp - complete', TRUE);
   
   v_sql1 :=
     q'{MERGE INTO lego_cac lc
        USING (
              SELECT cac_oid, cac_value, cac_desc, 
                     cac_segment_1_id, cac_segment_1_value, cac_segment_1_desc,
                     cac_segment_2_id, cac_segment_2_value, cac_segment_2_desc,
                     cac_segment_3_id, cac_segment_3_value, cac_segment_3_desc,
                     cac_segment_4_id, cac_segment_4_value, cac_segment_4_desc,
                     cac_segment_5_id, cac_segment_5_value, cac_segment_5_desc
                FROM lego_cac_temp c2
               WHERE NOT EXISTS
                         (SELECT cac_oid 
                            FROM lego_cac c1
                           WHERE NVL(c2.cac_oid,'ABC') = NVL(c1.cac_oid,'ABC'))
              ) news
      ON (NVL(lc.cac_oid,'ABC') = NVL(news.cac_oid,'ABC'))
      WHEN MATCHED THEN
         UPDATE
            SET lc.cac_value           = news.cac_value,
                lc.cac_desc            = news.cac_desc,
                lc.cac_segment_1_id    = news.cac_segment_1_id,
                lc.cac_segment_1_value = news.cac_segment_1_value,
                lc.cac_segment_1_desc  = news.cac_segment_1_desc,
                lc.cac_segment_2_id    = news.cac_segment_2_id,
                lc.cac_segment_2_value = news.cac_segment_2_value,
                lc.cac_segment_2_desc  = news.cac_segment_2_desc,
                lc.cac_segment_3_id    = news.cac_segment_3_id,
                lc.cac_segment_3_value = news.cac_segment_3_value,
                lc.cac_segment_3_desc  = news.cac_segment_3_desc,
                lc.cac_segment_4_id    = news.cac_segment_4_id,
                lc.cac_segment_4_value = news.cac_segment_4_value,
                lc.cac_segment_4_desc  = news.cac_segment_4_desc,
                lc.cac_segment_5_id    = news.cac_segment_5_id,
                lc.cac_segment_5_value = news.cac_segment_5_value,
                lc.cac_segment_5_desc  = news.cac_segment_5_desc
      WHEN NOT MATCHED THEN
         INSERT VALUES
            (SYS_GUID(), news.cac_oid, news.cac_value, news.cac_desc,
             news.cac_segment_1_id, news.cac_segment_1_value, news.cac_segment_1_desc,
             news.cac_segment_2_id, news.cac_segment_2_value, news.cac_segment_2_desc,
             news.cac_segment_3_id, news.cac_segment_3_value, news.cac_segment_3_desc,
             news.cac_segment_4_id, news.cac_segment_4_value, news.cac_segment_4_desc,
             news.cac_segment_5_id, news.cac_segment_5_value, news.cac_segment_5_desc)}';
   logger_pkg.debug('merge1.1');
   EXECUTE IMMEDIATE v_sql1;
   logger_pkg.debug('merge1.1 - complete - ' || to_char(SQL%ROWCOUNT) || ' rows merged', TRUE);
   COMMIT;

   v_sql1 :=
      q'{MERGE INTO lego_cac_collection lcc
         USING
     ( SELECT /*+ PARALLEL (6) */
               DISTINCT
               c.identifier                 AS cac_id,
               NVL(bo.business_org_fk, -1)  AS bus_org_id,
               cac_collection_fk            AS cac_collection_id,
               s.cac_kind                   AS cac_kind,
               c.start_date,
               c.end_date,
               l.cac_guid
         FROM (SELECT * FROM cost_alloc_code WHERE lego_cac_guid IS NULL) c,
              lego_cac l,
              cac_spec s,
              (SELECT bf.cac1_spec_fk AS cac_spec_id, fr.business_org_fk
                 FROM buyer_firm bf, firm_role fr
                WHERE bf.firm_id = fr.firm_id 
                  AND cac1_spec_fk IS NOT NULL
               UNION ALL
               SELECT bf.cac2_spec_fk AS cac_spec_id, fr.business_org_fk
                 FROM buyer_firm bf, firm_role fr
                WHERE bf.firm_id = fr.firm_id 
                  AND cac2_spec_fk IS NOT NULL) bo
        WHERE c.cac_spec_fk = bo.cac_spec_id(+)
          AND NVL(RTRIM(c.cac_oid_string,':'),'ABC') = NVL(l.cac_oid (+),'ABC')
          AND c.cac_spec_fk = s.identifier(+)
        ORDER BY bus_org_id, cac_collection_id, cac_id ) news
       ON (lcc.cac_id = news.cac_id)
   WHEN MATCHED THEN
         UPDATE
            SET lcc.bus_org_id         = news.bus_org_id,
                lcc.cac_collection_id  = news.cac_collection_id,
                lcc.cac_kind           = news.cac_kind,
                lcc.start_date         = news.start_date,       
                lcc.end_date           = news.end_date,
                lcc.cac_guid           = news.cac_guid 
      WHEN NOT MATCHED THEN
         INSERT VALUES
            (news.cac_id, news.bus_org_id, news.cac_collection_id, news.cac_kind, news.start_date, news.end_date, news.cac_guid)}';
   logger_pkg.debug('merge1.2');
   EXECUTE IMMEDIATE v_sql1;
   logger_pkg.debug('merge1.2 - complete - ' || to_char(SQL%ROWCOUNT) || ' rows merged', TRUE);
   COMMIT;

   -----------------------
   --UPDATE Descriptions--
   -----------------------

    v_sql1 := 
    'CREATE TABLE lego_cac_temp2
          ' || v_storage ||  
          q'{ AS
          WITH cac_val AS
               (SELECT identifier, 
                       TRIM(value) AS value, 
                       TRIM(description) AS description
                  FROM cac_value c)
         SELECT cac_oid,
                RTRIM (        cac_segment_1.VALUE
                            || ':'
                            || cac_segment_2.VALUE
                            || ':'
                            || cac_segment_3.VALUE
                            || ':'
                            || cac_segment_4.VALUE
                            || ':'
                            || cac_segment_5.VALUE, ':')   AS cac_value,
                RTRIM (        cac_segment_1.description
                            || ':'
                            || cac_segment_2.description
                            || ':'
                            || cac_segment_3.description
                            || ':'
                            || cac_segment_4.description
                            || ':'
                            || cac_segment_5.description, ':') AS cac_desc,
                cac_segment_1_id,
                cac_segment_1.value AS cac_segment_1_value,
                cac_segment_1.description AS cac_segment_1_desc,
                cac_segment_2_id,
                cac_segment_2.value AS cac_segment_2_value,
                cac_segment_2.description AS cac_segment_2_desc,
                cac_segment_3_id,
                cac_segment_3.value AS cac_segment_3_value,
                cac_segment_3.description AS cac_segment_3_desc,
                cac_segment_4_id,
                cac_segment_4.value AS cac_segment_4_value,
                cac_segment_4.description AS cac_segment_4_desc,
                cac_segment_5_id,
                cac_segment_5.value AS cac_segment_5_value,
                cac_segment_5.description AS cac_segment_5_desc
           FROM ( SELECT /*+ PARALLEL (cac,8) */ 
                         DISTINCT RTRIM (cac.cac_oid_string,':') cac_oid,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 1, NULL,1)) AS cac_segment_1_id,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 2, NULL,1)) AS cac_segment_2_id,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 3, NULL,1)) AS cac_segment_3_id,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 4, NULL,1)) AS cac_segment_4_id,
                         TO_NUMBER(REGEXP_SUBSTR(cac.cac_oid_string, '([^:]*)(:|$)', 1, 5, NULL,1)) AS cac_segment_5_id
                    FROM (SELECT c.*
                            FROM cost_alloc_code c,
                                 (SELECT lc.cac_id
                                    FROM lego_cac_collection lc,
                                         (SELECT cac_guid FROM 
                                            (WITH cac_changes AS
                                                          (SELECT cac_value_id
                                                             FROM cac_value_desc_log
                                                            WHERE change_date < TO_DATE('}' || TO_CHAR(v_date,'DD-MON-YYYY hh24:mi:ss') || q'{','DD-MON-YYYY hh24:mi:ss') )
                                                         SELECT *
                                                           FROM lego_cac cac1
                                                          WHERE cac1.cac_segment_1_id IN (SELECT cac_value_id FROM cac_changes)
                                                          UNION
                                                         SELECT *
                                                           FROM lego_cac cac2
                                                          WHERE cac2.cac_segment_2_id IN (SELECT cac_value_id FROM cac_changes)
                                                          UNION
                                                         SELECT *
                                                           FROM lego_cac cac3
                                                          WHERE cac3.cac_segment_3_id IN (SELECT cac_value_id FROM cac_changes) 
                                                          UNION
                                                         SELECT *
                                                           FROM lego_cac cac4
                                                          WHERE cac4.cac_segment_4_id IN (SELECT cac_value_id FROM cac_changes)
                                                          UNION
                                                         SELECT *
                                                           FROM lego_cac cac5
                                                          WHERE cac5.cac_segment_5_id IN (SELECT cac_value_id FROM cac_changes)
                                            )
                                         ) guids
                                   WHERE lc.cac_guid = guids.cac_guid) get_ids
                           WHERE c.identifier = get_ids.cac_id) cac ) a,
                cac_val cac_segment_1,
                cac_val cac_segment_2,
                cac_val cac_segment_3,
                cac_val cac_segment_4,
                cac_val cac_segment_5
          WHERE a.cac_segment_1_id = cac_segment_1.identifier(+)
            AND a.cac_segment_2_id = cac_segment_2.identifier(+)
            AND a.cac_segment_3_id = cac_segment_3.identifier(+)
            AND a.cac_segment_4_id = cac_segment_4.identifier(+)
            AND a.cac_segment_5_id = cac_segment_5.identifier(+)
       ORDER BY cac_value}';
   logger_pkg.debug(v_sql1);
   logger_pkg.debug('creating table lego_cac_temp2');
   EXECUTE IMMEDIATE v_sql1;  
   logger_pkg.debug('creating table lego_cac_temp2 - complete', TRUE);

   v_sql1 :=
     q'{MERGE INTO lego_cac lc
        USING (
              SELECT cac_oid, cac_value, cac_desc, 
                     cac_segment_1_id, cac_segment_1_value, cac_segment_1_desc,
                     cac_segment_2_id, cac_segment_2_value, cac_segment_2_desc,
                     cac_segment_3_id, cac_segment_3_value, cac_segment_3_desc,
                     cac_segment_4_id, cac_segment_4_value, cac_segment_4_desc,
                     cac_segment_5_id, cac_segment_5_value, cac_segment_5_desc
                FROM lego_cac_temp2 c2
              ) news
      ON (NVL(lc.cac_oid,'ABC') = NVL(news.cac_oid,'ABC'))
      WHEN MATCHED THEN
         UPDATE
            SET lc.cac_value           = news.cac_value,
                lc.cac_desc            = news.cac_desc,
                lc.cac_segment_1_id    = news.cac_segment_1_id,
                lc.cac_segment_1_value = news.cac_segment_1_value,
                lc.cac_segment_1_desc  = news.cac_segment_1_desc,
                lc.cac_segment_2_id    = news.cac_segment_2_id,
                lc.cac_segment_2_value = news.cac_segment_2_value,
                lc.cac_segment_2_desc  = news.cac_segment_2_desc,
                lc.cac_segment_3_id    = news.cac_segment_3_id,
                lc.cac_segment_3_value = news.cac_segment_3_value,
                lc.cac_segment_3_desc  = news.cac_segment_3_desc,
                lc.cac_segment_4_id    = news.cac_segment_4_id,
                lc.cac_segment_4_value = news.cac_segment_4_value,
                lc.cac_segment_4_desc  = news.cac_segment_4_desc,
                lc.cac_segment_5_id    = news.cac_segment_5_id,
                lc.cac_segment_5_value = news.cac_segment_5_value,
                lc.cac_segment_5_desc  = news.cac_segment_5_desc
      WHEN NOT MATCHED THEN
         INSERT VALUES
            (SYS_GUID(), news.cac_oid, news.cac_value, news.cac_desc,
             news.cac_segment_1_id, news.cac_segment_1_value, news.cac_segment_1_desc,
             news.cac_segment_2_id, news.cac_segment_2_value, news.cac_segment_2_desc,
             news.cac_segment_3_id, news.cac_segment_3_value, news.cac_segment_3_desc,
             news.cac_segment_4_id, news.cac_segment_4_value, news.cac_segment_4_desc,
             news.cac_segment_5_id, news.cac_segment_5_value, news.cac_segment_5_desc)}';
   logger_pkg.debug('merge2');
   EXECUTE IMMEDIATE v_sql1;
   logger_pkg.debug('merge2 - complete - ' || to_char(SQL%ROWCOUNT) || ' rows merged', TRUE);
   COMMIT;

   v_sql1 := 'DELETE 
                FROM cac_value_desc_log
               WHERE change_date < :1';
   logger_pkg.debug('merge2 delete using date: ' || to_char(v_date,'YYYY-Mon-DD hh24:mi:ss'));
   EXECUTE IMMEDIATE v_sql1 USING v_date;
   logger_pkg.debug('merge2 delete using date: ' || to_char(v_date,'YYYY-Mon-DD hh24:mi:ss') || 
                    ' - complete - ' || to_char(SQL%ROWCOUNT) || ' rows deleted', TRUE);
   COMMIT; 

   logger_pkg.debug('dropping temp tables lego_cac_temp and lego_cac_temp2');
   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_cac_temp PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;

   BEGIN
      EXECUTE IMMEDIATE 'DROP TABLE lego_cac_temp2 PURGE';
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END;
   logger_pkg.debug('dropping temp tables lego_cac_temp and lego_cac_temp2 - complete', TRUE);
   
   ------------
   logger_pkg.set_code_location('checking FO column COST_ALLOC_CODE.LEGO_CAC_GUID');
   v_sql1 := 'SELECT COUNT(*)
                FROM (SELECT 1
                        FROM cost_alloc_code
                       WHERE lego_cac_guid IS NOT NULL)
               WHERE rownum < 2';
   EXECUTE IMMEDIATE v_sql1 INTO v_count;

   IF v_count > 0 THEN
      --this fo updater only runs after an initial update fo has been run manually, outside the normal process,
      --package resides in the FO schema
      logger_pkg.info('Calling lego_guid_maintenance.upd_cost_alloc_codes_guid');
      v_sql1 := q'{BEGIN
                   lego_guid_maintenance.upd_cost_alloc_codes_guid ('}'||gc_curr_schema||'.LEGO_CAC_COLLECTION'||q'{');
                 END;}';
      EXECUTE IMMEDIATE v_sql1;
   ELSE
     logger_pkg.info('NO need to call lego_guid_maintenance.upd_cost_alloc_codes_guid'); 
   END IF;

   logger_pkg.info('LEGO_CAC_COLLECTION refresh complete');
   
EXCEPTION
   WHEN OTHERS THEN
     ROLLBACK;
     logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                      pi_error_code         => SQLCODE,
                      pi_message            => SQLERRM);

     RAISE;

END load_lego_cacs_refresh;
   
   
PROCEDURE lego_address_refresh
AS
/*******************************************************************************
 *PROCEDURE NAME : lego_address_refresh
 *DATE CREATED   : August 17, 2012
 *AUTHOR         : Derek Reiner
 *PURPOSE        : Incorporates New and Updated address information into
 *                 LEGO_ADDRESS and LEGO_CONTACT_ADDRESS
 *MODIFICATIONS  : August 25, 2012 - Removed SCN logic from tables
 *               : December 6, 2012 - Wrapped code in execute immediate so that
 *                 lego_util would remain valid even in a bootstrap environment.
 *               : January 30, 2013 - Rewrote queries to use function based indexes and
 *                  reduced the number of times a full table scan of the address table occured
 *                  from four times to once.
 *               :February 8, 2013 - added package prefix to UPDATE_LEGO_ADDRESS_GUID call
 *                  because lego procs were consolidated into the LEGO_GUID_MAINTENANCE
 *                  package on IQPROD.
 *               :February 21, 2013 - added some error handling for No Data Found
 *                 and made the insert of new address_ids into lego_contact_address better.
 *               :February 22, 2013 - changed the logic for finding new additions to address
 *                 and made the insert of new address_ids into lego_contact_address better.
 *               :March 27, 2013 - added incremental commit to inserts and updates.
 *               :April 8, 2013 - added error handling into procedure call to frontoffice to handle
 *                 the no data found scenario. Added incremental commit to insert into GTT.
 *               :April 11, 2013 - Changed insert into GTT to join as incremental commit was taking
 *                 to long.  Added parallel and append hints.
 *               :April 12, 2013 - Backed out join and returned to incremental commit.  Added one more
 *                 parallel hint.
 *               :April 15, 2013 - Added error handling to catch duplicate records from
 *                 the address table (contact_info, address_type).
 ******************************************************************************/
BEGIN

EXECUTE IMMEDIATE q'{
DECLARE
   v_int        NUMBER := 0;
   v_source     VARCHAR2 (61) := '.UPDATING_LEGO_ADDRESS_TABLES';

BEGIN

   logger_pkg.set_source (v_source);

   logger_pkg.set_code_location ('DETERMINE NEW ADDRESSES');
   LOGGER_PKG.INFO ('INSERT NEW ADDRESSES INTO LEGO_ADDRESS...');

   -- Get all the possible distinct addresses and then MINUS with what exists already...these are the new addresses
   INSERT                                                        /*+ APPEND */
         INTO                lego_address
      SELECT                                                /*+ PARALLEL(4) */
            SYS_GUID () address_guid,
             a.*
        FROM (SELECT DISTINCT country_id,
                              country,
                              country_code,
                              state,
                              city,
                              postal_code,
                              PLACE_ID,
                              standard_place_desc,
                              line1,
                              line2,
                              line3,
                              line4,
                              county
                FROM lego_address_stage_vw
              MINUS
              SELECT country_id,
                     country,
                     country_code,
                     state,
                     city,
                     postal_code,
                     PLACE_ID,
                     standard_place_desc,
                     line1,
                     line2,
                     line3,
                     line4,
                     county
                FROM lego_address) a;

   logger_pkg.info (
         'INSERT NEW ADDRESSES INTO LEGO_ADDRESS... - DONE!  '
      || SQL%ROWCOUNT
      || ' Rows Inserted!',
      TRUE);

   COMMIT;

   logger_pkg.set_code_location ('TRUNC LEGO_CONTACT_ADDRESS_GTT');
   LOGGER_PKG.INFO ('TRUNC LEGO_CONTACT_ADDRESS_GTT FOR ADDRESS LOAD...');

   EXECUTE IMMEDIATE 'TRUNCATE TABLE LEGO_CONTACT_ADDRESS_GTT';

   logger_pkg.info (
      'TRUNC LEGO_CONTACT_ADDRESS_GTT FOR ADDRESS LOAD.. - DONE!',
      TRUE);

   logger_pkg.set_code_location ('INSERT ADDRESS INFO INTO GTT');
   LOGGER_PKG.INFO ('INSERT ADDRESS INFO INTO GTT...');

   INSERT INTO lego_contact_address_gtt
      SELECT                                              /*+ parallel (a,4)*/
            A.contact_info_fk contact_info_id,
             A.NAME address_type,
             a.address_id,
             a.lego_address_guid address_guid
        FROM address a
       WHERE a.address_type = 'P' AND a.contact_info_fk <> -1;

   logger_pkg.info (
         'INSERT ADDRESS INFO INTO GTT... - DONE!  '
      || SQL%ROWCOUNT
      || ' Rows Inserted!',
      TRUE);

   logger_pkg.set_code_location ('NULL OUT ADDRESS_GUID');
   LOGGER_PKG.INFO ('UPDATE ADDRESS_GUID TO NULL...');

   -- NULL out the value in lego_contact_address where address.lego_address_guid is NULL.
   -- This will happen with updates or creations in the address table.
   UPDATE lego_contact_address ca
      SET address_guid = NULL
    WHERE (ca.address_id, ca.contact_info_id, ca.address_type) IN
             (SELECT               /*+ index(LEGO_CONTACT_ADDRESS_GTT_FI01) */
                    a.address_id
                     , a.contact_info_id
                     , a.address_type
                FROM lego_contact_address_gtt a
               WHERE NVL2 (
                        A.ADDRESS_GUID,
                        NULL,
                        1) = 1);

   logger_pkg.info (
         'UPDATE ADDRESS_GUID TO NULL... - DONE!  '
      || SQL%ROWCOUNT
      || ' Rows Updated!',
      TRUE);

   COMMIT;

   logger_pkg.set_code_location ('INSERT NEW CONTACT_INFO_ID');
   LOGGER_PKG.INFO ('INSERT NEW CONTACT_INFO_ID...');

   -- Get all the new contact info ids and insert them into lego_contact_address
   -- with a NULL value for address_guid and an undefined value for business org.
   DECLARE
      CURSOR new_contact_info_cur
      IS
         (SELECT                   /*+ index(LEGO_CONTACT_ADDRESS_GTT_FI01) */
                a.contact_info_id,
                 a.address_type,
                 a.address_id
            FROM lego_contact_address_gtt a
           WHERE NVL2 (A.ADDRESS_GUID, NULL, 1) = 1)
         MINUS
         (SELECT contact_info_id,
                 address_type,
                 address_id
            FROM lego_contact_address);
   BEGIN
      v_int := 0;

      FOR new_contact_info_rec IN new_contact_info_cur
      LOOP
         BEGIN
            INSERT INTO lego_contact_address ca ( CA.BUYER_ORG_ID,
                                                  CA.CONTACT_INFO_ID,
                                                  CA.ADDRESS_TYPE,
                                                  CA.ADDRESS_ID,
                                                  CA.ADDRESS_GUID)
                 VALUES (-99,
                         new_contact_info_rec.contact_info_id,
                         new_contact_info_rec.address_type,
                         new_contact_info_rec.address_id,
                         NULL);
         EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
               LOGGER_PKG.INFO ( 'DUPLICATE CONTACT_INFO_ID: ' || new_contact_info_rec.contact_info_id || ' and ADDRESS_TYPE: ' || new_contact_info_rec.address_type || ' FOUND');
         END;

         v_int := v_int + 1;

         IF (MOD ( v_int,
                   1000) = 0)
         THEN
            COMMIT;
         END IF;
      END LOOP;

      logger_pkg.info (
            'INSERT NEW CONTACT_INFO_ID... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Inserted!');
      COMMIT;
   END;


   logger_pkg.set_code_location (
      'TRUNC LEGO_CONTACT_ADDRESS_GTT FOR UPDATE LOGIC');
   LOGGER_PKG.INFO (
      'TRUNC LEGO_CONTACT_ADDRESS_GTT TO UPDATE THE NULL ADDRESS_GUIDs...');

   EXECUTE IMMEDIATE 'TRUNCATE TABLE LEGO_CONTACT_ADDRESS_GTT';

   logger_pkg.info (
      'TRUNC LEGO_CONTACT_ADDRESS_GTT TO UPDATE THE NULL ADDRESS_GUIDs... - DONE!',
      TRUE);



   logger_pkg.set_code_location ('INSERT DATA INTO LEGO_CONTACT_ADDRESS_GTT');
   LOGGER_PKG.INFO ('INSERT DATA INTO LEGO_CONTACT_ADDRESS_GTT...');

   -- Update the NULL ADDRESS_GUIDs
   DECLARE
      CURSOR null_guid_address_id_cur
      IS
         SELECT                        /*+ index(LEGO_CONTACT_ADDRESS_FI01) */
               LCA.ADDRESS_ID
           FROM lego_contact_address lca
          WHERE NVL2 (LCA.ADDRESS_GUID, NULL, 1) = 1;
   BEGIN
      v_int := 0;

      FOR null_guid_address_id_rec IN null_guid_address_id_cur
      LOOP
         INSERT INTO lego_contact_address_gtt
            SELECT                                       /*+ parallel (la,4)*/
                  CA.CONTACT_INFO_ID,
                   CA.ADDRESS_TYPE,
                   CA.ADDRESS_ID,
                   la.address_guid
              FROM lego_address_stage_vw a,
                   lego_address la,
                   lego_contact_address ca
             WHERE NVL (la.standard_place_desc, 'NULL') =
                      NVL (a.standard_place_desc, 'NULL')
                   AND NVL (la.city, 'NULL') = NVL (a.city, 'NULL')
                   AND NVL (la.county, 'NULL') = NVL (a.county, 'NULL')
                   AND NVL (la.state, 'NULL') = NVL (a.state, 'NULL')
                   AND NVL (la.country_id, -1) = NVL (a.country_id, -1)
                   AND NVL (la.line1, 'NULL') = NVL (a.line1, 'NULL')
                   AND NVL (la.line2, 'NULL') = NVL (a.line2, 'NULL')
                   AND NVL (la.line3, 'NULL') = NVL (a.line3, 'NULL')
                   AND NVL (la.line4, 'NULL') = NVL (a.line4, 'NULL')
                   AND NVL (la.postal_code, 'NULL') =
                          NVL (a.postal_code, 'NULL')
                   AND NVL (la.place_id, -1) = NVL (A.PLACE_ID, -1)
                   AND CA.CONTACT_INFO_ID = A.CONTACT_INFO_ID
                   AND CA.ADDRESS_TYPE = A.ADDRESS_TYPE
                   AND CA.ADDRESS_ID = A.ADDRESS_ID
                   AND A.ADDRESS_ID = null_guid_address_id_rec.address_id;

         v_int := v_int + 1;

         IF (MOD ( v_int,
                   1000) = 0)
         THEN
            COMMIT;
         END IF;

         IF (MOD ( v_int,
                   5000) = 0)
         THEN
            LOGGER_PKG.INFO ('5,000 ROWS INSERTED INTO GTT...');
         END IF;
      END LOOP;
   END;

   logger_pkg.info (
         'INSERT DATA INTO LEGO_CONTACT_ADDRESS_GTT... - DONE!  '
      || SQL%ROWCOUNT
      || ' Rows Inserted!',
      TRUE);

   COMMIT;

   logger_pkg.set_code_location ('UPDATE NULL ADDRESS_GUID');
   LOGGER_PKG.INFO ('UPDATE NULL ADDRESS_GUID IN LEGO_CONTACT_ADDRESS...');

   -- Update lego_contact_address with the proper guids
   DECLARE
      CURSOR new_address_guid_cur
      IS
         SELECT GTT.ADDRESS_ID,
                GTT.ADDRESS_TYPE,
                GTT.CONTACT_INFO_ID,
                GTT.ADDRESS_GUID
           FROM lego_contact_address_gtt gtt;
   BEGIN
      FOR new_address_guid_rec IN new_address_guid_cur
      LOOP
         UPDATE lego_contact_address ca
            SET CA.ADDRESS_GUID = NEW_ADDRESS_GUID_REC.ADDRESS_GUID
          WHERE     CA.ADDRESS_ID = NEW_ADDRESS_GUID_REC.ADDRESS_ID
                AND CA.ADDRESS_TYPE = NEW_ADDRESS_GUID_REC.ADDRESS_TYPE
                AND CA.CONTACT_INFO_ID = NEW_ADDRESS_GUID_REC.CONTACT_INFO_ID
                AND CA.ADDRESS_GUID IS NULL;
      END LOOP;


      logger_pkg.info (
            'UPDATE NULL ADDRESS_GUID IN LEGO_CONTACT_ADDRESS... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);

      COMMIT;
   END;

   logger_pkg.set_code_location (
      'UPDATE NULL ADDRESS_GUID FOR ALL NULL ADDRESS');
   LOGGER_PKG.INFO (
      'UPDATE NULL ADDRESS_GUID FOR ALL NULL ADDRESS COLUMNS...');

   -- All NULL addresses are not captured in the insert into lego_contact_address_gtt
   -- update these address_guids with the all NULL address_guid
   DECLARE
      CURSOR all_null_address_cur
      IS
         SELECT                        /*+ index(LEGO_CONTACT_ADDRESS_FI01) */
               ca.ADDRESS_ID,
                ca.ADDRESS_TYPE,
                ca.CONTACT_INFO_ID
           FROM lego_contact_address ca,
                address a
          WHERE     NVL2 (CA.ADDRESS_GUID, NULL, 1) = 1
                AND ca.address_id = a.address_id
                AND ca.address_type = a.name
                AND a.address_type = 'P'
                AND a.contact_info_fk = ca.CONTACT_INFO_ID
                AND a.line1 IS NULL
                AND a.line2 IS NULL
                AND a.line3 IS NULL
                AND a.line4 IS NULL
                AND a.city IS NULL
                AND a.postal_code IS NULL
                AND a.country IS NULL
                AND a.place_fk IS NULL;

      v_null_address_guid   RAW (16);
   BEGIN
      SELECT MIN (address_guid) address_guid
        INTO v_null_address_guid
        FROM lego_address a
       WHERE     a.line1 IS NULL
             AND a.line2 IS NULL
             AND a.line3 IS NULL
             AND a.line4 IS NULL
             AND a.city IS NULL
             AND a.postal_code IS NULL
             AND a.country IS NULL
             AND a.place_id IS NULL
             AND a.country_id IS NULL
             AND a.country_code IS NULL
             AND a.state IS NULL
             AND a.standard_place_desc IS NULL
             AND a.county IS NULL;

      v_int := 0;

      FOR all_null_address_rec IN all_null_address_cur
      LOOP
         UPDATE lego_contact_address ca
            SET ca.ADDRESS_GUID = v_null_address_guid
          WHERE     ca.ADDRESS_ID = all_null_address_rec.ADDRESS_ID
                AND ca.ADDRESS_TYPE = all_null_address_rec.ADDRESS_TYPE
                AND ca.CONTACT_INFO_ID = all_null_address_rec.CONTACT_INFO_ID
                AND ca.ADDRESS_GUID IS NULL;

         v_int := v_int + 1;

         IF (MOD ( v_int,
                   1000) = 0)
         THEN
            COMMIT;
         END IF;
      END LOOP;


      logger_pkg.info (
         'UPDATE NULL ADDRESS_GUID FOR ALL NULL ADDRESS COLUMNS... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);

      COMMIT;
   END;


   -- Begin updating the Business Org values with an undefined value (-99)

   logger_pkg.set_code_location ('UPDATE BUYER ORG VIA BUSINESS ORG');
   LOGGER_PKG.INFO ('UPDATE BUYER ORG VIA BUSINESS ORG...');

   -- Update the Buyer Org using the Business Org relationship
   DECLARE
      CURSOR buyer_org_via_bus_org_cur
      IS
         SELECT BO.BUSINESS_ORGANIZATION_ID,
                CA.CONTACT_INFO_ID,
                CA.ADDRESS_TYPE
           FROM lego_contact_address ca,
                BUSINESS_ORGANIZATION bo
          WHERE CA.CONTACT_INFO_ID = BO.CONTACT_INFORMATION_FK
                AND CA.BUYER_ORG_ID = -99;
   BEGIN
      FOR buyer_org_via_bus_org_rec IN buyer_org_via_bus_org_cur
      LOOP
         UPDATE lego_contact_address ca
            SET ca.BUYER_ORG_ID = buyer_org_via_bus_org_rec.BUSINESS_ORGANIZATION_ID
          WHERE CA.CONTACT_INFO_ID =
                   buyer_org_via_bus_org_rec.CONTACT_INFO_ID
                AND CA.ADDRESS_TYPE = buyer_org_via_bus_org_rec.ADDRESS_TYPE;
      END LOOP;


      logger_pkg.info (
            'UPDATE BUYER ORG VIA BUSINESS ORG... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);
      COMMIT;
   END;


   logger_pkg.set_code_location ('UPDATE BUYER ORG VIA ASSIGNMENT');
   LOGGER_PKG.INFO ('UPDATE BUYER ORG VIA ASSIGNMENT...');

   -- Update the Buyer Org using the Assignment relationship
   DECLARE
      CURSOR buyer_org_via_assignment_cur
      IS
         SELECT DISTINCT BO.BUSINESS_ORGANIZATION_ID,
                         CA.CONTACT_INFO_ID,
                         CA.ADDRESS_TYPE
           FROM lego_contact_address ca,
                assignment_edition ae,
                ASSIGNMENT_CONTINUITY ac,
                FIRM_ROLE fr,
                BUSINESS_ORGANIZATION bo
          WHERE     CA.CONTACT_INFO_ID = AE.RESOURCE_ONSITE_FK
                AND AE.ASSIGNMENT_CONTINUITY_FK = AC.ASSIGNMENT_CONTINUITY_ID
                AND AC.OWNING_BUYER_FIRM_FK = FR.FIRM_ID
                AND FR.BUSINESS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
                AND CA.BUYER_ORG_ID = -99;
   BEGIN
      FOR buyer_org_via_assignment_rec IN buyer_org_via_assignment_cur
      LOOP
         UPDATE lego_contact_address ca
            SET ca.BUYER_ORG_ID = buyer_org_via_assignment_rec.BUSINESS_ORGANIZATION_ID
          WHERE CA.CONTACT_INFO_ID =
                   buyer_org_via_assignment_rec.CONTACT_INFO_ID
                AND CA.ADDRESS_TYPE =
                       buyer_org_via_assignment_rec.ADDRESS_TYPE;
      END LOOP;


      logger_pkg.info (
            'UPDATE BUYER ORG VIA ASSIGNMENT... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);
      COMMIT;
   END;


   logger_pkg.set_code_location ('UPDATE BUYER ORG VIA CONTRACT');
   LOGGER_PKG.INFO ('UPDATE BUYER ORG VIA CONTRACT...');

   -- Update the Buyer Org using the Contract relationship
   DECLARE
      CURSOR buyer_org_via_contract_cur
      IS
         SELECT BO.BUSINESS_ORGANIZATION_ID,
                CA.CONTACT_INFO_ID,
                CA.ADDRESS_TYPE
           FROM lego_contact_address ca,
                contract_party_term cpt,
                CONTRACT_PARTY cp,
                business_organization bo
          WHERE     CA.CONTACT_INFO_ID = CPT.CONTACT_INFO_FK
                AND CPT.CONTRACT_PARTY_FK = CP.CONTRACT_PARTY_ID
                AND CP.LEGAL_ENTITY_FK = BO.BUSINESS_ORGANIZATION_ID
                AND CA.BUYER_ORG_ID = -99;
   BEGIN
      FOR buyer_org_via_contract_rec IN buyer_org_via_contract_cur
      LOOP
         UPDATE lego_contact_address ca
            SET ca.BUYER_ORG_ID = buyer_org_via_contract_rec.BUSINESS_ORGANIZATION_ID
          WHERE CA.CONTACT_INFO_ID =
                   buyer_org_via_contract_rec.CONTACT_INFO_ID
                AND CA.ADDRESS_TYPE = buyer_org_via_contract_rec.ADDRESS_TYPE;
      END LOOP;


      logger_pkg.info (
            'UPDATE BUYER ORG VIA CONTRACT... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);
      COMMIT;
   END;


   logger_pkg.set_code_location ('UPDATE BUYER ORG VIA BUYER');
   LOGGER_PKG.INFO ('UPDATE BUYER ORG VIA BUYER...');

   -- Update the Buyer Org using the Buyer relationship
   DECLARE
      CURSOR buyer_org_via_buyer_cur
      IS
         SELECT BO.BUSINESS_ORGANIZATION_ID,
                CA.CONTACT_INFO_ID,
                CA.ADDRESS_TYPE
           FROM lego_contact_address ca,
                invoiced_buyer_supplier ibs,
                BUSINESS_ORGANIZATION bo
          WHERE     CA.CONTACT_INFO_ID = IBS.BUYER_BUS_ORG_BILL_TO_ADDR_FK
                AND IBS.BUYER_BUS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
                AND CA.BUYER_ORG_ID = -99;
   BEGIN
      FOR buyer_org_via_buyer_rec IN buyer_org_via_buyer_cur
      LOOP
         UPDATE lego_contact_address ca
            SET ca.BUYER_ORG_ID = buyer_org_via_buyer_rec.BUSINESS_ORGANIZATION_ID
          WHERE CA.CONTACT_INFO_ID = buyer_org_via_buyer_rec.CONTACT_INFO_ID
                AND CA.ADDRESS_TYPE = buyer_org_via_buyer_rec.ADDRESS_TYPE;
      END LOOP;


      logger_pkg.info (
            'UPDATE BUYER ORG VIA BUYER... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);
      COMMIT;
   END;

   logger_pkg.set_code_location ('UPDATE BUYER ORG VIA SUPPLIER');
   LOGGER_PKG.INFO ('UPDATE BUYER ORG VIA SUPPLIER...');

   -- Update the Buyer Org using the Supplier relationship
   DECLARE
      CURSOR buyer_org_via_supplier_cur
      IS
         SELECT BO.BUSINESS_ORGANIZATION_ID,
                CA.CONTACT_INFO_ID,
                CA.ADDRESS_TYPE
           FROM lego_contact_address ca,
                invoiced_buyer_supplier ibs,
                BUSINESS_ORGANIZATION bo
          WHERE     CA.CONTACT_INFO_ID = IBS.SUPPLIER_BUS_ORG_PYMNT_ADDR_FK
                AND IBS.BUYER_BUS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
                AND CA.BUYER_ORG_ID = -99;
   BEGIN
      FOR buyer_org_via_supplier_rec IN buyer_org_via_supplier_cur
      LOOP
         UPDATE lego_contact_address ca
            SET ca.BUYER_ORG_ID = buyer_org_via_supplier_rec.BUSINESS_ORGANIZATION_ID
          WHERE CA.CONTACT_INFO_ID =
                   buyer_org_via_supplier_rec.CONTACT_INFO_ID
                AND CA.ADDRESS_TYPE = buyer_org_via_supplier_rec.ADDRESS_TYPE;
      END LOOP;


      logger_pkg.info (
            'UPDATE BUYER ORG VIA SUPPLIER... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);
      COMMIT;
   END;


   logger_pkg.set_code_location ('UPDATE BUYER ORG VIA PERSON');
   LOGGER_PKG.INFO ('UPDATE BUYER ORG VIA PERSON...');

   -- Update the Buyer Org using the Person relationship
   DECLARE
      CURSOR buyer_org_via_person_cur
      IS
         SELECT DISTINCT BO.BUSINESS_ORGANIZATION_ID,
                         CA.CONTACT_INFO_ID,
                         CA.ADDRESS_TYPE
           FROM lego_contact_address ca,
                BUSINESS_ORGANIZATION bo,
                PERSON per
          WHERE CA.CONTACT_INFO_ID = PER.CONTACT_INFO_FK
                AND per.BUSINESS_ORGANIZATION_FK =
                       BO.BUSINESS_ORGANIZATION_ID
                AND CA.BUYER_ORG_ID = -99;
   BEGIN
      FOR buyer_org_via_person_rec IN buyer_org_via_person_cur
      LOOP
         UPDATE lego_contact_address ca
            SET ca.BUYER_ORG_ID = buyer_org_via_person_rec.BUSINESS_ORGANIZATION_ID
          WHERE CA.CONTACT_INFO_ID = buyer_org_via_person_rec.CONTACT_INFO_ID
                AND CA.ADDRESS_TYPE = buyer_org_via_person_rec.ADDRESS_TYPE;
      END LOOP;


      logger_pkg.info (
            'UPDATE BUYER ORG VIA PERSON... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);
      COMMIT;
   END;

   logger_pkg.set_code_location ('UPDATE BUYER ORG VIA EMPLOYMENT TERM');
   LOGGER_PKG.INFO ('UPDATE BUYER ORG VIA EMPLOYMENT TERM...');

   -- Update the Buyer Org using the Employment Term relationship
   DECLARE
      CURSOR buyer_org_via_emp_term_cur
      IS
         SELECT DISTINCT BO.BUSINESS_ORGANIZATION_ID,
                         CA.CONTACT_INFO_ID,
                         CA.ADDRESS_TYPE
           FROM lego_contact_address ca,
                BUSINESS_ORGANIZATION bo,
                employment_term et,
                job j,
                buyer_firm bf,
                firm_role fr
          WHERE     CA.CONTACT_INFO_ID = ET.WORK_ADDRESS_FK
                AND ET.JOB_FK = J.JOB_ID
                AND J.BUYER_FIRM_FK = BF.FIRM_ID
                AND BF.FIRM_ID = FR.FIRM_ID
                AND FR.BUSINESS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
                AND CA.BUYER_ORG_ID = -99;
   BEGIN
      FOR buyer_org_via_emp_term_rec IN buyer_org_via_emp_term_cur
      LOOP
         UPDATE lego_contact_address ca
            SET ca.BUYER_ORG_ID = buyer_org_via_emp_term_rec.BUSINESS_ORGANIZATION_ID
          WHERE CA.CONTACT_INFO_ID =
                   buyer_org_via_emp_term_rec.CONTACT_INFO_ID
                AND CA.ADDRESS_TYPE = buyer_org_via_emp_term_rec.ADDRESS_TYPE;
      END LOOP;


      logger_pkg.info (
            'UPDATE BUYER ORG VIA EMPLOYMENT TERM... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);
      COMMIT;
   END;


   logger_pkg.set_code_location ('UPDATE BUYER ORG VIA ASSIGNMENT TERM');
   LOGGER_PKG.INFO ('UPDATE BUYER ORG VIA ASSIGNMENT TERM...');

   -- Update the Buyer Org using the Assignment Term relationship
   DECLARE
      CURSOR buyer_org_via_asgn_term_cur
      IS
         SELECT DISTINCT BO.BUSINESS_ORGANIZATION_ID,
                         CA.CONTACT_INFO_ID,
                         CA.ADDRESS_TYPE
           FROM lego_contact_address ca,
                BUSINESS_ORGANIZATION bo,
                work_assignment_term wat,
                contract_term ct,
                contract_version CV,
                contract c,
                buyer_supplier_agreement bsa,
                buyer_firm bf,
                firm_role fr
          WHERE     CA.CONTACT_INFO_ID = wat.work_location_fk
                AND WAT.CONTRACT_TERM_ID = CT.CONTRACT_TERM_ID
                AND CT.CONTRACT_VERSION_FK = CV.CONTRACT_VERSION_ID
                AND CV.CONTRACT_FK = C.CONTRACT_ID
                AND C.CONTRACT_ID = BSA.CONTRACT_ID
                AND BSA.BUYER_FIRM_FK = BF.FIRM_ID
                AND BF.FIRM_ID = FR.FIRM_ID
                AND FR.BUSINESS_ORG_FK = BO.BUSINESS_ORGANIZATION_ID
                AND CA.BUYER_ORG_ID = -99;
   BEGIN
      FOR buyer_org_via_asgn_term_rec IN buyer_org_via_asgn_term_cur
      LOOP
         UPDATE lego_contact_address ca
            SET ca.BUYER_ORG_ID = buyer_org_via_asgn_term_rec.BUSINESS_ORGANIZATION_ID
          WHERE CA.CONTACT_INFO_ID =
                   buyer_org_via_asgn_term_rec.CONTACT_INFO_ID
                AND CA.ADDRESS_TYPE =
                       buyer_org_via_asgn_term_rec.ADDRESS_TYPE;
      END LOOP;


      logger_pkg.info (
            'UPDATE BUYER ORG VIA ASSIGNMENT TERM... - DONE!  '
         || SQL%ROWCOUNT
         || ' Rows Updated!',
         TRUE);
      COMMIT;
   END;


   logger_pkg.set_code_location ('UPDATE REMAINING BUYER ORG TO DEFAULT');
   LOGGER_PKG.INFO ('UPDATE REMAINING BUYER ORG TO DEFAULT...');

   -- After we have figured out all the Business Orgs we can...we set the remaining
   -- unknowns (-99) to -1
   UPDATE lego_contact_address
      SET BUYER_ORG_ID = -1
    WHERE BUYER_ORG_ID = -99;


   logger_pkg.info (
         'UPDATE REMAINING BUYER ORG TO DEFAULT... - DONE!  '
      || SQL%ROWCOUNT
      || ' Rows Updated!',
      TRUE);
   COMMIT;

   logger_pkg.set_code_location ('UPDATE ADDRESS TABLE WITH ADDRESS_GUID');
   LOGGER_PKG.INFO ('UPDATE ADDRESS TABLE WITH ADDRESS_GUID...');

   -- Update the Address Tables NULL LEGO_ADDRESS_GUIDs
   DECLARE
      CURSOR null_guids_cur
      IS
         SELECT address_id
           FROM address
          WHERE     address_type = 'P'
                AND contact_info_fk <> -1
                AND lego_address_guid IS NULL;

      v_lego_address_guid   RAW (16) := NULL;
   BEGIN
      v_int := 0;

      FOR null_guids_rec IN null_guids_cur
      LOOP
         BEGIN
            SELECT address_guid
              INTO v_lego_address_guid
              FROM lego_contact_address
             WHERE address_id = null_guids_rec.address_id;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               v_lego_address_guid := NULL;
         END;

         IF v_lego_address_guid IS NOT NULL
         THEN
            lego_guid_maintenance.update_lego_address_guid (
               null_guids_rec.address_id,
               v_lego_address_guid);
         END IF;

         v_lego_address_guid := NULL;

         v_int := v_int + 1;

         IF (MOD ( v_int,
                   1000) = 0)
         THEN
            COMMIT;
         END IF;
      END LOOP;

      COMMIT;

      logger_pkg.info ( 'UPDATE ADDRESS TABLE WITH ADDRESS_GUID... - DONE!',
                        TRUE);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         LOGGER_PKG.INFO ( 'NO_DATA_FOUND...ADDRESS_ID NOT FOUND IN LEGO_CONTACT_ADDRESS TABLE');
   END;

   logger_pkg.unset_source (v_source);
EXCEPTION
   WHEN OTHERS
   THEN
      logger_pkg.fatal ( 'ROLLBACK',
                         SQLCODE,
                         SQLERRM);
      logger_pkg.unset_source (v_source);
      RAISE;
END;
}';

END lego_address_refresh;

PROCEDURE load_lego_time_to_fill (p_table_name IN VARCHAR2) AS  
/*******************************************************************************
 *PROCEDURE NAME : load_lego_time_to_fill
 *DATE CREATED   : September 05, 2013
 *AUTHOR         : Joe Pullifrone
 *PURPOSE        : This procedure load the LEGO_TIME_TO_FILL base table.  Which
 *                 table to load will be determined by the value passed IN as
 *                 p_table_name. IQN-7609 - Rel 11.4
 *MODIFICATIONS: 13 Sep 2013 J.Pullifrone removed AS OF SCN wrapping around entire SQL and added
 *               it only were needed.  Release 11.4 
 *               19 Nov 2013 M.Dunlap   added time_to_select, match_create_date and source_method_name_fk fields
 *               01 Jan 2014 E.Clark - changed logic on how to determine if the day is a SAT or SUN,
 *                                   - simplified the join logic to the Assigment_edition table, 
 *                                   - updated logic to use lego table data already being captured for various assignment dates
 *                                   - changed source of job approval date field from approval_process to lego_approval table, partition=Job
 *                                   - changed source of match_dates from event tables to lego_match
 *                                   - removed two unnecessary joins to business_organization (buyer, supplier)
 *                                   - fixed multiple issues with SOURCING_METHOD, CANDIDATE_SOURCING_METHOD 
 *                                   - changed from PARALLEL 2 to 4 - Release 12.0
 *               10 Feb 2014 E.Clark - IQN-13086 - removed this where clause: ac.work_order_fk IS NOT NULL (to get the EA assignments)
 *                                   - removed MIN on assign_start_date because the lego tables only have 1 row per assignment_continuity_id already 
 *                                   - added filter for WHERE sourcing_method IN ('Requisitioned','Long Term')
 *                                   - Removed MIN grouping on Job table (not necessary).
 *                                   - added field Assignment_type (distinct values are WO,EA)  - Release 12.0.1
 *******************************************************************************/  
  
  v_source                      VARCHAR2(61) := 'load_lego_time_to_fill';
  v_sql_1                       CLOB;
  v_sql_2                       CLOB;
  v_assignment_wo_base_tbl      VARCHAR2(30) := most_recently_loaded_table('LEGO_ASSIGNMENT_WO');
  v_assignment_ea_base_tbl      VARCHAR2(30) := most_recently_loaded_table('LEGO_ASSIGNMENT_EA');
  v_assignment_match_base_tbl   VARCHAR2(30) := most_recently_loaded_table('LEGO_MATCH');
  v_storage                     lego_refresh.exadata_storage_clause%TYPE;
  
  BEGIN
  
    logger_pkg.set_level('DEBUG');
    logger_pkg.set_source(v_source);

    logger_pkg.set_code_location('Get storage info for LEGO_TIME_TO_FILL');
    SELECT exadata_storage_clause
      INTO v_storage
      FROM lego_refresh
     WHERE object_name = 'LEGO_TIME_TO_FILL';    

    logger_pkg.set_code_location('Build table '||p_table_name);
    
    v_sql_1 := 'CREATE TABLE '||p_table_name||' '||v_storage||'  AS';
    
    v_sql_1 := v_sql_1|| 
          q'{ 
            WITH cal_date_weekend
              AS
              (SELECT TO_DATE('01-JAN-1999','DD-MON-YYYY') + daynum AS day_dt, 
                      TO_CHAR(TO_DATE('01-JAN-1999','DD-MON-YYYY') + daynum,'FMDAY') AS DOW
                FROM (SELECT ROWNUM - 1 AS daynum
                        FROM dual
                     CONNECT BY ROWNUM < SYSDATE + 360 - TO_DATE('01-JAN-1999','DD-MON-YYYY') + 1 )
               WHERE TO_CHAR(TO_DATE('01-JAN-1999','DD-MON-YYYY') + daynum,'FMDAY') IN ('SATURDAY','SUNDAY'))
              SELECT /*+ PARALLEL(4) */
                     BUYER_ORG_ID,
                     SUPPLIER_ORG_ID,
                     JOB_ID,
                     ASSIGNMENT_CONTINUITY_ID,
                     CANDIDATE_ID,
                     JOB_CATEGORY_ID,
                     JOB_CREATED_DATE,
                     JOB_APPROVED_DATE,
                     JOB_RELEASED_TO_SUPP_DATE,
                     SUBMIT_MATCH_DATE,
                     FWD_TO_HM_DATE,
                     CANDIDATE_INTERVIEW_DATE,
                     WO_RELEASE_TO_SUPP_DATE,
                     WO_ACCEPT_BY_SUPP_DATE,
                     ASSIGNMENT_CREATED_DATE,
                     ASSIGNMENT_EFFECT_DATE,
                     ASSIGNMENT_START_DATE,
                     (CASE
                         WHEN job_created_date <= job_approved_date
                         THEN
                            (SELECT ROUND(job_approved_date - job_created_date - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE job_created_date <= day_dt
                                AND job_approved_date > day_dt)
                         WHEN job_created_date > job_approved_date
                         THEN
                           (SELECT (ROUND(job_approved_date - job_created_date + COUNT(*),2))
                               FROM cal_date_weekend
                              WHERE job_created_date >= day_dt
                                AND job_approved_date < day_dt)
                         ELSE
                            NULL
                      END)
                        tt_job_approval,
                     (CASE
                         WHEN COALESCE(JOB_CREATED_DATE, JOB_APPROVED_DATE) <= JOB_RELEASED_TO_SUPP_DATE
                         THEN
                            (SELECT ROUND(JOB_RELEASED_TO_SUPP_DATE - COALESCE(JOB_CREATED_DATE, JOB_APPROVED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(JOB_CREATED_DATE, JOB_APPROVED_DATE) <= day_dt
                                AND JOB_RELEASED_TO_SUPP_DATE > day_dt)
                         WHEN COALESCE(JOB_CREATED_DATE, JOB_APPROVED_DATE) > JOB_RELEASED_TO_SUPP_DATE
                         THEN
                            (SELECT ROUND(JOB_RELEASED_TO_SUPP_DATE - COALESCE(JOB_CREATED_DATE, JOB_APPROVED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(JOB_CREATED_DATE, JOB_APPROVED_DATE) >= day_dt
                                AND JOB_RELEASED_TO_SUPP_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TT_JOB_RELEASED,
                     (CASE
                         WHEN COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) <= SUBMIT_MATCH_DATE
                         THEN
                            (SELECT ROUND(SUBMIT_MATCH_DATE - COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) <= day_dt
                                AND SUBMIT_MATCH_DATE > day_dt)
                         WHEN COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) > SUBMIT_MATCH_DATE
                         THEN
                            (SELECT ROUND(SUBMIT_MATCH_DATE - COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) >= day_dt
                                AND SUBMIT_MATCH_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TT_MATCH_FOR_SUPP,
                     (CASE
                         WHEN COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) <= FWD_TO_HM_DATE
                         THEN
                            (SELECT ROUND(FWD_TO_HM_DATE - COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) <= day_dt
                                AND FWD_TO_HM_DATE > day_dt)
                         WHEN COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) > FWD_TO_HM_DATE
                         THEN
                            (SELECT ROUND(FWD_TO_HM_DATE - COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) >= day_dt
                                AND FWD_TO_HM_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TT_FWD_TO_HM,
                     (CASE
                         WHEN COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                              JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) <= ASSIGNMENT_CREATED_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_CREATED_DATE - COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                                    JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) <= day_dt
                                AND ASSIGNMENT_CREATED_DATE > day_dt)
                         WHEN COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                              JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) > ASSIGNMENT_CREATED_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_CREATED_DATE - COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                                    JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) >= day_dt
                                AND ASSIGNMENT_CREATED_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TT_CREATE_ASSIGNMENT,
                     (CASE
                         WHEN JOB_CREATED_DATE <= ASSIGNMENT_START_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_START_DATE - JOB_CREATED_DATE - COUNT(*), 2)
                               FROM cal_date_weekend
                              WHERE JOB_CREATED_DATE <= day_dt
                                AND ASSIGNMENT_START_DATE > day_dt)
                         WHEN JOB_CREATED_DATE > ASSIGNMENT_START_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_START_DATE - JOB_CREATED_DATE + COUNT(*), 2)
                               FROM cal_date_weekend
                              WHERE JOB_CREATED_DATE >= day_dt
                                AND ASSIGNMENT_START_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TT_START_ASSIGNMENT,
                     (CASE
                         WHEN JOB_CREATED_DATE <= ASSIGNMENT_EFFECT_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_EFFECT_DATE - JOB_CREATED_DATE - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE JOB_CREATED_DATE <= day_dt
                                AND ASSIGNMENT_EFFECT_DATE > day_dt)
                         WHEN JOB_CREATED_DATE > ASSIGNMENT_EFFECT_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_EFFECT_DATE - JOB_CREATED_DATE + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE JOB_CREATED_DATE >= day_dt
                                AND ASSIGNMENT_EFFECT_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TT_EFFECTIVE_ASSIGNMENT,
                     (CASE
                         WHEN JOB_APPROVED_DATE <= ASSIGNMENT_CREATED_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_CREATED_DATE - JOB_APPROVED_DATE - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE JOB_APPROVED_DATE <= day_dt
                                AND ASSIGNMENT_CREATED_DATE > day_dt)
                         WHEN JOB_APPROVED_DATE > ASSIGNMENT_CREATED_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_CREATED_DATE - JOB_APPROVED_DATE + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE JOB_APPROVED_DATE >= day_dt
                                AND ASSIGNMENT_CREATED_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TT_FILL_ASSIGNMENT,
                     (CASE
                         WHEN JOB_CREATED_DATE <= JOB_APPROVED_DATE
                         THEN
                            (SELECT ROUND(JOB_APPROVED_DATE - JOB_CREATED_DATE - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE JOB_CREATED_DATE <= day_dt
                                AND JOB_APPROVED_DATE > day_dt)
                         WHEN JOB_CREATED_DATE > JOB_APPROVED_DATE
                         THEN
                            (SELECT ROUND(JOB_APPROVED_DATE - JOB_CREATED_DATE + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE JOB_CREATED_DATE >= day_dt
                                AND JOB_APPROVED_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X1,
                     (CASE
                         WHEN COALESCE(JOB_APPROVED_DATE, JOB_CREATED_DATE) <= JOB_RELEASED_TO_SUPP_DATE
                         THEN
                            (SELECT ROUND(JOB_RELEASED_TO_SUPP_DATE - COALESCE(JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(JOB_APPROVED_DATE, JOB_CREATED_DATE) <= day_dt
                                AND JOB_RELEASED_TO_SUPP_DATE > day_dt)
                         WHEN COALESCE(JOB_APPROVED_DATE, JOB_CREATED_DATE) > JOB_RELEASED_TO_SUPP_DATE
                         THEN
                            (SELECT ROUND(JOB_RELEASED_TO_SUPP_DATE - COALESCE(JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(JOB_APPROVED_DATE, JOB_CREATED_DATE) >= day_dt
                                AND JOB_RELEASED_TO_SUPP_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X2,
                     (CASE
                         WHEN COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) <= SUBMIT_MATCH_DATE
                         THEN
                            (SELECT ROUND(SUBMIT_MATCH_DATE - COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) <= day_dt
                                AND SUBMIT_MATCH_DATE > day_dt)
                         WHEN COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) > SUBMIT_MATCH_DATE
                         THEN
                            (SELECT ROUND(SUBMIT_MATCH_DATE - COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) >= day_dt
                                AND SUBMIT_MATCH_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X3,
                     (CASE
                         WHEN COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) <= FWD_TO_HM_DATE
                         THEN
                            (SELECT ROUND(FWD_TO_HM_DATE - COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) <= day_dt
                                AND FWD_TO_HM_DATE > day_dt)
                         WHEN COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) > FWD_TO_HM_DATE
                         THEN
                            (SELECT ROUND(FWD_TO_HM_DATE - COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) >= day_dt
                                AND FWD_TO_HM_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X4,
                     (CASE
                         WHEN COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                              JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) <= CANDIDATE_INTERVIEW_DATE
                         THEN
                            (SELECT ROUND(CANDIDATE_INTERVIEW_DATE - COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                                    JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) <= day_dt
                                AND CANDIDATE_INTERVIEW_DATE > day_dt)
                         WHEN COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                              JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) > CANDIDATE_INTERVIEW_DATE
                         THEN
                            (SELECT ROUND(CANDIDATE_INTERVIEW_DATE - COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                                    JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) >= day_dt
                                AND CANDIDATE_INTERVIEW_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X5, }';
          v_sql_2 := q'{                        
                     (CASE
                         WHEN COALESCE(CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                              SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) <= ASSIGNMENT_CREATED_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_CREATED_DATE - COALESCE(CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                                    SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) <= day_dt
                                AND ASSIGNMENT_CREATED_DATE > day_dt)
                         WHEN COALESCE(CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                              SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) > ASSIGNMENT_CREATED_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_CREATED_DATE - COALESCE(CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                                    SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) >= day_dt
                                AND ASSIGNMENT_CREATED_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X6,
                  (CASE
                         WHEN COALESCE(ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE,
                              FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) <= WO_RELEASE_TO_SUPP_DATE
                         THEN
                            (SELECT ROUND(WO_RELEASE_TO_SUPP_DATE - COALESCE(ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(ASSIGNMENT_CREATED_DATE,
                                    CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                                    SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) <= day_dt
                                AND WO_RELEASE_TO_SUPP_DATE > day_dt)
                         WHEN COALESCE(ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE,
                              FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) > WO_RELEASE_TO_SUPP_DATE
                         THEN
                            (SELECT ROUND(WO_RELEASE_TO_SUPP_DATE - COALESCE(ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(ASSIGNMENT_CREATED_DATE,
                                    CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                                    SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) >= day_dt
                                AND WO_RELEASE_TO_SUPP_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X7,
                     (CASE
                         WHEN COALESCE(WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE,
                              CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                              JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) <= WO_ACCEPT_BY_SUPP_DATE
                         THEN
                            (SELECT ROUND(WO_ACCEPT_BY_SUPP_DATE - COALESCE(WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(WO_RELEASE_TO_SUPP_DATE,
                                    ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE,
                                    FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                                    JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) <= day_dt
                                AND WO_ACCEPT_BY_SUPP_DATE > day_dt)
                         WHEN COALESCE(WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE,
                              CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                              JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                              JOB_CREATED_DATE) > WO_ACCEPT_BY_SUPP_DATE
                         THEN
                            (SELECT ROUND(WO_ACCEPT_BY_SUPP_DATE - COALESCE(WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(WO_RELEASE_TO_SUPP_DATE,
                                    ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE,
                                    FWD_TO_HM_DATE, SUBMIT_MATCH_DATE,
                                    JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE,
                                    JOB_CREATED_DATE) >= day_dt
                                AND WO_ACCEPT_BY_SUPP_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X8,
                     (CASE
                         WHEN COALESCE(WO_ACCEPT_BY_SUPP_DATE, WO_RELEASE_TO_SUPP_DATE,
                              ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE,
                              FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) <= ASSIGNMENT_EFFECT_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_EFFECT_DATE - COALESCE(WO_ACCEPT_BY_SUPP_DATE, WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(WO_ACCEPT_BY_SUPP_DATE,
                                    WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE,
                                    CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                                    SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) <= day_dt
                                AND ASSIGNMENT_EFFECT_DATE > day_dt)
                         WHEN COALESCE(WO_ACCEPT_BY_SUPP_DATE, WO_RELEASE_TO_SUPP_DATE,
                              ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE,
                              FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) > ASSIGNMENT_EFFECT_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_EFFECT_DATE - COALESCE(WO_ACCEPT_BY_SUPP_DATE, WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(WO_ACCEPT_BY_SUPP_DATE,
                                    WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE,
                                    CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                                    SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) >= day_dt
                                AND ASSIGNMENT_EFFECT_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X9A,
                     (CASE
                         WHEN COALESCE(WO_ACCEPT_BY_SUPP_DATE, WO_RELEASE_TO_SUPP_DATE,
                              ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE,
                              FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) <= ASSIGNMENT_START_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_START_DATE - COALESCE(WO_ACCEPT_BY_SUPP_DATE, WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(WO_ACCEPT_BY_SUPP_DATE,
                                    WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE,
                                    CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                                    SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) <= day_dt
                                AND ASSIGNMENT_START_DATE > day_dt)
                         WHEN COALESCE(WO_ACCEPT_BY_SUPP_DATE, WO_RELEASE_TO_SUPP_DATE,
                              ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE,
                              FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                              JOB_APPROVED_DATE, JOB_CREATED_DATE) > ASSIGNMENT_START_DATE
                         THEN
                            (SELECT ROUND(ASSIGNMENT_START_DATE - COALESCE(WO_ACCEPT_BY_SUPP_DATE, WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE, CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE, SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE, JOB_APPROVED_DATE, JOB_CREATED_DATE) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(WO_ACCEPT_BY_SUPP_DATE,
                                    WO_RELEASE_TO_SUPP_DATE, ASSIGNMENT_CREATED_DATE,
                                    CANDIDATE_INTERVIEW_DATE, FWD_TO_HM_DATE,
                                    SUBMIT_MATCH_DATE, JOB_RELEASED_TO_SUPP_DATE,
                                    JOB_APPROVED_DATE, JOB_CREATED_DATE) >= day_dt
                                AND ASSIGNMENT_START_DATE < day_dt)
                         ELSE
                            NULL
                      END)
                        TIME_X9B,
                        TIME_TO_SELECT,
                        MATCH_CREATE_DATE,
                        CANDIDATE_SOURCING_METHOD_ID,
                        CANDIDATE_SOURCING_METHOD,
                        SOURCING_METHOD,
                        ASSIGNMENT_TYPE
                        --> add fields here...
            FROM (WITH appr_dates
                         AS (SELECT *
                               FROM (  SELECT TO_NUMBER(id) job_id,
                                              MIN(date_approved_t_stamp) approved_date
                                         FROM lego_approval
                                        WHERE approvable_type = 'Job'
                                          AND approval_status = 'Approved' 
                                        GROUP BY TO_NUMBER(id))),
                       match_dates
                         AS (SELECT *
                               FROM (  SELECT match_id,
                                              supplier_submitted_date submit_match_date,
                                              pass_candidate_screening_date fwd_to_hm_date,
                                              create_date create_date
                                         FROM }'||v_assignment_match_base_tbl||                                    
                        q'{            )),
                       cand
                         AS (SELECT *
                               FROM (  SELECT m.job_fk, m.job_opportunity_fk,
                                              MAX(ed.timestamp) candidate_interview_date
                                         FROM match AS OF SCN lego_refresh_mgr_pkg.get_scn() m,
                                              match_event_description med,
                                              event_description ed
                                        WHERE med.match_fk = m.match_id
                                          AND ed.identifier = med.identifier
                                          AND ed.event_name_fk = 31013
                                        GROUP BY m.job_fk, m.job_opportunity_fk)),
                       wo_dates
                         AS (SELECT *
                               FROM (  SELECT work_order_id,
                                              MIN(wo_accept_by_supp_date) wo_accept_by_supp_date,
                                              MAX(wo_release_to_supp_date) wo_release_to_supp_date
                                         FROM (SELECT woed.work_order_id work_order_id,
                                                      CASE WHEN ed.EVENT_NAME_FK = 36000 THEN ed.timestamp END wo_accept_by_supp_date,
                                                      CASE WHEN ed.EVENT_NAME_FK = 36007 THEN ed.timestamp END wo_release_to_supp_date
                                                 FROM work_order_event_description woed,
                                                      event_description ed
                                                WHERE woed.IDENTIFIER = ed.IDENTIFIER
                                                  AND ed.event_name_fk IN (36000, 36007))
                                        GROUP BY work_order_id)),
                       assign_eff_date
                         AS (SELECT *
                               FROM (  SELECT aed.assignment_continuity_fk,
                                              MIN(timestamp) assignment_effect_date
                                         FROM event_description ed,
                                              assignment_event_description aed,
                                              event_name en
                                        WHERE ed.identifier = aed.identifier
                                          AND ed.event_name_fk = en.VALUE
                                          AND en.VALUE = 3012
                                        GROUP BY aed.assignment_continuity_fk)),
                       assign_start_date
                         AS (SELECT assignment_continuity_id,
                                    sourcing_method,
                                    assignment_start_dt AS assignment_start_date,
                                    'WO' assignment_type
                               FROM }'||v_assignment_wo_base_tbl||
                        q'{   WHERE sourcing_method IN ('Requisitioned','Long Term') 
                              UNION ALL
                             SELECT assignment_continuity_id,
                                    sourcing_method,
                                    assignment_start_dt AS assignment_start_date,
                                    'EA' assignment_type
                               FROM }'||v_assignment_ea_base_tbl||
                        q'{   WHERE sourcing_method IN ('Requisitioned','Long Term') ),
                       assign_create_date
                         AS (SELECT *
                               FROM (  SELECT ae.assignment_continuity_fk,
                                              MIN(ae.create_date) assignment_created_date
                                         FROM assignment_edition ae
                                        GROUP BY ae.assignment_continuity_fk))
                      SELECT buyer.business_org_fk buyer_org_id,
                             supplier.business_org_fk supplier_org_id, 
                             j.job_id,
                             ae.assignment_continuity_fk assignment_continuity_id, 
                             c.candidate_id,
                             j.job_category_fk job_category_id,
                             j.create_date job_created_date,
                             appr_dates.approved_date job_approved_date,
                             MIN(jo.creation_date) job_released_to_supp_date,
                             m.creation_date submit_match_date,
                             md.fwd_to_hm_date fwd_to_hm_date,
                             cand.candidate_interview_date candidate_interview_date,
                             wod.wo_release_to_supp_date wo_release_to_supp_date,
                             wod.wo_accept_by_supp_date wo_accept_by_supp_date,
                             acd.assignment_created_date,
                             aed.assignment_effect_date assignment_effect_date,
                             asd.assignment_start_date assignment_start_date,
                             ROUND((acd.assignment_created_date - md.fwd_to_hm_date),2) time_to_select,
                             m.creation_date match_create_date,
                             ae.sourcing_method_name_fk   AS candidate_sourcing_method_id,
                             csm_jcl.constant_description AS candidate_sourcing_method,
                             asd.sourcing_method,
                             asd.assignment_type
                        FROM assignment_edition                AS OF SCN lego_refresh_mgr_pkg.get_scn() ae,
                             assignment_continuity             AS OF SCN lego_refresh_mgr_pkg.get_scn() ac,
                             candidate                         AS OF SCN lego_refresh_mgr_pkg.get_scn() c,
                             job                               AS OF SCN lego_refresh_mgr_pkg.get_scn() j,
                             job_opportunity                   AS OF SCN lego_refresh_mgr_pkg.get_scn() jo,
                             match                             AS OF SCN lego_refresh_mgr_pkg.get_scn() m,
                             match_event_description med,
                             match_event_description med1,
                             firm_role                         AS OF SCN lego_refresh_mgr_pkg.get_scn() buyer,
                             firm_role                         AS OF SCN lego_refresh_mgr_pkg.get_scn() supplier,
                             assign_start_date asd,
                             assign_create_date acd,
                             assign_eff_date aed,
                             wo_dates wod,
                             match_dates md,
                             cand,
                             appr_dates                        AS OF SCN lego_refresh_mgr_pkg.get_scn(),
                             (SELECT constant_value, constant_description
                                FROM java_constant_lookup
                               WHERE constant_type    = 'SOURCING_METHOD'
                                 AND UPPER(locale_fk) = 'EN_US') csm_jcl
                       WHERE ac.has_ever_been_effective  = 1      -- Ever been effective
                         AND ac.is_targeted_assignment   = 0
                         AND ac.assignment_continuity_id = ae.assignment_continuity_fk
                         AND ac.current_edition_fk       = ae.assignment_edition_id
                         AND ae.sourcing_method_name_fk  = csm_jcl.constant_value(+)
                         AND acd.assignment_created_date >= TO_DATE('01/01/2009', 'MM/DD/YYYY') 
                         AND ac.candidate_fk             = c.candidate_id(+)
                         AND j.job_id                    = ac.job_fk
                         AND j.job_state_fk NOT IN (1, 5)         -- Not Interested in Under Development/Canceled
                         AND j.template_type IS NULL              -- Eliminate Job templates
                         AND j.source_of_record IN ('GUI', 'MWO') -- Not interested in Stub Jobs
                         AND jo.job_fk                   = j.job_id
                         AND jo.supply_firm_fk           = ac.owning_supply_firm_fk
                         AND m.job_opportunity_fk(+)     = jo.job_opportunity_id
                         AND m.creation_date(+) IS NOT NULL
                         AND med.match_fk(+)             = m.match_id
                         AND med.after_state_fk(+)       = 13
                         AND med1.match_fk(+)            = m.match_id
                         AND m.candidate_fk              = ac.candidate_fk
                         AND m.job_fk                    = ac.job_fk
                         AND med1.after_state_fk(+)      = 3
                         AND ac.owning_buyer_firm_fk     = buyer.firm_id
                         AND ac.owning_supply_firm_fk    = supplier.firm_id
                         AND ac.assignment_continuity_id = asd.assignment_continuity_id
                         AND ac.assignment_continuity_id = aed.assignment_continuity_fk
                         AND ac.assignment_continuity_id = acd.assignment_continuity_fk
                         AND ac.work_order_fk            = wod.work_order_id(+)
                         AND m.match_id                  = md.match_id(+)
                         AND m.job_fk                    = cand.job_fk(+)
                         AND m.job_opportunity_fk        = cand.job_opportunity_fk(+)
                         AND ac.job_fk                   = appr_dates.job_id(+)
                       GROUP BY buyer.business_org_fk, 
                                supplier.business_org_fk, 
                                j.job_id,
                                ae.assignment_continuity_fk, 
                                c.candidate_id,
                                j.job_category_fk,
                                j.create_date,
                                appr_dates.approved_date, 
                                m.creation_date,
                                md.fwd_to_hm_date, 
                                cand.candidate_interview_date,
                                wod.wo_release_to_supp_date, 
                                wod.wo_accept_by_supp_date,
                                acd.assignment_created_date, 
                                aed.assignment_effect_date,
                                asd.assignment_start_date,
                                (ae.create_date - md.fwd_to_hm_date),
                                m.creation_date,
                                ae.sourcing_method_name_fk,
                                csm_jcl.constant_description,
                                asd.sourcing_method,
                                asd.assignment_type) mv
                       ORDER BY buyer_org_id, supplier_org_id}';    

    logger_pkg.debug (v_sql_1||v_sql_2);
    EXECUTE IMMEDIATE v_sql_1||v_sql_2;
  
  END load_lego_time_to_fill;

------------------------------------

     PROCEDURE load_lego_approvals_init
    AS
       /*******************************************************************************
        *PROCEDURE NAME : load_lego_approvals_init
        *DATE CREATED   : November 11, 2012
        *AUTHOR         : McKay Dunlap
        *PURPOSE        : This procedure create the initial LEGO_APPROVALS Table (Partitioned by Approval Type).
                          (Replacing the CTAS Version.) This will be merged with new data on the lego refresh schedule.
        *MODIFICATIONS  : 11/11/2013 - Mc-K - Orignal Release 11.4.2
        *               : 01/29/2014 - M<-K - Updated for WFPROD Defect on Delegations, Currency Association.
        *               : 08/18/2014 - pmuller - IQN-19497 - convert all logging to use LOGGER_PKG. Also moved
        *                                        the grant on the base table into its own block - v12.2
        ******************************************************************************/
       v_count            NUMBER;
       v_sql              LEGO_REFRESH.REFRESH_SQL%TYPE;
       --> Exadata storage clause stored in lego_refresh table
       v_storage          LEGO_REFRESH.EXADATA_STORAGE_CLAUSE%TYPE;
       --> Partition Clause stored in lego_refresh table
       v_partition        LEGO_REFRESH.PARTITION_CLAUSE%TYPE;
       --> lego_approvals ctas sql stored in lego_refresh table
       v_sqlstmt          LEGO_REFRESH.REFRESH_SQL%TYPE;
 
    BEGIN
       /* We don't need these three logger setup steps if this is run through the refresh manager (which would be the 
          case in a from-scratch environment).  But I'm including them here since this is most often kicked off via a 
          migration script in current PROD and QA databases.  The existance of these three commands should not prevent 
          this procedure from working in a from-scratch database.   */
       logger_pkg.instantiate_logger;
       logger_pkg.set_level('DEBUG');  --to ensure maximum messages
       logger_pkg.set_source('Approvals Lego initial load/reload');

       logger_pkg.set_code_location ('Approvals init');
 
       SELECT COUNT(*)
         INTO v_count
         FROM user_tables
        WHERE table_name = 'LEGO_APPROVAL';
 
       IF v_count = 1 THEN
 
         BEGIN
 
          EXECUTE IMMEDIATE 'DROP TABLE LEGO_APPROVAL PURGE';
 
         EXCEPTION WHEN OTHERS THEN
            NULL;
 
         END;
 
       END IF;
 
       SELECT COUNT(*)
         INTO v_count
         FROM user_tables
        WHERE table_name = 'LEGO_APPROVAL';
 
       IF v_count = 0 THEN
 
           logger_pkg.info('Null out incremental Refresh time');
           UPDATE lego_refresh
              SET next_refresh_time = NULL
            WHERE object_name = 'LEGO_APPROVAL';
            COMMIT;
 
          logger_pkg.info('Get Lego approval exadata clause ');
          SELECT exadata_storage_clause
            INTO v_storage
            FROM lego_refresh
           WHERE object_name = 'LEGO_APPROVAL_INIT';
 
          logger_pkg.info('get_lego approval partition clause');
          SELECT partition_clause
            INTO v_partition
            FROM lego_refresh
           WHERE object_name = 'LEGO_APPROVAL_INIT';
 
          logger_pkg.info('get_lego_apaproval ctas code');
           SELECT refresh_sql
            INTO v_sqlstmt
            FROM lego_refresh
           WHERE object_name = 'LEGO_APPROVAL_INIT';
 
          v_sql :=
             'CREATE TABLE lego_approval ' ||
              v_partition ||
              v_storage  ||
              ' AS ' ||
              v_sqlstmt;
 
          --CREATE LEGO_APPROVAL table
          logger_pkg.info('Start Approval CTAS with: ' || v_sql);
          logger_pkg.info('Approval CTAS');
          EXECUTE IMMEDIATE v_sql;
          logger_pkg.info('Approval CTAS - complete', TRUE);
 
          --Gather Stats is this needed for Lego_approval
          logger_pkg.info('Gather Approval Stats Start');
          DBMS_STATS.gather_table_stats (ownname          => gc_curr_schema,
                                         tabname          => 'LEGO_APPROVAL',
                                         estimate_percent => 10,
                                         degree           => 6);
          logger_pkg.info('Gather Approval Stats Finish', TRUE);
          COMMIT;
 
          -- grants on the base table
          BEGIN
            EXECUTE IMMEDIATE 'GRANT SELECT ON LEGO_APPROVAL TO RO_' || gc_curr_schema;
          EXCEPTION
            WHEN OTHERS THEN
              logger_pkg.error('Could NOT grant select on the base table to the RO_D schema.' ||
                               ' Submit a HF if you want the grant!');
          END;                       
          
          -- create indexes in QA databases
          BEGIN
              IF sys_context('USERENV', 'DB_NAME') NOT IN ('WAP', 'IQP') THEN
 
                 logger_pkg.info('Building QA indexes');
   
                 EXECUTE IMMEDIATE 'CREATE INDEX LEGO_APPROVAL_NI01
                                    ON LEGO_APPROVAL(APPROVABLE_ID)
                                    TABLESPACE LEGO_USERS
                                    NOLOGGING
                                    COMPRESS
                                    LOCAL';
 
                 EXECUTE IMMEDIATE 'CREATE INDEX LEGO_APPROVAL_NI02
                                    ON LEGO_APPROVAL(BUYER_ORG_ID)
                                    TABLESPACE LEGO_USERS
                                    NOLOGGING
                                    COMPRESS
                                    LOCAL';
									
                 logger_pkg.info('Building QA indexes - complete', TRUE);
 
              ELSE
                 logger_pkg.info('not QA database.  NO indexes built');
                
              END IF;
 
          EXCEPTION  WHEN OTHERS THEN
             logger_pkg.error('Building QA Indexes Failed.  Submit a HF if you want indexes here!');
 
          END;
 
         --> Update next incremental refresh_time ===============================
           logger_pkg.info('Updating Approval next_refresh_time');
 
           UPDATE lego_refresh
              SET next_refresh_time = (SELECT next_refresh_time
                                         FROM lego_refresh
                                        WHERE object_name = 'LEGO_WO_AMENDMENT')
            WHERE object_name = 'LEGO_APPROVAL';
            COMMIT;
 
       ELSE
         logger_pkg.warn('Table exists - no action taken.');
       END IF;
 
    EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                           pi_error_code         => SQLCODE,
                           pi_message            => SQLERRM);
          RAISE;
 
    END load_lego_approvals_init;
 
  PROCEDURE load_lego_approvals_refresh
    AS
 
       /*---------------------------------------------------------------------------*\
       || PROCEDURE NAME       : load_lego_approvals_refresh
       || AUTHOR               : McKay Dunlap
       || DATE CREATED         : November 11, 2013
       || PURPOSE              : This procedure is used to merge changed approval data into LEGO_APPROVALS table.
       ||                        (As determined by the max of the last  NVL(completed_date, started_date) from
                                  approval_activiy grouped by approval_process_fk.)
       || MODIFICATION HISTORY : 11/11/2013 - Mc-K  - Initial Creation and Release for 11.4.2.
       ||                        01/29/2014 - M<-K - Updated for WFPROD Defect on Delegations, Currency Association.
       \*---------------------------------------------------------------------------*/
 
       v_sql1             LEGO_REFRESH.REFRESH_SQL%TYPE;
       v_count            PLS_INTEGER;
       v_sqlrowcount      NUMBER;
       v_rdate            DATE;

      BEGIN
         logger_pkg.set_code_location('Approvals refresh');
         
         select count(*)
           into v_count
           from user_tables;
 
         select MAX(TRUNC(refresh_start_time))
          into v_rdate
          from lego_refresh_history
         where object_name in ( 'LEGO_APPROVALS', 'LEGO_APPROVAL_REFRESH', 'LEGO_APPROVAL_INIT', 'LEGO_APPROVAL' )
           and status in ('released','refresh complete');
 
         logger_pkg.debug('Build merge sql with '|| to_char(v_rdate,'YYYY-Mon-DD hh24:mi:ss'));
 
          select refresh_sql
            into v_sql1
            from lego_refresh
           where object_name = 'LEGO_APPROVAL';
 
         logger_pkg.info('Starting Approval Merge');
         EXECUTE IMMEDIATE v_sql1;
         v_sqlrowcount := SQL%ROWCOUNT;
         COMMIT;

         logger_pkg.info('Approval refresh complete. ' || to_char(v_sqlrowcount) ||
                         ' rows merged.');
 
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                           pi_error_code         => SQLCODE,
                           pi_message            => SQLERRM);
          RAISE;
 
   END load_lego_approvals_refresh;

  
  ---------------

  PROCEDURE load_lego_tenure (pi_refresh_table_name VARCHAR2) AS
  
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_tenure
    || AUTHOR               : Paul Muller
    || DATE CREATED         : January 7th, 2014
    || PURPOSE              : This procedure creates the tenure lego.
    || MODIFICATION HISTORY : 01/07/2014 - pmuller - initial build.
    ||                      : 04/14/2014 - pmuller - replace code with call to get_exadata_storage_clase function.
    ||                      : 09/17/2015 - pmuller - added logic to compute EARILEST_DATE in cases where clients 
    ||                      :                        specified tenure limits in units of MONTHs.  IQN-28519
    \*---------------------------------------------------------------------------*/
  
    TYPE lt_object_array IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
    la_table lt_object_array;
    
    TYPE lt_sql_array  IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;
    la_sql lt_sql_array;
    
    le_table_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_table_not_exist, -00942);
    
    lv_final_exadata_clause        lego_refresh.exadata_storage_clause%TYPE;
    lv_intermediate_exadata_clause lego_refresh.exadata_storage_clause%TYPE;
    lv_debug_flag                  BOOLEAN;
    
  BEGIN
    /* I suspect that this is not returning correct results in cases where (tenure limit + gap time)
       is more than 5 years.  This is due to the hardcoded 5 year limit in a few queries below.  */
       
    /* Get the exadata storage clause for the final lego table.  Then use that clause 
       to create a storage clause for the intermediate tables. */
    lv_final_exadata_clause := get_exadata_storage_clause('LEGO_TENURE');
    lv_intermediate_exadata_clause := REPLACE(lv_final_exadata_clause,'STORAGE (CELL_FLASH_CACHE KEEP)'); 

    /* get the debug parameter value */
    lv_debug_flag := NVL(lego_refresh_mgr_pkg.get_lego_parameter_text_value(pi_parameter_name => 'lego_tenure_debugging_flag'), 'OFF') = 'ON';
         
    /* Initialize an array of temp table names and an array storing SQL to populate the temp tables. */
    la_table(1) := 'TEMP_FIRM_SETTINGS';
    la_sql(1) := q'{SELECT business_org_fk AS business_organization_id,
       track_con_time_limits,
       con_include_service_gaps,
       con_time_lmt_thrshold,
       con_time_lmt_thrshold_days_rmn,
       time_limit_in_days,
       time_limit_in_months,
       time_limit_gap_in_days,
       time_limit_gap_in_months,
       CASE 
         WHEN time_limit_in_days IS NOT NULL AND time_limit_gap_in_days IS NOT NULL AND time_limit_in_months IS     NULL AND time_limit_gap_in_months IS     NULL 
           THEN TRUNC(add_months(SYSDATE, -1)) - (time_limit_in_days + time_limit_gap_in_days)
         WHEN time_limit_in_days IS     NULL AND time_limit_gap_in_days IS     NULL AND time_limit_in_months IS NOT NULL AND time_limit_gap_in_months IS NOT NULL 
           THEN TRUNC(add_months(SYSDATE, -1 * (1 + time_limit_in_months + time_limit_gap_in_months)))
         WHEN time_limit_in_days IS     NULL AND time_limit_gap_in_days IS NOT NULL AND time_limit_in_months IS NOT NULL AND time_limit_gap_in_months IS     NULL 
           THEN TRUNC(add_months(SYSDATE, -1 * (1 + time_limit_in_months))) - time_limit_gap_in_days
         WHEN time_limit_in_days IS NOT NULL AND time_limit_gap_in_days IS     NULL AND time_limit_in_months IS     NULL AND time_limit_gap_in_months IS NOT NULL 
           THEN TRUNC(add_months(SYSDATE, -1 * (1 + time_limit_gap_in_months))) - time_limit_in_days
         ELSE to_date(NULL)
       END AS earliest_date   --some orgs are back in Apr-2007!  check back on this.
  FROM (SELECT fr.business_org_fk,
               bf.track_con_time_limits,
               bf.con_include_service_gaps,
               bf.con_time_lmt_thrshold,
               bf.con_time_lmt_thrshold_days_rmn,
               CASE 
                 WHEN bf.con_time_limit_unit = 3
                   THEN bf.con_time_limit
                 WHEN bf.con_time_limit_unit = 4
                   THEN bf.con_time_limit * 7
                 WHEN bf.con_time_limit_unit = 5
                   THEN to_number(NULL)  --add_months(sysdate,bf.con_time_limit) - SYSDATE
                 ELSE -1    
               END AS time_limit_in_days,
               CASE 
                 WHEN bf.con_time_limit_unit = 5
                   THEN bf.con_time_limit
                 ELSE NULL    
               END AS time_limit_in_months,
               CASE 
                 WHEN bf.con_time_limit_gap_unit = 3
                   THEN bf.con_time_limit_gap
                 WHEN bf.con_time_limit_gap_unit = 4
                   THEN bf.con_time_limit_gap * 7
                 WHEN bf.con_time_limit_gap_unit = 5
                   THEN to_number(NULL)  --add_months(SYSDATE, bf.con_time_limit_gap) - SYSDATE
                 ELSE -1    
               END AS time_limit_gap_in_days,
               CASE 
                 WHEN bf.con_time_limit_gap_unit = 5
                   THEN bf.con_time_limit_gap
                 ELSE NULL    
               END AS time_limit_gap_in_months
          FROM buyer_firm AS OF SCN lego_refresh_mgr_pkg.get_scn() bf,
               firm_role  AS OF SCN lego_refresh_mgr_pkg.get_scn() fr
         WHERE bf.firm_id = fr.firm_id
           AND bf.track_con_time_limits = 1
           AND fr.business_org_fk NOT IN (26376,51467,25156))  -- these orgs have valid but nonsensical data.  No results for them!
 WHERE (time_limit_in_days     IS NULL OR time_limit_in_days     != -1)    -- filter out invalid data
   AND (time_limit_gap_in_days IS NULL OR time_limit_gap_in_days != -1)}';
    
    la_table(2) := 'TEMP_ASSIGNMENTS';
    la_sql(2) := 'SELECT la.buyer_org_id, 
       fs.con_time_lmt_thrshold, fs.con_time_lmt_thrshold_days_rmn, fs.time_limit_in_days,
       fs.time_limit_in_months, fs.time_limit_gap_in_days, fs.time_limit_gap_in_months, 
       fs.earliest_date, la.assignment_continuity_id, la.candidate_id, la.job_id, 
       la.assignment_state, la.assignment_start_dt, la.assignment_actual_end_dt, la.assignment_end_dt
  FROM (SELECT assignment_continuity_id, buyer_org_id, candidate_id, job_id, 
               assignment_state, assignment_start_dt, assignment_actual_end_dt, assignment_end_dt          
          FROM ' || most_recently_loaded_table('LEGO_ASSIGNMENT_WO') || 
       ' UNION ALL
        SELECT assignment_continuity_id, buyer_org_id, candidate_id, job_id, 
               assignment_state, assignment_start_dt, assignment_actual_end_dt, assignment_end_dt
          FROM ' || most_recently_loaded_table('LEGO_ASSIGNMENT_EA') ||
       ' UNION ALL
        SELECT assignment_continuity_id, buyer_org_id, candidate_id, job_id, 
               assignment_state, assignment_start_dt, assignment_actual_end_dt, assignment_end_dt
          FROM ' || most_recently_loaded_table('LEGO_ASSIGNMENT_TA') || ') la, ' ||
     ' temp_firm_settings fs
 WHERE fs.business_organization_id = la.buyer_org_id
   AND la.candidate_id IS NOT NULL
   AND (la.assignment_start_dt >= fs.earliest_date OR    -- only assignments with at least some time since the "earliest_date"
        la.assignment_actual_end_dt >= fs.earliest_date OR
        la.assignment_end_dt >= fs.earliest_date)';
    
    la_table(3) := 'TEMP_RELATED_CANDIDATES';
    la_sql(3) := q'{SELECT DISTINCT 
       a.candidate_id   AS candidate_id, 
       a.buyer_org_id   AS assignment_buyer_org, --increases cardinality, but we need this to join candidate-based data to firm_settings later.
       c2.candidate_id  AS related_candidate_id  
  FROM temp_assignments a,
       candidate AS OF SCN lego_refresh_mgr_pkg.get_scn() c1, 
       candidate AS OF SCN lego_refresh_mgr_pkg.get_scn() c2,
       assignment_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn() ac1, 
       assignment_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn() ac2,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn() fr1, 
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn() fr2,
       lego_buyer_org_vw lbo1,
       lego_buyer_org_vw lbo2
 WHERE a.candidate_id = c1.candidate_id 
   AND c1.candidate_id = ac1.candidate_fk
   AND ac1.owning_buyer_firm_fk = fr1.firm_id   -- should be supply firm?
   AND fr1.business_org_fk = lbo1.buyer_org_id
   AND lbo1.buyer_enterprise_bus_org_id = lbo2.buyer_enterprise_bus_org_id  
   AND lbo2.buyer_org_id = fr2.business_org_fk
   AND fr2.firm_id = ac2.owning_buyer_firm_fk   -- should be supply firm?
   AND ac2.candidate_fk = c2.candidate_id
   AND c1.fed_id = c2.fed_id
   AND c1.fed_id_type_fk = c2.fed_id_type_fk}';
    
    la_table(4) := 'TEMP_PAST_ASSIGNMENTS';
    la_sql(4) := q'{SELECT rc.candidate_id,         --needed for later rollup by candidate_id
       rc.assignment_buyer_org, --needed for later join to firm_settings.
       rc.related_candidate_id,
       pa.assignment_continuity_id,
       pa.start_date,
       pa.end_date
  FROM temp_related_candidates rc,
       (SELECT ac.candidate_fk, 
               ac.assignment_continuity_id,
               ald.valid_from                       AS start_date, 
               ald.valid_to                         AS end_date
          FROM assignment_continuity  AS OF SCN lego_refresh_mgr_pkg.get_scn() ac,
               assignment_edition     AS OF SCN lego_refresh_mgr_pkg.get_scn() ae,
               assignment_state       AS OF SCN lego_refresh_mgr_pkg.get_scn() state,
               assignment_line_detail AS OF SCN lego_refresh_mgr_pkg.get_scn() ald
         WHERE ae.assignment_edition_id = ac.current_edition_fk
           AND ae.assignment_continuity_fk = ac.assignment_continuity_id
           AND state.value = ae.assignment_state_fk
           AND ald.assignment_edition_fk = ae.assignment_edition_id
           AND state.type IN
               ('AssignmentAwaitingStartDateState',
                'AssignmentCompletedState',
                'AssignmentEffectiveState',
                'AssignmentTerminatedState')
           AND ald.valid_from < SYSDATE
         UNION ALL
        SELECT ac.candidate_fk, 
               ac.assignment_continuity_id,
               pt.start_date                        AS start_date,
               NVL(ae.actual_end_date, pt.end_date) AS end_date
          FROM performance_term       AS OF SCN lego_refresh_mgr_pkg.get_scn() pt,
               contract_term          AS OF SCN lego_refresh_mgr_pkg.get_scn() ct,
               contract_version       AS OF SCN lego_refresh_mgr_pkg.get_scn() cv,
               work_order_version     AS OF SCN lego_refresh_mgr_pkg.get_scn() wov,
               work_order             AS OF SCN lego_refresh_mgr_pkg.get_scn() wo,
               assignment_continuity  AS OF SCN lego_refresh_mgr_pkg.get_scn() ac,
               assignment_edition     AS OF SCN lego_refresh_mgr_pkg.get_scn() ae,
               assignment_state       AS OF SCN lego_refresh_mgr_pkg.get_scn() state
         WHERE ct.contract_term_id = pt.contract_term_id
           AND cv.contract_version_id = ct.contract_version_fk
           AND wov.contract_version_id = cv.contract_version_id
           AND wo.contract_id = cv.contract_fk
           AND ac.work_order_fk = wo.contract_id
           AND ae.assignment_edition_id = ac.current_edition_fk
           AND ae.assignment_continuity_fk = ac.assignment_continuity_id
           AND state.value = ae.assignment_state_fk
           AND state.type IN
               ('AssignmentAwaitingStartDateState',
                'AssignmentCompletedState',
                'AssignmentEffectiveState',
                'AssignmentTerminatedState')
           AND cv.contract_version_id =
               (CASE
                 WHEN wo.in_process_version_fk = cv.contract_version_id
                  AND wov.work_order_version_state IN (3, 17)
                   THEN wo.in_process_version_fk
                 ELSE NVL(wo.executing_version_fk, wo.last_past_version_fk)
                END)
           AND pt.start_date < SYSDATE) pa   --should we also filter out 1-day assignments where start_date = end_date???
 WHERE pa.candidate_fk = rc.related_candidate_id
   AND pa.end_date >= TRUNC(SYSDATE-5*365)  --hardcoded 5 years.  used to be (SELECT MIN(row_date) FROM days)
   and 1=1}';
    
    la_table(5) := 'TEMP_ASSIGNMENT_DAYS';
    la_sql(5) := q'{SELECT /*+ PARALLEL(2) */ DISTINCT --to remove overlaps
       pa.candidate_id, pa.assignment_buyer_org, d.row_date AS assignment_day  
  FROM temp_past_assignments pa, 
       temp_firm_settings fs,
       (SELECT TRUNC(SYSDATE - (LEVEL -1)) AS row_date 
          FROM dual 
       CONNECT BY LEVEL <= (365 * 5)) d 
 WHERE pa.assignment_buyer_org = fs.business_organization_id
   AND d.row_date BETWEEN pa.start_date AND pa.end_date
   AND d.row_date >= fs.earliest_date}';
    
    la_table(6) := 'TEMP_EARLIEST_DAYS';
    la_sql(6) := q'{SELECT candidate_id, assignment_buyer_org, MIN(assignment_day) AS earliest_start_day
  FROM temp_assignment_days
 GROUP BY candidate_id, assignment_buyer_org}';
    
    la_table(7) := 'TEMP_TENURE_GAPS';
    la_sql(7) := q'{SELECT candidate_id, 
       assignment_buyer_org, 
       most_recent_gap_start_date, 
       most_recent_gap_end_date,
       most_recent_gap_end_date - most_recent_gap_start_date AS gap_days, 
       NVL(add_months(most_recent_gap_start_date, time_limit_gap_in_months), most_recent_gap_start_date + time_limit_gap_in_days) AS date_gap_met
  FROM (SELECT g.candidate_id, 
               g.assignment_buyer_org,
               fs.time_limit_gap_in_days, 
               fs.time_limit_gap_in_months,
               max(g.previous_day) + 1 AS most_recent_gap_start_date,  -- in cases with more than one gap, we only want the most recent 
               max(g.assignment_day)   AS most_recent_gap_end_date
          FROM (SELECT candidate_id, 
                       assignment_buyer_org, 
                       assignment_day,
                       LAG(assignment_day,1,NULL) OVER (PARTITION BY candidate_id,assignment_buyer_org ORDER BY assignment_day) AS previous_day
                  FROM temp_assignment_days) g,
               temp_firm_settings fs
         WHERE g.assignment_buyer_org = fs.business_organization_id
           AND g.assignment_day >= NVL(add_months(previous_day, time_limit_gap_in_months), previous_day + time_limit_gap_in_days) -- check by months if available, by days if not.
         GROUP BY g.candidate_id, 
                  g.assignment_buyer_org, 
                  fs.time_limit_gap_in_days, 
                  fs.time_limit_gap_in_months)}';
    
    la_table(8) := 'TEMP_DAYS_WORKED';
    la_sql(8) := q'{SELECT a.candidate_id, a.assignment_buyer_org, 
       MAX(date_gap_met) AS date_gap_met,  -- date_gap_met is NULL or constant over the group so we get it with MAX.
       COUNT(*)          AS days_worked    -- count all days on assignment since last tenure gap.
  FROM temp_assignment_days a,
       temp_firm_settings fs,
       temp_earliest_days e,
       temp_tenure_gaps t
 WHERE a.candidate_id = e.candidate_id
   AND a.assignment_buyer_org = e.assignment_buyer_org
   AND a.assignment_buyer_org = fs.business_organization_id
   AND a.candidate_id = t.candidate_id(+)
   AND a.assignment_buyer_org = t.assignment_buyer_org(+)
   AND fs.con_include_service_gaps = 0 
   AND a.assignment_day >= NVL(t.most_recent_gap_start_date, e.earliest_start_day)  --if no tenure gap use ealiest day.
 GROUP BY a.candidate_id, a.assignment_buyer_org
 UNION ALL
SELECT a.candidate_id, a.assignment_buyer_org, 
       MAX(date_gap_met),                                            -- date_gap_met is NULL or constant over the group so we get it with MAX.
       MAX(assignment_day) - MIN(assignment_day) + 1 AS days_worked  -- count all days since last tenure gap even if there was a small (non-tenure length) gap
  FROM temp_assignment_days a,
       temp_firm_settings fs,
       temp_earliest_days e,
       temp_tenure_gaps t
 WHERE a.candidate_id = e.candidate_id
   AND a.assignment_buyer_org = e.assignment_buyer_org
   AND a.assignment_buyer_org = fs.business_organization_id
   AND a.candidate_id = t.candidate_id(+)
   AND a.assignment_buyer_org = t.assignment_buyer_org(+)
   AND a.assignment_day >= NVL(t.most_recent_gap_start_date, e.earliest_start_day)
   AND fs.con_include_service_gaps = 1
 GROUP BY a.candidate_id, a.assignment_buyer_org}';
    
    /* Next clean up any objects which may be remaining from previous failed runs. */
    logger_pkg.set_code_location('LEGO_TENURE - cleanup');
    FOR lv_loop_index IN 1 .. 8 LOOP

      BEGIN
        EXECUTE IMMEDIATE ('drop table ' || la_table(lv_loop_index) || ' purge');
        logger_pkg.debug('dropped table ' || la_table(lv_loop_index));
      EXCEPTION
        WHEN le_table_not_exist
          THEN NULL;
      END;

    END LOOP;

    /*  Now start building tables to hold intermediate steps. */
    logger_pkg.set_code_location('LEGO_TENURE - table builds');
    FOR lv_loop_index IN 1 .. 8 LOOP

      lego_refresh_mgr_pkg.ctas(pi_table_name             => la_table(lv_loop_index),
                                pi_stmt_clob              => la_sql(lv_loop_index),
                                pi_exadata_storage_clause => lv_intermediate_exadata_clause);
      IF lv_debug_flag
      THEN 
        EXECUTE IMMEDIATE('grant select on ' || la_table(lv_loop_index) || 
                          ' to RO_' || gc_curr_schema);
      END IF;                                    

    END LOOP;

    /* intermediate tables built, we can now build the final lego table. */
    lego_refresh_mgr_pkg.ctas(pi_table_name => pi_refresh_table_name,
                              pi_exadata_storage_clause => lv_final_exadata_clause,
                              pi_stmt_clob  => q'{SELECT a.buyer_org_id, a.assignment_continuity_id, a.job_id, a.candidate_id,
       dw.date_gap_met, 
       dw.days_worked                        AS days_actually_worked,
       CASE 
          WHEN dw.days_worked > a.time_limit_in_days THEN 'Y'
          ELSE 'N' 
       END                                   AS over_tenure_work_duration,
       CASE 
         WHEN dw.days_worked >= a.time_limit_in_days - a.con_time_lmt_thrshold THEN 'Y'
         ELSE 'N'
       END                                   AS tenure_at_risk_time_met,
       a.time_limit_in_days - dw.days_worked AS days_remaining_to_threshold,
       CASE
         WHEN dw.days_worked > a.time_limit_in_days
           THEN dw.days_worked - a.time_limit_in_days
         ELSE NULL
       END                                   AS days_over_tenure_threshold,
       cast(null as number)  AS num_days_planned_to_work,
       cast(null as number)  AS additional_days_plan_to_work,
       cast(null as date)    AS tenure_risk_met_planned_end_dt,
       cast(null as date)    AS furthest_plan_end_dt,
       cast(null as date)    AS effec_assign_latest_planned_dt,
       cast(null as number)  AS tenure_gap_in_service,
       a.time_limit_in_days                  AS tenure_limit_in_days,
       a.time_limit_in_months                AS tenure_limit_in_months,   
       a.time_limit_gap_in_days              AS continuous_work_break_days,
       a.time_limit_gap_in_months            AS continuous_work_break_months,
       a.con_time_lmt_thrshold               AS tenure_at_risk_days
  FROM temp_assignments a, 
       temp_days_worked dw
 WHERE a.candidate_id = dw.candidate_id
 ORDER BY a.buyer_org_id}');

    /* Drop the tables unless the lego_tenure_debugging_flag parameter is set to 'ON'. */
    IF NOT lv_debug_flag THEN
      
      logger_pkg.set_code_location('LEGO_TENURE - final cleanup');
      FOR lv_loop_index IN 1 .. 8 LOOP

        BEGIN
          EXECUTE IMMEDIATE ('drop table ' || la_table(lv_loop_index) || ' purge');
          logger_pkg.debug('dropped table ' || la_table(lv_loop_index));
        EXCEPTION
          WHEN le_table_not_exist
            THEN NULL;
        END;

      END LOOP;
    
    END IF;  --lv_drop_tables

  END load_lego_tenure;
  ----------------------------------------------------------------------------------

 PROCEDURE load_candidate_search_index
    AS
       /*******************************************************************************
        *PROCEDURE NAME : load_candidate_search_index
        *DATE CREATED   : July 18, 2014
        *AUTHOR         : McKay Dunlap
        *PURPOSE        : This procedure drop/recreate the Tokenized Index for Utlizing Oracle Text Search for ResourceIQ.
        *                  
        *MODIFICATIONS  : 
        *               : 
        ******************************************************************************/
       v_count            NUMBER;
       v_recenttbl        VARCHAR(30);
       v_recentidx        VARCHAR(30);
    
    BEGIN
       

      --> Find most recent table......either LEGO_CAND_SEARCH1 or LEGO_CAND_SEARCH2
       select lego_util.most_recently_loaded_table('LEGO_CAND_SEARCH') as Recent_table 
         into v_recenttbl
         from dual;
         logger_pkg.debug('Most Recent Table: '||v_recenttbl);  
         

       --> Define Index Name.....based on table 
         select CASE WHEN lego_util.most_recently_loaded_table('LEGO_CAND_SEARCH') = 'LEGO_CAND_SEARCH1'
                     THEN 'CAND_SEARCH_IDX1' ELSE 'CAND_SEARCH_IDX2' END as Recent_table 
         into v_recentidx
         from dual;
         logger_pkg.debug('Most Recent Index: '||v_recentidx);
       
       --> Index Check
       SELECT COUNT(*)
         INTO v_count
         FROM user_indexes
        WHERE index_name = v_recentidx;

       IF v_count = 1 THEN

         BEGIN

          EXECUTE IMMEDIATE 'DROP INDEX '||v_recentidx;
          logger_pkg.debug('Index ' || v_recentidx || ' dropped');

         EXCEPTION WHEN OTHERS THEN
            NULL;

         END;

       END IF;
        
       
       --> Create Actual Tokenized Text Index: CAND_SKILL_DATA_STORE Pref must exist.
       
       BEGIN 
             logger_pkg.info('Create Actual Text Index');
             
             EXECUTE IMMEDIATE '
             CREATE INDEX '||v_recentidx||' ON '||v_recenttbl||'(job_position_title)
             INDEXTYPE IS CTXSYS.CONTEXT
             PARAMETERS('||''''||'
                datastore CAND_SKILL_DATA_STORE 
                section group CTXSYS.AUTO_SECTION_GROUP
                SYNC (ON COMMIT)'||''''||')';

             logger_pkg.info('Create Actual Text Index complete', TRUE);
             
       EXCEPTION WHEN OTHERS THEN 
           logger_pkg.fatal(pi_transaction_result => NULL,
                            pi_error_code         => SQLCODE,
                            pi_message            => 'Creating Tokenized Index: ' || v_recentidx ||
                                                     ' ON ' ||v_recenttbl || ' error message ' || SQLERRM);
           RAISE;

       END;
       
    END load_candidate_search_index; 

  ---------------

END lego_util;
/


