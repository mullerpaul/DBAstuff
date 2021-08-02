-- Follow on from IQN-40743 and IQN-40224.  Those two did NOT insert data for
-- the below legos:

-- LEGO_INVOICED_EXPD_DETAIL
-- LEGO_INVD_EXPD_DATE_RU
--- dependencies below

-- LEGO_CAC_COLLECTION_HISTORY
-- LEGO_CAC_HISTORY
-- LEGO_INVOICE_DETAIL
-- These legos don't have a refresh procedure in OPERATIONALSTORE - we will remove them.

-- LEGO_JOB_FOID_GUID_MAP
-- LEGO_JOB_OPP_FOID_GUID_MAP
-- LEGO_MATCH_FOID_GUID_MAP
-- These legos depend only on themselves and FO objects - no dependencies to insert!

-- LEGO_MNTH_ASSGN_LIST_SPEND_DET
-- This one depends on an MV.  No lego dependencies to insert.

-- LEGO_ALL_ORGS_CALENDAR
-- this depends on non-existant objects and probably never has been refreshed in OPERATIONALSTORE.  remove

-- LEGO_FINANCE_REVENUE
-- LEGO_DATE_TREND
-- no lego dependencies to insert

-- We are addressing the missing dependency info for WF INVOICE legos!


INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVOICED_EXPD_DETAIL', 'WFPROD', 'LEGO_BUS_ORG', 'WFPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_INVOICED_EXPD_DETAIL', 'WFPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_BUS_ORG', 'WFPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_PERSON', 'WFPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_SOW_MILESTONE_INVOICE', 'WFPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_ASSIGNMENT_EA', 'WFPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_ASSIGNMENT_WO', 'WFPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_PROJECT_AGREEMENT', 'WFPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_ASSIGN_PAYMENT_REQUEST', 'WFPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_TIMECARD_APPROVAL', 'WFPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_INVD_EXPD_DATE_RU', 'WFPROD', 'LEGO_EXPENSE_APPROVAL', 'WFPROD')
/

COMMIT
/


