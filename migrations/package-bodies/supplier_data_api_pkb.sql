CREATE OR REPLACE PACKAGE BODY supplier_data_api
AS
/******************************************************************************
   NAME:       supplier_data_api
   PURPOSE:    public functions and procedures which read the detailed data 
               used for grading and ranking suppliers.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   MSCV-707   05/12/2017  Paul Muller      Created package
   MSCV-2764  03/06/2018  McKay Dunlap     Removed Reference to client_metric_coefficient_guid
                                           to client_metric_conversion table changed join to be on 
										   metric_id, client_guid 
******************************************************************************/

  ------------------------------------------------------------------------------
  PROCEDURE get_supplier_metric_scores (pi_client_guid         IN  RAW,
                                        PI_INTERVAL_START_DATE in  date,
                                        pi_interval_end_date   IN  DATE,
                                        po_metric_scores       OUT SYS_REFCURSOR)
  IS
    lv_interval_start_date DATE := pi_interval_start_date;
    lv_interval_end_date   DATE := nvl(pi_interval_end_date, SYSDATE);
    
  BEGIN
    /* Confirm valid inputs */
    IF (pi_client_guid IS NULL OR
        lv_interval_start_date IS NULL OR
        lv_interval_start_date >= lv_interval_end_date) THEN
      raise_application_error(-20001, 'Invalid inputs');
    END IF;
    
    /* Open the results cursor */
    OPEN po_metric_scores FOR
    WITH metric_numbers
      AS (SELECT supplier_name, 
                 count(DISTINCT requisition_guid) AS requisitions_received,
                 count(submission_guid)           AS total_candidates_submitted,
                 count(assignment_start_date)     AS placements_count,
                 1 - (count(CASE WHEN submission_guid IS NULL THEN 'x' END) / count(DISTINCT requisition_guid))                 AS supplier_response_ratio,
                 count(CASE WHEN offer_accepted_rate > requisition_rate THEN 'x' END)  AS placements_over_req_rate,
                 count(CASE WHEN offer_accepted_rate <= requisition_rate THEN 'x' END) AS placements_not_over_req_rate,
                 count(offer_rejected_date)       AS offer_rejection_count,
                 count(offer_accepted_date)       AS offer_accepted_count,
                 count(offer_rejected_date) / nullif(count(submission_guid), 0)        AS offer_rejected_ratio,
                 count(offer_accepted_date) / nullif(count(submission_guid), 0)        AS offer_acceptance_ratio,
                 count(assignment_start_date) / nullif(count(submission_guid), 0)      AS submit_to_hire_ratio,
                 count(CASE WHEN submitted_bill_rate <= requisition_rate THEN 'x' END) / nullif(count(assignment_start_date),0) AS rate_competitiveness,
                 count(assignment_unfav_term_date) / nullif(count(COALESCE(assignment_end_date, assignment_unfav_term_date)),0) AS unfavorable_termination_ratio
            FROM supp_data_and_exclusions_vw 
           WHERE client_guid = pi_client_guid
             AND excluded_requisition_guid IS NULL
             AND excluded_submission_guid IS NULL
             AND (submission_date >= pi_interval_start_date OR 
                  (submission_date IS NULL AND release_date >= pi_interval_start_date))
             AND (submission_date < pi_interval_end_date OR 
                  (submission_date IS NULL AND release_date < pi_interval_end_date))
           GROUP BY supplier_guid, supplier_name),
         unpivot_scores_to_rows
      AS (SELECT *
            FROM metric_numbers
         UNPIVOT (metric_raw_number
                  FOR metric_id
                   IN (requisitions_received AS 1006,    --numbers above 1000 are not in metric table yet.
                       total_candidates_submitted AS 10,
                       placements_count AS 11,
                       supplier_response_ratio AS 1000,
                       placements_over_req_rate AS 23,
                       placements_not_over_req_rate AS 1001,
                       offer_rejection_count AS 1002,
                       offer_accepted_count AS 1003,
                       offer_rejected_ratio AS 1004,
                       offer_acceptance_ratio AS 14,
                       submit_to_hire_ratio AS 15,
                       rate_competitiveness AS 24,
                       unfavorable_termination_ratio AS 1005))),
         metric_score_ranges
      AS (SELECT me.metric_id, me.metric_name, me.metric_category, 
                 e.metric_coefficient,
                 n.greater_than_or_equal, n.less_than, n.range_grade, n.range_score, n.range_score_conversion_factor
            FROM metric me,
                 client_metric_coefficient e,
                 client_metric_conversion n
           WHERE me.metric_id = e.metric_id
             --AND e.client_metric_coefficient_guid = n.client_metric_coefficient_guid
			 AND e.metric_id = n.metric_id and e.client_guid = n.client_guid 
             AND e.client_guid = pi_client_guid) 
  SELECT u.supplier_name, m.metric_category, m.metric_name, 
         u.metric_raw_number, m.range_grade as metric_grade, 
         CASE
           WHEN m.range_score IS NOT NULL
             THEN m.range_score
           WHEN m.range_score_conversion_factor IS NOT NULL
             THEN m.range_Score_conversion_factor * u.metric_raw_number
           ELSE 
             to_number(NULL)
         END as metric_score
    FROM unpivot_scores_to_rows u,
         metric_score_ranges m
   WHERE u.metric_id = m.metric_id(+)
     AND u.metric_raw_number >= m.greater_than_or_equal(+)
     AND u.metric_raw_number < m.less_than(+); 

  END get_supplier_metric_scores; 

END supplier_data_api;
/
