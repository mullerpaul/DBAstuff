CREATE OR REPLACE FORCE VIEW lego_upcoming_ends_sec_vw
AS
SELECT assignment_continuity_id, buyer_org_id, assignment_end_dt 
  FROM lego_upcoming_ends_sec
/

