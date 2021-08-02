/* Joe Pullifrone
   IQN-33370
   07/10/2016

   This script will mark chain steps 2-5 to be "skipped"
   so that those steps do not run.  These steps will 
   skip the following steps in the DM_CHAIN_DAILY chain:
   
   DM_PG_TT_FILL_FACT_PROCESS  (dm_tt_fill_fact_process.p_main)
   DM_PG_HC_FACT_DAILY_PROCESS (dm_headcount_fact_process.p_main)
   DM_PG_INV_HC_FACT_PROCESS   (dm_inv_headcount_fact_process.p_main)
   DM_PG_INVOICE_FACT_PROCESS  (dm_invoiced_cac_dim_process.p_main, dm_invoice_fact_process.p_main)
   
   This step will continue to run: DM_DAILY_PROCESS

*/
DECLARE
  le_chain_not_exist EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_chain_not_exist, -27476);
  
BEGIN
    DBMS_SCHEDULER.ALTER_CHAIN (
       chain_name              => 'DM_CHAIN_DAILY',
       step_name               => 'STEP2',
       attribute               => 'SKIP',
       value                   => TRUE);
       
    DBMS_SCHEDULER.ALTER_CHAIN (
       chain_name              => 'DM_CHAIN_DAILY',
       step_name               => 'STEP3',
       attribute               => 'SKIP',
       value                   => TRUE);     

    DBMS_SCHEDULER.ALTER_CHAIN (
       chain_name              => 'DM_CHAIN_DAILY',
       step_name               => 'STEP4',
       attribute               => 'SKIP',
       value                   => TRUE);
       
    DBMS_SCHEDULER.ALTER_CHAIN (
       chain_name              => 'DM_CHAIN_DAILY',
       step_name               => 'STEP5',
       attribute               => 'SKIP',
       value                   => TRUE);     
  
EXCEPTION
  WHEN le_chain_not_exist
    THEN NULL;
           
END;
/
