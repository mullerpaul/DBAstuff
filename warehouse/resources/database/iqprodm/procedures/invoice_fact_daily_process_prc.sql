CREATE OR REPLACE PROCEDURE invoice_fact_daily_process
AS
  ln_date_id NUMBER := TO_NUMBER(TO_CHAR(sysdate,'YYYYMMDD'));
  ld_date DATE;
BEGIN
 IF ltrim(rtrim(to_char(sysdate,'DAY'))) NOT IN ('FRIDAY') THEN 
    DM_INVOICED_CAC_DIM_PROCESS.p_main('REGULAR',ln_date_id);
    upd_cube_dim_load_status(ln_date_id,'SPEND_CUBE-DIM');
 
   dm_invoice_fact_process.p_main;
 END IF;
END invoice_fact_daily_process;
/
