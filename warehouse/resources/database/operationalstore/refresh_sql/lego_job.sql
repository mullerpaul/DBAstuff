/*******************************************************************************
SCRIPT NAME         lego_job.sql 
 
LEGO OBJECT NAME    LEGO_JOB
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark      - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
04/11/2014 - E.Clark      - IQN-15353 - localized RATE_TYPE and JOB_PRIORITY- Release 12.0.3
07/14/2014 - J.Pullifrone - IQN-18303 - added pwfe_agreement_creation_type - Release 12.1.2  
07/15/2014 - J.Pullifrone - IQN-18303 - added proposed_approvable_aspects_id - Release 12.1.2
01/27/2016 - P.Muller                 - modifications for DB links, multiple sources, and remote SCN
03/07/2016 - P.Muller                 - get rid of position and candidate count columns, listagg columns, CAC columns
05/04/2016 - J.Pullifrone             - remove rate info and put in separate lego
09/13/2016 - J.Pullifrone - IQN-32037 - add job_template job description 
05/03/2016 - J.Pullifrone - IQN-37554 - add approved_date
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_job.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JOB'; 

  v_clob CLOB := q'{
SELECT j.job_id,
       bfr.business_org_fk          AS buyer_org_id,
       hfw.never_null_person_fk     AS hiring_mgr_person_id,
       ofw.never_null_person_fk     AS owner_person_id,
       cfw.never_null_person_fk     AS creator_person_id,
       CASE WHEN j.source_of_record != 'GUI' THEN 3
          ELSE j.job_state_fk
       END                          AS job_state_id,
       j.project_agreement_fk       AS project_agreement_id,
       pw.agreement_creation_type   AS pwfe_agreement_creation_type,
       j.proposed_approvable_aspects_fk AS proposed_approvable_aspects_id,
       j.udf_collection_fk          AS udf_collection_id,
       DECODE(j.template_type,'C','Company','P','Personal',NULL) AS template_availability,
       pw.allow_overfill,
       pw.allow_overfill_zero_position,
       pw.allow_overfill_null_position,
       pw.overfill_tolerance,
       DECODE(pw.overfill_tolerance_type, 0,'Percent', 1, 'Positions', 2, 'Unlimited') AS overfill_tolerance_type,
       j.position_title              AS job_position_title,
       j.description_lp              AS job_description_lp,
       j.position_title_lp           AS job_position_title_lp,
       jc.value                      AS jc_value,
       jc.type                       AS jc_type,
       jc.description                AS jc_description,
       j.org_sub_classification,
       j.create_date                 AS job_created_date,
	   aprv_dt.approved_date,
       j.date_submitted_for_matching AS job_sub_matching_date,
       TRUNC(j.start_date)           AS job_start_date,
       j.archived_date               AS job_archived_date,
       j.last_modified_date          AS last_modified_date,
       CASE WHEN j.is_fast_path = 0 THEN NVL(jcet.min_duration,0)
            ELSE CASE WHEN NVL(jcet.min_duration,'0') = 0 AND NVL(jcet.max_duration,'0') = 0 THEN paj.min_duration
                      ELSE NVL(jcet.min_duration,'0')
                 END
       END AS job_duration_min,
       CASE WHEN j.is_fast_path = 0 THEN NVL(jcet.max_duration,0)
            ELSE CASE WHEN NVL(jcet.min_duration,'0') = 0 AND NVL(jcet.max_duration,'0') = 0 THEN paj.max_duration
                      ELSE NVL(jcet.max_duration,'0')
                 END
       END AS job_duration_max,
       du.type AS job_duration_unit,
       j.source_of_record AS job_source_of_record,
       DECODE(CASE WHEN j.source_of_record != 'GUI' THEN 3
              ELSE j.job_state_fk
              END,
          1, 'Under Development',
          2, 'Active',
          3, 'Closed',
          5, 'Canceled',
          13, 'Under Contract',
          14, 'Closed to New Matches') AS job_state,
       CASE j.internal_approval_state
          WHEN 0 THEN '1'        --'Approval Not Required'
          WHEN 1 THEN '2'        --'Needs Approval'
          WHEN 2 THEN '3'        --'Approval Pending'
          WHEN 3 THEN '4'        --'Approved'
          WHEN 4 THEN '5'        --'Rejected'
       END AS job_approval_status_id,
       CASE j.internal_approval_state
          WHEN 0 THEN 'Approval Not Required'
          WHEN 1 THEN 'Needs Approval'
          WHEN 2 THEN 'Approval Pending'
          WHEN 3 THEN 'Approved'
          WHEN 4 THEN 'Rejected'
       END AS job_approval_status,
       jl.value          AS jl_value,
       jl.type           AS jl_type,
       jl.description    AS job_level_desc,
       CASE WHEN jcet.has_contr_empl_interest = 1 THEN 'Contract'
            WHEN jchet.has_contr_hire_empl_interest = 1 THEN 'Contract-to-Hire'
            WHEN jpet.has_perm_empl_interest = 1 THEN 'Direct-Hire'
       END                          AS job_type,
       j.description                AS job_description,
       jtemp.description            AS job_template_description,
       pw.requisition_type          AS job_requisition_type,
       j.job_priority_fk            AS job_priority_id,
       CASE j.job_priority_fk
          WHEN 0 THEN 'Normal'
          WHEN 1 THEN 'Critical'
          ELSE NULL
       END                          AS job_priority,
       j.phase_type_id
  FROM job_employment_terms@db_link_name AS OF SCN source_db_SCN      jet,
       job_contr_empl_terms@db_link_name AS OF SCN source_db_SCN      jcet,
       job_contr_hire_empl_terms@db_link_name AS OF SCN source_db_SCN jchet,
       job_perm_empl_terms@db_link_name AS OF SCN source_db_SCN       jpet,
       procurement_wkfl_edition@db_link_name AS OF SCN source_db_SCN  pw,
       job_level@db_link_name AS OF SCN source_db_SCN        jl,
       firm_role@db_link_name AS OF SCN source_db_SCN        bfr,
       job_category@db_link_name AS OF SCN source_db_SCN     jc,       
       job@db_link_name AS OF SCN source_db_SCN              j,
       job@db_link_name AS OF SCN source_db_SCN              jtemp,
       firm_worker@db_link_name AS OF SCN source_db_SCN      hfw,
       firm_worker@db_link_name AS OF SCN source_db_SCN      ofw,
       firm_worker@db_link_name AS OF SCN source_db_SCN      cfw,
       duration_units@db_link_name AS OF SCN source_db_SCN   du,
       proposed_approvable_jobaspects@db_link_name AS OF SCN source_db_SCN  paj,
       (SELECT apa.approvable_id AS job_id, apa.completed_date AS approved_date
          FROM approval_process@db_link_name AS OF SCN source_db_SCN  apa
         WHERE apa.active_process     = 1
           AND apa.approvable_type_fk = 3
           AND apa.state_code         = 3) aprv_dt      
 WHERE j.job_category_fk                = jc.value(+)
   AND NVL(j.archived_date,SYSDATE)    >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   AND j.job_level_fk                   = jl.value(+)
   AND j.procurement_wkfl_edition_fk    = pw.procurement_wkfl_edition_id(+)
   AND j.hiring_mgr_firm_woker_fk       = hfw.firm_worker_id(+)
   AND j.owner_firm_worker_fk           = ofw.firm_worker_id(+)
   AND j.creator_id                     = cfw.firm_worker_id(+)
   AND j.job_employment_terms_fk        = jet.job_employment_terms_id
   AND jet.job_employment_terms_id      = jcet.job_employment_terms_fk
   AND jet.job_employment_terms_id      = jchet.job_employment_terms_fk
   AND jet.job_employment_terms_id      = jpet.job_employment_terms_fk
   AND j.buyer_firm_fk                  = bfr.firm_id
   AND jcet.duration_units_fk           = du.value(+)
   AND j.proposed_approvable_aspects_fk = paj.identifier(+)
   AND j.source_template_id             = jtemp.job_id(+)
   AND j.job_id                         = aprv_dt.job_id(+)}';

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

