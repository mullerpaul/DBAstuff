DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_SOW_SERVICE_RATETBL_RATES';
  lv_syn_name    lego_refresh.synonym_name%TYPE := REPLACE(lv_object_name, 'LEGO_') || '_IQP';

BEGIN
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
     'TWICE DAILY',
     20,
     3,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);


  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS rate_table_continuity_id,
                                0 AS rate_table_edition_id,          
                                0 AS service_rate_id,       
                                0 AS service_id,
                                'abc' AS services_rate_table_type,
                                'abc' AS rate_table_name,          
                                'abc' AS service_name,
                                sysdate AS effective_from,
                                sysdate AS effective_to,
                                'abc' AS service_expenditure_type,       
                                0 AS is_negotiable, 
                                0 AS lower_service_rate, 
                                0 AS upper_service_rate, 
                                'abc' AS rate_table_rate_type, 
                                'abc' AS fee_classification,
                                0 AS measurement_unit_id
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';
  
  
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
     'TWICE DAILY',
     20,
     3,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);
     
 COMMIT; 

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS rate_table_continuity_id,
                                0 AS rate_table_edition_id,          
                                0 AS service_rate_id,       
                                0 AS service_id,
                                'abc' AS services_rate_table_type,
                                'abc' AS rate_table_name,          
                                'abc' AS service_name,
                                sysdate AS effective_from,
                                sysdate AS effective_to,
                                'abc' AS service_expenditure_type,       
                                0 AS is_negotiable, 
                                0 AS lower_service_rate, 
                                0 AS upper_service_rate, 
                                'abc' AS rate_table_rate_type, 
                                'abc' AS fee_classification,
                                0 AS measurement_unit_id
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  

END;
/