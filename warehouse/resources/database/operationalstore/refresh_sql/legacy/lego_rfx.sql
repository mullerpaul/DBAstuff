/*******************************************************************************
SCRIPT NAME         lego_rfx.sql 
 
LEGO OBJECT NAME    LEGO_RFX
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
04/15/2014 - E.Clark - IQN-15394 - localization added for CURRENT_PHASE, RESP_BID_TYPE, RESP_BILLABLE_EVENT - Release 12.0.3
08/14/2014 - pmuller - IQN-19498 - refactored SQL to use WITH subqueries, combined several aggregates into one subquey, 
                                   added AS OF clause to all FO table references, and made ordering deterministic by 
                                   adding a column to the order by clause. - Release 12.2
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_rfx.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_RFX'; 

  v_clob CLOB :=
    q'{SELECT rownum AS lego_rfx_id,
       buyer_org_id,
       project_rfx_id,
       project_rfx_version_id,
       supplier_org_id,
       x_division,
       x_mgr_person_id,
       project_id,
       current_phase_id,
       current_phase,
       x_request_title,
       x_project_component_title,
       cac_collection1_id,
       cac_collection2_id,
       udf_collection_id,
       x_decision_by_date,
       x_estimated_start_date,
       x_estimated_end_date,
       x_estimated_req_budget,
       x_currency_id,
       x_currency,
       resp_currency_id,
       resp_currency,
       x_invoice_detail,
       x_payment_request_options,
       x_request_type,
       x_responses_due_date,
       x_response_evaluator,
       x_status,
       x_status_id,
       x_title,
       x_description,
       x_approval_workflow,
       x_assigned_cams,
       evaluation_dtl,
       eval_avg AS evaluation_rating_avg,
       pm_hlist,
       po_outline,
       response_id,
       rej_reason_codes,
       resp_bid_type_id,
       resp_bid_type,
       resp_billable_event_id,
       resp_billable_event,
       resp_billable_resource_cnt,
       resp_non_billable_resource_cnt,
       resp_deliverable_cost,
       resp_start_date,
       resp_end_date,
       resp_total_estimated_costs,
       resp_expense_costs,
       resp_labor_costs,
       resp_resource_comments,
       resp_resource_start_date,
       resp_resource_end_date,
       resp_resource_title,
       resp_submission_date,
       resp_supp_prj_mgr_person_id,
       resp_title,
       single_source_supplier,
       single_source_reason_cds,
       payment_milestone_id,
       resp_x_mi_estimated_start_date,
       resp_x_mi_estimated_end_date,
       resp_x_mi_title,
       resp_x_mi_amount,
       x_selected_suppliers
  FROM (  WITH xpc 
            AS (SELECT project_rfx_version_fk AS project_rfx_version_id, 
                       LISTAGG(title,'; ') WITHIN GROUP (ORDER BY title) AS x_project_component_title
                  FROM project_rfx_version_component AS OF SCN lego_refresh_mgr_pkg.get_scn()
                 WHERE title IS NOT NULL
                 GROUP BY project_rfx_version_fk),
               x_cams
            AS (SELECT project_rfx_version_id,
                       LISTAGG(cam_full_name, '; ') WITHIN GROUP (ORDER BY cam_full_name) AS cam_list
                  FROM (SELECT prv.project_rfx_version_fk AS project_rfx_version_id,
                               pcam.last_name || ', ' || pcam.first_name || 
                               CASE WHEN pcam.middle_name IS NOT NULL THEN ' ' || pcam.middle_name END AS cam_full_name
                          FROM project_rfx_version_cams_x AS OF SCN lego_refresh_mgr_pkg.get_scn() prv,
                               firm_worker                AS OF SCN lego_refresh_mgr_pkg.get_scn() fwcam,
                               person                     AS OF SCN lego_refresh_mgr_pkg.get_scn() pcam
                         WHERE prv.firm_worker_fk = fwcam.firm_worker_id
                           AND fwcam.never_null_person_fk = pcam.person_id)
                 GROUP BY project_rfx_version_id),
               eval_name
            AS (SELECT pr.project_fk AS project_id,
                       LISTAGG(p.last_name || ', ' || p.first_name,'; ') WITHIN GROUP (ORDER BY p.last_name,p.first_name) AS proj_eval_name
                  FROM project_rfx_bid_evaluators_x AS OF SCN lego_refresh_mgr_pkg.get_scn() pr, 
                       firm_worker AS OF SCN lego_refresh_mgr_pkg.get_scn() f, 
                       person AS OF SCN lego_refresh_mgr_pkg.get_scn() p
                 WHERE pr.firm_worker_fk = f.firm_worker_id
                   AND f.user_fk         = p.person_id
                 GROUP BY pr.project_fk),
               resp_comments  --had to separate this from the resp_res_info subquery into its own subquery due to some rows going over the 4k limit.
            AS (SELECT prdp.project_rfx_response_fk AS response_id,  
                       REPLACE(LISTAGG(NVL(prd.comments,'~^'),'; ') WITHIN GROUP (ORDER BY prd.project_resource_desc_id),'~^') AS comments
                  FROM project_resource_description AS OF SCN lego_refresh_mgr_pkg.get_scn() prd,
                       project_res_desc_phase AS OF SCN lego_refresh_mgr_pkg.get_scn() prdp,
                       (SELECT prdp.project_rfx_response_fk
                          FROM project_resource_description AS OF SCN lego_refresh_mgr_pkg.get_scn() prd,
                               project_res_desc_phase AS OF SCN lego_refresh_mgr_pkg.get_scn() prdp
                         WHERE prdp.phase_id = prd.phase_fk
                           AND prdp.project_rfx_response_fk IS NOT NULL
                         GROUP BY prdp.project_rfx_response_fk
                        HAVING SUM(LENGTH(NVL(prd.comments,'~^')) + 2) - 2 < 4000) listagg_limit
                 WHERE prdp.phase_id = prd.phase_fk
                   AND prdp.project_rfx_response_fk IS NOT NULL
                   AND prdp.project_rfx_response_fk = listagg_limit.project_rfx_response_fk
                 GROUP BY prdp.project_rfx_response_fk),
               resp_res_info
            AS (SELECT prdp.project_rfx_response_fk AS response_id, 
                       REPLACE(LISTAGG(NVL(TO_CHAR(prd.estimated_start_date, 'mm/dd/yyyy'),'~^'),'; ') 
                          WITHIN GROUP (ORDER BY prd.project_resource_desc_id),'~^') AS start_date,
                       REPLACE(LISTAGG(NVL(TO_CHAR(prd.estimated_end_date, 'mm/dd/yyyy'),'~^'),'; ') 
                          WITHIN GROUP (ORDER BY prd.project_resource_desc_id),'~^') AS end_date,   -- can contain extra semicolons where all data is null
                       REPLACE(LISTAGG(NVL(prd.title,'~^'),'; ') WITHIN GROUP (ORDER BY prd.project_resource_desc_id),'~^') AS title,
                       SUM(CASE WHEN prd.is_billable = 1  THEN prd.number_of_resources ELSE 0 END) AS bill_cnt,
                       SUM(CASE WHEN prd.is_billable <> 1 THEN prd.number_of_resources ELSE 0 END) AS non_bill_cnt
                  FROM project_resource_description AS OF SCN lego_refresh_mgr_pkg.get_scn() prd,
                       project_res_desc_phase       AS OF SCN lego_refresh_mgr_pkg.get_scn() prdp
                 WHERE prdp.phase_id = prd.phase_fk
                   AND prdp.project_rfx_response_fk IS NOT NULL
                 GROUP BY prdp.project_rfx_response_fk),
               resp_del_cost
            AS (SELECT ppm.project_rfx_response_fk AS response_id, 
                       SUM(e.payment_amount)       AS resp_del_cost
                  FROM project_payment_milestone AS OF SCN lego_refresh_mgr_pkg.get_scn() ppm, 
                       expenditure AS OF SCN lego_refresh_mgr_pkg.get_scn() e
                 WHERE ppm.expenditure_fk = e.identifier
                 GROUP BY ppm.project_rfx_response_fk),
               eval
            AS (SELECT project_rfx_response_fk AS response_id,
                       RTRIM(LISTAGG(evaluation_details,'; ') WITHIN GROUP (ORDER BY evaluation_details),',') AS evaluation_dtl
                  FROM (SELECT prv.project_rfx_response_fk,  
                               TO_CHAR(last_modified_date,'MM/DD/YYYY HH24:MI') ||','  ||  --eval_date,
                               pcam.last_name || ', ' || pcam.first_name || 
                               CASE WHEN pcam.middle_name IS NOT NULL THEN ' ' || pcam.middle_name END ||  --eval_person,
                               ','  || TO_CHAR(evaluation) ||', ' ||  --eval_score,
                               REPLACE(prv.comments,',') AS evaluation_details                                      
                          FROM project_rfx_response_eval AS OF SCN lego_refresh_mgr_pkg.get_scn() prv,
                               firm_worker AS OF SCN lego_refresh_mgr_pkg.get_scn() fwcam,
                               person AS OF SCN lego_refresh_mgr_pkg.get_scn() pcam
                         WHERE prv.evaluator_fk           = fwcam.firm_worker_id
                           AND fwcam.never_null_person_fk = pcam.person_id)
                 GROUP BY project_rfx_response_fk),
               eval_rating
            AS (SELECT project_rfx_response_fk AS response_id, 
                       AVG(evaluation)         AS eval_avg
                  FROM project_rfx_response_eval AS OF SCN lego_refresh_mgr_pkg.get_scn()
                 GROUP BY project_rfx_response_fk),
               selected_suppliers
            AS (SELECT project_rfx_id,
                       LISTAGG(name,'; ') WITHIN GROUP (ORDER BY name) AS selected_suppliers
                  FROM (SELECT DISTINCT 
                               pro.project_rfx_fk AS project_rfx_id, 
                               bo.name
                          FROM project_rfx_opportunity AS OF SCN lego_refresh_mgr_pkg.get_scn() pro,
                               business_organization AS OF SCN lego_refresh_mgr_pkg.get_scn() bo,
                               firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn() fr
                         WHERE pro.supply_firm_fk = fr.firm_id
                           AND fr.business_org_fk = bo.business_organization_id)
                 GROUP BY project_rfx_id),
               supp_cnt  --can this be added to the above "selected suppliers" block?
            AS (SELECT project_rfx_fk AS project_rfx_id,
                       CASE WHEN count(*) = 1 THEN 'Single Supplier'
                            WHEN count(*) > 1 THEN 'Multiple Suppliers'
                            ELSE NULL
                       END AS single_source_supplier
                  FROM project_rfx_opportunity AS OF SCN lego_refresh_mgr_pkg.get_scn()
                 WHERE state_fk <> 4
                 GROUP BY project_rfx_fk),
               cp_jcl 
            AS (SELECT constant_value, constant_description
                  FROM lego_java_constant_lookup
                 WHERE constant_type    = 'PROJECT_RFX_PHASE'
                   AND UPPER(locale_fk) = 'EN_US')                 
        SELECT xver.project_rfx_version_id,
               bfr.business_org_fk          AS buyer_org_id,
               xfr.business_org_fk          AS supplier_org_id,
               xver.org_sub_classification  AS x_division,
               xmph.person_id               AS x_mgr_person_id,
               p.project_id,
               prfx.current_phase           AS current_phase_id,
               cp_jcl.constant_description  AS current_phase,
               xver.project_rfx_fk          AS project_rfx_id,
               xprr.response_id             AS response_id,
               xver.title                   AS x_request_title,
               xpc.x_project_component_title,
               xver.cac_collection1_fk      AS cac_collection1_id,
               xver.cac_collection2_fk      AS cac_collection2_id,
               xver.udf_collection_fk       AS udf_collection_id,
               xver.decision_by_date        AS x_decision_by_date,
               xver.estimated_start_date    AS x_estimated_start_date,
               xver.estimated_end_date      AS x_estimated_end_date,
               xver.estimated_budget        AS x_estimated_req_budget,
               xcu.value                    AS x_currency_id,
               xcu.description              AS x_currency,
               NVL(resp_cu.value,xcu.value) AS resp_currency_id,
               NVL(resp_cu.description,xcu.description) AS resp_currency,
               xidvac.value                 AS x_invoice_detail,
               RTRIM(CASE
                       WHEN xver.milestone_fixed_fee_based = 1
                         THEN 'Pre-planned milestones (fixed fee and/or unit based); '
                     END || 
                     CASE
                       WHEN xver.time_expense_based = 1 
                         THEN 'Time/expense based; '
                     END || 
                     CASE
                       WHEN xver.unplanned_ms_fixed_fee_based = 1
                         THEN 'Unplanned milestones (fixed fee and/or unit based); '
                     END || 
                     CASE
                       WHEN xver.rate_table_based = 1
                         THEN 'Rate Table Based Deliverables'
                     END,'; ')              AS x_payment_request_options,
               CASE
                  WHEN xver.rfx_type = 1 THEN 'RFI'
                  WHEN xver.rfx_type = 2 THEN 'RFP'
                  WHEN xver.rfx_type = 3 THEN 'RFQ'
                  ELSE NULL
               END                          AS x_request_type,
               xver.response_due_date       AS x_responses_due_date,
               eval_name.proj_eval_name     AS x_response_evaluator,                                                              
               CASE
                  WHEN xvers.value = 1 THEN 'Under Development'
                  WHEN xvers.value = 2 THEN 'Active'
                  WHEN xvers.value = 3 THEN 'Canceled'
                  WHEN xvers.value = 4 THEN 'Completed'
                  WHEN xvers.value = 5 THEN 'Archived'
                  ELSE NULL
               END                          AS x_status,
               xvers.value                  AS x_status_id,
               xver.title                   AS x_title,
               xver.description             AS x_description,
               aps.name                     AS x_approval_workflow,
               x_cams.cam_list              AS x_assigned_cams,
               eval.evaluation_dtl,
               eval_rating.eval_avg,
               IQN_HIERARCHY.get_list(pmfw.user_fk, '-', 'Person')               AS pm_hlist,
               CASE WHEN p.is_stub = 0 THEN 'Y' WHEN p.is_stub = 1 THEN 'N' END  AS po_outline,
               RPT_UTIL_RFX.get_rfx_reas_rejected(prfx.project_rfx_id)           AS rej_reason_codes,
               DECODE(xprr.full_response,1,1,0,0,NULL)                           AS resp_bid_type_id,
               CASE
                  WHEN xprr.full_response = 1 THEN 'Full'
                  WHEN xprr.full_response = 0 THEN 'Partial'
                  ELSE NULL
               END                                      AS resp_bid_type,
               DECODE(e.is_billable_event,1,1,0,2,NULL) AS resp_billable_event_id,
               CASE
                  WHEN e.is_billable_event = 1 THEN 'Yes'
                  WHEN e.is_billable_event = 0 THEN 'No'
                  ELSE NULL
               END                            AS resp_billable_event,
               resp_res_info.bill_cnt         AS resp_billable_resource_cnt,
               resp_res_info.non_bill_cnt     AS resp_non_billable_resource_cnt,
               resp_del_cost.resp_del_cost    AS resp_deliverable_cost,
               xprr.start_date                AS resp_start_date,
               xprr.end_date                  AS resp_end_date,
               xprr.estimated_total_costs     AS resp_total_estimated_costs,
               xprr.estimated_expense_costs   AS resp_expense_costs,
               xprr.estimated_labor_costs     AS resp_labor_costs,
               resp_comments.comments         AS resp_resource_comments,
               resp_res_info.start_date       AS resp_resource_start_date,
               resp_res_info.end_date         AS resp_resource_end_date,
               resp_res_info.title            AS resp_resource_title, 
               TRUNC(xprr.submission_date)    AS resp_submission_date,
               man.never_null_person_fk       AS resp_supp_prj_mgr_person_id,
               xprr.title                     AS resp_title,
               supp_cnt.single_source_supplier,     
               RPT_UTIL_RFX.get_rfx_single_src_reason(xver.project_rfx_version_id)  AS single_source_reason_cds,
               ppm.payment_milestone_id,
               ppm.start_date                        AS resp_x_mi_estimated_start_date,
               ppm.end_date                          AS resp_x_mi_estimated_end_date,
               ppm.title                             AS resp_x_mi_title,
               e.payment_amount                      AS resp_x_mi_amount,
               selected_suppliers.selected_suppliers AS x_selected_suppliers
          FROM expenditure          AS OF SCN lego_refresh_mgr_pkg.get_scn()       e,
               project_payment_milestone AS OF SCN lego_refresh_mgr_pkg.get_scn()  ppm,
               invoice_detail_value AS OF SCN lego_refresh_mgr_pkg.get_scn()       idvac,
               project_rfx_response AS OF SCN lego_refresh_mgr_pkg.get_scn()       xprr,
               invoice_detail_value AS OF SCN lego_refresh_mgr_pkg.get_scn()       xidvac,
               firm_worker          AS OF SCN lego_refresh_mgr_pkg.get_scn()       xmfw,
               firm_worker          AS OF SCN lego_refresh_mgr_pkg.get_scn()       man,
               firm_worker          AS OF SCN lego_refresh_mgr_pkg.get_scn()       pmfw,          
               person               AS OF SCN lego_refresh_mgr_pkg.get_scn()       xmph,
               project_rfx_opportunity   AS OF SCN lego_refresh_mgr_pkg.get_scn()  xpro,
               firm_role            AS OF SCN lego_refresh_mgr_pkg.get_scn()       xfr,
               firm_role            AS OF SCN lego_refresh_mgr_pkg.get_scn()       bfr,
               approval_process_spec     AS OF SCN lego_refresh_mgr_pkg.get_scn()  aps,
               project_rfx_version_state AS OF SCN lego_refresh_mgr_pkg.get_scn()  xvers,
               project_rfx_version       AS OF SCN lego_refresh_mgr_pkg.get_scn()  xver,
               project_rfx          AS OF SCN lego_refresh_mgr_pkg.get_scn()       prfx,
               project              AS OF SCN lego_refresh_mgr_pkg.get_scn()       p,
               currency_unit        AS OF SCN lego_refresh_mgr_pkg.get_scn()       resp_cu,
               currency_unit        AS OF SCN lego_refresh_mgr_pkg.get_scn()       xcu,
               xpc,
               x_cams,
               eval_name,
               resp_comments,
               resp_res_info,
               resp_del_cost,
               eval,
               eval_rating,
               selected_suppliers,
               supp_cnt,
               cp_jcl
         WHERE ppm.expenditure_fk               = e.identifier(+)
           AND xprr.response_id                 = ppm.project_rfx_response_fk(+)
           AND xprr.currency_unit_fk            = resp_cu.value(+)
           AND p.buyer_firm_fk                  = bfr.firm_id
           AND p.accounting_code_fk             = idvac.identifier(+)
           AND p.project_id                     = prfx.project_fk
           AND p.project_manager_fk             = pmfw.firm_worker_id(+)
           AND prfx.project_rfx_id              = xver.project_rfx_fk(+)
           AND xprr.supplier_project_manager_fk = man.firm_worker_id(+)
           AND xver.project_rfx_version_id      = (SELECT MAX(xver2.project_rfx_version_id)
                                                     FROM project_rfx_version xver2
                                                    WHERE xver2.project_rfx_fk = xver.project_rfx_fk)
           AND xver.currency_unit_fk            = xcu.value(+)
           AND xver.accounting_code_fk          = xidvac.identifier(+)
           AND xver.project_rfx_version_id      = xpc.project_rfx_version_id(+)
           AND xver.rfx_manager_fk              = xmfw.firm_worker_id(+)
           AND xmfw.user_fk                     = xmph.person_id(+)
           AND xver.state_fk                    = xvers.value(+)
           AND prfx.project_rfx_id              = xpro.project_rfx_fk(+)
           AND xpro.supply_firm_fk              = xfr.firm_id(+)
           AND xpro.opportunity_id              = xprr.opportunity_fk(+)
           AND xver.approval_workflow_fk        = aps.approval_process_spec_id(+)
           AND xprr.response_id                 = eval.response_id(+)
           AND xprr.response_id                 = eval_rating.response_id(+)
           AND xprr.response_id                 = resp_comments.response_id(+)
           AND xprr.response_id                 = resp_res_info.response_id(+)
           AND xprr.response_id                 = resp_del_cost.response_id(+)
           AND prfx.project_rfx_id              = selected_suppliers.project_rfx_id(+)
           AND prfx.project_rfx_id              = supp_cnt.project_rfx_id(+)
           AND xver.project_rfx_version_id      = x_cams.project_rfx_version_id(+)
           AND p.project_id                     = eval_name.project_id(+)
           AND prfx.current_phase               = cp_jcl.constant_value(+)
           AND (p.is_archived = 0
                  OR 
                  (p.is_archived = 1
                   AND NVL(p.last_modified_date,SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE), - months_in_refresh)))
         ORDER BY bfr.business_org_fk, project_rfx_id, supplier_org_id, response_id, x_mgr_person_id, payment_milestone_id)}';

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

