DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_SOW_COMPLEX_RESOURCE';
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
                 q'{  as SELECT 0 AS project_resource_desc_id, 
                                0 AS project_agreement_id,  
                                0 AS rate_table_edition_id, 
                                0 AS service_rate_id, 
                                sysdate AS estimated_start_date, 
                                sysdate AS estimated_end_date, 
                                0 AS estimated_units, 
                                0 AS number_of_resources, 
                                0 AS estimated_cost
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
                 q'{  as SELECT 0 AS project_resource_desc_id, 
                                0 AS project_agreement_id,  
                                0 AS rate_table_edition_id, 
                                0 AS service_rate_id, 
                                sysdate AS estimated_start_date, 
                                sysdate AS estimated_end_date, 
                                0 AS estimated_units, 
                                0 AS number_of_resources, 
                                0 AS estimated_cost
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  

END;
/