-----  tables
-- DATABASECHANGELOG
GRANT SELECT ON databasechangelog TO supplier_scorecard_user, readonly, ops
/
-- DATABASECHANGELOGLOCK
GRANT SELECT ON databasechangeloglock TO supplier_scorecard_user, readonly, ops
/

-- DEFAULT_METRIC_CONVERSION
GRANT SELECT, INSERT, UPDATE, DELETE ON default_metric_conversion TO supplier_scorecard_user
/
GRANT SELECT ON default_metric_conversion TO readonly, ops
/

-- CLIENT_CATEGORY_COEFFICIENT
GRANT SELECT ON client_category_coefficient TO supplier_scorecard_user
/
GRANT SELECT ON client_category_coefficient TO readonly, ops
/

-- CLIENT_METRIC_COEFFICIENT
GRANT SELECT ON client_metric_coefficient TO supplier_scorecard_user
/
GRANT SELECT ON client_metric_coefficient TO readonly, ops
/

-- CLIENT_METRIC_CONVERSION
GRANT SELECT ON client_metric_conversion TO supplier_scorecard_user
/
GRANT SELECT ON client_metric_conversion TO readonly, ops
/

-- CLIENT_VISIBILITY_LIST
GRANT SELECT ON client_visibility_list TO supplier_scorecard_user, ops, readonly
/

-- CLIENT_VISIBILITY_LIST_GTT
GRANT SELECT, INSERT, UPDATE, DELETE ON client_visibility_list_gtt TO ssis_user, operationalstore
/
GRANT SELECT ON client_visibility_list_gtt TO readonly, ops
/

-- EXCLUDED_CANDIDATE
GRANT SELECT, INSERT, UPDATE, DELETE ON excluded_candidate TO supplier_scorecard_user
/
GRANT SELECT ON excluded_candidate TO readonly, ops
/

-- EXCLUDED_REQUISITION
GRANT SELECT, INSERT, UPDATE, DELETE ON excluded_requisition TO supplier_scorecard_user
/
GRANT SELECT ON excluded_requisition TO readonly, ops
/

-- METRIC
GRANT SELECT, INSERT, UPDATE, DELETE ON metric TO supplier_scorecard_user
/
GRANT SELECT ON metric TO readonly, ops
/


-- PROCESSING_LOG
GRANT SELECT ON processing_log TO supplier_scorecard_user, ops, readonly
/
-- TRANSACTION_LOG
GRANT SELECT, INSERT ON transaction_log TO supplier_scorecard_user
/
GRANT SELECT ON transaction_log TO readonly, ops
/


-- msvc-1344 drops and recreates data tables.  Adding this comment so this script reruns.
-- SUPPLIER_RELEASE
GRANT SELECT ON supplier_release TO supplier_scorecard_user, readonly, ops
/
-- SUPPLIER_SUBMISSION
GRANT SELECT ON supplier_submission TO supplier_scorecard_user, readonly, ops
/
-- msvc-782 drops and recreates temp tables.  Adding comment so this script reruns.
-- msvc-807 drops and recreates temp tables.  Adding comment so this script reruns.
-- msvc-1019 drops and recreates temp tables.  Adding comment so this script reruns.
-- SUPPLIER_RELEASE_GTT
GRANT SELECT, INSERT, UPDATE, DELETE ON supplier_release_gtt TO ssis_user, operationalstore
/
GRANT SELECT ON supplier_release_gtt TO readonly, ops
/
-- SUPPLIER_SUBMISSION_GTT
GRANT SELECT, INSERT, UPDATE, DELETE ON supplier_submission_gtt TO ssis_user, operationalstore
/
GRANT SELECT ON supplier_submission_gtt TO readonly, ops
/
GRANT SELECT ON supplier_scorecard_comments TO supplier_scorecard_user, readonly, ops
/

-- msvc-781 - drop and recreate load_history.  Adding comment to rerun grants
-- LOAD_HISTORY
GRANT SELECT ON load_history TO supplier_scorecard_user, readonly, ops
/


-----  views
-- supp_data_and_exclusions_vw
GRANT SELECT ON supp_data_and_exclusions_vw TO supplier_scorecard_user, readonly, ops
/
-- supp_data_and_exclusions_vw
GRANT SELECT ON client_visibility_list_vw TO supplier_scorecard_user, readonly, ops
/

-----  materialized views
GRANT SELECT ON release_submission_beeline_mv TO supplier_scorecard_user, readonly, ops
/
GRANT SELECT ON release_submission_iqn_mv TO supplier_scorecard_user, readonly, ops
/
GRANT SELECT ON SUPPLIER_SCORECARD.METRIC_DATA_MV TO OPS, READONLY, SUPPLIER_SCORECARD_USER
/
GRANT SELECT ON supplier_scorecard.supplier_name_mv  TO OPS, READONLY, SUPPLIER_SCORECARD_USER
/

-----  packages
-- LOGGER_PKG
--   {none}
-- SUPPLIER_DATA_UTILITY
GRANT EXECUTE ON supplier_data_utility TO ssis_user, operationalstore, ops
/
GRANT DEBUG ON supplier_data_utility TO ops
/
-- SUPPLIER_DATA_API
GRANT EXECUTE ON supplier_data_api TO supplier_scorecard_user
/
GRANT EXECUTE, DEBUG ON supplier_data_api TO ops
/
-- CLIENT_METRIC_SETTINGS_UTIL
GRANT EXECUTE ON client_metric_settings_util TO supplier_scorecard_user
/
GRANT DEBUG ON client_metric_settings_util TO ops
/
-- CLIENT_EXCLUSION_UTIL
GRANT EXECUTE ON client_exclusion_util TO supplier_scorecard_user
/
GRANT DEBUG ON client_exclusion_util TO ops
/


-- MSVC-2014 - Created table for duplicate supplier release data on Beeline's lower environments
GRANT SELECT ON supplier_release_duplicates TO readonly, ops
/



