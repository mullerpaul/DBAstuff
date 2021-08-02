CREATE OR REPLACE FORCE VIEW lego_mnth_assgn_cnt_sec_vw
AS
SELECT assignment_continuity_id, buyer_org_id, assignment_start_dt, assignment_actual_end_dt 
  FROM lego_mnth_assgn_cnt_sec
/

