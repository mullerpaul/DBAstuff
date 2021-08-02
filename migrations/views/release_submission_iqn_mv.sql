/*******************************************************************************
SCRIPT NAME         release_submission_iqn_mv.sql
 
OBJECT NAME         release_submission_iqn_mv
 
CREATED             Aug 30th, 2017
 
ORIGINAL AUTHOR     Joe Pullifrone and Paul Muller

STORY               MSVC-1268

DESCRIPTION         This materialized view was created to provide a pre-joined and partitioned 
                    view of the Beeline supplier scorecard data.  Organizing the data in this 
					way will speed the score queries issued by the application by helping ensure 
					they do not read any more data than necessary.

Here are the configurations for this MV:
  BUILD IMMEIDATE vs BUILD DEFERRED
    Immediate creates and populates the segments when this runs, deferred will build the segments 
    now but will not popluate them until the first refresh.

  REFRESH ON DEMAND
    This means that the MV will only be refreshed when told to do so. The alternative is 
	REFRESH ON COMMIT.  We are fine with on demand and will put that command into the load procedure.
	
******************************************************************************/  

CREATE MATERIALIZED VIEW release_submission_iqn_mv
PARTITION BY RANGE (metric_score_date)
SUBPARTITION BY HASH (client_guid) SUBPARTITIONS 128
 (PARTITION p_2015_q1 VALUES LESS THAN (TO_DATE('2015-Apr-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2015_q2 VALUES LESS THAN (TO_DATE('2015-Jul-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2015_q3 VALUES LESS THAN (TO_DATE('2015-Oct-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2015_q4 VALUES LESS THAN (TO_DATE('2016-Jan-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2016_q1 VALUES LESS THAN (TO_DATE('2016-Apr-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2016_q2 VALUES LESS THAN (TO_DATE('2016-Jul-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2016_q3 VALUES LESS THAN (TO_DATE('2016-Oct-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2016_q4 VALUES LESS THAN (TO_DATE('2017-Jan-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2017_q1 VALUES LESS THAN (TO_DATE('2017-Apr-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2017_q2 VALUES LESS THAN (TO_DATE('2017-Jul-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2017_q3 VALUES LESS THAN (TO_DATE('2017-Oct-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2017_q4 VALUES LESS THAN (TO_DATE('2018-Jan-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2018_q1 VALUES LESS THAN (TO_DATE('2018-Apr-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2018_q2 VALUES LESS THAN (TO_DATE('2018-Jul-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2018_q3 VALUES LESS THAN (TO_DATE('2018-Oct-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2018_q4 VALUES LESS THAN (TO_DATE('2019-Jan-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2019_q1 VALUES LESS THAN (TO_DATE('2019-Apr-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2019_q2 VALUES LESS THAN (TO_DATE('2019-Jul-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2019_q3 VALUES LESS THAN (TO_DATE('2019-Oct-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2019_q4 VALUES LESS THAN (TO_DATE('2020-Jan-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2020_q1 VALUES LESS THAN (TO_DATE('2020-Apr-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2020_q2 VALUES LESS THAN (TO_DATE('2020-Jul-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2020_q3 VALUES LESS THAN (TO_DATE('2020-Oct-01','YYYY-Mon-DD')) PCTFREE 0,
  PARTITION p_2020_q4 VALUES LESS THAN (TO_DATE('2021-Jan-01','YYYY-Mon-DD')) PCTFREE 0)
BUILD IMMEDIATE
REFRESH ON DEMAND
AS
SELECT r.release_guid,
       r.client_guid,
       COALESCE(s.submission_date, r.release_date) AS metric_score_date,
       r.legacy_source_vms,
       r.client_name,
       r.supplier_guid,
       r.supplier_name,
       r.release_date,
       r.requisition_guid,
       r.requisition_id,
       r.requisition_create_date,
       r.requisition_currency,
       r.requisition_title,
       r.requisition_industry,
       r.requisition_country,
       r.requisition_state,
       r.requisition_city,
       r.release_tier,
       r.requisition_positions,
       r.requisition_rate,
       r.last_modified_date AS requisition_last_ssc_refresh,
       s.submission_guid,
       s.submission_date,
       s.candidate_name,
       s.submitted_bill_rate,
       s.offer_made_date,
       s.offer_accepted_date,
       s.offer_rejected_date,
       s.offer_accepted_rate,
       s.interview_requested_date,
       s.interview_scheduled_date,
       s.interview_date,
       s.avg_interview_rating,
       s.assignment_id,
       s.assignment_status,
       s.assignment_start_date,
       s.assignment_pay_rate,
       s.assignment_bill_rate,
       s.assignment_unfav_term_date,
       s.assignment_end_date,
       s.assignment_end_type,
       s.last_modified_date AS submission_last_ssc_refresh
  FROM supplier_release r,
       supplier_submission s
 WHERE r.release_guid = s.release_guid(+)  -- outer join because releases may not have submissions
   AND r.legacy_source_vms = 'IQN'
/

