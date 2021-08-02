/*******************************************************************************
SCRIPT NAME         lego_job_opportunity.sql 
 
LEGO OBJECT NAME    LEGO_JOB_OPPORTUNITY
 
CREATED             7/17/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

07/17/2014 - J.Pullifrone - IQN-18303 - new refresh_sql created - Release 12.1.2  
01/27/2016 - jpullifrone              - modifications for DB links, multiple sources, and remote SCN   
07/13/2016 - jpullifrone  - IQN-33436 - replacing FO tables with legos (job)
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_job_opportunity.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JOB_OPPORTUNITY'; 

  v_clob CLOB :=
      q'{SELECT j.buyer_org_id,
                frs.business_org_fk    AS supplier_org_id,
                jo.job_opportunity_id,
                j.job_id,
                jo.job_submission_fk   AS job_submission_id,
                jo.creation_date       AS create_date,
                jo.last_modified_date,
                DECODE(jo.state, 'A','Active','R','Retracted') AS state
           FROM job_sourceNameShort j,
                job_opportunity@db_link_name AS OF SCN source_db_SCN jo,
                firm_role@db_link_name       AS OF SCN source_db_SCN frs
          WHERE j.job_id = jo.job_fk
            AND jo.supply_firm_fk   = frs.firm_id}';

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

