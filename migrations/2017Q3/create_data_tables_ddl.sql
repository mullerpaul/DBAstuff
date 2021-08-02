CREATE TABLE supplier_release (
  release_guid             RAW(16)            NOT NULL,
  client_guid              RAW(16)            NOT NULL,
  legacy_source_vms        VARCHAR2(7)        NOT NULL,
  last_modified_date       DATE               NOT NULL,
  client_name              VARCHAR2(128 CHAR) NOT NULL,
  supplier_guid            RAW(16)            NOT NULL,
  supplier_name            VARCHAR2(255 CHAR) NOT NULL,
  release_date             DATE               NOT NULL,
  release_tier             VARCHAR2(255 CHAR),
  requisition_guid         RAW(16)            NOT NULL,
  requisition_id           VARCHAR2(50)       NOT NULL,
  requisition_create_date  DATE               NOT NULL,
  requisition_currency     VARCHAR2(50 CHAR)  NOT NULL,
  requisition_positions    NUMBER,
  requisition_rate         NUMBER,
  requisition_title        VARCHAR2(255 CHAR),
  requisition_industry     VARCHAR2(255 CHAR),
  requisition_country      VARCHAR2(100 CHAR),
  requisition_state        VARCHAR2(100 CHAR),
  requisition_city         VARCHAR2(100 CHAR),
  CONSTRAINT supplier_release_pk PRIMARY KEY (release_guid)
)
PARTITION BY LIST (legacy_source_vms)
 (PARTITION p_iqn_vms     VALUES ('IQN'),
  PARTITION p_beeline_vms VALUES ('Beeline'))
/

-- This is unique if we do NOT do any normalization of IQN supplier data.
-- If we want to normalize the suppliers, we may have to get rid of this.  I tried normalization via top-level org and by DM_SUPPLIERS; 
-- but in both cases, this was no longer unique.  Perhaps there is a better way that I missed.
ALTER TABLE supplier_release ADD CONSTRAINT supplier_release_ui01 UNIQUE (client_guid, supplier_guid, requisition_guid)
/

COMMENT ON TABLE supplier_release IS 'This table is "per release" - one row for each supplier a requisition is released to.'
/
COMMENT ON COLUMN supplier_release.release_guid IS 'Unique identifier for the release.'
/
COMMENT ON COLUMN supplier_release.client_guid IS 'Unique Identifier for a client (buyer)'
/
COMMENT ON COLUMN supplier_release.client_name IS 'The name of the client'
/
COMMENT ON COLUMN supplier_release.supplier_guid IS 'Unique Identifier for a supplier.'
/
COMMENT ON COLUMN supplier_release.supplier_name IS 'The name of the supplier.'
/
COMMENT ON COLUMN supplier_release.release_date IS 'Date the release (opportunity) was made available to supplier.'
/
COMMENT ON COLUMN supplier_release.requisition_guid IS 'Unique guid for a requisition.'
/
COMMENT ON COLUMN supplier_release.requisition_id IS 'Identifier used to reference the req in the transactional system'
/
COMMENT ON COLUMN supplier_release.requisition_create_date IS 'Create date associated with the requisition.'
/
COMMENT ON COLUMN supplier_release.requisition_currency IS 'Currency in which the requisition will be billed.'
/
COMMENT ON COLUMN supplier_release.requisition_title IS 'Job title of requisition.'
/
COMMENT ON COLUMN supplier_release.requisition_industry IS 'Customer entered industry value (may be NULL for legacy IQN data)'
/
COMMENT ON COLUMN supplier_release.requisition_country IS 'Customer entered work country (may be NULL for legacy IQN data)'
/
COMMENT ON COLUMN supplier_release.requisition_state IS 'Customer entered work state (may be NULL for legacy IQN data)'
/
COMMENT ON COLUMN supplier_release.requisition_city IS 'Customer entered work city (may be NULL for legacy IQN data)'
/
COMMENT ON COLUMN supplier_release.requisition_positions IS 'Number of people the client hopes to hire with this req (may be NULL for legacy Beeline data)'
/
COMMENT ON COLUMN supplier_release.requisition_rate IS 'The proposed rate specified on the requisition'
/
COMMENT ON COLUMN supplier_release.last_modified_date IS 'When this row was loaded or last updated'
/


CREATE TABLE  supplier_submission (
  submission_guid             RAW(16)  NOT NULL,
  submission_date             DATE     NOT NULL,
  release_guid                RAW(16)  NOT NULL,
  last_modified_date          DATE     NOT NULL,
  candidate_name              VARCHAR2(350),
  submitted_bill_rate         NUMBER,
  offer_made_date             DATE,
  offer_accepted_date         DATE,
  offer_rejected_date         DATE,
  offer_accepted_rate         NUMBER,
  interview_requested_date    DATE,
  interview_scheduled_date    DATE,
  interview_date              DATE,
  avg_interview_rating        NUMBER,
  assignment_id               VARCHAR2(30),
  assignment_status_id        NUMBER,
  assignment_status           VARCHAR2(255),
  assignment_start_date       DATE,
  assignment_pay_rate         NUMBER,
  assignment_bill_rate        NUMBER,
  assignment_unfav_term_date  DATE,
  assignment_end_date         DATE,
  assignment_end_type         VARCHAR2(255),
  CONSTRAINT supplier_submission_pk PRIMARY KEY (submission_guid),
  CONSTRAINT supplier_submission_fk01 FOREIGN KEY (release_guid) REFERENCES supplier_release(release_guid)
)
PARTITION BY REFERENCE (supplier_submission_fk01)
/

COMMENT ON TABLE supplier_submission IS 'This table is "per submission" - one row for each candidate a supplier submitted for a requisition.'
/
COMMENT ON COLUMN supplier_submission.submission_guid IS 'Unique Identifier for a submission.'
/
COMMENT ON COLUMN supplier_submission.submission_date IS 'Date the submission (candidate) was given to client (buyer)'
/
COMMENT ON COLUMN supplier_submission.release_guid IS 'Unique Identifier for a release.'
/
COMMENT ON COLUMN supplier_submission.candidate_name IS 'The name of the submitted candidate.'
/
COMMENT ON COLUMN supplier_submission.submitted_bill_rate IS 'Rate submitted with the candidate.'
/
COMMENT ON COLUMN supplier_submission.offer_made_date IS 'Date an offer was made to the candidate.'
/
COMMENT ON COLUMN supplier_submission.offer_accepted_date IS 'Date the candidate accepted the position.'
/
COMMENT ON COLUMN supplier_submission.offer_rejected_date IS 'Date the candidate declined the position.'
/
COMMENT ON COLUMN supplier_submission.offer_accepted_rate IS 'Rate accepted by the candidate'
/
COMMENT ON COLUMN supplier_submission.interview_requested_date IS 'The date and time when a VMS user requested an interview of a specific candidate.'
/
COMMENT ON COLUMN supplier_submission.interview_scheduled_date IS 'The date and time when a supplier set a time for a candidate interview. (not the time of the interview itself)'
/
COMMENT ON COLUMN supplier_submission.interview_date IS 'The date and time when an interview is scheduled to or did occur.'
/
COMMENT ON COLUMN supplier_submission.avg_interview_rating IS 'Average of numeric quality ratings assigned after interviews.'
/
COMMENT ON COLUMN supplier_submission.assignment_id IS 'Assignment identifier used in the source CWM system.'
/
COMMENT ON COLUMN supplier_submission.assignment_status_id IS 'The status ID from the legacy VMS.'
/
COMMENT ON COLUMN supplier_submission.assignment_status IS 'The text of the assignment status (localized into English for now)'
/
COMMENT ON COLUMN supplier_submission.assignment_start_date IS '??? Assignment planned start date?  OR actual start date?  Not sure yet.'
/
COMMENT ON COLUMN supplier_submission.assignment_pay_rate IS 'Rate payed to the candidate (may be NULL for legacy IQN data)'
/
COMMENT ON COLUMN supplier_submission.assignment_bill_rate IS 'Bill Rate for the assignment.'
/
COMMENT ON COLUMN supplier_submission.assignment_unfav_term_date IS 'Date the assignment was unfavorably terminated.'
/
COMMENT ON COLUMN supplier_submission.assignment_end_date IS 'Date the assignment was favorably terminated.'
/
COMMENT ON COLUMN supplier_submission.last_modified_date IS 'When this row was loaded or last updated'
/
COMMENT ON COLUMN supplier_submission.assignment_end_type IS 'How did the assignment end?'
/


