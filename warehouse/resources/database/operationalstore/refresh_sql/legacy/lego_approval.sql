/*******************************************************************************
SCRIPT NAME         lego_approval.sql 
 
LEGO OBJECT NAME    LEGO_APPROVAL
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     McKay Dunlap

***************************MODIFICATION HISTORY ********************************
08/15/2016 - jpullifrone - IQN-34018 -removed parallel hint                                   
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_approval.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_APPROVAL'; 

  v_clob CLOB :=            
q'{ MERGE INTO LEGO_APPROVAL apprm
            USING 
 (WITH appr as
            (select /* MATERIALIZE */ 
                ap.approval_process_id, ap.approvable_id, ap.approvable_type, 
                ap.started_date, ap.completed_date 
             from approval_process ap, 
                  (select approval_process_fk from approval_activity
                    where NVL(completed_date, started_date) >= NVL( (select MAX(TRUNC(refresh_start_time)) from lego_refresh_history
                                                                 where object_name in ( 'LEGO_APPROVALS', 'LEGO_APPROVAL_REFRESH', 'LEGO_APPROVAL_INIT', 'LEGO_APPROVAL' )
                                                                   and status in ('released','refresh complete')), trunc(sysdate))
                                                                   group by approval_process_fk ) aa 
             where ap.approval_process_id = aa.approval_process_fk ) ,
              apprv AS (}';
              
    v_clob1 CLOB:= v_clob || q'{          
            SELECT /*+ MATERIALIZE*/  * FROM (
            select  
            bo.business_organization_id AS buyer_org_id,
            ap.approvable_id,
            ap.approvable_type, 
            ap.approval_process_id,
            CASE WHEN ap.state_code = 1 THEN 'Waiting To Start'
               WHEN ap.state_code = 2 THEN 'Approval Pending'
               WHEN ap.state_code = 3 THEN 'Approved'
               WHEN ap.state_code = 4 THEN 'Rejected'
               WHEN ap.state_code = 5 THEN 'Retracted'
               END AS approval_status,
            (TRUNC (NVL (ap.completed_date, SYSDATE) - ap.started_date) || ':'
            || TRUNC (MOD ((NVL (ap.completed_date, SYSDATE) - ap.started_date) * 24,24)) || ':'
            || TRUNC (MOD ((NVL (ap.completed_date, SYSDATE) - ap.started_date) * 24 * 60, 60))) AS time_in_approval_process,   
            aps.name AS approval_workflow,
            pr.last_name||', '|| pr.first_name || ' '|| pr.middle_name AS approver_requestor,    
            TRUNC (ap.started_date) AS date_submitted_for_app,
            TRUNC (ap.completed_date) AS date_approved_date,   
            ap.started_date AS date_sub_for_app_t_stamp,
            ap.completed_date AS date_approved_t_stamp, 
            bo.name AS bo_name,
            le.actual_final_approver final_approver,
            le.last_event,
            le.completed_date as last_event_date,
            (TRUNC (SYSDATE - le.completed_date_calc)|| ':'
            || TRUNC (MOD ( (SYSDATE - le.completed_date_calc) * 24, 24)) || ':'
            || TRUNC (MOD ( (SYSDATE - le.completed_date_calc) * 24 * 60, 60))) as time_last_approver,
            ca.current_approver,
            ca.current_approver_email,
            ps_data.total_amount, 
            ps_data.currency_unit, 
            ps_data.approval_buyer_org_id,
            ps_data.approval_buyer_name,
            ps_data.approval_supplier_org_id, 
            ps_data.approval_supp_name,
            ps_data.id, 
            ps_data.hiring_mgr_person_id, 
            ps_data.hiring_proj_manager,
            ps_data.name_type,
            ps_data.contractor_full_name,
            ps_data.Ranking,
            act_pla_pvt.first_actual_approver_id,
            act_pla_pvt.second_actual_approver_id,
            act_pla_pvt.third_actual_approver_id,
            act_pla_pvt.fourth_actual_approver_id,
            act_pla_pvt.fifth_actual_approver_id,
            act_pla_pvt.sixth_actual_approver_id,
            act_pla_pvt.seventh_actual_approver_id,
            act_pla_pvt.eighth_actual_approver_id,
            act_pla_pvt.first_actual_approver,
            act_pla_pvt.second_actual_approver,
            act_pla_pvt.third_actual_approver,
            act_pla_pvt.fourth_actual_approver,
            act_pla_pvt.fifth_actual_approver,
            act_pla_pvt.sixth_actual_approver,
            act_pla_pvt.seventh_actual_approver,
            act_pla_pvt.eighth_actual_approver,
            act_pla_pvt.first_actual_primary_email,
            act_pla_pvt.second_actual_primary_email,
            act_pla_pvt.third_actual_primary_email,
            act_pla_pvt.fourth_actual_primary_email,
            act_pla_pvt.fifth_actual_primary_email,
            act_pla_pvt.sixth_actual_primary_email,
            act_pla_pvt.seventh_actual_primary_email,
            act_pla_pvt.eighth_actual_primary_email,
            act_pla_pvt.first_planned_approver_id,
            act_pla_pvt.second_planned_approver_id,
            act_pla_pvt.third_planned_approver_id,
            act_pla_pvt.fourth_planned_approver_id,
            act_pla_pvt.fifth_planned_approver_id,
            act_pla_pvt.sixth_planned_approver_id,
            act_pla_pvt.seventh_planned_approver_id,
            act_pla_pvt.eighth_planned_approver_id,
            act_pla_pvt.first_planned_approver,
            act_pla_pvt.second_planned_approver,
            act_pla_pvt.third_planned_approver,
            act_pla_pvt.fourth_planned_approver,
            act_pla_pvt.fifth_planned_approver,
            act_pla_pvt.sixth_planned_approver,
            act_pla_pvt.seventh_planned_approver,
            act_pla_pvt.eighth_planned_approver,
            act_pla_pvt.first_planned_primary_email,
            act_pla_pvt.second_planned_primary_email,
            act_pla_pvt.third_planned_primary_email,
            act_pla_pvt.fourth_planned_primary_email,
            act_pla_pvt.fifth_planned_primary_email,
            act_pla_pvt.sixth_planned_primary_email,
            act_pla_pvt.seventh_planned_primary_email,
            act_pla_pvt.eighth_planned_primary_email
            FROM }';
     v_clob2 CLOB := v_clob1 || q'{       
            approval_process_spec aps,
            approval_process ap,
            business_organization bo,
            --> LAST_EVENT ============================================================
            (SELECT aa.approval_process_fk, app.state_code, aa.completed_date, 
                    CASE WHEN app.state_code not in (3,4) and aa.state_code = 3 
                         THEN aa.completed_date else NULL END as completed_date_calc,
                    CASE WHEN aa.state_code = 3 THEN ple.last_name || ', ' || ple.first_name  
                         ELSE NULL end as actual_final_approver, 
                    REPLACE(REPLACE(apst.Type, 'ApproverGroup'), 'State') as Last_event
            FROM approval_activity aa, approval_process app, approval_process_state apst,
                 firm_worker fwle, person ple, 
             (SELECT MAX (a.approval_activity_id) approval_activity_id, a.approval_process_fk
              FROM approval_activity a
              WHERE a.completed_date IS NOT NULL
                AND a.activity_type = 'ApproverTask'
              GROUP BY a.approval_process_fk  ) am
            WHERE --aa.approval_process_fk = p_id
            --aa.activity_type = 'ApproverTask'
              aa.approval_activity_id = am.approval_activity_id
             AND aa.approval_process_fk = app.approval_process_id
             AND aa.actual_approver_fk = fwle.firm_worker_id(+)
             AND fwle.never_null_person_fk = ple.person_id(+)
             AND app.state_code = apst.value(+)
             AND aa.completed_date IS NOT NULL) le,
            --> Approval Requestor ====================================================
            firm_worker fwr, person pr,
            --> Current Approver, Current Email.=======================================
            (select 
            rap.approval_process_id,
            (CASE WHEN dap.current_approver_email is null 
                 THEN rap.current_approver_email 
                 ELSE dap.current_approver_email END)  as current_approver_email, 
            (CASE WHEN dap.current_approver is null 
                 THEN rap.current_approver 
                 ELSE dap.current_approver END) as current_approver 
            from 
            (SELECT approval_process_id, current_approver_email, current_approver from (
            (SELECT ap.approval_process_id, p.primary_email current_approver_email, p.last_name || ', ' || p.first_name current_approver,
                    RANK() OVER (PARTITION BY ap.approval_process_id ORDER BY dra.delegation_rule_fk) AS dr
             FROM firm_worker fw,
                  person p,
                  approver_task at,
                  delegation_rule dr,
                  deleg_rule_approvable_type_x dra,
                  approval_process ap
             WHERE ap.approvable_type_fk = dra.approvable_type_fk
               AND dra.delegation_rule_fk = dr.identifier
               AND at.approver_fk = dr.approver_fk
               AND dr.is_active = 1
               AND at.approval_process_fk = ap.approval_process_id
               AND dr.delegate_fk = fw.firm_worker_id
               AND fw.never_null_person_fk = p.person_id
               AND at.state_code = 2) )
             WHERE dr = 1 --> for WELLS FARGO PROD, MULTIPLE DELGATIONS
               )  dap,
            ( SELECT  apt.approval_process_fk as approval_process_id , 
                     LISTAGG(p.primary_email, '; ') WITHIN GROUP (ORDER BY p.primary_email) as current_approver_email, 
                     LISTAGG(p.last_name || ', ' || p.first_name, '; ') WITHIN GROUP (ORDER BY p.last_name || ', ' || p.first_name) as current_approver
             FROM firm_worker fw, person p, approver_task apt
             WHERE apt.approver_fk = fw.firm_worker_id
               AND fw.never_null_person_fk = p.person_id
               AND apt.state_code = 2
            GROUP BY apt.approval_process_fk) rap
            WHERE rap.approval_process_id = dap.approval_process_id (+)
            ) ca, 
            (SELECT
            app.approval_process_id, 
            act.first_actual_approver_id,
            act.second_actual_approver_id,
            act.third_actual_approver_id,
            act.fourth_actual_approver_id,
            act.fifth_actual_approver_id,
            act.sixth_actual_approver_id,
            act.seventh_actual_approver_id,
            act.eighth_actual_approver_id,
            act.first_actual_approver,
            act.second_actual_approver,
            act.third_actual_approver,
            act.fourth_actual_approver,
            act.fifth_actual_approver,
            act.sixth_actual_approver,
            act.seventh_actual_approver,
            act.eighth_actual_approver,
            act.first_actual_primary_email,
            act.second_actual_primary_email,
            act.third_actual_primary_email,
            act.fourth_actual_primary_email,
            act.fifth_actual_primary_email,
            act.sixth_actual_primary_email,
            act.seventh_actual_primary_email,
            act.eighth_actual_primary_email,
            pla.first_planned_approver_id,
            pla.second_planned_approver_id,
            pla.third_planned_approver_id,
            pla.fourth_planned_approver_id,
            pla.fifth_planned_approver_id,
            pla.sixth_planned_approver_id,
            pla.seventh_planned_approver_id,
            pla.eighth_planned_approver_id,
            pla.first_planned_approver,
            pla.second_planned_approver,
            pla.third_planned_approver,
            pla.fourth_planned_approver,
            pla.fifth_planned_approver,
            pla.sixth_planned_approver,
            pla.seventh_planned_approver,
            pla.eighth_planned_approver,
            pla.first_planned_primary_email,
            pla.second_planned_primary_email,
            pla.third_planned_primary_email,
            pla.fourth_planned_primary_email,
            pla.fifth_planned_primary_email,
            pla.sixth_planned_primary_email,
            pla.seventh_planned_primary_email,
            pla.eighth_planned_primary_email
            FROM
            approval_process app, 
            (SELECT
              approval_process_id,
              MAX(CASE WHEN d_rank = 1 THEN person_id ELSE NULL END) as FIRST_PLANNED_APPROVER_ID,
              MAX(CASE WHEN d_rank = 2 THEN person_id ELSE NULL END) as SECOND_PLANNED_APPROVER_ID,
              MAX(CASE WHEN d_rank = 3 THEN person_id ELSE NULL END) as THIRD_PLANNED_APPROVER_ID,
              MAX(CASE WHEN d_rank = 4 THEN person_id ELSE NULL END) as FOURTH_PLANNED_APPROVER_ID,
              MAX(CASE WHEN d_rank = 5 THEN person_id ELSE NULL END) as FIFTH_PLANNED_APPROVER_ID,
              MAX(CASE WHEN d_rank = 6 THEN person_id ELSE NULL END) as SIXTH_PLANNED_APPROVER_ID,
              MAX(CASE WHEN d_rank = 7 THEN person_id ELSE NULL END) as SEVENTH_PLANNED_APPROVER_ID,
              MAX(CASE WHEN d_rank = 8 THEN person_id ELSE NULL END) as EIGHTH_PLANNED_APPROVER_ID,
              MAX(CASE WHEN d_rank = 1 THEN approver_name ELSE NULL END) as FIRST_PLANNED_APPROVER,
              MAX(CASE WHEN d_rank = 2 THEN approver_name ELSE NULL END) as SECOND_PLANNED_APPROVER,
              MAX(CASE WHEN d_rank = 3 THEN approver_name ELSE NULL END) as THIRD_PLANNED_APPROVER,
              MAX(CASE WHEN d_rank = 4 THEN approver_name ELSE NULL END) as FOURTH_PLANNED_APPROVER,
              MAX(CASE WHEN d_rank = 5 THEN approver_name ELSE NULL END) as FIFTH_PLANNED_APPROVER,
              MAX(CASE WHEN d_rank = 6 THEN approver_name ELSE NULL END) as SIXTH_PLANNED_APPROVER,
              MAX(CASE WHEN d_rank = 7 THEN approver_name ELSE NULL END) as SEVENTH_PLANNED_APPROVER,
              MAX(CASE WHEN d_rank = 8 THEN approver_name ELSE NULL END) as EIGHTH_PLANNED_APPROVER,
              MAX(CASE WHEN d_rank = 1 THEN primary_email ELSE NULL END) as FIRST_PLANNED_PRIMARY_EMAIL,
              MAX(CASE WHEN d_rank = 2 THEN primary_email ELSE NULL END) as SECOND_PLANNED_PRIMARY_EMAIL,
              MAX(CASE WHEN d_rank = 3 THEN primary_email ELSE NULL END) as THIRD_PLANNED_PRIMARY_EMAIL,
              MAX(CASE WHEN d_rank = 4 THEN primary_email ELSE NULL END) as FOURTH_PLANNED_PRIMARY_EMAIL,
              MAX(CASE WHEN d_rank = 5 THEN primary_email ELSE NULL END) as FIFTH_PLANNED_PRIMARY_EMAIL,
              MAX(CASE WHEN d_rank = 6 THEN primary_email ELSE NULL END) as SIXTH_PLANNED_PRIMARY_EMAIL,
              MAX(CASE WHEN d_rank = 7 THEN primary_email ELSE NULL END) as SEVENTH_PLANNED_PRIMARY_EMAIL,
              MAX(CASE WHEN d_rank = 8 THEN primary_email ELSE NULL END) as EIGHTH_PLANNED_PRIMARY_EMAIL
            FROM 
            (SELECT ap.approval_process_id, p.person_id, p.primary_email, --ap.approvable_type, ap.approvable_id, 
            p.last_name||', '||p.first_name||' '||p.middle_name as APPROVER_NAME,
                     na.position as d_rank
             FROM approval_process ap, appr,
                  approval_process_spec aps,
                  named_approver na,
                  firm_worker fw,
                  person p
             WHERE ap.approval_process_id = appr.approval_process_id
               AND ap.approval_process_spec_fk = aps.approval_process_spec_id
               AND aps.approval_process_spec_id = na.approval_process_spec_fk
               AND na.approver_fk = fw.firm_worker_id
               AND fw.never_null_person_fk = p.person_id
               AND aps.approval_process_spec_type != 'RBAW'
         UNION ALL
            SELECT ap.approval_process_id,  p.person_id,  p.primary_email, --ap.approvable_type, ap.approvable_id,
                   p.last_name||', '||p.first_name||' '||p.middle_name as APPROVER_NAME,
                   dense_rank() over (partition by aa.approval_process_fk order by aa.COMPLETED_DATE) d_rank
            FROM firm_worker fw, approval_activity aa, approval_process ap, person p, appr
            WHERE aa.approval_process_fk = appr.approval_process_id
              AND aa.actual_approver_fk = fw.firm_worker_id
              AND fw.never_null_person_fk = p.person_id
              AND aa.activity_type = 'ApproverTask'
              AND ap.approval_process_spec_fk in (select approval_process_spec_id from approval_process_spec where approval_process_spec_type = 'RBAW')
              AND aa.approval_process_fk = ap.approval_process_id
              )
             GROUP BY approval_process_id ) pla,
             (SELECT
                approval_process_fk,
                MAX(CASE WHEN d_rank = 1 THEN person_id ELSE NULL END) as FIRST_ACTUAL_APPROVER_ID,
                MAX(CASE WHEN d_rank = 2 THEN person_id ELSE NULL END) as SECOND_ACTUAL_APPROVER_ID,
                MAX(CASE WHEN d_rank = 3 THEN person_id ELSE NULL END) as THIRD_ACTUAL_APPROVER_ID,
                MAX(CASE WHEN d_rank = 4 THEN person_id ELSE NULL END) as FOURTH_ACTUAL_APPROVER_ID,
                MAX(CASE WHEN d_rank = 5 THEN person_id ELSE NULL END) as FIFTH_ACTUAL_APPROVER_ID,
                MAX(CASE WHEN d_rank = 6 THEN person_id ELSE NULL END) as SIXTH_ACTUAL_APPROVER_ID,
                MAX(CASE WHEN d_rank = 7 THEN person_id ELSE NULL END) as SEVENTH_ACTUAL_APPROVER_ID,
                MAX(CASE WHEN d_rank = 8 THEN person_id ELSE NULL END) as EIGHTH_ACTUAL_APPROVER_ID,
                MAX(CASE WHEN d_rank = 1 THEN APPROVER_NAME ELSE NULL END) as FIRST_ACTUAL_APPROVER,
                MAX(CASE WHEN d_rank = 2 THEN APPROVER_NAME ELSE NULL END) as SECOND_ACTUAL_APPROVER,
                MAX(CASE WHEN d_rank = 3 THEN APPROVER_NAME ELSE NULL END) as THIRD_ACTUAL_APPROVER,
                MAX(CASE WHEN d_rank = 4 THEN APPROVER_NAME ELSE NULL END) as FOURTH_ACTUAL_APPROVER,
                MAX(CASE WHEN d_rank = 5 THEN APPROVER_NAME ELSE NULL END) as FIFTH_ACTUAL_APPROVER,
                MAX(CASE WHEN d_rank = 6 THEN APPROVER_NAME ELSE NULL END) as SIXTH_ACTUAL_APPROVER,
                MAX(CASE WHEN d_rank = 7 THEN APPROVER_NAME ELSE NULL END) as SEVENTH_ACTUAL_APPROVER,
                MAX(CASE WHEN d_rank = 8 THEN APPROVER_NAME ELSE NULL END) as EIGHTH_ACTUAL_APPROVER,
                MAX(CASE WHEN d_rank = 1 THEN primary_email ELSE NULL END) as FIRST_ACTUAL_PRIMARY_EMAIL,
                MAX(CASE WHEN d_rank = 2 THEN primary_email ELSE NULL END) as SECOND_ACTUAL_PRIMARY_EMAIL,
                MAX(CASE WHEN d_rank = 3 THEN primary_email ELSE NULL END) as THIRD_ACTUAL_PRIMARY_EMAIL,
                MAX(CASE WHEN d_rank = 4 THEN primary_email ELSE NULL END) as FOURTH_ACTUAL_PRIMARY_EMAIL,
                MAX(CASE WHEN d_rank = 5 THEN primary_email ELSE NULL END) as FIFTH_ACTUAL_PRIMARY_EMAIL,
                MAX(CASE WHEN d_rank = 6 THEN primary_email ELSE NULL END) as SIXTH_ACTUAL_PRIMARY_EMAIL,
                MAX(CASE WHEN d_rank = 7 THEN primary_email ELSE NULL END) as SEVENTH_ACTUAL_PRIMARY_EMAIL,
                MAX(CASE WHEN d_rank = 8 THEN primary_email ELSE NULL END) as EIGHTH_ACTUAL_PRIMARY_EMAIL
             FROM
             (SELECT 
               ap.approvable_id, ap.approvable_type, p.primary_email, p.person_id, aa.approval_process_fk,
               p.last_name||', '||p.first_name||' '||p.middle_name as APPROVER_NAME,
               dense_rank() over (partition by aa.approval_process_fk order by aa.COMPLETED_DATE) as d_rank
              FROM firm_worker fw, approval_activity aa, approval_process ap, person p, appr
              WHERE aa.approval_process_fk = appr.approval_process_id
               AND aa.actual_approver_fk = fw.firm_worker_id
               AND fw.never_null_person_fk = p.person_id
               AND aa.activity_type = 'ApproverTask'
               AND aa.state_code = 3
               AND aa.approval_process_fk = ap.approval_process_id
               )
             GROUP BY approval_process_fk) act
            WHERE app.approval_process_id = act.approval_process_fk(+)
            AND app.approval_process_id = pla.approval_process_id(+)) act_pla_pvt, 
            }';
   v_clob3 CLOB := v_clob2 || q'{
            --> Process Specific Data Query: 
            (SELECT approval_process_id, approvable_id, approvable_type, 
                   total_amount, currency_unit,
                   approval_buyer_org_id, approval_buyer_name,
                   approval_supplier_org_id, approval_supp_name,
                   ID,  hiring_mgr_person_id, hiring_proj_manager,
                   name_type, contractor_full_name,
                  Ranking
            FROM (
            SELECT pi.approval_process_id, pi.approvable_id, pi.approvable_type, 
                  pi.total_amount, cu.description as currency_unit,
                  bo.business_organization_id as approval_buyer_org_id, bo.name as approval_buyer_name,
                  sbo.business_organization_id as approval_supplier_org_id, sbo.name as approval_supp_name,
                  pi.ID,  ph.person_id as hiring_mgr_person_id, ph.last_name ||  ', ' || ph.first_name as  hiring_proj_manager,
                  pi.name_type, pi.contractor_full_name,
                   ROW_NUMBER ()
                          OVER (
                             PARTITION BY CASE WHEN pi.approvable_type in ('WorkOrderVersion', 'WorkOrderAmendment', 'AssignmentEdition') 
                                               THEN 'AssignWorkOrder' ELSE pi.approvable_type END, pi.ID
                             ORDER BY
                               appr.approval_process_id DESC, --apprv.approvable_id DESC,
                               appr.started_date DESC,
                               appr.completed_date DESC,
                               pi.currency_unit_fk ASC
                                )
                             Ranking
            FROM (
            --> ExpenseReport Workflow Process ===============================================================================================
                SELECT 'ExpenseReport' as APPROVABLE_TYPE, erli.expense_report_fk as APPROVABLE_ID,  appr.approval_process_id,
                 --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT  
                        erli.total_amount, ae.currency_unit_fk , --> rewrite this one as subQry
                 --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                        ae.owning_buyer_firm_fk as fr_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                 --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) APPROVAL_SUPPLIER_ORG_ID
                 --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,
                        ae.owning_supply_firm_fk as sfr_firm_fk, --sbo.business_organization_id as APPROVAL_SUPPLIER_ORG_ID, sbo.name as APPROVAL_SUPP_NAME,
                 --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                         CASE WHEN expense_report_fk >= 100000 THEN to_char(expense_report_fk)
                              ELSE rtrim(to_char(expense_report_fk,'099999MI')) END as ID, 
                 --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                        ae.hiring_mgr_fk, --ph.person_id as HIRING_MGR_PERSON_ID, ph.last_name ||  ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                 --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                        'Expense Report - E-' || CASE WHEN expense_report_fk >= 100000 THEN to_char(expense_report_fk)
                                                 ELSE rtrim(to_char(expense_report_fk,'099999MI')) END as NAME_TYPE,
                 --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                        pc.last_name || ', ' || pc.first_name as CONTRACTOR_FULL_NAME
                       FROM  (SELECT er.assignment_continuity_fk, er.expense_report_fk, SUM(total_amount) total_amount
                                FROM expense_report_line_item er
                              GROUP BY er.assignment_continuity_fk, er.expense_report_fk) erli,
                             (select ae.hiring_mgr_fk, ae.assignment_continuity_fk, 
                                     ae.assignment_edition_id, ac1.owning_buyer_firm_fk, ac1.candidate_fk,
                                     ac1.owning_supply_firm_fk, ac1.currency_unit_fk
                                from assignment_edition ae, assignment_continuity ac1
                               where ae.assignment_continuity_fk = ac1.assignment_continuity_id
                                 and ae.assignment_edition_id = ac1.current_edition_fk) ae,
                            candidate c, person pc, appr
                       WHERE erli.assignment_continuity_fk = ae.assignment_continuity_fk
                           AND ae.candidate_fk = c.candidate_id
                           AND c.person_fk = pc.person_id
                           AND appr.approvable_id = erli.expense_report_fk
                           AND appr.approvable_type = 'ExpenseReport'      
             UNION ALL               
            --> WorkOrderVersion, WorkOrderAmendment Workflow Process ===========================================================================================       
                  SELECT appr.approvable_type,  wov.contract_version_id  as approvable_id, appr.approval_process_id,--'WorkOrderVersion' as approvable_type,
                   --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT  
                          wov.TOTAL_AMOUNT,  wo.approved_currency_fk currency_unit,
                   --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                         ac.owning_buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                   --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) APPROVAL_SUPPLIER_ORG_ID
                     --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,
                         ac.owning_supply_firm_fk, --sbo.business_organization_id as APPROVAL_SUPPLIER_ORG_ID, sbo.name as APPROVAL_SUPP_NAME,
                   --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                         CAST(ac.assignment_continuity_id as VARCHAR2(256)) as ID,
                   --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                         ae.hiring_mgr_fk, --ph.person_id as HIRING_MGR_PERSON_ID, ph.last_name ||  ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                   --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                         'Work Order: '|| j.position_title|| ' ('|| ac.assignment_continuity_id
                        || CASE WHEN cv.contract_version_name IS NOT NULL THEN '/ ' || cv.contract_version_name END || ')' as NAME_TYPE ,            
                   --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                         pc.last_name || ', ' || pc.first_name as CONTRACTOR_FULL_NAME
                   FROM work_order_version wov, contract_version cv, work_order wo, 
                        assignment_continuity ac, 
                         (select ae1.assignment_continuity_fk, ae1.assignment_edition_id, ae1.hiring_mgr_fk 
                         from assignment_edition ae1, assignment_continuity ac1
                         where ac1.assignment_continuity_id = ae1.assignment_continuity_fk
                           AND ae1.assignment_edition_id = ac1.current_edition_fk
                           ) ae,
                        job j, candidate c, person pc,
                        appr
                  WHERE wov.contract_version_id = cv.contract_version_id
                  AND cv.contract_fk = wo.contract_id --> test cardinality.
                  AND wo.contract_id = ac.work_order_fk
                  AND ac.job_fk = j.job_id (+) --> does a work order always have a job id? Leaning toward, yes...
                  AND ac.candidate_fk = c.candidate_id(+)
                  AND c.person_fk = pc.person_id(+)
                  AND ac.assignment_continuity_id = ae.assignment_continuity_fk -->
                  AND appr.approvable_id = wov.contract_version_id
                  AND appr.approvable_type in ('WorkOrderVersion', 'WorkOrderAmendment')
                  --AND wov.contract_version_id = p_id    
             UNION ALL
            --> Job Workflow Process ========================================================================================================
                SELECT  'Job' as Approvable_type, j.job_id as approvable_id,  appr.approval_process_id,
                    --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT  
                          j.MRA_TOTAL, r.currency_unit_fk,
                   --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                          j.buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                   --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) APPROVAL_SUPPLIER_ORG_ID
                   --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,
                          NULL , --NULL as APPROVAL_SUPPLIER_ORG_ID, NULL as APPROVAL_SUPP_NAME,
                   --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                          CAST(j.job_id as VARCHAR2(256)) as ID, 
                   --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                          j.hiring_mgr_firm_woker_fk, --ph.person_id as HIRING_MGR_PERSON_ID, ph.last_name ||  ', '|| ph.first_name as  HIRING_PROJ_MANAGER,
                   --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                           'Job Requisition: '|| j.position_title|| ' ('|| j.job_id|| ')'as NAME_TYPE,
                   --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                           pc.last_name || ', ' || pc.first_name as CONTRACTOR_FULL_NAME
                 FROM job j, job_employment_terms jet, job_contr_empl_terms jcet,
                      compensation comp, rate r,
                      firm_worker fwc, person pc ,
                      appr
                 WHERE j.job_employment_terms_fk = jet.job_employment_terms_id
                     AND jet.job_employment_terms_id = jcet.job_employment_terms_fk
                     AND jcet.compensation_fk = comp.compensation_id(+)
                     AND comp.compensation_id = r.compensation_fk(+)
                     AND comp.selected_rate = r.rate_unit_fk(+)
                     AND j.owner_firm_worker_fk = fwc.firm_worker_id(+)
                     AND fwc.user_fk = pc.person_id(+)   
                     AND appr.approvable_id = j.job_id
                     AND appr.approvable_type = 'Job'  
                     --AND j.job_id = p_id;
            --> MilestoneInvoice Workflow Process ===========================================================================================       
              UNION ALL
                SELECT    'MilestoneInvoice' as approvable_type,  mi.identifier as approvable_id, appr.approval_process_id,
                 --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT  
                   --> Points to rpt_util_project.get_p_this_amount(pa.contract_id, mi.expenditure_fk) 
                          e.payment_amount, pa.currency_unit_fk,
                --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                          p.buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) APPROVAL_SUPPLIER_ORG_ID
                --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,
                          pa.supply_firm_fk, --sbo.business_organization_id as APPROVAL_SUPPLIER_ORG_ID, sbo.name as APPROVAL_SUPP_NAME, 
                --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                          CAST(pa.contract_id AS VARCHAR2(256)) as ID,
                --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                          pa.project_manager_fk, --ph.person_id as HIRING_MGR_PERSON_ID, ph.last_name ||  ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                          'Payment Request: '|| PA.NAME|| ' ('|| PA.CONTRACT_ID || ')' as NAME_TYPE,
                --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                          NULL as CONTRACTOR_FULL_NAME    
                FROM   project_agreement pa, milestone_invoice mi, 
                       expenditure e, project p,
                       appr
                WHERE mi.PROJECT_AGREEMENT_FK = pa.contract_id
                  AND mi.expenditure_fk = e.identifier
                  AND pa.project_fk = p.project_id
                  AND appr.approvable_id = mi.identifier
                  AND appr.approvable_type = 'MilestoneInvoice'  
                  }';
                  
       v_clob4 CLOB := v_clob3 || q'{           
            --> ProjectRFxVersion Workflow Process ==========================================================================================           
              UNION ALL
                SELECT  'ProjectRFxVersion' as approvable_type,  prv.project_rfx_version_id as approvable_id, appr.approval_process_id, 
                  --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT   
                         prv.ESTIMATED_BUDGET, prv.currency_unit_fk,
                 --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                         p.buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                 --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) APPROVAL_SUPPLIER_ORG_ID
                 --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,
                         p.supply_firm_fk, --sbo.business_organization_id as APPROVAL_SUPPLIER_ORG_ID, sbo.name as APPROVAL_SUPP_NAME, 
                 --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                         CAST(prv.project_rfx_fk AS VARCHAR2(256)) as ID,
                 --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                         prv.project_manager_fk, --ph.person_id as HIRING_MGR_PERSON_ID, ph.last_name || ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                 --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                         'Project RFx: ' || PRV.TITLE as NAME_TYPE,
                 --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                         NULL as CONTRACTOR_FULL_NAME
                 FROM project_rfx_version prv, project_rfx pr, project p  ,
                      appr
                 WHERE prv.project_rfx_fk = pr.project_rfx_id
                     AND pr.project_fk = p.project_id
                     AND appr.approvable_id = prv.project_rfx_version_id
                     AND appr.approvable_type = 'ProjectRFxVersion'   
                     --AND prv.project_rfx_version_id = p_id 
            --> ProjectAgreementVersion Workflow Process ====================================================================================
              UNION ALL
                 SELECT
                    'ProjectAgreementVersion' as approvable_type, pav.contract_version_id  as approvable_id, appr.approval_process_id, 
                   --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT     
                    pav.TOTAL_ESTIMATED_COSTS, pa.currency_unit_fk ,
                   --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                    p.buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                   --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) APPROVAL_SUPPLIER_ORG_ID
                   --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,
                    pa.supply_firm_fk, --sbo.business_organization_id  as APPROVAL_SUPPLIER_ORG_ID  ,   sbo.name as APPROVAL_SUPP_NAME,     
                   --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                    CAST(pa.contract_id as VARCHAR2(256)) as ID,
                   --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                    pa.project_manager_fk, --ph.person_id as HIRING_MGR_PERSON_ID, ph.last_name || ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                   --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                    'Project Agreement: ' || pa.name || ' (' || pa.contract_id || CASE WHEN cv.contract_version_name IS NOT NULL
                              THEN '/ ' || cv.contract_version_name END || ')' as NAME_TYPE,
                   --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                   NULL as CONTRACTOR_FULL_NAME              
                 FROM project_agreement_version pav, contract_version cv, 
                      project_agreement pa, project p, 
                      appr
                  WHERE pav.contract_version_id = cv.contract_version_id 
                  AND cv.contract_fk = pa.contract_id
                  AND pa.project_fk = p.project_id
                  AND appr.approvable_id = pav.contract_version_id
                  AND appr.approvable_type = 'ProjectAgreementVersion' 
                  --AND pav.contract_version_id = p_id   
            --> AssignmentEdition Workflow Process ==========================================================================================    
              UNION ALL
                 SELECT 'AssignmentEdition' as approvable_type, ae.assignment_edition_id as approvable_id, appr.approval_process_id,
                  --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT  
                         ae.TOTAL_AMOUNT, ac.currency_unit_fk,
                 --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                         ac.owning_buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                 --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) APPROVAL_SUPPLIER_ORG_ID
                 --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,
                         ac.owning_supply_firm_fk, --sbo.business_organization_id  as APPROVAL_SUPPLIER_ORG_ID,  sbo.name as  APPROVAL_SUPP_NAME,        
                 --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                         CAST(ac.assignment_continuity_id as VARCHAR2(256)) as ID,
                 --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                         ae.hiring_mgr_fk, --ph.person_id as HIRING_MGR_PERSON_ID, ph.last_name || ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                 --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                         'Assignment: ' || J.POSITION_TITLE || ' (' || ac.ASSIGNMENT_CONTINUITY_ID || ')' as NAME_TYPE,
                 --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                         pc.last_name || ', ' || pc.first_name as CONTRACTOR_FULL_NAME
                 FROM assignment_edition ae, assignment_continuity ac, 
                      job j, candidate c, person pc,
                      appr
                 WHERE ae.assignment_continuity_fk = ac.assignment_continuity_id
                     AND ac.job_fk = j.job_id
                     AND ac.candidate_fk = c.candidate_id
                     AND c.person_fk = pc.person_id
                     AND appr.approvable_id = ae.assignment_edition_id
                     AND appr.approvable_type = 'AssignmentEdition' 
                     --AND ae.assignment_edition_id = p_id 
            --> PaymentRequest Workflow Process =============================================================================================       
              UNION ALL
                 SELECT 'PaymentRequest' as approvable_type, pr.identifier as approvable_id, appr.approval_process_id,
                  --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT  
                         pr.requested_amount, ac.currency_unit_fk,
                 --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                         ac.owning_buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                 --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) APPROVAL_SUPPLIER_ORG_ID
                 --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,
                         ac.owning_supply_firm_fk, --sbo.business_organization_id as APPROVAL_SUPPLIER_ORG_ID, sbo.name as   APPROVAL_SUPP_NAME, 
                 --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                         CAST(pr.identifier as VARCHAR2(256)) as ID,
                  --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                         ae.hiring_mgr_fk, --ph.person_id, ph.last_name ||  ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                  --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                        'Payment Request: '|| ct.child_role_name || '(' || pr.identifier || ')' as NAME_TYPE,
                  --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                         pc.last_name || ', ' || pc.first_name
                   FROM payment_request pr, assignment_continuity ac, contract_term ct,
                        (select hiring_mgr_fk, assignment_continuity_fk, assignment_edition_id
                         from assignment_edition ae, assignment_continuity ac1
                         where ae.assignment_continuity_fk = ac1.assignment_continuity_id
                           and ae.assignment_edition_id = ac1.current_edition_fk) ae, 
                        candidate c, person pc, appr
                    WHERE pr.assignment_continuity_fk = ac.assignment_continuity_id
                      AND ac.assignment_continuity_id = ae.assignment_continuity_fk 
                      AND pr.payment_request_spec_fk = ct.contract_term_id
                      AND ac.candidate_fk = c.candidate_id
                      AND c.person_fk = pc.person_id
                      AND appr.approvable_id = pr.identifier
                      AND appr.approvable_type = 'PaymentRequest'         
                      --AND pr.IDENTIFIER = P_ID
            --> TimeCard Workflow Process ===================================================================================================
              UNION ALL
                --SELECT GET_TIMECARD_AMOUNT (P_ID) INTO V_VALUE FROM DUAL; --> consider keeping.
                 SELECT 'TimeCard' as approvable_type, t.timecard_id as approvable_id,  appr.approval_process_id,
                 --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT  in this case link to timecard lego.
                          0 as Amount, ac.currency_unit_fk,
                 --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                          ac.owning_buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                 --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) APPROVAL_SUPPLIER_ORG_ID
                 --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,
                          ac.owning_supply_firm_fk, --sbo.business_organization_id as APPROVAL_SUPPLIER_ORG_ID, sbo.name as APPROVAL_SUPP_NAME,
                 --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                          CAST(t.timecard_number as VARCHAR2(256)) as ID,
                 --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                          ae.hiring_mgr_fk, --ph.person_id as HIRING_MGR_PERSON_ID, ph.last_name ||  ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                 --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                          'Timecard: ' || t.timecard_number,
                 --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                          pc.last_name || ', ' || pc.first_name as CONTRACTOR_FULL_NAME
                       FROM timecard t, assignment_continuity ac, 
                             (select hiring_mgr_fk, assignment_continuity_fk, assignment_edition_id
                              from assignment_edition ae, assignment_continuity ac1
                              where ae.assignment_continuity_fk = ac1.assignment_continuity_id
                                and ae.assignment_edition_id = ac1.current_edition_fk) ae,           
                            candidate c, person pc, appr
                         WHERE t.assignment_continuity_fk = ac.assignment_continuity_id
                           AND ac.assignment_continuity_id = ae.assignment_continuity_fk 
                           AND ac.candidate_fk = c.candidate_id
                           AND c.person_fk = pc.person_id
                           AND appr.approvable_id = t.timecard_id
                           AND appr.approvable_type = 'TimeCard' 
            --> SupplierProjectResourceProposal Workflow Process =============================================================================       
             UNION ALL
                     /*
                 Supplier Project Resource Proposals do not have an "approval amount" (the concept does not apply) for this workflow process
                 */ --> check workflow: ac.procurement_wkfl_edition_fk?
                    SELECT 'SupplierProjectResourceProposal' as approvable_type,  pr.identifier as Approvable_id, appr.approval_process_id,
                   --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT  
                           NULL as AMOUNT, NULL as currency_unit_fk , 
                    --> rpt_util_apCURRENCY_CONVERSION_FKproval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                           ac.owning_buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                    --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type)
                    --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME,   
                           pa.supply_firm_fk, --sbo.business_organization_id as APPROVAL_SUPPLIER_ORG_ID, sbo.name as APPROVAL_SUPP_NAME,  
                    --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                           CAST(pr.project_agreement_fk as VARCHAR2(256)) as ID,
                    --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,HIRING_PROJ_MANAGER
                           pr.supplier_project_manager_fk, --ph.person_id as HIRING_MGR_PERSON_ID,  ph.last_name || ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                    --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                           'Project Resource: ' || p.first_name || ' ' || p.last_name as NAME_TYPE,
                    --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                            p.last_name || ', ' || p.first_name as CONTRACTOR_FULL_NAME   
                   FROM project_resource_proposal pr, project_agreement pa, 
                        candidate c, person p, assignment_continuity ac, 
                        (select hiring_mgr_fk, assignment_continuity_fk, assignment_edition_id
                              from assignment_edition ae, assignment_continuity ac1
                              where ae.assignment_continuity_fk = ac1.assignment_continuity_id
                                and ae.assignment_edition_id = ac1.current_edition_fk) ae,
                        appr
                  WHERE  pr.project_agreement_fk = pa.contract_id
                        AND pr.assignment_continuity_fk  = ac.assignment_continuity_id(+)
                        AND ac.assignment_continuity_id = ae.assignment_continuity_fk(+)--> Cardinality?
                        AND pr.candidate_fk = c.candidate_id(+)
                        AND c.person_fk = p.person_id(+)
                        AND appr.approvable_id =  pr.identifier
                        AND appr.approvable_type = 'SupplierProjectResourceProposal'     
            --> RequestToBuyEdition Workflow Process ========================================================================================= 
            /* RTB may or may not have an amount captured. */                 
             UNION ALL
                 SELECT  'RequestToBuyEdition' as approvable_type, rtbe.identifier as approvable_id, appr.approval_process_id,
                  --> rpt_util_approval.GET_APPROVAL_AMOUNT (ap.approvable_id, ap.approvable_type) APPROVAL_AMOUNT  
                         NVL (rtbe.anticipated_costs, rtbe.total_budget) as APPROVAL_AMOUNT, rtbe.currency_unit_fk,
                 --> rpt_util_approval.GET_APPROVAL_BUS_ID (ap.approvable_id, ap.approvable_type) APPROVAL_BUYER_ORG_ID
                         rtbc.owning_buyer_firm_fk, --bo.business_organization_id as APPROVAL_BUYER_ORG_ID,
                 --> rpt_util_approval.GET_APPROVAL_SUPP_ID (ap.approvable_id, ap.approvable_type) as APPROVAL_SUPPLIER_ORG_ID,
                 --> rpt_util_approval.GET_APPROVAL_SUPP_NAME (ap.approvable_id, ap.approvable_type) AS APPROVAL_SUPP_NAME, 
                         pa.supply_firm_fk, --sbo.business_organization_id as APPROVAL_SUPPLIER_ORG_ID, sbo.name as APPROVAL_SUPP_NAME,
                 --> rpt_util_approval.GET_APPROVAL_ID (ap.approvable_id, ap.approvable_type) ID,
                         CAST(rtbe.identifier AS VARCHAR2(256)) as ID,
                 --> rpt_util_approval.GET_HIRING_MANG_ID (ap.approvable_id, ap.approvable_type) HIRING_MGR_PERSON_ID,
                         pa.project_manager_fk, --ph.person_id, ph.last_name || ', ' || ph.first_name as  HIRING_PROJ_MANAGER,
                 --> rpt_util_approval.GET_APPROVAL_NAME_ID (ap.approvable_id, ap.approvable_type) AS NAME_TYPE,
                         'Request to Buy: '||rtbe.title as NAME_TYPE,
                 --> rpt_util_approval.GET_APPROVAL_CONTRACTOR (AP.APPROVABLE_ID, AP.APPROVABLE_TYPE) AS CONTRACTOR_FULL_NAME
                         NULL as CONTRACTOR_FULL_NAME                          
                   FROM request_to_buy_edition rtbe, request_to_buy_continuity rtbc, 
                        project_agreement pa, project p,
                        appr
                  WHERE rtbe.request_to_buy_continuity_fk = rtbc.identifier
                    AND rtbc.identifier = pa.request_to_buy_fk(+)
                    AND pa.project_fk = p.project_id(+)
                    AND appr.approvable_id =  rtbe.identifier
                    AND appr.approvable_type = 'RequestToBuyEdition' 
                      --AND rtbe.identifier = p_id
                      ) pi,
                      firm_role fr, business_organization bo, 
                     firm_role sfr, business_organization sbo,
                     firm_worker fw, person ph,
                     currency_unit cu, appr
            WHERE appr.approval_process_id = pi.approval_process_id
              AND pi.fr_firm_fk = fr.firm_id(+) 
              AND fr.business_org_fk = bo.business_organization_id (+)
              AND pi.sfr_firm_fk = sfr.firm_id(+)
              AND sfr.business_org_fk = sbo.business_organization_id(+)
              AND pi.hiring_mgr_fk = fw.firm_worker_id(+)
              AND fw.user_fk = ph.person_id(+)
              AND pi.currency_unit_fk = cu.value(+))
            ) ps_data
            WHERE ap.approval_process_id = le.approval_process_fk(+)
            AND ap.approval_process_id = ca.approval_process_id(+)
            AND ap.approval_process_spec_fk = aps.approval_process_spec_id
            AND ap.buyer_organization_fk = bo.business_organization_id
            AND ap.approval_requestor_fk = fwr.firm_worker_id(+)
            AND fwr.never_null_person_fk = pr.person_id(+)
            AND ap.approval_process_id = act_pla_pvt.approval_process_id 
            AND ap.approval_process_id = ps_data.approval_process_id
            )) select * from apprv) apprv
            }';
    v_clob5 CLOB := v_clob4 || q'{
            ON (apprm.approval_process_id = apprv.approval_process_id
                and apprm.Ranking = apprv.Ranking) --> Currency Diffs
        WHEN MATCHED THEN UPDATE SET 
            apprm.buyer_org_id = apprv.buyer_org_id,
            apprm.approvable_id = apprv.approvable_id,
            apprm.approvable_type  = apprv.approvable_type, 
            --apprm.approval_process_id = apprv.approval_process_id,
            apprm.approval_status = apprv.approval_status,
            apprm.time_in_approval_process    = apprv.time_in_approval_process,   
            apprm.approval_workflow = apprv.approval_workflow,
            apprm.approver_requestor     = apprv.approver_requestor,    
            apprm.date_submitted_for_app = apprv.date_submitted_for_app,
            apprm.date_approved_date    = apprv.date_approved_date,   
            apprm.date_sub_for_app_t_stamp = apprv.date_sub_for_app_t_stamp,
            apprm.date_approved_t_stamp  = apprv.date_approved_t_stamp, 
            apprm.bo_name = apprv.bo_name,
            apprm.final_approver = apprv.final_approver,
            apprm.last_event = apprv.last_event,
            apprm.last_event_date = apprv.last_event_date,
            apprm.time_last_approver = apprv.time_last_approver,
            apprm.current_approver = apprv.current_approver,
            apprm.current_approver_email = apprv.current_approver_email,
            apprm.total_amount  = apprv.total_amount, 
            apprm.currency_unit  = apprv.currency_unit, 
            apprm.approval_buyer_org_id = apprv.approval_buyer_org_id,
            apprm.approval_buyer_name = apprv.approval_buyer_name,
            apprm.approval_supplier_org_id  = apprv.approval_supplier_org_id, 
            apprm.approval_supp_name = apprv.approval_supp_name,
            apprm.id  = apprv.id, 
            apprm.hiring_mgr_person_id  = apprv.hiring_mgr_person_id, 
            apprm.hiring_proj_manager = apprv.hiring_proj_manager,
            apprm.name_type = apprv.name_type,
            apprm.contractor_full_name = apprv.contractor_full_name,
            --apprm.Ranking = apprv.Ranking,
            apprm.first_actual_approver_id = apprv.first_actual_approver_id,
            apprm.second_actual_approver_id = apprv.second_actual_approver_id,
            apprm.third_actual_approver_id = apprv.third_actual_approver_id,
            apprm.fourth_actual_approver_id = apprv.fourth_actual_approver_id,
            apprm.fifth_actual_approver_id = apprv.fifth_actual_approver_id,
            apprm.sixth_actual_approver_id = apprv.sixth_actual_approver_id,
            apprm.seventh_actual_approver_id = apprv.seventh_actual_approver_id,
            apprm.eighth_actual_approver_id = apprv.eighth_actual_approver_id,
            apprm.first_actual_approver = apprv.first_actual_approver,
            apprm.second_actual_approver = apprv.second_actual_approver,
            apprm.third_actual_approver = apprv.third_actual_approver,
            apprm.fourth_actual_approver = apprv.fourth_actual_approver,
            apprm.fifth_actual_approver = apprv.fifth_actual_approver,
            apprm.sixth_actual_approver = apprv.sixth_actual_approver,
            apprm.seventh_actual_approver = apprv.seventh_actual_approver,
            apprm.eighth_actual_approver = apprv.eighth_actual_approver,
            apprm.first_actual_primary_email = apprv.first_actual_primary_email,
            apprm.second_actual_primary_email = apprv.second_actual_primary_email,
            apprm.third_actual_primary_email = apprv.third_actual_primary_email,
            apprm.fourth_actual_primary_email = apprv.fourth_actual_primary_email,
            apprm.fifth_actual_primary_email = apprv.fifth_actual_primary_email,
            apprm.sixth_actual_primary_email = apprv.sixth_actual_primary_email,
            apprm.seventh_actual_primary_email = apprv.seventh_actual_primary_email,
            apprm.eighth_actual_primary_email = apprv.eighth_actual_primary_email,
            apprm.first_planned_approver_id = apprv.first_planned_approver_id,
            apprm.second_planned_approver_id = apprv.second_planned_approver_id,
            apprm.third_planned_approver_id = apprv.third_planned_approver_id,
            apprm.fourth_planned_approver_id = apprv.fourth_planned_approver_id,
            apprm.fifth_planned_approver_id = apprv.fifth_planned_approver_id,
            apprm.sixth_planned_approver_id = apprv.sixth_planned_approver_id,
            apprm.seventh_planned_approver_id = apprv.seventh_planned_approver_id,
            apprm.eighth_planned_approver_id = apprv.eighth_planned_approver_id,
            apprm.first_planned_approver = apprv.first_planned_approver,
            apprm.second_planned_approver = apprv.second_planned_approver,
            apprm.third_planned_approver = apprv.third_planned_approver,
            apprm.fourth_planned_approver = apprv.fourth_planned_approver,
            apprm.fifth_planned_approver = apprv.fifth_planned_approver,
            apprm.sixth_planned_approver = apprv.sixth_planned_approver,
            apprm.seventh_planned_approver = apprv.seventh_planned_approver,
            apprm.eighth_planned_approver = apprv.eighth_planned_approver,
            apprm.first_planned_primary_email = apprv.first_planned_primary_email,
            apprm.second_planned_primary_email = apprv.second_planned_primary_email,
            apprm.third_planned_primary_email = apprv.third_planned_primary_email,
            apprm.fourth_planned_primary_email = apprv.fourth_planned_primary_email,
            apprm.fifth_planned_primary_email = apprv.fifth_planned_primary_email,
            apprm.sixth_planned_primary_email = apprv.sixth_planned_primary_email,
            apprm.seventh_planned_primary_email = apprv.seventh_planned_primary_email,
            apprm.eighth_planned_primary_email = apprv.eighth_planned_primary_email
            WHEN NOT MATCHED 
               THEN INSERT (
                apprm.buyer_org_id, 
                apprm.approvable_id, 
                apprm.approvable_type , 
                apprm.approval_process_id, 
                apprm.approval_status, 
                apprm.time_in_approval_process   , 
                apprm.approval_workflow, 
                apprm.approver_requestor    , 
                apprm.date_submitted_for_app, 
                apprm.date_approved_date   , 
                apprm.date_sub_for_app_t_stamp, 
                apprm.date_approved_t_stamp , 
                apprm.bo_name, 
                apprm.final_approver, 
                apprm.last_event, 
                apprm.last_event_date, 
                apprm.time_last_approver, 
                apprm.current_approver, 
                apprm.current_approver_email, 
                apprm.total_amount , 
                apprm.currency_unit , 
                apprm.approval_buyer_org_id, 
                apprm.approval_buyer_name, 
                apprm.approval_supplier_org_id , 
                apprm.approval_supp_name, 
                apprm.id , 
                apprm.hiring_mgr_person_id , 
                apprm.hiring_proj_manager, 
                apprm.name_type, 
                apprm.contractor_full_name, 
                apprm.Ranking, 
                apprm.first_actual_approver_id, 
                apprm.second_actual_approver_id, 
                apprm.third_actual_approver_id, 
                apprm.fourth_actual_approver_id, 
                apprm.fifth_actual_approver_id, 
                apprm.sixth_actual_approver_id, 
                apprm.seventh_actual_approver_id, 
                apprm.eighth_actual_approver_id, 
                apprm.first_actual_approver, 
                apprm.second_actual_approver, 
                apprm.third_actual_approver, 
                apprm.fourth_actual_approver, 
                apprm.fifth_actual_approver, 
                apprm.sixth_actual_approver, 
                apprm.seventh_actual_approver, 
                apprm.eighth_actual_approver, 
                apprm.first_actual_primary_email, 
                apprm.second_actual_primary_email, 
                apprm.third_actual_primary_email, 
                apprm.fourth_actual_primary_email, 
                apprm.fifth_actual_primary_email, 
                apprm.sixth_actual_primary_email, 
                apprm.seventh_actual_primary_email, 
                apprm.eighth_actual_primary_email, 
                apprm.first_planned_approver_id, 
                apprm.second_planned_approver_id, 
                apprm.third_planned_approver_id, 
                apprm.fourth_planned_approver_id, 
                apprm.fifth_planned_approver_id, 
                apprm.sixth_planned_approver_id, 
                apprm.seventh_planned_approver_id, 
                apprm.eighth_planned_approver_id, 
                apprm.first_planned_approver, 
                apprm.second_planned_approver, 
                apprm.third_planned_approver, 
                apprm.fourth_planned_approver, 
                apprm.fifth_planned_approver, 
                apprm.sixth_planned_approver, 
                apprm.seventh_planned_approver, 
                apprm.eighth_planned_approver, 
                apprm.first_planned_primary_email, 
                apprm.second_planned_primary_email, 
                apprm.third_planned_primary_email, 
                apprm.fourth_planned_primary_email, 
                apprm.fifth_planned_primary_email, 
                apprm.sixth_planned_primary_email, 
                apprm.seventh_planned_primary_email, 
                apprm.eighth_planned_primary_email)
              VALUES (
                apprv.buyer_org_id, 
                apprv.approvable_id, 
                apprv.approvable_type , 
                apprv.approval_process_id, 
                apprv.approval_status, 
                apprv.time_in_approval_process   , 
                apprv.approval_workflow, 
                apprv.approver_requestor    , 
                apprv.date_submitted_for_app, 
                apprv.date_approved_date   , 
                apprv.date_sub_for_app_t_stamp, 
                apprv.date_approved_t_stamp , 
                apprv.bo_name, 
                apprv.final_approver, 
                apprv.last_event, 
                apprv.last_event_date, 
                apprv.time_last_approver, 
                apprv.current_approver, 
                apprv.current_approver_email, 
                apprv.total_amount , 
                apprv.currency_unit , 
                apprv.approval_buyer_org_id, 
                apprv.approval_buyer_name, 
                apprv.approval_supplier_org_id , 
                apprv.approval_supp_name, 
                apprv.id , 
                apprv.hiring_mgr_person_id , 
                apprv.hiring_proj_manager, 
                apprv.name_type, 
                apprv.contractor_full_name, 
                apprv.Ranking, 
                apprv.first_actual_approver_id, 
                apprv.second_actual_approver_id, 
                apprv.third_actual_approver_id, 
                apprv.fourth_actual_approver_id, 
                apprv.fifth_actual_approver_id, 
                apprv.sixth_actual_approver_id, 
                apprv.seventh_actual_approver_id, 
                apprv.eighth_actual_approver_id, 
                apprv.first_actual_approver, 
                apprv.second_actual_approver, 
                apprv.third_actual_approver, 
                apprv.fourth_actual_approver, 
                apprv.fifth_actual_approver, 
                apprv.sixth_actual_approver, 
                apprv.seventh_actual_approver, 
                apprv.eighth_actual_approver, 
                apprv.first_actual_primary_email, 
                apprv.second_actual_primary_email, 
                apprv.third_actual_primary_email, 
                apprv.fourth_actual_primary_email, 
                apprv.fifth_actual_primary_email, 
                apprv.sixth_actual_primary_email, 
                apprv.seventh_actual_primary_email, 
                apprv.eighth_actual_primary_email, 
                apprv.first_planned_approver_id, 
                apprv.second_planned_approver_id, 
                apprv.third_planned_approver_id, 
                apprv.fourth_planned_approver_id, 
                apprv.fifth_planned_approver_id, 
                apprv.sixth_planned_approver_id, 
                apprv.seventh_planned_approver_id, 
                apprv.eighth_planned_approver_id, 
                apprv.first_planned_approver, 
                apprv.second_planned_approver, 
                apprv.third_planned_approver, 
                apprv.fourth_planned_approver, 
                apprv.fifth_planned_approver, 
                apprv.sixth_planned_approver, 
                apprv.seventh_planned_approver, 
                apprv.eighth_planned_approver, 
                apprv.first_planned_primary_email, 
                apprv.second_planned_primary_email, 
                apprv.third_planned_primary_email, 
                apprv.fourth_planned_primary_email, 
                apprv.fifth_planned_primary_email, 
                apprv.sixth_planned_primary_email, 
                apprv.seventh_planned_primary_email, 
                apprv.eighth_planned_primary_email)
                 }';          
         

BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob5);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  UPDATE lego_refresh
     SET refresh_sql = v_clob5
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

