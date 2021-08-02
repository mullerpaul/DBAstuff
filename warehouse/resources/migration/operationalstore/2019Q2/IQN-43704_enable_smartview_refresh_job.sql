DECLARE
  lv_value varchar2(240) := 'BEGIN lego_refresh_smartview.start_refresh_run(240, ''WFPROD'', ''LEGO_JOB''); END;';
  ln_count      NUMBER := 0;
BEGIN
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE (
    name         =>  '"TEMP_REFRESH_SSC_SMARTVW_LEGOS"',
    attribute    =>  'JOB_ACTION',
    value        =>  lv_value
  );
  
  SYS.dbms_scheduler.set_attribute (
    name      =>  'TEMP_REFRESH_SSC_SMARTVW_LEGOS',
    attribute =>  'START_DATE',
    value     =>  SYSDATE);
    
  SELECT COUNT(1)
  INTO ln_count
  FROM
  (SELECT db_link FROM all_db_links WHERE db_link = 'FO_WAP'
  UNION SELECT db_link FROM user_db_links WHERE db_link = 'FO_WAP') db;
  
  IF ln_count <> 0 THEN
    DBMS_SCHEDULER.ENABLE('TEMP_REFRESH_SSC_SMARTVW_LEGOS');
  END IF;
  
  COMMIT;
END;
/