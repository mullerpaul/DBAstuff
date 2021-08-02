CREATE OR REPLACE FORCE VIEW LEGO_SECURE_ASSIGNMENT_VW
  (user_id, assignment_id, business_organization_id)
AS
SELECT user_id, 
       assignment_id, 
       NULL AS business_organization_id  --this column is not used by Jasper, but allegedy required by dashboards.  Remove once dashboards are disabled.
  FROM lego_slot_assignment
/
