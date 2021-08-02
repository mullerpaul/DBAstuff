CREATE OR REPLACE PROCEDURE dw_saturday_process
AS
BEGIN

  IF ltrim(rtrim(to_char(sysdate,'DAY'))) = ('SATURDAY') THEN
     DIM_DAILY_PROCESS;
     dm_inv_headcount_fact_process.p_main;
     --dm_headcount_fact_process.p_main;
  END IF;
END dw_saturday_process;
/
