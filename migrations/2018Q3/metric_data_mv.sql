
DECLARE
   v_cnt   NUMBER := 0;
BEGIN
        
        SELECT COUNT (1)
          INTO v_cnt
          FROM user_objects u
         WHERE u.object_name = 'METRIC_DATA_MV'
               AND object_type = 'MATERIALIZED VIEW';
       
        IF v_cnt > 0 THEN
           EXECUTE immediate ('drop materialized view METRIC_DATA_MV');
        END IF; 
        
END;
/
CREATE MATERIALIZED VIEW SUPPLIER_SCORECARD.METRIC_DATA_MV (
                           log_in_client_guid,
                           visible_client_guid,
                           release_guid,
                           client_guid,
                           metric_score_date,
                           legacy_source_vms,
                           client_name,
                           supplier_guid,
                           supplier_name,
                           release_date,
                           requisition_guid,
                           requisition_id,
                           requisition_create_date,
                           requisition_currency,
                           requisition_title,
                           requisition_industry,
                           requisition_country,
                           requisition_state,
                           requisition_city,
                           release_tier,
                           requisition_positions,
                           requisition_rate,
                           requisition_last_ssc_refresh,
                           submission_guid,
                           submission_date,
                           candidate_name,
                           submitted_bill_rate,
                           offer_made_date,
                           offer_accepted_date,
                           offer_rejected_date,
                           offer_accepted_rate,
                           interview_requested_date,
                           interview_scheduled_date,
                           interview_date,
                           avg_interview_rating,
                           assignment_id,
                           assignment_status,
                           assignment_start_date,
                           assignment_pay_rate,
                           assignment_bill_rate,
                           assignment_unfav_term_date,
                           assignment_end_date,
                           assignment_end_type,
                           submission_last_ssc_refresh,
                           excluded_requisition_guid, -- use this col for performance (check for NULL)
                           requisition_inclusion_status,
                           excluded_submission_guid, -- use this col for performance (check for NULL)
                           submission_inclusion_status)
TABLESPACE FALCON_SUPPLIER_SCORECARD
PCTUSED    0
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
NOCACHE
LOGGING
NOCOMPRESS
NOPARALLEL
BUILD IMMEDIATE
REFRESH FORCE ON DEMAND
WITH PRIMARY KEY
AS SELECT cvl.log_in_client_guid,
                           cvl.visible_client_guid,
                           mv.release_guid,
                           mv.client_guid,
                           mv.metric_score_date,
                           mv.legacy_source_vms,
                           mv.client_name,
                           mv.supplier_guid,
                           mv.supplier_name,
                           mv.release_date,
                           mv.requisition_guid,
                           mv.requisition_id,
                           mv.requisition_create_date,
                           mv.requisition_currency,
                           mv.requisition_title,
                           mv.requisition_industry,
                           mv.requisition_country,
                           mv.requisition_state,
                           mv.requisition_city,
                           mv.release_tier,
                           mv.requisition_positions,
                           mv.requisition_rate,
                           mv.requisition_last_ssc_refresh,
                           mv.submission_guid,
                           mv.submission_date,
                           mv.candidate_name,
                           mv.submitted_bill_rate,
                           mv.offer_made_date,
                           mv.offer_accepted_date,
                           mv.offer_rejected_date,
                           mv.offer_accepted_rate,
                           mv.interview_requested_date,
                           mv.interview_scheduled_date,
                           mv.interview_date,
                           mv.avg_interview_rating,
                           mv.assignment_id,
                           mv.assignment_status,
                           mv.assignment_start_date,
                           mv.assignment_pay_rate,
                           mv.assignment_bill_rate,
                           mv.assignment_unfav_term_date,
                           mv.assignment_end_date,
                           mv.assignment_end_type,
                           mv.submission_last_ssc_refresh,
                           xr.requisition_guid AS excluded_requisition_guid, -- use this col for performance (check for NULL)
                           CASE                -- use this col for readability
                              WHEN xr.requisition_guid IS NULL THEN 'included'
                              ELSE 'excluded'
                           END
                              AS requisition_inclusion_status,
                           xc.candidate_guid AS excluded_submission_guid, -- use this col for performance (check for NULL)
                           CASE          -- use this col for human readability
                              WHEN xc.candidate_guid IS NULL THEN 'included'
                              ELSE 'excluded'
                           END
                              AS submission_inclusion_status
                      FROM supplier_scorecard.release_submission_iqn_mv mv,
                           supplier_scorecard.client_visibility_list cvl,
                           supplier_scorecard.excluded_requisition xr,
                           supplier_scorecard.excluded_candidate xc
                     WHERE     cvl.visible_client_guid = mv.client_guid
                           AND mv.requisition_guid = xr.requisition_guid(+) -- outer to get requisitions which are NOT excluded
                           AND mv.submission_guid = xc.candidate_guid(+)
                           AND xr.requisition_guid IS NULL
                           AND xc.candidate_guid IS NULL
                    UNION ALL
                    SELECT cvl.log_in_client_guid,
                           cvl.visible_client_guid,
                           mv.release_guid,
                           mv.client_guid,
                           mv.metric_score_date,
                           mv.legacy_source_vms,
                           mv.client_name,
                           mv.supplier_guid,
                           mv.supplier_name,
                           mv.release_date,
                           mv.requisition_guid,
                           mv.requisition_id,
                           mv.requisition_create_date,
                           mv.requisition_currency,
                           mv.requisition_title,
                           mv.requisition_industry,
                           mv.requisition_country,
                           mv.requisition_state,
                           mv.requisition_city,
                           mv.release_tier,
                           mv.requisition_positions,
                           mv.requisition_rate,
                           mv.requisition_last_ssc_refresh,
                           mv.submission_guid,
                           mv.submission_date,
                           mv.candidate_name,
                           mv.submitted_bill_rate,
                           mv.offer_made_date,
                           mv.offer_accepted_date,
                           mv.offer_rejected_date,
                           mv.offer_accepted_rate,
                           mv.interview_requested_date,
                           mv.interview_scheduled_date,
                           mv.interview_date,
                           mv.avg_interview_rating,
                           mv.assignment_id,
                           mv.assignment_status,
                           mv.assignment_start_date,
                           mv.assignment_pay_rate,
                           mv.assignment_bill_rate,
                           mv.assignment_unfav_term_date,
                           mv.assignment_end_date,
                           mv.assignment_end_type,
                           mv.submission_last_ssc_refresh,
                           xr.requisition_guid AS excluded_requisition_guid, -- use this col for performance (check for NULL)
                           CASE                -- use this col for readability
                              WHEN xr.requisition_guid IS NULL THEN 'included'
                              ELSE 'excluded'
                           END
                              AS requisition_inclusion_status,
                           xc.candidate_guid AS excluded_submission_guid, -- use this col for performance (check for NULL)
                           CASE          -- use this col for human readability
                              WHEN xc.candidate_guid IS NULL THEN 'included'
                              ELSE 'excluded'
                           END
                              AS submission_inclusion_status
                      FROM supplier_scorecard.release_submission_beeline_mv mv,
                           supplier_scorecard.client_visibility_list cvl,
                           supplier_scorecard.excluded_requisition xr,
                           supplier_scorecard.excluded_candidate xc
                     WHERE     cvl.visible_client_guid = mv.client_guid
                           AND mv.requisition_guid = xr.requisition_guid(+) -- outer to get requisitions which are NOT excluded
                           AND mv.submission_guid = xc.candidate_guid(+)
                           AND xr.requisition_guid IS NULL
                           AND xc.candidate_guid IS NULL
/



COMMENT ON MATERIALIZED VIEW SUPPLIER_SCORECARD.METRIC_DATA_MV IS 'snapshot table for snapshot SUPPLIER_SCORECARD.SUMMARIZED_METRIC_DATA_MV'
/

CREATE OR REPLACE SYNONYM SUPPLIER_SCORECARD_USER.METRIC_DATA_MV FOR SUPPLIER_SCORECARD.METRIC_DATA_MV
/

 GRANT SELECT ON METRIC_DATA_MV TO supplier_scorecard_user
/

 GRANT SELECT ON METRIC_DATA_MV TO ops
/

 GRANT SELECT ON METRIC_DATA_MV TO Readonly
/