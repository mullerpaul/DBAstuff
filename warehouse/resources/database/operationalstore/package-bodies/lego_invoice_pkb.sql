create or replace PACKAGE BODY lego_invoice
/******************************************************************************
 * Name: lego_invoice
 * Desc: This package contains all the procedures required to
 *       load invoice/spend data
 *
 * Author        Date        Version   History
 * -----------------------------------------------------------------
 * jpullifrone   06/30/2016  Initial
 * jpullifrone   07/21/2016  1.01      IQN-33597 - Remove join to Opstore bus_org
 * jpulliforne   08/03/2016  1.02      IQN-33780 - Add new rollup table and load process, and
 *                                                 expenditure_approval info, supplier_resource_id 
 * jpullifrone   08/15/2016  1.03      IQN-34032 - partition add value; relaced hard-coded value with var 
 * jpullifrone   09/19/2016  1.04      IQN-34663 - more cols added to lego_invoiced_expd_detail; doing CTAS first
 *                                                 then INSERT in order to do FAST REFRESH MVs
 * jpullifrone   10/11/2016  1.05      IQN-35075 - fixed lv_load_date format and CTAS table name will differ based
 *                                                 on source_name.
 * jpullifrone   04/19/2017  1.06      IQN-37458 - adding the following columns: invoiceable_exp_owner_id, invoiceable_expenditure_txn_id
 *                                                 and payee_business_org_id. renamed expenditure_item_id to invoiceable_expenditure_id
 * McKay         04/19/2017  1.06      IQN-42256 - Updating the remove invoice function to included the LEGO_INVOICED_EXPD_DETAIL object cleanup. 
 ******************************************************************************/
AS
  gc_curr_schema             CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');
  g_source                   CONSTANT VARCHAR2(30) := 'LEGO_INVOICE';
  g_oc_invd_exp_job_name     CONSTANT VARCHAR2(30) := 'OCL'; --will be suffix to object_name - stands for Off-Cycle Load
  gv_error_stack             VARCHAR2(1000);  
  g_null_partition_name      CONSTANT VARCHAR2(30) := 'P_NULL'; 

  PROCEDURE index_maint (pi_object_name   IN lego_object.object_name%TYPE,
                         pi_process_stage IN VARCHAR2) IS
                         
  --PI_PROCESS_STAGE: BEGIN, MAINT, END
  
  v_source            VARCHAR2(61) := g_source || '.index_maint';
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('index_maint');
    
    IF pi_object_name = 'LEGO_INVOICED_EXPD_DETAIL' THEN
      
      BEGIN
        CASE UPPER(pi_process_stage)
          WHEN 'BEGIN' THEN 
            logger_pkg.info('Dropping index lego_invoiced_expd_detail_n01 on '||pi_object_name);
            EXECUTE IMMEDIATE 'DROP INDEX lego_invoiced_expd_detail_n01';
            logger_pkg.info('Successfully dropped index lego_invoiced_expd_detail_n01 on '||pi_object_name,TRUE);
          WHEN 'MAINT' THEN NULL;
          WHEN 'END'   THEN 
            logger_pkg.info('Creating index lego_invoiced_expd_detail_n01 on '||pi_object_name);
            EXECUTE IMMEDIATE 'CREATE INDEX lego_invoiced_expd_detail_n01 ON '||pi_object_name||' (invoice_id, owning_buyer_org_id, source_name)';
            logger_pkg.info('Successfully created index lego_invoiced_expd_detail_n01 on '||pi_object_name,TRUE);
        ELSE NULL;
        END CASE;   
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
      
      logger_pkg.info('Gathering stats on '||pi_object_name);
      dbms_stats.gather_table_stats(ownname          => gc_curr_schema,
                                    tabname          => pi_object_name,
                                    degree           => 4);   
      logger_pkg.info('Successfully gathered stats on '||pi_object_name,TRUE);                                    
    
    ELSIF pi_object_name = 'LEGO_INVD_EXPD_DATE_RU' THEN
    
      logger_pkg.info('Gathering stats on '||pi_object_name);
      dbms_stats.gather_table_stats(ownname          => gc_curr_schema,
                                    tabname          => pi_object_name,
                                    degree           => 4);     
      logger_pkg.info('Successfully gathered stats on '||pi_object_name,TRUE);                                    
    
    ELSE
      NULL;
    END IF;
  
    logger_pkg.unset_source(v_source); 
    
  END index_maint;
  
  PROCEDURE parse_partition_values (pi_object_name IN lego_object.object_name%TYPE,
                                    pi_source      IN lego_object.source_name%TYPE) IS
  
  v_source            VARCHAR2(61) := g_source || '.parse_partition_values';
  TYPE varchar2_table IS TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
  lv_delim VARCHAR2(5) := ', ';
  lv_string VARCHAR2(32767);
  lv_nfields PLS_INTEGER := 1;
  lv_table varchar2_table;    
  lv_delimpos PLS_INTEGER;
  lv_delimlen PLS_INTEGER := LENGTH(lv_delim);
  lv_load_date DATE := SYSDATE;
    
  CURSOR tab_part_list_vals IS
    SELECT buyer_enterprise_bus_org_id,
           part_name,
           part_list
      FROM lego_part_by_enterprise_gtt
     WHERE object_name = pi_object_name;             
    
  BEGIN
  
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('parse_partition_values'); 
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE lego_part_by_enterprise_gtt';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE lego_part_by_ent_buyer_org_gtt';
    
    logger_pkg.info('Insert into partition GTT to hold data associated with existing partitions.');
    /* Note: if you want to get or store high_value from user_tab_partitions, you have to convert
       it to a LOB, TO_LOB(high_value). */  
    
    INSERT INTO lego_part_by_enterprise_gtt
      SELECT pi_object_name                 object_name,
             pi_source                      source_name,
             TO_NUMBER(SUBSTR(partition_name,3)) buyer_enterprise_bus_org_id, 
             partition_name                 part_name, 
             TO_LOB(high_value)             part_list,
             SYSDATE                        load_date
       FROM user_tab_partitions
      WHERE table_name = pi_object_name
        AND partition_name != g_null_partition_name;   
    
    logger_pkg.info('Successfully inserted into partition GTT to hold existing partitions.'||SQL%ROWCOUNT||' records inserted.',TRUE);
    COMMIT;
    
    logger_pkg.info('Loop through records in lego_part_by_enterprise_gtt, parsing the partition values.');
    FOR r1 IN tab_part_list_vals LOOP
      
      lv_delimpos := INSTR(r1.part_list,lv_delim);
      lv_string := TO_CHAR(r1.part_list); --must be stored as CLOB 
      lv_delimlen := LENGTH(lv_delim);
      
      WHILE lv_delimpos > 0
      LOOP
        lv_table(lv_nfields) := SUBSTR(lv_string,1,lv_delimpos-1);
        lv_string := SUBSTR(lv_string,lv_delimpos+lv_delimlen);
        lv_nfields := lv_nfields+1;
        lv_delimpos := INSTR(lv_string, lv_delim);
      END LOOP;
      
      lv_table(lv_nfields) := lv_string;         
      
      FOR x IN 1..lv_nfields LOOP
    
        INSERT INTO lego_part_by_ent_buyer_org_gtt VALUES(pi_object_name, pi_source, r1.buyer_enterprise_bus_org_id, lv_table(x), r1.part_name, lv_load_date);
      
      END LOOP;
      COMMIT;
      
   END LOOP;
   logger_pkg.info('Successfully parsed all partition values in lego_part_by_enterprise_gtt.', TRUE);
   
   logger_pkg.unset_source(v_source);
   
  END parse_partition_values;
 
  PROCEDURE off_cycle_invoice_load (pi_object_name IN lego_object.object_name%TYPE,
                                    pi_source      IN lego_object.source_name%TYPE,
                                    pi_start_ts    IN TIMESTAMP DEFAULT SYSTIMESTAMP) AS
  
  v_source            VARCHAR2(61) := g_source || '.off_cycle_invd_exp_detail';
  lv_job_str          VARCHAR2(2000);
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('off_cycle_invoice_load');  
  
    lv_job_str :=
      'BEGIN
        logger_pkg.instantiate_logger;
        logger_pkg.set_source('''||pi_object_name||'_'||g_oc_invd_exp_job_name||''');
        lego_invoice.invoice_load('''||pi_object_name||''','''||pi_source||'''); 
      EXCEPTION
        WHEN OTHERS THEN                                       
          logger_pkg.unset_source('''||pi_object_name||'_'||g_oc_invd_exp_job_name||''');                                       
      END;';

    logger_pkg.info(lv_job_str);
    
    DBMS_SCHEDULER.CREATE_JOB (
          job_name             => pi_object_name||'_'||g_oc_invd_exp_job_name,
          job_type             => 'PLSQL_BLOCK',
          job_action           => lv_job_str,
          start_date           => pi_start_ts,
          enabled              => TRUE,
          comments             => 'Manually populate '||pi_object_name||'-this will take a while');
  
    logger_pkg.unset_source(v_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.unset_source(v_source);
      RAISE;
  
  END off_cycle_invoice_load;   
  
  PROCEDURE reload_invoices (pi_object_name     IN lego_object.object_name%TYPE,
                             pi_source          IN lego_object.source_name%TYPE,
                             pi_start_ts        IN TIMESTAMP DEFAULT SYSTIMESTAMP,
                             pi_drop_partition  IN BOOLEAN   DEFAULT FALSE) AS
  
  /******************************WARNING****************************************
  
  THIS PROCEDURE WILL TRUNCATE EVERYTHING AND START OVER.  ONLY RUN THIS 
  PROCEDURE IF THAT IS YOUR INTENTION.
  
   ******************************WARNING***************************************/ 
  
  
  v_source            VARCHAR2(61) := g_source || '.reload_invoices';
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('reload_invoices'); 
  
    IF pi_drop_partition THEN
    
      /* Do not drop the NULL partition.  Otherwise you would have to drop 
         the entire table. Instead of using a DEFAULT partition, we will use a NULL
         partition.  Reason is, we need a "first" partition when creating the table,
         upon which all the other partitions can be added.  If we were to create the 
         table with a DEFAULT partition, we cannot then create other partitions since
         it will raise ORA-14323.  No records, however, should go into the NULL 
         partition since the column, buyer_enterprise_bus_org_id, is defined as NOT NULL.
         */
      FOR p1 IN (SELECT partition_name
                   FROM user_tab_partitions
                  WHERE table_name = pi_object_name
                    AND partition_name != g_null_partition_name
                  ORDER BY partition_position DESC) LOOP
                
        logger_pkg.info('Dropping partition on '||pi_object_name||': '||p1.partition_name);
        EXECUTE IMMEDIATE 'ALTER TABLE '||pi_object_name||' DROP PARTITION '||p1.partition_name;
        logger_pkg.info('Sucessfully dropped partition on '||pi_object_name||': '||p1.partition_name);
    
      END LOOP;
    
    ELSE
    
      logger_pkg.info('Truncating table, '||pi_object_name||', with reuse storage');      
      EXECUTE IMMEDIATE 'TRUNCATE TABLE '||pi_object_name||' REUSE STORAGE';
      logger_pkg.info('Sucessfully truncated table, '||pi_object_name||', with reuse storage', TRUE);    
  
    END IF;
    
    logger_pkg.info('Truncating table, lego_invoice_approved, with reuse storage');
    EXECUTE IMMEDIATE 'TRUNCATE TABLE lego_invoice_approved REUSE STORAGE';
    logger_pkg.info('Sucessfully truncated table, lego_invoice_approved, with reuse storage', TRUE);    
    
    index_maint (pi_object_name   => pi_object_name,
                 pi_process_stage => 'BEGIN');
    
    IF pi_source = 'ALL' THEN
    --run for all sources
      FOR src IN (SELECT DISTINCT source_name 
                    FROM lego_invoice_approved) LOOP
                      
        off_cycle_invoice_load (pi_object_name => pi_object_name,
                                pi_source      => src.source_name,
                                pi_start_ts    => pi_start_ts);
        
      END LOOP;  
        
    ELSE
      --run for just one
      off_cycle_invoice_load (pi_object_name => pi_object_name,
                              pi_source      => pi_source,
                              pi_start_ts    => pi_start_ts);     
    END IF;          
    
    logger_pkg.unset_source(v_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.unset_source(v_source);
      RAISE;  
  
  END reload_invoices;
  
  PROCEDURE reload_part_invoice (pi_object_name          IN lego_object.object_name%TYPE,
                                 pi_source               IN lego_object.source_name%TYPE,
                                 pi_buyer_ent_bus_org_id IN lego_invoice_approved.buyer_enterprise_bus_org_id%TYPE,
                                 pi_start_ts             IN TIMESTAMP DEFAULT SYSTIMESTAMP) AS
                                         
  v_source            VARCHAR2(61) := g_source || '.reload_part_invoice';
  lv_partition_name   VARCHAR2(30);
  lv_alter_sql        VARCHAR2(200);
  lv_part_count       PLS_INTEGER;
  /*****************************************************************************
  
   Run this procedure if you want to target a particular partition for removal
   and reload.  The routine will automatically reload the data into the same
   partition as well as anything else that is ready to be loaded.
   
   Since there are multiple sources inside a partition, you will have to reload
   the data for earch source.  
   ****************************************************************************/ 
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('reload_part_invoice'); 
  
    IF pi_buyer_ent_bus_org_id IS NOT NULL THEN          
      
      BEGIN
      
        SELECT UPPER(partition_name)
          INTO lv_partition_name
          FROM user_tab_partitions
         WHERE table_name = pi_object_name
           AND partition_name = 'P_'||pi_buyer_ent_bus_org_id;
               
        logger_pkg.info('Remove records in lego_invoice_approved which are associated with partition: '||lv_partition_name);
        
        DELETE FROM lego_invoice_approved
         WHERE buyer_enterprise_bus_org_id = pi_buyer_ent_bus_org_id
           AND object_name = pi_object_name;
                                                     
        logger_pkg.info('Successfully removed records in lego_invoice_approved which are associated with partition: '||lv_partition_name||' Records deleted: '||SQL%ROWCOUNT, TRUE);                                                     
              
        lv_alter_sql := 'ALTER TABLE '||pi_object_name||' DROP PARTITION '||lv_partition_name;
        logger_pkg.info('Dropping partition on '||pi_object_name||': '||lv_alter_sql);
             
        EXECUTE IMMEDIATE lv_alter_sql;
      
        logger_pkg.info('Sucessfully dropped partition on '||pi_object_name||': '||lv_partition_name, TRUE);   
  
        COMMIT; --commit only after the partition is dropped      
      
        --general off-cycle load 
        IF pi_source = 'ALL' THEN
          --run for all sources
          FOR src IN (SELECT DISTINCT source_name 
                        FROM lego_invoice_approved) LOOP
                      
            off_cycle_invoice_load (pi_object_name => pi_object_name,
                                    pi_source      => src.source_name,
                                    pi_start_ts    => pi_start_ts);
        
          END LOOP;  
        
        ELSE
          --run for just one
          off_cycle_invoice_load (pi_object_name => pi_object_name,
                                  pi_source      => pi_source,
                                  pi_start_ts    => pi_start_ts);     
        END IF;
        
        
    
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          logger_pkg.warn('Partition, '||lv_partition_name||', is not a valid partition name for '||pi_object_name);
        WHEN OTHERS THEN
          ROLLBACK;
          RAISE;
      END;
    
    ELSE
    
      logger_pkg.warn('No value for pi_partition_name was passed in.  Please pass in a valid partition name for '||pi_object_name);
  
    END IF;

    logger_pkg.unset_source(v_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.warn('When others exception occurred '||pi_source||' : '||pi_start_ts||' : '||lv_partition_name||' : '||pi_object_name,TRUE);
      logger_pkg.unset_source(v_source);
      RAISE;  
                                         
  END reload_part_invoice; 

  
  PROCEDURE remove_invoice (pi_source              IN lego_object.source_name%TYPE,                            
                            pi_owning_buyer_org_id IN lego_invoice_approved.owning_buyer_org_id%TYPE,
                            pi_buyer_org_id        IN lego_invd_expd_date_ru.buyer_org_id%TYPE,
                            pi_invoice_id          IN lego_invoice_approved.invoice_id%TYPE) AS

  v_source            VARCHAR2(61) := g_source || '.remove_invoice';
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('remove_invoice');   

    logger_pkg.info('Delete invoice details from LEGO_INVOICE_APPROVED '||pi_source||' : '||pi_owning_buyer_org_id||' : '||pi_invoice_id); 
    
    DELETE FROM lego_invoice_approved
     WHERE owning_buyer_org_id = pi_owning_buyer_org_id
       AND invoice_id   = pi_invoice_id
       AND source_name  = pi_source
       --AND object_name  = 'LEGO_INVD_EXPD_DATE_RU'
	   ;
       
    logger_pkg.info('Successfully deleted '||SQL%ROWCOUNT|| ' rows from LEGO_INVOICE_APPROVED',TRUE);
    
   
    logger_pkg.info('Delete invoice details from LEGO_INVOICED_EXPD_DETAIL '||pi_source||' : '||pi_buyer_org_id||' : '||pi_invoice_id); 
    
    DELETE FROM lego_invoiced_expd_detail
     WHERE buyer_org_id = pi_buyer_org_id
       AND invoice_id   = pi_invoice_id
       AND source_name  = pi_source;
       
    logger_pkg.info('Successfully deleted '||SQL%ROWCOUNT|| ' rows from LEGO_INVOICED_EXPD_DETAIL',TRUE);    
 
    
    logger_pkg.info('Delete invoice details from LEGO_INVD_EXPD_DATE_RU '||pi_source||' : '||pi_buyer_org_id||' : '||pi_invoice_id); 
    
    DELETE FROM lego_invd_expd_date_ru
     WHERE buyer_org_id = pi_buyer_org_id
       AND invoice_id   = pi_invoice_id
       AND source_name  = pi_source;
       
    logger_pkg.info('Successfully deleted '||SQL%ROWCOUNT|| ' rows from LEGO_INVD_EXPD_DATE_RU',TRUE);        
       
    COMMIT;    
    
    logger_pkg.unset_source(v_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;

      logger_pkg.fatal('ROLLBACK', SQLCODE,'When others exception occurred '||pi_source||' : '||pi_owning_buyer_org_id||' : '||pi_buyer_org_id||' : '||pi_invoice_id||': '||SQLERRM);
      logger_pkg.unset_source(v_source);
      RAISE;                  
      
  END remove_invoice;
  
  
  PROCEDURE drop_oc_invd_exp_job (pi_object_name lego_object.object_name%TYPE) AS
  
  v_source   VARCHAR2(61) := g_source || '.drop_oc_invd_exp_job';
  
  BEGIN
  
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('drop_oc_invd_exp_job'); 
  
    logger_pkg.info('Dropping job, '||pi_object_name||'_'||g_oc_invd_exp_job_name);
    
    DBMS_SCHEDULER.DROP_JOB(pi_object_name||'_'||g_oc_invd_exp_job_name,TRUE);  
    
    logger_pkg.unset_source(v_source); 
    
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.warn('When others exception occurred in '||v_source,TRUE);
      logger_pkg.unset_source(v_source);
      RAISE;      
  
  END drop_oc_invd_exp_job;
    
  PROCEDURE load_invd_expd_detail (pi_object_name  IN lego_object.object_name%TYPE,
                                   pi_source       IN lego_object.source_name%TYPE,
                                   pi_db_link_name IN lego_source.db_link_name%TYPE) AS
  
  CURSOR c_new_det 
  IS
    SELECT invoice_id,
           buyer_enterprise_bus_org_id,
           owning_buyer_org_id,
           invoice_date
      FROM lego_invoice_approved 
     WHERE load_date IS NULL
       AND object_name = pi_object_name
       AND source_name = pi_source
     ORDER BY invoice_date DESC, invoice_id DESC;  
  
  v_source               VARCHAR2(61) := g_source || '.load_invd_expd_detail';
  lv_insert_sql          CLOB;  
  lv_ctas_sql            CLOB;
  lv_load_date           lego_invoice_approved.load_date%TYPE;     
  lv_load_time_sec       lego_invoice_approved.load_time_sec%TYPE;
  lv_records_loaded      VARCHAR2(30);
  
  BEGIN
  
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('load_invd_expd_detail');  
  
    FOR r_new_det IN c_new_det LOOP
    
      BEGIN   
      
        BEGIN
          EXECUTE IMMEDIATE 'DROP TABLE invd_expd_det_'||pi_source||' PURGE';
        EXCEPTION
          WHEN OTHERS THEN NULL;
        END;
                
        lv_load_date := SYSDATE;                                                  
        
        lv_ctas_sql :=                                                                  
        'CREATE TABLE invd_expd_det_'||pi_source||' AS
          SELECT ibs.buyer_bus_org_fk                                                                       buyer_org_id,
                 ibs.supplier_bus_org_fk                                                                    supplier_org_id,
				 ind.payee_business_org_fk                                                                  payee_business_org_id,
                 inv.invoice_id                                                                             invoice_id,
                 inh.invoice_header_id                                                                      invoice_header_id,
                 ind.invoice_detail_id                                                                      invoice_detail_id,
                 inv.invoice_date                                                                           invoice_date,
                 inv.create_date                                                                            invoice_create_date,
                 inh.invoiceable_exp_owner_fk				                                                invoiceable_exp_owner_id,
                 ind.invoiceable_expenditure_fk                                                             invoiceable_expenditure_id,
				 ind.invoiceable_expenditure_txn_fk                                                         invoiceable_expenditure_txn_id,
                 inh.expenditure_number                                                                     expenditure_number,
                 ind.expenditure_date                                                                       expenditure_date,
                 ind.week_ending_date                                                                       week_ending_date,
                 ina.assignment_continuity_fk                                                               assignment_continuity_id,                  
                 ind.timecard_fk                                                                            timecard_id,
                 ind.timecard_entry_fk                                                                      timecard_entry_id,  
                 ind.assignment_bonus_fk                                                                    assignment_bonus_id,
                 ind.payment_request_fk                                                                     payment_request_id,
                 ind.payment_request_invdtl_fk                                                              payment_request_invdtl_id,
                 ind.expense_report_fk                                                                      expense_report_id,
                 ind.expense_report_line_item_fk                                                            expense_report_line_item_id,               
                 ina.direct_hire_agmt_fk                                                                    direct_hire_agmt_id,
                 ina.project_agreement_fk                                                                   project_agreement_id,               
                 inh.milestone_invoice_fk                                                                   milestone_invoice_id, 
                 ind.milestone_invoice_detail_fk                                                            milestone_invoice_detail_id,
                 ina.candidate_fk                                                                           candidate_id,
                 ina.candidate_last_name||'', ''||ina.candidate_first_name                                  candidate_name,
                 ina.manager_user_fk                                                                        hiring_mgr_person_id,
                 ina.manager_last_name||'', ''||ina.manager_first_name                                      hiring_mgr_name,
                 ina.sar_user_fk                                                                            sar_person_id,
                 ina.sar_last_name||'', ''||ina.sar_first_name                                              sar_name,
                 ina.org_sub_classification                                                                 org_sub_classification,
                 ibs.customer_supplier_internal_id                                                          customer_supplier_internal_id,
                 ind.accounting_code                                                                        accounting_code,
                 ina.buyer_resource_id                                                                      buyer_resource_id,
                 ind.ap_invoice_number                                                                      ap_invoice_number,
                 ind.is_vat_applied_on_fee                                                                  is_vat_applied_on_fee,  
                 ind.is_vat_applied_on_base                                                                 is_vat_applied_on_base,                 
                 ilib.amount                                                                                buyer_fee,  --when ind.flexrate_type is null
                 ilis.amount                                                                                supplier_fee, --when ind.flexrate_type is null    
                 ind.flexrate_mgmt_fee_amount                                                               flexrate_mgmt_fee_amount,
                 ind.buyer_fee_calc_percent                                                                 buyer_fee_calc_percent,
                 ind.supplier_fee_calc_percent                                                              supplier_fee_calc_percent,                    
                 ind.flexrate_type                                                                          flexrate_type,
                 ind.invoice_transaction_type                                                               invoice_transaction_type,
                 ind.expense_type_name                                                                      expense_type_name,
                 ind.payment_type_name                                                                      payment_type_name,
                 ind.invalidating_event_desc_fk                                                             invalidating_event_desc_id,
                 ind.reversed_expenditure_txn_fk                                                            reversed_expenditure_txn_id,
                 ind.invoiceable_mgmt_fee_txn_fk                                                            invoiceable_mgmt_fee_txn_id,
                 ind.custom_expenditure_type_fk                                                             custom_expenditure_type_id,
                 ind.custom_expenditure_type_desc                                                           custom_expenditure_type_desc,
                 ind.partial_rate_percent                                                                   partial_rate_percent,
                 ind.flexrate_exp_type_name_fk                                                              flexrate_exp_type_name,
                 ind.service_fk                                                                             service_id,
                 ind.service_identifier                                                                     service_identifier,                 
                 ind.service_exp_type_desc                                                                  service_exp_type_desc,
                 ind.service_exp_type_fk                                                                    service_exp_type_id,
                 ind.purchase_order                                                                         purchase_order,
                 inh.supplier_ref_number                                                                    supplier_reference_num,
                 ind.debit_credit_indicator                                                                 debit_credit_indicator,
                 ind.project_number                                                                         project_number, 
                 ibs.buyer_bus_org_bill_to_addr_fk                                                          buyer_bus_org_bill_to_addr_id,                     
                 ibs.buyer_taxable_country                                                                  buyer_taxable_country_id,
                 ibs.buyer_bus_org_tax_id                                                                   buyer_bus_org_tax_id,
                 ibs.supplier_bus_org_tax_id                                                                supplier_bus_org_tax_id,
                 ibs.supplier_taxable_country                                                               supplier_taxable_country_id,
                 ibs.is_iqn_mgmt_fee_payee                                                                  is_iqn_mgmt_fee_payee, 
                 ind.is_for_backoffice_reversal                                                             is_for_backoffice_reversal,  
                 ind.cac1_segment1_value                                                                    cac1_segment1_value,
                 ind.cac1_segment2_value                                                                    cac1_segment2_value, 
                 ind.cac1_segment3_value                                                                    cac1_segment3_value,
                 ind.cac1_segment4_value                                                                    cac1_segment4_value,
                 ind.cac1_segment5_value                                                                    cac1_segment5_value,
                 ind.cac2_segment1_value                                                                    cac2_segment1_value,
                 ind.cac2_segment2_value                                                                    cac2_segment2_value,
                 ind.cac2_segment3_value                                                                    cac2_segment3_value,
                 ind.cac2_segment4_value                                                                    cac2_segment4_value,
                 ind.cac2_segment5_value                                                                    cac2_segment5_value,
                 TRIM('':'' FROM ind.cac1_segment1_oid||'':''||ind.cac1_segment2_oid||'':''||ind.cac1_segment3_oid||'':''||ind.cac1_segment4_oid||'':''||ind.cac1_segment5_oid) cac1_oid,
                 TRIM('':'' FROM ind.cac2_segment1_oid||'':''||ind.cac2_segment2_oid||'':''||ind.cac2_segment3_oid||'':''||ind.cac2_segment4_oid||'':''||ind.cac2_segment5_oid) cac2_oid,                 
                 ind.rate_unit_fk                                                                           rate_unit_id,
                 ind.rate_identifier_fk                                                                     rate_identifier_id,
                 ind.rate_identifier_name                                                                   rate_identifier_name,
                 ind.base_bill_rate                                                                         base_bill_rate,
                 ind.base_pay_rate                                                                          base_pay_rate,
                 ind.buyer_adjusted_bill_rate                                                               buyer_adjusted_bill_rate,
                 ind.supplier_reimbursement_rate                                                            supplier_reimbursement_rate,
                 ind.flexrate_buyer_rate                                                                    flexrate_buyer_rate,
                 ind.flexrate_supplier_rate                                                                 flexrate_supplier_rate, 
                 ind.quantity                                                                               quantity,
                 ind.payment_amount                                                                         payment_amount,
                 ind.markup_amount                                                                          markup_amount,
                 ind.bill_amount                                                                            bill_amount,
                 ind.buyer_adjusted_amount                                                                  buyer_adjusted_amount,
                 ind.supplier_reimbursement_amount                                                          supplier_reimbursement_amount,
                 ind.flexrate_buyer_base_amount                                                             flexrate_buyer_base_amount,
                 ind.flexrate_buyer_amount                                                                  flexrate_buyer_amount,
                 ind.flexrate_supplier_base_amount                                                          flexrate_supplier_base_amount,
                 ind.flexrate_supplier_amount                                                               flexrate_supplier_amount,
                 ind.flexrate_mgmt_fee_base_amount                                                          flexrate_mgmt_fee_base_amount,
                 ind.curr_conv_info_fk                                                                      curr_conv_info_id,
                 cu.description                                                                             currency,
                 inv.business_organization_fk                                                               owning_bus_org_id,
                 '||r_new_det.buyer_enterprise_bus_org_id||'                                                buyer_enterprise_bus_org_id,
                 '''||pi_source||'''                                                                        source_name,'||CHR(10)                 
                 ||'TO_DATE('''||TO_CHAR(lv_load_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'') load_date
            FROM invoice@'||pi_db_link_name||'                    inv,
                 invoice_header@'||pi_db_link_name||'             inh,
                 invoice_detail@'||pi_db_link_name||'             ind,
                 invoiced_agreement@'||pi_db_link_name||'         ina,
                 invoiced_buyer_supplier@'||pi_db_link_name||'    ibs,
                 invoice_line_item@'||pi_db_link_name||'          ilib,
                 invoice_line_item@'||pi_db_link_name||'          ilis,
                 currency_unit@'||pi_db_link_name||'              cu
           WHERE inv.invoice_id                     = inh.invoice_fk
             AND inh.invoice_header_id              = ind.invoice_header_fk
             AND ina.invoiced_agreement_id          = inh.invoiced_agreement_fk
             AND ibs.invoiced_buyer_supplier_id     = ina.invoiced_buyer_supplier_fk
             AND ind.buyer_management_fees_fk       = ilib.identifier(+)
             AND ind.supplier_management_fees_fk    = ilis.identifier(+)
             AND cu.value                           = ind.currency_unit_fk
             AND inh.invoiceable_exp_owner_state_fk = 0 --for hold transaction
             AND ind.invalidating_event_desc_fk     IS NULL
             AND inv.invoice_id                     = '||r_new_det.invoice_id||'
             AND inv.business_organization_fk       = '||r_new_det.owning_buyer_org_id;                                                           
        
        lv_insert_sql := 'INSERT /*+APPEND*/ INTO lego_invoiced_expd_detail SELECT * FROM invd_expd_det_'||pi_source;
        
        logger_pkg.info('Creating temp table AND loading of records for invoice_id = '||r_new_det.invoice_id||', owning_buyer_org_id = '||r_new_det.owning_buyer_org_id||' - '||lv_ctas_sql||' - '||lv_insert_sql); 
        EXECUTE IMMEDIATE lv_ctas_sql; 
                        
        EXECUTE IMMEDIATE lv_insert_sql;  
        
        lv_load_time_sec := ROUND(86400 * (SYSDATE - lv_load_date),2);
        
        lv_records_loaded := SQL%ROWCOUNT;
        
        logger_pkg.info('Successfully loaded records for invoice_id = '||r_new_det.invoice_id||', owning_buyer_org_id = '||r_new_det.owning_buyer_org_id||' Number of records inserted: '||lv_records_loaded||' Load time in seconds: '||lv_load_time_sec, TRUE);
      
        UPDATE lego_invoice_approved
           SET load_date = lv_load_date,
               records_loaded   = lv_records_loaded,
               load_time_sec    = lv_load_time_sec
         WHERE object_name                 = pi_object_name
           AND source_name                 = pi_source
           AND invoice_id                  = r_new_det.invoice_id
           AND buyer_enterprise_bus_org_id = r_new_det.buyer_enterprise_bus_org_id
           AND owning_buyer_org_id         = r_new_det.owning_buyer_org_id;
         
        COMMIT;
        
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          logger_pkg.warn('Failed to load records for invoice_id = '||r_new_det.invoice_id||', owning_buyer_org_id = '||r_new_det.owning_buyer_org_id||' - '||SQLERRM || chr(10) || dbms_utility.format_error_backtrace||' - '||lv_insert_sql);
      END;
    
    END LOOP;     
    
    logger_pkg.unset_source(v_source); 
   
  END load_invd_expd_detail;
  
  PROCEDURE load_invd_expd_date_ru (pi_object_name      IN lego_object.object_name%TYPE,
                                    pi_source           IN lego_object.source_name%TYPE,
                                    pi_db_link_name     IN lego_source.db_link_name%TYPE,
                                    pi_src_name_short   IN lego_source.source_name_short%TYPE,
                                    pi_dependent_object IN lego_object.object_name%TYPE) AS
  
  CURSOR c_new_ru 
  IS
    SELECT ia_ru.invoice_id,
           ia_ru.buyer_enterprise_bus_org_id,
           ia_ru.owning_buyer_org_id,
           ia_ru.invoice_date
      FROM lego_invoice_approved ia_ru, lego_invoice_approved ia_det 
     WHERE ia_ru.source_name                  = ia_det.source_name
       AND ia_ru.invoice_id                   = ia_det.invoice_id
       AND ia_ru.buyer_enterprise_bus_org_id  = ia_det.buyer_enterprise_bus_org_id
       AND ia_ru.owning_buyer_org_id          = ia_det.owning_buyer_org_id
       AND ia_ru.load_date                    IS NULL
       AND ia_ru.object_name                  = pi_object_name
       AND ia_ru.source_name                  = pi_source
       AND ia_det.object_name                 = pi_dependent_object
       AND ia_det.source_name                 = pi_source
       AND ia_det.load_date                   IS NOT NULL
     ORDER BY ia_ru.invoice_date DESC, ia_ru.invoice_id DESC;
  
  v_source               VARCHAR2(61) := g_source || '.load_invd_expd_date_ru';
  lv_insert_sql          CLOB;  
  lv_load_date           lego_invoice_approved.load_date%TYPE;     
  lv_load_time_sec       lego_invoice_approved.load_time_sec%TYPE;
  lv_records_loaded      VARCHAR2(30);
  
  BEGIN
  
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('load_invd_expd_date_ru');    
  
    FOR r_new_ru IN c_new_ru LOOP
    
      BEGIN   
      
        lv_load_date := SYSDATE;                                                  
        
        lv_insert_sql := 
        'INSERT /*+APPEND*/ INTO lego_invd_expd_date_ru
             WITH asgmt AS (
               SELECT asgmt.assignment_continuity_id, asgmt.assignment_type, asgmt.job_id, asgmt.contractor_person_id, asgmt.assign_job_title, asgmt.jc_description AS job_category, 
                      asgmt.jl_description AS job_level, asgmt.assignment_start_dt, asgmt.assignment_actual_end_dt, asgmt.supplier_resource_id
                 FROM assignment_wo_'||pi_src_name_short||' asgmt
                UNION ALL
               SELECT asgmt.assignment_continuity_id, asgmt.assignment_type, asgmt.job_id, asgmt.contractor_person_id, asgmt.assign_job_title, asgmt.jc_description AS job_category, 
                      asgmt.jl_description AS job_level, asgmt.assignment_start_dt, asgmt.assignment_actual_end_dt, asgmt.supplier_resource_id
                 FROM assignment_ea_'||pi_src_name_short||' asgmt),
             sow AS (
                SELECT s.milestone_invoice_id, s.approver_person_id, apprv_per.display_name AS expenditure_approver, s.approved_date, s.sow_spend_category, s.sow_spend_type     
                  FROM sow_milestone_invoice_'||pi_src_name_short||' s,
                       person_'||pi_src_name_short||' apprv_per
                 WHERE s.approver_person_id = apprv_per.person_id(+)),
             apr AS (
                SELECT p.payment_request_id, p.approver_person_id, apprv_per.display_name AS expenditure_approver, p.approved_date     
                  FROM assign_payment_request_'||pi_src_name_short||' p,
                       person_'||pi_src_name_short||' apprv_per
                 WHERE p.approver_person_id = apprv_per.person_id(+)),        
             tca AS (
                SELECT t.timecard_id, t.approver_person_id, apprv_per.display_name AS expenditure_approver, t.approved_date     
                  FROM timecard_approval_'||pi_src_name_short||' t,
                       person_'||pi_src_name_short||' apprv_per
                 WHERE t.approver_person_id = apprv_per.person_id(+)),     
             ea  AS (
                SELECT e.expense_report_id, e.approver_person_id, apprv_per.display_name AS expenditure_approver, e.buyer_approved_date AS approved_date     
                  FROM expense_approval_'||pi_src_name_short||' e,
                       person_'||pi_src_name_short||' apprv_per
                 WHERE e.approver_person_id = apprv_per.person_id(+)) '||                                      
    
      q'{SELECT iedf.buyer_org_id, 
                bo.bus_org_name,
                iedf.supplier_org_id,
                so.bus_org_name,
                iedf.invoice_id,
                iedf.invoice_date invoice_date,
                iedf.expenditure_number,
               (CASE
                  WHEN ((iedf.timecard_id IS NOT NULL AND iedf.flexrate_type IS NULL) or (iedf.custom_expenditure_type_id = 2  AND iedf.flexrate_type IS NULL)) THEN 'Time'
                  WHEN (iedf.expense_report_id IS NOT NULL AND iedf.flexrate_type IS NULL) THEN 'Expense'
                  WHEN (iedf.assignment_bonus_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Assignment Bonus'
                  WHEN (iedf.direct_hire_agmt_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Direct Hire'
                  WHEN (iedf.payment_request_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Payment Requests'
                  WHEN (iedf.milestone_invoice_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Milestones'
                  WHEN (iedf.flexrate_type IS NOT NULL AND iedf.invalidating_event_desc_id IS NULL ) THEN 'Tax and Discounts'
                ELSE NULL
                END) transaction_type,         
       iedf.expenditure_date,
       iedf.week_ending_date,
      (CASE
       WHEN iedf.assignment_continuity_id IS NOT NULL THEN iedf.assignment_continuity_id
       WHEN iedf.direct_hire_agmt_id IS NOT NULL      THEN iedf.direct_hire_agmt_id
       WHEN iedf.milestone_invoice_id IS NOT NULL     THEN iedf.milestone_invoice_id
       END) work_order_id,   
      (CASE
       WHEN iedf.assignment_continuity_id IS NOT NULL THEN asgmt.assignment_type
       WHEN iedf.direct_hire_agmt_id IS NOT NULL THEN 'DH'
       WHEN iedf.milestone_invoice_id IS NOT NULL THEN 'M'
       END) work_order_type,
       CASE 
         WHEN iedf.timecard_id          IS NOT NULL THEN tca.approved_date
         WHEN iedf.expense_report_id    IS NOT NULL THEN ea.approved_date
         WHEN iedf.payment_request_id   IS NOT NULL THEN apr.approved_date
         WHEN iedf.milestone_invoice_id IS NOT NULL THEN sow.approved_date
       ELSE NULL
       END expenditure_approved_date,
       CASE 
         WHEN iedf.timecard_id          IS NOT NULL THEN tca.expenditure_approver
         WHEN iedf.expense_report_id    IS NOT NULL THEN ea.expenditure_approver
         WHEN iedf.payment_request_id   IS NOT NULL THEN apr.expenditure_approver
         WHEN iedf.milestone_invoice_id IS NOT NULL THEN sow.expenditure_approver
       ELSE NULL
       END expenditure_approver,    
       CASE 
         WHEN iedf.timecard_id          IS NOT NULL THEN tca.approver_person_id
         WHEN iedf.expense_report_id    IS NOT NULL THEN ea.approver_person_id
         WHEN iedf.payment_request_id   IS NOT NULL THEN apr.approver_person_id
         WHEN iedf.milestone_invoice_id IS NOT NULL THEN sow.approver_person_id
       ELSE NULL
       END expenditure_approver_pid,             
       iedf.customer_supplier_internal_id,
       iedf.accounting_code,
       iedf.buyer_resource_id,
       SUM(iedf.buyer_fee) buyer_fee,
       SUM(iedf.supplier_fee) supplier_fee,
       SUM(iedf.buyer_fee + iedf.supplier_fee) total_fee,
       iedf.cac1_segment1_value,
       iedf.cac1_segment2_value,
       iedf.cac1_segment3_value,
       iedf.cac1_segment4_value,
       iedf.cac1_segment5_value,
       iedf.cac2_segment1_value,
       iedf.cac2_segment2_value,
       iedf.cac2_segment3_value,
       iedf.cac2_segment4_value,
       iedf.cac2_segment5_value,
       iedf.candidate_name,
       asgmt.contractor_person_id,
       currency,
       iedf.hiring_mgr_name,
       iedf.hiring_mgr_person_id,
      (CASE
       WHEN ((iedf.timecard_id IS NOT NULL AND iedf.flexrate_type IS NULL) or (iedf.custom_expenditure_type_id = 2  AND iedf.flexrate_type IS NULL)) THEN 'Time'
       WHEN (iedf.expense_report_id IS NOT NULL AND iedf.flexrate_type IS NULL) THEN 'Expense'
       WHEN (iedf.assignment_bonus_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Assignment Bonus'
       WHEN (iedf.direct_hire_agmt_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Direct Hire'
       WHEN (iedf.payment_request_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Payment Requests'
       WHEN (iedf.milestone_invoice_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Milestones'
       WHEN (iedf.flexrate_type IS NOT NULL AND iedf.invalidating_event_desc_id IS NULL ) THEN 'Tax and Discounts'
       ELSE NULL
       END) spend_category,  
      (CASE
       WHEN (iedf.timecard_id IS NOT NULL AND iedf.flexrate_type IS NULL) THEN DECODE(iedf.rate_identifier_id,1,'ST',
                                                                                                              2,'OT',
                                                                                                              3,'DT',
                                                                                                                'CS')
       WHEN (iedf.payment_request_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN payment_type_name
       WHEN (iedf.milestone_invoice_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Milestone'
       WHEN (iedf.flexrate_type  = 'ST' AND iedf.invalidating_event_desc_id IS NULL ) THEN 'TAX'
       WHEN (iedf.flexrate_type  = 'D' AND iedf.invalidating_event_desc_id IS NULL ) THEN 'TD'
       WHEN (iedf.flexrate_type IS NOT NULL AND iedf.flexrate_type NOT IN ('ST','D') AND iedf.invalidating_event_desc_id IS NULL ) THEN 'Flex - '||iedf.flexrate_type
       WHEN (iedf.custom_expenditure_type_id = 2  AND iedf.flexrate_type IS NULL) THEN 'Rate Adjustment' 
       ELSE expense_type_name 
       END) spend_type,
       SUM(CASE 
           WHEN iedf.flexrate_type IS NULL THEN nvl(iedf.buyer_adjusted_amount,0)
           WHEN (iedf.flexrate_type IS NOT NULL AND iedf.invalidating_event_desc_id IS NULL) THEN nvl(iedf.flexrate_buyer_amount,0) 
           ELSE 0 
           END) buyer_adjusted_amount,
       SUM(CASE
           WHEN iedf.flexrate_type IS NULL THEN nvl(iedf.supplier_reimbursement_amount,0)
           WHEN (iedf.flexrate_type IS NOT NULL AND iedf.invalidating_event_desc_id IS NULL) THEN nvl(iedf.flexrate_supplier_amount,0) 
           ELSE 0 
           END) supplier_reimbursement_amount,
       SUM(CASE
           WHEN iedf.flexrate_type IS NULL THEN CASE
                                           WHEN iedf.invoiceable_mgmt_fee_txn_id IS NULL THEN nvl(iedf.quantity,0)*(decode(iedf.reversed_expenditure_txn_id,null,1,-1))
                                           ELSE 0
                                           END
           ELSE 0
           END) quantity,
       NVL(base_bill_rate,0) base_bill_rate,
       (CASE
        WHEN iedf.flexrate_type IS NULL THEN nvl(iedf.buyer_adjusted_bill_rate,0)
        WHEN (iedf.flexrate_type IS NOT NULL AND iedf.invalidating_event_desc_id IS NULL) THEN nvl(iedf.flexrate_buyer_rate,0)
        ELSE 0
        END) buyer_adjusted_bill_rate,
       (nvl(iedf.base_pay_rate,0)) base_pay_rate,
       (CASE
        WHEN iedf.flexrate_type IS NULL THEN nvl(iedf.supplier_reimbursement_rate,0)
        WHEN (iedf.flexrate_type IS NOT NULL AND invalidating_event_desc_id IS NULL) THEN nvl(iedf.flexrate_supplier_rate,0)
        ELSE 0
        END) supplier_reimbursement_rate,
       (CASE
        WHEN nvl(iedf.base_bill_rate,0) = 0 THEN 0
        ELSE(nvl(iedf.base_bill_rate,0) - nvl(iedf.base_pay_rate,0))/nvl(iedf.base_bill_rate,0)
        END) markup_pct,             
       iedf.supplier_reference_num,
       asgmt.supplier_resource_id,       
       iedf.project_agreement_id,
       pa.pa_name project_agreement_name,
       CASE
       WHEN (iedf.flexrate_type  = 'ST' AND iedf.invalidating_event_desc_id IS NULL ) THEN iedf.flexrate_exp_type_name
       ELSE NULL
       END tax_type,
       iedf.invoice_create_date invoice_creation_date,
       asgmt.assignment_start_dt assignment_start_date, 
       asgmt.assignment_actual_end_dt assignment_end_date,
       asgmt.job_id,
       asgmt.assign_job_title job_title,
       asgmt.job_category,
       asgmt.job_level,
       sow.sow_spend_category,
       sow.sow_spend_type,
       iedf.owning_buyer_org_id,
       iedf.buyer_enterprise_bus_org_id,
       iedf.source_name,}'||'
       TO_DATE('''||TO_CHAR(lv_load_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'')
  FROM lego_invoiced_expd_detail iedf,
       asgmt,
       sow,
       apr,
       tca,
       ea,
       project_agreement_'||pi_src_name_short||' pa,
       bus_org_'||pi_src_name_short||' bo,
       bus_org_'||pi_src_name_short||q'{ so
 WHERE iedf.assignment_continuity_id = asgmt.assignment_continuity_id(+)
   AND iedf.project_agreement_id     = pa.project_agreement_id(+)
   AND iedf.milestone_invoice_id     = sow.milestone_invoice_id(+)
   AND iedf.payment_request_id       = apr.payment_request_id(+)
   AND iedf.timecard_id              = tca.timecard_id(+)
   AND iedf.expense_report_id        = ea.expense_report_id(+)
   AND iedf.buyer_org_id             = bo.bus_org_id
   AND iedf.supplier_org_id          = so.bus_org_id
   AND iedf.invoice_id               = :1
   AND iedf.owning_buyer_org_id      = :2    
   AND iedf.source_name              = :3
 GROUP BY 
       iedf.buyer_org_id,
       bo.bus_org_name,
       iedf.supplier_org_id,
       so.bus_org_name,
       iedf.invoice_id,
       iedf.invoice_date,
       iedf.expenditure_number,
       CASE
       WHEN ((iedf.timecard_id IS NOT NULL AND iedf.flexrate_type IS NULL) or (iedf.custom_expenditure_type_id = 2  AND iedf.flexrate_type IS NULL)) THEN 'Time'
       WHEN (iedf.expense_report_id IS NOT NULL AND iedf.flexrate_type IS NULL) THEN 'Expense'
       WHEN (iedf.assignment_bonus_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Assignment Bonus'
       WHEN (iedf.direct_hire_agmt_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Direct Hire'
       WHEN (iedf.payment_request_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Payment Requests'
       WHEN (iedf.milestone_invoice_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Milestones'
       WHEN (iedf.flexrate_type IS NOT NULL AND iedf.invalidating_event_desc_id IS NULL ) THEN 'Tax and Discounts'
       ELSE NULL
       END,       
       iedf.expenditure_date,
       iedf.week_ending_date,
      CASE
       WHEN iedf.assignment_continuity_id IS NOT NULL THEN iedf.assignment_continuity_id
       WHEN iedf.direct_hire_agmt_id IS NOT NULL      THEN iedf.direct_hire_agmt_id
       WHEN iedf.milestone_invoice_id IS NOT NULL     THEN iedf.milestone_invoice_id
       END,   
      CASE
       WHEN iedf.assignment_continuity_id IS NOT NULL THEN asgmt.assignment_type
       WHEN iedf.direct_hire_agmt_id IS NOT NULL THEN 'DH'
       WHEN iedf.milestone_invoice_id IS NOT NULL THEN 'M'
       END,
       CASE 
         WHEN iedf.timecard_id          IS NOT NULL THEN tca.approved_date
         WHEN iedf.expense_report_id    IS NOT NULL THEN ea.approved_date
         WHEN iedf.payment_request_id   IS NOT NULL THEN apr.approved_date
         WHEN iedf.milestone_invoice_id IS NOT NULL THEN sow.approved_date
       ELSE NULL
       END,
       CASE 
         WHEN iedf.timecard_id          IS NOT NULL THEN tca.expenditure_approver
         WHEN iedf.expense_report_id    IS NOT NULL THEN ea.expenditure_approver
         WHEN iedf.payment_request_id   IS NOT NULL THEN apr.expenditure_approver
         WHEN iedf.milestone_invoice_id IS NOT NULL THEN sow.expenditure_approver
       ELSE NULL
       END,    
       CASE 
         WHEN iedf.timecard_id          IS NOT NULL THEN tca.approver_person_id
         WHEN iedf.expense_report_id    IS NOT NULL THEN ea.approver_person_id
         WHEN iedf.payment_request_id   IS NOT NULL THEN apr.approver_person_id
         WHEN iedf.milestone_invoice_id IS NOT NULL THEN sow.approver_person_id
       ELSE NULL
       END,         
       iedf.customer_supplier_internal_id,
       iedf.accounting_code,
       iedf.buyer_resource_id,
       iedf.cac1_segment1_value,
       iedf.cac1_segment2_value,
       iedf.cac1_segment3_value,
       iedf.cac1_segment4_value,
       iedf.cac1_segment5_value,
       iedf.cac2_segment1_value,
       iedf.cac2_segment2_value,
       iedf.cac2_segment3_value,
       iedf.cac2_segment4_value,
       iedf.cac2_segment5_value,
       iedf.candidate_name,
       asgmt.contractor_person_id,
       currency,
       iedf.hiring_mgr_name,
       iedf.hiring_mgr_person_id,
      CASE
       WHEN ((iedf.timecard_id IS NOT NULL AND iedf.flexrate_type IS NULL) or (iedf.custom_expenditure_type_id = 2  AND iedf.flexrate_type IS NULL)) THEN 'Time'
       WHEN (iedf.expense_report_id IS NOT NULL AND iedf.flexrate_type IS NULL) THEN 'Expense'
       WHEN (iedf.assignment_bonus_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Assignment Bonus'
       WHEN (iedf.direct_hire_agmt_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Direct Hire'
       WHEN (iedf.payment_request_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Payment Requests'
       WHEN (iedf.milestone_invoice_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Milestones'
       WHEN (iedf.flexrate_type IS NOT NULL AND iedf.invalidating_event_desc_id IS NULL ) THEN 'Tax and Discounts'
       ELSE NULL
       END,  
      CASE
       WHEN (iedf.timecard_id IS NOT NULL AND iedf.flexrate_type IS NULL) THEN DECODE(iedf.rate_identifier_id,1,'ST',
                                                                                                              2,'OT',
                                                                                                              3,'DT',
                                                                                                                'CS')
       WHEN (iedf.payment_request_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN payment_type_name
       WHEN (iedf.milestone_invoice_id IS NOT NULL and iedf.flexrate_type IS NULL) THEN 'Milestone'
       WHEN (iedf.flexrate_type  = 'ST' AND iedf.invalidating_event_desc_id IS NULL ) THEN 'TAX'
       WHEN (iedf.flexrate_type  = 'D' AND iedf.invalidating_event_desc_id IS NULL ) THEN 'TD'
       WHEN (iedf.flexrate_type IS NOT NULL AND iedf.flexrate_type NOT IN ('ST','D') AND iedf.invalidating_event_desc_id IS NULL ) THEN 'Flex - '||iedf.flexrate_type
       WHEN (iedf.custom_expenditure_type_id = 2  AND iedf.flexrate_type IS NULL) THEN 'Rate Adjustment' 
       ELSE expense_type_name 
       END,   
       NVL(base_bill_rate,0),
       CASE
        WHEN iedf.flexrate_type IS NULL THEN nvl(iedf.buyer_adjusted_bill_rate,0)
        WHEN (iedf.flexrate_type IS NOT NULL AND iedf.invalidating_event_desc_id IS NULL) THEN nvl(iedf.flexrate_buyer_rate,0)
        ELSE 0
        END,
       nvl(iedf.base_pay_rate,0),
       CASE
        WHEN iedf.flexrate_type IS NULL THEN nvl(iedf.supplier_reimbursement_rate,0)
        WHEN (iedf.flexrate_type IS NOT NULL AND invalidating_event_desc_id IS NULL) THEN nvl(iedf.flexrate_supplier_rate,0)
        ELSE 0
        END,
       CASE
        WHEN nvl(iedf.base_bill_rate,0) = 0 THEN 0
        ELSE(nvl(iedf.base_bill_rate,0) - nvl(iedf.base_pay_rate,0))/nvl(iedf.base_bill_rate,0)
        END,       
       iedf.supplier_reference_num,
       asgmt.supplier_resource_id,
       iedf.project_agreement_id,
       pa.pa_name,
       CASE
       WHEN (iedf.flexrate_type  = 'ST' AND iedf.invalidating_event_desc_id IS NULL ) THEN iedf.flexrate_exp_type_name
       ELSE NULL
       END,
       iedf.invoice_create_date,
       asgmt.assignment_start_dt, 
       asgmt.assignment_actual_end_dt,       
       asgmt.job_id,
       asgmt.assign_job_title,
       asgmt.job_category,
       asgmt.job_level,       
       sow.sow_spend_category,
       sow.sow_spend_type,
       iedf.owning_buyer_org_id,
       iedf.buyer_enterprise_bus_org_id,
       iedf.source_name,}'||'
       TO_DATE('''||TO_CHAR(lv_load_date,'MM/DD/YYYY HH24:MI:SS')||''',''MM/DD/YYYY HH24:MI:SS'')';                                               
        
        logger_pkg.info('Loading records for invoice_id = '||r_new_ru.invoice_id||', owning_buyer_org_id = '||r_new_ru.owning_buyer_org_id||' - '||lv_insert_sql); 
        EXECUTE IMMEDIATE lv_insert_sql USING r_new_ru.invoice_id, r_new_ru.owning_buyer_org_id, pi_source;
        
        lv_load_time_sec := ROUND(86400 * (SYSDATE - lv_load_date),2);
        
        lv_records_loaded := SQL%ROWCOUNT;
        
        logger_pkg.info('Successfully loaded records for invoice_id = '||r_new_ru.invoice_id||', owning_buyer_org_id = '||r_new_ru.owning_buyer_org_id||' Number of records inserted: '||lv_records_loaded||' Load time in seconds: '||lv_load_time_sec, TRUE);
      
        UPDATE lego_invoice_approved
           SET load_date = lv_load_date,
               records_loaded   = lv_records_loaded,
               load_time_sec    = lv_load_time_sec
         WHERE object_name                 = pi_object_name
           AND source_name                 = pi_source
           AND invoice_id                  = r_new_ru.invoice_id
           AND buyer_enterprise_bus_org_id = r_new_ru.buyer_enterprise_bus_org_id
           AND owning_buyer_org_id         = r_new_ru.owning_buyer_org_id;
         
        COMMIT;
        
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          logger_pkg.warn('Failed to load records for invoice_id = '||r_new_ru.invoice_id||', owning_buyer_org_id = '||r_new_ru.owning_buyer_org_id||' - '||SQLERRM || chr(10) || dbms_utility.format_error_backtrace||' - '||lv_insert_sql);
      END;
    
    END LOOP;
    
    logger_pkg.unset_source(v_source); 
   
  END load_invd_expd_date_ru;   
  
  PROCEDURE invoice_load (pi_object_name lego_object.object_name%TYPE,
                          pi_source      lego_object.source_name%TYPE) AS
  
  v_source               VARCHAR2(61) := g_source || '.invoice_load';
  lv_db_link_name        lego_source.db_link_name%TYPE;
  lv_load_date           lego_invoice_approved.load_date%TYPE := SYSDATE;
  lv_load_time_sec       lego_invoice_approved.load_time_sec%TYPE;
  lv_ins_inv_apprv       CLOB;
  lv_ins_buyers_by_ent   CLOB;
  lv_insert_inv_sql      CLOB;
  lv_records_loaded      VARCHAR2(30);
  lv_part_sql            VARCHAR2(2000);
  lv_alter_tbl_part_sql  VARCHAR2(4000);
  lv_part_list           VARCHAR2(4000);
  lv_src_name_short      VARCHAR2(30);

         
  CURSOR c_new_part 
  IS
    WITH new_ents AS (   
      SELECT buyer_enterprise_bus_org_id, 'P_'||buyer_enterprise_bus_org_id part_name
        FROM lego_buyers_by_ent_inv_gtt  --this table is built joined to lego_invoice_approved
       MINUS
      SELECT buyer_enterprise_bus_org_id, part_name
        FROM lego_part_by_enterprise_gtt) 
      
      SELECT buyer_enterprise_bus_org_id, 
             part_name, 
             LISTAGG(buyer_org_id,', ') WITHIN GROUP (ORDER BY buyer_org_id) part_list   
        FROM (SELECT DISTINCT bye.buyer_enterprise_bus_org_id, bye.buyer_org_id, ie.part_name
                FROM lego_buyers_by_ent_inv_gtt bye,  --this table is built joined to lego_invoice_approved
                     new_ents ie
               WHERE bye.buyer_enterprise_bus_org_id = ie.buyer_enterprise_bus_org_id)
       GROUP BY buyer_enterprise_bus_org_id, part_name; 
      
  CURSOR c_chg_part 
  IS
   WITH chg_ents AS (  --all partitioned ents that already exist that may or may not have changed
      SELECT pbe.buyer_enterprise_bus_org_id, 
             pbe.part_name
        FROM lego_part_by_enterprise_gtt pbe)
    
      SELECT chg_ents.buyer_enterprise_bus_org_id, chg_ents.part_name, buyer_org_id 
        FROM chg_ents,
             --all possible values for which their are approved invoices
            (
            SELECT 'P_'||bye.buyer_enterprise_bus_org_id part_name, bye.buyer_enterprise_bus_org_id, bye.buyer_org_id 
               FROM lego_buyers_by_ent_inv_gtt bye
              MINUS   
             --those values already in partitions
             SELECT iedp.part_name, iedp.buyer_enterprise_bus_org_id, iedp.buyer_org_id
               FROM lego_part_by_ent_buyer_org_gtt iedp 
               ) new_vals
       WHERE chg_ents.buyer_enterprise_bus_org_id = new_vals.buyer_enterprise_bus_org_id;
    
  BEGIN
    --logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('invoice_load');    
    
    /* get the actual dblink based on the input value of pi_source */
    lv_db_link_name := lego_tools.get_db_link_name(pi_source);
    
    /* get source_name_short from lego_source to append to lego tables */
    lv_src_name_short := lego_tools.get_src_name_short(pi_source);
    
    /* This query gets invoice IDs from the FO invoice table along with a few 
       other attributes.  Note that the value for inv.business_organization_fk
       is the owning buyer org ID, which may be different than the buyer org ID
       associated with the assignment or project agreement. Basically, there is 
       one organization associated with the invoice record but multiple buyer
       organizations associated with the invoice detail. Therefore, since this 
       table is maent to track the loading of details for each INVOICE, it must
       store the owning buyer org ID as opposed to the various buyer org IDs
       in the detail. */
    lv_ins_inv_apprv := 
    'INSERT INTO lego_invoice_approved
       SELECT DISTINCT
              '''||pi_object_name||'''          object_name,
              '''||pi_source||'''               source_name,
              inv.invoice_id,
              bo.enterprise_bus_org_id      buyer_enterprise_bus_org_id,
              inv.business_organization_fk  owning_buyer_org_id,
              inv.invoice_date,
              NULL load_date,
              NULL load_time_sec,
              NULL records_loaded
         FROM invoice@'||lv_db_link_name||' inv,
              invoiced_buyer_supplier@'||lv_db_link_name||' ibs,
              operationalstore.bus_org_'||lv_src_name_short||' bo
        WHERE ibs.buyer_bus_org_fk = bo.bus_org_id
          AND inv.invoice_id = ibs.invoice_fk
          AND inv.state_fk = 2
          AND inv.expenditure_count > 0        
        MINUS
       SELECT '''||pi_object_name||'''          object_name,
              '''||pi_source||'''               source_name,
              invoice_id, 
              buyer_enterprise_bus_org_id,
              owning_buyer_org_id,
              invoice_date,
              NULL load_date,
              NULL load_time_sec,
              NULL records_loaded
         FROM lego_invoice_approved
        WHERE object_name = '''||pi_object_name||'''
          AND source_name = '''||pi_source||'''
        ORDER BY invoice_date DESC, invoice_id DESC';
        
    lv_ins_buyers_by_ent :=
    'INSERT INTO lego_buyers_by_ent_inv_gtt
       SELECT DISTINCT 
              :1                       object_name,
              :2                       source_name,
              bo.enterprise_bus_org_id buyer_enterprise_bus_org_id,
              ibs.buyer_bus_org_fk     buyer_org_id,
              ibs.invoice_fk           invoice_id,
              :3                       load_date
         FROM lego_invoice_approved ia,
              invoiced_buyer_supplier@'||lv_db_link_name||' ibs,
              operationalstore.bus_org_'||lv_src_name_short||' bo
        WHERE ia.invoice_id        = ibs.invoice_fk
          AND ibs.buyer_bus_org_fk = bo.bus_org_id
          AND ia.load_date         IS NULL --?? not sure about is
          AND object_name          = '''||pi_object_name||'''
          AND source_name          = '''||pi_source||'''';       

    logger_pkg.info('INSERT newly approved invoice IDs into lego_invoice_approved - '||lv_ins_inv_apprv);    
    EXECUTE IMMEDIATE lv_ins_inv_apprv;  
    logger_pkg.info('Successfully inserted newly approved invoice IDs into lego_invoice_approved. Number of records loaded: '||SQL%ROWCOUNT,TRUE);
    COMMIT;
    
    logger_pkg.info('INSERT newly approved invoices by enterprise and their associated buyer orgs - '||lv_ins_buyers_by_ent);    
    EXECUTE IMMEDIATE lv_ins_buyers_by_ent USING pi_object_name, pi_source, lv_load_date;    
    logger_pkg.info('Successfully inserted newly approved invoices by enterprise and their associated buyer orgs. Number of records loaded: '||SQL%ROWCOUNT,TRUE);    
    COMMIT;
    
    /* Call procedure to get all partitions and partition values for the target table, converting from concatenated string to table.
       This table will be used to determine if new partitions or partition values are needed. */
    parse_partition_values (pi_object_name => pi_object_name,
                            pi_source      => pi_source);
    
    FOR r_new_part IN c_new_part --(pi_object_name, pi_source) 
    LOOP
    /* Which enterprises are new that need to have partitions added for each of them? */
      BEGIN                       
        --lv_alter_tbl_part_sql := 'ALTER TABLE lego_invoiced_expd_detail ADD PARTITION :1 VALUES (:2)';
        lv_alter_tbl_part_sql := 'ALTER TABLE '||pi_object_name||' ADD PARTITION '||r_new_part.part_name||' VALUES ('||r_new_part.part_list ||')';
        logger_pkg.info('Create new partition: '||lv_alter_tbl_part_sql);
        
        --EXECUTE IMMEDIATE lv_alter_tbl_part_sql USING r_new_part.part_name, lv_part_list;
        EXECUTE IMMEDIATE lv_alter_tbl_part_sql;
        
        logger_pkg.info('Successfully created new partition: '||lv_alter_tbl_part_sql,TRUE);
  
      EXCEPTION
        WHEN OTHERS THEN
          logger_pkg.warn('Failed to create new partition: '||SQLERRM || chr(10) || dbms_utility.format_error_backtrace||' - '||lv_part_sql||' - '||r_new_part.part_name||' - '||r_new_part.part_list||' - '||lv_alter_tbl_part_sql);
      END;
      
    END LOOP;
    
    FOR r_chg_part IN c_chg_part --(pi_object_name, pi_source) 
    LOOP
    /* The query associated with this cursor represents the enterprise orgs that alredy exist
       in user_tab_partitions.  What we are trying to do is check to see if any new buyer_org_id
       values have been discovered as part of the enterprise, so that we can add those values to
       the List Partition with MODIFIY PARTITION ADD VALUES. 
      
       For each enterprise in the loop (those that already have partitions) MINUS the buyer
       org IDs to determine which are newly added based on new invoices.  Then loop through
       those, adding them to the already existing List Partition. */
    
      BEGIN
        /*We must join back to lego_invoice_approved because some invoices were created under multiple enterprises but they were never approved.
          Joining back helps us to only consider those that were approved. */                 
      
        lv_alter_tbl_part_sql := 'ALTER TABLE '||pi_object_name||' MODIFY PARTITION '||r_chg_part.part_name ||' ADD VALUES ('||r_chg_part.buyer_org_id||')';
        logger_pkg.info('Add new value: '||r_chg_part.part_name||' to partition: '||r_chg_part.buyer_org_id);
        
        EXECUTE IMMEDIATE lv_alter_tbl_part_sql;
        
        logger_pkg.info('Successfully created new value for partition: '||lv_alter_tbl_part_sql,TRUE);
    
      EXCEPTION
        WHEN OTHERS THEN
          logger_pkg.warn('Failed to add new value to partition: '||SQLERRM || chr(10) || dbms_utility.format_error_backtrace||' - '||lv_alter_tbl_part_sql);
      END;    
    
    
    END LOOP;
    
    --There may be no new invoices but still have invoices waiting in lego_invoice_approved with detail_load_date = NULL
    IF pi_object_name = 'LEGO_INVOICED_EXPD_DETAIL' THEN
      
      load_invd_expd_detail (pi_object_name  => pi_object_name,
                             pi_source       => pi_source,
                             pi_db_link_name => lv_db_link_name);
      
      
    ELSIF pi_object_name = 'LEGO_INVD_EXPD_DATE_RU' THEN
     
       load_invd_expd_date_ru (pi_object_name      => pi_object_name,
                               pi_source           => pi_source,
                               pi_db_link_name     => lv_db_link_name,
                               pi_src_name_short   => lv_src_name_short,
                               pi_dependent_object => 'LEGO_INVOICED_EXPD_DETAIL');
    
    ELSE
      NULL;
       
    END IF;

    logger_pkg.info('Invoiced Expenditure Load Complete!');
    logger_pkg.info('Invoiced Expenditure Load Complete!', TRUE);
    logger_pkg.unset_source(v_source);
    
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;     
      gv_error_stack := SQLERRM || chr(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal('ROLLBACK', SQLCODE, 'Error loading invoiced expenditure details ' || SQLERRM);      
      logger_pkg.unset_source(v_source);
      RAISE;
  
  END invoice_load;
  
END lego_invoice;
/