DELETE FROM lego_refresh
 WHERE object_name IN ('LEGO_JOB_CANCEL_TMP','LEGO_JOB_CAC')
/

-- Now that we removed lego_job_cancel_temp, LEGO_JOB no longer relies on any of the 8,1 legos.  
-- we should move it up the RDO.
UPDATE lego_refresh
   SET refresh_dependency_order = 1
 WHERE object_name = 'LEGO_JOB'
/
   

COMMIT
/



 
