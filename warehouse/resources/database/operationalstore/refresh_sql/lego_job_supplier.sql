/*******************************************************************************
SCRIPT NAME         lego_job_supplier.sql 
 
LEGO OBJECT NAME    LEGO_JOB_SUPPLIER
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2  
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_job_supplier.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JOB_SUPPLIER'; 

  v_clob CLOB :=
      q'{SELECT j.job_id,
             frs.business_org_fk AS supplier_org_id
        FROM job AS OF SCN lego_refresh_mgr_pkg.get_scn() j,
             job_submittee AS OF SCN lego_refresh_mgr_pkg.get_scn() js,
             firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn() frs
       WHERE j.job_submission_fk = js.job_submission_fk
         AND js.supply_firm_fk   = frs.firm_id
         AND NVL(j.archived_date,SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
       ORDER BY j.job_id, frs.business_org_fk}';

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

