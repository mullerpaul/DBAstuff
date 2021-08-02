/*******************************************************************************
SCRIPT NAME         lego_assignment_wo.sql 
 
LEGO OBJECT NAME    LEGO_ASSIGNMENT_WO
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark -     IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
04/04/2014 - E.Clark -     IQN-15392 - localized RATE_TYPE - Release 12.0.3
01/27/2016 - pmuller                 - modifications for DB links, multiple sources, and remote SCN
03/09/2016 - pmuller                 - removed localized columns, address GUID, listagg'ed reason code column, and CAC columns
05/26/2016 - jpullifrone - IQN-32394 - add, has_ever_been_effective, column. Removed parallel hint.
08/02/2016 - jpullifrone - IQN-33807 - add job_level info and supplier_resource_id
09/13/2016 - jpullifrone - IQN-32037 - add description from work_assignment_term 
05/03/2017 - jpullifrone - IQN-35777 - remove est_wo_budget_remain_approved; added effective_date, released_to_supplier_date, accepted_by_supplier_date 
05/22/2017 - jpullifrone - IQN-37665 - add offer_id for Supplier Scorecard 2.0
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assignment_wo.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSIGNMENT_WO'; 

  v_clob CLOB := q'{SELECT 
          --Work Order Assignments
           ac.assignment_continuity_id,
           cand.person_fk               AS contractor_person_id,
           hfw.user_fk                  AS hiring_mgr_person_id,
           ahm_fw.user_fk               AS act_hiring_mgr_person_id,
           fr.business_org_fk           AS buyer_org_id,
           frs.business_org_fk          AS supplier_org_id,
           ac.job_fk                    AS job_id,
           cand.candidate_id            AS candidate_id,
           o.offer_id,
           'WO'                         AS assignment_type,
           ac.assignment_continuity_id ||'/'||cv.contract_version_name AS amendment_id,
           wos.in_process_ver_name      AS amendment_in_process_num,
		   NVL(wo_event_dates.wo_create_date, creator.create_date)  AS assignment_create_date,
           TRUNC(wos.curr_ver_start_date) AS assignment_start_dt,
           TRUNC(wos.curr_ver_end_date)   AS assignment_end_dt,
           TRUNC(NVL(ae.actual_end_date, wos.curr_ver_end_date))  AS assignment_actual_end_dt,
           TRUNC(ae.actual_end_date)     AS actual_end_dt_no_deflt,
           wo_event_dates.wo_release_to_supp_date AS released_to_supplier_date,
           wo_event_dates.wo_accept_by_supp_date  AS accepted_by_supplier_date,		   
           wo_event_dates.wo_effective_date       AS assignment_effective_date,
           TRUNC(wov.last_modified_date) AS last_modified_date,
           TRUNC(NVL(ae.actual_end_date, wos.curr_ver_end_date) - wos.curr_ver_start_date) AS assignment_duration,
           ac.has_ever_been_effective,
           DECODE (wov.approval_status,
                   1, 2,                   --NEEDS_APPROVAL
                   2, 3,                   --APPROVING
                   3, 6,                   --REAPPROVING
                   4, 5,                   --APPROVAL_REJECTED
                   5, 4,                   --APPROVED
                   6, 1,                   --APPROVAL_NOT_REQUIRED
                   wov.approval_status) AS approval_state_id,
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
           DECODE (wov.approval_status,
                   1, 'Needs Approval',
                   2, 'Approval Pending',
                   3, 'Reapproving',
                   4, 'Rejected',
                   5, 'Approved',
                   6, 'Approval Not Required',
                   7, 'Supplier Request Rejected By Hiring Manager')  AS approval_state,
           DECODE (o.offer_type,
                   'C',    'Requisitioned',
                   'MC',   'Targeted Work Order',
                   'PAC',  'Requisitioned',
                   'WL',   'Loaded',
                   'WLRC', 'Loaded',
                    NULL)               AS sourcing_method,
           ae.sourcing_method_name_fk   AS candidate_sourcing_method_id,
           ac.current_edition_fk        AS current_edition_id,
           ae.resource_onsite_fk        AS contact_info_id,
           cam_fw.never_null_person_fk  AS cam_person_id,
           sar_fw.never_null_person_fk  AS sar_person_id,
           ac.project_fk                AS project_id,
           ae.project_agmt_fk           AS project_agreement_id,
           creator.creator_fk               AS creator_person_id,
           ae.timecard_approval_workflow_fk AS timecard_approval_workflow_id,
           ae.evaluation_fk                 AS evaluation_id,
           ac.procurement_wkfl_edition_fk   AS procurement_wkfl_edition_id,
           'Work Order'                     AS assign_requisition_type,
           ae.approval_workflow_fk          AS approval_workflow_id,
           ae.worker_fk                     AS worker_id,
           ac.work_order_fk                 AS work_order_id,
           ae.udf_collection_fk             AS udf_collection_id,
           wov.udf_collection_fk            AS wov_udf_collection_id,
           we.udf_collection_fk             AS worker_ed_udf_collection_id,
           ac.onboard_allowed,
           ae.onboard_checklist_fk          AS onboard_checklist_id,
           ae.buyer_resource_id,
           ae.supplier_resource_id,
           ae.org_sub_classification,
           jc.value                         AS jc_value,
           jc.type                          AS jc_type,
           jc.description                   AS jc_description,
           jl.value                         AS jl_value,
           jl.description                   AS jl_description,           
           ae.job_title                     AS assign_job_title,
           ae.job_title_lp                  AS assign_job_title_lp,
           wat.description                  AS wat_description,
           ac.phase_type_id                 AS current_phase_type_id,
           fet.buyer_bill_rate_unit_fk      AS rate_type_id,
           DECODE (fet.buyer_bill_rate_unit_fk,
                   '0','Hourly',
                   '1', 'Daily',
                   '2', 'Annual',
                   '3', 'Monthly',
                   '4', 'Weekly',
                   'N/A')                    AS rate_type,
           fet.supplier_bill_rate            AS reg_bill_rate,
           fet.supplier_ot_rate              AS ot_bill_rate,
           fet.supplier_dt_rate              AS dt_bill_rate,
           NVL(custom_rates.custom_bill_rate,0) AS custom_bill_rate,
           --buyer (adjusted) rates
           fet.buyer_bill_rate                 AS adjusted_bill_rate,
           fet.buyer_ot_rate                   AS adjusted_ot_rate,
           fet.buyer_dt_rate                   AS adjusted_dt_rate,
           fet.buyer_adj_bill_rate_rt_idntfr   AS adjusted_custom_rate,
           --supplier reimb rates
           fet.supplier_reimbursement_rate     AS supplier_reimb_bill_rate,
           fet.supplier_ot_reimbursement_rate  AS supplier_ot_reimb_bill_rate,
           fet.supplier_dt_reimbursement_rate  AS supplier_dt_reimb_bill_rate,
           fet.supplier_reimburse_rt_idntfr    AS supplier_cust_reimb_bill_rate,
           --pay rates
           fet.pay_rate                        AS reg_pay_rate,
           fet.ot_pay_rate                     AS ot_pay_rate,
           fet.dt_pay_rate                     AS dt_pay_rate,
           NVL(custom_rates.custom_pay_rate,0) AS custom_pay_rate,
           --markup rates
           fet.mark_up                       AS reg_mark_up,
           fet.ot_mark_up                    AS ot_mark_up,
           fet.dt_mark_up                    AS dt_mark_up,
           NVL(custom_rates.custom_mark_up_rate,0) AS custom_mark_up,
           cu.value                          AS assignment_currency_id,
           cu.description                    AS assignment_currency,
           wov.total_amount                  AS est_total_budgeted_amount           
      FROM contract@db_link_name AS OF SCN source_db_SCN c,
           (SELECT cv1.contract_version_id, cv1.contract_fk, cv1.contract_version_name,
                   RANK () OVER (PARTITION BY cv1.contract_fk
                                     ORDER BY cv1.contract_version_number DESC, cv1.create_date DESC) cv_rk
              FROM contract_version@db_link_name AS OF SCN source_db_SCN cv1
             WHERE cv1.object_version_state <> 4 OR cv1.contract_type = 'WO' ) cv,
           work_order@db_link_name AS OF SCN source_db_SCN wo,
           offer@db_link_name AS OF SCN source_db_SCN o,
           work_order_summary@db_link_name AS OF SCN source_db_SCN wos,
           work_order_version@db_link_name AS OF SCN source_db_SCN wov,
           contract_term@db_link_name AS OF SCN source_db_SCN pt_ct,
           performance_term@db_link_name AS OF SCN source_db_SCN pert,
           firm_role@db_link_name AS OF SCN source_db_SCN frs,
           firm_role@db_link_name AS OF SCN source_db_SCN fr,
           assignment_continuity@db_link_name AS OF SCN source_db_SCN ac,
           assignment_edition@db_link_name AS OF SCN source_db_SCN ae,
           worker_continuity@db_link_name AS OF SCN source_db_SCN wc,
           worker_edition@db_link_name AS OF SCN source_db_SCN we,
           job_category@db_link_name  AS OF SCN source_db_SCN  jc,
           job_level@db_link_name     AS OF SCN source_db_SCN jl,
           firm_worker@db_link_name   AS OF SCN source_db_SCN  hfw,
           firm_worker@db_link_name   AS OF SCN source_db_SCN  cam_fw,
           firm_worker@db_link_name   AS OF SCN source_db_SCN  sar_fw,
           firm_worker@db_link_name   AS OF SCN source_db_SCN  ahm_fw,
           candidate@db_link_name     AS OF SCN source_db_SCN  cand,
           contract_term@db_link_name AS OF SCN source_db_SCN fet_ct,
           contract_term@db_link_name AS OF SCN source_db_SCN wa_ct,
           work_assignment_term@db_link_name AS OF SCN source_db_SCN wat,
           fee_expense_term@db_link_name AS OF SCN source_db_SCN fet,
           currency_unit@db_link_name AS OF SCN source_db_SCN cu,
           (SELECT ae3.assignment_continuity_fk, ae3.creator_fk, ae3.create_date
              FROM assignment_edition@db_link_name AS OF SCN source_db_SCN ae3
             WHERE ae3.revision = 1) creator,
           (SELECT rate_identifier_rate_set_fk,
                   SUM(DECODE(rate_category_fk,1,rate,0)) AS custom_pay_rate,
                   SUM(DECODE(rate_category_fk,2,rate,0)) AS custom_mark_up_rate,
                   SUM(DECODE(rate_category_fk,3,rate,0)) AS custom_bill_rate
              FROM rate_category_rate@db_link_name AS OF SCN source_db_SCN
             WHERE rate_category_fk IN (1,2,3)
             GROUP BY rate_identifier_rate_set_fk) custom_rates,	
		   (SELECT woed.work_order_id work_order_id,
                   MIN(CASE WHEN en.value = 36000 THEN ed.timestamp END) wo_accept_by_supp_date,
                   MAX(CASE WHEN en.value = 36007 THEN ed.timestamp END) wo_release_to_supp_date,
                   MIN(CASE WHEN en.value = 36012 THEN ed.timestamp END) wo_effective_date,
				   MIN(CASE WHEN en.value IN (36001, 36014, 36015) THEN ed.timestamp END) wo_create_date
              FROM work_order_event_description@db_link_name AS OF SCN source_db_SCN woed,
                   event_description@db_link_name AS OF SCN source_db_SCN ed,
                   event_name@db_link_name AS OF SCN source_db_SCN en
             WHERE woed.IDENTIFIER = ed.IDENTIFIER
               AND ed.event_name_fk = en.value
               AND en.value IN (36000, 36001, 36007, 36012, 36014, 36015)
             GROUP BY work_order_id) wo_event_dates
     WHERE ac.work_order_fk IS NOT NULL
       AND NVL(ae.actual_end_date, wos.curr_ver_end_date) >= ADD_MONTHS(TRUNC(SYSDATE), - months_in_refresh)
       AND ac.current_edition_fk        = ae.assignment_edition_id
       AND ac.assignment_continuity_id  = ae.assignment_continuity_fk
       AND ac.assignment_continuity_id  = creator.assignment_continuity_fk
       AND ac.work_order_fk             = wo.contract_id
       AND wo.contract_id               = c.contract_id
       AND wo.contract_id               = wos.work_order_fk(+)
       AND wo.offer_fk                  = o.offer_id
       AND ac.owning_supply_firm_fk     = frs.firm_id
       AND ac.owning_buyer_firm_fk      = fr.firm_id
       AND ac.currency_unit_fk          = cu.value
       AND c.contract_id                = cv.contract_fk
       AND cv.contract_version_id       = wov.contract_version_id
       AND cv.cv_rk                     = 1
       AND ac.candidate_fk              = cand.candidate_id(+)
       AND ae.hiring_mgr_fk             = hfw.firm_worker_id(+)
       AND ae.assignment_admin_fk       = ahm_fw.firm_worker_id(+)
       AND ae.cam_firm_worker_fk        = cam_fw.firm_worker_id(+)
       AND ae.supplier_account_rep      = sar_fw.firm_worker_id(+)
       AND ae.job_category_fk           = jc.value(+)
       AND ae.job_level_fk              = jl.value(+)              
       AND cv.contract_version_id       = pt_ct.contract_version_fk
       AND pt_ct.type                   = 'PerformanceTerm'
       AND pt_ct.contract_term_id       = pert.contract_term_id                     
       AND cv.contract_version_id       = fet_ct.contract_version_fk
       AND fet_ct.type                  = 'FeeAndExpenseTerm'
       AND fet_ct.contract_term_id      = fet.contract_term_id       
       AND cv.contract_version_id       = wa_ct.contract_version_fk 
       AND wa_ct.type                   = 'WorkAssignmentTerm'            
       AND wa_ct.contract_term_id       = wat.contract_term_id                     
       AND fet.rate_identifier_rate_set_fk = custom_rates.rate_identifier_rate_set_fk(+)
       AND ae.worker_fk                 = wc.worker_continuity_id(+)
       AND wc.current_edition_fk        = we.worker_edition_id(+)
	   AND ac.work_order_fk             = wo_event_dates.work_order_id(+)}';

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

