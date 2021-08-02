DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_ASSGN_LOC_ST_ATOM_RR';
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
     synonym_name,
     refresh_procedure_name)
  VALUES
    (lv_object_name,
     'USPROD',
     'PROC TOGGLE',
     'TWICE DAILY',
     11,
     3,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name,
     'lego_dashboard_refresh.assgn_loc_st_atom_rr');

  INSERT INTO lego_refresh_index (object_name, source_name, index_name, index_type, column_list, tablespace_name)
       VALUES (lv_object_name,'USPROD','ASSGN_LOC_ST_ATOM_RR_NI01','NONUNIQUE','LOGIN_USER_ID',NULL);
     
  COMMIT;

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0     AS login_user_id,
                                'abc' AS cmsa_primary_state_code, 
                                0     AS effective_assgn_count
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';
  
END;
/

 