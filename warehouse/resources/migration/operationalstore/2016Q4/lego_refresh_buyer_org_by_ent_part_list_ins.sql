DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_BUYER_BY_ENT_PART_LIST';
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
     1,
     1,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);


  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0     AS buyer_enterprise_bus_org_id, 
                                'abc' AS part_name,  
                                'abc' AS part_list 
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
     1,
     1,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name);
     
 COMMIT; 

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0     AS buyer_enterprise_bus_org_id, 
                                'abc' AS part_name,  
                                'abc' AS part_list 
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';  

END;
/