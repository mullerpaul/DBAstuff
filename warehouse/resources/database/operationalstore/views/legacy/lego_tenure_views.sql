CREATE OR REPLACE FORCE VIEW lego_tenure_vw
AS
SELECT buyer_org_id, 
       assignment_continuity_id,
       job_id,
       candidate_id,
       date_gap_met,
       days_actually_worked,
       over_tenure_work_duration,
       tenure_at_risk_time_met,
       days_remaining_to_threshold,
       days_over_tenure_threshold,
       num_days_planned_to_work,
       additional_days_plan_to_work,
       tenure_risk_met_planned_end_dt,
       furthest_plan_end_dt,
       effec_assign_latest_planned_dt,
       tenure_gap_in_service,
       tenure_limit_in_days,
       tenure_limit_in_months,
       continuous_work_break_days,
       continuous_work_break_months,
       tenure_at_risk_days
  FROM lego_tenure
/


