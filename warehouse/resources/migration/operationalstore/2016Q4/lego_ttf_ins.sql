DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_TIME_TO_FILL';
  lv_syn_name    lego_refresh.synonym_name%TYPE := REPLACE(lv_object_name, 'LEGO_') || '_IQP';
  
  PROCEDURE make_table_and_syn(lv_table_name   IN VARCHAR2,
                               lv_synonym_name IN VARCHAR2) AS
  BEGIN
    EXECUTE IMMEDIATE 'create table ' || lv_table_name || 
                   q'{ as SELECT 0 AS buyer_enterprise_bus_org_id,
                                 'abc' AS buyer_enterprise_name,  
                                 0 AS buyer_org_id,
                                 'abc' AS buyer_name,
                                 0 AS job_id,
                                 0 AS procurement_wflw_agree_type,
                                 0 AS job_requisition_type,
                                 0 AS position_pool_id,
                                 0 AS position_id,
                                 0 AS position_history_id,
                                 0 AS position_filled_flag,  
                                 0 AS days_to_position_close,
                                 'abc' AS position_state,
                                 SYSDATE AS position_available_date,
                                 SYSDATE AS position_offer_accepted_date,
                                 SYSDATE AS position_eliminated_date,
                                 SYSDATE AS position_abandoned_date,   
                                 SYSDATE AS reference_date,  
                                 'abc' AS job_category_desc,
                                 'abc' AS job_title,
                                 'abc' AS job_currency,
                                 'abc' AS job_rate_type,
                                 0 AS rate_min,
                                 0 AS rate_max,
                                 'abc' AS custom_city, 
                                 'abc' AS standard_city, 
                                 'abc' AS custom_state, 
                                 'abc' AS standard_state, 
                                 0 AS postal_code, 
                                 'abc' AS custom_country, 
                                 'abc' AS standard_country, 
                                 'abc' AS custom_country_code, 
                                 'abc' AS standard_country_code
                            FROM dual WHERE 1=0}';
  
    EXECUTE IMMEDIATE 'create synonym ' || lv_synonym_name || ' for ' || lv_table_name;
  
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END make_table_and_syn;

BEGIN
  /* Insert IQP row and create dummy table & syn for IQP */                     
  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name)
  VALUES
    (lv_object_name,
     'USPROD',
     'SQL TOGGLE',
     'DAILY',
     8,
     2,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);

  /* Dummy table and synonym so that view can be created valid. */
  make_table_and_syn(lv_table_name => lv_syn_name || '1',
                     lv_synonym_name => lv_syn_name);
                     

  /* Insert WF row and create dummy table & syn for WF */                     
  lv_syn_name := REPLACE(lv_object_name, 'LEGO_') || '_WF';
  
  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     refresh_schedule,
     refresh_group,
     refresh_dependency_order,
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name)
  VALUES
    (lv_object_name,
     'WFPROD',
     'SQL TOGGLE',
     'DAILY',
     8,
     2,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);
     
  /* Dummy table and synonym so that view can be created valid. */
  make_table_and_syn(lv_table_name => lv_syn_name || '1',
                     lv_synonym_name => lv_syn_name);

  /* Its not strictly needed due to the DDL; but we'll commit here.  This means that if the 
     dummy tables/syns can't be created for some reason, the LEGO_REFRESH rows will be 
     commited anyway. */
  COMMIT;

END;
/
