/*******************************************************************************
SCRIPT NAME         lego_project_agreement.sql 
 
LEGO OBJECT NAME    LEGO_PROJECT_AGREEMENT
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Sajeev Sadasivan

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark     - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
04/07/2014 - E.Clark     - IQN-15422 - added PA_STATUS_ID for localization in view - Release 12.0.3
03/24/2016 - jpullifrone             - modifications for DB links, multiple sources, and remote SCN,
                                       removed pa_status, pa_assigned_cams, current_phase - these can be joined back inside a view
08/15/2016 - jpullifrone - IQN-34018 removed parallel hint                                   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_project_agreement.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_PROJECT_AGREEMENT'; 

  v_clob CLOB :=
q'{ SELECT * 
      FROM (WITH 
            mi_exp AS 
             (SELECT /*+ MATERIALIZE */
                     pa.contract_id pa_id,
                     NVL(SUM(e.payment_amount),0) amount
                FROM project_agreement@db_link_name AS OF SCN source_db_SCN pa, 
                     milestone_invoice@db_link_name AS OF SCN source_db_SCN mi, 
                     expenditure@db_link_name AS OF SCN source_db_SCN e
               WHERE pa.contract_id = mi.project_agreement_fk
                 AND mi.expenditure_fk = e.identifier
                 AND mi.state_code IN (6, 3, 2, 5, 8)
               GROUP BY pa.contract_id),
            assign_exp AS
             (SELECT /*+ MATERIALIZE */
                     ae.project_agmt_fk pa_id,
                     NVL(SUM(ae.estimated_buyer_amount),0) amount
                FROM assignment_expenditure@db_link_name AS OF SCN source_db_SCN ae
               GROUP BY ae.project_agmt_fk),
            tc_exp AS
             (SELECT /*+ MATERIALIZE */
                     ae.project_agmt_fk pa_id,
                     NVL(SUM(estimated_buyer_amount),0) amount
                FROM assignment_expenditure@db_link_name AS OF SCN source_db_SCN ae, 
                     timecard_entry@db_link_name AS OF SCN source_db_SCN tce
               WHERE tce.assignment_expenditure_fk = ae.assignment_expenditure_id
                 AND EXISTS (SELECT timecard_fk
                               FROM milestone_invoice_detail@db_link_name AS OF SCN source_db_SCN mid,
                                    milestone_invoice@db_link_name AS OF SCN source_db_SCN mi
                              WHERE mi.project_agreement_fk = ae.project_agmt_fk
                                AND mi.identifier = mid.milestone_invoice_fk
                                AND tce.timecard_fk = mid.timecard_fk
                                AND mi.state_code IN (6, 3, 2, 5, 8))
                 AND EXISTS (SELECT contract_id
                               FROM (SELECT cv3.contract_fk contract_id, RANK () OVER (PARTITION BY cv3.contract_fk ORDER BY cv3.contract_version_number DESC) rk
                                       FROM project_agreement_version@db_link_name AS OF SCN source_db_SCN pav,
                                            contract_version@db_link_name AS OF SCN source_db_SCN cv3
                                      WHERE cv3.contract_version_id = pav.contract_version_id
                                        AND NVL(pav.end_date,SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
                                        AND pav.project_timecards_based = 1)
                              WHERE contract_id = ae.project_agmt_fk AND rk = 1)
                GROUP BY ae.project_agmt_fk),
            pa_ver AS
             (SELECT /*+ MATERIALIZE */
                     contract_fk, 
                     contract_version_number, 
                     contract_version_id,
                     project_agreement_approver_fk
                FROM (SELECT cv.contract_fk,
                             cv.contract_version_number,
                             cv.contract_version_id,
                             pav.project_agreement_approver_fk, 
                             RANK () OVER (PARTITION BY cv.contract_fk ORDER BY cv.contract_version_id DESC, NULL) rk
                        FROM contract_version@db_link_name AS OF SCN source_db_SCN cv,
                             project_agreement_version@db_link_name AS OF SCN source_db_SCN pav
                       WHERE cv.contract_version_id = pav.contract_version_id(+)
                         AND NVL(pav.end_date,SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
                         AND (object_version_state NOT IN (3, 4) OR contract_version_number = 1))
               WHERE rk = 1),
            pr AS
             (SELECT /*+ MATERIALIZE */
                     DISTINCT 
                     pa.contract_id pa_id,                      
                     'PAYMENT_REQUEST' pr_type
                FROM project_agreement@db_link_name AS OF SCN source_db_SCN pa,
                     project_agreement_version@db_link_name AS OF SCN source_db_SCN pav,
                     project_agmt_version_state@db_link_name AS OF SCN source_db_SCN pagv,
                     contract_version@db_link_name AS OF SCN source_db_SCN cv,
                     milestone_invoice@db_link_name AS OF SCN source_db_SCN mi
               WHERE pa.contract_id = cv.contract_fk(+)
                 AND cv.contract_version_id = pav.contract_version_id(+)
                 AND pav.state_fk = pagv.value(+)
                 AND NVL(pav.end_date,SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
                 AND pa.contract_id = mi.project_agreement_fk
                 AND cv.contract_version_number = (SELECT MAX(cvi.contract_version_number)
                                                     FROM contract_version@db_link_name AS OF SCN source_db_SCN cvi
                                                    WHERE cvi.contract_fk = cv.contract_fk
                                                      AND (cvi.object_version_state NOT IN (3, 4) OR cvi.contract_version_number = 1))),
            tot_assign_cnt AS
              (SELECT COUNT(assignment_continuity_id) AS total_assignment_cnt, 
                      project_agmt_fk  AS project_agreement_id
                 FROM assignment_continuity@db_link_name AS OF SCN source_db_SCN 
                WHERE project_agmt_fk IS NOT NULL
                GROUP BY project_agmt_fk)
    -------------------
    SELECT 
           buyer_org_id,
           supplier_org_id,
           project_agreement_id,
           project_id,
           pa_name,
           pa_currency_id,
           pa_currency,
           current_phase_id,
           --current_phase,
           project_agreement_version_id,
           org_sub_classification,
           pa_status_id,
           --pa_status,
           pa_start_date,
           pa_end_date,
           customer_mgr_person_id,
           timecard_approver_person_id,
           org_proj_agmt_mgr_person_id,
           supplier_project_mgr_person_id,
           pa_approver_person_id,
           approval_process_spec_name,
           pa_cac_collection1_id,
           pa_cac_collection2_id,
           source_project_rfx_response_id,
           pa_udf_collection_id,
           --pa_assigned_cams,
           pa_remaining_budget,
           pa_payment_requests,
           pa_total_amount_req_todate,
           pa_total_estimated_cost,
           pa_total_amount,
           pr_total_budget,
           pr_total_expenditure,
           pr_remaining_budget,
           total_assignment_cnt
      FROM (SELECT bfr.business_org_fk                          AS buyer_org_id,
                   sfr.business_org_fk                          AS supplier_org_id,
                   pa.org_sub_classification,
                   p.project_id                                 AS project_id,
                   pa.contract_id                               AS project_agreement_id,
                   pa.name pa_name,
                   pa_cu.value                                  AS pa_currency_id,
                   pa_cu.description                            AS pa_currency,
                   pa.current_phase                             AS current_phase_id,
                   --cp_jcl.constant_description                  AS current_phase,
                   pav.contract_version_id                      AS project_agreement_version_id,
                   pav.state_fk                                 AS pa_status_id,
                   --java_constant.constant_description           AS pa_status,
                   pav.start_date pa_start_date,
                   pav.end_date pa_end_date,
                   fwcu.never_null_person_fk                    AS customer_mgr_person_id,
                   tca.never_null_person_fk                     AS timecard_approver_person_id,
                   fwfn.never_null_person_fk                    AS org_proj_agmt_mgr_person_id,
                   pasfw.never_null_person_fk                   AS supplier_project_mgr_person_id,
                   paapprvrfw.never_null_person_fk              AS pa_approver_person_id,
                   appr_wkflw.name                              AS approval_process_spec_name,
                   pa.cac_collection1_fk                        AS pa_cac_collection1_id,
                   pa.cac_collection2_fk                        AS pa_cac_collection2_id,
                   pa.source_project_rfx_response_fk            AS source_project_rfx_response_id,
                   pav.udf_collection_fk                        AS pa_udf_collection_id,
                   --cams.pa_assigned_cams,
                   pa.num_qualified_payment_requests            AS pa_payment_requests,
                   NVL(mi_exp.amount,0) + NVL(assign_exp.amount,0) - NVL(tc_exp.amount,0) AS pa_total_amount_req_todate,
                   NVL(pav.total_estimated_costs,0) - (NVL(mi_exp.amount,0) + NVL(assign_exp.amount,0) - NVL(tc_exp.amount,0)) AS pa_remaining_budget,
                   CASE
                     WHEN pr.pr_type = 'PAYMENT_REQUEST' THEN NVL(pav.total_estimated_costs,0) - (NVL(mi_exp.amount,0) + NVL(assign_exp.amount,0) - NVL(tc_exp.amount,0))
                     ELSE 0
                   END                                         AS pr_remaining_budget,
                   NVL(pav.total_estimated_costs, 0)           AS pa_total_estimated_cost,
                   NVL(pav.total_estimated_costs, 0)           AS pa_total_amount,
                   CASE
                     WHEN pr.pr_type = 'PAYMENT_REQUEST' THEN NVL(pav.total_estimated_costs,0)
                     ELSE 0
                   END                                         AS pr_total_budget,
                   CASE
                     WHEN pr.pr_type = 'PAYMENT_REQUEST' THEN NVL(mi_exp.amount,0) + NVL(assign_exp.amount,0) - NVL(tc_exp.amount,0)
                     ELSE 0
                   END                                         AS pr_total_expenditure,
                   NVL(tot_assign_cnt.total_assignment_cnt,0)  AS total_assignment_cnt
              FROM project@db_link_name AS OF SCN source_db_SCN p,
                   project_agreement@db_link_name AS OF SCN source_db_SCN pa,
                   project_agreement_version@db_link_name AS OF SCN source_db_SCN pav,
                   contract_version@db_link_name AS OF SCN source_db_SCN cv,
                   firm_role@db_link_name AS OF SCN source_db_SCN bfr,
                   firm_role@db_link_name AS OF SCN source_db_SCN sfr,
                   firm_worker@db_link_name AS OF SCN source_db_SCN tca,
                   firm_worker@db_link_name AS OF SCN source_db_SCN fwcu,
                   firm_worker@db_link_name AS OF SCN source_db_SCN fwfn,
                   firm_worker@db_link_name AS OF SCN source_db_SCN pasfw,
                   firm_worker@db_link_name AS OF SCN source_db_SCN paapprvrfw,
                   approval_process_spec@db_link_name AS OF SCN source_db_SCN appr_wkflw,
                   currency_unit@db_link_name pa_cu,
                   mi_exp,
                   assign_exp,
                   tc_exp,
                   pa_ver,
                   pr,
                   tot_assign_cnt--,
                   --(SELECT jcl.constant_value, jcl.constant_description
                   --   FROM java_constant_lookup jcl
                   --  WHERE jcl.constant_type    = 'PAVersionState'
                   --    AND UPPER(jcl.locale_fk) = 'EN_US') java_constant,
                   --(SELECT pac.project_agreement_fk AS project_agreement_id,
                   --        LISTAGG(p.display_name,'; ') WITHIN GROUP (ORDER BY p.display_name) AS pa_assigned_cams
                   --   FROM project_agreement_cams_x@db_link_name AS OF SCN source_db_SCN pac,
                   --        firm_worker@db_link_name AS OF SCN source_db_SCN fwcam,
                   --        lego_person p
                   --  WHERE pac.firm_worker_fk         = fwcam.firm_worker_id
                   --    AND fwcam.never_null_person_fk = p.person_id
                   --  GROUP BY pac.project_agreement_fk) cams,
                   -- (SELECT constant_value, constant_description
                   --    FROM java_constant_lookup
                   --   WHERE constant_type    = 'PROJECT_AGREEMENT_PHASE'
                   --     AND UPPER(locale_fk) = 'EN_US') cp_jcl 
             WHERE p.buyer_firm_fk                       = bfr.firm_id
               AND pa.supply_firm_fk                     = sfr.firm_id(+)
               AND p.project_id                          = pa.project_fk
               AND pa.contract_id                        = cv.contract_fk(+)
               AND cv.contract_version_id                = pav.contract_version_id(+)
               AND pa.timecard_approver_fk               = tca.firm_worker_id(+)
               AND pa.customer_manager_fk                = fwcu.firm_worker_id(+)
               AND pa.org_unit_proj_agmt_mgr_fk          = fwfn.firm_worker_id(+)
               AND pa.supplier_project_manager_fk        = pasfw.firm_worker_id(+)
               AND pa_ver.project_agreement_approver_fk  = paapprvrfw.firm_worker_id(+)
               AND pa.currency_unit_fk                   = pa_cu.value(+)
               AND pav.approval_workflow_fk              = appr_wkflw.approval_process_spec_id(+)
               --AND pav.state_fk                          = java_constant.constant_value(+)
               AND NVL(pav.end_date,SYSDATE)            >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
               AND pa.contract_id                        = pr.pa_id(+)
               AND cv.contract_fk                        = pa_ver.contract_fk
               AND cv.contract_version_id                = pa_ver.contract_version_id
               AND cv.contract_version_number            = pa_ver.contract_version_number
               AND pa.contract_id                        = mi_exp.pa_id(+)
               AND pa.contract_id                        = tc_exp.pa_id(+)
               AND pa.contract_id                        = assign_exp.pa_id(+)
               --AND pa.contract_id                        = cams.project_agreement_id(+)
               --AND pa.current_phase                      = cp_jcl.constant_value(+)
               AND pa.contract_id                        = tot_assign_cnt.project_agreement_id(+)))
     ORDER BY buyer_org_id, supplier_org_id, project_agreement_id, project_id}';

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

