--supplier scorecard candidate quality metrics view

CREATE OR REPLACE VIEW supplier_candidate_quality AS 
SELECT  buyer_org_guid, 
		supplier_guid,
		sr.supplier_name,
		TRUNC(ss.release_date, 'Q') AS qtr_start,
		COUNT(ss.candidates_declined) AS candidates_declined,
		AVG(ss.interview_rating) AS avg_interview_rating,
		COUNT (ss.assignment_unfavorably_terminated) AS unfavorable_terminations,
		COUNT (ss.assignment_id) AS placement_count,
		COUNT (ss.offer_accepted_date) / COUNT (ss.submission_date) AS submit_hire_ratio,
		COUNT (DISTINCT sr.requisition_guid) AS requests_received,
		COUNT (DISTINCT ss.requisition_guid) / COUNT (sr.requisition_guid) AS supplier_response_ratio,
		COUNT (ss.submission_guid) / COUNT (DISTINCT sr.release_id) AS candidates_per_opportunity
		COUNT (ss.interview_scheduled) / COUNT (ss.release_id) AS interview_hire_ratio,
		COUNT (ss.offer_accepted_date) / COUNT (ss.submission_date) AS acceptance_rate
FROM supplier_submission ss, supplier_release sr
WHERE ss.release_id = sr.release_id (+)
GROUP BY sr.buyer_org_guid, sr.supplier_guid, TRUNC(sr.opportunity_date, 'Q')
/
