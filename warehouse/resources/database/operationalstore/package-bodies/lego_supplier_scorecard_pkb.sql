CREATE OR REPLACE PACKAGE BODY lego_supplier_scorecard AS
  
  gc_curr_schema             VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');
  gc_source                  VARCHAR2(30) := 'LEGO_SUPPLIER_SCORECARD'; 
  gv_error_stack             VARCHAR2(1000); 
  gv_start_date              DATE;
  
  ------------------------------------------------------------------------------------
  PROCEDURE load_visibility_list (pi_object_name IN lego_refresh.object_name%TYPE,
                                  pi_source      IN lego_refresh.source_name%TYPE) AS
                                   
  lv_source            VARCHAR2(61) := gc_source || '.load_visibility_list';
  
  BEGIN
    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('load_visibility_list');  
    logger_pkg.DEBUG('insert into supplier_scorecard.client_visibility_list_gtt');

    /* I ALWAYS get confused with hierarchical queries, and this one is worse than most!
       The goal of this query is to make an adjacency list from the org tree.  We do this
       so no matter at which org level the user logs in, she can see data from that org 
       and all its child orgs.  
       So just like the FO table bus_org_lineage, there is a row for every child org
       of every org (at every level).  There is also a "self row" for every org, where
       the org_guid is the same in both columns.
       The secret sauce to this query is the use of CONNECT_BY_ROOT without using START WITH.
       If you add a "START WITH parent_bus_org_id IS NULL", this query will return FAR fewer 
       rows as only the topmost level orgs will appear as log_in level orgs.  This is NOT what 
       we want; but it might be a good way to understand what exactly connect_by_root is doing. */
    INSERT INTO supplier_scorecard.client_visibility_list_gtt
      (log_in_client_guid, visible_client_guid, score_config_owner_guid)
      WITH buyer_guids
        AS (SELECT bus_org_guid, parent_bus_org_guid, enterprise_bus_org_guid
              FROM bus_org_iqp
             WHERE bus_org_type = 'Buyer')
    SELECT CONNECT_BY_ROOT bus_org_guid AS log_in_client_guid,
           bus_org_guid                 AS visible_client_guid,
           enterprise_bus_org_guid      AS score_config_owner_guid 
      FROM buyer_guids
    CONNECT BY PRIOR bus_org_guid = parent_bus_org_guid;

    logger_pkg.DEBUG('insert into supplier_scorecard.client_visibility_list_gtt - complete ' ||
                     to_char(SQL%ROWCOUNT) || ' rows inserted', TRUE);
    logger_pkg.unset_source(lv_source);
    
  END load_visibility_list;
  
  ------------------------------------------------------------------------------------
  PROCEDURE load_supplier_release (pi_object_name IN lego_refresh.object_name%TYPE,
                                   pi_source      IN lego_refresh.source_name%TYPE) AS
                                   
  lv_source            VARCHAR2(61) := gc_source || '.load_supplier_release';
  
  BEGIN

    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('load_supplier_release');  

    logger_pkg.debug('insert into supplier_scorecard.supplier_release_gtt');
  
    INSERT INTO supplier_scorecard.supplier_release_gtt (
      release_guid,
      client_guid,
      client_name,
      supplier_guid,
      supplier_name,
      release_date,
      requisition_guid,
      requisition_id,
      requisition_create_date,
      requisition_currency,
      requisition_title,
      requisition_industry,
      requisition_country,
      requisition_state,
      requisition_city,
      release_tier,
      requisition_positions,
      requisition_rate
    )
      WITH single_loc_jobs AS (
        SELECT job_id
          FROM job_work_location_iqp
         GROUP BY job_id
        HAVING COUNT(*) = 1)
      SELECT jogm.job_opportunity_guid  AS release_guid,
             bo.bus_org_guid            AS client_guid,  --lowest level bus org guid
             bo.enterprise_name         AS client_name,  --top level bus org name
             so.bus_org_guid            AS supplier_guid,
             so.bus_org_name            AS supplier_name,
             jo.create_date             AS release_date,
             jgm.job_guid               AS requisition_guid,
             lj.job_id                  AS requisition_id,
             lj.job_created_date        AS requisition_create_date,
             jr.job_currency            AS requisition_currency,
             lj.job_position_title      AS requisition_title,
             lj.jc_description          AS requisition_industry,
             COALESCE(pl.standard_country, pl.country) AS requisition_country, --sometimes the custom country is flat out wrong!
             COALESCE(pl.standard_state, pl.state)     AS requisition_state, 
             COALESCE(pl.standard_city, pl.city)       AS requisition_city, 
             CAST(NULL AS VARCHAR2(100))               AS release_tier, --not available
             jp.positions_total                        AS requisition_positions,
             jr.bill_rate                              AS requisition_rate --bill_rate, correct?
        FROM job_iqp lj
             INNER JOIN bus_org_iqp           bo    ON (lj.buyer_org_id       = bo.bus_org_id)       
             INNER JOIN job_foid_guid_map     jgm   ON (lj.job_id             = jgm.job_id) 
             INNER JOIN job_rates_iqp         jr    ON (lj.job_id             = jr.job_id) 
             INNER JOIN job_position_iqp      jp    ON (lj.job_id             = jp.job_id)
             INNER JOIN job_opportunity_iqp   jo    ON (lj.job_id             = jo.job_id)
             INNER JOIN job_opp_foid_guid_map jogm  ON (jo.job_opportunity_id = jogm.job_opportunity_id)
             INNER JOIN bus_org_iqp           so    ON (jo.supplier_org_id    = so.bus_org_id)
             LEFT JOIN single_loc_jobs        soj   ON (lj.job_id             = soj.job_id)
             LEFT JOIN job_work_location_iqp  jwl   ON (jwl.job_id            = soj.job_id)
             LEFT JOIN lego_place_iqp         pl    ON (jwl.place_id          = pl.place_id)
       WHERE lj.template_availability IS NULL   -- exclude job templates
         AND lj.job_source_of_record NOT IN ('PRP','PEL') -- Exclude express assignments created from a project
         AND lj.job_state != 'Under Development'
         AND NOT (lj.job_state = 'Canceled' AND lj.job_sub_matching_date IS NULL)
         AND lj.job_created_date >= gv_start_date;

    logger_pkg.debug('insert into supplier_scorecard.supplier_release_gtt - complete '||SQL%ROWCOUNT||' rows inserted',TRUE);
    
    logger_pkg.unset_source(lv_source);         
      
  END load_supplier_release;
 
  ------------------------------------------------------------------------------------
  PROCEDURE load_supplier_submission (pi_object_name IN lego_refresh.object_name%TYPE,
                                      pi_source      IN lego_refresh.source_name%TYPE) AS                                   
  
  lv_source            VARCHAR2(61) := gc_source || '.load_supplier_submission';
  
  BEGIN
  
    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('load_supplier_submission');  

    logger_pkg.debug('insert into supplier_scorecard.supplier_submission_gtt');
  
    INSERT INTO supplier_scorecard.supplier_submission_gtt (
        submission_guid,
        submission_date,
        release_guid,
        candidate_name,
        submitted_bill_rate,
        offer_made_date,
        offer_accepted_date,
        offer_rejected_date,
        offer_accepted_rate,
        interview_requested_date,
        interview_scheduled_date,
        interview_date,
        avg_interview_rating,
        assignment_id,
        assignment_status_id,
        assignment_status,
        assignment_start_date,
        assignment_pay_rate,
        assignment_bill_rate,
        assignment_unfav_term_date,
        assignment_end_date,
        assignment_end_type     
    )
      WITH assign_wo AS 
       (SELECT aw.assignment_continuity_id,
               aw.job_id,
               aw.candidate_id,
               aw.supplier_org_id,
               aw.offer_id,
               'WO' AS assignment_type,
               aw.has_ever_been_effective,
               aw.accepted_by_supplier_date,
               aw.assignment_create_date,
               aw.assignment_effective_date,
               aw.assignment_start_dt,
               aw.assignment_end_dt,
               aw.assignment_actual_end_dt,
               aw.reg_bill_rate,
               aw.reg_pay_rate,
               aw.assignment_state_id,
               jcl_state.constant_description AS assignment_status
          FROM operationalstore.assignment_wo_iqp aw,
               (SELECT constant_value, constant_description
                  FROM operationalstore.java_constant_lookup_iqp
                 WHERE constant_type = 'SEARCHABLE_ASGNMT_STATE'
                   AND locale_fk = 'EN_US') jcl_state          
         WHERE aw.assignment_state_id = jcl_state.constant_value
           AND aw.assignment_state_id != 6),
       assign_ea AS
       (SELECT ea.assignment_continuity_id,
               ea.job_id,
               ea.candidate_id,
               ea.supplier_org_id,  
               NULL AS offer_id,
               'EA' AS assignment_type,
               ea.has_ever_been_effective,
               NULL AS accepted_by_supplier_date,
               ea.assignment_create_date,          
               ea.assignment_effective_date,
               ea.assignment_start_dt,
               ea.assignment_end_dt,
               ea.assignment_actual_end_dt,
               ea.reg_bill_rate,
               ea.reg_pay_rate,
               ea.assignment_state_id,
               jcl_state.constant_description AS assignment_status             
          FROM operationalstore.assignment_ea_iqp ea,
               (SELECT constant_value, constant_description
                  FROM operationalstore.java_constant_lookup_iqp
                 WHERE constant_type = 'SEARCHABLE_ASGNMT_STATE'
                   AND locale_fk = 'EN_US') jcl_state          
         WHERE ea.assignment_state_id = jcl_state.constant_value
           AND ea.assignment_state_id != 6),
       match AS 
       (SELECT m.match_id,
               mfg.match_guid            AS submission_guid, 
               m.creation_date           AS submission_date,   
               jofg.job_opportunity_guid AS release_guid,
               m.bill_rate               AS submitted_bill_rate,
               m.offer_id,
               m.job_id,
               m.assignment_continuity_fk  AS assignment_continuity_id,
               m.supplier_org_id,
               m.candidate_id,
               lp.display_name AS candidate_name,
               m.cand_offered_position,
               m.not_interested_in_job,
               m.declined_job,
               m.pay_rate,
               CAST(NULL AS NUMBER)            AS avg_interview_rating, --not available
               m.assignment_terminated
          FROM match_iqp m 
               INNER JOIN match_foid_guid_map    mfg ON (m.match_id            = mfg.match_id)              
               INNER JOIN job_opportunity_iqp     jo ON (m.job_opportunity_id  = jo.job_opportunity_id)
               INNER JOIN job_opp_foid_guid_map jofg ON (jo.job_opportunity_id = jofg.job_opportunity_id)
               INNER JOIN job_iqp                 lj ON (jo.job_id             = lj.job_id) 
               INNER JOIN person_iqp              lp ON (m.candidate_id        = lp.candidate_id)
         WHERE lj.template_availability IS NULL   -- exclude job templates
           AND lj.job_source_of_record NOT IN ('PRP','PEL') -- Exclude express assignments created from a project
           AND lj.job_state != 'Under Development'
           AND NOT (lj.job_state = 'Canceled' AND lj.job_sub_matching_date IS NULL)
           AND lj.job_created_date >= gv_start_date),
       intrvw AS 
       (SELECT match_id,
               CASE 
                 WHEN interview_requested_virtual IS NULL OR interview_requested_phone IS NOT NULL OR interview_requested_in_person IS NOT NULL
                   THEN GREATEST(NVL(interview_requested_virtual,TO_DATE('01/01/1900','MM/DD/YYYY')),NVL(interview_requested_phone,TO_DATE('01/01/1900','MM/DD/YYYY')),NVL(interview_requested_in_person,TO_DATE('01/01/1900','MM/DD/YYYY'))) 
               END AS interview_requested_date,
               CASE 
                 WHEN interview_scheduled_virtual IS NOT NULL OR interview_scheduled_phone IS NOT NULL OR interview_scheduled_in_person IS NOT NULL
                   THEN GREATEST(NVL(interview_scheduled_virtual,TO_DATE('01/01/1900','MM/DD/YYYY')),NVL(interview_scheduled_phone,TO_DATE('01/01/1900','MM/DD/YYYY')),NVL(interview_scheduled_in_person,TO_DATE('01/01/1900','MM/DD/YYYY'))) 
               END AS interview_scheduled_date,
               CASE
                 WHEN interview_scheduled_virtual IS NOT NULL OR interview_scheduled_phone IS NOT NULL OR interview_scheduled_in_person IS NOT NULL
                   THEN GREATEST(NVL(interview_date_virtual,TO_DATE('01/01/1900','MM/DD/YYYY')),NVL(interview_date_phone,TO_DATE('01/01/1900','MM/DD/YYYY')),NVL(interview_date_in_person,TO_DATE('01/01/1900','MM/DD/YYYY'))) 
               END AS interview_date            
          FROM interview_iqp)       
      SELECT match_wo.submission_guid, 
             match_wo.submission_date,   
             match_wo.release_guid,
             match_wo.candidate_name,
             match_wo.submitted_bill_rate,
             match_wo.cand_offered_position AS offer_made_date,
             assign_wo.accepted_by_supplier_date AS offer_accepted_date,
             CASE WHEN match_wo.offer_id IS NOT NULL AND match_wo.cand_offered_position IS NOT NULL AND ((match_wo.not_interested_in_job IS NOT NULL OR match_wo.declined_job IS NOT NULL) 
                                                                                       OR (assign_wo.assignment_continuity_id IS NOT NULL AND assign_wo.has_ever_been_effective = 0 AND assign_wo.assignment_state_id = 4))
                       THEN COALESCE(match_wo.not_interested_in_job, match_wo.declined_job, assign_wo.assignment_actual_end_dt) 
             END AS offer_rejected_date, --only candidates on WOs can reject offer
             CASE WHEN assign_wo.accepted_by_supplier_date IS NOT NULL THEN match_wo.pay_rate END AS offer_accepted_rate,   
             intrvw.interview_requested_date,
             intrvw.interview_scheduled_date,
             intrvw.interview_date,
             CAST(NULL AS NUMBER)                AS avg_interview_rating, --not available
             assign_wo.assignment_continuity_id  AS assignment_id,
             assign_wo.assignment_state_id       AS assignment_status_id,
             assign_wo.assignment_status,
             assign_wo.assignment_start_dt       AS assignment_start_date,
             assign_wo.reg_pay_rate              AS assignment_pay_rate,
             assign_wo.reg_bill_rate             AS assignment_bill_rate,
             CASE WHEN assign_wo.assignment_state_id = 17 THEN COALESCE(match_wo.assignment_terminated, assign_wo.assignment_actual_end_dt) END AS assignment_unfav_term_date,
             assign_wo.assignment_actual_end_dt  AS assignment_end_date,  --if assignment hasn't ended do we still want the anticipated end date?
             CAST(NULL AS VARCHAR2(255))         AS assignment_end_type
        FROM match match_wo
             LEFT OUTER JOIN assign_wo ON (match_wo.job_id          = assign_wo.job_id AND 
                                           match_wo.supplier_org_id = assign_wo.supplier_org_id AND 
                                           match_wo.candidate_id    = assign_wo.candidate_id AND
                                           match_wo.offer_id        = assign_wo.offer_id)
             LEFT OUTER JOIN intrvw    ON (match_wo.match_id        = intrvw.match_id)
       WHERE match_wo.offer_id IS NOT NULL --only WOs         
   UNION ALL         
      SELECT match_ea.submission_guid, 
             match_ea.submission_date,   -- many metrics based on this - make sure its what I think it is!
             match_ea.release_guid,
             match_ea.candidate_name,
             match_ea.submitted_bill_rate,
             match_ea.cand_offered_position AS offer_made_date, --works for WOs and EAs
             match_ea.cand_offered_position AS offer_accepted_date, --used to use assignment_create_date but often that timestamp is BEFORE cand_offered_position 
             CASE WHEN match_ea.offer_id IS NOT NULL AND match_ea.cand_offered_position IS NOT NULL AND ((match_ea.not_interested_in_job IS NOT NULL OR match_ea.declined_job IS NOT NULL) 
                                                                                       OR (assign_ea.assignment_continuity_id IS NOT NULL AND assign_ea.has_ever_been_effective = 0 AND assign_ea.assignment_state_id = 4))
                       THEN COALESCE(match_ea.not_interested_in_job, match_ea.declined_job, assign_ea.assignment_actual_end_dt) 
             END AS offer_rejected_date, --only candidates on WOs can reject offer
             CASE WHEN match_ea.cand_offered_position IS NOT NULL THEN match_ea.pay_rate END AS offer_accepted_rate,   
             intrvw.interview_requested_date,
             intrvw.interview_scheduled_date,
             intrvw.interview_date,
             CAST(NULL AS NUMBER)               AS avg_interview_rating, --not available
             assign_ea.assignment_continuity_id AS assignment_id,
             assign_ea.assignment_state_id      AS assignment_status_id,
             assign_ea.assignment_status,
             assign_ea.assignment_start_dt      AS assignment_start_date,
             assign_ea.reg_pay_rate             AS assignment_pay_rate,
             assign_ea.reg_bill_rate            AS assignment_bill_rate,
             CASE WHEN assign_ea.assignment_state_id = 17 THEN COALESCE(match_ea.assignment_terminated, assign_ea.assignment_actual_end_dt) END AS assignment_unfav_term_date,
             assign_ea.assignment_actual_end_dt AS assignment_end_date,  --if assignment hasn't ended do we still want the anticipated end date?
             CAST(NULL AS VARCHAR2(255))        AS assignment_end_type
        FROM match match_ea              
             INNER JOIN      assign_ea ON (match_ea.assignment_continuity_id = assign_ea.assignment_continuity_id)
             LEFT OUTER JOIN intrvw    ON (match_ea.match_id                 = intrvw.match_id);    
         
    logger_pkg.debug('insert into supplier_scorecard.supplier_submission_gtt - complete '||SQL%ROWCOUNT||' rows inserted',TRUE);
    
    logger_pkg.unset_source(lv_source);
    
   
  END load_supplier_submission;
  
  ------------------------------------------------------------------------------------
  PROCEDURE load_supplier_scorecard (pi_object_name IN lego_refresh.object_name%TYPE,
                                     pi_source      IN lego_refresh.source_name%TYPE) AS                                   
  
  lv_source            VARCHAR2(61) := gc_source || '.load_supplier_scorecard';
  
  BEGIN
  
    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('load_supplier_scorecard');  

    load_visibility_list (pi_object_name => pi_object_name,
                          pi_source      => pi_source);

    load_supplier_release (pi_object_name => pi_object_name,
                           pi_source      => pi_source);
                           
    load_supplier_submission (pi_object_name => pi_object_name,
                              pi_source      => pi_source);         

    COMMIT;
    
    logger_pkg.debug('call load proc, supplier_scorecard.supplier_data_utility.move_data_to_perm_tables');
    supplier_scorecard.supplier_data_utility.move_data_to_perm_tables('IQN');
    logger_pkg.debug('call load proc, supplier_scorecard.supplier_data_utility.move_data_to_perm_tables - complete',TRUE);

    logger_pkg.unset_source(lv_source);
    
  EXCEPTION
    WHEN OTHERS THEN
      gv_error_stack := SQLERRM || CHR(10) || dbms_utility.format_error_backtrace;
      logger_pkg.fatal(gv_error_stack);
      logger_pkg.unset_source(lv_source);
      RAISE;   
  END load_supplier_scorecard;  

BEGIN
  gv_start_date  := ADD_MONTHS(TRUNC(SYSDATE,'YEAR'), -24);
  logger_pkg.instantiate_logger;
  logger_pkg.set_source(gc_source);
  logger_pkg.set_level('DEBUG');
  
END lego_supplier_scorecard;
/
