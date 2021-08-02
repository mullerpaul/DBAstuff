/*******************************************************************************
SCRIPT NAME         lego_secure_expense_report.sql 
 
LEGO OBJECT NAME    LEGO_SECURE_EXPENSE_REPORT
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

03/31/2014 - E.Clark - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
04/09/2014 - E.Clark - fixed hardcoded 24 to use parameter - Release 12.0.3
04/14/2014 - P. Muller - IQN-15676 - changed this lego from a SQL toggle to a proc toggle.  This script will 
                         no longer be called.  We will leave it checked in for historical purposes. 

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_secure_expense_report.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_SECURE_EXPENSE_REPORT'; 

  v_clob CLOB :=
    q'{WITH lsa AS  --This is just the refresh SQL for LEGO_SECURE_ASSIGNMENT.  pasted it here to make this lego SQL TOGGLE
          (SELECT assignment_continuity.assignment_continuity_id assignment_id,
                  firm_role.business_org_fk business_organization_id,
                  never_null_person_fk user_id
             FROM firm_worker,
                  assignment_continuity,
                  assignment_edition,
                  firm_role,
                  (SELECT assignment_continuity_id
                     FROM lego_assignment_wo
                    UNION ALL
                   SELECT assignment_continuity_id
                     FROM lego_assignment_ea
                    UNION ALL
                   SELECT assignment_continuity_id
                     FROM lego_assignment_ta) lav
            WHERE assignment_continuity.assignment_continuity_id = lav.assignment_continuity_id
              AND assignment_continuity.current_edition_fk = assignment_edition.assignment_edition_id
              AND assignment_continuity.owning_buyer_firm_fk = firm_role.firm_id
              AND firm_worker.firm_worker_id IN
                         (assignment_edition.hiring_mgr_fk,
                          assignment_edition.assignment_admin_fk,
                          assignment_edition.cam_firm_worker_fk)
            UNION
           SELECT assignment_continuity.assignment_continuity_id assignment_id,
                  firm_role.business_org_fk business_organization_id,
                  never_null_person_fk user_id
             FROM firm_worker,
                  assignment_continuity,
                  assignment_edition,
                  firm_role,
                  (SELECT assignment_continuity_id
                     FROM lego_assignment_wo
                    UNION ALL
                   SELECT assignment_continuity_id
                     FROM lego_assignment_ea
                    UNION ALL
                   SELECT assignment_continuity_id
                     FROM lego_assignment_ta) lav
            WHERE assignment_continuity.assignment_continuity_id = lav.assignment_continuity_id                  
              AND assignment_continuity.current_edition_fk = assignment_edition.assignment_edition_id
              AND assignment_continuity.owning_supply_firm_fk = firm_role.firm_id
              AND firm_worker.firm_worker_id IN
                         (assignment_edition.supplier_account_rep,
                          assignment_edition.supplier_agent_fk))
    SELECT DISTINCT     --need distinct list.  Sorting once at top level
           user_id, 
           expense_report_id
      FROM (SELECT lsa.user_id   AS user_id,             --can user see the assignment?
                   erli.expense_report_fk AS expense_report_id
              FROM lsa, 
                   expense_report_line_item AS OF SCN lego_refresh_mgr_pkg.get_scn() erli
             WHERE lsa.assignment_id                = erli.assignment_continuity_fk
               AND erli.expense_week_ending_date   >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
             UNION ALL
            SELECT fw.never_null_person_fk AS user_id,   -- actual approvers
                   ap.approvable_id        AS expense_report_id
              FROM approval_activity AS OF SCN lego_refresh_mgr_pkg.get_scn() aa, 
                   approval_process  AS OF SCN lego_refresh_mgr_pkg.get_scn() ap, 
                   firm_worker       AS OF SCN lego_refresh_mgr_pkg.get_scn() fw
             WHERE aa.approval_process_fk = ap.approval_process_id
               AND aa.actual_approver_fk = fw.firm_worker_id
               AND aa.activity_type = 'ApproverTask'
               AND aa.state_code = 3
               AND ap.approvable_type ='ExpenseReport'
             UNION ALL
            SELECT fw.never_null_person_fk AS user_id,   -- planned approvers part 1
                   ap.approvable_id        AS expense_report_id
              FROM firm_worker    AS OF SCN lego_refresh_mgr_pkg.get_scn() fw, 
                   named_approver AS OF SCN lego_refresh_mgr_pkg.get_scn() na,
                   (SELECT DISTINCT approval_process_spec_fk,
                                    approvable_id,
                                    buyer_organization_fk
                      FROM approval_process AS OF SCN lego_refresh_mgr_pkg.get_scn()
                     WHERE approvable_type = 'ExpenseReport') ap
             WHERE ap.approval_process_spec_fk = na.approval_process_spec_fk  
               AND na.approver_fk = fw.firm_worker_id
             UNION ALL
            SELECT fw.never_null_person_fk AS user_id,   -- planned approvers part 2
                   ap.approvable_id        AS expense_report_id
              FROM firm_worker       AS OF SCN lego_refresh_mgr_pkg.get_scn() fw, 
                   approval_activity AS OF SCN lego_refresh_mgr_pkg.get_scn() aa, 
                   approval_process  AS OF SCN lego_refresh_mgr_pkg.get_scn() ap
             WHERE aa.approval_process_fk = ap.approval_process_id
               AND aa.approver_fk = fw.firm_worker_id
               AND ap.approvable_type ='ExpenseReport'
               AND aa.activity_type = 'ApproverTask')}';

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

