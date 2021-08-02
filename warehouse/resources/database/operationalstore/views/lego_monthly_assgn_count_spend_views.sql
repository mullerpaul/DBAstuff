CREATE OR REPLACE FORCE VIEW lego_mnthasgncntspnd_orgrll_vw
AS 
SELECT login_user_id, login_org_id, month_start, monthly_assignment_count, monthly_invoiced_buyer_spend
  FROM mnt_asgn_cntspnd_orgrll_iqp
/

CREATE OR REPLACE FORCE VIEW lego_mnthasgncntspnd_rowrll_vw
AS 
SELECT login_user_id, login_org_id, month_start, monthly_assignment_count, monthly_invoiced_buyer_spend
  FROM mnt_asgn_cntspnd_rowrll_iqp
/


