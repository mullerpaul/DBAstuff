/*******************************************************************************
SCRIPT NAME         lego_evaluation.sql 
 
LEGO OBJECT NAME    LEGO_EVALUATION
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark      - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2 
04/17/2014 - J.Pullifrone - IQN-15420 - Changed overall_evaluation to overall_rating so it can be translated by JCL. 
                                        Also added default english value in case localization is NULL - Release 12.1                                 
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_evaluation.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_EVALUATION'; 

  v_clob CLOB :=            
q'{SELECT fr.business_org_fk                                      AS buyer_org_id,
       frs.business_org_fk                                        AS supplier_org_id,
       ac.assignment_continuity_id                                AS assignment_continuity_id,
       ae.project_agmt_fk                                         AS project_agreement_id,
       evalu.evaluation_id                                        AS evaluation_id,
       eq.question_id                                             AS question_id,
       fweval.never_null_person_fk                                AS evaluator_person_id,
       'Assignment'                                               AS evaluation_type,
       ep.create_date                                             AS evaluation_date,
       ep.evaluation_start_date                                   AS evaluation_start_date,
       ep.evaluation_due_date                                     AS evaluation_due_date,
       CASE
             WHEN eqt.value = 3
             THEN
                answer.date_answer
             ELSE
                NULL
       END                                                        AS evaluation_answer_date,       
       eq.description                                             AS evaluation_question,
       CASE
         WHEN eqt.value IN (0, 4)   THEN  choice.answer_choice_description
         WHEN eqt.value = 1         THEN  answer.free_form_answer
         WHEN eqt.value = 2         THEN  DECODE (answer.is_yes_answer,  0, 'No',  1, 'Yes')       
         WHEN eqt.value = 5         THEN  (SELECT LISTAGG(eac.answer_choice_description,'; ') WITHIN GROUP (ORDER BY answer_choice_description) 
                                             FROM evaluation_answer AS OF SCN lego_refresh_mgr_pkg.get_scn ea,
                                                  eval_answr_eval_answr_choice_x AS OF SCN lego_refresh_mgr_pkg.get_scn eae,
                                                  evaluation_answer_choice AS OF SCN lego_refresh_mgr_pkg.get_scn eac
                                            WHERE ea.evaluation_question_fk       = answer.evaluation_question_fk
                                              AND ea.evaluation_fk                = answer.evaluation_fk
                                              AND ea.evaluation_answer_id         = eae.evaluation_answer_fk
                                              AND eae.evaluation_answer_choice_fk = eac.answer_choice_id
                                            GROUP BY eac.answers_collection_fk)         
       END                                                        AS evaluation_answer,
       ete.evaluation_template_name                               AS evaluation_template_name,       
       evalu.overall_rating                                       AS overall_rating,
       overall_eval_jcl_en_us.constant_description                AS overall_eval_jcl_en_us               
  FROM evaluation_process AS OF SCN lego_refresh_mgr_pkg.get_scn ep,
       evaluation_template_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn etc,
       evaluation_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ete,
       evaluation AS OF SCN lego_refresh_mgr_pkg.get_scn evalu,
       evaluation_question AS OF SCN lego_refresh_mgr_pkg.get_scn eq,
       evaluation_question_type AS OF SCN lego_refresh_mgr_pkg.get_scn eqt,
       evaluation_answer AS OF SCN lego_refresh_mgr_pkg.get_scn answer,
       evaluation_answer_choice AS OF SCN lego_refresh_mgr_pkg.get_scn choice,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn fr,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn frs,
       firm_worker AS OF SCN lego_refresh_mgr_pkg.get_scn fweval,
       assignment_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn ac,
       assignment_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ae,    
       work_order AS OF SCN lego_refresh_mgr_pkg.get_scn wo, 
       contract AS OF SCN lego_refresh_mgr_pkg.get_scn c,
       contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn cv,  
       work_order_version AS OF SCN lego_refresh_mgr_pkg.get_scn wov,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'OVERALL_EVAL'
           AND locale_fk = 'EN_US') overall_eval_jcl_en_us      
 WHERE ac.work_order_fk IS NOT NULL
   AND ac.assignment_continuity_id        = ep.evaluatable_fk
   AND ep.evaluation_process_id           = evalu.evaluation_process_fk
   AND ep.evaluatable_type                = 'AssignmentContinuity'
   AND answer.evaluation_fk               = evalu.evaluation_id
   AND NVL(evalu.submitted_by_firm_worker_fk, evalu.evaluator_firm_worker_fk) = fweval.firm_worker_id
   AND eq.question_id                     = answer.evaluation_question_fk
   AND answer.evaluation_answer_choice_fk = choice.answer_choice_id(+)
   AND eq.question_type_fk                = eqt.value
   AND ep.evaluation_tmplt_continuity_fk  = etc.continuity_id
   AND etc.continuity_id                  = ete.continuity_fk  
   AND ete.edition_id = (SELECT ete1.edition_id
                           FROM evaluation_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ete1
                          WHERE ete1.continuity_fk = ete.continuity_fk
                            AND ete1.create_date = (SELECT MAX (ete2.create_date)
                                                      FROM evaluation_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ete2
                                                     WHERE ete2.continuity_fk = ete1.continuity_fk
                                                       AND ete2.create_date < ep.evaluation_start_date)) 
   AND ac.work_order_fk            IS NOT NULL
   AND ac.current_edition_fk       = ae.assignment_edition_id
   AND ac.assignment_continuity_id = ae.assignment_continuity_fk
   AND NVL(ae.actual_end_date, SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   AND ac.work_order_fk            = wo.contract_id
   AND wo.contract_id              = c.contract_id
   AND ac.owning_supply_firm_fk    = frs.firm_id
   AND ac.owning_buyer_firm_fk     = fr.firm_id
   AND c.contract_id               = cv.contract_fk
   AND cv.contract_version_id      = wov.contract_version_id
   AND cv.contract_version_number  = (SELECT MAX (cv1.contract_version_number)
                                        FROM contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn cv1, work_order_version AS OF SCN lego_refresh_mgr_pkg.get_scn wov1
                                       WHERE cv1.contract_fk         = cv.contract_fk
                                         AND cv1.contract_version_id = wov1.contract_version_id) 
   AND evalu.overall_rating        = overall_eval_jcl_en_us.constant_value(+)                                          
UNION ALL
SELECT fr.business_org_fk                                         AS buyer_org_id,
       frs.business_org_fk                                        AS supplier_org_id,
       ac.assignment_continuity_id                                AS assignment_continuity_id,
       ae.project_agmt_fk                                         AS project_agreement_id,
       evalu.evaluation_id                                        AS evaluation_id,
       eq.question_id                                             AS question_id,
              fweval.never_null_person_fk                         AS evaluator_person_id, 
       'Assignment'                                               AS evaluation_type,
       ep.create_date                                             AS evaluation_date,
       ep.evaluation_start_date                                   AS evaluation_start_date,
       ep.evaluation_due_date                                     AS evaluation_due_date,
       CASE
             WHEN eqt.VALUE = 3
             THEN
                answer.date_answer
             ELSE
                NULL
       END                                                        AS evaluation_answer_date,
       
       eq.description                                             AS evaluation_question,
       CASE
         WHEN eqt.value IN (0, 4)   THEN  choice.answer_choice_description
         WHEN eqt.value = 1         THEN  answer.free_form_answer
         WHEN eqt.value = 2         THEN  DECODE (answer.is_yes_answer,  0, 'No',  1, 'Yes')       
         WHEN eqt.value = 5         THEN  (SELECT LISTAGG(eac.answer_choice_description,'; ') WITHIN GROUP (ORDER BY answer_choice_description) 
                                             FROM evaluation_answer AS OF SCN lego_refresh_mgr_pkg.get_scn ea,
                                                  eval_answr_eval_answr_choice_x AS OF SCN lego_refresh_mgr_pkg.get_scn eae,
                                                  evaluation_answer_choice AS OF SCN lego_refresh_mgr_pkg.get_scn eac
                                            WHERE ea.evaluation_question_fk       = answer.evaluation_question_fk
                                              AND ea.evaluation_fk                = answer.evaluation_fk
                                              AND ea.evaluation_answer_id         = eae.evaluation_answer_fk
                                              AND eae.evaluation_answer_choice_fk = eac.answer_choice_id
                                            GROUP BY eac.answers_collection_fk)         
       END                                                        AS evaluation_answer,
       ete.evaluation_template_name                               AS evaluation_template_name,
       evalu.overall_rating                                       AS overall_rating,
       overall_eval_jcl_en_us.constant_description                AS overall_eval_jcl_en_us
  FROM evaluation_process AS OF SCN lego_refresh_mgr_pkg.get_scn ep,
       evaluation_template_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn etc,
       evaluation_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ete,
       evaluation AS OF SCN lego_refresh_mgr_pkg.get_scn evalu,
       evaluation_question AS OF SCN lego_refresh_mgr_pkg.get_scn eq,
       evaluation_question_type AS OF SCN lego_refresh_mgr_pkg.get_scn eqt,
       evaluation_answer AS OF SCN lego_refresh_mgr_pkg.get_scn answer,
       evaluation_answer_choice AS OF SCN lego_refresh_mgr_pkg.get_scn choice,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn fr,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn frs,
       firm_worker AS OF SCN lego_refresh_mgr_pkg.get_scn fweval,
       assignment_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn ac,
       assignment_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ae, 
       asgmt_edition_position_asgmt_x AS OF SCN lego_refresh_mgr_pkg.get_scn aepa,
       position_assignment AS OF SCN lego_refresh_mgr_pkg.get_scn pa,
       project_agreement AS OF SCN lego_refresh_mgr_pkg.get_scn proj,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'OVERALL_EVAL'
           AND locale_fk = 'EN_US') overall_eval_jcl_en_us       
 WHERE ac.work_order_fk IS NULL
   AND ac.assignment_continuity_id        = ep.evaluatable_fk
   AND ep.evaluation_process_id           = evalu.evaluation_process_fk
   AND ep.evaluatable_type                = 'AssignmentContinuity'
   AND answer.evaluation_fk               = evalu.evaluation_id
   AND NVL(evalu.submitted_by_firm_worker_fk, evalu.evaluator_firm_worker_fk) = fweval.firm_worker_id
   AND eq.question_id                     = answer.evaluation_question_fk
   AND answer.evaluation_answer_choice_fk = choice.answer_choice_id(+)
   AND eq.question_type_fk                = eqt.value
   AND ep.evaluation_tmplt_continuity_fk  = etc.continuity_id
   AND etc.continuity_id                  = ete.continuity_fk  
   AND ete.edition_id = (SELECT ete1.edition_id
                           FROM evaluation_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ete1
                          WHERE ete1.continuity_fk = ete.continuity_fk
                            AND ete1.create_date = (SELECT MAX (ete2.create_date)
                                                      FROM evaluation_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ete2
                                                     WHERE ete2.continuity_fk = ete1.continuity_fk
                                                       AND ete2.create_date < ep.evaluation_start_date)) 
   AND ac.current_edition_fk       = ae.assignment_edition_id
   AND ac.assignment_continuity_id = ae.assignment_continuity_fk
   AND NVL(ae.actual_end_date, SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   AND ae.assignment_edition_id    = aepa.assignment_edition_fk(+)
   AND aepa.position_assignment_fk = (SELECT MAX (aepa1.position_assignment_fk)
                                       FROM asgmt_edition_position_asgmt_x AS OF SCN lego_refresh_mgr_pkg.get_scn aepa1
                                       WHERE aepa1.assignment_edition_fk = ae.assignment_edition_id)
   AND aepa.position_assignment_fk = pa.position_assignment_id
   AND ae.project_agmt_fk          = proj.contract_id(+)
   AND ac.owning_supply_firm_fk    = frs.firm_id
   AND ac.owning_buyer_firm_fk     = fr.firm_id
   AND evalu.overall_rating        = overall_eval_jcl_en_us.constant_value(+)
UNION ALL
SELECT p.buyer_firm_fk                                            AS buyer_org_id,
       frs.business_org_fk                                        AS supplier_org_id,
       NULL                                                       AS assignment_continuity_id,
       proj.contract_id                                           AS project_agreement_id,
       evalu.evaluation_id                                        AS evaluation_id,
       eq.question_id                                             AS question_id,  
       fweval.never_null_person_fk                                AS evaluator_person_id,               
       'ProjectAgreement'                                         AS evaluation_type,
       ep.create_date                                             AS evaluation_date,
       ep.evaluation_start_date                                   AS evaluation_start_date,
       ep.evaluation_due_date                                     AS evaluation_due_date,
       CASE
             WHEN eqt.value = 3
             THEN
                answer.date_answer
             ELSE
                NULL
       END                                                        AS evaluation_answer_date,
       eq.description                                             AS evaluation_question,
       CASE
         WHEN eqt.VALUE IN (0, 4)   THEN  choice.answer_choice_description
         WHEN eqt.VALUE = 1         THEN  answer.free_form_answer
         WHEN eqt.VALUE = 2         THEN  DECODE (answer.is_yes_answer,  0, 'No',  1, 'Yes')       
         WHEN eqt.VALUE = 5         THEN  (SELECT LISTAGG(eac.answer_choice_description,'; ') WITHIN GROUP (ORDER BY answer_choice_description) 
                                             FROM evaluation_answer AS OF SCN lego_refresh_mgr_pkg.get_scn ea,
                                                  eval_answr_eval_answr_choice_x AS OF SCN lego_refresh_mgr_pkg.get_scn eae,
                                                  evaluation_answer_choice AS OF SCN lego_refresh_mgr_pkg.get_scn eac
                                            WHERE ea.evaluation_question_fk       = answer.evaluation_question_fk
                                              AND ea.evaluation_fk                = answer.evaluation_fk
                                              AND ea.evaluation_answer_id         = eae.evaluation_answer_fk
                                              AND eae.evaluation_answer_choice_fk = eac.answer_choice_id
                                            GROUP BY eac.answers_collection_fk)         
       END                                                        AS evaluation_answer,
       ete.evaluation_template_name                               AS evaluation_template_name,
       evalu.overall_rating                                       AS overall_rating, 
       overall_eval_jcl_en_us.constant_description                AS overall_eval_jcl_en_us    
  FROM evaluation_process AS OF SCN lego_refresh_mgr_pkg.get_scn ep,
       evaluation_template_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn etc,
       evaluation_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ete,
       evaluation AS OF SCN lego_refresh_mgr_pkg.get_scn evalu,
       evaluation_question AS OF SCN lego_refresh_mgr_pkg.get_scn eq,
       evaluation_question_type AS OF SCN lego_refresh_mgr_pkg.get_scn eqt,
       evaluation_answer AS OF SCN lego_refresh_mgr_pkg.get_scn answer,
       evaluation_answer_choice AS OF SCN lego_refresh_mgr_pkg.get_scn choice,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn frs,
       firm_worker AS OF SCN lego_refresh_mgr_pkg.get_scn fweval,
       project AS OF SCN lego_refresh_mgr_pkg.get_scn p,
       contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn cv3, 
       project_agreement AS OF SCN lego_refresh_mgr_pkg.get_scn proj,
       project_agreement_version AS OF SCN lego_refresh_mgr_pkg.get_scn pav,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'OVERALL_EVAL'
           AND locale_fk = 'EN_US') overall_eval_jcl_en_us        
 WHERE p.project_id                         = proj.project_fk
   AND proj.contract_id                     = ep.evaluatable_fk
   AND proj.supply_firm_fk                  = frs.firm_id(+)
   AND proj.contract_id                     = cv3.contract_fk(+)
   AND cv3.contract_version_id              = pav.contract_version_id(+)
   AND NVL(pav.end_date,SYSDATE)           >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   AND cv3.contract_version_number = (SELECT MAX (cvi3.contract_version_number)
                                        FROM contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn cvi3
                                       WHERE cvi3.contract_fk = cv3.contract_fk)
   AND ep.evaluation_process_id           = evalu.evaluation_process_fk
   AND ep.evaluatable_type                = 'ProjectAgreement'
   AND answer.evaluation_fk               = evalu.evaluation_id
   AND NVL(evalu.submitted_by_firm_worker_fk, evalu.evaluator_firm_worker_fk) = fweval.firm_worker_id
   AND eq.question_id                     = answer.evaluation_question_fk
   AND answer.evaluation_answer_choice_fk = choice.answer_choice_id(+)
   AND eq.question_type_fk                = eqt.value
   AND ep.evaluation_tmplt_continuity_fk  = etc.continuity_id
   AND etc.continuity_id                  = ete.continuity_fk  
   AND ete.edition_id = (SELECT ete1.edition_id
                           FROM evaluation_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ete1
                          WHERE ete1.continuity_fk = ete.continuity_fk
                            AND ete1.create_date = (SELECT MAX (ete2.create_date)
                                                      FROM evaluation_template_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ete2
                                                     WHERE ete2.continuity_fk = ete1.continuity_fk
                                                       AND ete2.create_date < ep.evaluation_start_date)) 
   AND evalu.overall_rating        = overall_eval_jcl_en_us.constant_value(+)                                                                               
UNION ALL  --Standard Express Assignment
SELECT fr.business_org_fk                                         AS buyer_org_id,
       frs.business_org_fk                                        AS supplier_org_id,
       ac.assignment_continuity_id                                AS assignment_continuity_id,
       ae.project_agmt_fk                                         AS project_agreement_id,
       aeval.assignment_evaluation_id                             AS evaluation_id,
       NULL                                                       AS question_id, 
       fweval.never_null_person_fk                                AS evaluator_person_id,               
       'Assignment'                                               AS evaluation_type,
       NULL                                                       AS evaluation_date,
       NULL                                                       AS evaluation_start_date,
       NULL                                                       AS evaluation_due_date,
       NULL                                                       AS evaluation_answer_date,

       CASE
             WHEN aeq.value= 1
             THEN
                'Did the resource perform the duties as outlined in the work assignment?'
             WHEN aeq.value = 2
             THEN
                'Would you use the resource again?'
             WHEN aeq.value = 3
             THEN
                'Would you recommend the resource for another position?'
             ELSE
                NULL
          END                                                         AS evaluation_question,
       DECODE(aea.assign_eval_answer,'true','Yes','false','No',NULL)  AS evaluation_answer,
       NULL                                                           AS evaluation_template_name,
       CASE
         WHEN aea.assign_eval_answer = 'true' THEN 1
         ELSE 0
       END                                                            AS overall_rating,
       CASE
         WHEN aea.assign_eval_answer = 'true' THEN 'Positive'
         ELSE 'Negative'
       END                                                            AS overall_eval_jcl_en_us       
  FROM assignment_evaluation AS OF SCN lego_refresh_mgr_pkg.get_scn aeval,
       assignment_evaluation_answer AS OF SCN lego_refresh_mgr_pkg.get_scn aea,
       assignment_evaluation_question AS OF SCN lego_refresh_mgr_pkg.get_scn aeq,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn fr,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn frs,
       firm_worker AS OF SCN lego_refresh_mgr_pkg.get_scn fweval,
       assignment_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn ac,
       assignment_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ae, 
       asgmt_edition_position_asgmt_x AS OF SCN lego_refresh_mgr_pkg.get_scn aepa,
       position_assignment AS OF SCN lego_refresh_mgr_pkg.get_scn pa,
       project_agreement AS OF SCN lego_refresh_mgr_pkg.get_scn proj
 WHERE ac.work_order_fk IS NULL
   AND ac.assignment_continuity_id        = aeval.assignment_evaluation_id
   AND aea.assignment_eval_fk             = aeval.assignment_evaluation_id
   AND aea.assign_eval_question_fk        = aeq.value
   AND aeval.evaluation_by_fk             = fweval.firm_worker_id
  
   AND ac.current_edition_fk       = ae.assignment_edition_id
   AND ac.assignment_continuity_id = ae.assignment_continuity_fk
   AND ae.assignment_edition_id    = aepa.assignment_edition_fk(+)
   AND NVL(ae.actual_end_date, SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   AND aepa.position_assignment_fk = (SELECT MAX (aepa1.position_assignment_fk)
                                       FROM asgmt_edition_position_asgmt_x AS OF SCN lego_refresh_mgr_pkg.get_scn aepa1
                                       WHERE aepa1.assignment_edition_fk = ae.assignment_edition_id)
   AND aepa.position_assignment_fk = pa.position_assignment_id
   AND ae.project_agmt_fk          = proj.contract_id(+)
   AND ac.owning_supply_firm_fk    = frs.firm_id
   AND ac.owning_buyer_firm_fk     = fr.firm_id    
UNION ALL
SELECT fr.business_org_fk                                         AS buyer_org_id,
       frs.business_org_fk                                        AS supplier_org_id,
       ac.assignment_continuity_id                                AS assignment_continuity_id,
       ae.project_agmt_fk                                         AS project_agreement_id,
       aeval.assignment_evaluation_id                             AS evaluation_id,
       NULL                                                       AS question_id,  
       fweval.never_null_person_fk                                AS evaluator_person_id,      
       'Assignment'                                               AS evaluation_type,
       NULL                                                       AS evaluation_date,
       NULL                                                       AS evaluation_start_date,
       NULL                                                       AS evaluation_due_date,
       NULL                                                       AS evaluation_answer_date,
       CASE
             WHEN aeq.value = 1
             THEN
                'Did the resource perform the duties as outlined in the work assignment?'
             WHEN aeq.value = 2
             THEN
                'Would you use the resource again?'
             WHEN aeq.value = 3
             THEN
                'Would you recommend the resource for another position?'
             ELSE
                NULL
          END                                                         AS evaluation_question,
       DECODE(aea.assign_eval_answer,'true','Yes','false','No',NULL)  AS evaluation_answer,
       NULL                                                           AS evaluation_template_name,
       CASE
         WHEN aea.assign_eval_answer = 'true' THEN 1
         ELSE 0
       END                                                            AS overall_rating,
       CASE
         WHEN aea.assign_eval_answer = 'true' THEN 'Positive'
         ELSE 'Negative'
       END                                                            AS overall_eval_jcl_en_us        
  FROM assignment_evaluation AS OF SCN lego_refresh_mgr_pkg.get_scn aeval,
       assignment_evaluation_answer AS OF SCN lego_refresh_mgr_pkg.get_scn aea,
       assignment_evaluation_question AS OF SCN lego_refresh_mgr_pkg.get_scn aeq,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn fr,
       firm_role AS OF SCN lego_refresh_mgr_pkg.get_scn frs,
       firm_worker AS OF SCN lego_refresh_mgr_pkg.get_scn fweval,
       contract AS OF SCN lego_refresh_mgr_pkg.get_scn c,
       contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn cv,
       work_order AS OF SCN lego_refresh_mgr_pkg.get_scn wo,
       work_order_version AS OF SCN lego_refresh_mgr_pkg.get_scn wov,
       assignment_continuity AS OF SCN lego_refresh_mgr_pkg.get_scn ac,
       assignment_edition AS OF SCN lego_refresh_mgr_pkg.get_scn ae, 
       project_agreement AS OF SCN lego_refresh_mgr_pkg.get_scn proj
 WHERE ac.work_order_fk IS NOT NULL
   AND ac.current_edition_fk              = ae.assignment_edition_id
   AND ac.assignment_continuity_id        = ae.assignment_continuity_fk 
   AND ac.work_order_fk                   = wo.contract_id
   AND wo.contract_id                     = c.contract_id  
   AND ac.owning_supply_firm_fk           = frs.firm_id
   AND ac.owning_buyer_firm_fk            = fr.firm_id
   AND c.contract_id                      = cv.contract_fk
   AND cv.contract_version_id             = wov.contract_version_id
   AND cv.contract_version_number = (SELECT MAX (cv1.contract_version_number)
                                       FROM contract_version AS OF SCN lego_refresh_mgr_pkg.get_scn cv1, work_order_version AS OF SCN lego_refresh_mgr_pkg.get_scn wov1
                                      WHERE cv1.contract_fk = cv.contract_fk
                                        AND cv1.contract_version_id = wov1.contract_version_id)
   AND ae.project_agmt_fk                 = proj.contract_id(+)
   AND NVL(ae.actual_end_date, SYSDATE)  >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   AND ae.evaluation_fk                   = aeval.assignment_evaluation_id
   AND aea.assignment_eval_fk             = aeval.assignment_evaluation_id
   AND aea.assign_eval_question_fk        = aeq.value
   AND aeval.evaluation_by_fk             = fweval.firm_worker_id
ORDER BY buyer_org_id, supplier_org_id}';               
         

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

