CREATE OR REPLACE PROCEDURE DIM_DAILY_PROCESS
AS
/******************************************************************************
 * Name: dim_daily_process
 * Desc: This procedure contains calls to other procedures as part of a daily 
 *       refresh process.
 *       load invoice/spend data
 *
 * Author        Date        Version   History
 * -----------------------------------------------------------------
 * Unknown       Unknown     1.0       Initial
 * jpullifrone   08/04/2016  1.01      IQN-33878 - Commented out all but 3 jobs.
 ******************************************************************************/
  ln_date_id NUMBER := TO_NUMBER(TO_CHAR(sysdate,'YYYYMMDD'));
  ld_date DATE;
BEGIN
       /*
       ** Alter session so that process/optimizer
       ** can see all invisible indexes
       */
       dm_cube_utils.make_indexes_visible;
  
  DM_ORG_DIM.p_main('REGULAR',ln_date_id);
  DM_PERSON_DIM_PROCESS.main('REGULAR',ln_date_id);
  DM_JOB_DIM_PROCESS.p_main('REGULAR',ln_date_id);
  
  --DM_PROJECT_AGREEMENT_DIM_PRCS.p_main('REGULAR',ln_date_id);
  --DM_ASSIGNMENT_DIM_PROCESS.p_main('REGULAR', ln_date_id);
  --DM_EXPENDITURE_DIM_PROCESS.p_main('REGULAR');
  --upd_cube_dim_load_status(ln_date_id,'SPEND_CUBE-DIM');
  --dm_worker_dim_process.p_main('REGULAR',ln_date_id);
  --dm_buyer_supp_agmt_process.p_main(ln_date_id);
  --upd_cube_dim_load_status(ln_date_id,'CUBE-DIM');
  
  DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_ORGANIZATION_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
  DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_BUYER_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
  DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_SUPPLIER_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
  --DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_WORKER_DIM', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE); 
  --DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_BUYER_SUPPLIER_AGMT', ESTIMATE_PERCENT=>20, METHOD_OPT=>'FOR ALL INDEXED COLUMNS SIZE SKEWONLY', cascade=>TRUE, no_invalidate=>FALSE);
   
END;
/
