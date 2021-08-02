CREATE OR REPLACE FORCE VIEW dm_supplier_std_score_card_lv
AS
SELECT   ds.std_supplierorg_name
       , db.std_buyerorg_name
       , s.std_job_category_desc
       , s.candidates_submitted
       , s.avg_submit_days
       , s.avg_submit_bus_days
       , s.candidates_forwarded_2hm
       , s.avg_fwd_2hm_days
       , s.avg_fwd_2hm_bus_days
       , s.avg_fwd_2hm_days_4filled
       , s.avg_fwd_2hm_bus_days_4filled
       , s.candidates_interviewed
       , s.avg_time_to_fill_days
       , s.candidates_withdrawn
       , s.candidates_offered
       , s.candidates_declined
       , s.candidates_accepted
       , s.candidates_started
       , s.ea_candidates_started
       , s.rate_compliance_count
       , s.candidates_ended
       , null candidates_ended_negative
       , s.negative_evaluations_count
       , s.positive_evaluations_count
       , null null_evaluations_count
       , s.targeted_jobs_count
       ,null new_opportunity_count
       , null available_positions
       , s.adverse_event_count
       , s.submitted_candidates_ratio
       , s.qualified_candidates_ratio
       , s.interviewed_candidates_ratio
       , s.fill_ratio
       , s.supplier_score
       , s.supplier_rank
       , s.spend_amt
       , s.data_source_code
       , s.period_number
       , s.std_buyerorg_id
       , s.std_supplierorg_id
       , s.std_job_category_id
  FROM dm_supplier_std_summary s, dm_suppliers ds, dm_buyers db
 WHERE ds.std_supplierorg_id = s.std_supplierorg_id
   AND db.std_buyerorg_id = s.std_buyerorg_id
/

DECLARE 
  lv_status VARCHAR2(30);
BEGIN
  SELECT status 
    INTO lv_status
    FROM user_objects 
   WHERE object_name = 'DM_SUPPLIER_STD_SCORE_CARD_LV';
  
  IF lv_status = 'VALID' THEN
    EXECUTE IMMEDIATE 'GRANT SELECT ON DM_SUPPLIER_STD_SCORE_CARD_LV TO PUBLIC';
  END IF;
END;
/ 