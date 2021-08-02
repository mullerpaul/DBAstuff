CREATE OR REPLACE PACKAGE BODY lego_convergence_search AS

  /* From how many months back should the refresh pull data?  This should be a negative number.  */
  gc_lookback_months     CONSTANT NUMBER := -6;

  /* How many users security records can be handled in a single batch.
     This will be set by reading from the parameter table at runtime. */
  gv_security_batch_size          NUMBER;

  ------------------------------------------------------------------------------------
  PROCEDURE load_assignment_security IS
  BEGIN
    logger_pkg.set_code_location('load_assignment_security');
    logger_pkg.info('insert into convergence_search.assignment_sec_gtt');

    /* The below insert has a 4-way SELECT ... UNION ALL.  Each section of that select is for a 
       different type of security.  As of now, they are: MSP based, supplier based, buyer (non-role), and
       buyer (role).  Even though it leads to (a few) duplicate entries, we are using UNION ALL instead of UNION
       to combine the sets.  This is because in this case, the duplicates don't break anything.  The ElasicSearch
       queries this data will be used for won't care if a user is in there twice.  If the user is in there, the 
       record is visible to that user.  If not, it isn't.  If its in there multiple times, its still visible.
       Also, UNION ALL is MUCH faster since it doesn't do that huge de-duping.  */

    /* The "non_contractor_supplier_users" set is a list of all FO users attached to supplier
       orgs who are not candidates AND have logged in recently.  We use this set in the main query
       to grant access on assignments to users in same (low-level) org as the supplier_org. */
    INSERT INTO convergence_search.assignment_sec_gtt
       (assignment_id, user_name, user_domain_name, batch_id)
      WITH assign_info
        AS (SELECT assignment_continuity_id, buyer_org_id, supplier_org_id
              FROM minimal_assignment_ea_ta_iqp
             WHERE assignment_end_dt >= ADD_MONTHS(trunc(SYSDATE), gc_lookback_months)
             UNION ALL
            SELECT assignment_continuity_id, buyer_org_id, supplier_org_id
              FROM minimal_assignment_wo_iqp
             WHERE contractor_person_id IS NOT NULL
               AND assignment_end_dt >= ADD_MONTHS(trunc(SYSDATE), gc_lookback_months)),
           non_contractor_supplier_users
        AS (SELECT p.user_name, p.domain_name,
                   bo.bus_org_id
              FROM person_iqp p,
                   bus_org_iqp bo
             WHERE p.bus_org_id = bo.bus_org_id
               AND bo.bus_org_type = 'Supplier'
               AND p.candidate_id IS NULL
               AND p.user_three_months_login_flag = 1)
    SELECT assignment_continuity_id AS assignment_id,
           user_name, 
           domain_name AS user_domain_name,
           batch_id
      FROM (SELECT a1.assignment_continuity_id, u.user_name, u.domain_name, 
	               1 AS batch_id
              FROM assign_info a1,
                   msp_user_available_org_iqp u   --msp users to orgs
             WHERE a1.buyer_org_id = u.available_org_id
             UNION ALL -- We could use UNION to be sure we have no dupes; but really it doesn't matter if we do and this is much cheaper!
            SELECT a2.assignment_continuity_id, su.user_name, su.domain_name, 
			       2 AS batch_id
              FROM assign_info a2,
                   non_contractor_supplier_users su  --supplier users to orgs
             WHERE a2.supplier_org_id = su.bus_org_id
             UNION ALL
            SELECT ars.assignment_id AS assignment_continuity_id, p.user_name, p.domain_name, 
			       3 AS batch_id
              FROM assignment_row_security_iqp ars,  -- maps buyer users to assignments
                   person_iqp p
             WHERE ars.login_user_id = p.person_id
             UNION ALL
            SELECT a3.assignment_continuity_id, p.user_name, p.domain_name, 
                   4 AS batch_id 
              FROM assign_info a3,
                   (SELECT DISTINCT login_user_id, available_org_id 
                      FROM person_available_org) o,
                   person_iqp p,
                   user_roles_iqp ur,   -- lists users with certain roles
                   blone_linked_fo_account_hor blo  -- lists FO users linked to BLone accounts.
             WHERE ur.person_id = p.person_id
               AND p.person_id = o.login_user_id
               AND ur.person_id = o.login_user_id  -- may not need to specify this.  verify if it changes plan.
               AND p.user_name = blo.service_user_name -- the p to blo join ensures we only consider FO accounts linked to BLone accounts.
               AND p.domain_name = blo.service_user_domain
               AND o.available_org_id = a3.buyer_org_id
               AND p.user_three_months_login_flag = 1  -- filter out users who haven't logged in recently
               AND (ur.work_order_and_assignment_mgr = 1 OR  --we want users with any of these four roles enabled.
                    ur.assignment_administrator = 1 OR
                    ur.org_unit_assignment_mgr = 1 OR
                    ur.buyer_firm_executive = 1)
           );

    logger_pkg.info('insert into convergence_search.assignment_sec_gtt - complete ' ||
                    to_char(SQL%ROWCOUNT) || ' rows inserted', TRUE);

  END load_assignment_security;

  ------------------------------------------------------------------------------------
  PROCEDURE load_candidate_security IS
  BEGIN
    logger_pkg.set_code_location('load_candidate_security');
    logger_pkg.info('insert into convergence_search.candidate_sec_gtt');

    /* ToDo list of necessary changes before we re-enable candidates:
         add buyer security for candidates.
         add role-based security for candidates (need list of roles)
         add domain_name.
         add lookback month filter. */
    INSERT INTO convergence_search.candidate_sec_gtt
       (candidate_id, user_name, batch_id)
      WITH non_contractor_supplier_users
        AS (SELECT p.user_name,
                   bo.bus_org_id
              FROM operationalstore.person_iqp p,
                   operationalstore.bus_org_iqp bo
             WHERE p.bus_org_id = bo.bus_org_id
               AND bo.bus_org_type = 'Supplier'
               AND p.candidate_id IS NULL
               AND p.user_three_months_login_flag = 1)
    SELECT match_id AS candidate_id,
           user_name,
           FLOOR(ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY ROWNUM) / gv_security_batch_size) AS batch_id
      FROM (SELECT m1.match_id, u.user_name
              FROM match_iqp m1,
                   msp_user_available_org_iqp u   --msp users to orgs
             WHERE m1.buyer_org_id = u.available_org_id
             UNION ALL -- We could use UNION to be sure we have no dupes; but really it doesn't matter if we do and this is much cheaper!
            SELECT m2.match_id, su.user_name
              FROM match_iqp m2,
                   non_contractor_supplier_users su  --supplier users to orgs
             WHERE m2.supplier_org_id = su.bus_org_id);

    logger_pkg.info('insert into convergence_search.candidate_sec_gtt - complete ' ||
                    to_char(SQL%ROWCOUNT) || ' rows inserted', TRUE);

  END load_candidate_security;

  ------------------------------------------------------------------------------------
  PROCEDURE load_assignments IS
    lc_assgn_deeplink_template CONSTANT convergence_search.assignment_gtt.deeplink_url%TYPE := 
      '/wicket/wicket/bookmarkable/com.iqnavigator.frontoffice.web.wicket.falcon.FalconDeepLinkPage?dlt=TenureAlertDeepLink&oid=';
    
  BEGIN
    logger_pkg.set_code_location('load_assignments');
    logger_pkg.info('insert into convergence_search.assignment_gtt');

    /* Get a list of assignments and their attributes.
       No date filter other than what is used to build the legos.  There IS a data filter used when
       populating the ElasticSearch index. */
    INSERT INTO convergence_search.assignment_gtt
       (assignment_id,
        client_name,
        database_name,
        assignment_status,
        assignment_job_title,
        contractor_name,
        hiring_manager_name,
        assignment_start_date,
        assignment_end_date,
        deeplink_url)
      WITH assign_info
        AS (SELECT buyer_org_id, assignment_continuity_id, hiring_mgr_person_id, contractor_person_id, 
                   current_phase_type_id, assign_job_title, assignment_start_dt, assignment_end_dt
              FROM minimal_assignment_ea_ta_iqp
             WHERE assignment_end_dt >= ADD_MONTHS(trunc(SYSDATE), gc_lookback_months)
             UNION ALL
            SELECT buyer_org_id, assignment_continuity_id, hiring_mgr_person_id, contractor_person_id, 
                   current_phase_type_id, assign_job_title, assignment_start_dt, assignment_end_dt
              FROM minimal_assignment_wo_iqp
             WHERE contractor_person_id IS NOT NULL
               AND assignment_end_dt >= ADD_MONTHS(trunc(SYSDATE), gc_lookback_months)),
           phase_text
        AS (SELECT to_number(constant_value) AS phase_id,   --constant_value is VARCHAR for some reason
                   constant_description      AS phase_text 
              FROM java_constant_lookup_iqp
             WHERE locale_fk = 'EN_US'  --hardcoded to english.
               AND constant_type = 'ASSIGNMENT_PHASE')
    SELECT a.assignment_continuity_id AS assignment_id,
           lbo.enterprise_name        AS client_name,
           lbo.enterprise_name        AS database_name,   --client_name and database_name hold the same data for FO.
           p.phase_text               AS assignment_status,
           a.assign_job_title         AS assignment_job_title,
           lp_cont.display_name       AS contractor_name,
           lp_hm.display_name         AS hiring_manager_name,
           a.assignment_start_dt      AS assignment_start_date,
           a.assignment_end_dt        AS assignment_end_date,  -- need to verify we are using right date here
           lc_assgn_deeplink_template || to_char(a.assignment_continuity_id) AS deeplink_url
      FROM assign_info a,
           bus_org_iqp lbo,
           phase_text p,
           person_iqp lp_hm,
           person_iqp lp_cont
     WHERE a.buyer_org_id = lbo.bus_org_id
       AND a.current_phase_type_id = p.phase_id
       AND a.hiring_mgr_person_id = lp_hm.person_id(+)
       AND a.contractor_person_id = lp_cont.person_id;

    logger_pkg.info('insert into convergence_search.assignment_gtt - complete ' || 
                    to_char(SQL%ROWCOUNT) || ' rows inserted', TRUE);
  
  END load_assignments;

  ------------------------------------------------------------------------------------
  PROCEDURE load_candidates IS
    lc_cand_deeplink_template CONSTANT convergence_search.candidate_gtt.deeplink_url%TYPE := 
      '/wicket/wicket/bookmarkable/com.iqnavigator.frontoffice.web.wicket.falcon.FalconDeepLinkPage?dlt=MatchCandidateDeepLink&oid=';

  BEGIN
    logger_pkg.set_code_location('load_candidates');
    logger_pkg.info('insert into convergence_search.candidate_gtt');

    /* ToDo list of necessary changes before we re-enable candidates:
         add domain_name.
         add lookback month filter. */
    INSERT INTO convergence_search.candidate_gtt
       (candidate_id,
        client_name,
        database_name,
        job_requisition_id,
        candidate_name,
        submitted_date,
        supplier_name,
        job_title,
        status,
        deeplink_url)
      WITH candidate_status
        AS (SELECT to_number(constant_value) AS state_id,   --constant_value is VARCHAR for some reason
                   constant_description      AS state_text 
              FROM java_constant_lookup_iqp
             WHERE locale_fk = 'EN_US'  --hardcoded to english.
               AND constant_type = 'MATCH_STATE')   
    SELECT to_char(m.match_id)  AS candidate_id,
           bo_b.enterprise_name AS client_name,
           bo_b.enterprise_name AS database_name,   --client_name and database_name hold the same data for FO.
           to_char(m.job_id)    AS job_requisition_id,
           p_can.display_name   AS candidate_name,
           m.creation_date      AS submitted_date,
           bo_s.enterprise_name AS supplier_name,
           j.job_position_title AS job_title, 
           cs.state_text        AS status,
           lc_cand_deeplink_template || to_char(m.match_id)  AS deeplink_url
      FROM match_iqp m,
           job_iqp j,
           candidate_status cs,
           bus_org_iqp bo_b,
           bus_org_iqp bo_s,
           person_iqp p_can
     WHERE m.job_id = j.job_id
       AND m.match_state_id = cs.state_id
       AND m.buyer_org_id = bo_b.bus_org_id
       AND m.supplier_org_id = bo_s.bus_org_id
       AND m.candidate_id = p_can.candidate_id;

    logger_pkg.info('insert into convergence_search.candidate_gtt - complete ' || 
                    to_char(SQL%ROWCOUNT) || ' rows inserted', TRUE);
  
  END load_candidates;
  
  ------------------------------------------------------------------------------------
  PROCEDURE pivot_assignment_security IS
    lv_max_batch_id convergence_search.assignment_sec_gtt.batch_id%TYPE;
  BEGIN
    logger_pkg.set_code_location('pivot_assignment_security');
    logger_pkg.info('update convergence_search.assignment_gtt.security_info');

    /* We used to have a minimal number of batches; but it took WAY too much TEMP to aggregate
       over assignment security rows and figure out the number of batches.  So I've just set things
       to used a fixed number of batches.  So we will have a larger number of batches; but hopefully
       the lego will at least complete! */
    lv_max_batch_id := 4;

    /* The batch_id values are hardcoded in the load_assignment_security procedure.  */
    FOR batch_index IN 1 .. lv_max_batch_id
    LOOP
      logger_pkg.debug('Update #' || to_char(batch_index));
      /* I evaluated 3 ways to do this.  The first was correlated update.  It was incredibly slow.
         The second was an updateable join.  It gave an ORA-01779, which was probably fixable by adding
         a PK or UK on one or both of the GTT tables.  This third is this MERGE approach.  It works 
         faster than #1 without the required schema changes of #2. */
      /* The order of the IDs in the listagg'ed column really does not matter to us.  Unfortunatly, 
         its not an optional part of the syntax!  I picked "order by rownum" in hopes that its not 
         as resource intensive as order by username or other possibilities; but I admit to not having
         confirmed that. The below assumes USER_NAME contains no commas or pipes.  It doesn't now but
         I don't see anything preventing it.  */
      /* ToDo: try "ORDER BY 1 " or "ORDER BY NULL" in this listagg */ 

      MERGE INTO convergence_search.assignment_gtt t
      USING (SELECT sl.assignment_id,
                    LISTAGG('|' || sl.user_domain_name || '|' || sl.user_name, ',') WITHIN GROUP (order by rownum) AS batch_name_list
               FROM convergence_search.assignment_sec_gtt sl
              WHERE batch_id = batch_index
              GROUP BY sl.assignment_id) s
         ON (t.assignment_id = s.assignment_id)
       WHEN MATCHED THEN UPDATE
        SET t.security_list = t.security_list || CASE WHEN batch_index > 0 THEN ',' END || s.batch_name_list;

      logger_pkg.debug('Update #' || to_char(batch_index) || ' complete. ' || to_char(SQL%ROWCOUNT) || 
                       ' assignments updated', TRUE);
    END LOOP;
    logger_pkg.info('update convergence_search.assignment_gtt.security_info - complete');

  END pivot_assignment_security;

  ------------------------------------------------------------------------------------
  PROCEDURE pivot_candidate_security IS
    lv_max_batch_id convergence_search.candidate_sec_gtt.batch_id%TYPE;
  BEGIN
    logger_pkg.set_code_location('pivot_candidate_security');
    logger_pkg.info('update convergence_search.candidate_gtt.security_info');

    /* Find the number of batches we'll have to do */
    SELECT MAX(batch_id)
      INTO lv_max_batch_id
      FROM convergence_search.candidate_sec_gtt;

    /* The batch_id values start with 0 due to the SQL in load_candidate_security.  */
    FOR batch_index IN 0 .. lv_max_batch_id
    LOOP
      logger_pkg.debug('Update #' || to_char(batch_index));

      MERGE INTO convergence_search.candidate_gtt t
      USING (SELECT sl.candidate_id,
                    CASE WHEN batch_index > 0 THEN ',' END ||
                    LISTAGG('|GLOBAL|' || sl.user_name, ',') WITHIN GROUP (order by rownum) AS batch_name_list
               FROM convergence_search.candidate_sec_gtt sl
              WHERE batch_id = batch_index
              GROUP BY sl.candidate_id) s
         ON (t.candidate_id = s.candidate_id)
       WHEN MATCHED THEN UPDATE
        SET t.security_list = t.security_list || s.batch_name_list;

      logger_pkg.debug('Update #' || to_char(batch_index) || ' complete. ' || to_char(SQL%ROWCOUNT) || 
                       ' candidates updated', TRUE);
    END LOOP;
    logger_pkg.info('update convergence_search.candidate_gtt.security_info - complete');
  
  END pivot_candidate_security;

  ------------------------------------------------------------------------------------
  PROCEDURE load_convergence_search (pi_object_name IN lego_refresh.object_name%TYPE,
                                     pi_source      IN lego_refresh.source_name%TYPE) AS                                   

    lc_source_name  CONSTANT  VARCHAR2(30) := 'LEGO_CONVERGENCE_SEARCH';
    lv_error_stack            VARCHAR2(1000); 
    lv_load_candidates_flag   BOOLEAN;

  BEGIN
    logger_pkg.set_source(lc_source_name);
    logger_pkg.set_code_location('load_convergence_search');

    /* Initialize settings by reading from parameter table. */
    gv_security_batch_size := NVL(lego_tools.get_lego_parameter_num_value('convergence_srch_users_per_listagg_batch'), 100);
    lv_load_candidates_flag := CASE
                                 WHEN lego_tools.get_lego_parameter_text_value('convergence_srch_load_candidates_flag') = 'ON'
                                   THEN TRUE
                                 ELSE FALSE
                               END;  

    logger_pkg.info('Starting refresh of object_name: ' || pi_object_name ||
                    ' with source: ' || pi_source ||
                    ' candidate load: ' || CASE WHEN lv_load_candidates_flag THEN 'ENABLED' ELSE 'DISABLED' END ||
                    ' security batch size: ' || to_char(gv_security_batch_size)); 

    /* Push data into convergence_search temp tables.
       These two steps are not (yet) order dependent.  They could be in the future. */
    load_assignment_security;
    load_assignments;
    /* Now take the security data, aggregate it, and use it to update the main table. */
    pivot_assignment_security;

    IF lv_load_candidates_flag
      THEN
        /* Same steps for candidate data - if its enabled. */
        load_candidate_security;
        load_candidates;
        pivot_candidate_security;
    END IF;

    COMMIT;

    /* Now call convergence_search load procedure to move that data into the perm. tables */
    /* Need to verify how this logging works with logging in convergence_search.data_consolidation.move_data_to_perm_tables */
    logger_pkg.debug('call load procedure convergence_search.data_consolidation.move_data_to_perm_tables');
    convergence_search.data_consolidation.move_data_to_perm_tables(pi_legacy_source => 'IQN');
    logger_pkg.debug('call load procedure convergence_search.data_consolidation.move_data_to_perm_tables - complete', TRUE);

    logger_pkg.unset_source(lc_source_name);

  EXCEPTION
    WHEN OTHERS THEN
      lv_error_stack := SQLERRM || CHR(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal(lv_error_stack);  -- pass optional parameters?  transaction semantics?
      logger_pkg.unset_source(lc_source_name);
      RAISE;   

  END load_convergence_search;  

END lego_convergence_search;
/
