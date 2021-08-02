/*******************************************************************************
SCRIPT NAME         lego_time_to_fill.sql
 
LEGO OBJECT NAME    LEGO_TIME_TO_FILL
 
CREATED             05/04/2017
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************
05/04/2017 - IQN-37567  Initial version.
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_time_to_fill.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_TIME_TO_FILL';

  v_clob_1 CLOB :=            
   q'{WITH cal_date_weekend
              AS
              (SELECT TO_DATE('01-JAN-1999','DD-MON-YYYY') + daynum AS day_dt, 
                      TO_CHAR(TO_DATE('01-JAN-1999','DD-MON-YYYY') + daynum,'FMDAY') AS DOW
                FROM (SELECT ROWNUM - 1 AS daynum
                        FROM dual
                     CONNECT BY ROWNUM < SYSDATE + 360 - TO_DATE('01-JAN-1999','DD-MON-YYYY') + 1 )
               WHERE TO_CHAR(TO_DATE('01-JAN-1999','DD-MON-YYYY') + daynum,'FMDAY') IN ('SATURDAY','SUNDAY'))
              SELECT 
                     buyer_org_id,
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
                     assignment_created_date,
                     assignment_effect_date,
                     assignment_start_date,
                     (CASE
                         WHEN job_created_date <= job_approved_date
                         THEN
                            (SELECT round(job_approved_date - job_created_date - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE job_created_date <= day_dt
                                AND job_approved_date > day_dt)
                         WHEN job_created_date > job_approved_date
                         THEN
                           (SELECT (round(job_approved_date - job_created_date + COUNT(*),2))
                               FROM cal_date_weekend
                              WHERE job_created_date >= day_dt
                                AND job_approved_date < day_dt)
                         ELSE
                            NULL
                      END)
                        tt_job_approval,
                     (CASE
                         WHEN COALESCE(job_created_date, job_approved_date) <= job_released_to_supp_date
                         THEN
                            (SELECT round(job_released_to_supp_date - COALESCE(job_created_date, job_approved_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(job_created_date, job_approved_date) <= day_dt
                                AND job_released_to_supp_date > day_dt)
                         WHEN COALESCE(job_created_date, job_approved_date) > job_released_to_supp_date
                         THEN
                            (SELECT round(job_released_to_supp_date - COALESCE(job_created_date, job_approved_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(job_created_date, job_approved_date) >= day_dt
                                AND job_released_to_supp_date < day_dt)
                         ELSE
                            NULL
                      END)
                        tt_job_released,
                     (CASE
                         WHEN COALESCE(job_released_to_supp_date, job_approved_date,
                              job_created_date) <= submit_match_date
                         THEN
                            (SELECT round(submit_match_date - COALESCE(job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(job_released_to_supp_date, job_approved_date,
                                    job_created_date) <= day_dt
                                AND submit_match_date > day_dt)
                         WHEN COALESCE(job_released_to_supp_date, job_approved_date,
                              job_created_date) > submit_match_date
                         THEN
                            (SELECT round(submit_match_date - COALESCE(job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(job_released_to_supp_date, job_approved_date,
                                    job_created_date) >= day_dt
                                AND submit_match_date < day_dt)
                         ELSE
                            NULL
                      END)
                        tt_match_for_supp,
                     (CASE
                         WHEN COALESCE(submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) <= fwd_to_hm_date
                         THEN
                            (SELECT round(fwd_to_hm_date - COALESCE(submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) <= day_dt
                                AND fwd_to_hm_date > day_dt)
                         WHEN COALESCE(submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) > fwd_to_hm_date
                         THEN
                            (SELECT round(fwd_to_hm_date - COALESCE(submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) >= day_dt
                                AND fwd_to_hm_date < day_dt)
                         ELSE
                            NULL
                      END)
                        tt_fwd_to_hm,
                     (CASE
                         WHEN COALESCE(fwd_to_hm_date, submit_match_date,
                              job_released_to_supp_date, job_approved_date,
                              job_created_date) <= assignment_created_date
                         THEN
                            (SELECT round(assignment_created_date - COALESCE(fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(fwd_to_hm_date, submit_match_date,
                                    job_released_to_supp_date, job_approved_date,
                                    job_created_date) <= day_dt
                                AND assignment_created_date > day_dt)
                         WHEN COALESCE(fwd_to_hm_date, submit_match_date,
                              job_released_to_supp_date, job_approved_date,
                              job_created_date) > assignment_created_date
                         THEN
                            (SELECT round(assignment_created_date - COALESCE(fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(fwd_to_hm_date, submit_match_date,
                                    job_released_to_supp_date, job_approved_date,
                                    job_created_date) >= day_dt
                                AND assignment_created_date < day_dt)
                         ELSE
                            NULL
                      END)
                        tt_create_assignment,
                     (CASE
                         WHEN job_created_date <= assignment_start_date
                         THEN
                            (SELECT round(assignment_start_date - job_created_date - COUNT(*), 2)
                               FROM cal_date_weekend
                              WHERE job_created_date <= day_dt
                                AND assignment_start_date > day_dt)
                         WHEN job_created_date > assignment_start_date
                         THEN
                            (SELECT round(assignment_start_date - job_created_date + COUNT(*), 2)
                               FROM cal_date_weekend
                              WHERE job_created_date >= day_dt
                                AND assignment_start_date < day_dt)
                         ELSE
                            NULL
                      END)
                        tt_start_assignment,
                     (CASE
                         WHEN job_created_date <= assignment_effect_date
                         THEN
                            (SELECT round(assignment_effect_date - job_created_date - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE job_created_date <= day_dt
                                AND assignment_effect_date > day_dt)
                         WHEN job_created_date > assignment_effect_date
                         THEN
                            (SELECT round(assignment_effect_date - job_created_date + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE job_created_date >= day_dt
                                AND assignment_effect_date < day_dt)
                         ELSE
                            NULL
                      END)
                        tt_effective_assignment,
                     (CASE
                         WHEN job_approved_date <= assignment_created_date
                         THEN
                            (SELECT round(assignment_created_date - job_approved_date - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE job_approved_date <= day_dt
                                AND assignment_created_date > day_dt)
                         WHEN job_approved_date > assignment_created_date
                         THEN
                            (SELECT round(assignment_created_date - job_approved_date + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE job_approved_date >= day_dt
                                AND assignment_created_date < day_dt)
                         ELSE
                            NULL
                      END)
                        tt_fill_assignment,
                     (CASE
                         WHEN job_created_date <= job_approved_date
                         THEN
                            (SELECT round(job_approved_date - job_created_date - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE job_created_date <= day_dt
                                AND job_approved_date > day_dt)
                         WHEN job_created_date > job_approved_date
                         THEN
                            (SELECT round(job_approved_date - job_created_date + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE job_created_date >= day_dt
                                AND job_approved_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x1,
                     (CASE
                         WHEN COALESCE(job_approved_date, job_created_date) <= job_released_to_supp_date
                         THEN
                            (SELECT round(job_released_to_supp_date - COALESCE(job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(job_approved_date, job_created_date) <= day_dt
                                AND job_released_to_supp_date > day_dt)
                         WHEN COALESCE(job_approved_date, job_created_date) > job_released_to_supp_date
                         THEN
                            (SELECT round(job_released_to_supp_date - COALESCE(job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(job_approved_date, job_created_date) >= day_dt
                                AND job_released_to_supp_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x2,
                     (CASE
                         WHEN COALESCE(job_released_to_supp_date, job_approved_date,
                              job_created_date) <= submit_match_date
                         THEN
                            (SELECT round(submit_match_date - COALESCE(job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(job_released_to_supp_date, job_approved_date,
                                    job_created_date) <= day_dt
                                AND submit_match_date > day_dt)
                         WHEN COALESCE(job_released_to_supp_date, job_approved_date,
                              job_created_date) > submit_match_date
                         THEN
                            (SELECT round(submit_match_date - COALESCE(job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(job_released_to_supp_date, job_approved_date,
                                    job_created_date) >= day_dt
                                AND submit_match_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x3,
                     (CASE
                         WHEN COALESCE(submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) <= fwd_to_hm_date
                         THEN
                            (SELECT round(fwd_to_hm_date - COALESCE(submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) <= day_dt
                                AND fwd_to_hm_date > day_dt)
                         WHEN COALESCE(submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) > fwd_to_hm_date
                         THEN
                            (SELECT round(fwd_to_hm_date - COALESCE(submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) >= day_dt
                                AND fwd_to_hm_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x4,
                     (CASE
                         WHEN COALESCE(fwd_to_hm_date, submit_match_date,
                              job_released_to_supp_date, job_approved_date,
                              job_created_date) <= candidate_interview_date
                         THEN
                            (SELECT round(candidate_interview_date - COALESCE(fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(fwd_to_hm_date, submit_match_date,
                                    job_released_to_supp_date, job_approved_date,
                                    job_created_date) <= day_dt
                                AND candidate_interview_date > day_dt)
                         WHEN COALESCE(fwd_to_hm_date, submit_match_date,
                              job_released_to_supp_date, job_approved_date,
                              job_created_date) > candidate_interview_date
                         THEN
                            (SELECT round(candidate_interview_date - COALESCE(fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(fwd_to_hm_date, submit_match_date,
                                    job_released_to_supp_date, job_approved_date,
                                    job_created_date) >= day_dt
                                AND candidate_interview_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x5, }';
    v_clob_2 CLOB := q'{                                      
                     (CASE
                         WHEN COALESCE(candidate_interview_date, fwd_to_hm_date,
                              submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) <= assignment_created_date
                         THEN
                            (SELECT round(assignment_created_date - COALESCE(candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(candidate_interview_date, fwd_to_hm_date,
                                    submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) <= day_dt
                                AND assignment_created_date > day_dt)
                         WHEN COALESCE(candidate_interview_date, fwd_to_hm_date,
                              submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) > assignment_created_date
                         THEN
                            (SELECT round(assignment_created_date - COALESCE(candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(candidate_interview_date, fwd_to_hm_date,
                                    submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) >= day_dt
                                AND assignment_created_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x6,
                  (CASE
                         WHEN COALESCE(assignment_created_date, candidate_interview_date,
                              fwd_to_hm_date, submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) <= wo_release_to_supp_date
                         THEN
                            (SELECT round(wo_release_to_supp_date - COALESCE(assignment_created_date, candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(assignment_created_date,
                                    candidate_interview_date, fwd_to_hm_date,
                                    submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) <= day_dt
                                AND wo_release_to_supp_date > day_dt)
                         WHEN COALESCE(assignment_created_date, candidate_interview_date,
                              fwd_to_hm_date, submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) > wo_release_to_supp_date
                         THEN
                            (SELECT round(wo_release_to_supp_date - COALESCE(assignment_created_date, candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(assignment_created_date,
                                    candidate_interview_date, fwd_to_hm_date,
                                    submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) >= day_dt
                                AND wo_release_to_supp_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x7,
                     (CASE
                         WHEN COALESCE(wo_release_to_supp_date, assignment_created_date,
                              candidate_interview_date, fwd_to_hm_date, submit_match_date,
                              job_released_to_supp_date, job_approved_date,
                              job_created_date) <= wo_accept_by_supp_date
                         THEN
                            (SELECT round(wo_accept_by_supp_date - COALESCE(wo_release_to_supp_date, assignment_created_date, candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(wo_release_to_supp_date,
                                    assignment_created_date, candidate_interview_date,
                                    fwd_to_hm_date, submit_match_date,
                                    job_released_to_supp_date, job_approved_date,
                                    job_created_date) <= day_dt
                                AND wo_accept_by_supp_date > day_dt)
                         WHEN COALESCE(wo_release_to_supp_date, assignment_created_date,
                              candidate_interview_date, fwd_to_hm_date, submit_match_date,
                              job_released_to_supp_date, job_approved_date,
                              job_created_date) > wo_accept_by_supp_date
                         THEN
                            (SELECT round(wo_accept_by_supp_date - COALESCE(wo_release_to_supp_date, assignment_created_date, candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(wo_release_to_supp_date,
                                    assignment_created_date, candidate_interview_date,
                                    fwd_to_hm_date, submit_match_date,
                                    job_released_to_supp_date, job_approved_date,
                                    job_created_date) >= day_dt
                                AND wo_accept_by_supp_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x8,
                     (CASE
                         WHEN COALESCE(wo_accept_by_supp_date, wo_release_to_supp_date,
                              assignment_created_date, candidate_interview_date,
                              fwd_to_hm_date, submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) <= assignment_effect_date
                         THEN
                            (SELECT round(assignment_effect_date - COALESCE(wo_accept_by_supp_date, wo_release_to_supp_date, assignment_created_date, candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(wo_accept_by_supp_date,
                                    wo_release_to_supp_date, assignment_created_date,
                                    candidate_interview_date, fwd_to_hm_date,
                                    submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) <= day_dt
                                AND assignment_effect_date > day_dt)
                         WHEN COALESCE(wo_accept_by_supp_date, wo_release_to_supp_date,
                              assignment_created_date, candidate_interview_date,
                              fwd_to_hm_date, submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) > assignment_effect_date
                         THEN
                            (SELECT round(assignment_effect_date - COALESCE(wo_accept_by_supp_date, wo_release_to_supp_date, assignment_created_date, candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(wo_accept_by_supp_date,
                                    wo_release_to_supp_date, assignment_created_date,
                                    candidate_interview_date, fwd_to_hm_date,
                                    submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) >= day_dt
                                AND assignment_effect_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x9a,
                     (CASE
                         WHEN COALESCE(wo_accept_by_supp_date, wo_release_to_supp_date,
                              assignment_created_date, candidate_interview_date,
                              fwd_to_hm_date, submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) <= assignment_start_date
                         THEN
                            (SELECT round(assignment_start_date - COALESCE(wo_accept_by_supp_date, wo_release_to_supp_date, assignment_created_date, candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) - COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(wo_accept_by_supp_date,
                                    wo_release_to_supp_date, assignment_created_date,
                                    candidate_interview_date, fwd_to_hm_date,
                                    submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) <= day_dt
                                AND assignment_start_date > day_dt)
                         WHEN COALESCE(wo_accept_by_supp_date, wo_release_to_supp_date,
                              assignment_created_date, candidate_interview_date,
                              fwd_to_hm_date, submit_match_date, job_released_to_supp_date,
                              job_approved_date, job_created_date) > assignment_start_date
                         THEN
                            (SELECT round(assignment_start_date - COALESCE(wo_accept_by_supp_date, wo_release_to_supp_date, assignment_created_date, candidate_interview_date, fwd_to_hm_date, submit_match_date, job_released_to_supp_date, job_approved_date, job_created_date) + COUNT(*),2)
                               FROM cal_date_weekend
                              WHERE COALESCE(wo_accept_by_supp_date,
                                    wo_release_to_supp_date, assignment_created_date,
                                    candidate_interview_date, fwd_to_hm_date,
                                    submit_match_date, job_released_to_supp_date,
                                    job_approved_date, job_created_date) >= day_dt
                                AND assignment_start_date < day_dt)
                         ELSE
                            NULL
                      END)
                        time_x9b,
                        time_to_select,
                        match_create_date,
                        candidate_sourcing_method_id,
                        candidate_sourcing_method,
                        sourcing_method,
                        assignment_type
                        --> add fields here...
            FROM (
                      SELECT j.buyer_org_id,
                             jo.supplier_org_id, 
                             j.job_id,
                             assgn.assignment_continuity_id, 
                             m.candidate_id,
                             j.jc_value AS job_category_id,
                             j.job_created_date,
                             j.approved_date job_approved_date,
                             MIN(jo.create_date) job_released_to_supp_date,
                             m.creation_date submit_match_date,
                             m.cand_passed_screening fwd_to_hm_date,
                             m.schedule_interview candidate_interview_date,
                             assgn.released_to_supplier_date wo_release_to_supp_date,
                             assgn.accepted_by_supplier_date wo_accept_by_supp_date,
                             assgn.assignment_create_date assignment_created_date,
                             assgn.assignment_effective_date assignment_effect_date,
                             assgn.assignment_start_date assignment_start_date,
                             ROUND((assgn.assignment_create_date - m.cand_passed_screening),2) time_to_select,
                             m.creation_date match_create_date,
                             assgn.candidate_sourcing_method_id,
                             csm_jcl.constant_description AS candidate_sourcing_method,
                             assgn.sourcing_method,
                             assgn.assignment_type
                        FROM (SELECT job_id, assignment_continuity_id, assignment_type, sourcing_method, candidate_sourcing_method_id, assignment_create_date, 
                                     assignment_start_dt assignment_start_date, assignment_effective_date, accepted_by_supplier_date, released_to_supplier_date,
                                     has_ever_been_effective
                                FROM assignment_wo_sourceNameShort
                              UNION ALL
                              SELECT job_id, assignment_continuity_id, assignment_type, sourcing_method, candidate_sourcing_method_id, assignment_create_date, 
                                     assignment_start_dt assignment_start_date, assignment_effective_date, NULL AS accepted_by_supplier_date, NULL AS released_to_supplier_date,
                                     has_ever_been_effective
                                FROM assignment_ea_sourceNameShort) assgn,                              
                              job_sourceNameShort j,
                              job_opportunity_sourceNameShort jo,
                              match_sourceNameShort m,
                             (SELECT constant_value, constant_description
                                FROM java_constant_lookup_sourceNameShort
                               WHERE constant_type    = 'SOURCING_METHOD'
                                 AND locale_fk = 'EN_US') csm_jcl
                       WHERE assgn.has_ever_been_effective  = 1      -- Ever been effective
                         AND assgn.candidate_sourcing_method_id  = csm_jcl.constant_value(+)
                         AND assgn.assignment_create_date >= TO_DATE('01/01/2009', 'MM/DD/YYYY') 
                         AND j.job_id                    = assgn.job_id
                         AND j.job_state_id NOT IN (1, 5)         -- Not Interested in Under Development/Canceled
                         AND j.template_availability IS NULL              -- Eliminate Job templates
                         AND j.job_source_of_record IN ('GUI', 'MWO') -- Not interested in Stub Jobs
                         AND jo.job_id                   = j.job_id
                         AND m.job_opportunity_id(+)     = jo.job_opportunity_id
                         AND m.creation_date(+) IS NOT NULL
                       GROUP BY j.buyer_org_id,
                             jo.supplier_org_id, 
                             j.job_id,
                             assgn.assignment_continuity_id, 
                             m.candidate_id,
                             j.jc_value,
                             j.job_created_date,
                             j.approved_date,                             
                             m.creation_date,
                             m.cand_passed_screening,
                             m.schedule_interview,
                             assgn.released_to_supplier_date,
                             assgn.accepted_by_supplier_date,
                             assgn.assignment_create_date,
                             assgn.assignment_effective_date,
                             assgn.assignment_start_date,
                             ROUND((assgn.assignment_create_date - m.cand_passed_screening),2),
                             m.creation_date,
                             assgn.candidate_sourcing_method_id,
                             csm_jcl.constant_description,
                             assgn.sourcing_method,
                             assgn.assignment_type)}';        

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob_1||v_clob_2);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  UPDATE lego_refresh
     SET refresh_sql = v_clob_1||v_clob_2
   WHERE object_name = v_lego_object_name;  
  
  COMMIT;
    
  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/

