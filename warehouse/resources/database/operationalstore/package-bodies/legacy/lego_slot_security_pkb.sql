CREATE OR REPLACE PACKAGE BODY lego_slot_security AS
/******************************************************************************
   NAME:       lego_slot_security
   PURPOSE:    Build tables and processes associated with the slot security 
               Legos used by Jasper.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   IQN-17904  07/23/2014  Paul Muller      Created this package.
   
******************************************************************************/

  gc_curr_schema       CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');
  gv_months_in_refresh PLS_INTEGER := NVL(lego_refresh_mgr_pkg.get_lego_parameter_num_value(pi_parameter_name => 'months_in_refresh'), 24);

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_job_managed_cac(p_table_name IN VARCHAR2) AS
  
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_job_managed_cac
    || AUTHOR               : Erik Clark
    || DATE CREATED         : 09/25/2013
    || PURPOSE              : This builds the LEGO_JOB_MANAGED_CAC object used to report Managed CAC Records
    ||                      : in the JOB domain
    || MODIFICATION HISTORY : 07/16/2014 - pmuller - total rewrite - 12.1.2.  
    ||                      : Made this dependant on the new LEGO_MANAGED_CAC, LEGO_JOB, and the FO tables.
    ||                      : Also moved it into group 2 with other security legos.
    \*---------------------------------------------------------------------------*/
  
    /* LEGO_JOB_MANAGED_CAC contains a mapping of person IDs to the jobs which they can see based 
    on the managed CAC heirarchy.  If a person manages a CAC on a job, then they can view the job.
    Notice that since this first-pass lego is run every 4 hours; but it depends on the 2nd pass lego
    LEGO_JOB which is only run every 12 hours, the security entry for a new job will not appear until
    four hours after the new job appears in LEGO_JOB.  */
  
    lv_managed_cac_base_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_CAC');
    lv_sql                    VARCHAR2(4000) := q'{  WITH cac_to_key
    AS (SELECT j.job_id, x.cac_value_fk AS cac_value_id
          FROM cac_cacvalue_x x,
               (SELECT job_id, cac_collection1_fk AS cac_collection_id
                  FROM job
                 WHERE cac_collection1_fk IS NOT NULL
                   AND (archived_date IS NULL OR 
                        archived_date >= ADD_MONTHS(TRUNC(SYSDATE), -}' || to_char(gv_months_in_refresh) || q'{))
                 UNION ALL
                SELECT job_id, cac_collection2_fk
                  FROM job
                 WHERE cac_collection2_fk IS NOT NULL
                   AND (archived_date IS NULL OR 
                        archived_date >= ADD_MONTHS(TRUNC(SYSDATE), -}' || to_char(gv_months_in_refresh) || q'{))) j
         WHERE x.cac_fk = j.cac_collection_id)
SELECT mc.user_id, 
       ctk.job_id
  FROM cac_to_key ctk, }' ||
       lv_managed_cac_base_table || q'{ mc,
       lego_job l  --using synonym to get latet released table
 WHERE mc.cac_value_id = ctk.cac_value_id
   AND ctk.job_id      = l.job_id
 ORDER BY 1,2}';
  
  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => p_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_JOB_MANAGED_CAC'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_JOB_MANAGED_CAC'));
  
  END load_lego_job_managed_cac;

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_assign_managed_cac(p_table_name IN VARCHAR2) AS
  
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_assign_managed_cac
    || AUTHOR               : Erik Clark
    || DATE CREATED         : 09/25/2013
    || PURPOSE              : This builds the LEGO_ASSIGN_MANAGED_CAC object used to report Managed CAC Records
    ||                      : in the ASSIGNMENT domain
    || MODIFICATION HISTORY : 07/16/2014 - pmuller - total rewrite - 12.1.2.  
    ||                      : Made this dependant on the new LEGO_MANAGED_CAC, LEGO_ASSIGNMENT_VW view, and the FO tables.
    ||                      : Also moved it into group 2 with other security legos.
    \*---------------------------------------------------------------------------*/
  
    /* LEGO_ASSIGN_MANAGED_CAC contains a mapping of person IDs to the assignments which they can see 
    based on the managed CAC heirarchy.  If a person manages a CAC on an assignment, then they can 
    view the assignment.  Notice that since this first-pass lego is run every 4 hours; but it depends 
    on the 2nd pass LEGO_ASSIGNMENT_* legos which are only run every 12 hours, the security entry for a 
    new assignment will not appear until four hours after the new assignment appears in LEGO_ASSIGNMENT_VW.  */
    /* Refresh performance of this lego may be improved by making one or more of the following changes:
        1. replace the cac_to_key query with a query against LEGO_ASSIGNMENT_CAC
        2. replace the reference to LEGO_ASSIGNMENT_VW with a query against a union all of the three
           base assignment legos.  */
  
    lv_managed_cac_base_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_CAC');
    lv_sql                    VARCHAR2(4000) := q'{  WITH cac_to_key
    AS (SELECT a.assignment_continuity_id, x.cac_value_fk AS cac_value_id
          FROM cac_cacvalue_x x,
               (SELECT assignment_continuity_id, cac_collection1_fk AS cac_collection_id
                  FROM assignment_continuity ac, 
                       assignment_edition    ae
                 WHERE ac.assignment_continuity_id = ae.assignment_continuity_fk
                   AND ac.current_edition_fk       = ae.assignment_edition_id
                   AND cac_collection1_fk IS NOT NULL
                   AND (ae.actual_end_date IS NULL OR 
                        ae.actual_end_date >= ADD_MONTHS(TRUNC(SYSDATE), -}' || to_char(gv_months_in_refresh) || q'{)) 
                 UNION ALL
                SELECT assignment_continuity_id, cac_collection2_fk AS cac_collection_id
                  FROM assignment_continuity ac, 
                       assignment_edition    ae
                 WHERE ac.assignment_continuity_id = ae.assignment_continuity_fk
                   AND ac.current_edition_fk       = ae.assignment_edition_id
                   AND cac_collection2_fk IS NOT NULL
                   AND (ae.actual_end_date IS NULL OR 
                        ae.actual_end_date >= ADD_MONTHS(TRUNC(SYSDATE), -}' || to_char(gv_months_in_refresh) || q'{))) a
         WHERE x.cac_fk = a.cac_collection_id)
SELECT mc.user_id, 
       ctk.assignment_continuity_id
  FROM cac_to_key ctk, }' ||
       lv_managed_cac_base_table || q'{ mc,
       lego_assignment_vw l  --using view so we don't need to union the 3 lego assignment tables
 WHERE mc.cac_value_id = ctk.cac_value_id
   AND ctk.assignment_continuity_id = l.assignment_continuity_id
 ORDER BY 1,2}';
  
  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => p_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_ASSIGN_MANAGED_CAC'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_ASSIGN_MANAGED_CAC'));
  
  END load_lego_assign_managed_cac;

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_pa_managed_cac(p_table_name IN VARCHAR2) AS

    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_pa_managed_cac
    || AUTHOR               : Erik Clark
    || DATE CREATED         : 09/25/2013
    || PURPOSE              : This builds the LEGO_PA_MANAGED_CAC object used to report Managed CAC Records
    ||                      : in the PROJECT/PROJECT AGREEMENT domain
    || MODIFICATION HISTORY : 07/16/2014 - pmuller - total rewrite - 12.1.2.  
    ||                      : Made this dependant on the new LEGO_MANAGED_CAC, LEGO_PROJECT_AGREEMENT, 
    ||                      : and the FO tables.  Also moved it into group 2 with other security legos.
    \*---------------------------------------------------------------------------*/
  
    /* LEGO_PA_MANAGED_CAC contains a mapping of person IDs to the project agreements which they can 
    see based on the managed CAC heirarchy.  If a person manages a CAC on a project agreement, then 
    they can view the project agreement. Notice that since this first-pass lego is run every 4 hours; 
    but it depends on the 2nd pass lego LEGO_PROJECT_AGREEMENT which is only run every 12 hours, 
    the security entry for a new project agreement will not appear until four hours after the new PA
    appears in LEGO_PROJECT_AGREEMENT.  */
    /* To put a 2 year filter on the cac_to_key query we'd have to join to the project_agreement_version 
    table.  I didn't do this since project_agreement is relatively small.  If we need to improve the refresh
    performance of this lego, we should look at putting in the join and the 2 year limit. */
  
    lv_managed_cac_base_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_CAC');
    lv_sql                    VARCHAR2(4000) := q'{  WITH cac_to_key
    AS (SELECT pa.project_agreement_id, x.cac_value_fk AS cac_value_id
          FROM cac_cacvalue_x x,
               (SELECT contract_id AS project_agreement_id, cac_collection1_fk AS cac_collection_id
                  FROM project_agreement 
                 WHERE cac_collection1_fk IS NOT NULL
                 UNION ALL
                SELECT contract_id AS project_agreement_id, cac_collection2_fk AS cac_collection_id
                  FROM project_agreement 
                 WHERE cac_collection2_fk IS NOT NULL) pa
         WHERE x.cac_fk = pa.cac_collection_id)
SELECT mc.user_id, 
       ctk.project_agreement_id
  FROM cac_to_key ctk, }' ||
       lv_managed_cac_base_table || q'{ mc,
       lego_project_agreement l  --using synonym to get latest released table
 WHERE mc.cac_value_id = ctk.cac_value_id
   AND ctk.project_agreement_id = l.project_agreement_id
 ORDER BY 1,2}';

  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => p_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_PA_MANAGED_CAC'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_PA_MANAGED_CAC'));

  END load_lego_pa_managed_cac;

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_expense_managed_cac(pi_refresh_table_name IN VARCHAR2) 
    AS
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_expense_managed_cac
    || AUTHOR               : Paul Muller
    || DATE CREATED         : June 9th, 2014
    || PURPOSE              : This procedure builds a toggle table for LEGO_EXPENSE_MANAGED_CAC.
    || MODIFICATION HISTORY : 06/09/2014 - pmuller - initial build.
    \*---------------------------------------------------------------------------*/
  
    /* LEGO_EXPENSE_MANAGED_CAC contains a mapping of person IDs to the expense reports which they can see based 
    on the managed CAC heirarchy.  If a person manages a CAC on an expense report line item, then they can view 
    the expense report even if they can't view the assignment or are not an approver for the expense report. 
    Note that security is at the expense report level, NOT at the expense report line item level!  So if you can 
    see part of an expense report, you can see the whole thing.  */
  
    lv_managed_cac_base_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_CAC');
    lv_sql                    VARCHAR2(4000) := q'{  WITH cac_to_key
    AS (SELECT e.expense_report_id, x.cac_value_fk AS cac_value_id
          FROM cac_cacvalue_x AS OF SCN lego_refresh_mgr_pkg.get_scn() x,
               (SELECT DISTINCT
                       expense_report_fk   AS expense_report_id, 
                       cost_alloc_code1_fk AS cac_id  
                  FROM expense_report_line_item AS OF SCN lego_refresh_mgr_pkg.get_scn()
                 WHERE cost_alloc_code1_fk IS NOT NULL
                 UNION ALL
                SELECT DISTINCT 
                       expense_report_fk   AS expense_report_id, 
                       cost_alloc_code2_fk AS cac_id 
                  FROM expense_report_line_item AS OF SCN lego_refresh_mgr_pkg.get_scn()
                 WHERE cost_alloc_code2_fk IS NOT NULL) e
         WHERE e.cac_id = x.cac_fk),
       lego_expense_reports  
    AS (SELECT DISTINCT 
               expense_report_id
          FROM lego_expense)  -- selecting from the synonym for most recently RELEASED toggle table.
SELECT ch.user_id, 
       ctk.expense_report_id
  FROM cac_to_key ctk, }' ||
       lv_managed_cac_base_table || q'{ ch,
       lego_expense_reports l
 WHERE ch.cac_value_id = ctk.cac_value_id
   AND ctk.expense_report_id = l.expense_report_id
 ORDER BY 1,2}';
  
  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => pi_refresh_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_EXPENSE_MANAGED_CAC'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_EXPENSE_MANAGED_CAC'));
  
  END load_lego_expense_managed_cac;
    
  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_timecard_managed_cac(pi_refresh_table_name IN VARCHAR2) 
    AS
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_timecard_managed_cac
    || AUTHOR               : Paul Muller
    || DATE CREATED         : June 13th, 2014
    || PURPOSE              : This procedure builds a toggle table for LEGO_TIMECARD_MANAGED_CAC.
    || MODIFICATION HISTORY : 06/13/2014 - pmuller - initial build.
    \*---------------------------------------------------------------------------*/
  
    /* LEGO_TIMECARD_MANAGED_CAC contains a mapping of person IDs to the timecard which they can see based 
    on the managed CAC heirarchy.  If a person manages a CAC on a timecard entry, then they can view the 
    timecard even if they can't view the assignment or are not an approver for the timecard. 
    Note that security is at the timecard level, NOT at the timecard entry level!  So if you can 
    see part of a timecard, you can see the whole thing.  */
  
    lv_managed_cac_base_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_CAC');
    lv_sql                    VARCHAR2(4000) := q'{  WITH cac_to_key
    AS (SELECT t.timecard_fk  AS timecard_id, 
               x.cac_value_fk AS cac_value_id
          FROM cac_cacvalue_x AS OF SCN lego_refresh_mgr_pkg.get_scn() x,
               (SELECT DISTINCT
                       timecard_fk, 
                       cac1_fk AS cac_id
                  FROM timecard_entry AS OF SCN lego_refresh_mgr_pkg.get_scn() 
                 WHERE cac1_fk IS NOT NULL 
                 UNION ALL
                SELECT DISTINCT
                       timecard_fk, 
                       cac2_fk AS cac_id
                  FROM timecard_entry AS OF SCN lego_refresh_mgr_pkg.get_scn()
                 WHERE cac2_fk IS NOT NULL) t
         WHERE t.cac_id = x.cac_fk),
       lego_timecards  
    AS (SELECT DISTINCT timecard_id 
          FROM lego_timecard)
SELECT ch.user_id,
       ctk.timecard_id
  FROM cac_to_key ctk, }' ||
       lv_managed_cac_base_table || q'{ ch,
       lego_timecards t  -- this is an incremental load table
 WHERE ch.cac_value_id = ctk.cac_value_id
   AND ctk.timecard_id = t.timecard_id
 ORDER BY 1,2}';
    
  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => pi_refresh_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_TIMECARD_MANAGED_CAC'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_TIMECARD_MANAGED_CAC'));
  
  END load_lego_timecard_managed_cac;

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_slot_assignment (pi_refresh_table_name IN VARCHAR2)
    AS
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_slot_assignment
    || AUTHOR               : Paul Muller
    || DATE CREATED         : July 22nd, 2014
    || PURPOSE              : This procedure creates lego_slot_assignment
    || MODIFICATION HISTORY : 07/22/2014 - pmuller - initial build. 12.1.2
    \*---------------------------------------------------------------------------*/

    lv_managed_person_base_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_PERSON');
    lv_managed_cac_base_table    VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGN_MANAGED_CAC');
    lv_assignment_base_table     VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_SECURE_ASSIGNMENT');

    lv_sql                       VARCHAR2(4000) := q'{SELECT DISTINCT user_id, assignment_id
  FROM (SELECT lmp.manager_person_id AS user_id, 
               lsa.assignment_id
          FROM }' || lv_managed_person_base_table || ' lmp, ' ||
               lv_assignment_base_table || q'{ lsa
         WHERE lmp.employee_person_id = lsa.user_id
         UNION ALL
        SELECT amc.user_id, 
               amc.assignment_continuity_id as assignment_id
          FROM }' || lv_managed_cac_base_table || ' amc)';

  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => pi_refresh_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_SLOT_ASSIGNMENT'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_SLOT_ASSIGNMENT'));
  
  END load_lego_slot_assignment ;
    
  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_slot_job (pi_refresh_table_name IN VARCHAR2)
    AS
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_slot_job
    || AUTHOR               : Paul Muller
    || DATE CREATED         : July 22nd, 2014
    || PURPOSE              : This procedure creates lego_slot_job
    || MODIFICATION HISTORY : 07/22/2014 - pmuller - initial build. 12.1.2
    \*---------------------------------------------------------------------------*/

    lv_managed_person_base_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_PERSON');
    lv_managed_cac_base_table    VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_JOB_MANAGED_CAC');
    lv_job_base_table            VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_SECURE_JOB');

    lv_sql                       VARCHAR2(4000) := q'{SELECT DISTINCT user_id, job_id
  FROM (SELECT lmp.manager_person_id AS user_id, 
               lsj.job_id
          FROM }' || lv_managed_person_base_table || ' lmp, ' ||
               lv_job_base_table || q'{ lsj
         WHERE lmp.employee_person_id = lsj.user_id
         UNION ALL
        SELECT jmc.user_id, 
               jmc.job_id
          FROM }' || lv_managed_cac_base_table || ' jmc)';

  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => pi_refresh_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_SLOT_JOB'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_SLOT_JOB'));
  
  END load_lego_slot_job ;
    
  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_slot_proj_agreement (pi_refresh_table_name IN VARCHAR2)
    AS
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_slot_proj_agreement
    || AUTHOR               : Paul Muller
    || DATE CREATED         : July 22nd, 2014
    || PURPOSE              : This procedure creates lego_slot_proj_agreement
    || MODIFICATION HISTORY : 07/22/2014 - pmuller - initial build. 12.1.2
    \*---------------------------------------------------------------------------*/

    lv_managed_person_base_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_PERSON');
    lv_managed_cac_base_table    VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_PA_MANAGED_CAC');
    lv_proj_agg_base_table       VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_SECURE_PROJECT_AGREEMENT');

    lv_sql                       VARCHAR2(4000) := q'{SELECT DISTINCT user_id, project_agreement_id
  FROM (SELECT lmp.manager_person_id AS user_id, 
               lspa.project_agreement_id
          FROM }' || lv_managed_person_base_table || ' lmp, ' ||
               lv_proj_agg_base_table || q'{ lspa
         WHERE lmp.employee_person_id = lspa.user_id
         UNION ALL
        SELECT pamc.user_id, 
               pamc.project_agreement_id
          FROM }' || lv_managed_cac_base_table || ' pamc)';

  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => pi_refresh_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_SLOT_PROJECT_AGREEMENT'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_SLOT_PROJECT_AGREEMENT'));
  
  END load_lego_slot_proj_agreement;

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_slot_expense_report (pi_refresh_table_name IN VARCHAR2)
    AS
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_slot_expense_report
    || AUTHOR               : Paul Muller
    || DATE CREATED         : June 17th, 2014
    || PURPOSE              : This procedure creates lego_slot_expense_report.
    || MODIFICATION HISTORY : 06/17/2014 - pmuller - initial build.
    \*---------------------------------------------------------------------------*/

    /* Slot security for expense reports works like this:
            If you or one of your subordinates can see the assignment  OR
               you are an approver for the expense report  OR
               you manage a CAC on one or more expense report line items for the expense report
            Then you can see the expense report.  Otherwise you cannot see the expense report.
       Also, we apply security at the expense report level.  NOT at the expense report line item level. 
       We will use the prebuilt mappings in LEGO_MANAGED_PERSON, LEGO_MANAGED_CAC, and LEGO_SECURE_ASSIGNMENT
       to build this list.  Those other legos are in the same group and are parents of this lego, so we can find 
       the names of the tables which were just built easily. */
    lv_expense_managed_cac_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_EXPENSE_MANAGED_CAC');
    lv_managed_person_base_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_PERSON');
    lv_assignment_base_table     VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_SECURE_ASSIGNMENT');
    
    /* This lego must be a DISTINCT list of user_id and timecard_ids.  Any dupes would cause duplicate
    rows in the jasper resultset, and then all arithmatic manipulation (SUM, AVG, etc) would be incorrect.
    To make this distinct, I've used UNIONs instead of UNION ALLs.   */
    lv_sql                       VARCHAR2(4000) := q'{SELECT lmp.manager_person_id  AS user_id,    -- managed person and assignments
       erli.expense_report_fk AS expense_report_id
  FROM }' || lv_managed_person_base_table || q'{ lmp,
       }' || lv_assignment_base_table || q'{ lsa,
       expense_report_line_item AS OF SCN lego_refresh_mgr_pkg.get_scn() erli
 WHERE lmp.employee_person_id = lsa.user_id
   AND lsa.assignment_id = erli.assignment_continuity_fk
   AND erli.expense_week_ending_date >= ADD_MONTHS(TRUNC(SYSDATE), -}' || to_char(gv_months_in_refresh) || q'{ )     
 UNION 
SELECT fw.never_null_person_fk AS user_id,   -- actual approvers
       ap.approvable_id        AS expense_report_id
  FROM approval_activity AS OF SCN lego_refresh_mgr_pkg.get_scn() aa, 
       approval_process  AS OF SCN lego_refresh_mgr_pkg.get_scn() ap, 
       firm_worker       AS OF SCN lego_refresh_mgr_pkg.get_scn() fw
 WHERE aa.approval_process_fk = ap.approval_process_id
   AND aa.actual_approver_fk = fw.firm_worker_id
   AND aa.activity_type = 'ApproverTask'
   AND aa.state_code = 3
   AND ap.approvable_type ='ExpenseReport'
 UNION 
SELECT fw.never_null_person_fk AS user_id,   -- planned approvers part 1
       ap.approvable_id        AS expense_report_id
  FROM firm_worker    AS OF SCN lego_refresh_mgr_pkg.get_scn() fw, 
       named_approver AS OF SCN lego_refresh_mgr_pkg.get_scn() na,
       (SELECT DISTINCT approval_process_spec_fk,
                        approvable_id,
                        buyer_organization_fk
          FROM approval_process AS OF SCN lego_refresh_mgr_pkg.get_scn()
         WHERE approvable_type = 'ExpenseReport') ap
 WHERE ap.approval_process_spec_fk = na.approval_process_spec_fk  
   AND na.approver_fk = fw.firm_worker_id
 UNION 
SELECT fw.never_null_person_fk AS user_id,   -- planned approvers part 2
       ap.approvable_id        AS expense_report_id
  FROM firm_worker       AS OF SCN lego_refresh_mgr_pkg.get_scn() fw, 
       approval_activity AS OF SCN lego_refresh_mgr_pkg.get_scn() aa, 
       approval_process  AS OF SCN lego_refresh_mgr_pkg.get_scn() ap
 WHERE aa.approval_process_fk = ap.approval_process_id
   AND aa.approver_fk = fw.firm_worker_id
   AND ap.approvable_type ='ExpenseReport'
   AND aa.activity_type = 'ApproverTask'
 UNION
SELECT user_id,                              -- managed CAC
       expense_report_id
  FROM }' || lv_expense_managed_cac_table || q'{ lmc}';

  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => pi_refresh_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_SLOT_EXPENSE_REPORT'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_SLOT_EXPENSE_REPORT'));

  END load_lego_slot_expense_report;
    
  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_slot_timecard (pi_refresh_table_name IN VARCHAR2)
    AS
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_slot_timecard
    || AUTHOR               : Paul Muller
    || DATE CREATED         : June 17th, 2014
    || PURPOSE              : This procedure creates lego_slot_timecard.
    || MODIFICATION HISTORY : 06/17/2014 - pmuller - initial build.
    \*---------------------------------------------------------------------------*/

    /* Slot security for timecards works like this:
            If you or one of your subordinates can see the assignment  OR
               you are an approver for the timecard  OR
               you manage a CAC on one or more timecard entries for the timecard
            Then you can see the timecard.  Otherwise you cannot see the timecard.
       Also, we apply security at the timecard level.  NOT at the timecard entry level. 
       We will use the prebuilt mappings in LEGO_MANAGED_PERSON, LEGO_MANAGED_CAC, and LEGO_SECURE_ASSIGNMENT
       to build this list.  Those other legos are in the same group and are parents of this lego, so we can find 
       the names of the tables which were just built easily. */
    lv_timecard_managed_cac_table VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_TIMECARD_MANAGED_CAC');
    lv_managed_person_base_table  VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_MANAGED_PERSON');
    lv_assignment_base_table      VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_SECURE_ASSIGNMENT');
    
    /* This lego must be a DISTINCT list of user_id and timecard_ids.  Any dupes would cause duplicate
    rows in the jasper resultset, and then all arithmatic manipulation (SUM, AVG, etc) would be incorrect.
    To make this distinct, I've used UNIONs instead of UNION ALLs.   */
    lv_sql                       VARCHAR2(4000) := q'{SELECT lmp.manager_person_id AS user_id,     -- managed person and assignment
       t.timecard_id
  FROM }' || lv_assignment_base_table || q'{ lsa,
       }' || lv_managed_person_base_table || q'{ lmp,
       timecard AS OF SCN lego_refresh_mgr_pkg.get_scn() t
 WHERE lmp.employee_person_id = lsa.user_id
   AND lsa.assignment_id = t.assignment_continuity_fk
   AND t.week_ending_date >= ADD_MONTHS(TRUNC(SYSDATE), -1 * }' || to_char(gv_months_in_refresh) || q'{ ) 
 UNION
SELECT fw.never_null_person_fk AS user_id,   -- actual approvers
       ap.approvable_id        AS timecard_id
  FROM approval_activity AS OF SCN lego_refresh_mgr_pkg.get_scn() aa, 
       approval_process  AS OF SCN lego_refresh_mgr_pkg.get_scn() ap, 
       firm_worker       AS OF SCN lego_refresh_mgr_pkg.get_scn() fw
 WHERE aa.approval_process_fk = ap.approval_process_id
   AND aa.actual_approver_fk  = fw.firm_worker_id
   AND aa.activity_type       = 'ApproverTask'
   AND aa.state_code          = 3
   AND ap.approvable_type     ='TimeCard'
 UNION
SELECT fw.never_null_person_fk AS user_id,   -- planned approvers part 1
       ap.approvable_id        AS timecard_id
  FROM firm_worker    AS OF SCN lego_refresh_mgr_pkg.get_scn() fw, 
       named_approver AS OF SCN lego_refresh_mgr_pkg.get_scn() na,
       (SELECT DISTINCT approval_process_spec_fk,
                        approvable_id,
                        buyer_organization_fk
          FROM approval_process AS OF SCN lego_refresh_mgr_pkg.get_scn()
         WHERE approvable_type = 'TimeCard') ap
 WHERE ap.approval_process_spec_fk = na.approval_process_spec_fk  
   AND na.approver_fk              = fw.firm_worker_id
 UNION
SELECT fw.never_null_person_fk AS user_id,   -- planned approvers part 2
       ap.approvable_id        AS timecard_id
  FROM firm_worker       AS OF SCN lego_refresh_mgr_pkg.get_scn() fw, 
       approval_activity AS OF SCN lego_refresh_mgr_pkg.get_scn() aa, 
       approval_process  AS OF SCN lego_refresh_mgr_pkg.get_scn() ap
 WHERE aa.approval_process_fk = ap.approval_process_id
   AND aa.approver_fk         = fw.firm_worker_id
   AND ap.approvable_type     = 'TimeCard'
   AND aa.activity_type       = 'ApproverTask'
 UNION
SELECT lmc.user_id,                          -- timecard managed cac
       lmc.timecard_id
  FROM }' || lv_timecard_managed_cac_table || ' lmc';

  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => pi_refresh_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_SLOT_TIMECARD'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_SLOT_TIMECARD'));

  END load_lego_slot_timecard;

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_secure_inv_assgnmt (pi_refresh_table_name IN VARCHAR2)
    AS
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_secure_inv_assgnmt
    || AUTHOR               : Paul Muller
    || DATE CREATED         : July 22nd, 2014
    || PURPOSE              : This procedure creates lego_secure_inv_assgnmt
    || MODIFICATION HISTORY : 07/22/2014 - pmuller - initial build (converted from SQL TOGGLE. 12.1.2)
    \*---------------------------------------------------------------------------*/

    lv_assignment_base_table  VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_SLOT_ASSIGNMENT');
    lv_sql                    VARCHAR2(4000) := 'SELECT lsa.user_id, lsa.assignment_id 
  FROM ' || lv_assignment_base_table || ' lsa
 UNION ALL                                                 -- Adding a -1 row for each person.
SELECT DISTINCT person_fk AS user_id, -1 AS assignment_id  -- This will allow invoice slot security joins to work.
  FROM iq_user AS OF SCN lego_refresh_mgr_pkg.get_scn()
 ORDER BY 1';

  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => pi_refresh_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_SECURE_INV_ASSGNMT'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_SECURE_INV_ASSGNMT'));
  
  END load_lego_secure_inv_assgnmt;
  
  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_secure_inv_prj_agr (pi_refresh_table_name IN VARCHAR2)
    AS
    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_secure_inv_prj_agr
    || AUTHOR               : Paul Muller
    || DATE CREATED         : July 22nd, 2014
    || PURPOSE              : This procedure creates lego_secure_inv_prj_agr
    || MODIFICATION HISTORY : 07/22/2014 - pmuller - initial build (converted from SQL TOGGLE. 12.1.2)
    \*---------------------------------------------------------------------------*/

    lv_proj_agg_base_table  VARCHAR2(30) := lego_util.most_recently_loaded_table(i_lego_name => 'LEGO_SLOT_PROJECT_AGREEMENT');
    lv_sql                  VARCHAR2(4000) := 'SELECT lspa.user_id, lspa.project_agreement_id 
  FROM ' || lv_proj_agg_base_table || ' lspa
 UNION ALL                                                 -- Adding a -1 row for each person.
SELECT DISTINCT person_fk AS user_id, -1 AS project_agreement_id  -- This will allow invoice slot security joins to work.
  FROM iq_user AS OF SCN lego_refresh_mgr_pkg.get_scn()
 ORDER BY 1';

  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name             => pi_refresh_table_name,
                              pi_stmt_clob              => lv_sql,
                              pi_partition_clause       => lego_util.get_partition_clause('LEGO_SECURE_INV_PRJ_AGR'),
                              pi_exadata_storage_clause => lego_util.get_exadata_storage_clause('LEGO_SECURE_INV_PRJ_AGR'));
  
  END load_lego_secure_inv_prj_agr;

END lego_slot_security;
/




