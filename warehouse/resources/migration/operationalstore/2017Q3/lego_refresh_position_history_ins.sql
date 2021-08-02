DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_POSITION_HISTORY';
  lv_syn_name    lego_refresh.synonym_name%TYPE := REPLACE(lv_object_name, 'LEGO_') || '_IQP';
  
  PROCEDURE make_table_and_syn(lv_table_name   IN VARCHAR2,
                               lv_synonym_name IN VARCHAR2) AS
  BEGIN
    EXECUTE IMMEDIATE 'create table ' || lv_table_name || 
                   q'{ as SELECT 0 as job_id,
                                 0 as position_pool_id,
                                 0 as position_id,
                                 0 as position_history_id,
                                 cast (null as varchar2(80)) as position_state,
                                 sysdate as date_available,
                                 sysdate as date_offer_accepted,
                                 sysdate as date_eliminated,
                                 sysdate as date_abandoned
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
     'TWICE DAILY',
     8,
     1,
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
     'TWICE DAILY',
     8,
     1,
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
