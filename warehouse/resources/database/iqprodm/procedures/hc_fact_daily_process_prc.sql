CREATE OR REPLACE PROCEDURE hc_fact_daily_process
AS
BEGIN
  IF ltrim(rtrim(to_char(sysdate,'DAY'))) NOT IN ('FRIDAY') THEN      
     dm_headcount_fact_process.p_main;
  END IF;
END hc_fact_daily_process;
/
