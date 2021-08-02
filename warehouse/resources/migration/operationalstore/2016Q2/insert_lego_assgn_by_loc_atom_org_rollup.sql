DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_ASSGN_BY_LOC_ATOM_ORGROLL';
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
     '(login_org_id, cmsa_name, metro_name, cmsa_primary_state_code, cmsa_primary_city_name, cmsa_primary_city_lat, cmsa_primary_city_long, effective_assgn_count, CONSTRAINT LEGO_IOT_PK PRIMARY KEY (login_org_id, cmsa_primary_city_lat, cmsa_primary_city_long)) ORGANIZATION INDEX COMPRESS 1 NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name,
     'lego_dashboard_refresh.assgn_by_loc_atom_org_rollup');

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