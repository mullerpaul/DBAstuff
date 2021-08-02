CREATE OR REPLACE FORCE VIEW lego_upcoming_ends_org_roll_vw
AS 
SELECT login_user_id, login_org_id, days_until_assignment_end, job_category, assignment_count 
  FROM upcoming_ends_org_roll_iqp
/

CREATE OR REPLACE FORCE VIEW lego_upcoming_ends_row_roll_vw
AS 
SELECT login_user_id, login_org_id, days_until_assignment_end, job_category, assignment_count
  FROM upcoming_ends_row_roll_iqp
/


