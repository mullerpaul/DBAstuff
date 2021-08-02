/*******************************************************************************
SCRIPT NAME         lego_expense_approval.sql 
 
LEGO OBJECT NAME    LEGO_EXPENSE_APPROVAL
 
CREATED             08/08/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

08/08/2014 - J.Pullifrone - IQN-33780 - Splitting out approval information for better refresh performance.
                                        It also comports better with this level of granularity (expense_report_id). 
08/16/2016 - J.Pullifrone - IQN-34063 - Incorporate the event dates.  Use approval_process for buyer_approved_date.                                        
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_expense_approval.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_EXPENSE_APPROVAL'; 

  v_clob CLOB :=            
   q'{WITH event AS (
        SELECT ered.expense_report_fk AS expense_report_id,
               MAX(CASE WHEN ed.event_name_fk = 37000 THEN ed.timestamp ELSE NULL END) created_date,
               MAX(CASE WHEN ed.event_name_fk = 37002 THEN ed.timestamp ELSE NULL END) submit_approval_date,
               --MAX(CASE WHEN ed.event_name_fk = 37003 THEN ed.timestamp ELSE NULL END) buyer_approved_date,
               MAX(CASE WHEN ed.event_name_fk = 37004 THEN ed.timestamp ELSE NULL END) buyer_rejected_date,
               MAX(CASE WHEN ed.event_name_fk = 37005 THEN ed.timestamp ELSE NULL END) retracted_date,
               MAX(CASE WHEN ed.event_name_fk = 37008 THEN ed.timestamp ELSE NULL END) sar_approved_date,
               MAX(CASE WHEN ed.event_name_fk = 37009 THEN ed.timestamp ELSE NULL END) sar_rejected_date
          FROM expense_report_event_desc@db_link_name AS OF SCN source_db_SCN ered, 
               event_description@db_link_name AS OF SCN source_db_SCN ed
         WHERE ered.identifier  = ed.identifier
           AND ed.event_name_fk IN (37000, 37001, 37002, 37004, 37005, 37008, 37009)
         GROUP BY ered.expense_report_fk),
      apprv AS (
        SELECT expense_report_id, 
               approver_person_id,
               approved_date       AS buyer_approved_date
          FROM (SELECT apa.approvable_id AS expense_report_id, fw.never_null_person_fk AS approver_person_id, DECODE(apa.state_code, 3, apa.completed_date, NULL) AS approved_date,
                       RANK() OVER (PARTITION BY apa.approvable_id ORDER BY t.approver_task_id DESC) rk
                  FROM approval_process@db_link_name AS OF SCN source_db_SCN  apa, 
                       approver_task@db_link_name AS OF SCN source_db_SCN     t, 
                       firm_worker@db_link_name AS OF SCN source_db_SCN       fw
                 WHERE apa.approval_process_id = t.approval_process_fk
                   AND t.actual_approver_fk    = fw.firm_worker_id
                   AND apa.active_process = 1
                   AND apa.approvable_type_fk = 12)
         WHERE rk = 1)
      SELECT event.expense_report_id, 
             apprv.approver_person_id,
             event.created_date,
             event.submit_approval_date,
             apprv.buyer_approved_date,
             event.buyer_rejected_date,
             event.retracted_date,
             event.sar_approved_date,
             event.sar_rejected_date
        FROM event,
             apprv
       WHERE event.expense_report_id = apprv.expense_report_id(+)}';              
         

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

