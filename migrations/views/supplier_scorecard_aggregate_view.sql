CREATE OR REPLACE VIEW supplier_aggregate_metrics AS
SELECT sc.buyer_org_guid,
  sc.supplier_guid,
  scq.supplier_name,
  qtr_start,
  candidates_declined,
  avg_interview_rating,
  unfavorable_terminations,
  placement_count,
  submit_hire_ratio,
  requests_received,
  supplier_response_ratio,
  candidates_per_opportunity,
  interview_hire_ratio,
  acceptance_rate,
  placements_over_req_rate,
  rate_competitiveness,
  avg_interview_response_time,
  avg_offer_response_time,
  min_time_to_submit
FROM supplier_cost sc, supplier_candidate_quality scq, supplier_efficiency se
WHERE   sc.buyer_org_guid = scq.buyer_org_guid
    AND sc.qtr_start = scq.qtr_start
    AND sc.supplier_guid = scq.supplier_guid
    AND scq.buyer_org_guid = se.buyer_org_guid
    AND scq.qtr_start = se.qtr_start
    AND scq.supplier_guid = se.supplier_guid
GROUP BY scq.buyer_org_guid, scq.supplier_org, scq.qtr_start
/