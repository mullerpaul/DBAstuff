CREATE OR REPLACE PACKAGE BODY lego_dashboard_refresh AS
/******************************************************************************
   NAME:       lego_dashboard_refresh
   PURPOSE:    Build tables and processes associated with the dashboards
               used by Falcon.

   REVISIONS:
   Jira       Date        Author         Description
   ---------  ----------  -------------  ------------------------------------
   IQN-29295  11/20/2015  Paul Muller    Created this package.
              04/22/2016  Paul Muller    modifications for mart
   IQN-32023  05/13/2016  Paul Muller    procedures for monthly assignment count & spend
   IQN-32025  08/05/2016  Paul Muller    overhaul org security model to match FO.
   IQN-33571  "           "              "
   IQN-34080  08/24/2016  Paul Muller    add ORDER BY to CMSA-level rollups to reduce avg_blocks_per_key for index
   IQN-34189  08/24/2016  Paul Muller    Add user_ID filter to two org rollup legos to reduce size.
   IQN-34465  09/19/2016  Paul Muller    Assignment count & spend by month to only count assignments billed in USD.
   IQN-34784  09/26/2016  Joe Pullifrone In month_assgn_list_spend_detail, renamed MV to buyer_invd_assign_spnd_mon_mv,
                                         which is the same as before, only it is a Fast Refresh MV now.
******************************************************************************/

  ----------------------------------------------------------------------------------
  PROCEDURE load_upcoming_ends_detail (pi_table_name  IN VARCHAR2,
                                       pi_source_name IN VARCHAR2,
                                       pi_source_scn  IN VARCHAR2) AS 

    /* This code builds a table holding detail-level data which will be used to:
        1. build highly summarized tables to blend with security data for dashboard consumption.
        2. provide a source of detail-level data for dashboard interactivity.   */

    lv_most_recent_ea_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_EA',
                                                                                  i_source_name => pi_source_name);
    lv_most_recent_ta_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_TA',
                                                                                  i_source_name => pi_source_name);
    lv_most_recent_wo_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_WO',
                                                                                  i_source_name => pi_source_name);
    
    lv_most_recent_person_table VARCHAR(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_PERSON',
                                                                                     i_source_name => pi_source_name);
    lv_most_recent_org_table    VARCHAR(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_BUS_ORG',
                                                                                     i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := q'{SELECT assignment_continuity_id, bo.bus_org_id, bo.bus_org_name AS buyer_org_name, 
       so.bus_org_name AS supplier_org_name, hmp.display_name AS hiring_manager_name, 
       assignment_start_dt, assignment_end_dt, job_category, days_until_assignment_end
  FROM (SELECT assignment_continuity_id, buyer_org_id, supplier_org_id,
               hiring_mgr_person_id, assignment_start_dt, assignment_end_dt, 
               NVL(jc_description, 'Undefined') AS job_category,  --does NOT use localized or custom names like lego_assignment_vw
               TRUNC(assignment_end_dt) - TRUNC(SYSDATE) AS days_until_assignment_end
          FROM }' || lv_most_recent_ea_table ||
    q'{  WHERE assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
           AND current_phase_type_id IN (4, 5)   -- working, offboarding - do we need this?
           AND assignment_end_dt BETWEEN TRUNC(SYSDATE-10) AND TRUNC(SYSDATE+30)
         UNION ALL
        SELECT assignment_continuity_id, buyer_org_id, supplier_org_id,
               hiring_mgr_person_id, assignment_start_dt, assignment_end_dt, 
               NVL(jc_description, 'Undefined') AS job_category,
               TRUNC(assignment_end_dt) - TRUNC(SYSDATE) AS days_until_assignment_end
          FROM }' || lv_most_recent_ta_table || 
    q'{  WHERE assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
           AND current_phase_type_id IN (4, 5)   -- working, offboarding - do we need this?
           AND assignment_end_dt BETWEEN TRUNC(SYSDATE-10) AND TRUNC(SYSDATE+30)
         UNION ALL
        SELECT assignment_continuity_id, buyer_org_id, supplier_org_id,
               hiring_mgr_person_id, assignment_start_dt, assignment_end_dt, 
               NVL(jc_description, 'Undefined') AS job_category,
               TRUNC(assignment_end_dt) - TRUNC(SYSDATE) AS days_until_assignment_end
          FROM }' || lv_most_recent_wo_table ||
    q'{  WHERE assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
           AND current_phase_type_id IN (4, 5)   -- working, offboarding - do we need this?
           AND assignment_end_dt BETWEEN TRUNC(SYSDATE-10) AND TRUNC(SYSDATE+30)) a, }' ||  
       lv_most_recent_org_table || ' bo, ' ||
       lv_most_recent_org_table || ' so, ' ||
       lv_most_recent_person_table || q'{ hmp
 WHERE a.buyer_org_id = bo.bus_org_id
   AND a.supplier_org_id = so.bus_org_id
   AND a.hiring_mgr_person_id = hmp.person_id(+)}';
 
  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_UPCOMING_ENDS_DETAIL', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_UPCOMING_ENDS_DETAIL',
                                 fi_source_name => pi_source_name));
       
  END load_upcoming_ends_detail;  
  
  ----------------------------------------------------------------------------------
  PROCEDURE load_upcoming_ends_row_rollup(pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2) AS
  
    lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_UPCOMING_ENDS_DETAIL',
                                                  i_source_name => pi_source_name);
    lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);
    lv_most_recent_row_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_ASSIGNMENT_ROW_SECURITY',
                                                  i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := q'{SELECT r.login_user_id, o.login_org_id, d.days_until_assignment_end, d.job_category, 
       COUNT(*) AS assignment_count
  FROM }' || lv_most_recent_detail_tab || ' d, ' ||
       lv_most_recent_row_sec_tab || ' r, ' ||
       lv_most_recent_org_sec_tab || q'{ o
 WHERE d.assignment_continuity_id = r.assignment_id
   AND d.bus_org_id = o.available_org_id
   AND r.login_user_id = o.login_user_id
 GROUP BY r.login_user_id, o.login_org_id, d.days_until_assignment_end, d.job_category}';
  
  BEGIN
    lego_refresh_mgr_pkg.ctas(pi_table_name       => pi_table_name,
                              pi_stmt_clob        => lv_sql,
                              pi_storage_clause   => lego_tools.get_storage_clause
                                                       (fi_object_name => 'LEGO_UPCOMING_ENDS_ROW_ROLLUP',
                                                        fi_source_name => pi_source_name),
                              pi_partition_clause => lego_tools.get_partition_clause
                                                       (fi_object_name => 'LEGO_UPCOMING_ENDS_ROW_ROLLUP',
                                                        fi_source_name => pi_source_name));
  
  END load_upcoming_ends_row_rollup;

  ----------------------------------------------------------------------------------
  PROCEDURE load_upcoming_ends_org_rollup(pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2) AS

    lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_UPCOMING_ENDS_DETAIL',
                                                  i_source_name => pi_source_name);
    lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := q'{WITH recent_dashboard_users
    AS (SELECT DISTINCT login_user_id 
          FROM appint.dashboard_api_calls 
         WHERE call_time_utc >= add_months(SYSDATE, -2)  --arbitrary limit
           AND login_user_id IS NOT NULL)
SELECT s.login_user_id, s.login_org_id, d.days_until_assignment_end, d.job_category, 
       COUNT(*) AS assignment_count
  FROM }' || lv_most_recent_detail_tab || ' d, ' ||
       lv_most_recent_org_sec_tab || q'{ s,
       recent_dashboard_users r
 WHERE s.available_org_id = d.bus_org_id
   AND s.login_user_id = r.login_user_id  -- limits users in table to keep it a reasonable size
 GROUP BY s.login_user_id, s.login_org_id, d.days_until_assignment_end, d.job_category}';
    
  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_UPCOMING_ENDS_ORG_ROLLUP', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_UPCOMING_ENDS_ORG_ROLLUP',
                                 fi_source_name => pi_source_name));
       
  END load_upcoming_ends_org_rollup;  

  ----------------------------------------------------------------------------------
  PROCEDURE load_req_by_status_detail (pi_table_name  IN VARCHAR2,
                                       pi_source_name IN VARCHAR2,
                                       pi_source_scn  IN VARCHAR2) AS
                                 
    lv_most_recent_job_table    VARCHAR(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_JOB',
                                                                                     i_source_name => pi_source_name);  
    lv_most_recent_person_table VARCHAR(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_PERSON',
                                                                                     i_source_name => pi_source_name);
    lv_most_recent_org_table    VARCHAR(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_BUS_ORG',
                                                                                     i_source_name => pi_source_name);
    lv_most_recent_jcl_table    VARCHAR(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_JAVA_CONSTANT_LOOKUP',
                                                                                     i_source_name => pi_source_name);

    lv_sql   VARCHAR2(4000) := q'{SELECT job_id, buyer_org_id,
       bo.bus_org_name AS buyer_org_name,
       hmp.display_name AS hiring_manager_name, 
       jc_description, job_state, job_created_date, 
       CAST(cp_jcl.constant_description AS VARCHAR2(20)) AS current_phase   --needed since JCL is defined as varchar2(4000) and that long length messes up IOTs
  FROM }' || lv_most_recent_org_table || ' bo, ' ||
       lv_most_recent_person_table || ' hmp, ' ||
       lv_most_recent_jcl_table || q'{ cp_jcl, 
       (SELECT job_id, buyer_org_id, hiring_mgr_person_id, jc_description, 
               job_state, job_created_date, phase_type_id 
          FROM }' || lv_most_recent_job_table ||
    q'{  WHERE phase_type_id NOT IN (6, 7)  -- completed, archived
           AND job_state_id <> 3  -- closed
           AND template_availability IS NULL) a  -- exclude job templates 
 WHERE a.buyer_org_id = bo.bus_org_id 
   AND a.hiring_mgr_person_id = hmp.person_id
   AND a.phase_type_id = cp_jcl.constant_value
   AND cp_jcl.constant_type = 'JOB_PHASE'
   AND cp_jcl.locale_fk = 'EN_US'}';  --hardcoded english phase names

  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_REQ_BY_STATUS_DETAIL', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_REQ_BY_STATUS_DETAIL',
                                 fi_source_name => pi_source_name));

  END load_req_by_status_detail;  

  ----------------------------------------------------------------------------------
  PROCEDURE load_req_by_status_row_rollup(pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2) AS

    lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_REQ_BY_STATUS_DETAIL',
                                                  i_source_name => pi_source_name);
    lv_most_recent_row_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_JOB_ROW_SECURITY',
                                                  i_source_name => pi_source_name);
    lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);
    lv_sql VARCHAR2(4000) := q'{SELECT r.login_user_id, o.login_org_id, d.current_phase, d.jc_description, 
       COUNT(*) AS requisition_count
  FROM }' || lv_most_recent_detail_tab || ' d, ' ||
       lv_most_recent_row_sec_tab || ' r, ' || 
       lv_most_recent_org_sec_tab || q'{ o
 WHERE d.job_id = r.job_id
   AND d.buyer_org_id = o.available_org_id
   AND r.login_user_id = o.login_user_id
 GROUP BY r.login_user_id, o.login_org_id, d.current_phase, d.jc_description}';

  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_REQ_BY_STATUS_ROW_ROLLUP', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_REQ_BY_STATUS_ROW_ROLLUP',
                                 fi_source_name => pi_source_name));
       
  END load_req_by_status_row_rollup;  

  ----------------------------------------------------------------------------------
  PROCEDURE load_req_by_status_org_rollup(pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2) AS

    lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_REQ_BY_STATUS_DETAIL',
                                                  i_source_name => pi_source_name);
    lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := q'{SELECT s.login_user_id, s.login_org_id, d.current_phase, d.jc_description,
       COUNT(*) AS requisition_count
  FROM }' || lv_most_recent_detail_tab || ' d, ' || 
       lv_most_recent_org_sec_tab || q'{ s
 WHERE s.available_org_id = d.buyer_org_id
 GROUP BY s.login_user_id, s.login_org_id, d.current_phase, d.jc_description}';

  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_REQ_BY_STATUS_ORG_ROLLUP', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_REQ_BY_STATUS_ORG_ROLLUP',
                                 fi_source_name => pi_source_name));
       
  END load_req_by_status_org_rollup;  
  
  ----------------------------------------------------------------------------------
  PROCEDURE load_monthly_assignment_list (pi_table_name  IN VARCHAR2,
                                          pi_source_name IN VARCHAR2,
                                          pi_source_scn  IN VARCHAR2) AS 

    lv_most_recent_ea_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_EA',
                                                                                  i_source_name => pi_source_name);
    lv_most_recent_ta_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_TA',
                                                                                  i_source_name => pi_source_name);
    lv_most_recent_wo_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_WO',
                                                                                  i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := q'{  WITH month_list  -- list of months from Jan of previous year to now.  between 13 and 24 rows.
    AS (SELECT trunc(add_months(sysdate, -1 * (LEVEL-1)), 'MM')     AS month_start,
               trunc(add_months(sysdate, -1 * (LEVEL-1) + 1), 'MM') AS month_end
          FROM dual
       CONNECT BY LEVEL <= 1 + months_between(TRUNC(SYSDATE, 'MM'), TRUNC(add_months(SYSDATE, -12), 'YY'))),
       assignment_list
    AS (SELECT assignment_continuity_id, buyer_org_id, assignment_start_dt, assignment_actual_end_dt
          FROM }' || lv_most_recent_ea_table || q'{
         WHERE assignment_state_id <> 6  -- get rid of this? or not?  possible also add filter on ever_been_active
           AND assignment_actual_end_dt >= TRUNC(add_months(SYSDATE, -12), 'YYYY') -- ended or will end AFTER Jan-01 last years ago.
           AND assignment_start_dt < TRUNC(add_months(SYSDATE, 1), 'MONTH')       -- started or will start before the beginning of next month
         UNION ALL
        SELECT assignment_continuity_id, buyer_org_id, assignment_start_dt, assignment_actual_end_dt
          FROM }' || lv_most_recent_ta_table || q'{
         WHERE assignment_state_id <> 6  -- get rid of this? or not?  possible also add filter on ever_been_active
           AND assignment_actual_end_dt >= TRUNC(add_months(SYSDATE, -12), 'YYYY') -- ended or will end AFTER Jan-01 last years ago.
           AND assignment_start_dt < TRUNC(add_months(SYSDATE, 1), 'MONTH')       -- started or will start before the beginning of next month           
         UNION ALL   
        SELECT assignment_continuity_id, buyer_org_id, assignment_start_dt, assignment_actual_end_dt
          FROM }' || lv_most_recent_wo_table || q'{
         WHERE assignment_state_id <> 6  -- get rid of this? or not?  possible also add filter on ever_been_active
           AND assignment_actual_end_dt >= TRUNC(add_months(SYSDATE, -12), 'YYYY') -- ended or will end AFTER Jan-01 last years ago.
           AND assignment_start_dt < TRUNC(add_months(SYSDATE, 1), 'MONTH'))       -- started or will start before the beginning of next month           
SELECT a.assignment_continuity_id, a.buyer_org_id, m.month_start 
  FROM month_list m,
       assignment_list a
 WHERE m.month_start <= a.assignment_actual_end_dt
   AND m.month_end > a.assignment_start_dt}';
    
  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_MONTHLY_ASSIGNMENT_LIST', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_MONTHLY_ASSIGNMENT_LIST',
                                 fi_source_name => pi_source_name));

  END load_monthly_assignment_list;  
                                           
  ----------------------------------------------------------------------------------
  PROCEDURE month_assgn_list_spend_detail (pi_table_name  IN VARCHAR2,
                                           pi_source_name IN VARCHAR2,
                                           pi_source_scn  IN VARCHAR2) AS 

    /* Changed from outer to inner join for IQN-34465.  But after making that change, I realized this lego
       doesn't even need LEGO_MONTHLY_ASSIGNMENTS anymore, so I removed it and now there is no join at all!
       That lego contains info about how many assignments WERE ACTIVE in that month; but for a syncronized line
       graph, both attributes should be measured over the same set of assignments.  So we are now counting how
       many assignments WERE INVOICED in a month instead of how many WERE ACTIVE.  */

    /*  We may later want to add more detail to this table so it can serve as a source for later
        tabular request from API.  Join to org & person legos. */
           
    lv_sql VARCHAR2(4000) := q'{SELECT assignment_continuity_id,
       buyer_org_id,
       invoice_month_date          AS month_start,
       buyer_invd_assign_spend_amt AS invoiced_spend_per_month
  FROM buyer_invd_assign_spnd_mon_mv
 WHERE invoice_month_date >= TRUNC(add_months(SYSDATE, -12), 'MM') -- rolling 12 months window
   AND currency = 'USD'   -- only USD for now
   AND source_name = '}' || pi_source_name || '''';

  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_MNTH_ASSGN_LIST_SPEND_DET', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_MNTH_ASSGN_LIST_SPEND_DET',
                                 fi_source_name => pi_source_name));

  END month_assgn_list_spend_detail;  
  
  ----------------------------------------------------------------------------------
  PROCEDURE month_asgn_cnt_spnd_row_rollup (pi_table_name  IN VARCHAR2,
                                            pi_source_name IN VARCHAR2,
                                            pi_source_scn  IN VARCHAR2) AS 
  
  lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_MNTH_ASSGN_LIST_SPEND_DET',
                                                  i_source_name => pi_source_name);
  lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);
  lv_most_recent_row_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_ASSIGNMENT_ROW_SECURITY',
                                                  i_source_name => pi_source_name);

  lv_sql VARCHAR2(4000) := q'{SELECT r.login_user_id, o.login_org_id, d.month_start,
       COUNT(*) AS monthly_assignment_count,
       SUM(d.invoiced_spend_per_month) AS monthly_invoiced_buyer_spend
  FROM }' || lv_most_recent_detail_tab || ' d, ' ||
       lv_most_recent_row_sec_tab || ' r, ' ||
       lv_most_recent_org_sec_tab || q'{ o
 WHERE d.assignment_continuity_id = r.assignment_id
   AND d.buyer_org_id = o.available_org_id
   AND r.login_user_id = o.login_user_id
 GROUP BY r.login_user_id, o.login_org_id, d.month_start}';

  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_MNTH_ASGN_CNTSPND_ROWROLL', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_MNTH_ASGN_CNTSPND_ROWROLL',
                                 fi_source_name => pi_source_name));

  END month_asgn_cnt_spnd_row_rollup;                                 
    
  ----------------------------------------------------------------------------------
  PROCEDURE month_asgn_cnt_spnd_org_rollup (pi_table_name  IN VARCHAR2,
                                            pi_source_name IN VARCHAR2,
                                            pi_source_scn  IN VARCHAR2) AS 
  
    lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_MNTH_ASSGN_LIST_SPEND_DET',
                                                  i_source_name => pi_source_name);
    lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := q'{WITH recent_dashboard_users
    AS (SELECT DISTINCT login_user_id
          FROM appint.dashboard_api_calls
         WHERE call_time_utc >= add_months(SYSDATE, -2) --arbitrary cutoff
           AND login_user_id IS NOT NULL)
SELECT s.login_user_id, s.login_org_id, d.month_start,
       COUNT(*) AS monthly_assignment_count,
       SUM(d.invoiced_spend_per_month) AS monthly_invoiced_buyer_spend
  FROM }' || lv_most_recent_detail_tab || ' d, ' ||
       lv_most_recent_org_sec_tab || q'{ s,
       recent_dashboard_users r
 WHERE s.available_org_id = d.buyer_org_id
   AND s.login_user_id = r.login_user_id  -- limits users in table to keep it a reasonable size
 GROUP BY s.login_user_id, s.login_org_id, d.month_start}';

  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_MNTH_ASGN_CNTSPND_ORGROLL', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_MNTH_ASGN_CNTSPND_ORGROLL',
                                 fi_source_name => pi_source_name));

  END month_asgn_cnt_spnd_org_rollup;                                 

  ----------------------------------------------------------------------------------
  PROCEDURE load_assgn_atom_detail(pi_table_name  IN VARCHAR2,
                                   pi_source_name IN VARCHAR2,
                                   pi_source_scn  IN VARCHAR2) AS
                                     
    lv_most_recent_ea_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_EA',
                                                                                  i_source_name => pi_source_name);
    lv_most_recent_ta_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_TA',
                                                                                  i_source_name => pi_source_name);
    lv_most_recent_wo_table VARCHAR2(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_WO',
                                                                                  i_source_name => pi_source_name);
    lv_most_recent_person_table VARCHAR(30) := lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_PERSON',
                                                                                     i_source_name => pi_source_name);                                                                                  
    lv_sql VARCHAR2(4000) := q'{
    WITH assgn_per AS(   
      SELECT assgn.buyer_org_id, assgn.supplier_org_id, assgn.assignment_continuity_id,
             assgn.hiring_mgr_person_id, cp.display_name AS contractor_name, 
             hmp.display_name AS hiring_manager_name, assgn.assignment_type, assgn.assignment_start_dt, 
             assgn.assignment_end_dt, assgn.assignment_actual_end_dt, assgn.assignment_duration, 
             assgn.approval_state, assgn.assignment_state_id, assgn.sourcing_method, 
             assgn.assign_requisition_type, assgn.current_phase_type_id
        FROM }' || lv_most_recent_person_table || q'{ cp,
             }' || lv_most_recent_person_table || q'{ hmp,
            (SELECT buyer_org_id, supplier_org_id, assignment_continuity_id, hiring_mgr_person_id,
                     contractor_person_id, assignment_type, assignment_start_dt, assignment_end_dt, 
                     assignment_actual_end_dt, assignment_duration, approval_state, assignment_state_id, 
                     sourcing_method, assign_requisition_type, current_phase_type_id
                FROM }' || lv_most_recent_wo_table || q'{ 
              UNION ALL
              SELECT buyer_org_id, supplier_org_id, assignment_continuity_id, hiring_mgr_person_id,
                     contractor_person_id, assignment_type, assignment_start_dt, assignment_end_dt, 
                     assignment_actual_end_dt, assignment_duration, approval_state, assignment_state_id, 
                     sourcing_method, assign_requisition_type, current_phase_type_id
                FROM }' || lv_most_recent_ea_table || q'{ 
             UNION ALL
             SELECT buyer_org_id, supplier_org_id, assignment_continuity_id, hiring_mgr_person_id,
                    contractor_person_id, assignment_type, assignment_start_dt, assignment_end_dt, 
                    assignment_actual_end_dt, assignment_duration, approval_state, assignment_state_id, 
                    sourcing_method, assign_requisition_type, current_phase_type_id
               FROM }' || lv_most_recent_ta_table || q'{) assgn
       WHERE assgn.contractor_person_id     = cp.person_id
         AND assgn.hiring_mgr_person_id     = hmp.person_id) 
  
      SELECT assgn_per.buyer_org_id, assgn_per.supplier_org_id, assgn_per.assignment_continuity_id,
             assgn_per.hiring_mgr_person_id, assgn_per.contractor_name, assgn_per.hiring_manager_name,
             assgn_per.assignment_type, assgn_per.assignment_start_dt, assgn_per.assignment_end_dt,
             assgn_per.assignment_actual_end_dt, assgn_per.assignment_duration, assgn_per.approval_state,
             assgn_per.assignment_state_id, assgn_per.sourcing_method, assgn_per.assign_requisition_type,
             assgn_per.current_phase_type_id, ap.std_buyerorg_name, ap.std_supplierorg_name,               
             ap.std_state, ap.std_city, ap.std_country, ap.std_postal_code, ap.std_region, 
             ap.cmsa_name, ap.metro_name, ap.cmsa_primary_state_code, ap.cmsa_primary_city_name, 
             ap.cmsa_primary_city_lat, ap.cmsa_primary_city_long, ajtc.std_job_title_desc,
             ajtc.std_job_category_desc
        FROM iqprodm.dm_atom_place ap,
             iqprodm.dm_atom_job_title_cat ajtc,
             assgn_per
       WHERE assgn_per.assignment_continuity_id = ap.assignment_continuity_id
         AND ap.data_source_code                = DECODE('}' || pi_source_name || q'{','USPROD','REGULAR','WFPROD','WACHOVIA',NULL)
         AND assgn_per.assignment_continuity_id = ajtc.assignment_continuity_id
         AND ajtc.data_source_code              = DECODE('}' || pi_source_name || q'{','USPROD','REGULAR','WFPROD','WACHOVIA',NULL) }';
    
  BEGIN
  
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_ASSGN_ATOM_DETAIL', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_ASSGN_ATOM_DETAIL',
                                 fi_source_name => pi_source_name));  
  
  END load_assgn_atom_detail;
  
  ----------------------------------------------------------------------------------
  PROCEDURE assgn_loc_cmsa_atom_or(pi_table_name  IN VARCHAR2,
                                   pi_source_name IN VARCHAR2,
                                   pi_source_scn  IN VARCHAR2) AS

    lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_ASSGN_ATOM_DETAIL',
                                                  i_source_name => pi_source_name);
    lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := 
    q'{SELECT COUNT(*) AS effective_assgn_count, 
              s.login_org_id, s.login_user_id, aad.cmsa_name, aad.metro_name, aad.cmsa_primary_state_code, 
              aad.cmsa_primary_city_name, aad.cmsa_primary_city_lat, aad.cmsa_primary_city_long
         FROM }' || lv_most_recent_detail_tab ||' aad, ' ||
              lv_most_recent_org_sec_tab || q'{ s        
        WHERE s.available_org_id = aad.buyer_org_id
          AND aad.assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
          AND aad.current_phase_type_id IN (4, 5)   -- working, offboarding
        GROUP BY s.login_org_id, s.login_user_id, aad.cmsa_name, aad.metro_name, aad.cmsa_primary_state_code, 
                 aad.cmsa_primary_city_name, aad.cmsa_primary_city_lat, aad.cmsa_primary_city_long
        ORDER BY s.login_user_id, s.login_org_id}';  -- order by to reduce avg_table_blocks_per_key of index
    
  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_ASSGN_LOC_CMSA_ATOM_OR', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_ASSGN_LOC_CMSA_ATOM_OR',
                                 fi_source_name => pi_source_name));
       
  END assgn_loc_cmsa_atom_or;  
  
  ----------------------------------------------------------------------------------
  PROCEDURE assgn_loc_st_atom_or(pi_table_name  IN VARCHAR2,
                                 pi_source_name IN VARCHAR2,
                                 pi_source_scn  IN VARCHAR2) AS

    lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_ASSGN_ATOM_DETAIL',
                                                  i_source_name => pi_source_name);
    lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := 
    q'{SELECT s.login_org_id, s.login_user_id, aad.cmsa_primary_state_code, COUNT(*) AS effective_assgn_count
         FROM }' || lv_most_recent_detail_tab ||' aad, ' ||
              lv_most_recent_org_sec_tab || q'{ s        
        WHERE s.available_org_id = aad.buyer_org_id
          AND aad.assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
          AND aad.current_phase_type_id IN (4, 5)   -- working, offboarding
        GROUP BY s.login_org_id, s.login_user_id, aad.cmsa_primary_state_code}';
    
  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_ASSGN_LOC_ST_ATOM_OR', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_ASSGN_LOC_ST_ATOM_OR',
                                 fi_source_name => pi_source_name));
       
  END assgn_loc_st_atom_or;  

  ----------------------------------------------------------------------------------
  PROCEDURE assgn_loc_st_atom_rr(pi_table_name  IN VARCHAR2,
                                 pi_source_name IN VARCHAR2,
                                 pi_source_scn  IN VARCHAR2) AS

    lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_ASSGN_ATOM_DETAIL',
                                                  i_source_name => pi_source_name);
    lv_most_recent_row_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_ASSIGNMENT_ROW_SECURITY',
                                                  i_source_name => pi_source_name);
    lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := 
    q'{SELECT r.login_user_id, o.login_org_id, aad.cmsa_primary_state_code,
       COUNT(*) AS effective_assgn_count
  FROM }' || lv_most_recent_detail_tab || ' aad, ' || 
       lv_most_recent_row_sec_tab || ' r, ' ||
       lv_most_recent_org_sec_tab || q'{ o
 WHERE aad.assignment_continuity_id = r.assignment_id
   AND aad.buyer_org_id = o.available_org_id
   AND r.login_user_id = o.login_user_id
   AND aad.assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
   AND aad.current_phase_type_id IN (4, 5)   -- working, offboarding
 GROUP BY r.login_user_id, o.login_org_id, aad.cmsa_primary_state_code}';
    
  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_ASSGN_LOC_ST_ATOM_RR', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_ASSGN_LOC_ST_ATOM_RR',
                                 fi_source_name => pi_source_name));
       
  END assgn_loc_st_atom_rr;  

  ----------------------------------------------------------------------------------
  PROCEDURE assgn_loc_cmsa_atom_rr(pi_table_name  IN VARCHAR2,
                                   pi_source_name IN VARCHAR2,
                                   pi_source_scn  IN VARCHAR2) AS

    lv_most_recent_detail_tab  VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_ASSGN_ATOM_DETAIL',
                                                  i_source_name => pi_source_name);
    lv_most_recent_row_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_ASSIGNMENT_ROW_SECURITY',
                                                  i_source_name => pi_source_name);
    lv_most_recent_org_sec_tab VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                 (i_lego_name   => 'LEGO_PERSON_AVAILABLE_ORG',
                                                  i_source_name => pi_source_name);

    lv_sql VARCHAR2(4000) := 
    q'{SELECT COUNT(*) AS effective_assgn_count, 
       r.login_user_id, o.login_org_id, aad.cmsa_name, aad.metro_name, aad.cmsa_primary_state_code, 
       aad.cmsa_primary_city_name, aad.cmsa_primary_city_lat, aad.cmsa_primary_city_long
  FROM }' || lv_most_recent_detail_tab || ' aad, ' || 
       lv_most_recent_row_sec_tab || ' r, ' || 
       lv_most_recent_org_sec_tab || q'{ o
 WHERE aad.assignment_continuity_id = r.assignment_id
   AND aad.buyer_org_id = o.available_org_id
   AND r.login_user_id = o.login_user_id
   AND aad.assignment_state_id IN (3, 8, 9)  -- awaiting start date, effective, effective onboard
   AND aad.current_phase_type_id IN (4, 5)   -- working, offboarding
 GROUP BY r.login_user_id, o.login_org_id, aad.cmsa_name, aad.metro_name, aad.cmsa_primary_state_code, 
          aad.cmsa_primary_city_name, aad.cmsa_primary_city_lat, aad.cmsa_primary_city_long
 ORDER BY r.login_user_id, o.login_org_id}';  -- order by to reduce avg_table_blocks_per_key of index
    
  BEGIN
    lego_refresh_mgr_pkg.ctas
      (pi_table_name       => pi_table_name,
       pi_stmt_clob        => lv_sql,
       pi_storage_clause   => lego_tools.get_storage_clause
                                (fi_object_name => 'LEGO_ASSGN_LOC_CMSA_ATOM_RR', 
                                 fi_source_name => pi_source_name),
       pi_partition_clause => lego_tools.get_partition_clause
                                (fi_object_name => 'LEGO_ASSGN_LOC_CMSA_ATOM_RR',
                                 fi_source_name => pi_source_name));
       
  END assgn_loc_cmsa_atom_rr;    
  
END lego_dashboard_refresh;
/
