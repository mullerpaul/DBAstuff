DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_ASSGN_LOC_CMSA_ATOM_OR';
  lv_syn_name    lego_refresh.synonym_name%TYPE := REPLACE(lv_object_name, 'LEGO_') || '_IQP';

BEGIN

--Delete the old one because I do not like the names
DELETE FROM lego_refresh
 WHERE object_name = 'LEGO_ASSGN_BY_LOC_ATOM_ORGROLL';
 
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
     'lego_dashboard_refresh.assgn_loc_cmsa_atom_or');

  INSERT INTO lego_refresh_index (object_name, source_name, index_name, index_type, column_list, tablespace_name)
       VALUES (lv_object_name,'USPROD','ASSGN_LOC_CMSA_ATOM_OR_UI01','UNIQUE','LOGIN_ORG_ID,CMSA_PRIMARY_STATE_CODE','NOLOGGING');
     
  COMMIT;

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS effective_assgn_count, 
                                0 AS login_org_id, 
                                'abc' AS cmsa_name,
                                'abc' AS metro_name, 
                                'abc' AS cmsa_primary_state_code, 
                                'abc' AS cmsa_primary_city_name,
                                0 AS cmsa_primary_city_lat, 
                                0 AS cmsa_primary_city_long
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';
  
END;
/

 