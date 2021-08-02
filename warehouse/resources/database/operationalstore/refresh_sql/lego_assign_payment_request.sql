/*******************************************************************************
SCRIPT NAME         lego_assign_payment_request.sql 
 
LEGO OBJECT NAME    LEGO_ASSIGN_PAYMENT_REQUEST
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark      - IQN-14482 - added months_in_refresh for a hard limit 
                                        on data going into the lego, added create_date - Release 12.0.2 
04/15/2014 - J.Pullifrone - IQN-15810 - Return only one (latest) pr_approved_date if PR gets approved twice - Release 12.0.3
07/16/2014 - J.Pullifrone - IQN-18927 - Changing DECODE for pr_approved_date to CASE to avoid conversion to char.  Release 12.1.2  
08/20/2014 - J.Pullifrone - IQN-18776 - removed invoice_id and added invoiced_amount - Release 12.2.0   
07/27/2016 - jpullifrone  - IQN-33504 - modifications for DB links, multiple sources, and remote SCN, removed invoiced_amount,
                                        contractor person, and hiring mgr person.
08/08/2016 - jpullifrone  - IQN-33780 - modified logic for approvals in-line view to get approver_person_id as well.  
09/20/2016 - jpullifrone  - IQN-34711 - change cardinality to payment_request.                                     
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assign_payment_request.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSIGN_PAYMENT_REQUEST'; 

  v_clob CLOB :=
       q'{SELECT bfr.business_org_fk            AS buyer_org_id, 
                 sfr.business_org_fk            AS supplier_org_id,
                 ac.assignment_continuity_id    AS assignment_continuity_id, 
                 pr.identifier                  AS payment_request_id,
                 TRUNC(pr.request_date)         AS payment_request_date,
                 apprv.approved_date,                   
                 apprv.approver_person_id,                 
                 pr.requested_amount              AS request_amount,
                 pr.adjusted_amount               AS buyer_adjusted_amount,
                 pr.reimbursement_amount          AS supplier_reimbursement_amount,            
                 pr.invoice_date                AS expenditure_item_date,
                 pt.description                 AS payment_type,
                 pr.comments                    AS comments,
                 pr.supplier_ref_number         AS supplier_ref_number,
                 pr.supplier_ref_date           AS supplier_ref_date,   
                 CASE
                    WHEN pr.supplier_ref_flag = 1 THEN 'Y'
                    WHEN pr.supplier_ref_flag = 0 THEN 'N'
                    ELSE NULL
                 END                            AS supplier_ref_flag,                           
                 CASE
                    WHEN pr.state_code = 1 THEN 'Editing'
                    WHEN pr.state_code = 2 THEN 'Submitted for Approval'
                    WHEN pr.state_code = 3 THEN 'Approved'
                    WHEN pr.state_code = 4 THEN 'Rejected'
                    WHEN pr.state_code = 5 THEN 'Submitted For Invoicing'
                    ELSE NULL
                 END                            AS payment_request_state,
                 pr.create_date,
                 ac.currency_unit_fk            AS currency_id,                         
                 cu.description                 AS currency_code
            FROM assignment_edition@db_link_name AS OF SCN source_db_SCN        ae,
                 assignment_continuity@db_link_name AS OF SCN source_db_SCN     ac,
                 payment_type@db_link_name AS OF SCN source_db_SCN              pt,
                 payment_request_spec_term@db_link_name AS OF SCN source_db_SCN prs,
                 payment_request@db_link_name AS OF SCN source_db_SCN           pr,
                 firm_role@db_link_name AS OF SCN source_db_SCN                 sfr,
                 firm_role@db_link_name AS OF SCN source_db_SCN                 bfr,
                 currency_unit@db_link_name                                      cu,
                 (SELECT payment_request_id, approved_date, approver_person_id
                    FROM (SELECT apa.approvable_id AS payment_request_id, DECODE(apa.state_code, 3, apa.completed_date, NULL) AS approved_date, fw.never_null_person_fk AS approver_person_id,
                                 RANK() OVER (PARTITION BY apa.approvable_id ORDER BY t.approver_task_id DESC) rk
                            FROM approval_process@db_link_name AS OF SCN source_db_SCN apa, 
                                 approver_task@db_link_name AS OF SCN source_db_SCN t, 
                                 firm_worker@db_link_name AS OF SCN source_db_SCN fw
                           WHERE apa.approval_process_id = t.approval_process_fk
                             AND t.actual_approver_fk    = fw.firm_worker_id
                             AND apa.active_process = 1
                             AND apa.approvable_type_fk = 9) --Payment Requests
                   WHERE rk = 1) apprv    
           WHERE bfr.firm_id                   = pr.buyer_firm_fk
             AND pr.create_date               >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
             AND sfr.firm_id                   = pr.supply_firm_fk
             AND pr.payment_request_spec_fk    = prs.contract_term_id
             AND prs.payment_type_fk           = pt.identifier
             AND pr.assignment_continuity_fk   = ac.assignment_continuity_id
             AND ac.assignment_continuity_id   = ae.assignment_continuity_fk
             AND ac.current_edition_fk         = ae.assignment_edition_id
             AND ac.currency_unit_fk           = cu.value(+)     
             AND pr.identifier                 = apprv.payment_request_id(+)}';

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
