/*******************************************************************************
SCRIPT NAME         lego_evaluation_views.sql 
 
LEGO OBJECT NAME    LEGO_EVALUATION
 
CREATED             1/30/2013
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

04/17/2014 - J.Pullifrone - IQN-15420 - added localization of overall_evaluation - Release 12.1
   
*******************************************************************************/ 
CREATE OR REPLACE FORCE VIEW lego_evaluation_vw AS
  SELECT buyer_org_id,
         supplier_org_id,
         assignment_continuity_id,
         project_agreement_id,
         evaluator_person_id,
         evaluation_type,
         evaluation_date,
         evaluation_start_date,
         evaluation_due_date,
         evaluation_answer_date,
         evaluation_question,
         evaluation_answer,
         evaluation_template_name,
         NVL(overall_eval.constant_description, overall_eval_jcl_en_us) AS overall_evaluation
    FROM lego_evaluation,
         (SELECT constant_value, constant_description
            FROM lego_java_constant_lookup
           WHERE constant_type    = 'OVERALL_EVAL'
             AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) overall_eval
    WHERE overall_rating          = overall_eval.constant_value(+)     
/    
    
    
COMMENT ON COLUMN lego_evaluation_vw.buyer_org_id               IS 'Buyer Organization FK'
/

COMMENT ON COLUMN lego_evaluation_vw.supplier_org_id            IS 'Supplier Organization FK'
/

COMMENT ON COLUMN lego_evaluation_vw.assignment_continuity_id   IS 'Assignment FK'
/

COMMENT ON COLUMN lego_evaluation_vw.project_agreement_id       IS 'Project Agreement FK - if it is an evaluation of a project'
/

COMMENT ON COLUMN lego_evaluation_vw.evaluator_person_id        IS 'Person ID of the evaluator'
/

COMMENT ON COLUMN lego_evaluation_vw.evaluation_type            IS 'Type of evaluation.  Defined by the Lego: Assignment or ProjectAgreement.'
/

COMMENT ON COLUMN lego_evaluation_vw.evaluation_date            IS 'Date the evaluation took place'
/

COMMENT ON COLUMN lego_evaluation_vw.evaluation_start_date      IS 'Evaluation period start date'
/

COMMENT ON COLUMN lego_evaluation_vw.evaluation_due_date        IS 'Date evaluation is due'
/

COMMENT ON COLUMN lego_evaluation_vw.evaluation_answer_date     IS 'Data evaluation is answered'
/

COMMENT ON COLUMN lego_evaluation_vw.evaluation_question        IS 'Evaluation question'
/

COMMENT ON COLUMN lego_evaluation_vw.evaluation_answer          IS 'Evaluation answer'
/

COMMENT ON COLUMN lego_evaluation_vw.evaluation_template_name   IS 'Evaulation template name'
/

COMMENT ON COLUMN lego_evaluation_vw.overall_evaluation         IS 'Overall evaluation: Positive or Negative (in whatever language)'
/
    