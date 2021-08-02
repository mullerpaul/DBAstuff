CREATE OR REPLACE FORCE VIEW lego_mnth_assgn_cnt_nonsec_vw
AS
SELECT buyer_org_id, month_start, assignments_with_time_in_month
  FROM lego_mnth_assgn_cnt_nonsec
/

