CREATE OR REPLACE PROCEDURE invoice_spend_all_process
AS
BEGIN
  --This job will not run Friday 8PM through Saturday 7AM
  --621 means 6th day( Friday) 21 (9PM)
  --707 means 7th day( Saturday) 07 (7AM)

  IF ( TO_NUMBER(ltrim(rtrim(to_char(sysdate,'D')))||to_char(sysdate,'HH24')) < 616 OR TO_NUMBER(ltrim(rtrim(to_char(sysdate,'D')))||to_char(sysdate,'HH24')) > 708 )  THEN      
     DM_INVOICED_SPEND.p_main;
  
    --Run MV Refresh, dm_buyer_invd_assign_spnd_mon, 1x/day at 11:00p
    IF TO_CHAR(SYSDATE,'HH24') = '23' THEN
      DBMS_MVIEW.REFRESH('DM_BUYER_INVD_ASSIGN_SPND_MON','C');
    END IF;
  
  END IF;

END invoice_spend_all_process;
/
