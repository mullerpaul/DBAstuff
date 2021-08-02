/*******************************************************************************
SCRIPT NAME         lego_job_fill_trend.sql
 
LEGO OBJECT NAME    LEGO_JOB_FILL_TREND
 
CREATED             02/14/2018
 
ORIGINAL AUTHOR     Paul Muller & McKay Dunlap

***************************MODIFICATION HISTORY ********************************

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_job_fill_trend';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JOB_FILL_TREND';

  v_clob CLOB :=
   q'{  WITH
    supplier_opportunities_per_job
    AS (SELECT job_id,
               COUNT(*) AS supp_opportunity_count,
               COUNT(CASE WHEN state = 'Active' THEN 'x' END) AS supp_active_opportunity_count
          FROM job_opportunity_sourceNameShort
         GROUP BY job_id),
    match_info_per_job
    AS (SELECT job_id,
               COUNT(*) as match_count,
               COUNT(DISTINCT candidate_id) as distinct_cand_id_count,
               MIN(creation_date) AS earliest_match,
               MIN(cand_offered_position) AS earliest_offer
          FROM match_sourceNameShort
         GROUP BY job_id),
    assignment_info
    AS (SELECT assignment_continuity_id, 'WO' AS assignment_type, job_id, contact_info_id, reg_bill_rate
          FROM assignment_wo_sourceNameShort
         UNION ALL
        SELECT assignment_continuity_id, 'EA' AS assignment_type, job_id, contact_info_id, reg_bill_rate
          FROM assignment_ea_sourceNameShort
         UNION ALL
        SELECT assignment_continuity_id, 'TA' AS assignment_type, job_id, contact_info_id, 0 AS reg_bill_rate
          FROM assignment_ta_sourceNameShort),
    job_assignment_location_info  --sadly, we have dupe job_id rows from this set.  joining to this breaks cardinality slightly 
    AS (SELECT A.job_id, A.assignment_type, ladd.country_code, ladd.STATE, ladd.city, 
               COUNT(*) AS assignment_count,  --one row per assignment
               COUNT(DISTINCT A.contact_info_id) contact_info_distinct_count,
               MAX(A.reg_bill_rate) AS max_assignment_reg_bill_rate,
               MIN(A.reg_bill_rate) AS min_assignment_reg_bill_rate,
               MEDIAN(A.reg_bill_rate) AS med_assignment_reg_bill_rate
          FROM assignment_info A,
               lego_contact_address_sourceNameShort lca,
               lego_address_sourceNameShort ladd
         WHERE A.contact_info_id = lca.contact_info_id  -- inner filters out less than 0.1% of all assignments
           AND lca.primary_address_guid = ladd.address_guid  -- these two designed to be inner joined
         GROUP BY A.job_id, A.assignment_type, ladd.country_code, ladd.STATE, ladd.city)
SELECT j.buyer_org_id, 
       bw.enterprise_name AS buyer_enterprise_name, 
       bw.bus_org_name AS buyer_name,
       bw.managing_organization_name AS buyer_managing_org_name,
       dmb.industry_name, 
       j.job_id AS requisition_id,
       hmp.person_id as hiring_manager_person_id,
       hmp.display_name AS hiring_manager_name,
       jcp.display_name AS requisition_creator_name,
       j.job_created_date AS requisition_create_date,
       j.job_state AS requisition_state,
       j.job_position_title AS job_title,
       j.jc_description AS job_category,
       j.job_description, 
       j.job_type AS job_type,
       jr.bill_rate,
       jr.rate_type,
       jr.rate_type_new,
       jr.job_currency,
       jp.positions_total,
       jp.positions_filled,
       jp.positions_available_cur AS positions_available_currently,
       jp.job_canceled_date,
       jp.job_closed_date,
       so.supp_opportunity_count,
       so.supp_active_opportunity_count,
       jm.distinct_cand_id_count AS total_candidates_sumbitted,  --may be slight overcounting here.  A cand submitted by multiple suppliers counts multiple times.
       jm.earliest_match AS earliest_match_submission,
       jm.earliest_offer AS earliest_offer_made,
       jal.assignment_count,  -- if this is > 1, it shows the number of repeated rows.
       jal.contact_info_distinct_count as assignment_location_count,
       jal.assignment_type,
       jal.country_code AS assignment_location_country,
       jal.state AS assignment_location_state,
       jal.city AS assignment_location_city,
       jal.max_assignment_reg_bill_rate,
       jal.min_assignment_reg_bill_rate,
       jal.med_assignment_reg_bill_rate
  FROM job_sourceNameShort          j,
       job_position_sourceNameShort jp,
       job_rates_sourceNameShort    jr,
       supplier_opportunities_per_job    so,
       match_info_per_job                jm,
       job_assignment_location_info      jal,
       person_sourceNameShort       hmp,
       person_sourceNameShort       jcp,
       bus_org_sourceNameShort      bw,
       iqprodm.dm_buyers                 dmb
 WHERE j.job_id = jp.job_id     -- Inner is good due to design of job_positions lego.
   AND j.job_id = jr.job_id     -- Inner is good due to design of job_rates lego.
   AND j.job_id = so.job_id     -- This set is grouped by job_id. Jobs without opportunities are filtered out, but thats what we want.
   AND j.job_id = jm.job_id(+)  -- Outer since we want jobs with AND without matches.
   AND j.job_id = jal.job_id(+) -- Outer because not all requisitions make it to assignment.
   AND j.hiring_mgr_person_id = hmp.person_id
   AND j.creator_person_id = jcp.person_id
   AND j.buyer_org_id = bw.bus_org_id 
   AND bw.enterprise_bus_org_id = dmb.std_buyerorg_id(+) -- some (newer) enterprises do not have a row in dmb.
}';

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

