DECLARE
  lv_object_name lego_refresh.object_name%TYPE := 'LEGO_TIME_TO_FILL';
  lv_syn_name    lego_refresh.synonym_name%TYPE := REPLACE(lv_object_name, 'LEGO_') || '_IQP';
  
  PROCEDURE make_table_and_syn(lv_table_name   IN VARCHAR2,
                               lv_synonym_name IN VARCHAR2) AS
  BEGIN
    EXECUTE IMMEDIATE 'create table ' || lv_table_name || 
                   q'{ as SELECT 0 AS buyer_org_id,
                                 0 AS supplier_org_id,
                                 0 AS job_id,
                                 0 AS assignment_continuity_id,
                                 0 AS candidate_id,               
                                 0 AS job_category_id,
                                 SYSDATE AS job_created_date,
                                 SYSDATE AS job_approved_date,
                                 SYSDATE AS job_released_to_supp_date,
                                 SYSDATE AS submit_match_date,
                                 SYSDATE AS fwd_to_hm_date,
                                 SYSDATE AS candidate_interview_date,
                                 SYSDATE AS wo_release_to_supp_date,
                                 SYSDATE AS wo_accept_by_supp_date,
                                 SYSDATE AS assignment_created_date,
                                 SYSDATE AS assignment_effect_date,
                                 SYSDATE AS assignment_start_date,
                                 0 AS tt_job_approval,
                                 0 AS tt_job_released,
                                 0 AS tt_match_for_supp,
                                 0 AS tt_fwd_to_hm,
                                 0 AS tt_create_assignment,
                                 0 AS tt_start_assignment,
                                 0 AS tt_effective_assignment,
                                 0 AS tt_fill_assignment,
                                 0 AS time_x1,
                                 0 AS time_x2,
                                 0 AS time_x3,
                                 0 AS time_x4,
                                 0 AS time_x5,
                                 0 AS time_x6,
                                 0 AS time_x7,
                                 0 AS time_x8,
                                 0 AS time_x9a,
                                 0 AS time_x9b,
                                 0 AS time_to_select,
                                 SYSDATE AS match_create_date,
                                 'acb' AS candidate_sourcing_method_id,
                                 'acb' AS candidate_sourcing_method,
                                 'acb' AS sourcing_method,
                                 'abc' AS assignment_type
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
     11,
     6,
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
     11,
     6,
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
