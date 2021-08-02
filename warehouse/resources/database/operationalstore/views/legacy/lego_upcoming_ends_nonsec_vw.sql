CREATE OR REPLACE FORCE VIEW lego_upcoming_ends_nonsec_vw
AS
SELECT buyer_org_id, 
       assgn_ending_in_30days_or_less, 
       assgn_ending_in_30_to_60_days, 
       assgn_ending_in_60_to_90_days 
  FROM lego_upcoming_ends_nonsec
/

