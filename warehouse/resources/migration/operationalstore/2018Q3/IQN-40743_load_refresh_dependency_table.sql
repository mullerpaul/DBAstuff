-- Only loading info for USPROD now since I don't think the WF legos are used for anything
-- other than ad-hoc requests from execs.  Currently all of those fall on McKay.  
-- I'll bring this up with him.

-- This list does NOT contain dependencies for the following legos.
-- Those were code-based, or depended on other schema objects, and so I left them out for now
-- be sure to add data for these later.

-- LEGO_INVOICED_EXPD_DETAIL
-- LEGO_INVD_EXPD_DATE_RU
-- LEGO_CAC_COLLECTION_HISTORY
-- LEGO_CAC_HISTORY
-- LEGO_JOB_FOID_GUID_MAP
-- LEGO_JOB_OPP_FOID_GUID_MAP
-- LEGO_MATCH_FOID_GUID_MAP
-- LEGO_SUPPLIER_SCORECARD
-- LEGO_MNTH_ASSGN_LIST_SPEND_DET
-- LEGO_ALL_ORGS_CALENDAR
-- LEGO_FINANCE_REVENUE
-- LEGO_INVOICE_DETAIL
-- LEGO_DATE_TREND


INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSIGN_MANAGED_CAC', 'USPROD', 'LEGO_ASSIGNMENT_CAC_MAP', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSIGN_MANAGED_CAC', 'USPROD', 'LEGO_MANAGED_CAC', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_MANAGED_CAC', 'USPROD', 'LEGO_JOB_CAC_MAP', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_MANAGED_CAC', 'USPROD', 'LEGO_MANAGED_CAC', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSIGNMENT_ROW_SECURITY', 'USPROD', 'LEGO_ASSIGNMENT_SLOTS', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSIGNMENT_ROW_SECURITY', 'USPROD', 'LEGO_MANAGED_PERSON', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSIGNMENT_ROW_SECURITY', 'USPROD', 'LEGO_ASSIGN_MANAGED_CAC', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_ROW_SECURITY', 'USPROD', 'LEGO_JOB_SLOTS', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_ROW_SECURITY', 'USPROD', 'LEGO_MANAGED_PERSON', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_ROW_SECURITY', 'USPROD', 'LEGO_JOB_MANAGED_CAC', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_OPPORTUNITY', 'USPROD', 'LEGO_JOB', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_POSITION_TIME_TO_FILL', 'USPROD', 'LEGO_JOB', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_POSITION_TIME_TO_FILL', 'USPROD', 'LEGO_JOB_RATES', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_POSITION_TIME_TO_FILL', 'USPROD', 'LEGO_JOB_WORK_LOCATION', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_POSITION_TIME_TO_FILL', 'USPROD', 'LEGO_POSITION_HISTORY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_POSITION_TIME_TO_FILL', 'USPROD', 'LEGO_PLACE', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_POSITION_TIME_TO_FILL', 'USPROD', 'LEGO_BUS_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_REQ_BY_STATUS_DETAIL', 'USPROD', 'LEGO_BUS_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_REQ_BY_STATUS_DETAIL', 'USPROD', 'LEGO_PERSON', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_REQ_BY_STATUS_DETAIL', 'USPROD', 'LEGO_JAVA_CONSTANT_LOOKUP', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_REQ_BY_STATUS_DETAIL', 'USPROD', 'LEGO_JOB', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MATCH', 'USPROD', 'LEGO_JOB_OPPORTUNITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_REQ_BY_STATUS_ORG_ROLLUP', 'USPROD', 'LEGO_REQ_BY_STATUS_DETAIL', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_REQ_BY_STATUS_ORG_ROLLUP', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_REQ_BY_STATUS_ROW_ROLLUP', 'USPROD', 'LEGO_REQ_BY_STATUS_DETAIL', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_REQ_BY_STATUS_ROW_ROLLUP', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_REQ_BY_STATUS_ROW_ROLLUP', 'USPROD', 'LEGO_JOB_ROW_SECURITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_ASSIGNMENT_EA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_ASSIGNMENT_TA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_ASSIGNMENT_WO', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_PERSON', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_BUS_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_MSP_USER_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_MATCH', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_JAVA_CONSTANT_LOOKUP', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_JOB_OPPORTUNITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_MATCH', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_ASSIGNMENT_EA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_ASSIGNMENT_TA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_ASSIGNMENT_WO', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_ADDRESS', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_CONTACT_ADDRESS', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_JOB', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_JOB_POSITION', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_JOB_FILL_TREND', 'USPROD', 'LEGO_JOB_RATES', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MATCH_STATS_BY_JOB', 'USPROD', 'LEGO_JOB_OPPORTUNITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MATCH_STATS_BY_JOB', 'USPROD', 'LEGO_MATCH', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MATCH_STATS_BY_JOB', 'USPROD', 'LEGO_INTERVIEW', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_ATOM_DETAIL', 'USPROD', 'LEGO_PERSON', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_ATOM_DETAIL', 'USPROD', 'LEGO_ASSIGNMENT_EA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_ATOM_DETAIL', 'USPROD', 'LEGO_ASSIGNMENT_TA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_ATOM_DETAIL', 'USPROD', 'LEGO_ASSIGNMENT_WO', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MONTHLY_ASSIGNMENT_LIST', 'USPROD', 'LEGO_ASSIGNMENT_EA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MONTHLY_ASSIGNMENT_LIST', 'USPROD', 'LEGO_ASSIGNMENT_TA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MONTHLY_ASSIGNMENT_LIST', 'USPROD', 'LEGO_ASSIGNMENT_WO', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_DETAIL', 'USPROD', 'LEGO_ASSIGNMENT_EA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_DETAIL', 'USPROD', 'LEGO_ASSIGNMENT_TA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_DETAIL', 'USPROD', 'LEGO_ASSIGNMENT_WO', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_DETAIL', 'USPROD', 'LEGO_PERSON', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_DETAIL', 'USPROD', 'LEGO_BUS_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_CMSA_ATOM_OR', 'USPROD', 'LEGO_ASSGN_ATOM_DETAIL', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_CMSA_ATOM_OR', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_CMSA_ATOM_RR', 'USPROD', 'LEGO_ASSGN_ATOM_DETAIL', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_CMSA_ATOM_RR', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_CMSA_ATOM_RR', 'USPROD', 'LEGO_ASSIGNMENT_ROW_SECURITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_ST_ATOM_OR', 'USPROD', 'LEGO_ASSGN_ATOM_DETAIL', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_ST_ATOM_OR', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_ST_ATOM_RR', 'USPROD', 'LEGO_ASSGN_ATOM_DETAIL', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_ST_ATOM_RR', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_ASSGN_LOC_ST_ATOM_RR', 'USPROD', 'LEGO_ASSIGNMENT_ROW_SECURITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MNTH_ASGN_CNTSPND_ORGROLL', 'USPROD', 'LEGO_MNTH_ASSGN_LIST_SPEND_DET', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MNTH_ASGN_CNTSPND_ORGROLL', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MNTH_ASGN_CNTSPND_ROWROLL', 'USPROD', 'LEGO_ASSIGNMENT_ROW_SECURITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MNTH_ASGN_CNTSPND_ROWROLL', 'USPROD', 'LEGO_MNTH_ASSGN_LIST_SPEND_DET', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_MNTH_ASGN_CNTSPND_ROWROLL', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_ORG_ROLLUP', 'USPROD', 'LEGO_UPCOMING_ENDS_DETAIL', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_ORG_ROLLUP', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_ROW_ROLLUP', 'USPROD', 'LEGO_UPCOMING_ENDS_DETAIL', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_ROW_ROLLUP', 'USPROD', 'LEGO_ASSIGNMENT_ROW_SECURITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_UPCOMING_ENDS_ROW_ROLLUP', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_TIME_TO_FILL', 'USPROD', 'LEGO_ASSIGNMENT_WO', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_TIME_TO_FILL', 'USPROD', 'LEGO_ASSIGNMENT_EA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_TIME_TO_FILL', 'USPROD', 'LEGO_JOB', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_TIME_TO_FILL', 'USPROD', 'LEGO_JOB_OPPORTUNITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_TIME_TO_FILL', 'USPROD', 'LEGO_MATCH', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_TIME_TO_FILL', 'USPROD', 'LEGO_JAVA_CONSTANT_LOOKUP', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SOW_MILESTONE_INVOICE', 'USPROD', 'LEGO_PROJECT_AGREEMENT', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVCD_EXPENDITURE_SUM', 'USPROD', 'LEGO_INVOICE_DETAIL', 'USPROD')
/


COMMIT
/
