-- Follow on from IQN-40743.  That one did NOT insert data for SSC and thats 
-- what we are doing here.  After this script inserts the SSC deps; we still 
-- need to address the following legos in US:

-- LEGO_INVOICED_EXPD_DETAIL
-- LEGO_INVD_EXPD_DATE_RU
-- LEGO_CAC_COLLECTION_HISTORY
-- LEGO_CAC_HISTORY
-- LEGO_JOB_FOID_GUID_MAP
-- LEGO_JOB_OPP_FOID_GUID_MAP
-- LEGO_MATCH_FOID_GUID_MAP
-- LEGO_MNTH_ASSGN_LIST_SPEND_DET
-- LEGO_ALL_ORGS_CALENDAR
-- LEGO_FINANCE_REVENUE
-- LEGO_INVOICE_DETAIL
-- LEGO_DATE_TREND

-- We also need to address the missing dependency info for ALL WF legos!

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_ASSIGNMENT_EA', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_ASSIGNMENT_WO', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_BUS_ORG', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_INTERVIEW', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_JAVA_CONSTANT_LOOKUP', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_JOB', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_JOB_FOID_GUID_MAP', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_JOB_OPPORTUNITY', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_JOB_OPP_FOID_GUID_MAP', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_JOB_POSITION', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_JOB_RATES', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_JOB_WORK_LOCATION', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_MATCH', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_MATCH_FOID_GUID_MAP', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_PERSON', 'USPROD')
/

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_SUPPLIER_SCORECARD', 'USPROD', 'LEGO_PLACE', 'USPROD')
/


COMMIT
/

