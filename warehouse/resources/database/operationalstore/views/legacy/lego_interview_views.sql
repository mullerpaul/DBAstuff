--J.Pullifrone
--IQN-7613
--Rel 11.4

CREATE OR REPLACE FORCE VIEW lego_interview_vw 
AS
  SELECT buyer_org_id,
         supplier_org_id,
         match_id,  
         job_id,       
         interview_type,
         interview_status,
         interview_time,
         interview_date,
         interview_note,
         interview_location
    FROM lego_interview
/

COMMENT ON COLUMN lego_interview_vw.buyer_org_id                IS 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/
COMMENT ON COLUMN lego_interview_vw.supplier_org_id             IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'
/
COMMENT ON COLUMN lego_interview_vw.match_id                    IS 'Match ID FK to LEGO_MATCH_VW'
/
COMMENT ON COLUMN lego_interview_vw.job_id                      IS 'Job ID FK to LEGO_JOB_VW'
/   
COMMENT ON COLUMN lego_interview_vw.interview_type              IS 'Interview Type'
/
COMMENT ON COLUMN lego_interview_vw.interview_status            IS 'Interview Status'
/
COMMENT ON COLUMN lego_interview_vw.interview_time              IS 'Interview Time'
/
COMMENT ON COLUMN lego_interview_vw.interview_date              IS 'Interview Date - multiple for each interview'
/
COMMENT ON COLUMN lego_interview_vw.interview_note              IS 'Interview Note - multiple for each interview'
/
COMMENT ON COLUMN lego_interview_vw.interview_location          IS 'Interview Type'
/


