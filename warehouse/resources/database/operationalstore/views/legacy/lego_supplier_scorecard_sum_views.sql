/*******************************************************************************
SCRIPT NAME         lego_supplier_scorecard_sum_views.sql 
 
LEGO OBJECT NAME    LEGO_SUPPLIER_SCORECARD_SUM
 
CREATED             8/12/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************
 
8/12/2014 - J.Pullifrone - IQN-19352 - new view added - Release 12.1.3 
   
*******************************************************************************/  
CREATE OR REPLACE VIEW lego_supplier_scorecard_sum_vw
AS
SELECT buyer_org_id,
       supplier_org_id,
       jc_value,
       year,
       quarter,
       preferred_supplier,
       current_contractor_head_count,
       total_spend,
       jobs_submitted_supplier,
       total_submit_time,
       job_req_submitted,
       avail_pos,
       candidates_submitted_supplier,
       hm_candidate_count,
       candidate_interviewed,
       total_work_orders,
       rejected_work_orders,
       accepted_work_orders,
       new_starts,
       new_starts_ea,
       targeted_jobs,
       rate_card_compliance_count,
       total_contractors_ended,
       contractors_ended_negative,
       total_positive_evaluations,
       wired_starts,                     
       (new_starts + new_starts_ea + targeted_jobs)                                                                                               AS total_new_starts,
       ROUND(candidates_submitted_supplier/DECODE(job_req_submitted,0, null, job_req_submitted),4)                                                AS submital_job_req,
       ROUND(candidates_submitted_supplier/DECODE(avail_pos,0,NULL, avail_pos),4)                                                                 AS submital_rate_pos,
       ROUND(total_submit_time/DECODE(jobs_submitted_supplier,0,NULL, jobs_submitted_supplier),4)                                                 AS average_submit_time,
       ROUND(hm_candidate_count/DECODE(candidates_submitted_supplier,0,NULL,candidates_submitted_supplier),4)                                     AS candidate_quality,
       ROUND(candidate_interviewed/DECODE(candidates_submitted_supplier,0, NULL, candidates_submitted_supplier),4)                                AS interview_rate,
       ROUND(total_work_orders/DECODE(job_req_submitted,0,null,job_req_submitted),4)                                                              AS fill_rate_req,
       ROUND(total_work_orders/DECODE(avail_pos,0,NULL, avail_pos),4)                                                                             AS fill_rate_pos,
       ROUND(accepted_work_orders/DECODE(total_work_orders,0,NULL,total_work_orders),4)                                                           AS acceptance_rate,
       ROUND(targeted_jobs/DECODE(new_starts+new_starts_ea+targeted_jobs, 0, NULL, new_starts + new_starts_ea + targeted_jobs),4)                 AS pct_targeted,
       ROUND(wired_starts/DECODE(new_starts + new_starts_ea + targeted_jobs, 0, NULL, new_starts + new_starts_ea + targeted_jobs),4)              AS pct_wired,
       ROUND(rate_card_compliance_count/DECODE(new_starts + new_starts_ea + targeted_jobs, 0, NULL,new_starts + new_starts_ea + targeted_jobs),4) AS rate_compliance,
       ROUND(total_positive_evaluations/DECODE(total_contractors_ended,0,NULL,total_contractors_ended),4)                                         AS contractor_quality 
  FROM lego_supplier_scorecard_sum
 WHERE (current_contractor_head_count + --total_spend + 
       job_req_submitted + avail_pos + candidates_submitted_supplier + hm_candidate_count + candidate_interviewed + total_work_orders + rejected_work_orders +
       accepted_work_orders + new_starts + targeted_jobs + rate_card_compliance_count + total_contractors_ended + contractors_ended_negative  +      
       total_positive_evaluations + wired_starts) > 0
/

COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.buyer_org_id                  IS 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.supplier_org_id               IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.jc_value                      IS 'Job Category ID FK to LEGO_JOB_VW'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.year                          IS 'Calendar year in which metrics where derived'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.quarter                       IS 'Calendar year in which metrics where derived'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.preferred_supplier            IS 'Indicates whether this is a preferred supplier (Yes,No,Not Applicable)'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.current_contractor_head_count IS 'Current number of contractors that are/were on assignment for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.total_spend                   IS 'Total Spend derived from this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.jobs_submitted_supplier       IS 'Number of Jobs Candidate is submitted to by this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.total_submit_time             IS 'Total length of time in days between when a candidate is released to a supplier and when the candidate is submitted for match'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.job_req_submitted             IS 'Number of job reqs made available to this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.avail_pos                     IS 'Number of positions available for Match by this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.candidates_submitted_supplier IS 'Number of candidates submitted for Match by this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.hm_candidate_count            IS 'Number of candidates that passed HM screening for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.candidate_interviewed         IS 'Number of candidates scheduled for interview for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.total_work_orders             IS 'Number of total work orders released to this supplier (WOs only)'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.rejected_work_orders          IS 'Number of work orders rejected by this supplier (WOs only)'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.accepted_work_orders          IS 'Number of work orders accepted by this supplier (WOs only)'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.new_starts                    IS 'Number of work order assignments started for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.new_starts_ea                 IS 'Number of targeted express assignments started for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.targeted_jobs                 IS 'Number of targeted work orders for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.rate_card_compliance_count    IS 'Number of assignments compliant with established rate cards for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.total_contractors_ended       IS 'Number of contractors ended/Assignments completed or terminated for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.contractors_ended_negative    IS 'Number of contractors ended/Assignments completed or terminated with a negative evaluation for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.total_positive_evaluations    IS 'Number of contractors ended/Assignments completed with a positive evaluation for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.wired_starts                  IS 'Number of wired assignment starts for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.total_new_starts              IS 'Number of work order assignments + Number of targeted express assignments started for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.submital_job_req              IS 'Ratio of number of candidates submitted for match to number of job reqs submitted to supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.submital_rate_pos             IS 'Ratio of number of candidates submitted for match to number of positions available for match for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.average_submit_time           IS 'Average number of days to submit candidates to Job Requisitions for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.candidate_quality             IS 'Ratio of number of candidates that passed HM screening to number of candidates submitted for match for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.interview_rate                IS 'Ratio of number of candidates scheduled for interview to number of candidates submitted for match for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.fill_rate_req                 IS 'Ratio of number of total work orders released to number of job reqs submitted to this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.fill_rate_pos                 IS 'Ratio of number of total work orders released to number of positions available for match for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.acceptance_rate               IS 'Ratio of number of work orders accepted by this supplier to number of total work orders released to this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.pct_targeted                  IS 'Ratio of number of targeted work orders for this supplier to the sum of (number of work order assignments started + number of targeted express assignments started + number of targeted work orders) for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.pct_wired                     IS 'Ratio of Number of wired assignment starts for this supplier to the sum of (number of work order assignments started + number of targeted express assignments started + number of targeted work orders) for this supplier'
/
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.rate_compliance               IS 'Ratio of number of assignments compliant with established rate cards to the sum of (number of work order assignments started + number of targeted express assignments started + number of targeted work orders) for this supplier'
/                                                                         
COMMENT ON COLUMN lego_supplier_scorecard_sum_vw.contractor_quality            IS 'Ratio of number of contractors ended/Assignments completed with a positive evaluation to number of contractors ended/Assignments completed or terminated for this supplier'
/

