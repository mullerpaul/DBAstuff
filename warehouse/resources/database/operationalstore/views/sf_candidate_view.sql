	CREATE OR REPLACE FORCE VIEW sf_candidate_vw AS
WITH single_loc_jobs  
          AS ( SELECT job_id, place_id FROM
                ( SELECT job_id, place_id, ROW_NUMBER() OVER ( PARTITION BY job_id ORDER BY job_id ) rn
                  FROM OPERATIONALSTORE.job_work_location_iqp
                ) WHERE rn = 1
             ),
          LastRefresh AS (SELECT MAX(REFRESH_END_TIME) AS LastRefreshDate
                  FROM OPERATIONALSTORE.LEGO_REFRESH_HISTORY 
                  WHERE SOURCE_NAME = 'USPROD' 
                    AND OBJECT_NAME = 'LEGO_JOB' 
                    AND STATUS = 'released'
                ),
      intrvw AS (SELECT match_id, CASE WHEN interview_scheduled_virtual IS NOT NULL OR interview_scheduled_phone IS NOT NULL OR interview_scheduled_in_person IS NOT NULL
                   THEN GREATEST(NVL(interview_date_virtual,TO_DATE('01/01/1900','MM/DD/YYYY')),NVL(interview_date_phone,TO_DATE('01/01/1900','MM/DD/YYYY')),NVL(interview_date_in_person,TO_DATE('01/01/1900','MM/DD/YYYY'))) 
               END AS interview_date            
          FROM operationalstore.interview_iqp), 
       rate_card_info 
            AS (SELECT
                    jri.job_id, 
                     COALESCE (max(rci.bill_rate_max), 
                    min(rci.bill_rate_min)) as bill_rate,  -- max rate
                    COALESCE (min(rci.bill_rate_min), 
                    max(rci.bill_rate_max)) as bill_rate2,  -- min rate
                    rci.rate_card_identifier as rcc1,
                    null as rcc2
                 FROM  operationalstore.job_rates_iqp jri
                    inner join operationalstore.ratecard_iqp rci
                        ON (rci.rate_card_identifier_id = jri.rate_card_identifier_id
                            AND rci.source_template_id = jri.source_template_id                       
                            )
                WHERE rci.active = 'Y'
                GROUP BY jri.job_id, rci.rate_card_identifier
                ),
     job_position_info AS
     (SELECT  j.buyer_org_id,
              j.job_id,
              job_closed_date,
              job_rejected_date,
              job_closed_to_new_matches,
              CASE WHEN j.job_approval_status IN ('Rejected') THEN
                    jp.job_rejected_date
                 ELSE NULL
              END AS final_req_rej_date
      FROM OPERATIONALSTORE.job_iqp j
          INNER JOIN  OPERATIONALSTORE.job_position_iqp jp
           ON (j.job_id = jp.job_id)        
      ),
     position_offer_info
     AS ( SELECT buyer_org_id, 
                 supplier_org_id, 
                 job_id,              
                 candidate_id,        
                 min(m.cand_offered_position) as  first_cand_offered_pos,
                 max(cand_approved_date) as  cand_final_approved_date          
             FROM operationalstore.match_iqp m                 
       GROUP BY buyer_org_id, supplier_org_id, job_id,candidate_id
       ),
     cand_submitted_by_supplier
     AS ( SELECT buyer_org_id, supplier_org_id, job_id, candidate_id, min(m.creation_date) first_cand_submitted
            FROM operationalstore.match_iqp m
            WHERE (automatch is not null
             OR interested_in_job is not null
             OR direct_submit is not null)
          GROUP BY buyer_org_id, supplier_org_id, job_id, candidate_id),
     date_released_to_supplier_info
     AS ( SELECT jo.buyer_org_id,
                 jo.supplier_org_id,
                 jo.job_id, 
                 min(job_sub_matching_date) as job_sub_matching_date,
                 min(j.approved_date) as date_req_approved,
                 CASE WHEN job_approval_status IN ('Approved') THEN
                    max(j.approved_date)
                 ELSE NULL
                 END AS final_req_appr_date,
                 min(jo.create_date) date_released_to_supplier                
           FROM operationalstore.job_iqp j
             INNER JOIN  operationalstore.job_opportunity_iqp jo              
                ON ( jo.job_id = j.job_id)         
            group by jo.buyer_org_id, jo.supplier_org_id, jo.job_id, job_approval_status),  
     assignment_info AS
     (
       SELECT  aw.buyer_org_id,
               aw.supplier_org_id,
               aw.job_id,
               aw.offer_id,
               aw.assignment_continuity_id,
               aw.candidate_id,
               aw.assignment_start_dt,
               aw.accepted_by_supplier_date,
               aw.released_to_supplier_date
         FROM  OPERATIONALSTORE.LEGO_ALL_ASSIGNMENT_TYPES_VW aw
       ) 
  SELECT
        msj.candidates_submitted AS num_candidates,
        msj.Suppliers_available_to_submit as num_suppliers,
        lj.job_id AS request_id, 
        mi.match_id AS candidate_id,
        mi.supplier_org_id AS supplier_id,
        bo.enterprise_name AS client_name,
        COALESCE(pl.standard_city, pl.city) AS city,
        COALESCE(pl.standard_state, pl.state) AS state,
        COALESCE(pl.standard_country, pl.country) AS country,
        pl.postal_code AS postalcode,
        pi1.display_name AS contractor_name,
        jr.JOB_CURRENCY AS currency,
        mi.CREATION_DATE as date_candidate_submitted,
        lj.jc_description AS job_class,
        lj.job_position_title AS job_title,
        pi.display_name AS hiring_manager,
        jp.POSITIONS_TOTAL AS number_of_openings,
        ri.bill_rate AS rate_card_rate,
        CASE lj.job_duration_unit 
            when 'Days' then   round(lj.Job_Duration_Max/7)
            when 'Months' then round(lj.Job_Duration_Max * 4.3)
            when 'Weeks' then lj.Job_Duration_Max
            else NULL
        END as job_durationinweeks,
        lr.LastRefreshDate AS last_update_dt,
        lj.JOB_STATE AS request_status,
        lj.JOB_TYPE AS request_type,      
        lj.approved_date AS date_request_start,
        lj.JOB_SUB_MATCHING_DATE AS date_request_submitted,
        lj.JOB_CREATED_DATE AS date_request_released,     
        so.bus_org_name as supplier_name,
        intv.interview_date as interview_date,
        jr.bill_rate as request_rate,
        mi.bill_rate as supplier_submitted_rate,
        mi.pay_rate as pay_rate,
                                mi.job_closed as request_close_date,
        CASE 
          when jr.bill_rate = ri.bill_rate then 'Equal'
          when jr.bill_rate > ri.bill_rate then 'Above'
          when jr.bill_rate < ri.bill_rate then 'Below'
          ELSE NULL
       END AS rate_card_above_within,
       (ri.bill_rate - jr.bill_rate) * 2000 AS rate_card_req_annaul_saving,
       ri.bill_rate - jr.bill_rate AS rate_card_req_rate_diff,    
        CASE 
          when jr.bill_rate = mi.pay_rate then 'Equal'
          when jr.bill_rate > mi.pay_rate then 'Below'
          when jr.bill_rate < mi.pay_rate then 'Above'
          ELSE NULL
       END AS rq_off_above_within,
       (jr.bill_rate - mi.pay_rate) * 2000 AS rq_off_annaul_saving,
       jr.bill_rate - mi.pay_rate AS rq_off_rate_diff,    
        CASE 
          when mi.bill_rate = mi.pay_rate then 'Equal'
          when mi.bill_rate > mi.pay_rate then 'Below'
         when mi.bill_rate < mi.pay_rate then 'Above'
          ELSE NULL
       END AS sub_off_above_within,
       (mi.bill_rate - mi.pay_rate) * 2000 AS sub_off_annaul_saving,
       mi.bill_rate - mi.pay_rate AS sub_off_rate_diff,    
        CASE 
          when ri.bill_rate = mi.bill_rate then 'Equal'
          when ri.bill_rate > mi.bill_rate then 'Below'
          when ri.bill_rate < mi.bill_rate then 'Above'
          ELSE NULL
       END AS rc_sub_above_within,
       (ri.bill_rate - mi.bill_rate) * 2000 AS rc_sub_annaul_saving,
       ri.bill_rate - mi.bill_rate AS rc_sub_rate_diff,    
        CASE 
          when ri.bill_rate = mi.pay_rate then 'Equal'
          when ri.bill_rate > mi.pay_rate then 'Below'
          when ri.bill_rate < mi.pay_rate then 'Above'
          ELSE NULL
       END AS rc_off_above_within,
       (ri.bill_rate - mi.pay_rate) * 2000 AS rc_off_annaul_saving,
       ri.bill_rate - mi.pay_rate AS rc_off_rate_diff,
        CASE 
          when jr.bill_rate = mi.bill_rate then 'Equal'
          when jr.bill_rate > mi.bill_rate then 'Below'
          when jr.bill_rate < mi.bill_rate then 'Above'
          ELSE NULL
      END AS req_sub_above_within,
       (jr.bill_rate - mi.bill_rate) * 2000 AS req_sub_annaul_saving,
       jr.bill_rate - mi.bill_rate AS req_sub_rate_diff,
        CASE 
          when assign_info.accepted_by_supplier_date is not null then 'Yes'
          else 'No'
        END as OfferAccepted,
        assign_info.accepted_by_supplier_date AS Offerdate,
        mi.pay_rate As OfferRate,
        mi.cand_approved_date AS FinalApprovalCompletedDate,
        jp.job_closed_date as request_filled_date,
              bo.enterprise_name as level_0_ou_name,
       'None' as level_1_ou_name,
       'None' as level_2_ou_name,
       'None' as level_3_ou_name,
       'None' as level_4_ou_name,
       'None' as level_5_ou_name,
        ri.rcc1,
        ri.rcc2,
       pa.pa_name as procurement_project_name,
       CASE WHEN pa.project_agreement_id  is not null THEN
            'Yes'
       ELSE 
            'No'
       END AS project_or_services,
       CASE WHEN lj.job_source_of_record  IN ('MWO') then 'Yes'  -- targeted jobs
       ELSE 'No'
       END as candidate_pre_identified,
       TRUNC(drs.date_released_to_supplier) -  TRUNC(drs.date_req_approved)  AS ct_approved_to_released,
       TRUNC(assign_info.assignment_start_dt) - TRUNC(drs.final_req_appr_date) as ct_final_approval_onboarded,
       TRUNC(jp.first_cand_offered_pos) - TRUNC(cs.first_cand_submitted) as ct_first_cand_to_first_offer, 
       TRUNC(cs.first_cand_submitted) - TRUNC(drs.date_released_to_supplier) as ct_first_supp_first_cand,
       TRUNC(mi.cand_offered_position) - TRUNC(mi.interested_in_cand) as ct_hm_qualified_offer, 
       NULL AS ct_msp_qual_to_hm_qualified,
       TRUNC(assign_info.accepted_by_supplier_date) - TRUNC(cand_final_approved_date) AS ct_offer_accpt_to_approval,
       TRUNC(assign_info.accepted_by_supplier_date) - TRUNC(assign_info.assignment_start_dt) as ct_offer_to_onboarded,
       TRUNC(assign_info.accepted_by_supplier_date) - TRUNC(mi.cand_offered_position) as offer_to_offer_accepted, 
       TRUNC(cs.first_cand_submitted) - TRUNC(drs.date_released_to_supplier) as ct_req_rel_to_submitted,
       NULL  AS ct_sub_to_msp_qualified,
       TRUNC(mi.interested_in_cand) - TRUNC(mi.creation_date) as ct_sub_to_hm_qualified,
       TRUNC(assign_info.accepted_by_supplier_date) -  TRUNC(mi.creation_date)  as ct_sub_to_accpt_offer,   -- supplier receive offer 
       TRUNC(assign_info.accepted_by_supplier_date) - TRUNC(drs.job_sub_matching_date)  as ct_req_sub_to_accpt_offer,
       TRUNC(drs.final_req_appr_date)  - TRUNC(drs.job_sub_matching_date) as ct_to_approve,
       NVL(TRUNC(lj.approved_date),TRUNC(job_position_info.job_rejected_date)) -  TRUNC(lj.job_sub_matching_date) AS ct_to_approve_reject,
       TRUNC(job_position_info.job_closed_to_new_matches) - TRUNC(lj.job_sub_matching_date) as ct_req_sub_to_filled,
       TRUNC(job_position_info.job_closed_to_new_matches) - TRUNC(drs.date_released_to_supplier) as ct_to_sub_candidate            
  FROM
        OPERATIONALSTORE.match_iqp mi
        INNER JOIN OPERATIONALSTORE.job_iqp lj
            ON (mi.job_id = lj.job_id)
        INNER JOIN OPERATIONALSTORE.bus_org_iqp bo
            ON ( lj.buyer_org_id = bo.bus_org_id )
        INNER JOIN OPERATIONALSTORE.job_rates_iqp jr
            ON ( lj.job_id = jr.job_id )
        INNER JOIN OPERATIONALSTORE.job_position_iqp jp
            ON ( lj.job_id = jp.job_id )
        INNER JOIN OPERATIONALSTORE.bus_org_iqp so
            ON ( mi.supplier_org_id = so.bus_org_id )
        LEFT JOIN OPERATIONALSTORE.single_loc_jobs soj
            ON ( lj.job_id = soj.job_id )
        LEFT JOIN OPERATIONALSTORE.job_work_location_iqp jwl
            ON ( jwl.job_id = soj.job_id and jwl.place_id = soj.place_id )
        LEFT JOIN OPERATIONALSTORE.lego_place_iqp pl
            ON ( jwl.place_id = pl.place_id )
        LEFT JOIN OPERATIONALSTORE.person_iqp pi1
            ON ( mi.candidate_id = pi1.candidate_id )
        LEFT JOIN OPERATIONALSTORE.person_iqp pi
            ON ( lj.HIRING_MGR_person_id = pi.person_id ) 
        LEFT JOIN OPERATIONALSTORE.MATCH_STATS_BY_JOB_IQP msj
            ON (lj.job_id = msj.job_id)
        LEFT JOIN operationalstore.intrvw intv
          ON (mi.match_id = intv.match_id)
        LEFT JOIN OPERATIONALSTORE.rate_card_info ri
          ON (lj.job_id = ri.job_id) 
        LEFT JOIN OPERATiONALSTORE.position_offer_info jp
            ON (jp.buyer_org_id = mi.buyer_org_id
               AND jp.supplier_org_id = mi.supplier_org_id
               AND jp.job_id = mi.job_id
               AND jp.candidate_id = mi.candidate_id )
        LEFT JOIN OPERATIONALSTORE.date_released_to_supplier_info drs
            ON (drs.buyer_org_id = mi.buyer_org_id
                AND drs.supplier_org_id = mi.supplier_org_id
                AND drs.job_id = mi.job_id)
        LEFT JOIN OPERATIONALSTORE.cand_submitted_by_supplier cs
            ON (cs.buyer_org_id = mi.buyer_org_id
                AND cs.supplier_org_id = mi.supplier_org_id
                AND cs.job_id = mi.job_id
                AND cs.candidate_id = mi.candidate_id) 
        LEFT JOIN operationalstore.assignment_info assign_info
          ON (mi.buyer_org_id = assign_info.buyer_org_id
            AND mi.supplier_org_id = assign_info.supplier_org_id
            AND mi.job_id = assign_info.job_id
            AND mi.offer_id = assign_info.offer_id
            AND mi.candidate_id = assign_info.candidate_id            )
        LEFT JOIN operatinalstore.job_position_info job_position_info
          ON (mi.buyer_org_id = job_position_info.buyer_org_id
           AND mi.job_id = job_position_info.job_id)           
        LEFT JOIN OPERATIONALSTORE.project_agreement_iqp pa
          ON (pa.project_agreement_id = lj.project_agreement_id)
        CROSS JOIN OPERATIONALSTORE.LastRefresh lr
                WHERE   mi.CREATION_DATE between ADD_MONTHS (TRUNC (SYSDATE,'mm'), -24) and  trunc(sysdate,'MM') -1
/
