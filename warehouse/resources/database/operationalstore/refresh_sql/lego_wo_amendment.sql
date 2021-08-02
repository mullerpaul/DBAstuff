/*******************************************************************************
SCRIPT NAME         lego_wo_amendment.sql 
 
LEGO OBJECT NAME    LEGO_WO_AMENDMENT
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark     - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2 
01/27/2016 - pmuller                 - modifications for DB links, multiple sources, and remote SCN
03/09/2016 - pmuller                 - removed address, CAC, and localized columns
08/15/2016 - jpullifrone - IQN-34018 - removed parallel hint 
08/15/2016 - jpullifrone - IQN-34057 - add contact_info_id
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_wo_amendment.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_WO_AMENDMENT'; 

  v_clob1 CLOB :=
q'{SELECT 
       work_order_id,
       wo_version_id,
       assignment_continuity_id,
       amendment_in_process_num,
       contractor_person_id,
       hiring_mgr_person_id,
       buyer_org_id,
       supplier_org_id,
       assignment_edition_id,
       job_id,
       project_id,
       project_agreement_id,
       udf_collection_id,
       wov_udf_collection_id,
       contact_info_id,
       approval_status,
       wo_status,
       wo_status_id,
       wo_cv_create_date,
       effective_date,
       approval_date,
       approval_wkflw_name,
       NVL(start_date_prev, start_date_cur) AS start_date_prev,
       start_date_cur,
       CASE
          WHEN NVL(start_date_prev, start_date_cur) != NVL(start_date_cur, SYSDATE) THEN 'Y'
          ELSE 'N'
       END AS start_date_change,
       NVL(end_date_prev, end_date_cur) AS end_date_prev,
       end_date_cur,
       CASE
          WHEN NVL(end_date_prev, end_date_cur) != NVL(end_date_cur, SYSDATE) THEN 'Y'
          ELSE 'N'
       END AS end_date_change,
       CAST(NVL(est_labor_prev, est_labor_cur) AS NUMBER) AS est_labor_prev,
       CAST(est_labor_cur AS NUMBER) AS est_labor_cur,
       CASE
          WHEN NVL(est_labor_prev, est_labor_cur) != NVL(est_labor_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS est_labor_change,
       CAST(NVL(exp_prev, exp_cur) AS NUMBER) AS exp_prev,
       CAST(exp_cur AS NUMBER) as exp_cur,
       CASE
          WHEN NVL(exp_prev, exp_cur) != NVL(exp_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS exp_change,
       CAST(NVL(total_labor_prev, total_labor_cur) AS NUMBER) AS total_labor_prev,
       CAST(total_labor_cur AS NUMBER) AS total_labor_cur,
       CASE
          WHEN NVL(total_labor_prev, total_labor_cur) != NVL(total_labor_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS total_labor_change,
       CAST(NVL(reg_pay_rate_prev, reg_pay_rate_cur) AS NUMBER) AS reg_pay_rate_prev,
       CAST(reg_pay_rate_cur AS NUMBER) AS reg_pay_rate_cur,
       CASE
          WHEN NVL(reg_pay_rate_prev, reg_pay_rate_cur) != NVL(reg_pay_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS reg_pay_rate_change,
       CAST(NVL(ot_pay_rate_prev, ot_pay_rate_cur) AS NUMBER) AS ot_pay_rate_prev,
       CAST(ot_pay_rate_cur AS NUMBER) AS ot_pay_rate_cur,
       CASE
          WHEN NVL(ot_pay_rate_prev, ot_pay_rate_cur) != NVL(ot_pay_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS ot_pay_rate_change,
       CAST(NVL(dt_pay_rate_prev, dt_pay_rate_cur) AS NUMBER) AS dt_pay_rate_prev,
       CAST(dt_pay_rate_cur AS NUMBER) AS dt_pay_rate_cur,
       CASE
          WHEN NVL(dt_pay_rate_prev, dt_pay_rate_cur) != NVL(dt_pay_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS dt_pay_rate_change,
       CAST(NVL(reg_bill_rate_prev, reg_bill_rate_cur) AS NUMBER) AS reg_bill_rate_prev,
       CAST(reg_bill_rate_cur AS NUMBER) AS reg_bill_rate_cur,
       CASE
          WHEN NVL(reg_bill_rate_prev, reg_bill_rate_cur) != NVL(reg_bill_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS reg_bill_rate_change,
       CAST(NVL(ot_bill_rate_prev, ot_bill_rate_cur) AS NUMBER) AS ot_bill_rate_prev,
       CAST(ot_bill_rate_cur AS NUMBER) AS ot_bill_rate_cur,
       CASE
          WHEN NVL(ot_bill_rate_prev, ot_bill_rate_cur) != NVL(ot_bill_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS ot_bill_rate_change,
       CAST(NVL(dt_bill_rate_prev, dt_bill_rate_cur) AS NUMBER) AS dt_bill_rate_prev,
       CAST(dt_bill_rate_cur AS NUMBER) AS dt_bill_rate_cur,
       CASE
          WHEN NVL(dt_bill_rate_prev, dt_bill_rate_cur) != NVL(dt_bill_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS dt_bill_rate_change,
       CAST(NVL(reg_adj_bill_rate_prev, reg_adj_bill_rate_cur) AS NUMBER) AS reg_adj_bill_rate_prev,
       CAST(reg_adj_bill_rate_cur AS NUMBER) AS reg_adj_bill_rate_cur,
       CASE
          WHEN NVL(reg_adj_bill_rate_prev, reg_adj_bill_rate_cur) != NVL(reg_adj_bill_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS reg_adj_bill_rate_change,
       CAST(NVL(ot_adj_bill_rate_prev, ot_adj_bill_rate_cur) AS NUMBER) AS ot_adj_bill_rate_prev,
       CAST(ot_adj_bill_rate_cur AS NUMBER) AS ot_adj_bill_rate_cur,
       CASE
          WHEN NVL(ot_adj_bill_rate_prev, ot_adj_bill_rate_cur) != NVL(ot_adj_bill_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS ot_adj_bill_rate_change,
       CAST(NVL(dt_adj_bill_rate_prev, dt_adj_bill_rate_cur) AS NUMBER) AS dt_adj_bill_rate_prev,
       CAST(dt_adj_bill_rate_cur AS NUMBER) AS dt_adj_bill_rate_cur,
       CASE
          WHEN NVL(dt_adj_bill_rate_prev, dt_adj_bill_rate_cur) !=  NVL(dt_adj_bill_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS dt_adj_bill_rate_change,
       CAST(NVL(reg_reimb_rate_prev, reg_reimb_rate_cur) AS NUMBER) AS reg_reimb_rate_prev,
       CAST(reg_reimb_rate_cur AS NUMBER) AS reg_reimb_rate_cur,
       CASE
          WHEN NVL(reg_reimb_rate_prev, reg_reimb_rate_cur) != NVL(reg_reimb_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS reg_reimb_rate_change,
       CAST(NVL(ot_reimb_rate_prev, ot_reimb_rate_cur) AS NUMBER) AS ot_reimb_rate_prev,
       CAST(ot_reimb_rate_cur AS NUMBER) AS ot_reimb_rate_cur,
       CASE
          WHEN NVL(ot_reimb_rate_prev, ot_reimb_rate_cur) != NVL(ot_reimb_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS ot_reimb_rate_change,
       CAST(NVL(dt_reimb_rate_prev, dt_reimb_rate_cur) AS NUMBER) AS dt_reimb_rate_prev,
       CAST(dt_reimb_rate_cur AS NUMBER) AS dt_reimb_rate_cur,
       CASE
          WHEN NVL(dt_reimb_rate_prev, dt_reimb_rate_cur) != NVL(dt_reimb_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS dt_reimb_rate_change,
       CAST(NVL(reg_markup_prev, reg_markup_cur) AS NUMBER) AS reg_markup_prev,
       CAST(reg_markup_cur AS NUMBER) AS reg_markup_cur,
       CASE
          WHEN NVL(reg_markup_prev, reg_markup_cur) != NVL(reg_markup_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS reg_markup_change,
       CAST(NVL(ot_markup_prev, ot_markup_cur) AS NUMBER) AS ot_markup_prev,
       CAST(ot_markup_cur AS NUMBER) AS ot_markup_cur,
       CASE
          WHEN NVL(ot_markup_prev, ot_markup_cur) != NVL(ot_markup_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS ot_markup_change,
       CAST(NVL(dt_markup_prev, dt_markup_cur) AS NUMBER) AS dt_markup_prev,
       CAST(dt_markup_cur AS NUMBER) AS dt_markup_cur,
       CASE
          WHEN NVL(dt_markup_prev, dt_markup_cur) != NVL(dt_markup_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS dt_markup_change,
       CAST(NVL(custom_pay_rate_prev, custom_pay_rate_cur) AS NUMBER) AS custom_pay_rate_prev,
       CAST(custom_pay_rate_cur AS NUMBER) AS custom_pay_rate_cur,
       CASE
          WHEN NVL(custom_pay_rate_prev, custom_pay_rate_cur) != NVL(custom_pay_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS custom_pay_rate_change,
       CAST(NVL(custom_bill_rate_prev, custom_bill_rate_cur) AS NUMBER) AS custom_bill_rate_prev,
       CAST(custom_bill_rate_cur AS NUMBER) AS custom_bill_rate_cur,
       CASE
          WHEN NVL(custom_bill_rate_prev, custom_bill_rate_cur) != NVL(custom_bill_rate_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS custom_bill_rate_change,
       CAST(NVL(custom_markup_prev, custom_markup_cur) AS NUMBER) AS custom_markup_prev,
       CAST(custom_markup_cur AS NUMBER) AS custom_markup_cur,
       CASE
          WHEN NVL(custom_markup_prev, custom_markup_cur) != NVL(custom_markup_cur, -1) THEN 'Y'
          ELSE 'N'
       END AS custom_markup_change,
       public_notes,
       misc_conditions,
       current_phase_type_id,
       wo_amend_currency_id,
       wo_amend_currency}';

   v_clob2 CLOB := 
q'{ FROM (SELECT work_order_id,
               contract_version_id AS wo_version_id,
               assignment_continuity_id,
               amendment_in_process_num,
               contractor_person_id,
               hiring_mgr_person_id,
               buyer_org_id,
               supplier_org_id,
               assignment_edition_id,
               job_id,
               project_id,
               project_agreement_id,
               udf_collection_id,
               wov_udf_collection_id,
               contact_info_id,
               approval_status,
               wo_status,
               wo_status_id,
               wo_cv_create_date,
               effective_date,
               LAG(start_date_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS start_date_prev,
               start_date_cur,
               LAG(end_date_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS end_date_prev,
               end_date_cur,
               approval_date,
               approval_wkflw_name,
               LAG(est_labor_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS est_labor_prev,
               est_labor_cur,
               LAG(exp_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS exp_prev,
               exp_cur,
               LAG(total_labor_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS total_labor_prev,
               total_labor_cur,
               LAG(reg_pay_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS reg_pay_rate_prev,
               reg_pay_rate_cur,
               LAG(ot_pay_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS ot_pay_rate_prev,
               ot_pay_rate_cur,
               LAG(dt_pay_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS dt_pay_rate_prev,
               dt_pay_rate_cur,
               LAG(reg_bill_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS reg_bill_rate_prev,
               reg_bill_rate_cur,
               LAG(ot_bill_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS ot_bill_rate_prev,
               ot_bill_rate_cur,
               LAG(dt_bill_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS dt_bill_rate_prev,
               dt_bill_rate_cur,
               LAG(reg_adj_bill_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS reg_adj_bill_rate_prev,
               reg_adj_bill_rate_cur,
               LAG(ot_adj_bill_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS ot_adj_bill_rate_prev,
               ot_adj_bill_rate_cur,
               LAG(dt_adj_bill_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS dt_adj_bill_rate_prev,
               dt_adj_bill_rate_cur,
               LAG(reg_reimb_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS reg_reimb_rate_prev,
               reg_reimb_rate_cur,
               LAG(ot_reimb_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS ot_reimb_rate_prev,
               ot_reimb_rate_cur,
               LAG(dt_reimb_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS dt_reimb_rate_prev,
               dt_reimb_rate_cur,
               LAG(reg_markup_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS reg_markup_prev,
               reg_markup_cur,
               LAG(ot_markup_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS ot_markup_prev,
               ot_markup_cur,
               LAG(dt_markup_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS dt_markup_prev,
               dt_markup_cur,
               LAG(custom_pay_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS custom_pay_rate_prev,
               custom_pay_rate_cur,
               LAG(custom_bill_rate_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS custom_bill_rate_prev,
               custom_bill_rate_cur,
               LAG(custom_markup_cur,1,NULL) OVER (PARTITION BY work_order_id ORDER BY contract_version_id) AS custom_markup_prev,
               custom_markup_cur,
               public_notes,
               misc_conditions,
               current_phase_type_id,
               wo_amend_currency_id,
               wo_amend_currency
          FROM (SELECT acc.work_order_fk             AS work_order_id,
                       cv.contract_version_id,
                       acc.assignment_continuity_id,
                       cv.contract_version_name      AS amendment_in_process_num,
                       cand.person_fk                AS contractor_person_id,
                       hfw.user_fk                   AS hiring_mgr_person_id,
                       fr.business_org_fk            AS buyer_org_id,
                       frs.business_org_fk           AS supplier_org_id,
                       ae.assignment_edition_id,
                       acc.job_fk                    AS job_id,
                       acc.project_fk                AS project_id,
                       ae.project_agmt_fk            AS project_agreement_id,
                       ae.udf_collection_fk          AS udf_collection_id,
                       wov.udf_collection_fk         AS wov_udf_collection_id,
                       ae.resource_onsite_fk         AS contact_info_id,
                       DECODE(wov.approval_status,
                                 1, 'Needs Approval',
                                 2, 'Approving',
                                 3, 'Reapproving',
                                 4, 'Approval Rejected',
                                 5, 'Approved',
                                 6, 'Approval Not Required')      AS approval_status,
                       TRUNC(cv.create_date)                      AS wo_cv_create_date,
                       cv.effective_date                          AS effective_date,
                       pert.start_date                            AS start_date_cur,
                       pert.end_date                              AS end_date_cur,
                       TRUNC(ap.approval_date)                    AS approval_date,
                       appr_wkflw.name                            AS approval_wkflw_name,
                       wov.labor_amount                           AS est_labor_cur,
                       wov.additional_expenses                    AS exp_cur,
                       wov.total_amount                           AS total_labor_cur,
                       fet.pay_rate                               AS reg_pay_rate_cur,
                       fet.ot_pay_rate                            AS ot_pay_rate_cur,
                       fet.dt_pay_rate                            AS dt_pay_rate_cur,
                       fet.supplier_bill_rate                     AS reg_bill_rate_cur,
                       fet.supplier_ot_rate                       AS ot_bill_rate_cur,
                       fet.supplier_dt_rate                       AS dt_bill_rate_cur,
                       fet.buyer_bill_rate                        AS reg_adj_bill_rate_cur,
                       fet.buyer_ot_rate                          AS ot_adj_bill_rate_cur,
                       fet.buyer_dt_rate                          AS dt_adj_bill_rate_cur,
                       fet.supplier_reimbursement_rate            AS reg_reimb_rate_cur,
                       fet.supplier_ot_reimbursement_rate         AS ot_reimb_rate_cur,
                       fet.supplier_dt_reimbursement_rate         AS dt_reimb_rate_cur,
                       fet.mark_up                                AS reg_markup_cur,
                       fet.ot_mark_up                             AS ot_markup_cur,
                       fet.dt_mark_up                             AS dt_markup_cur,
                       c_rates.custom_pay_rate                    AS custom_pay_rate_cur,
                       c_rates.custom_bill_rate                   AS custom_bill_rate_cur,
                       c_rates.custom_markup                      AS custom_markup_cur,
                       CASE
                          WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                          WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                          WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                          WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                          WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                          WHEN ae.assignment_state_fk = 13 THEN
                             CASE
                                WHEN (acc.onboard_allowed = 1 AND acc.onboard_date IS NOT NULL) THEN 'Effective-OnBoard'
                                ELSE 'Effective'
                             END
                          WHEN ae.assignment_state_fk = 0 THEN
                             CASE
                                WHEN wov.work_order_version_state = 1  THEN 'Not Released'
                                WHEN wov.work_order_version_state = 2  THEN 'Position Offered'
                                WHEN wov.work_order_version_state = 4  THEN 'Offer Declined'
                                WHEN wov.work_order_version_state = 5  THEN 'Not Released'
                                WHEN wov.work_order_version_state = 6  THEN 'Reinstated'
                                WHEN wov.work_order_version_state = 7  THEN 'Canceled'
                                WHEN wov.work_order_version_state = 8  THEN 'Canceled'
                                WHEN wov.work_order_version_state = 3  THEN 'Awaiting Start Date'
                                WHEN wov.work_order_version_state = 10 THEN 'Completed'
                                WHEN wov.work_order_version_state = 11 THEN 'Terminated'
                                WHEN wov.work_order_version_state = 12 THEN 'Terminated'
                                WHEN wov.work_order_version_state = 14 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 15 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 16 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 17 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 18 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 19 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 20 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 21 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 22 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 23 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 'Awaiting Start Date'
                                      WHEN ae.assignment_state_fk = 13 THEN 'Effective'
                                      WHEN ae.assignment_state_fk = 10 THEN 'Completed'
                                      WHEN ae.assignment_state_fk = 12 THEN 'Terminated'
                                      WHEN ae.assignment_state_fk = 1  THEN 'Approval In Process'
                                      WHEN ae.assignment_state_fk = 7  THEN 'Canceled'
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 13 THEN
                                   CASE
                                      WHEN (acc.onboard_allowed = 1 AND acc.onboard_date IS NOT NULL) THEN 'Effective-OnBoard'
                                      ELSE 'Effective'
                                   END
                                WHEN wov.work_order_version_state = 22 THEN 'Amendment Canceled'
                                WHEN wov.work_order_version_state = 23 THEN 'Amendment Canceled'
                                WHEN wov.work_order_version_state = 24 THEN 'Amendment In Process'
                             END
                       END AS wo_status,
                       CASE 
                          WHEN ae.assignment_state_fk = 3  THEN 3
                          WHEN ae.assignment_state_fk = 10 THEN 10
                          WHEN ae.assignment_state_fk = 12 THEN 12
                          WHEN ae.assignment_state_fk = 7  THEN 7
                          WHEN ae.assignment_state_fk = 1  THEN 1
                          WHEN ae.assignment_state_fk = 13 THEN 13
                          WHEN ae.assignment_state_fk = 0  THEN
                             CASE
                                WHEN wov.work_order_version_state = 1  THEN 1
                                WHEN wov.work_order_version_state = 2  THEN 2
                                WHEN wov.work_order_version_state = 4  THEN 4
                                WHEN wov.work_order_version_state = 5  THEN 5
                                WHEN wov.work_order_version_state = 6  THEN 6
                                WHEN wov.work_order_version_state = 7  THEN 7
                                WHEN wov.work_order_version_state = 8  THEN 7
                                WHEN wov.work_order_version_state = 3  THEN 3
                                WHEN wov.work_order_version_state = 10 THEN 10
                                WHEN wov.work_order_version_state = 11 THEN 11
                                WHEN wov.work_order_version_state = 12 THEN 11
                                WHEN wov.work_order_version_state = 14 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 15 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 16 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 17 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 18 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 19 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 20 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 21 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 22 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 23 THEN
                                   CASE
                                      WHEN ae.assignment_state_fk = 3  THEN 3
                                      WHEN ae.assignment_state_fk = 13 THEN 13
                                      WHEN ae.assignment_state_fk = 10 THEN 10
                                      WHEN ae.assignment_state_fk = 12 THEN 12
                                      WHEN ae.assignment_state_fk = 1  THEN 1
                                      WHEN ae.assignment_state_fk = 7  THEN 7
                                      ELSE NULL
                                   END
                                WHEN wov.work_order_version_state = 13 THEN 13
                                WHEN wov.work_order_version_state = 22 THEN 20 --(Amendment Cancelled Pre Release) -> Amendment Canceled
                                WHEN wov.work_order_version_state = 23 THEN 21 --(Amendment Cancelled Post Release) -> Amendment Canceled
                                WHEN wov.work_order_version_state = 24 THEN 22 --(Supplier Initiated Amendment In Process) -> Amendment In Process
                             END
                       END AS wo_status_id,
                       won.note                            AS public_notes,
                       wat.misc_conditions,
                       acc.phase_type_id                   AS current_phase_type_id,
                       fet_cu.value                        AS wo_amend_currency_id,
                       fet_cu.description                  AS wo_amend_currency}';
					   
   v_clob3 CLOB :=
q'{ FROM contract@db_link_name AS OF SCN source_db_SCN                 c,
                      contract_version@db_link_name AS OF SCN source_db_SCN         cv,
                      work_order_version@db_link_name AS OF SCN source_db_SCN       wov,
                      work_order_version_state@db_link_name AS OF SCN source_db_SCN wovs,
                      assignment_continuity@db_link_name AS OF SCN source_db_SCN    acc,
                      firm_role@db_link_name AS OF SCN source_db_SCN                fr,
                      firm_role@db_link_name AS OF SCN source_db_SCN                frs,
                      assignment_edition@db_link_name AS OF SCN source_db_SCN       ae,
                      contract_term@db_link_name AS OF SCN source_db_SCN            fet_ct,
                      fee_expense_term@db_link_name AS OF SCN source_db_SCN         fet,
                      contract_term@db_link_name AS OF SCN source_db_SCN            pt_ct,
                      performance_term@db_link_name AS OF SCN source_db_SCN         pert,
                      currency_unit@db_link_name AS OF SCN source_db_SCN            fet_cu,
                      contract_term@db_link_name AS OF SCN source_db_SCN            wat_ct,
                      firm_worker@db_link_name AS OF SCN source_db_SCN              hfw,
                      approval_process_spec@db_link_name AS OF SCN source_db_SCN    appr_wkflw,
                      candidate@db_link_name AS OF SCN source_db_SCN                cand,
                      work_order_summary@db_link_name AS OF SCN source_db_SCN       wos,
                      work_assignment_term@db_link_name AS OF SCN source_db_SCN     wat,
                      work_order_note@db_link_name AS OF SCN source_db_SCN          won,
                      (SELECT approvable_id, completed_date AS approval_date
                         FROM approval_process@db_link_name AS OF SCN source_db_SCN
                        WHERE approvable_type IN ('WorkOrderVersion','WorkOrderAmendment')
                          AND active_process = 1
                          AND approval_process_id != 578660) ap,
                      (SELECT rate_identifier_rate_set_fk,
                              MAX(DECODE(rate_category_fk, 1, rate, 0)) AS custom_pay_rate,
                              MAX(DECODE(rate_category_fk, 2, rate, 0)) AS custom_markup,
                              MAX(DECODE(rate_category_fk, 3, rate, 0)) AS custom_bill_rate
                         FROM rate_category_rate@db_link_name AS OF SCN source_db_SCN
                        WHERE rate_category_fk IN (1,2,3)
                        GROUP BY rate_identifier_rate_set_fk) c_rates
                WHERE acc.work_order_fk IS NOT NULL
                  AND NVL(ae.actual_end_date, wos.curr_ver_end_date) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
                  AND acc.assignment_continuity_id    = ae.assignment_continuity_fk
                  AND acc.current_edition_fk          = ae.assignment_edition_id
                  AND acc.owning_buyer_firm_fk        = fr.firm_id
                  AND acc.owning_supply_firm_fk       = frs.firm_id
                  AND acc.work_order_fk               = c.contract_id
                  AND c.contract_id                   = cv.contract_fk
                  AND cv.contract_version_id          = ap.approvable_id(+)
                  AND cv.contract_version_id          = wov.contract_version_id
                  AND cv.contract_version_id          = fet_ct.contract_version_fk
                  AND fet_ct.type                     = 'FeeAndExpenseTerm'
                  AND fet_ct.contract_term_id         = fet.contract_term_id
                  AND fet.currency_unit_fk            = fet_cu.value(+)
                  AND fet.rate_identifier_rate_set_fk = c_rates.rate_identifier_rate_set_fk(+)
                  AND cv.contract_version_id          = wat_ct.contract_version_fk
                  AND wat_ct.type                     = 'WorkAssignmentTerm'
                  AND ae.hiring_mgr_fk                = hfw.firm_worker_id(+)
                  AND wov.approval_workflow_fk        = appr_wkflw.approval_process_spec_id(+)
                  AND acc.candidate_fk                = cand.candidate_id(+)
                  AND cv.contract_version_id          = pt_ct.contract_version_fk
                  AND pt_ct.type                      = 'PerformanceTerm'
                  AND pt_ct.contract_term_id          = pert.contract_term_id
                  AND acc.work_order_fk               = wos.work_order_fk(+)
                  AND wov.work_order_version_state    = wovs.value
                  AND wovs.value                      NOT IN (22,23)
                  AND cv.contract_version_id          = won.contract_version_fk(+)
                  AND wat_ct.contract_term_id         = wat.contract_term_id(+) )
)}';

BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob1||v_clob2||v_clob3);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  UPDATE lego_refresh
     SET refresh_sql = v_clob1||v_clob2||v_clob3
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

