/*******************************************************************************
SCRIPT NAME         lego_job_slots.sql 
 
LEGO OBJECT NAME    LEGO_JOB_SLOTS
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

03/31/2014 - E.Clark - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2 
08/15/2014 - pmuller - IQN-19828 - added comments - Release 12.2
01/27/2016 - pmuller             - Modifications for DB links, multiple sources, and remote SCN
04/21/2016 - pmuller             - renamed from LEGO_SECURE_JOB
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_job_slots.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JOB_SLOTS'; 

  v_clob CLOB :=
       q'{SELECT job_id job_id,
       fr.business_org_fk business_organization_id,
       fw.never_null_person_fk user_id
  FROM job@db_link_name AS OF SCN source_db_SCN,
       firm_worker@db_link_name AS OF SCN source_db_SCN fw,
       firm_role@db_link_name AS OF SCN source_db_SCN fr
 WHERE fw.firm_worker_id IN
          (job.hiring_mgr_firm_woker_fk,  -- the hiring manager can see the job
           job.creator_id,                -- the creator can see the job
           job.owner_firm_worker_fk)      -- the owner can see the job
   AND job.buyer_firm_fk = fr.firm_id
   AND job.template_type IS NULL          -- no template data in the security view.  Don't know if this is correct.
   AND (job.archived_date IS NULL OR                                         -- Time-based limit. The string
        job.archived_date >= ADD_MONTHS(TRUNC(SYSDATE), -months_in_refresh)) -- "months_in_refresh" will be replaced at runtime.
 UNION      -- bottom half uses different joins to get CAM.
SELECT j.job_id job_id,
       fr.business_org_fk business_organization_id,
       fw.never_null_person_fk user_id
  FROM job@db_link_name AS OF SCN source_db_SCN         j,
       firm_worker@db_link_name AS OF SCN source_db_SCN fw,
       firm_role@db_link_name AS OF SCN source_db_SCN   fr,
       job_cams_x@db_link_name AS OF SCN source_db_SCN  x     -- the CAM can see the job.
 WHERE j.job_id         = x.job_id
   AND x.firm_worker_fk = fw.firm_worker_id
   AND j.buyer_firm_fk  = fr.firm_id
   AND j.template_type IS NULL     -- again, no templates.
   AND (j.archived_date IS NULL OR
        j.archived_date >= ADD_MONTHS(TRUNC(SYSDATE), -months_in_refresh))}';

BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  UPDATE lego_refresh
     SET refresh_sql = v_clob
   WHERE object_name = v_lego_object_name;  
  
  COMMIT;
    
  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/

