
CREATE TABLE supplier_rollup (
  buyer_org_guid				RAW(16) NOT NULL,
	supplier_guid				RAW(16) NOT NULL,
	supplier_name				VARCHAR(30) NOT NULL,
	timeframe					VARCHAR(20) NOT NULL,
	job_category				VARCHAR(30) NOT NULL,
	location					VARCHAR(30) NOT NULL,
	grade						VARCHAR(2) NOT NULL,
	active_since				DATE DEFAULT SYSDATE NOT NULL,
	total_spend					NUMBER,
	candidates_submitted		NUMBER,
	candidates_placed			NUMBER,
	candidates_declined			NUMBER,
	candidates_per_opportunity	NUMBER,
	time_to_fill				NUMBER,
	acceptance_rate				NUMBER,
	submit_hire_ratio			NUMBER,
	unfavorable_terminations	NUMBER,
	interview_rating			NUMBER,
	interview_hire_ratio		NUMBER,
	first_cand_response_time	NUMBER,
	interview_response_time		NUMBER,
	offer_response_time			NUMBER,
	placements_over_req_rate	NUMBER,
	rate_competitiveness		NUMBER,
	markup_percentage			NUMBER
)
/

ALTER TABLE supplier_rollup ADD CONSTRAINT supplier_rollup_pk PRIMARY KEY (supplier_guid)
/
ALTER TABLE supplier_rollup ADD CONSTRAINT supplier_rollup_ui01 UNIQUE (supplier_guid, buyer_org_guid, timeframe)
/

COMMENT ON TABLE supplier_rollup IS 'Supplier quarterly metrics.'
/
COMMENT ON COLUMN supplier_rollup.buyer_org_guid IS 'Unique Identifier for a buyer org.'
/
COMMENT ON COLUMN supplier_rollup.supplier_guid IS 'Unique Identifier for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.supplier_name IS 'Name for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.timeframe IS 'Rollup timeframe (e.g. monthly, quarterly, etc).'
/
COMMENT ON COLUMN supplier_rollup.job_category IS 'Job category.'
/
COMMENT ON COLUMN supplier_rollup.location IS 'Location for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.grade IS 'An overall grade for the supplier.'
/
COMMENT ON COLUMN supplier_rollup.active_since IS 'Date of first hire through supplier.'
/
COMMENT ON COLUMN supplier_rollup.total_spend IS 'Total amount ($) spent with a supplier.'
/
COMMENT ON COLUMN supplier_rollup.candidates_submitted IS 'Number of candidates submitted through supplier.'
/
COMMENT ON COLUMN supplier_rollup.candidates_placed IS 'Number of candidates placed in a position through supplier.'
/
COMMENT ON COLUMN supplier_rollup.candidates_declined IS 'Number of candidates declined to a position for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.candidates_per_opportunity IS 'Average number of candidates submitted to a single position for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.time_to_fill IS 'Average time to fill a position for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.acceptance_rate IS 'Candidates accepted over candidates submitted for a supplier.' 
/
COMMENT ON COLUMN supplier_rollup.submit_hire_ratio IS 'Candidates hired over candidates submitted for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.unfav_terminations IS 'Number of positions unfavorably terminated for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.interview_rating IS 'Average interview rating for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.interview_hire_ratio IS 'Candidates hired over candidates interviewed for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.first_cand_response_time IS 'Average time before first response by a candidate for a req for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.interview_response_time IS 'Average time between an interview requested and scheduled for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.offer_response_time IS 'Average time between an offer made and accepted for a supplier.'
/
COMMENT ON COLUMN supplier_rollup.placements_over_req_rate IS 'Number of placements for a supplier where candidate pay is over the request rate.'
/
COMMENT ON COLUMN supplier_rollup.rate_competitiveness IS 'Average percent variation between offer accepted rate and requested rate for a supplier.'
/

GRANT SELECT ON supplier_rollup TO falcon_readonly
/
GRANT DELETE ON supplier_rollup TO schema_name
/
GRANT SELECT ON supplier_rollup TO schema_name
/
GRANT UPDATE ON supplier_rollup TO schema_name
/
GRANT INSERT ON supplier_rollup TO schema_name
/
