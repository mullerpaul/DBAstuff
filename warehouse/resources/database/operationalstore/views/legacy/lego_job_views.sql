/*******************************************************************************
SCRIPT NAME         lego_job_views.sql 
 
LEGO OBJECT NAME    LEGO_JOB
 
CREATED             7/14/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************
 
07/14/2014 - J.Pullifrone - IQN-18303 - added pwfe_agreement_creation_type column - Release 12.1.2 
07/15/2014 - J.Pullifrone - IQN-18303 - added proposed_approvable_aspects_id column - Release 12.1.2 
   
*******************************************************************************/  
CREATE OR REPLACE FORCE VIEW lego_job_vw 
AS
SELECT j.job_id,
       j.buyer_org_id,
       j.hiring_mgr_person_id,
       j.owner_person_id,
       j.creator_person_id,
       j.cac_collection1_id,
       j.cac_collection2_id,
       j.job_state_id,
       j.project_agreement_id,
       j.rate_card_identifier_id,
       j.source_template_id,
       j.pwfe_agreement_creation_type,
       j.proposed_approvable_aspects_id,
       j.udf_collection_id,
       j.positions_total,
       j.positions_filled,
       j.positions_available_cur,
       j.positions_available_nf,
       j.positions_pending,
       j.positions_closed,
       j.template_availability,
       j.allow_overfill,
       j.allow_overfill_zero_position,
       j.allow_overfill_null_position,
       j.overfill_tolerance,
       j.overfill_tolerance_type,
       NVL(job_title_jcl.job_title, j.job_position_title) AS job_position_title,
       j.job_description_lp,
       j.job_position_title_lp,
       j.jc_value,
       j.jc_type,
       CASE 
          WHEN j.jc_type = 'CONSTANT' THEN NVL(jc_jcl.constant_description, j.jc_description) 
          WHEN j.jc_type = 'CUSTOM'   THEN NVL(jc_cust.jc_description, NVL(jc_jcl.constant_description, j.jc_description))
          ELSE j.jc_description
       END AS jc_description,
       j.org_sub_classification,
       j.job_created_date,
       j.job_sub_matching_date,
       j.job_start_date,
       j.job_canceled_date,
       j.reason_canceled,
       j.job_closed_date,
       j.job_archived_date,
       j.last_modified_date,
       j.job_duration_min,
       j.job_duration_max,
       j.job_duration_unit,
       j.target_distro,
       j.candidates_submitted,
       j.candidates_interviewed,
       j.pass_candidate_screening_cnt,
       j.fail_candidate_screening_cnt,
       j.cam_names,
       j.job_source_of_record,
       NVL(state_jcl.constant_description, j.job_state) AS job_state,
       NVL(job_app_jcl.constant_description, j.job_approval_status) AS job_approval_status,
       j.jl_value,
       j.jl_type,
       CASE 
          WHEN j.jl_type = 'CONSTANT' THEN NVL(jl_jcl.constant_description, j.job_level_desc) 
          WHEN j.jl_type = 'CUSTOM'   THEN NVL(jl_cust.job_level_desc, NVL(jl_jcl.constant_description, j.job_level_desc))
          ELSE j.job_level_desc
       END AS job_level_desc,
       j.job_type,
       j.job_description,
       j.job_requisition_type,
       j.job_priority_id,
       NVL(jp_jcl.constant_description, j.job_priority) AS job_priority,
       j.rate_min,
       ROUND(j.rate_min * NVL(cc.conversion_rate, 1), 2) AS rate_min_cc,
       j.rate_max,
       ROUND(j.rate_max * NVL(cc.conversion_rate, 1), 2) AS rate_max_cc,
       j.bill_rate,
       ROUND(j.bill_rate * NVL(cc.conversion_rate, 1), 2) AS bill_rate_cc,
       j.bill_rate_ot,
       ROUND(j.bill_rate_ot * NVL(cc.conversion_rate, 1), 2) AS bill_rate_ot_cc,
       j.bill_rate_dt,
       ROUND(j.bill_rate_dt * NVL(cc.conversion_rate, 1), 2) AS bill_rate_dt_cc,
       j.pay_rate,
       ROUND(j.pay_rate * NVL(cc.conversion_rate, 1), 2) AS pay_rate_cc,
       j.pay_rate_ot,
       ROUND(j.pay_rate_ot * NVL(cc.conversion_rate, 1), 2) AS pay_rate_ot_cc,
       j.pay_rate_dt,
       ROUND(j.pay_rate_dt * NVL(cc.conversion_rate, 1), 2) AS pay_rate_dt_cc,
       j.markup,
       j.markup_ot,
       j.markup_dt,
       j.rate_type_id,
       NVL(rate_jcl.constant_description, j.rate_type)   AS rate_type,
       j.phase_type_id,
       NVL(cp_jcl.constant_description, j.current_phase) AS current_phase,
       j.job_currency_id,
       j.job_currency,
       NVL(cc.converted_currency_id, j.job_currency_id)  AS to_job_currency_id,
       NVL(cc.converted_currency_code, j.job_currency)   AS to_job_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6)              AS conversion_rate
  FROM lego_job j,
       lego_currency_conv_rates_vw cc,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'JOB_PHASE'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) cp_jcl,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'JOB_CATEGORY'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) jc_jcl,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'JOB_STATE'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) state_jcl,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'JP'
           AND UPPER(locale_fk) = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) jp_jcl,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'RES_RATE_BASIS'
           AND UPPER(locale_fk) = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) rate_jcl,
       (SELECT domain_object_oid AS jc_value, 
               locale_preference,
               text1 AS jc_description
          FROM localized_text
         WHERE domain_object_class     = 'CustomJobCategory'
           AND domain_object_attribute = 'localizedTexts'
           AND locale_preference       = (SELECT IQN_SESSION_CONTEXT_PKG.get_current_locale_preference FROM dual)) jc_cust,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'JOB_LEVEL'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) jl_jcl,
       (SELECT domain_object_oid AS jl_value, 
               locale_preference,
               text1 AS job_level_desc
          FROM localized_text
         WHERE domain_object_class     = 'CustomJobLevel'
           AND domain_object_attribute = 'localizedTexts'
           AND locale_preference       = (SELECT IQN_SESSION_CONTEXT_PKG.get_current_locale_preference FROM dual)) jl_cust,
       (SELECT domain_object_oid AS job_id,
               locale_preference,
               text1 AS job_title
          FROM localized_text
         WHERE domain_object_class     = 'Job'
           AND domain_object_attribute = 'POSITION_TITLE'
           AND locale_preference       = (SELECT IQN_SESSION_CONTEXT_PKG.get_current_locale_preference FROM dual)) job_title_jcl,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'ASGNMT_APPROVAL_STATE'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) job_app_jcl
 WHERE j.job_currency_id = cc.original_currency_id(+)
   AND j.phase_type_id   = cp_jcl.constant_value(+)
   AND j.jc_value        = jc_jcl.constant_value(+)
   AND j.jc_value        = jc_cust.jc_value(+)
   AND j.jl_value        = jl_jcl.constant_value(+)
   AND j.jl_value        = jl_cust.jl_value(+)
   AND j.job_state_id    = state_jcl.constant_value(+)
   AND j.job_id          = job_title_jcl.job_id(+)
   AND j.job_approval_status_id = job_app_jcl.constant_value(+)
   AND j.job_priority_id = jp_jcl.constant_value(+)
   AND j.rate_type_id    = rate_jcl.constant_value(+)
   AND j.template_availability IS NULL
/

comment on column LEGO_JOB_VW.JOB_ID is 'JOB_ID is the Primary key for the LEGO_JOB_VW'
/

comment on column LEGO_JOB_VW.POSITIONS_FILLED is 'Positions Filled include those work orders that are currently effective and those awaiting start date that will become effective when the start date is reached.'
/

comment on column LEGO_JOB_VW.TEMPLATE_AVAILABILITY is 'Job Templates have the TEMPLATE_AVAILABILITY column being non-null. If TEMPLATE_AVAILABILTY is null, the row houses an Express Requisition (IS_FAST_PATH = 1) or a Job Requisition (IS_FAST_PATH = 0).'
/

comment on column LEGO_JOB_VW.ALLOW_OVERFILL is 'Allow suppliers to overfill requisitions? 1=Yes, 2=No.'
/

comment on column LEGO_JOB_VW.ALLOW_OVERFILL_ZERO_POSITION is 'Allow overfill for day labor positions with 0 available positions? 1=Yes, 2=No.'
/

comment on column LEGO_JOB_VW.ALLOW_OVERFILL_NULL_POSITION is 'Allow overfill for day labor positions with no defined (blank) available positions? 1=Yes, 2=No.'
/

comment on column LEGO_JOB_VW.JC_VALUE is 'This field is a Foreign Key reference to job_category.value'
/

comment on column LEGO_JOB_VW.JC_TYPE is 'This field contains data from job_category.type'
/

comment on column LEGO_JOB_VW.JC_DESCRIPTION is 'This field contains data from job_category.description'
/

comment on column LEGO_JOB_VW.JOB_SOURCE_OF_RECORD is 'A value of GUI indicates this row was created as the result of using one of the frontoffices editors (e.g. JobEditor). Values other than GUI (MWO = created for a Targeted Order,WOL = created as a result of Work Order loading) indicate this is a mini-job and most likely should not be represented in reports.'
/

comment on column LEGO_JOB_VW.JOB_PRIORITY is 'Based on JOB.JOB_PRIORITY_FK value. 0=Normal, 1=Critical'
/



-----------------------------------

CREATE OR REPLACE FORCE VIEW LEGO_JOB_CAC_VW AS
SELECT job_id, 
       cac_collection_id, 
       cac_id, 
       buyer_org_id, 
       cac_kind, 
       cac_start_date, 
       cac_end_date,
       cac1_segment_1_value, 
       cac1_segment_2_value, 
       cac1_segment_3_value, 
       cac1_segment_4_value, 
       cac1_segment_5_value, 
       cac1_segment_1_desc, 
       cac1_segment_2_desc, 
       cac1_segment_3_desc,  
       cac1_segment_4_desc,
       cac1_segment_5_desc,    
       cac2_segment_1_value,
       cac2_segment_2_value,
       cac2_segment_3_value,
       cac2_segment_4_value,
       cac2_segment_5_value,
       cac2_segment_1_desc,
       cac2_segment_2_desc,
       cac2_segment_3_desc,
       cac2_segment_4_desc,
       cac2_segment_5_desc  
  FROM (
SELECT ljc.job_id               AS job_id,
       ljc.cac_collection_id    AS cac_collection_id,
       ljc.cac_id               AS cac_id,
       ljc.buyer_org_id         AS buyer_org_id,
       ljc.cac_kind             AS cac_kind,
       ljc.cac_start_date       AS cac_start_date,
       ljc.cac_end_date         AS cac_end_date,
       lc.cac_segment_1_value   AS cac1_segment_1_value,
       lc.cac_segment_2_value   AS cac1_segment_2_value,
       lc.cac_segment_3_value   AS cac1_segment_3_value,
       lc.cac_segment_4_value   AS cac1_segment_4_value,
       lc.cac_segment_5_value   AS cac1_segment_5_value,
       lc.cac_segment_1_desc    AS cac1_segment_1_desc,
       lc.cac_segment_2_desc    AS cac1_segment_2_desc,
       lc.cac_segment_3_desc    AS cac1_segment_3_desc,
       lc.cac_segment_4_desc    AS cac1_segment_4_desc,
       lc.cac_segment_5_desc    AS cac1_segment_5_desc,
       NULL                     AS cac2_segment_1_value,
       NULL                     AS cac2_segment_2_value,
       NULL                     AS cac2_segment_3_value,
       NULL                     AS cac2_segment_4_value,
       NULL                     AS cac2_segment_5_value,
       NULL                     AS cac2_segment_1_desc,
       NULL                     AS cac2_segment_2_desc,
       NULL                     AS cac2_segment_3_desc,
       NULL                     AS cac2_segment_4_desc,
       NULL                     AS cac2_segment_5_desc
 FROM lego_job_cac ljc, lego_cac lc
WHERE ljc.cac_guid = lc.cac_guid
  AND cac_kind = 1
UNION ALL
SELECT ljc.job_id               AS job_id,
       ljc.cac_collection_id    AS cac_collection_id,
       ljc.cac_id               AS cac_id,
       ljc.buyer_org_id         AS buyer_org_id,
       ljc.cac_kind             AS cac_kind,
       ljc.cac_start_date       AS cac_start_date,
       ljc.cac_end_date         AS cac_end_date,
       NULL                     AS cac1_segment_1_value,
       NULL                     AS cac1_segment_2_value,
       NULL                     AS cac1_segment_3_value,
       NULL                     AS cac1_segment_4_value,
       NULL                     AS cac1_segment_5_value,
       NULL                     AS cac1_segment_1_desc,
       NULL                     AS cac1_segment_2_desc,
       NULL                     AS cac1_segment_3_desc,
       NULL                     AS cac1_segment_4_desc,
       NULL                     AS cac1_segment_5_desc,
       lc.cac_segment_1_value   AS cac2_segment_1_value,
       lc.cac_segment_2_value   AS cac2_segment_2_value,
       lc.cac_segment_3_value   AS cac2_segment_3_value,
       lc.cac_segment_4_value   AS cac2_segment_4_value,
       lc.cac_segment_5_value   AS cac2_segment_5_value,
       lc.cac_segment_1_desc    AS cac2_segment_1_desc,
       lc.cac_segment_2_desc    AS cac2_segment_2_desc,
       lc.cac_segment_3_desc    AS cac2_segment_3_desc,
       lc.cac_segment_4_desc    AS cac2_segment_4_desc,
       lc.cac_segment_5_desc    AS cac2_segment_5_desc
 FROM lego_job_cac ljc, lego_cac lc
WHERE ljc.cac_guid = lc.cac_guid
  AND ljc.cac_kind = 2)
/

comment on column LEGO_JOB_CAC_VW.JOB_ID is 'This is the Primary Key used for joining with LEGO_JOB_VW'
/

comment on column LEGO_JOB_CAC_VW.BUYER_ORG_ID is 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/



------


CREATE OR REPLACE FORCE VIEW LEGO_JOB_WORK_LOCATION_VW AS
SELECT lj.job_id,
        lj.buyer_org_id,
        lj.place_id,
        NVL(j_place_jcl.constant_description, lj.work_location) AS work_location,
        lj.address_guid
   FROM lego_job_work_location lj,
        (SELECT constant_value, constant_description
           FROM lego_java_constant_lookup
          WHERE constant_type    = 'PLACE'
            AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) j_place_jcl  
  WHERE lj.place_id =  j_place_jcl.constant_value(+)
/

comment on column LEGO_JOB_WORK_LOCATION_VW.JOB_ID is 'This is the Primary Key used for joining with LEGO_JOB_VW'
/

comment on column LEGO_JOB_WORK_LOCATION_VW.BUYER_ORG_ID is 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/

comment on column LEGO_JOB_WORK_LOCATION_VW.ADDRESS_GUID is 'Address Guid is a FK to LEGO_ADDRESS_VW'
/

