DECLARE

lv_insert_record_count PLS_INTEGER;
lv_script_being_tested VARCHAR2(255) := 'warehouse\src\main\resources\migration\iqprodm\2017Q3\dm_date_dim_top_level_default_insert_iqn-38261.sql';


BEGIN

  SELECT COUNT(*)
    INTO lv_insert_record_count
	FROM dm_date_dim
   WHERE top_parent_buyer_org_id = 0
     AND day_dt >= TO_DATE('01/01/2017','MM/DD/YYYY');
	 
  IF lv_insert_record_count <> 2556 THEN
    raise_application_error (-20010, 'Unit Test Failed for '||lv_script_being_tested);
  END IF;

END;
/