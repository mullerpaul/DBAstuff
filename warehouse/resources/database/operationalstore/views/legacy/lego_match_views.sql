/*******************************************************************************
SCRIPT NAME         lego_match_views.sql 
 
LEGO OBJECT NAME    LEGO_MATCH
 
CREATED             7/11/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************
 
07/11/2014 - J.Pullifrone - IQN-18303 - added job_opportunity_id column - Release 12.1.2 
   
*******************************************************************************/  
CREATE OR REPLACE FORCE VIEW lego_match_vw 
AS
SELECT m.match_id, 
       m.job_id,
       m.job_opportunity_id,
       m.buyer_org_id,
       m.supplier_org_id,
       m.candidate_id,
       m.contractor_person_id,
       m.supplier_agent_person_id,
       m.supplier_acct_rep_person_id,
       m.assignment_continuity_id,
       m.create_date,
       m.match_start_date,
       m.match_end_date,
       m.job_sub_matching_date,
       m.supp_sub_for_match_date,
       m.supplier_submitted_date,
       m.candidate_approved_date,
       m.interested_in_candidate_date,
       m.interested_in_job_date,
       m.decline_candidate_date,
       m.fail_candidate_screening_date,
       m.match_pos_available_date,
       m.match_pos_filled_date,
       m.offer_position_date,
       m.pass_candidate_screening_date,
       m.interview_requested_date,  
       m.schedule_interview_date,
       m.match_status_id,       
       NVL(ms_jcl.constant_description, m.match_status) AS match_status
  FROM lego_match m,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'MATCH_STATE'
           AND locale_fk        = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) ms_jcl
 WHERE m.match_status_id = ms_jcl.constant_value(+)
/  
  
COMMENT ON COLUMN lego_match_vw.buyer_org_id                  IS 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/

COMMENT ON COLUMN lego_match_vw.supplier_org_id               IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'
/

COMMENT ON COLUMN lego_match_vw.match_id                      IS 'Match ID PK'
/

COMMENT ON COLUMN lego_match_vw.job_id                        IS 'Job ID - FK to LEGO_JOB_VW'
/

COMMENT ON COLUMN lego_match_vw.job_opportunity_id            IS 'Job Opportunity ID'
/

COMMENT ON COLUMN lego_match_vw.candidate_id                  IS 'Candidate ID'
/

COMMENT ON COLUMN lego_match_vw.contractor_person_id          IS 'Person ID for Contract - FK to LEGO_PERSON_VW'
/

COMMENT ON COLUMN lego_match_vw.supplier_agent_person_id      IS 'Person ID for Supplier Agent - FK to LEGO_PERSON_VW'
/

COMMENT ON COLUMN lego_match_vw.supplier_acct_rep_person_id   IS 'Person ID for Supplier Acct Rep - FK to LEGO_PERSON_VW'
/

COMMENT ON COLUMN lego_match_vw.assignment_continuity_id      IS 'Assignnment ID - FK to LEGO_ASSIGNMENT'
/

COMMENT ON COLUMN lego_match_vw.match_start_date              IS 'Match start date'
/

COMMENT ON COLUMN lego_match_vw.match_end_date                IS 'Match end date'
/

COMMENT ON COLUMN lego_match_vw.job_sub_matching_date         IS 'Date the job was submitted for a match'
/

COMMENT ON COLUMN lego_match_vw.supp_sub_for_match_date       IS 'Date the supplier submitted candidate for match'
/

COMMENT ON COLUMN lego_match_vw.supplier_submitted_date       IS 'Date the supplier was submitted for match'
/

COMMENT ON COLUMN lego_match_vw.interview_requested_date      IS 'Date the interview is requested'
/

COMMENT ON COLUMN lego_match_vw.schedule_interview_date       IS 'Date the interview is scheduled'
/                                         

COMMENT ON COLUMN lego_match_vw.pass_candidate_screening_date IS 'Date the candidate passes screening'
/

COMMENT ON COLUMN lego_match_vw.interested_in_candidate_date  IS 'Date it is indicated that there is interest in the candidate'
/

COMMENT ON COLUMN lego_match_vw.interested_in_job_date        IS 'Date candidate indicates interest in the job'
/

COMMENT ON COLUMN lego_match_vw.decline_candidate_date        IS 'Date candidate declines job'
/

COMMENT ON COLUMN lego_match_vw.fail_candidate_screening_date IS 'Date candidate fails screening'
/

COMMENT ON COLUMN lego_match_vw.match_pos_available_date      IS 'Date position becomes available'
/

COMMENT ON COLUMN lego_match_vw.match_pos_filled_date         IS 'Date position become filled'
/
       
COMMENT ON COLUMN lego_match_vw.offer_position_date           IS 'Date position is offered'
/       

COMMENT ON COLUMN lego_match_vw.match_status                  IS 'Match status from JAVA_CONSTANT_LOOKUP where constant_type = MATCH_STATE'
/
