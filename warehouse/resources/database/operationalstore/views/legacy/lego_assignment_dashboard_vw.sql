CREATE OR REPLACE FORCE VIEW lego_assignment_dashboard_vw
AS
SELECT assignment_continuity_id, 
       buyer_org_id, 
       assignment_state_id, 
       assignment_start_dt, 
       assignment_end_dt, 
       assignment_actual_end_dt, 
       fed_id
  FROM lego_assignment_dashboard
/

