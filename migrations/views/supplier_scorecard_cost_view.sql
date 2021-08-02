--supplier scorecard cost metrics view

CREATE OR REPLACE VIEW supplier_cost AS
SELECT 	buyer_org_guid,
		supplier_guid,
		TRUNC(release_date, 'Q') AS qtr_start,
		COUNT 	(CASE
					WHEN submitted_bill_rate > assignment_bill_rate
					THEN 1
				END) AS placements_over_req_rate,
		AVG (submitted_bill_rate / assignment_bill_rate) AS rate_competitiveness
FROM supplier_submission
GROUP BY buyer_org_guid, supplier_guid, TRUNC(release_date, 'Q')
/