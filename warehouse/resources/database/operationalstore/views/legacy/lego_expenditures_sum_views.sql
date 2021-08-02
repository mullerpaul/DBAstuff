/*******************************************************************************
SCRIPT NAME         lego_expenditures_sum_views.sql 
 
LEGO OBJECT NAME    N/A
 
CREATED             12/19/2013
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

09/10/2014 - J.Pullifrone - IQN-18776 - Adding invoiced_amount back to view now that the
                                        value represents the actual invoiced amount from 
                                        LEGO_INVOICE_DETAIL/LEGO_INVOICED_EXPENDITURE_SUM.
                                        Release 12.2.0

*******************************************************************************/ 
CREATE OR REPLACE FORCE VIEW LEGO_EXPENDITURES_SUM_VW
AS
SELECT buyer_org_id,
       supplier_org_id,
       contractor_person_id,
       hiring_mgr_person_id,
       expenditure_type,
       expenditure_number,
       assignment_continuity_id,
       project_agreement_id,
       NVL(assignment_continuity_id, -1)                        AS secjn_assignment_continuity_id,
       NVL(project_agreement_id, -1)                            AS secjn_project_agreement_id,
       COALESCE(assignment_continuity_id, project_agreement_id) AS secjn_proj_agree_assgn_cont_id,
       expenditure_date,
       state,
       accrual_amount,
       accrual_amount_cc,
       invoiced_amount,
       invoiced_amount_cc,       
       cac1_guid,
       cac2_guid,
       from_currency,
       from_currency_id,
       to_currency,
       to_currency_id,
       conversion_rate
  FROM (SELECT 'Labor'                  AS expenditure_type,
               TO_CHAR(timecard_number) AS expenditure_number,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               hiring_mgr_person_id,
               assignment_continuity_id,
               NULL                    AS project_agreement_id,
               week_ending_date        AS expenditure_date,
               timecard_state          AS state,
               SUM(accrual_amount)     AS accrual_amount,
               SUM(invoiced_amount)    AS invoiced_amount,
               SUM(accrual_amount_cc)  AS accrual_amount_cc,
               SUM(invoiced_amount_cc) AS invoiced_amount_cc,
               cac1_guid,
               cac2_guid,
               timecard_currency       AS from_currency,
               timecard_currency_id    AS from_currency_id,
               to_timecard_currency    AS to_currency,
               to_timecard_currency_id AS to_currency_id,
               conversion_rate
          FROM lego_timecard_vw t,
               available_orgs_view org
         WHERE t.buyer_org_id = org.available_org_id
         GROUP BY TO_CHAR(timecard_number),
                  buyer_org_id,
                  supplier_org_id,
                  contractor_person_id,
                  hiring_mgr_person_id,
                  assignment_continuity_id,
                  week_ending_date,
                  timecard_state,
                  cac1_guid,
                  cac2_guid,
                  timecard_currency,
                  to_timecard_currency,
                  timecard_currency_id,
                  to_timecard_currency_id,
                  conversion_rate
         UNION ALL
        SELECT 'Expense'             AS expenditure_type,
               expense_report_number AS expenditure_number,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               hiring_mgr_person_id,
               assignment_continuity_id,
               NULL                    AS project_agreement_id,
               week_ending_date        AS expenditure_date,
               expense_status          AS state,
               SUM(accrual_amount)     AS accrual_amount,
               SUM(invoiced_amount)    AS invoiced_amount,
               SUM(accrual_amount_cc)  AS accrual_amount_cc,
               SUM(invoiced_amount_cc) AS invoiced_amount_cc,
               cac1_guid,
               cac2_guid,
               expense_currency,
               expense_currency_id,
               to_expense_currency,
               to_expense_currency_id,
               conversion_rate
          FROM lego_expense_vw e,
               available_orgs_view org
         WHERE e.buyer_org_id = org.available_org_id
         GROUP BY expense_report_number,
                  buyer_org_id,
                  supplier_org_id,
                  contractor_person_id,
                  hiring_mgr_person_id,
                  assignment_continuity_id,
                  week_ending_date,
                  expense_status,
                  cac1_identifier,
                  cac2_identifier,
                  cac1_guid,
                  cac2_guid,
                  expense_currency,
                  expense_currency_id,
                  to_expense_currency,
                  to_expense_currency_id,
                  conversion_rate
         UNION ALL
        SELECT 'Payment Request'           AS expenditure_type,
               to_char(payment_request_id) AS expenditure_number,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               hiring_mgr_person_id,
               assignment_continuity_id,
               NULL                        AS project_agreement_id,
               payment_request_date        AS expenditure_date,
               payment_request_state       AS state,
               SUM(accrual_amt)            AS accural_amount,
               SUM(invoiced_amt)           AS invoiced_amount,
               SUM(accrual_amt_cc)         AS accrual_amount_cc,
               SUM(invoiced_amt_cc)        AS invoiced_amount_cc,
               cac1_guid,
               cac2_guid,
               currency,
               currency_id,
               to_apr_currency,
               to_apr_currency_id,
               conversion_rate
          FROM lego_assign_payment_request_vw a,
               available_orgs_view org
         WHERE a.buyer_org_id = org.available_org_id
         GROUP BY TO_CHAR(payment_request_id),
                  buyer_org_id,
                  supplier_org_id,
                  contractor_person_id,
                  hiring_mgr_person_id,
                  assignment_continuity_id,
                  payment_request_date,
                  payment_request_state,
                  cac1_identifier,
                  cac2_identifier,
                  cac1_guid,
                  cac2_guid,
                  currency,
                  currency_id,
                  to_apr_currency,
                  to_apr_currency_id,
                  conversion_rate
         UNION ALL
        SELECT 'Milestone'                   AS expenditure_type,
               to_char(milestone_invoice_id) AS expenditure_number,
               buyer_org_id,
               supplier_org_id,
               contractor_person_id,
               NULL AS hiring_mgr_person_id,
               NULL AS assignment_continuity_id,
               project_agreement_id,
               TRUNC(submitted_date)   AS expenditure_date,
               payment_request_status  AS state,
               SUM(accrual_amount)     AS accrual_amount,
               SUM(invoiced_amount)    AS invoiced_amount,
               SUM(accrual_amount_cc)  AS accrual_amount_cc,
               SUM(invoiced_amount_cc) AS invoice_amount_cc,
               cac1_guid,
               cac2_guid,
               currency,
               currency_id,
               to_pr_currency,
               to_pr_currency_id,
               conversion_rate
          FROM lego_payment_request_vw p,
               available_orgs_view org
         WHERE p.buyer_org_id = org.available_org_id
         GROUP BY TO_CHAR(milestone_invoice_id),
                  buyer_org_id,
                  supplier_org_id,
                  contractor_person_id,
                  project_agreement_id,
                  TRUNC(submitted_date),
                  payment_request_status,
                  cac1_guid,
                  cac2_guid,
                  currency,
                  currency_id,
                  to_pr_currency,
                  to_pr_currency_id,
                  conversion_rate)
/

