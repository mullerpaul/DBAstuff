DECLARE
  lv_object_name      lego_refresh.object_name%TYPE := 'LEGO_MSP_USER_AVAILABLE_ORG';
  lv_synonym_name     VARCHAR2(29)                  := 'MSP_USER_AVAILABLE_ORG_IQP';
  lv_refresh_schedule lego_refresh.refresh_schedule%TYPE;
  lv_refresh_time     lego_refresh.refresh_on_or_after_time%TYPE;
  
BEGIN
  /* Get the refresh schedule and time from a similar lego in the same environment.
     This way, in envs where we don't run legos, the new lego is also unscheduled; but it
     will be scheduled in envs. with legos running.  */
  BEGIN
    /* This lookup by PK can only return 1 or 0 rows */
    SELECT refresh_schedule, refresh_on_or_after_time
      INTO lv_refresh_schedule, lv_refresh_time
      FROM lego_refresh
     WHERE object_name = 'LEGO_PERSON_AVAILABLE_ORG'
       AND source_name = 'USPROD';

  EXCEPTION
    WHEN no_data_found THEN 
      lv_refresh_schedule := 'DAILY';
      lv_refresh_time     := NULL;
  END;  

  /* Now insert row. */
  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     refresh_on_or_after_time, 
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name)
  VALUES
    (lv_object_name,
     'USPROD',
     'SQL TOGGLE',
     lv_refresh_schedule,
     2,
     1,
     lv_refresh_time, 
     'NOLOGGING',
     lv_synonym_name || '1',
     lv_synonym_name || '2',
     lv_synonym_name);

  COMMIT;

  /* Dummy table and synonym so that converence_search load package can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_synonym_name || '1' || 
                    q'{  as SELECT 0     AS msp_user_id,
                                   'abc' AS user_name, 
                                   0     AS user_name_domain_fk,
                                   0     AS available_org_id
                              FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_synonym_name || 
                    ' for ' || lv_synonym_name || '1';

END;
/


