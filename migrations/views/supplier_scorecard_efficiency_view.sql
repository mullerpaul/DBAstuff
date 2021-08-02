--supplier scorecard efficiency metrics view

CREATE OR REPLACE VIEW supplier_efficiency AS
SELECT	buyer_org_guid,
		supplier_guid,
		sr.supplier_name,
		TRUNC(ss.release_date, 'Q') AS qtr_start,
		--TODO: AVG (MIN (ss.interview_scheduled - ss.release_create_date)) AS avg_interview_response_time,
		AVG(CASE 
				WHEN offer_accepted_date IS NOT NULL THEN offer_accepted_date
                WHEN offer_rejected_date IS NOT NULL THEN offer_rejected_date
				ELSE NULL 
				END) - ss.cand_offered_position) AS avg_offer_response_time,
		MIN(ss.submission_date - sr.release_date) AS min_time_to_submit
FROM supplier_submission ss, supplier_release sr 
WHERE ss.release_id = sr.release_id (+)
GROUP BY sr.buyer_org_guid, sr.supplier_guid, TRUNC(sr.release_date, 'Q')
/

--TODO: first cand response time? interview_scheduled?