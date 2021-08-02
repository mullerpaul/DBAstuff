CREATE OR REPLACE FORCE VIEW lego_req_by_status_org_roll_vw
AS 
SELECT login_user_id, login_org_id, current_phase, jc_description, requisition_count
  FROM req_by_status_org_roll_iqp
/

CREATE OR REPLACE FORCE VIEW lego_req_by_status_row_roll_vw
AS 
SELECT login_user_id, login_org_id, current_phase, jc_description, requisition_count
  FROM req_by_status_row_roll_iqp
/


