CREATE OR REPLACE FORCE VIEW lego_time_to_fill_vw 
AS 
   SELECT buyer_org_id,
          supplier_org_id,
          job_id,
          assignment_continuity_id,
          candidate_id,
          job_category_id,
          job_created_date,
          job_approved_date,
          job_released_to_supp_date,
          submit_match_date,
          fwd_to_hm_date,
          candidate_interview_date,
          wo_release_to_supp_date,
          wo_accept_by_supp_date,
          TRUNC(assignment_created_date) AS assignment_created_date,
          assignment_effect_date,
          assignment_start_date,
          tt_job_approval,
          tt_job_released,
          tt_match_for_supp,
          tt_fwd_to_hm,
          tt_create_assignment,
          tt_start_assignment,
          tt_effective_assignment,
          tt_fill_assignment,
          time_x1,
          time_x2,
          time_x3,
          time_x4,
          time_x5,
          time_x6,
          time_x7,
          time_x8,
          time_x9a,
          time_x9b,
          candidate_sourcing_method_id,
          NVL(csm_jcl.constant_description, lttf.candidate_sourcing_method) AS candidate_sourcing_method,
          sourcing_method,
          TRUNC(match_create_date) AS match_create_date,
          time_to_select,
          assignment_type
     FROM lego_time_to_fill lttf,
          (SELECT constant_value, constant_description
             FROM lego_java_constant_lookup
            WHERE constant_type = 'SOURCING_METHOD'
              AND locale_fk     = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) csm_jcl
    WHERE lttf.candidate_sourcing_method_id = csm_jcl.constant_value(+)
/