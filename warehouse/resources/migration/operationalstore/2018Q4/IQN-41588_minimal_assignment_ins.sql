DECLARE
  lv_object_name_ea_ta   lego_refresh.object_name%TYPE := 'LEGO_MINIMAL_ASSIGNMENT_EA_TA';
  lv_synonym_name_ea_ta  VARCHAR2(29)                  := 'MINIMAL_ASSIGNMENT_EA_TA_IQP';
  lv_object_name_wo      lego_refresh.object_name%TYPE := 'LEGO_MINIMAL_ASSIGNMENT_WO';
  lv_synonym_name_wo     VARCHAR2(29)                  := 'MINIMAL_ASSIGNMENT_WO_IQP';

BEGIN
  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name)
  VALUES
    (lv_object_name_ea_ta,
     'USPROD',
     'SQL TOGGLE',
     'NOLOGGING',
     lv_synonym_name_ea_ta || '1',
     lv_synonym_name_ea_ta || '2',
     lv_synonym_name_ea_ta);

  INSERT INTO lego_refresh
    (object_name,
     source_name,
     refresh_method,
     storage_clause,
     refresh_object_name_1,
     refresh_object_name_2,
     synonym_name)
  VALUES
    (lv_object_name_wo,
     'USPROD',
     'SQL TOGGLE',
     'NOLOGGING',
     lv_synonym_name_wo || '1',
     lv_synonym_name_wo || '2',
     lv_synonym_name_wo);

  COMMIT;

  /* Dummy table and synonym so that converence_search load package can compile before next refresh. */
  EXECUTE IMMEDIATE 'create table ' || lv_synonym_name_ea_ta || '1' || 
                    q'{  as SELECT 1       AS assignment_continuity_id,
                                   1       AS contractor_person_id,
                                   1       AS hiring_mgr_person_id,
                                   1       AS buyer_org_id,
                                   1       AS supplier_org_id,
                                   'EA'    AS assignment_type,
                                   sysdate AS assignment_start_dt,
                                   sysdate AS assignment_end_dt,
                                   sysdate AS assignment_actual_end_dt,
                                   sysdate AS assignment_duration,
                                   1       AS has_ever_been_effective,
                                   1       AS assignment_state_id,
                                   'abc'   AS jc_description,
                                   'abc'   AS assign_job_title,
                                   1       AS current_phase_type_id
                              FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create table ' || lv_synonym_name_wo || '1' || 
                    q'{  as SELECT 1       AS assignment_continuity_id,
                                   1       AS contractor_person_id,
                                   1       AS hiring_mgr_person_id,
                                   1       AS buyer_org_id,
                                   1       AS supplier_org_id,
                                   'WO'    AS assignment_type,
                                   sysdate AS assignment_start_dt,
                                   sysdate AS assignment_end_dt,
                                   sysdate AS assignment_actual_end_dt,
                                   sysdate AS assignment_duration,
                                   1       AS has_ever_been_effective,
                                   1       AS assignment_state_id,
                                   'abc'   AS jc_description,
                                   'abc'   AS assign_job_title,
                                   1       AS current_phase_type_id
                              FROM dual WHERE 1=0}';

  EXECUTE IMMEDIATE 'create synonym ' || lv_synonym_name_ea_ta || 
                    ' for ' || lv_synonym_name_ea_ta || '1';

  EXECUTE IMMEDIATE 'create synonym ' || lv_synonym_name_wo || 
                    ' for ' || lv_synonym_name_wo || '1';

END;
/

