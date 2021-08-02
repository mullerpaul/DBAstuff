/*******************************************************************************
SCRIPT NAME         lego_minimal_assignment_wo.sql
 
LEGO OBJECT NAME    LEGO_MINIMAL_ASSIGNMENT_WO
 
CREATED             10/29/2018
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

10/29/2018 - Paul Muller - IQN-41588 - Created.  This lego has a only small subset of the columns 
                                       from the regular assignment WO lego.  That is by design in hopes
                                       of keeping the refresh time very fast.  We accomplished this 
                                       by removing the columns from (and joins to) the 
                                       offer, contract, contract_version, and work_order_version tables.
                                       If you find yourself adding columns to this lego, please
                                       keep the speed of refreshes in mind.
                                       
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_minimal_assignment_wo.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MINIMAL_ASSIGNMENT_WO'; 

  v_clob CLOB :=
      q'{SELECT    --Work Order Assignments
           ac.assignment_continuity_id,
           cand.person_fk                 AS contractor_person_id,
           hfw.user_fk                    AS hiring_mgr_person_id,
           fr.business_org_fk             AS buyer_org_id,
           frs.business_org_fk            AS supplier_org_id,
           'WO'                           AS assignment_type,
           TRUNC(wos.curr_ver_start_date) AS assignment_start_dt,
           TRUNC(wos.curr_ver_end_date)   AS assignment_end_dt,
           TRUNC(NVL(ae.actual_end_date, wos.curr_ver_end_date))  AS assignment_actual_end_dt,
           TRUNC(NVL(ae.actual_end_date, wos.curr_ver_end_date) - wos.curr_ver_start_date) AS assignment_duration,
           ac.has_ever_been_effective,
           CASE WHEN wos.curr_ver_state_fk = 1  THEN 1    -- Not Released
                WHEN wos.curr_ver_state_fk = 2  THEN 2    -- Position Offered
                WHEN wos.curr_ver_state_fk = 4  THEN 4    -- Offer Declined
                WHEN wos.curr_ver_state_fk = 5  THEN 1    -- Not Released
                WHEN wos.curr_ver_state_fk = 6  THEN 5    -- Reinstated
                WHEN wos.curr_ver_state_fk = 7  THEN 6    -- Canceled
                WHEN wos.curr_ver_state_fk = 8  THEN 6    -- Canceled
                WHEN wos.curr_ver_state_fk = 3  THEN 3    -- Awaiting Start Date
                WHEN wos.curr_ver_state_fk = 10 THEN 7    -- Completed
                WHEN wos.curr_ver_state_fk = 11 THEN 17   -- Terminated
                WHEN wos.curr_ver_state_fk = 12 THEN 17   -- Terminated
                WHEN wos.curr_ver_state_fk = 13 THEN
                CASE WHEN (ac.onboard_allowed = 1 AND ac.onboard_date IS NOT NULL) THEN 9    -- Effective-OnBoard
                     ELSE 8    -- Effective
                END
                WHEN wos.curr_ver_state_fk = 14 THEN 19    -- Amended and Restated
                WHEN wos.curr_ver_state_fk = 15 THEN 12    -- Amendment In Process
                WHEN wos.curr_ver_state_fk = 16 THEN 13    -- Amendment Offered
                WHEN wos.curr_ver_state_fk = 17 THEN 11    -- Amendment Awaiting Start Date
                WHEN wos.curr_ver_state_fk = 18 THEN 14    -- Amendment Declined
                WHEN wos.curr_ver_state_fk = 19 THEN 12    -- Amendment In Process
                WHEN wos.curr_ver_state_fk = 20 THEN 19    -- Amended and Restated
                WHEN wos.curr_ver_state_fk = 21 THEN 15    -- Amendment Reinstated
                WHEN wos.curr_ver_state_fk = 22 THEN 20    -- Amendment Canceled
                WHEN wos.curr_ver_state_fk = 23 THEN 20    -- Amendment Canceled
                WHEN wos.curr_ver_state_fk = 24 THEN 12    -- Amendment In Process
                WHEN ae.assignment_state_fk = 3  THEN 3    -- Awaiting Start Date
                WHEN ae.assignment_state_fk = 10 THEN 7    -- Completed
                WHEN ae.assignment_state_fk = 12 THEN 17   -- Terminated
                WHEN ae.assignment_state_fk = 7  THEN 6    -- Canceled
                WHEN ae.assignment_state_fk = 1  THEN 18   -- Approval In Process
                WHEN ae.assignment_state_fk = 13 THEN
                   CASE WHEN (ac.onboard_allowed = 1 AND ac.onboard_date IS NOT NULL) THEN 9  -- Effective-OnBoard
                        ELSE 8    -- Effective
                   END
           END AS assignment_state_id,
           jc.description                   AS jc_description,
           ae.job_title                     AS assign_job_title,
           ac.phase_type_id                 AS current_phase_type_id
      FROM assignment_continuity@db_link_name AS OF SCN source_db_SCN ac,
           assignment_edition@db_link_name AS OF SCN source_db_SCN ae,
           work_order@db_link_name AS OF SCN source_db_SCN wo,
           work_order_summary@db_link_name AS OF SCN source_db_SCN wos,
           firm_role@db_link_name AS OF SCN source_db_SCN frs,
           firm_role@db_link_name AS OF SCN source_db_SCN fr,
           job_category@db_link_name AS OF SCN source_db_SCN jc,
           firm_worker@db_link_name AS OF SCN source_db_SCN hfw,
           candidate@db_link_name AS OF SCN source_db_SCN cand
     WHERE ac.work_order_fk IS NOT NULL
       AND NVL(ae.actual_end_date, wos.curr_ver_end_date) >= ADD_MONTHS(TRUNC(SYSDATE), -months_in_refresh)
       AND ac.current_edition_fk        = ae.assignment_edition_id
       AND ac.assignment_continuity_id  = ae.assignment_continuity_fk
       AND ac.work_order_fk             = wo.contract_id
       AND wo.contract_id               = wos.work_order_fk(+)
       AND ac.owning_supply_firm_fk     = frs.firm_id
       AND ac.owning_buyer_firm_fk      = fr.firm_id
       AND ae.job_category_fk           = jc.value(+)
       AND ae.hiring_mgr_fk             = hfw.firm_worker_id(+)
       AND ac.candidate_fk              = cand.candidate_id(+)}';

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

