/*******************************************************************************
SCRIPT NAME         lego_timecard_approval.sql 
 
LEGO OBJECT NAME    LEGO_TIMECARD_APPROVAL
 
CREATED             08/08/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

JIRA STORY          IQN-33780

***************************MODIFICATION HISTORY ********************************

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_timecard_approval.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_TIMECARD_APPROVAL'; 

  v_clob CLOB :=
q'{SELECT tc.timecard_id, 
          NVL(apprv_dt.approved_date, tc.create_date) approved_date, 
          apprv_per.approver_person_id
     FROM timecard@db_link_name AS OF SCN source_db_SCN tc, 
          (SELECT apa.approvable_id AS timecard_id, MAX(ap.completed_date) approved_date
             FROM approval_process@db_link_name AS OF SCN source_db_SCN apa,
                  approval_process@db_link_name AS OF SCN source_db_SCN ap
            WHERE ap.approval_process_id = apa.approval_process_id
              AND ap.state_code = 3
              AND apa.approvable_type_fk = 10
            GROUP BY apa.approvable_id) apprv_dt,
          (SELECT ap.approvable_id AS timecard_id, MAX(fw.never_null_person_fk) AS approver_person_id 
             FROM approval_process@db_link_name AS OF SCN source_db_SCN ap,
                  named_approver@db_link_name AS OF SCN source_db_SCN na,
                  firm_worker@db_link_name AS OF SCN source_db_SCN fw
            WHERE ap.approval_process_spec_fk 	= na.approval_process_spec_fk
              AND na.approver_fk 		= fw.firm_worker_id
              AND ap.state_code IN(3,4)
              AND ap.approvable_type_fk = 10
              AND na.position 			 = 1
              AND ap.active_process = 1
            GROUP BY ap.approvable_id) apprv_per
   WHERE tc.timecard_id = apprv_dt.timecard_id(+)
     AND tc.timecard_id = apprv_per.timecard_id(+)}';

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

