CREATE OR REPLACE FORCE VIEW LEGO_SECURE_JOB_VW
   (user_id, job_id, business_organization_id)
AS
SELECT user_id, 
       job_id, 
       NULL AS business_organization_id --this column is not used by Jasper, but allegedy required by dashboards.  Remove once dashboards are disabled.
FROM lego_slot_job
/
