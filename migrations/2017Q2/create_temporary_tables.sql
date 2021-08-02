-- no constraints on the temp tables.
-- data will be validated when moved to the perm tables.
-- revisit this decision later!

CREATE GLOBAL TEMPORARY TABLE supplier_release_gtt (
  release_guid             RAW(17)            NOT NULL,
  client_guid              RAW(17)            NOT NULL,
  client_name              VARCHAR2(128 CHAR) NOT NULL,
  supplier_guid            RAW(17)            NOT NULL,
  supplier_name            VARCHAR2(255 CHAR) NOT NULL,
  release_date             DATE               NOT NULL,
  requisition_guid         RAW(17)            NOT NULL,
  requisition_id           VARCHAR2(50)       NOT NULL,
  requisition_create_date  DATE               NOT NULL,
  requisition_currency     VARCHAR2(50)       NOT NULL,
  requisition_title        VARCHAR2(255 CHAR),
  requisition_industry     VARCHAR2(255 CHAR),
  requisition_country      VARCHAR2(100 CHAR),
  requisition_state        VARCHAR2(100 CHAR),
  requisition_city         VARCHAR2(100 CHAR),
  release_tier             VARCHAR2(255 CHAR),
  requisition_positions    NUMBER,
  requisition_rate         NUMBER)
ON COMMIT PRESERVE ROWS
/


CREATE GLOBAL TEMPORARY TABLE supplier_submission_gtt (
  submission_guid             RAW(17)  NOT NULL,
  submission_date             DATE     NOT NULL,
  release_guid                RAW(17)  NOT NULL,
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
  assignment_end_type         VARCHAR2(255))
ON COMMIT PRESERVE ROWS
/

