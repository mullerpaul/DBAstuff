DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_ASSGN_ATOM_DETAIL';
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
     2,
     'NOLOGGING',
     lv_syn_name || '1',
     lv_syn_name || '2',
     lv_syn_name,
     'lego_dashboard_refresh.load_assgn_atom_detail');

  COMMIT;

  /* Dummy table and synonym so that view can be created valid. */
  EXECUTE IMMEDIATE 'create table ' || lv_syn_name || '1' || 
                 q'{  as SELECT 0 AS buyer_org_id, 
                                0 AS supplier_org_id, 
                                0 AS assignment_continuity_id,
                                0 AS hiring_mgr_person_id, 
                                'abc' AS contractor_name, 
                                'abc' AS hiring_manager_name,
                                'abc' AS assignment_type, 
                                SYSDATE AS assignment_start_dt, 
                                SYSDATE AS assignment_end_dt,
                                SYSDATE AS assignment_actual_end_dt, 
                                0 AS assignment_duration, 
                                'abc' AS approval_state,
                                0 AS assignment_state_id, 
                                'abc' AS sourcing_method, 
                                'abc' AS assign_requisition_type,
                                0 AS current_phase_type_id, 
                                'abc' AS std_buyerorg_name, 
                                'abc' AS std_supplierorg_name,               
                                'abc' AS std_state, 
                                'abc' AS std_city, 
                                'abc' AS std_country, 
                                'abc' AS std_postal_code, 
                                'abc' AS std_region,
                                'abc' AS cmsa_name, 
                                'abc' AS metro_name, 
                                'abc' AS cmsa_primary_state_code, 
                                'abc' AS cmsa_primary_city_name, 
                                0 AS cmsa_primary_city_lat, 
                                0 AS cmsa_primary_city_long, 
                                'abc' AS std_job_title_desc,
                                'abc' AS std_job_category_desc
                           FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_syn_name || ' for ' || lv_syn_name || '1';

END;
/