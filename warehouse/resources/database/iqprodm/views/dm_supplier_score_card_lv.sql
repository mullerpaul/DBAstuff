CREATE OR REPLACE FORCE VIEW DM_SUPPLIER_SCORE_CARD_LV
(
   STD_SUPPLIERORG_NAME,
   JOB_CATEGORY_DESC,
   CANDIDATES_SUBMITTED,
   AVG_SUBMIT_DAYS,
   AVG_SUBMIT_BUS_DAYS,
   CANDIDATES_FORWARDED_2HM,
   AVG_FWD_2HM_DAYS,
   AVG_FWD_2HM_BUS_DAYS,
   AVG_FWD_2HM_DAYS_4FILLED,
   AVG_FWD_2HM_BUS_DAYS_4FILLED,
   CANDIDATES_INTERVIEWED,
   AVG_TIME_TO_FILL_DAYS,
   CANDIDATES_WITHDRAWN,
   CANDIDATES_OFFERED,
   CANDIDATES_DECLINED,
   CANDIDATES_ACCEPTED,
   CANDIDATES_STARTED,
   EA_CANDIDATES_STARTED,
   RATE_COMPLIANCE_COUNT,
   CANDIDATES_ENDED,
   NEGATIVE_EVALUATIONS_COUNT,
   POSITIVE_EVALUATIONS_COUNT,
   TARGETED_JOBS_COUNT,
   ADVERSE_EVENT_COUNT,
   SUBMITTED_CANDIDATES_RATIO,
   QUALIFIED_CANDIDATES_RATIO,
   INTERVIEWED_CANDIDATES_RATIO,
   FILL_RATIO,
   SUPPLIER_SCORE,
   SUPPLIER_RANK,
   SPEND_AMT,
   DATA_SOURCE_CODE,
   PERIOD_NUMBER,
   BUYERORG_ID,
   SUPPLIERORG_ID,
   JOB_CATEGORY_ID,
   OPPORTUNITIES_RECEIVED
)
AS
   SELECT   NULL AS std_supplierorg_name,
            s.job_category_desc,
            s.candidates_submitted,
            s.avg_submit_days,
            s.avg_submit_bus_days,
            s.candidates_forwarded_2hm,
            s.avg_fwd_2hm_days,
            s.avg_fwd_2hm_bus_days,
            s.avg_fwd_2hm_days_4filled,
            s.avg_fwd_2hm_bus_days_4filled,
            s.candidates_interviewed,
            s.avg_time_to_fill_days,
            s.candidates_withdrawn,
            s.candidates_offered,
            s.candidates_declined,
            s.candidates_accepted,
            s.candidates_started,
            s.ea_candidates_started,
            s.rate_compliance_count,
            s.candidates_ended,
            s.negative_evaluations_count,
            s.positive_evaluations_count,
            s.targeted_jobs_count,
            s.adverse_event_count,
            s.submitted_candidates_ratio,
            s.qualified_candidates_ratio,
            s.interviewed_candidates_ratio,
            s.fill_ratio,
            s.supplier_score,
            s.supplier_rank,
            s.spend_amt,
            s.data_source_code,
            s.period_number,
            s.buyerorg_id,
            s.supplierorg_id,
            s.job_category_id,
            s.opportunities_received
     FROM   dm_supplier_summary s
/

DECLARE 
  lv_status VARCHAR2(30);
BEGIN
  SELECT status 
    INTO lv_status
    FROM user_objects 
   WHERE object_name = 'DM_SUPPLIER_SCORE_CARD_LV';
  
  IF lv_status = 'VALID' THEN
    EXECUTE IMMEDIATE 'GRANT SELECT ON DM_SUPPLIER_SCORE_CARD_LV TO PUBLIC';
  END IF;
END;
/ 
