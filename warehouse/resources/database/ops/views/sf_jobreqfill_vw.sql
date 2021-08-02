CREATE OR REPLACE FORCE VIEW "OPS"."SF_JOBREQFILL_VW" 
("SOURCE_LOCATION", "RECORD_TYPE", "BUYER_ORG_ID", "ENTERPRISE_NAME", "BUYER_ORG_NAME", "INDUSTRY_NAME"
, "BUYER_MANAGE_NAME", "REQUISITION_ID", "HIRING_MANAGER_PERSON_ID", "HIRING_MANAGER_NAME", "REQUISITION_CREATOR_NAME", "REQUISITION_CREATE_DATE", "REQUISITION_STATE", "JOB_TITLE", "JOB_CATEGORY", "REQUISITION_TYPE", "BILL_RATE", "RATE_TYPE", "RATE_TYPE_NEW", "CURRENCY", "POSITIONS_TOTAL", "POSITIONS_FILLED", "CURRENT_POSITIONS_AVAILABLE", "JOB_CANCELED_DATE", "JOB_CLOSED_DATE", "SUPP_OPPORTUNITY_COUNT", "SUPP_ACTIVE_OPPORTUNITY_COUNT", "TOTAL_CANDIDATES_SUMBITTED", "EARLIEST_MATCH_SUBMISSION"
, "EARLIEST_OFFER_MADE", "COUNTRY_CODE", "COUNTRY", "STATE", "CITY", "ASSIGNMENT_COUNT", "ASSIGN_JOB_ID", "CONTACT_COUNT", "MAXASGNREGBILLRATE", "MINASGNREGBILLRATE", "MEDASGNREGBILLRATE", "ASSIGNMENT_TYPE", "CT_APPROVED_TO_RELEASED", "JOB_START_DATE"
, "DATE_FIRST_RELEASED", "PROJECT_AGREEMENT_ID", "PRODUCT") AS 
  WITH supplier_opportunities_per_job
    AS (SELECT job_id,
               COUNT(*) AS supp_opportunity_count,
               COUNT(CASE WHEN state = 'Active' THEN 'x' END) AS supp_active_opportunity_count
          FROM operationalstore.job_opportunity_iqp 
         GROUP BY job_id),
    supplier_opportus_per_jb_wf
    AS (SELECT job_id,
               COUNT(*) AS supp_opportunity_count,
               COUNT(CASE WHEN state = 'Active' THEN 'x' END) AS supp_active_opportunity_count
          FROM operationalstore.job_opportunity_wf
         GROUP BY job_id),
       match_info_per_job
    AS (SELECT job_id,
               COUNT(*) as match_count,
               COUNT(DISTINCT candidate_id) as distinct_cand_id_count,
               MIN(creation_date) AS earliest_match,
               MIN(cand_offered_position) AS earliest_offer
          FROM operationalstore.match_iqp 
         GROUP BY job_id),
       match_info_per_job_wf
    AS (SELECT job_id,
               COUNT(*) as match_count,
               COUNT(DISTINCT candidate_id) as distinct_cand_id_count,
               MIN(creation_date) AS earliest_match,
               MIN(cand_offered_position) AS earliest_offer
          FROM operationalstore.match_wf 
         GROUP BY job_id),  
     date_released_info
     AS ( SELECT jo.buyer_org_id,
                 --jo.supplier_org_id,
                 jo.job_id, 
                 min(job_sub_matching_date) as job_sub_matching_date,
                 min(j.job_created_date) as requisition_create_date,
                 MAX(CASE WHEN j.job_approval_status IN ('Approved', 'Approval Not Required') 
                      THEN (NVL(j.approved_date,j.job_created_date ))
                  ELSE NULL
                 END) AS final_req_appr_date,
                 min(jo.create_date) date_first_released
           FROM operationalstore.job_iqp j
             INNER JOIN  operationalstore.job_opportunity_iqp jo              
                ON ( jo.job_id = j.job_id)         
            group by jo.buyer_org_id, --jo.supplier_org_id, 
            jo.job_id
            ),  
      date_released_info_wf
     AS ( SELECT jo.buyer_org_id,
                 --jo.supplier_org_id,
                 jo.job_id, 
                 min(job_sub_matching_date) as job_sub_matching_date,
                 min(j.job_created_date) as requisition_create_date,
                 MAX(CASE WHEN j.job_approval_status IN ('Approved', 'Approval Not Required') 
                      THEN (NVL(j.approved_date,j.job_created_date ))
                  ELSE NULL
                 END) AS final_req_appr_date,
                 min(jo.create_date) date_first_released
           FROM operationalstore.job_wf j
             INNER JOIN  operationalstore.job_opportunity_wf jo              
                ON ( jo.job_id = j.job_id)         
            group by jo.buyer_org_id, --jo.supplier_org_id, 
            jo.job_id
            ),       
       job_assignment_location_info
    AS (SELECT a.job_id, ladd.country_code, ladd.state, ladd.city, count(distinct a.assignment_continuity_id) AssignCt, count(distinct  a.contact_info_id) contactCt,
               MAX(a.reg_bill_rate) MaxAsgnRegBillRate,  MIN(a.reg_bill_rate) MinAsgnRegBillRate, Median(a.reg_bill_rate) MEDAsgnRegBillRate,  a.Assignment_Type, ladd.country
          FROM operationalstore.lego_contact_address_iqp lca, -- select * from operationalstore.lego_contact_address_iqp@IQP_US_IQMCE_OPS
               operationalstore.lego_address_iqp ladd, -- SELECT * FROM operationalstore.lego_address_iqp@IQP_US_IQMCE_OPS 
               (SELECT 'WO' Assignment_Type, assignment_continuity_id, job_id, contact_info_id, Reg_bill_rate
                  FROM operationalstore.assignment_wo_iqp
                 UNION ALL
                SELECT 'EA' Assignment_Type, assignment_continuity_id, job_id, contact_info_id, Reg_bill_rate
                  FROM operationalstore.assignment_ea_iqp
                 UNION ALL
                SELECT 'TA' Assignment_Type, assignment_continuity_id, job_id, contact_info_id, 0 as Reg_bill_rate
                  FROM operationalstore.assignment_ta_iqp) a
         WHERE a.contact_info_id = lca.contact_info_id
           AND lca.primary_address_guid = ladd.address_guid
     GROUP BY a.job_id, ladd.country_code, ladd.state, ladd.city,  a.Assignment_Type, ladd.country ),
     job_assgnt_location_info_wf
    AS (SELECT a.job_id, ladd.country_code, ladd.state, ladd.city, count(distinct a.assignment_continuity_id) AssignCt, count(distinct  a.contact_info_id) contactCt,
               MAX(a.reg_bill_rate) MaxAsgnRegBillRate,  MIN(a.reg_bill_rate) MinAsgnRegBillRate, Median(a.reg_bill_rate) MEDAsgnRegBillRate,  a.Assignment_Type, ladd.country
          FROM operationalstore.lego_contact_address_iqp lca, -- select * from operationalstore.lego_contact_address_iqp@IQP_US_IQMCE_OPS
               operationalstore.lego_address_iqp ladd, -- SELECT * FROM operationalstore.lego_address_iqp@IQP_US_IQMCE_OPS 
               (SELECT 'WO' Assignment_Type, assignment_continuity_id, job_id, contact_info_id, Reg_bill_rate
                  FROM operationalstore.assignment_wo_wf
                 UNION ALL
                SELECT 'EA' Assignment_Type, assignment_continuity_id, job_id, contact_info_id, Reg_bill_rate
                  FROM operationalstore.assignment_ea_wf
                 UNION ALL
                SELECT 'TA' Assignment_Type, assignment_continuity_id, job_id, contact_info_id, 0 as Reg_bill_rate
                  FROM operationalstore.assignment_ta_wf) a
         WHERE a.contact_info_id = lca.contact_info_id
           AND lca.primary_address_guid = ladd.address_guid
     GROUP BY a.job_id, ladd.country_code, ladd.state, ladd.city,  a.Assignment_Type, ladd.country ),
     ever_invoiced
     AS (select   SOURCE_NAME, JOB_ID from operationalstore.lego_invd_expd_date_ru
      group BY SOURCE_NAME, JOB_ID)
SELECT 'USPROD' AS source_location,
       'Request' as Record_type,
       j.buyer_org_id, 
       bw.enterprise_name , 
       bw.bus_org_name buyer_org_name,
       dmb.Industry_name, 
       bw.managing_organization_name Buyer_Manage_name,
       j.job_id AS requisition_id,
       hmp.person_id as hiring_manager_person_id,
       hmp.display_name AS hiring_manager_name,
       jcp.display_name AS requisition_creator_name,
       j.job_created_date AS requisition_create_date,
       j.job_state AS requisition_state,
       j.job_position_title AS job_title,
       j.jc_description AS job_category,
       j.job_type as requisition_type,
       jr.bill_rate,
       jr.rate_type,
       jr.rate_type_new,
       jr.job_currency as currency,
       jp.positions_total,
       jp.positions_filled,
       jp.positions_available_cur AS current_positions_available,
       jp.job_canceled_date,
       jp.job_closed_date,
       so.supp_opportunity_count,
       so.supp_active_opportunity_count,
       jm.distinct_cand_id_count AS total_candidates_sumbitted,  --may not be correct, same cand. submitted by multiple suppliers counts multiple times
       jm.earliest_match AS earliest_match_submission,
       jm.earliest_offer AS earliest_offer_made,
       jal.country_code,
        jal.country,
       jal.state AS state,
       jal.city AS city,
       jal.AssignCt as assignment_count,
       jal.job_id as assign_job_id,
       jal.contactCt as contact_count,
       jal.MaxAsgnRegBillRate,
       jal.MinAsgnRegBillRate,
       jal.MEDAsgnRegBillRate,
       jal.Assignment_Type,
       -- Cycle Times: ===================================================
       TRUNC(dri.final_req_appr_date) - TRUNC(dri.date_first_released )  AS ct_approved_to_released,
       j.job_start_date,
       dri.date_first_released,
      j.project_agreement_id,
      (CASE
      WHEN j.project_agreement_id IS NOT NULL THEN 'SOW'
        WHEN (j.project_agreement_id IS NULL AND EVER_INVOICED.job_id IS NULL) THEN 'Headcount Tracking'
        WHEN (j.project_agreement_id IS NULL AND EVER_INVOICED.job_id IS NOT NULL) THEN 'Contingent'
        ELSE 'Unknown'
      END) as Product
       FROM operationalstore.job_iqp j
       JOIN operationalstore.person_iqp hmp
         ON j.hiring_mgr_person_id = hmp.person_id
       JOIN operationalstore.person_iqp jcp
         ON j.creator_person_id = jcp.person_id
  LEFT JOIN operationalstore.job_position_iqp jp
         ON j.job_id = jp.job_id   -- May not need be need
  LEFT JOIN operationalstore.job_rates_iqp jr
         ON j.job_id = jr.job_id   
       JOIN supplier_opportunities_per_job so
         ON j.job_id = so.job_id
  LEFT JOIN match_info_per_job jm 
         ON j.job_id = jm.job_id 
  LEFT JOIN job_assignment_location_info jal
         ON j.job_id = jal.job_id 
  LEFT JOIN OPERATIONALSTORE.BUS_ORG_iqp bw 
         ON j.buyer_org_id = bw.bus_org_id -- select * from 
  LEFT JOIN IQPRODM.DM_BUYERS dmb -- May revmove this
         ON bw.enterprise_bus_org_id = dmb.std_buyerorg_id 
  LEFT JOIN date_released_info dri
         ON (dri.buyer_org_id = j.buyer_org_id
        AND dri.job_id = j.job_id)
  LEFT JOIN ever_invoiced 
        ON ever_invoiced.source_name = 'USPROD'
        AND j.job_id = ever_invoiced.job_id
UNION
SELECT 'WFPROD' AS source_location,
       'Request' as Record_type,
       j.buyer_org_id, 
       bw.enterprise_name , 
       bw.bus_org_name buyer_org_name,
       dmb.Industry_name, 
       bw.managing_organization_name Buyer_Manage_name,
       j.job_id AS requisition_id,
       hmp.person_id as hiring_manager_person_id,
       hmp.display_name AS hiring_manager_name,
       jcp.display_name AS requisition_creator_name,
       j.job_created_date AS requisition_create_date,
       j.job_state AS requisition_state,
       j.job_position_title AS job_title,
       j.jc_description AS job_category,
       j.job_type as requisition_type,
       jr.bill_rate,
       jr.rate_type,
       jr.rate_type_new,
       jr.job_currency as currency,
       jp.positions_total,
       jp.positions_filled,
       jp.positions_available_cur AS current_positions_available,
       jp.job_canceled_date,
       jp.job_closed_date,
       so.supp_opportunity_count,
       so.supp_active_opportunity_count,
       jm.distinct_cand_id_count AS total_candidates_sumbitted,  --may not be correct, same cand. submitted by multiple suppliers counts multiple times
       jm.earliest_match AS earliest_match_submission,
       jm.earliest_offer AS earliest_offer_made,
       jal.country_code,
        jal.country,
       jal.state AS state,
       jal.city AS city,
       jal.AssignCt as assignment_count,
       jal.job_id as assign_job_id,
       jal.contactCt as contact_count,
       jal.MaxAsgnRegBillRate,
       jal.MinAsgnRegBillRate,
       jal.MEDAsgnRegBillRate,
       jal.Assignment_Type,
       -- Cycle Times: ===================================================
       TRUNC(dri.final_req_appr_date) - TRUNC(dri.date_first_released )  AS ct_approved_to_released,
       j.job_start_date,
       dri.date_first_released,
      j.PROJECT_AGREEMENT_ID,
      (CASE
      WHEN j.project_agreement_id IS NOT NULL THEN 'SOW'
        WHEN (j.project_agreement_id IS NULL AND EVER_INVOICED.job_id IS NULL) THEN 'Headcount Tracking'
        WHEN (j.project_agreement_id  IS NULL AND EVER_INVOICED.job_id IS NOT NULL) THEN 'Contingent'
        ELSE 'Unknown'
      END) as Product
       FROM operationalstore.job_wf j
       JOIN operationalstore.person_wf hmp
         ON j.hiring_mgr_person_id = hmp.person_id
       JOIN operationalstore.person_wf jcp
         ON j.creator_person_id = jcp.person_id
  LEFT JOIN operationalstore.job_position_wf jp
         ON j.job_id = jp.job_id   -- May not need be need
  LEFT JOIN OPERATIONALSTORE.job_rates_wf jr
         ON j.job_id = jr.job_id   
       JOIN supplier_opportus_per_jb_wf so
         ON j.job_id = so.job_id
  LEFT JOIN match_info_per_job_wf jm 
         ON j.job_id = jm.job_id 
  LEFT JOIN job_assgnt_location_info_wf jal
         ON j.job_id = jal.job_id 
  LEFT JOIN OPERATIONALSTORE.BUS_ORG_wf bw 
         ON j.buyer_org_id = bw.bus_org_id -- select * from 
  LEFT JOIN IQPRODM.DM_BUYERS dmb -- May revmove this
         ON bw.enterprise_bus_org_id = dmb.std_buyerorg_id 
  LEFT JOIN date_released_info_wf dri
         ON (dri.buyer_org_id = j.buyer_org_id
        AND dri.job_id = j.job_id)
  LEFT JOIN ever_invoiced 
        ON ever_invoiced.source_name = 'WFPROD'
        AND j.job_id = ever_invoiced.job_id
        /
