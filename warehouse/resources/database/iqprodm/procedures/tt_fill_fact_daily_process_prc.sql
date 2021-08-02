CREATE OR REPLACE PROCEDURE tt_fill_fact_daily_process
AS
BEGIN
  IF ltrim(rtrim(to_char(sysdate,'DAY'))) NOT IN ('FRIDAY') THEN      
     dm_tt_fill_fact_process.p_main;
  END IF;
END tt_fill_fact_daily_process;
/
