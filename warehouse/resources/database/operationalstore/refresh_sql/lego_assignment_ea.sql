/*******************************************************************************
SCRIPT NAME         lego_assignment_ea.sql 
 
LEGO OBJECT NAME    LEGO_ASSIGNMENT_EA
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark     - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
04/04/2014 - E.Clark     - IQN-15392 - localized RATE_TYPE - Release 12.0.3
01/27/2016 - pmuller                 - modifications for DB links, multiple sources, and remote SCN
03/09/2016 - pmuller                 - removed localized columns, address GUID, and CAC columns
05/26/2016 - jpullifrone - IQN-32394 - add, has_ever_been_effective, column.  Removed parallel hint.    
08/02/2016 - jpullifrone - IQN-33807 - add job_level info adn supplier_resource_id
05/03/2017 - jpullifrone - IQN-35777 - remove est_wo_budget_remain_approved; added assignment_effective_date
05/04/2017 - jpullifrone - IQN-37567 - add create_date
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assignment_ea.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSIGNMENT_EA'; 

  v_clob CLOB := q'{SELECT 
                --Express Assignments
                ac.assignment_continuity_id,
                cand.person_fk               AS contractor_person_id,
                hfw.user_fk                  AS hiring_mgr_person_id,
                ahm_fw.user_fk               AS act_hiring_mgr_person_id,
                fr.business_org_fk           AS buyer_org_id,
                frs.business_org_fk          AS supplier_org_id,
                ac.job_fk                    AS job_id,
                cand.candidate_id            AS candidate_id,
                'EA'                         AS assignment_type,
                '0'                          AS amendment_in_process_num,
				assgn_dates.assignment_create_date,
                TRUNC(pa.start_date)         AS assignment_start_dt,
                TRUNC(pa.end_date)           AS assignment_end_dt,
                TRUNC(NVL(ae.actual_end_date, pa.end_date)) AS assignment_actual_end_dt,
                TRUNC(ae.actual_end_date)    AS actual_end_dt_no_deflt,
				assgn_dates.assignment_effective_date,
                TRUNC(ae.create_date)        AS last_modified_date,
                TRUNC(NVL(ae.actual_end_date, pa.end_date) - pa.start_date) AS assignment_duration,
                ac.has_ever_been_effective,
                CASE WHEN ae.assignment_state_fk = 3  THEN 3    -- Awaiting Start Date
                     WHEN ae.assignment_state_fk = 10 THEN 7    -- Completed
                     WHEN ae.assignment_state_fk = 12 THEN 17   -- Terminated
                     WHEN ae.assignment_state_fk = 7  THEN 6    -- Canceled
                     WHEN ae.assignment_state_fk = 1  THEN 18   -- Approval In Process
                     WHEN ae.assignment_state_fk = 13 THEN
                        CASE WHEN (ac.onboard_allowed = 1 AND ac.onboard_date IS NOT NULL) THEN 9    -- Effective-OnBoard
                             ELSE 8    -- Effective
                        END
                END AS assignment_state_id,
                DECODE(ae.approval_status,
                           4, 6,                --REAPPROVING
                           5, 4,                --APPROVED
                           6, 5,                --REJECTED
                           ae.approval_status)  AS approval_state_id,
                DECODE (ae.approval_status,
                           0, '-',
                           1, 'Approval Not Required',
                           2, 'Needs Approval',
                           3, 'Approval Pending',
                           4, 'Reapproving',
                           5, 'Approved',
                           6, 'Rejected',
                           7, 'Supplier Request Rejected By Hiring Manager')  AS approval_state,
                DECODE (pwe.requisition_type,
                        'LTR',  'Long Term',
                        'LTNR', 'Long Term',
                        'DAILY','Daily',
                        'N/A')               AS sourcing_method,
                ae.sourcing_method_name_fk   AS candidate_sourcing_method_id,
                ac.current_edition_fk        AS current_edition_id,
                1                            AS contract_version_id,
                ae.resource_onsite_fk        AS contact_info_id,
                cam_fw.never_null_person_fk  AS cam_person_id,
                sar_fw.never_null_person_fk  AS sar_person_id,
                ac.project_fk                AS project_id,
                ae.project_agmt_fk           AS project_agreement_id,
                creator.creator_fk           AS creator_person_id,
                ae.timecard_approval_workflow_fk AS timecard_approval_workflow_id,
                ae.evaluation_fk                 AS evaluation_id,
                ac.procurement_wkfl_edition_fk   AS procurement_wkfl_edition_id,
                CASE WHEN NVL(ac.is_targeted_assignment, -1) <> 0 THEN 'Headcount Tracking Assignment'
                     WHEN pwe.procurement_wkfl_edition_id IS NOT NULL THEN
                        CASE WHEN pwe.requisition_type = 'DAILY' THEN 'Daily'
                        ELSE 'Long Term'
                        END
                ELSE
                    NULL
                END AS assign_requisition_type,
                ae.approval_workflow_fk          AS approval_workflow_id,
                ae.worker_fk                     AS worker_id,
                ac.work_order_fk                 AS work_order_id,
                ae.udf_collection_fk             AS udf_collection_id,
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
                ac.phase_type_id                 AS current_phase_type_id,
                ald.rate_unit_fk                 AS rate_type_id,
                DECODE(ald.rate_unit_fk,
                        '0', 'Hourly',
                        '1', 'Daily',
                        '2', 'Annual',
                        '3', 'Monthly',
                        '4', 'Weekly',
                        'N/A')                     AS rate_type,
                rs.bill_rate                       AS reg_bill_rate,
                rs.ot_bill_rate                    AS ot_bill_rate,
                rs.dt_bill_rate                    AS dt_bill_rate,
                NVL(custom_rates.custom_bill_rate,0) AS custom_bill_rate,
                --buyer (adjusted) rates
                ald.buyer_adj_bill_rate            AS adjusted_bill_rate,
                ald.buyer_adj_bill_rate_dt         AS adjusted_ot_rate,
                ald.buyer_adj_bill_rate_ot         AS adjusted_dt_rate,
                CASE WHEN ald.buyer_adj_bill_rate_rt_idntfr IS NOT NULL THEN cust_adj.amount
                ELSE NULL
                END AS adjusted_custom_rate,
                --supplier reimb rates
                ald.supplier_reimbursement_rate    AS supplier_reimb_bill_rate,
                ald.supplier_reimbursement_rate_ot AS supplier_ot_reimb_bill_rate,
                ald.supplier_reimbursement_rate_dt AS supplier_dt_reimb_bill_rate,
                cust_adj.amount                    AS supplier_cust_reimb_bill_rate,
                --pay rates
                rs.pay_rate                        AS reg_pay_rate,
                rs.ot_pay_rate                     AS ot_pay_rate,
                rs.dt_pay_rate                     AS dt_pay_rate,
                NVL(custom_rates.custom_pay_rate,0) AS custom_pay_rate,
                --markup rates
                rs.markup                          AS reg_mark_up,
                rs.ot_markup                       AS ot_mark_up,
                rs.dt_markup                       AS dt_mark_up,
                NVL(custom_rates.custom_mark_up_rate,0) AS custom_mark_up,
                cu.value                           AS assignment_currency_id,
                cu.description                     AS assignment_currency,
                CASE WHEN NVL(pwe.requisition_type,'DAILY')='DAILY' THEN
                   NULL
                ELSE
                   ae.total_amount
                END                                AS est_total_budgeted_amount
           FROM (SELECT assignment_edition_fk,
                        position_assignment_fk,
                        RANK () OVER (PARTITION BY a1.assignment_edition_fk
                                ORDER BY a1.position_assignment_fk DESC, a1.rowid DESC) aepa_rk
                   FROM asgmt_edition_position_asgmt_x@db_link_name AS OF SCN source_db_SCN a1) aepa,
                position_assignment@db_link_name AS OF SCN source_db_SCN pa,
                firm_worker@db_link_name AS OF SCN source_db_SCN hfw,
                firm_worker@db_link_name AS OF SCN source_db_SCN cam_fw,
                firm_worker@db_link_name AS OF SCN source_db_SCN sar_fw,
                firm_worker@db_link_name AS OF SCN source_db_SCN ahm_fw,
                firm_role@db_link_name AS OF SCN source_db_SCN fr,
                firm_role@db_link_name AS OF SCN source_db_SCN frs,
                rate_set@db_link_name AS OF SCN source_db_SCN rs,
                currency_unit@db_link_name AS OF SCN source_db_SCN cu,
                (SELECT ald1.*,
                        RANK () OVER (PARTITION BY ald1.assignment_edition_fk
                                ORDER BY ald1.valid_from DESC, rowid desc) ald_rk
                   FROM assignment_line_detail@db_link_name AS OF SCN source_db_SCN ald1) ald,
                candidate@db_link_name AS OF SCN source_db_SCN cand,
                assignment_edition@db_link_name AS OF SCN source_db_SCN ae,
                worker_continuity@db_link_name AS OF SCN source_db_SCN wc,
                worker_edition@db_link_name AS OF SCN source_db_SCN we,
                job_category@db_link_name AS OF SCN source_db_SCN  jc,
                job_level@db_link_name AS OF SCN source_db_SCN jl,
                assignment_continuity@db_link_name AS OF SCN source_db_SCN ac,
                procurement_wkfl_edition@db_link_name AS OF SCN source_db_SCN pwe,                
                (SELECT ae3.assignment_continuity_fk, ae3.creator_fk
                   FROM assignment_edition@db_link_name AS OF SCN source_db_SCN ae3
                  WHERE ae3.revision = 1) creator,
                (SELECT rate_identifier_rate_set_fk,
                        SUM(DECODE(rate_category_fk,1,rate,0)) AS custom_pay_rate,
                        SUM(DECODE(rate_category_fk,2,rate,0)) AS custom_mark_up_rate,
                        SUM(DECODE(rate_category_fk,3,rate,0)) AS custom_bill_rate
                   FROM rate_category_rate@db_link_name AS OF SCN source_db_SCN
                  WHERE rate_category_fk IN (1,2,3)
                  GROUP BY rate_identifier_rate_set_fk) custom_rates,
                (SELECT identifier, amount
                   FROM invoice_line_item@db_link_name AS OF SCN source_db_SCN) cust_adj, -- ald.buyer_adj_bill_rate_rt_idntfr)
		        (SELECT aed.assignment_continuity_fk AS assignment_continuity_id,
				        MIN(CASE WHEN en.value = 3012 THEN ed.TIMESTAMP ELSE NULL END) AS assignment_effective_date,
                        MIN(CASE WHEN en.value IN (3007, 3008, 3021) THEN ed.TIMESTAMP ELSE NULL END) AS assignment_create_date
                   FROM event_description@db_link_name AS OF SCN source_db_SCN ed,
                        assignment_event_description@db_link_name AS OF SCN source_db_SCN aed,
                        event_name@db_link_name AS OF SCN source_db_SCN en
                  WHERE ed.identifier = aed.identifier
                    AND ed.event_name_fk = en.value
                    AND en.value IN (3007, 3008, 3012, 3021)
                  GROUP BY aed.assignment_continuity_fk) assgn_dates				   
          WHERE ac.work_order_fk IS NULL
            AND NVL(ae.actual_end_date, pa.end_date) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
            AND ac.current_edition_fk          = ae.assignment_edition_id
            AND ac.assignment_continuity_id    = ae.assignment_continuity_fk
            AND ac.assignment_continuity_id    = creator.assignment_continuity_fk
            AND ac.procurement_wkfl_edition_fk = pwe.procurement_wkfl_edition_id(+)
            AND ae.assignment_edition_id       = aepa.assignment_edition_fk(+)            
            AND aepa.aepa_rk                   = 1
            AND aepa.position_assignment_fk    = pa.position_assignment_id
            AND ae.hiring_mgr_fk               = hfw.firm_worker_id(+)
            AND ae.assignment_admin_fk         = ahm_fw.firm_worker_id(+)
            AND ae.cam_firm_worker_fk          = cam_fw.firm_worker_id(+)
            AND ae.supplier_account_rep        = sar_fw.firm_worker_id(+)
            AND ae.job_category_fk             = jc.value(+)
            AND ae.job_level_fk                = jl.value(+)
            AND ac.owning_buyer_firm_fk        = fr.firm_id
            AND ac.owning_supply_firm_fk       = frs.firm_id
            AND ae.assignment_edition_id       = ald.assignment_edition_fk
            AND ald.ald_rk                     = 1
            AND ald.rate_set_fk                = rs.rate_set_id (+)
            AND ac.candidate_fk                = cand.candidate_id
            AND ac.currency_unit_fk            = cu.value
            AND rs.rate_identifier_rate_set_fk = custom_rates.rate_identifier_rate_set_fk(+)
            AND ald.buyer_adj_bill_rate_rt_idntfr = cust_adj.identifier(+)
            AND ae.worker_fk                   = wc.worker_continuity_id(+)
            AND wc.current_edition_fk          = we.worker_edition_id(+)
            AND ac.assignment_continuity_id    = assgn_dates.assignment_continuity_id(+)}';

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

