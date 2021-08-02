/*******************************************************************************
SCRIPT NAME         lego_pa_change_request.sql 
 
LEGO OBJECT NAME    LEGO_PA_CHANGE_REQUEST
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark - IQN-14482   - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
01/27/2016 - jpullifrone IQN-33505 - modifications for DB links, multiple sources, and remote SCN, removed jcl values/tables
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_pa_change_request.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_PA_CHANGE_REQUEST'; 

  v_clob CLOB :=
q'{SELECT buyer_org_id,
          supplier_org_id,
          pa_project_title,
          pa_project_identifier,
          pa_name,
          pa_contract_id AS project_agreement_id,
          cac_collection1_id,
          cac_collection2_id,
          pa_status_id,
          --pa_status_desc,
          deliverable_type_id,
          --deliverable_type_desc,
          pa_description_prev,
          pa_description,
          CASE
             WHEN NVL(pa_description_prev, 'n/a') = NVL(pa_description, 'n/a') THEN 'N'
             ELSE 'Y'
          END AS pa_description_change,
          pa_apprval_status,
          pa_approval_workflow_prev,
          pa_approval_workflow,
          CASE
             WHEN NVL(pa_approval_workflow_prev, 'n/a') = NVL(pa_approval_workflow, 'n/a') THEN 'N'
             ELSE 'Y'
          END AS pa_approval_workflow_change,
          pa_start_dt_prev,
          pa_start_dt,
          CASE
             WHEN NVL(pa_start_dt_prev, TO_DATE('01-JAN-1999','DD-MON-YYYY')) = NVL(pa_start_dt, TO_DATE('01-JAN-1999','DD-MON-YYYY')) THEN 'N'
             ELSE 'Y'
          END AS pa_start_dt_change,
          pa_end_dt_prev,
          pa_end_dt,
          CASE
             WHEN NVL(pa_end_dt_prev, TO_DATE('01-JAN-1999','DD-MON-YYYY')) = NVL(pa_end_dt, TO_DATE('01-JAN-1999','DD-MON-YYYY')) THEN 'N'
             ELSE 'Y'
          END AS pa_end_dt_change,
          curr_conv_eff_date_prev,
          curr_conv_eff_date,
          CASE
             WHEN NVL(curr_conv_eff_date_prev, TO_DATE('01-JAN-1999','DD-MON-YYYY')) = NVL(curr_conv_eff_date, TO_DATE('01-JAN-1999','DD-MON-YYYY')) THEN 'N'
             ELSE 'Y'
          END AS curr_conv_eff_date_change,
          pa_project_mgr_person_id,
          pa_currency_id_prev,
          pa_currency_id,
          CASE
             WHEN NVL(pa_currency_id_prev, -11) = NVL(pa_currency_id, -11) THEN 'N'
             ELSE 'Y'
          END AS pa_currency_id_change,
          pa_currency_prev,
          pa_currency,
          CASE
             WHEN NVL(pa_currency_prev, 'n/a') = NVL(pa_currency, 'n/a') THEN 'N'
             ELSE 'Y'
          END AS pa_currency_change,
          pa_ttl_estimated_costs_prev,
          pa_ttl_estimated_costs,
          CASE
             WHEN NVL(pa_ttl_estimated_costs_prev, 0) = NVL(pa_ttl_estimated_costs, 0) THEN 'N'
             ELSE 'Y'
          END AS pa_ttl_estimated_costs_change,
          pa_total_amt_req_todate_prev,
          pa_total_amt_req_todate,
          CASE
             WHEN NVL(pa_total_amt_req_todate_prev, 0) = NVL(pa_total_amt_req_todate, 0) THEN 'N'
             ELSE 'Y'
          END AS pa_total_amt_req_todate_change,
          pa_remaining_budget_prev,
          pa_remaining_budget,
          CASE
             WHEN NVL(pa_remaining_budget_prev, 0) = NVL(pa_remaining_budget, 0) THEN 'N'
             ELSE 'Y'
          END AS pa_remaining_budget_change,
          pa_paymt_requests_prev,
          pa_paymt_requests,
          CASE
             WHEN NVL(pa_paymt_requests_prev, 0) =  NVL(pa_paymt_requests, 0) THEN 'N'
             ELSE 'Y'
          END AS pa_paymt_requests_change,
          pa_milestone_title_prev,
          pa_milestone_title,
          CASE
             WHEN NVL(pa_milestone_title_prev, 'n/a') = NVL(pa_milestone_title, 'n/a') THEN 'N'
             ELSE 'Y'
          END AS pa_milestone_title_change,
          pa_estimated_start_dt_prev,
          pa_estimated_start_dt,
          CASE
             WHEN NVL(pa_estimated_start_dt_prev, TO_DATE('01-JAN-1999','DD-MON-YYYY')) = NVL(pa_estimated_start_dt, TO_DATE('01-JAN-1999','DD-MON-YYYY')) THEN 'N'
             ELSE 'Y'
          END AS pa_estimated_start_dt_change,
          pa_estimated_end_dt_prev,
          pa_estimated_end_dt,
          CASE
             WHEN NVL(pa_estimated_end_dt_prev, TO_DATE('01-JAN-1999','DD-MON-YYYY')) = NVL(pa_estimated_end_dt, TO_DATE('01-JAN-1999','DD-MON-YYYY')) THEN 'N'
             ELSE 'Y'
          END AS pa_estimated_end_dt_change,
          pa_milestone_comments_prev,
          pa_milestone_comments,
          CASE
             WHEN NVL(pa_milestone_comments_prev, 'n/a') = NVL(pa_milestone_comments, 'n/a') THEN 'N'
             ELSE 'Y'
          END AS pa_milestone_comments_change,
          pa_milestone_billable_prev,
          pa_milestone_billable,
          CASE
             WHEN NVL(pa_milestone_billable_prev, 'n/a') = NVL(pa_milestone_billable, 'n/a') THEN 'N'
             ELSE 'Y'
          END AS pa_milestone_billable_change,
          pa_milestone_amt_prev,
          pa_milestone_amt,
          CASE
             WHEN NVL(pa_milestone_amt_prev, 0) = NVL(pa_milestone_amt, 0) THEN 'N'
             ELSE 'Y'
          END AS pa_milestone_amt_change,
          pa_pr_amount_prev,
          pa_pr_amount,
          CASE
             WHEN NVL(pa_pr_amount_prev, 0) = NVL(pa_pr_amount, 0) THEN 'N'
             ELSE 'Y'
          END AS pa_pr_amount_change,
          po_id,
          pa_version_id AS project_agreement_version_id,
          milestone_version_id,
          pa_version_number - 1 AS pa_version_number,
          -- Complex Resource
          pa_est_labor_cost_prev,
          pa_est_labor_cost,
          CASE
             WHEN NVL(pa_est_labor_cost_prev, 0) = NVL(pa_est_labor_cost, 0) THEN 'N'
             ELSE 'Y'
          END AS pa_est_labor_cost_change,
          --Standard
          rate_table_edition_id,
          pa_std_rate_table_name,
          pa_std_description,
          pa_std_rate_table_type,
          create_date,
          effective_date  
     FROM (SELECT lego.*,
                  NVL(LAG(pa_description,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_description) AS pa_description_prev,
                  NVL(LAG(pa_approval_workflow,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field),pa_approval_workflow) AS pa_approval_workflow_prev,
                  NVL(LAG(pa_start_dt,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field),pa_start_dt) AS pa_start_dt_prev,
                  NVL(LAG(pa_end_dt,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field),pa_end_dt) AS pa_end_dt_prev,
                  NVL(LAG(curr_conv_eff_date,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field),curr_conv_eff_date) AS curr_conv_eff_date_prev,
                  NVL(LAG(pa_currency_id,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_currency_id) AS pa_currency_id_prev,
                  NVL(LAG(pa_currency,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_currency) AS pa_currency_prev,
                  NVL(LAG(pa_ttl_estimated_costs, 1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_ttl_estimated_costs) AS pa_ttl_estimated_costs_prev,
                  NVL(LAG(pa_total_amt_req_todate,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_total_amt_req_todate) AS pa_total_amt_req_todate_prev,
                  NVL(LAG(pa_remaining_budget,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_remaining_budget) AS pa_remaining_budget_prev,
                  NVL(LAG(pa_paymt_requests,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_paymt_requests) AS pa_paymt_requests_prev,
                  NVL(LAG(pa_milestone_title,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field),pa_milestone_title) AS pa_milestone_title_prev,
                  NVL(LAG(pa_estimated_start_dt,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field),pa_estimated_start_dt) AS pa_estimated_start_dt_prev,
                  NVL(LAG(pa_estimated_end_dt,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field),pa_estimated_end_dt) AS pa_estimated_end_dt_prev,
                  NVL(LAG(pa_milestone_comments,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_milestone_comments) AS pa_milestone_comments_prev,
                  NVL(LAG(pa_milestone_billable,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field),pa_milestone_billable) AS pa_milestone_billable_prev,
                  NVL(LAG(pa_milestone_amt,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field),pa_milestone_amt) AS pa_milestone_amt_prev,
                  NVL(LAG(pa_pr_amount,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_pr_amount) AS pa_pr_amount_prev,
                  NVL(LAG(pa_est_labor_cost,1,NULL) OVER (PARTITION BY pa_contract_id, deliverable_type_id ORDER BY pa_version_id, ord_by_field), pa_est_labor_cost) AS pa_est_labor_cost_prev
             FROM (SELECT l.*, COALESCE(l.milestone_version_id, l.rate_table_edition_id) ord_by_field
                     FROM 
(--section1
SELECT 
       fr.business_org_fk             AS buyer_org_id,
       frs.business_org_fk            AS supplier_org_id,
       p.title                        AS pa_project_title,
       p.internal_identifier          AS pa_project_identifier,
       pa.name                        AS pa_name,
       pa.contract_id                 AS pa_contract_id,
       pagv.value                     AS pa_status_id,
       --pa_state.constant_description  AS pa_status_desc,
       '1'                            AS deliverable_type_id,
       --dev_type.constant_description  AS deliverable_type_desc,
       pav.description                AS pa_description,
       (SELECT rpt_util_project.get_pa_approval_status@db_link_name (pa.contract_id, pav.contract_version_id, fr.firm_id, pav.state_fk) FROM dual) AS pa_apprval_status, --yes, function, I am sorry
       CASE
          WHEN (appr_wkflw.approval_process_spec_type = 'RBAW' AND appr_wkflw.name IS NOT NULL) THEN 'Rules-based: ' || appr_wkflw.name
          ELSE appr_wkflw.name
       END                          AS pa_approval_workflow,
       pav.start_date               AS pa_start_dt,
       pav.end_date                 AS pa_end_dt,
       pav.curr_conv_effective_date AS curr_conv_eff_date,
       pmfw.user_fk                 AS pa_project_mgr_person_id,
       pa_cu.value                  AS pa_currency_id,    
       pa_cu.description            AS pa_currency,
       pav.total_estimated_costs    AS pa_ttl_estimated_costs,
       gtt.total_amt                AS pa_total_amt_req_todate,
       NVL(pav.total_estimated_costs, 0) - NVL (gtt.total_amt, 0) AS pa_remaining_budget,
       pa.num_qualified_payment_requests AS pa_paymt_requests,
       pa.cac_collection1_fk        AS cac_collection1_id,
       pa.cac_collection2_fk        AS cac_collection2_id,
       -- Milestone Invoice Data
       ppm.title                    AS pa_milestone_title,
       ppm.start_date               AS pa_estimated_start_dt,
       ppm.end_date                 AS pa_estimated_end_dt,
       ppm.comments                 AS pa_milestone_comments,
       CASE
          WHEN e.is_billable_event = 1 THEN 'Yes'
          WHEN e.is_billable_event = 0 THEN 'No'
          ELSE NULL
       END                          AS pa_milestone_billable,
       NVL(e.payment_amount,0)      AS pa_milestone_amt,
       NVL(last_pr_amt.payment_amount,0) AS pa_pr_amount,
       p.project_id                 AS po_id,
       pav.contract_version_id      AS pa_version_id,
       ppm.payment_milestone_id     AS milestone_version_id,
       cv.contract_version_number   AS pa_version_number,
       --resource
       NULL AS pa_est_labor_cost,
       --Standard Rate Table
       NULL AS rate_table_edition_id,
       NULL AS pa_std_rate_table_name,
       NULL AS pa_std_description,
       NULL AS pa_std_rate_table_type,
       cv.create_date,
       cv.effective_date
  FROM project@db_link_name AS OF SCN source_db_SCN                    p,
       project_agreement@db_link_name AS OF SCN source_db_SCN          pa,
       project_agreement_version@db_link_name AS OF SCN source_db_SCN  pav,
       project_agmt_version_state@db_link_name AS OF SCN source_db_SCN pagv,
       contract_version@db_link_name AS OF SCN source_db_SCN           cv,
       firm_role@db_link_name AS OF SCN source_db_SCN                  fr,
       firm_role@db_link_name AS OF SCN source_db_SCN                  frs,
       approval_process_spec@db_link_name AS OF SCN source_db_SCN      appr_wkflw,
       firm_worker@db_link_name AS OF SCN source_db_SCN                pmfw,
       currency_unit@db_link_name AS OF SCN source_db_SCN              pa_cu,
       project_payment_milestone@db_link_name AS OF SCN source_db_SCN  ppm,
       expenditure@db_link_name AS OF SCN source_db_SCN                e,
       (SELECT contract_id, SUM(amt) total_amt
            FROM (SELECT pa.contract_id, 
                         e.payment_amount AS amt
                    FROM project_agreement@db_link_name AS OF SCN source_db_SCN pa, 
                         milestone_invoice@db_link_name AS OF SCN source_db_SCN mi, 
                         expenditure@db_link_name AS OF SCN source_db_SCN e
                   WHERE pa.contract_id       = mi.project_agreement_fk
                     AND mi.expenditure_fk    = e.identifier
                     AND mi.state_code IN (6, 3, 2, 5, 8)
                   UNION ALL
                  SELECT project_agmt_fk AS contract_id, 
                         ae.estimated_buyer_amount AS amt
                    FROM assignment_expenditure@db_link_name AS OF SCN source_db_SCN ae
                   WHERE project_agmt_fk IS NOT NULL)
                   GROUP BY contract_id)  gtt,
        (SELECT contract_id, payment_amount
          FROM (SELECT pa.contract_id,
                       mi.identifier, 
                       e.payment_amount,
                       RANK () OVER (PARTITION BY pa.contract_id ORDER BY mi.identifier DESC, mi.rowid DESC) rk
                  FROM project_agreement@db_link_name AS OF SCN source_db_SCN pa,
                       milestone_invoice@db_link_name AS OF SCN source_db_SCN mi,
                       expenditure@db_link_name AS OF SCN source_db_SCN e
                 WHERE mi.project_agreement_fk = pa.contract_id
                   AND mi.expenditure_fk = e.identifier
                   AND state_code IN (2, 3, 5, 6, 8)
                   AND supplier_submission_date IS NOT NULL)
         WHERE rk = 1) last_pr_amt /*,
        (SELECT constant_value, constant_description
           FROM java_constant_lookup
          WHERE constant_type   = 'PAVersionState'
           AND UPPER(locale_fk) = 'EN_US') pa_state,
        (SELECT constant_value, constant_description
           FROM java_constant_lookup
          WHERE constant_type   = 'DELIVERABLE_TYPE'
           AND UPPER(locale_fk) = 'EN_US') dev_type */
  WHERE buyer_firm_fk            = fr.firm_id
    AND pa.supply_firm_fk          = frs.firm_id(+)
    AND p.project_id               = pa.project_fk
    AND pa.contract_id             = cv.contract_fk(+)
    AND cv.contract_version_id     = pav.contract_version_id(+)
    AND pav.approval_workflow_fk   = appr_wkflw.approval_process_spec_id(+)
    AND pav.contract_version_id    = ppm.project_agreement_version_fk(+)
    AND NVL(pav.end_date,SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
    AND ppm.expenditure_fk         = e.identifier
    AND p.project_manager_fk       = pmfw.firm_worker_id(+)
    AND pa.currency_unit_fk        = pa_cu.value(+)
    AND pav.state_fk               = pagv.value(+)
    AND pa.contract_id             = gtt.contract_id(+)
    --AND pagv.value                 = pa_state.constant_value(+)
    --AND 1                          = dev_type.constant_value(+)
    AND pa.contract_id             = last_pr_amt.contract_id(+)
UNION ALL
--section2
SELECT 
       fr.business_org_fk            AS buyer_org_id,
       frs.business_org_fk           AS supplier_org_id,
       p.title                       AS pa_project_title,
       p.internal_identifier         AS pa_project_identifier,
       pa.name                       AS pa_name,
       pa.contract_id                AS pa_contract_id,
       pagv.value                    AS pa_status_id,
       --pa_state.constant_description AS pa_status_desc,
       '2'                           AS deliverable_type_id,
       --dev_type.constant_description AS deliverable_type_desc,
       pav.description               AS pa_description,
       (SELECT rpt_util_project.get_pa_approval_status@db_link_name (pa.contract_id, pav.contract_version_id, fr.firm_id, pav.state_fk) FROM dual) AS pa_apprval_status,
       CASE
          WHEN (appr_wkflw.approval_process_spec_type = 'RBAW' AND appr_wkflw.name IS NOT NULL) THEN 'Rules-based: ' || appr_wkflw.name
          ELSE appr_wkflw.name
       END                          AS pa_approval_workflow,
       pav.start_date               AS pa_start_dt,
       pav.end_date                 AS pa_end_dt,
       pav.curr_conv_effective_date AS curr_conv_eff_date,
       pmfw.user_fk                 AS pa_project_mgr_person_id,
       pa_cu.value                  AS pa_currency_id,
       pa_cu.description            AS pa_currency,
       pav.total_estimated_costs    AS pa_ttl_estimated_costs,
       gtt.total_amt                AS pa_total_amt_req_todate,
       NVL(pav.total_estimated_costs,0) - NVL(gtt.total_amt,0)  AS pa_remaining_budget,
       pa.num_qualified_payment_requests AS pa_paymt_requests,
       pa.cac_collection1_fk        AS cac_collection1_id,
       pa.cac_collection2_fk        AS cac_collection2_id,
       NULL                         AS pa_milestone_title,    --NULLED
       NULL                         AS pa_estimated_start_dt, --NULLED
       NULL                         AS pa_estimated_end_dt,   --NULLED
       NULL                         AS pa_milestone_comments, --NULLED
       NULL                         AS pa_milestone_billable,
       NULL                         AS pa_milestone_amt,
       NVL(last_pr_amt.payment_amount,0) AS pa_pr_amount,
       p.project_id                 AS po_id,
       pav.contract_version_id      AS pa_version_id,
       NULL                         AS milestone_version_id,
       cv.contract_version_number   AS pa_version_number,
       --resource
       pav.estimated_labor_costs    AS pa_est_labor_cost,
       --Standard Rate Table
       NULL AS rate_table_edition_id,
       NULL AS pa_std_rate_table_name,
       NULL AS pa_std_description,
       NULL AS pa_std_rate_table_type,
       cv.create_date,
       cv.effective_date
  FROM project@db_link_name AS OF SCN source_db_SCN                    p,
       project_agreement@db_link_name AS OF SCN source_db_SCN          pa,
       project_agreement_version@db_link_name AS OF SCN source_db_SCN  pav,
       project_agmt_version_state@db_link_name AS OF SCN source_db_SCN pagv,
       contract_version@db_link_name AS OF SCN source_db_SCN           cv,
       firm_role@db_link_name AS OF SCN source_db_SCN                  fr,
       firm_role@db_link_name AS OF SCN source_db_SCN                  frs,       
       approval_process_spec@db_link_name AS OF SCN source_db_SCN      appr_wkflw,
       firm_worker@db_link_name AS OF SCN source_db_SCN                pmfw,
       currency_unit@db_link_name AS OF SCN source_db_SCN              pa_cu,
       (SELECT contract_id, SUM(amt) AS total_amt
            FROM (SELECT pa.contract_id, 
                         e.payment_amount AS amt
                    FROM project_agreement@db_link_name AS OF SCN source_db_SCN pa, 
                         milestone_invoice@db_link_name AS OF SCN source_db_SCN mi, 
                         expenditure@db_link_name AS OF SCN source_db_SCN e
                   WHERE pa.contract_id       = mi.project_agreement_fk
                     AND mi.expenditure_fk    = e.identifier
                     AND mi.state_code IN (6, 3, 2, 5, 8)
                   UNION ALL
                  SELECT project_agmt_fk AS contract_id, 
                         ae.estimated_buyer_amount AS amt
                    FROM assignment_expenditure@db_link_name AS OF SCN source_db_SCN ae
                   WHERE project_agmt_fk IS NOT NULL)
                   GROUP BY contract_id)  gtt,
        (SELECT contract_id, payment_amount
          FROM (SELECT pa.contract_id,
                       mi.identifier, 
                       e.payment_amount,
                       RANK () OVER (PARTITION BY pa.contract_id ORDER BY mi.identifier DESC, mi.rowid DESC) rk
                  FROM project_agreement@db_link_name AS OF SCN source_db_SCN pa,
                       milestone_invoice@db_link_name AS OF SCN source_db_SCN mi,
                       expenditure@db_link_name AS OF SCN source_db_SCN e
                 WHERE mi.project_agreement_fk = pa.contract_id
                   AND mi.expenditure_fk = e.identifier
                   AND state_code IN (2, 3, 5, 6, 8)
                   AND supplier_submission_date IS NOT NULL)
         WHERE rk = 1) last_pr_amt /*,
        (SELECT constant_value, constant_description
           FROM java_constant_lookup
          WHERE constant_type    = 'PAVersionState'
            AND UPPER(locale_fk) = 'EN_US') pa_state,
        (SELECT constant_value, constant_description
           FROM java_constant_lookup
          WHERE constant_type   = 'DELIVERABLE_TYPE'
           AND UPPER(locale_fk) = 'EN_US') dev_type  */  
 WHERE p.buyer_firm_fk            = fr.firm_id
   AND pa.supply_firm_fk          = frs.firm_id(+)
   AND p.project_id               = pa.project_fk
   AND pa.contract_id             = cv.contract_fk(+)
   AND cv.contract_version_id     = pav.contract_version_id(+)
   AND pav.approval_workflow_fk   = appr_wkflw.approval_process_spec_id(+)
   AND NVL(pav.end_date,SYSDATE) >=  ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   AND p.project_manager_fk       = pmfw.firm_worker_id(+)
   AND pa.currency_unit_fk        = pa_cu.value(+)
   AND pav.state_fk               = pagv.value(+)
   AND pa.contract_id             = gtt.contract_id(+) 
   AND pa.contract_id             = last_pr_amt.contract_id(+)
   --AND pagv.value                 = pa_state.constant_value(+)
   --AND 2                          = dev_type.constant_value(+)
UNION ALL
--Section3
SELECT 
       fr.business_org_fk            AS buyer_org_id,
       frs.business_org_fk           AS supplier_org_id,
       p.title                       AS pa_project_title,
       p.internal_identifier         AS pa_project_identifier,
       pa.name                       AS pa_name,
       pa.contract_id                AS pa_contract_id,
       pagv.value                    AS pa_status_id,
       --pa_state.constant_description AS pa_status_desc,
       '3'                           AS deliverable_type_id,
       --dev_type.constant_description AS deliverable_type_desc,
       pav.description               AS pa_description,
       (SELECT rpt_util_project.get_pa_approval_status@db_link_name (pa.contract_id, pav.contract_version_id, fr.firm_id, pav.state_fk) FROM dual) AS pa_apprval_status,
       CASE
          WHEN (appr_wkflw.approval_process_spec_type = 'RBAW' AND appr_wkflw.name IS NOT NULL) THEN 'Rules-based: ' || appr_wkflw.name
          ELSE appr_wkflw.name
       END AS pa_approval_workflow,
       pav.start_date               AS pa_start_dt,
       pav.end_date                 AS pa_end_dt,
       pav.curr_conv_effective_date AS curr_conv_eff_date,
       pmfw.user_fk                 AS pa_project_mgr_person_id,
       pa_cu.value                  AS pa_currency_id,
       pa_cu.description            AS pa_currency,
       pav.total_estimated_costs    AS pa_ttl_estimated_costs,
       gtt.total_amt                AS pa_total_amt_req_todate,
       NVL(pav.total_estimated_costs,0) - NVL(gtt.total_amt,0) AS pa_remaining_budget,
       pa.num_qualified_payment_requests                       AS pa_paymt_requests,
       pa.cac_collection1_fk        AS cac_collection1_id,
       pa.cac_collection2_fk        AS cac_collection2_id,
       --Milestone
       NULL                              AS pa_milestone_title,
       NULL                              AS pa_estimated_start_dt,
       NULL                              AS pa_estimated_end_dt,
       NULL                              AS pa_milestone_comments,
       NULL                              AS pa_milestone_billable,
       NULL                              AS pa_milestone_amt,
       NVL(last_pr_amt.payment_amount,0) AS pa_pr_amount,
       p.project_id                      AS po_id,
       pav.contract_version_id           AS pa_version_id,
       NULL                              AS milestone_version_id,
       cv.contract_version_number        AS pa_version_number,
       --resource
       NULL AS pa_est_labor_cost,
       --Standard Rate Table
       rte.rate_table_edition_id,
       rte.name        AS pa_std_rate_table_name,
       rte.description AS pa_std_description,
       'Standard'      AS pa_std_rate_table_type,
       cv.create_date,
       cv.effective_date
  FROM project@db_link_name AS OF SCN source_db_SCN                    p,
       project_agreement@db_link_name AS OF SCN source_db_SCN          pa,
       project_agreement_version@db_link_name AS OF SCN source_db_SCN  pav,
       project_agmt_version_state@db_link_name AS OF SCN source_db_SCN pagv,
       contract_version@db_link_name AS OF SCN source_db_SCN           cv,
       firm_role@db_link_name AS OF SCN source_db_SCN                  fr,
       firm_role@db_link_name AS OF SCN source_db_SCN                  frs,
       approval_process_spec@db_link_name AS OF SCN source_db_SCN      appr_wkflw,
       firm_worker@db_link_name AS OF SCN source_db_SCN                pmfw,
       currency_unit@db_link_name AS OF SCN source_db_SCN              pa_cu,
       rate_table_continuity@db_link_name AS OF SCN source_db_SCN      rtc,
       rate_table_edition@db_link_name AS OF SCN source_db_SCN         rte,
       (SELECT contract_id, SUM(amt) AS total_amt
            FROM (SELECT pa.contract_id, 
                         e.payment_amount AS amt
                    FROM project_agreement@db_link_name AS OF SCN source_db_SCN pa, 
                         milestone_invoice@db_link_name AS OF SCN source_db_SCN mi, 
                         expenditure@db_link_name AS OF SCN source_db_SCN e
                   WHERE pa.contract_id       = mi.project_agreement_fk
                     AND mi.expenditure_fk    = e.identifier
                     AND mi.state_code IN (6, 3, 2, 5, 8)
                   UNION ALL
                  SELECT project_agmt_fk AS contract_id, 
                         ae.estimated_buyer_amount AS amt
                    FROM assignment_expenditure@db_link_name AS OF SCN source_db_SCN ae
                   WHERE project_agmt_fk IS NOT NULL)
                   GROUP BY contract_id) gtt,
        (SELECT contract_id, payment_amount
          FROM (SELECT pa.contract_id,
                       mi.identifier, 
                       e.payment_amount,
                       RANK () OVER (PARTITION BY pa.contract_id ORDER BY mi.identifier DESC, mi.rowid DESC) rk
                  FROM project_agreement@db_link_name AS OF SCN source_db_SCN pa,
                       milestone_invoice@db_link_name AS OF SCN source_db_SCN mi,
                       expenditure@db_link_name AS OF SCN source_db_SCN e
                 WHERE mi.project_agreement_fk = pa.contract_id
                   AND mi.expenditure_fk = e.identifier
                   AND state_code IN (2, 3, 5, 6, 8)
                   AND supplier_submission_date IS NOT NULL)
         WHERE rk = 1) last_pr_amt /*,
        (SELECT constant_value, constant_description
           FROM java_constant_lookup
          WHERE constant_type    = 'PAVersionState'
            AND UPPER(locale_fk) = 'EN_US') pa_state,
        (SELECT constant_value, constant_description
           FROM java_constant_lookup
          WHERE constant_type   = 'DELIVERABLE_TYPE'
           AND UPPER(locale_fk) = 'EN_US') dev_type */
 WHERE p.buyer_firm_fk              = fr.firm_id
   AND pa.supply_firm_fk            = frs.firm_id(+)
   AND p.project_id                 = pa.project_fk
   AND pa.contract_id               = cv.contract_fk(+)
   AND cv.contract_version_id       = pav.contract_version_id(+)
   AND pav.approval_workflow_fk     = appr_wkflw.approval_process_spec_id(+)
   AND NVL(pav.end_date,SYSDATE) >=  ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   AND rtc.current_edition_fk       = rte.rate_table_edition_id
   AND rtc.rate_table_continuity_id = pav.rate_table_continuity_fk
   AND p.project_manager_fk         = pmfw.firm_worker_id(+)
   AND pa.currency_unit_fk          = pa_cu.value(+)
   AND pav.state_fk                 = pagv.value(+)
   AND pa.contract_id               = gtt.contract_id(+)
   AND pa.contract_id               = last_pr_amt.contract_id(+))
   --AND pagv.value                   = pa_state.constant_value(+)
   --AND 3                            = dev_type.constant_value(+)   
 l) lego )}';

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

