CREATE OR REPLACE PACKAGE BODY lego_tenure AS
  /******************************************************************************
     NAME:       lego_tenure
     PURPOSE:    Build tables and processes associated with the Tenure legos
  
     REVISIONS:
     Jira       Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
                03/14/2016  Paul Muller      Created this package.
     
  ******************************************************************************/

  ----------------------------------------------------------------------------------
  PROCEDURE drop_table(pi_table_name IN VARCHAR2) AS
    le_table_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_table_not_exist, -00942);
    
  BEGIN
    EXECUTE IMMEDIATE ('drop table ' || pi_table_name || ' purge');
    logger_pkg.debug('dropped table ' || pi_table_name);

  EXCEPTION
    WHEN le_table_not_exist
      THEN NULL;

  END drop_table;      

  ----------------------------------------------------------------------------------
  PROCEDURE make_table_grants(pi_table_name IN VARCHAR2) AS
    
  BEGIN
    EXECUTE IMMEDIATE('grant select on ' || pi_table_name || 
                      ' to ro_iqprodm');   -- add other schemas/roles here
  EXCEPTION
    WHEN OTHERS
      THEN NULL;

  END make_table_grants;      

  ----------------------------------------------------------------------------------
  PROCEDURE load_lego_tenure(pi_refresh_table_name IN VARCHAR2,
                             pi_source_name        IN VARCHAR2,
                             pi_source_scn         IN VARCHAR2) AS

    /*---------------------------------------------------------------------------*\
    || PROCEDURE NAME       : load_lego_tenure
    || AUTHOR               : Paul Muller
    || DATE CREATED         : January 7th, 2014
    || PURPOSE              : This procedure creates the tenure lego.
    || MODIFICATION HISTORY : 01/07/2014 - pmuller - initial build.
    ||                      : 04/14/2014 - pmuller - replace code with call to get_exadata_storage_clase function.
    ||                      : 09/17/2015 - pmuller - added logic to compute EARILEST_DATE in cases where clients 
    ||                      :                        specified tenure limits in units of MONTHs.  IQN-28519
    ||                      : 03/14/2016 - pmuller - moved to a new package.  Also modified for multiple sources.
    \*---------------------------------------------------------------------------*/
  
    TYPE lt_object_array IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
    la_table lt_object_array;
    
    TYPE lt_sql_array  IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;
    la_sql lt_sql_array;
    
    lv_final_storage_clause        lego_refresh.storage_clause%TYPE;
    lv_intermediate_storage_clause lego_refresh.storage_clause%TYPE;

    lv_source_short_name           VARCHAR2(10);
    lv_db_link_name                lego_source.db_link_name%TYPE;
    lv_debug_flag                  BOOLEAN;
    lv_bus_org_table               VARCHAR2(30) := lego_tools.most_recently_loaded_table
                                                     (i_lego_name => 'LEGO_BUS_ORG', 
                                                      i_source_name => pi_source_name);
  BEGIN
    /* I suspect that this is not returning correct results in cases where (tenure limit + gap time)
       is more than 5 years.  This is due to the hardcoded 5 year limit in a few queries below.  I
       think thats OK since most tenure settings are MUCH less than 5 years, and the ones that aren't
       are probably just misconfigured. */
       
    /* Get the short name and link name of the source.  
       We will be plaing these values into all intermediate table names and create SQL. */   
    SELECT '_' || source_name_short, db_link_name
      INTO lv_source_short_name, lv_db_link_name
      FROM lego_source
     WHERE source_name = pi_source_name;  
       
    /* Get the exadata storage clause for the final lego table. */
    lv_final_storage_clause := lego_tools.get_storage_clause(fi_object_name => 'LEGO_TENURE', 
                                                             fi_source_name => pi_source_name);
                                                             
    /* Given the final storage clause, create a storage clause for intermediate tables.
       We don't want any exadata type clauses here. */                                                             
    lv_intermediate_storage_clause := REPLACE(lv_final_storage_clause,'STORAGE (CELL_FLASH_CACHE KEEP)'); 

    /* get the debug parameter value */
    lv_debug_flag := NVL(lego_tools.get_lego_parameter_text_value('lego_tenure_debugging_flag'), 'OFF') = 'ON';
         
    /* Initialize an array of temp table names, and a parallel array of SQL to create those tables.
       Later we'll loop over these arrays, creating each table in turn. */
    la_table(1) := 'TEMP_FIRM_SETTINGS';
    la_sql(1) := q'{SELECT business_org_fk AS business_organization_id,
       track_con_time_limits,
       con_include_service_gaps,
       con_time_lmt_thrshold,
       con_time_lmt_thrshold_days_rmn,
       time_limit_in_days,
       time_limit_in_months,
       time_limit_gap_in_days,
       time_limit_gap_in_months,
       CASE 
         WHEN time_limit_in_days IS NOT NULL AND time_limit_gap_in_days IS NOT NULL AND time_limit_in_months IS     NULL AND time_limit_gap_in_months IS     NULL 
           THEN TRUNC(add_months(SYSDATE, -1)) - (time_limit_in_days + time_limit_gap_in_days)
         WHEN time_limit_in_days IS     NULL AND time_limit_gap_in_days IS     NULL AND time_limit_in_months IS NOT NULL AND time_limit_gap_in_months IS NOT NULL 
           THEN TRUNC(add_months(SYSDATE, -1 * (1 + time_limit_in_months + time_limit_gap_in_months)))
         WHEN time_limit_in_days IS     NULL AND time_limit_gap_in_days IS NOT NULL AND time_limit_in_months IS NOT NULL AND time_limit_gap_in_months IS     NULL 
           THEN TRUNC(add_months(SYSDATE, -1 * (1 + time_limit_in_months))) - time_limit_gap_in_days
         WHEN time_limit_in_days IS NOT NULL AND time_limit_gap_in_days IS     NULL AND time_limit_in_months IS     NULL AND time_limit_gap_in_months IS NOT NULL 
           THEN TRUNC(add_months(SYSDATE, -1 * (1 + time_limit_gap_in_months))) - time_limit_in_days
         ELSE to_date(NULL)
       END AS earliest_date   --some orgs are back in Apr-2007!  check back on this.
  FROM (SELECT fr.business_org_fk,
               bf.track_con_time_limits,
               bf.con_include_service_gaps,
               bf.con_time_lmt_thrshold,
               bf.con_time_lmt_thrshold_days_rmn,
               CASE 
                 WHEN bf.con_time_limit_unit = 3
                   THEN bf.con_time_limit
                 WHEN bf.con_time_limit_unit = 4
                   THEN bf.con_time_limit * 7
                 WHEN bf.con_time_limit_unit = 5
                   THEN to_number(NULL)  --add_months(sysdate,bf.con_time_limit) - SYSDATE
                 ELSE -1    
               END AS time_limit_in_days,
               CASE 
                 WHEN bf.con_time_limit_unit = 5
                   THEN bf.con_time_limit
                 ELSE NULL    
               END AS time_limit_in_months,
               CASE 
                 WHEN bf.con_time_limit_gap_unit = 3
                   THEN bf.con_time_limit_gap
                 WHEN bf.con_time_limit_gap_unit = 4
                   THEN bf.con_time_limit_gap * 7
                 WHEN bf.con_time_limit_gap_unit = 5
                   THEN to_number(NULL)  --add_months(SYSDATE, bf.con_time_limit_gap) - SYSDATE
                 ELSE -1    
               END AS time_limit_gap_in_days,
               CASE 
                 WHEN bf.con_time_limit_gap_unit = 5
                   THEN bf.con_time_limit_gap
                 ELSE NULL    
               END AS time_limit_gap_in_months
          FROM buyer_firm@db_link_name AS OF SCN source_db_SCN bf,
               firm_role@db_link_name AS OF SCN source_db_SCN fr
         WHERE bf.firm_id = fr.firm_id
           AND bf.track_con_time_limits = 1
           AND fr.business_org_fk NOT IN (26376,51467,25156))  -- these orgs have valid but nonsensical data.  No results for them!
 WHERE (time_limit_in_days     IS NULL OR time_limit_in_days     != -1)    -- filter out invalid data
   AND (time_limit_gap_in_days IS NULL OR time_limit_gap_in_days != -1)}';
    
    la_table(2) := 'TEMP_ASSIGNMENTS';
    la_sql(2) := 'SELECT la.buyer_org_id, 
       fs.con_time_lmt_thrshold, fs.con_time_lmt_thrshold_days_rmn, fs.time_limit_in_days,
       fs.time_limit_in_months, fs.time_limit_gap_in_days, fs.time_limit_gap_in_months, 
       fs.earliest_date, la.assignment_continuity_id, la.candidate_id, la.job_id, 
       la.assignment_start_dt, la.assignment_actual_end_dt, la.assignment_end_dt
  FROM (SELECT assignment_continuity_id, buyer_org_id, candidate_id, job_id, 
               assignment_start_dt, assignment_actual_end_dt, assignment_end_dt          
          FROM ' || lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_WO', i_source_name => pi_source_name) || 
       ' UNION ALL
        SELECT assignment_continuity_id, buyer_org_id, candidate_id, job_id, 
               assignment_start_dt, assignment_actual_end_dt, assignment_end_dt
          FROM ' || lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_EA', i_source_name => pi_source_name) ||
       ' UNION ALL
        SELECT assignment_continuity_id, buyer_org_id, candidate_id, job_id, 
               assignment_start_dt, assignment_actual_end_dt, assignment_end_dt
          FROM ' ||  lego_tools.most_recently_loaded_table(i_lego_name => 'LEGO_ASSIGNMENT_TA', i_source_name => pi_source_name) || ') la, ' ||
     ' temp_firm_settings' || lv_source_short_name || ' fs
 WHERE fs.business_organization_id = la.buyer_org_id
   AND la.candidate_id IS NOT NULL
   AND (la.assignment_start_dt >= fs.earliest_date OR    -- only assignments with at least some time since the "earliest_date"
        la.assignment_actual_end_dt >= fs.earliest_date OR
        la.assignment_end_dt >= fs.earliest_date)';
    
    la_table(3) := 'TEMP_RELATED_CANDIDATES';
    la_sql(3) := q'{SELECT DISTINCT 
       a.candidate_id   AS candidate_id, 
       a.buyer_org_id   AS assignment_buyer_org, --increases cardinality, but we need this to join candidate-based data to firm_settings later.
       c2.candidate_id  AS related_candidate_id  
  FROM temp_assignments}' || lv_source_short_name || q'{ a,
       candidate@db_link_name AS OF SCN source_db_SCN c1, 
       candidate@db_link_name AS OF SCN source_db_SCN c2,
       assignment_continuity@db_link_name AS OF SCN source_db_SCN ac1, 
       assignment_continuity@db_link_name AS OF SCN source_db_SCN ac2,
       firm_role@db_link_name AS OF SCN source_db_SCN fr1, 
       firm_role@db_link_name AS OF SCN source_db_SCN fr2, }' ||
       lv_bus_org_table || ' lbo1, ' ||
       lv_bus_org_table || ' lbo2 ' ||
q'{ WHERE a.candidate_id = c1.candidate_id 
   AND c1.candidate_id = ac1.candidate_fk
   AND ac1.owning_buyer_firm_fk = fr1.firm_id   -- should be supply firm?
   AND fr1.business_org_fk = lbo1.bus_org_id
   AND lbo1.enterprise_bus_org_id = lbo2.enterprise_bus_org_id  
   AND lbo2.bus_org_id = fr2.business_org_fk
   AND fr2.firm_id = ac2.owning_buyer_firm_fk   -- should be supply firm?
   AND ac2.candidate_fk = c2.candidate_id
   AND c1.fed_id = c2.fed_id
   AND c1.fed_id_type_fk = c2.fed_id_type_fk
   AND lbo1.bus_org_type = 'Buyer'
   AND lbo2.bus_org_type = 'Buyer'}';
    
    la_table(4) := 'TEMP_PAST_ASSIGNMENTS';
    la_sql(4) := q'{SELECT rc.candidate_id,         --needed for later rollup by candidate_id
       rc.assignment_buyer_org, --needed for later join to firm_settings.
       rc.related_candidate_id,
       pa.assignment_continuity_id,
       pa.start_date,
       pa.end_date
  FROM temp_related_candidates}' || lv_source_short_name || q'{ rc,
       (SELECT ac.candidate_fk, 
               ac.assignment_continuity_id,
               ald.valid_from                       AS start_date, 
               ald.valid_to                         AS end_date
          FROM assignment_continuity@db_link_name AS OF SCN source_db_SCN ac,
               assignment_edition@db_link_name AS OF SCN source_db_SCN ae,
               assignment_state@db_link_name AS OF SCN source_db_SCN state,
               assignment_line_detail@db_link_name AS OF SCN source_db_SCN ald
         WHERE ae.assignment_edition_id = ac.current_edition_fk
           AND ae.assignment_continuity_fk = ac.assignment_continuity_id
           AND state.value = ae.assignment_state_fk
           AND ald.assignment_edition_fk = ae.assignment_edition_id
           AND state.type IN
               ('AssignmentAwaitingStartDateState',
                'AssignmentCompletedState',
                'AssignmentEffectiveState',
                'AssignmentTerminatedState')
           AND ald.valid_from < SYSDATE
         UNION ALL
        SELECT ac.candidate_fk, 
               ac.assignment_continuity_id,
               pt.start_date                        AS start_date,
               NVL(ae.actual_end_date, pt.end_date) AS end_date
          FROM performance_term@db_link_name AS OF SCN source_db_SCN pt,
               contract_term@db_link_name AS OF SCN source_db_SCN ct,
               contract_version@db_link_name AS OF SCN source_db_SCN cv,
               work_order_version@db_link_name AS OF SCN source_db_SCN wov,
               work_order@db_link_name AS OF SCN source_db_SCN wo,
               assignment_continuity@db_link_name AS OF SCN source_db_SCN ac,
               assignment_edition@db_link_name AS OF SCN source_db_SCN ae,
               assignment_state@db_link_name AS OF SCN source_db_SCN state
         WHERE ct.contract_term_id = pt.contract_term_id
           AND cv.contract_version_id = ct.contract_version_fk
           AND wov.contract_version_id = cv.contract_version_id
           AND wo.contract_id = cv.contract_fk
           AND ac.work_order_fk = wo.contract_id
           AND ae.assignment_edition_id = ac.current_edition_fk
           AND ae.assignment_continuity_fk = ac.assignment_continuity_id
           AND state.value = ae.assignment_state_fk
           AND state.type IN
               ('AssignmentAwaitingStartDateState',
                'AssignmentCompletedState',
                'AssignmentEffectiveState',
                'AssignmentTerminatedState')
           AND cv.contract_version_id =
               (CASE
                 WHEN wo.in_process_version_fk = cv.contract_version_id
                  AND wov.work_order_version_state IN (3, 17)
                   THEN wo.in_process_version_fk
                 ELSE NVL(wo.executing_version_fk, wo.last_past_version_fk)
                END)
           AND pt.start_date < SYSDATE) pa   --should we also filter out 1-day assignments where start_date = end_date???
 WHERE pa.candidate_fk = rc.related_candidate_id
   AND pa.end_date >= TRUNC(SYSDATE-5*365)  --hardcoded 5 years.  used to be (SELECT MIN(row_date) FROM days)
   and 1=1}';
    
    la_table(5) := 'TEMP_ASSIGNMENT_DAYS';
    la_sql(5) := q'{SELECT /*+ PARALLEL(2) */ DISTINCT --to remove overlaps
       pa.candidate_id, pa.assignment_buyer_org, d.row_date AS assignment_day  
  FROM temp_past_assignments}' || lv_source_short_name || ' pa, 
       temp_firm_settings' || lv_source_short_name || q'{ fs,
       (SELECT TRUNC(SYSDATE - (LEVEL -1)) AS row_date 
          FROM dual 
       CONNECT BY LEVEL <= (365 * 5)) d 
 WHERE pa.assignment_buyer_org = fs.business_organization_id
   AND d.row_date BETWEEN pa.start_date AND pa.end_date
   AND d.row_date >= fs.earliest_date}';
    
    la_table(6) := 'TEMP_EARLIEST_DAYS';
    la_sql(6) := 'SELECT candidate_id, assignment_buyer_org, MIN(assignment_day) AS earliest_start_day
   FROM temp_assignment_days' || lv_source_short_name || 
' GROUP BY candidate_id, assignment_buyer_org';
    
    la_table(7) := 'TEMP_TENURE_GAPS';
    la_sql(7) := q'{SELECT candidate_id, 
       assignment_buyer_org, 
       most_recent_gap_start_date, 
       most_recent_gap_end_date,
       most_recent_gap_end_date - most_recent_gap_start_date AS gap_days, 
       NVL(add_months(most_recent_gap_start_date, time_limit_gap_in_months), most_recent_gap_start_date + time_limit_gap_in_days) AS date_gap_met
  FROM (SELECT g.candidate_id, 
               g.assignment_buyer_org,
               fs.time_limit_gap_in_days, 
               fs.time_limit_gap_in_months,
               max(g.previous_day) + 1 AS most_recent_gap_start_date,  -- in cases with more than one gap, we only want the most recent 
               max(g.assignment_day)   AS most_recent_gap_end_date
          FROM (SELECT candidate_id, 
                       assignment_buyer_org, 
                       assignment_day,
                       LAG(assignment_day,1,NULL) OVER (PARTITION BY candidate_id,assignment_buyer_org ORDER BY assignment_day) AS previous_day
                  FROM temp_assignment_days}' || lv_source_short_name || ') g,
               temp_firm_settings' || lv_source_short_name || q'{ fs
         WHERE g.assignment_buyer_org = fs.business_organization_id
           AND g.assignment_day >= NVL(add_months(previous_day, time_limit_gap_in_months), previous_day + time_limit_gap_in_days) -- check by months if available, by days if not.
         GROUP BY g.candidate_id, 
                  g.assignment_buyer_org, 
                  fs.time_limit_gap_in_days, 
                  fs.time_limit_gap_in_months)}';
    
    la_table(8) := 'TEMP_DAYS_WORKED';
    la_sql(8) := q'{SELECT a.candidate_id, a.assignment_buyer_org, 
       MAX(date_gap_met) AS date_gap_met,  -- date_gap_met is NULL or constant over the group so we get it with MAX.
       COUNT(*)          AS days_worked    -- count all days on assignment since last tenure gap.
  FROM temp_assignment_days}' || lv_source_short_name || ' a,' ||
    '  temp_firm_settings' || lv_source_short_name || ' fs,' ||
    '  temp_earliest_days' || lv_source_short_name || ' e,' ||
    '  temp_tenure_gaps' || lv_source_short_name || q'{ t 
 WHERE a.candidate_id = e.candidate_id
   AND a.assignment_buyer_org = e.assignment_buyer_org
   AND a.assignment_buyer_org = fs.business_organization_id
   AND a.candidate_id = t.candidate_id(+)
   AND a.assignment_buyer_org = t.assignment_buyer_org(+)
   AND fs.con_include_service_gaps = 0 
   AND a.assignment_day >= NVL(t.most_recent_gap_start_date, e.earliest_start_day)  --if no tenure gap use ealiest day.
 GROUP BY a.candidate_id, a.assignment_buyer_org
 UNION ALL
SELECT a.candidate_id, a.assignment_buyer_org, 
       MAX(date_gap_met),                                            -- date_gap_met is NULL or constant over the group so we get it with MAX.
       MAX(assignment_day) - MIN(assignment_day) + 1 AS days_worked  -- count all days since last tenure gap even if there was a small (non-tenure length) gap
  FROM temp_assignment_days}' || lv_source_short_name || ' a,' ||
    '  temp_firm_settings' || lv_source_short_name || ' fs,' ||
    '  temp_earliest_days' || lv_source_short_name || ' e,' ||
    '  temp_tenure_gaps' || lv_source_short_name || q'{ t
 WHERE a.candidate_id = e.candidate_id
   AND a.assignment_buyer_org = e.assignment_buyer_org
   AND a.assignment_buyer_org = fs.business_organization_id
   AND a.candidate_id = t.candidate_id(+)
   AND a.assignment_buyer_org = t.assignment_buyer_org(+)
   AND a.assignment_day >= NVL(t.most_recent_gap_start_date, e.earliest_start_day)
   AND fs.con_include_service_gaps = 1
 GROUP BY a.candidate_id, a.assignment_buyer_org}';

    /* Next clean up any objects which may be remaining from previous failed runs. */
    logger_pkg.set_code_location('LEGO_TENURE - cleanup');
    FOR lv_loop_index IN 1 .. 8 LOOP
      drop_table(pi_table_name => la_table(lv_loop_index) || lv_source_short_name); 
    END LOOP;

    /*  Now start building tables to hold intermediate steps. */
    logger_pkg.set_code_location('LEGO_TENURE - table builds');
    FOR lv_loop_index IN 1 .. 8 LOOP
      lego_refresh_mgr_pkg.ctas(pi_table_name     => la_table(lv_loop_index) || lv_source_short_name,
                                pi_stmt_clob      => lego_tools.replace_placeholders_in_sql
                                                          (fi_sql_in            => la_sql(lv_loop_index),
                                                           fi_months_in_refresh => 0, --not actually referenced in TENURE queries because they based on lego_Asssignment
                                                           fi_db_link_name      => lv_db_link_name,
                                                           fi_source_db_scn     => pi_source_scn),
                                pi_storage_clause => lv_intermediate_storage_clause);
      IF lv_debug_flag
      THEN 
        make_table_grants(pi_table_name => la_table(lv_loop_index) || lv_source_short_name);
      END IF;                                    

    END LOOP;

    /* intermediate tables built, we can now build the final lego table. */
    lego_refresh_mgr_pkg.ctas(pi_table_name => pi_refresh_table_name,
                              pi_storage_clause => lv_final_storage_clause,
                              pi_stmt_clob  => q'{SELECT a.buyer_org_id, a.assignment_continuity_id, a.job_id, a.candidate_id,
       dw.date_gap_met, 
       dw.days_worked                        AS days_actually_worked,
       CASE 
          WHEN dw.days_worked > a.time_limit_in_days THEN 'Y'
          ELSE 'N' 
       END                                   AS over_tenure_work_duration,
       CASE 
         WHEN dw.days_worked >= a.time_limit_in_days - a.con_time_lmt_thrshold THEN 'Y'
         ELSE 'N'
       END                                   AS tenure_at_risk_time_met,
       a.time_limit_in_days - dw.days_worked AS days_remaining_to_threshold,
       CASE
         WHEN dw.days_worked > a.time_limit_in_days
           THEN dw.days_worked - a.time_limit_in_days
         ELSE NULL
       END                                   AS days_over_tenure_threshold,
       cast(null as number)  AS num_days_planned_to_work,
       cast(null as number)  AS additional_days_plan_to_work,
       cast(null as date)    AS tenure_risk_met_planned_end_dt,
       cast(null as date)    AS furthest_plan_end_dt,
       cast(null as date)    AS effec_assign_latest_planned_dt,
       cast(null as number)  AS tenure_gap_in_service,
       a.time_limit_in_days                  AS tenure_limit_in_days,
       a.time_limit_in_months                AS tenure_limit_in_months,   
       a.time_limit_gap_in_days              AS continuous_work_break_days,
       a.time_limit_gap_in_months            AS continuous_work_break_months,
       a.con_time_lmt_thrshold               AS tenure_at_risk_days
  FROM temp_assignments}' || lv_source_short_name || ' a,' || 
     ' temp_days_worked' || lv_source_short_name || q'{ dw
 WHERE a.candidate_id = dw.candidate_id
 ORDER BY a.buyer_org_id}');

    /* Final table created we just clean up the intermediate tables!
       (unless the lego_tenure_debugging_flag parameter is set to 'ON')  */
    logger_pkg.set_code_location('LEGO_TENURE - final cleanup');
    IF NOT lv_debug_flag THEN
      FOR lv_loop_index IN 1 .. 8 LOOP
        drop_table(pi_table_name => la_table(lv_loop_index) || lv_source_short_name);
      END LOOP;
    
    END IF;

  END load_lego_tenure;

END lego_tenure;
/
