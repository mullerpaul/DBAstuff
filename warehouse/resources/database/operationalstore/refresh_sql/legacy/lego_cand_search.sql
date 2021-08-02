/*******************************************************************************
SCRIPT NAME         lego_cand_search.sql 
 
LEGO OBJECT NAME    LEGO_CAND_SEARCH
 
CREATED             07/01/2014
 
ORIGINAL AUTHOR     McKay Dunlap

***************************MODIFICATION HISTORY ********************************

07/14/2014 - Mc-K - IQN-17569 DATA - Add Coloumns Indexes for ResourceIQ  Release 12.2
08/01/2014 - Mc-K - IQN-17673 Lego Modifications for ResourceIQ Search    Release 12.2
08/11/2014 - Mc-K - IQN-19462 DATA - Oracle Text Search Tuning; Added additional fields.
09/14/2014 - Mc-K - IQN-IQN-20373 - Localization.

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_cand_search.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_CAND_SEARCH'; 

  v_clob CLOB := q'{ 
select cand.buyer_org_id, cand.supplier_org_id, cand.assignment_continuity_id, 
       cand.hiring_mgr_person_id,
       cand.buyer_name,
       cand.supplier_name, 
       cand.contractor_person_id, 
       cand.contractor_name, 
       cand.assignment_start_dt, 
       cand.assignment_actual_end_dt, 
       cand.reg_bill_rate, 
       cand.reg_pay_rate, 
       --cand.rate_type, --> localize
       NVL (rate_type_jcl.constant_description, cand.rate_type)
             AS rate_type,
       cand.assignment_currency, 
       cand.hiring_mgr_name, 
       cand.work_location,
       --cand.assignment_state, --> localize
       NVL (as_jcl.constant_description, cand.assignment_state)
             AS assignment_state,
       cand.assignment_state_id, 
       --cand.current_phase, --> Localize
       NVL (cp_jcl.constant_description, cand.current_phase)
             AS current_phase,    
       cand.phase_type_id,
       cand.days_until_assignment_end,
       cand.contractor_do_not_rehire_flag,
       cand.job_id, 
       cand.candidate_id, 
       --cand.job_position_title, --> localize
       --cand.job_position_title assign_job_title, --> localize
       NVL (ass_title_jcl.assign_job_title, cand.job_position_title)
             AS assign_job_title,
       NVL (ass_title_jcl.assign_job_title, cand.job_position_title)
             AS job_position_title,  
       cand.job_description, 
       cand.jc_description,
       cand.job_level_desc,
       (LISTAGG(cand.skills, ', ') WITHIN GROUP (ORDER BY skills)) AS skill_list,
       SUM(cand.skill_len) as skill_len,
       MAX(cand.linkedin_URL) linkedin_URL,
       lt.locale_type_id locale_id,
       lt.name locale_name 
  from  (       
--> Skill Data from job and candidate perspective...============================
select la_j.buyer_org_id, la_j.supplier_org_id, la_j.assignment_continuity_id, la_j.current_edition_id,
       la_j.hiring_mgr_person_id, la_j.job_id, la_j.candidate_id, 
       lbo.buyer_name,
       lso.supplier_name, 
       la_j.contractor_person_id, 
       pc.contractor_name, 
       la_j.assignment_start_dt, 
       la_j.assignment_actual_end_dt, 
       la_j.reg_bill_rate, 
       la_j.reg_pay_rate, 
       la_j.rate_type, 
       la_j.rate_type_id,
       la_j.assignment_currency,  
       hm.hiring_mgr_name, 
       lad.city || NVL2(lad.city, ', ', NULL) || lad.state || NVL2(lad.state, ', ', NULL) || lad.country AS work_location,
       la_j.assignment_state,
       la_j.current_phase,
       la_j.assignment_state_id, --> pull in for localization
       la_j.phase_type_id,
       la_j.days_until_assignment_end,
       pc.contractor_do_not_rehire_flag,
       TRIM(la_j.assign_job_title) job_position_title, 
       TRIM(NVL(la_j.assign_jc_description, lj.jc_description)) jc_description, 
       TRIM(lj.job_description) job_description, 
       TRIM(lj.job_level_desc) job_level_desc, 
       TRIM(st_j.description) skills,
       LENGTH(st_j.description)+LENGTH(la_j.assign_jc_description)+LENGTH(la_j.assign_job_title)+LENGTH(lj.job_level_desc) skill_len,
       '' as linkedin_URL
from 
 --> job-derived skills ========================================================
     lego_assignment_vw la_j, lego_job_vw lj, job j, resource_profile rp, res_prof_skill_x rps, 
     lego_address_vw lad, 
     lego_person_contractor_vw pc,
     lego_person_hiring_mgr_vw hm,
     lego_supplier_org_vw  lso,
     lego_buyer_org_vw lbo, 
      (select * from skill_topic st1, skill s2 
       where s2.skill_topic_fk = st1.value 
         and st1.description  not in ('iqn generic role', 'iqn generic skill')) st_j
where la_j.buyer_org_id = lbo.buyer_org_id
     AND lso.supplier_org_id = la_j.supplier_org_id
     AND la_j.hiring_mgr_person_id = hm.hiring_mgr_person_id 
     AND la_j.job_id = lj.job_id(+)
     AND lj.job_id = j.job_id(+)
     and j.resource_profile_fk = rp.resource_profile_id (+)
     and rp.resource_profile_id = rps.resource_profile_id (+)
     and rps.skill_id = st_j.skill_id (+)
     AND la_j.contractor_person_id = pc.contractor_person_id(+)  
     AND la_j.address_guid =lad.address_guid (+)
UNION
SELECT la_c.buyer_org_id, la_c.supplier_org_id, la_c.assignment_continuity_id, la_c.current_edition_id,
       la_c.hiring_mgr_person_id, la_c.job_id, la_c.candidate_id, 
       lbo.buyer_name,
       lso.supplier_name, 
       la_c.contractor_person_id, 
       pc.contractor_name, 
       la_c.assignment_start_dt, 
       la_c.assignment_actual_end_dt, 
       la_c.reg_bill_rate, 
       la_c.reg_pay_rate, 
       la_c.rate_type, 
       la_c.rate_type_id, 
       la_c.assignment_currency, 
       hm.hiring_mgr_name, 
       lad.city || NVL2(lad.city, ', ', NULL) || lad.state || NVL2(lad.state, ', ', NULL) || lad.country AS work_location,
       la_c.assignment_state,
       la_c.current_phase, 
       la_c.assignment_state_id, 
       la_c.phase_type_id,
       la_c.days_until_assignment_end,
       pc.contractor_do_not_rehire_flag,
       TRIM(la_c.assign_job_title) job_position_title, 
       TRIM(NVL(la_c.assign_jc_description, lj.jc_description)) jc_description, 
       TRIM(lj.job_description) job_description, 
       TRIM(lj.job_level_desc) job_level_desc, 
       TRIM(st_c.description) skills,
       LENGTH(st_c.description) skill_len,
       c.linkedin_URL
  from 
 --> candidate-derived skills ========================================================
     lego_assignment_vw la_c, lego_job_vw lj, candidate c, 
     lego_address_vw lad, 
     lego_person_contractor_vw  pc,
     lego_person_hiring_mgr_vw hm,
     lego_supplier_org_vw  lso,
     lego_buyer_org_vw lbo,
     resource_profile rp_c, res_prof_skill_x rps_c, 
      (select * from skill_topic st1, skill s2 
       where s2.skill_topic_fk = st1.value 
         and st1.description  not in ('iqn generic role', 'iqn generic skill')) st_c
where la_c.buyer_org_id = lbo.buyer_org_id  
  AND lso.supplier_org_id = la_c.supplier_org_id
  AND la_c.hiring_mgr_person_id = hm.hiring_mgr_person_id 
  AND la_c.job_id = lj.job_id(+)
  AND la_c.candidate_id = c.candidate_id (+)
  AND c.resource_profile_fk = rp_c.resource_profile_id (+)
  AND rp_c.resource_profile_id = rps_c.resource_profile_id (+)
  AND rps_c.skill_id = st_c.skill_id (+)
  AND la_c.contractor_person_id = pc.contractor_person_id  (+)
  AND la_c.address_guid = lad.address_guid (+)
  ) cand  
    --> Translate locale string to number and include all possible values.
    JOIN LEGO_LOCALES_BY_BUYER_ORG_VW lbb ON cand.buyer_org_id = lbb.buyer_org_id
    JOIN LOCALE_TYPE lt ON lbb.locale_preference = lt.locale_type_id
    LEFT OUTER JOIN 
  --> Pull in translated values otherwise default to english.  
          (SELECT constant_value, constant_description, locale_fk --join here
             FROM lego_java_constant_lookup
            WHERE constant_type = 'SEARCHABLE_ASGNMT_STATE') as_jcl
       ON (lt.name = as_jcl.locale_fk and cand.assignment_state_id = as_jcl.constant_value)
     LEFT OUTER JOIN 
          (SELECT constant_value, constant_description, locale_fk --> join here
             FROM lego_java_constant_lookup
            WHERE constant_type = 'ASSIGNMENT_PHASE') cp_jcl
       ON  (lt.name = cp_jcl.locale_fk and cand.phase_type_id = cp_jcl.constant_value)    
    LEFT OUTER JOIN    
          (SELECT domain_object_oid AS current_edition_id, locale_preference,  --> join on this
                  text1 AS assign_job_title
             FROM localized_text
            WHERE domain_object_class = 'AssignmentEdition'
                  AND domain_object_attribute = 'JOB_TITLE') ass_title_jcl
      ON (lt.locale_type_id = ass_title_jcl.locale_preference and cand.current_edition_id = ass_title_jcl.current_edition_id)
    LEFT OUTER JOIN    
          (SELECT constant_value, constant_description, locale_fk
             FROM lego_java_constant_lookup
            WHERE constant_type = 'RES_RATE_BASIS') rate_type_jcl
      ON (lt.name = rate_type_jcl.locale_fk and cand.rate_type_id = rate_type_jcl.constant_value)      
  where cand.contractor_do_not_rehire_flag <>  'Y'
Group by cand.buyer_org_id, cand.supplier_org_id, cand.assignment_continuity_id, 
       cand.hiring_mgr_person_id,
       cand.job_id, cand.candidate_id, 
       cand.buyer_name,
       cand.supplier_name, 
       cand.contractor_person_id, 
       cand.contractor_name, 
       cand.assignment_start_dt, 
       cand.assignment_actual_end_dt, 
       cand.reg_bill_rate, 
       cand.reg_pay_rate, 
       cand.rate_type, 
       cand.assignment_currency, 
       cand.hiring_mgr_name, 
       cand.work_location,
       cand.assignment_state,
       cand.current_phase,
       cand.assignment_state_id, 
       cand.phase_type_id,
       cand.days_until_assignment_end,cand.contractor_do_not_rehire_flag,
       cand.job_position_title, cand.jc_description, cand.job_level_desc,  cand.job_description,
       --> Localization Changes.
        NVL (rate_type_jcl.constant_description, cand.rate_type),
        NVL (as_jcl.constant_description, cand.assignment_state),
        NVL (cp_jcl.constant_description, cand.current_phase), 
        NVL (ass_title_jcl.assign_job_title, cand.job_position_title),
        lt.locale_type_id,
        lt.name 
  Order by buyer_org_id
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

