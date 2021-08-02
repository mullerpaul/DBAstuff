-- To avoid hardcoding schema names in code, the SUPPLIER_SCORECARD_USER schema needs
-- synonyms for the SUPPLIER_SCORECARD objects which it can access.
-- Normally, we'd need to run a migration as SUPPLIER_SCORECARD_USER to create the synonyms
-- there; but since SUPPLIER_SCORECARD has the CREATE ANY SYNONYM privilege, we can just run
-- this script as SUPPLIER_SCORECARD to create the synonyms in SUPPLIER_SCORECARD_USER!
-- Having that privilege is really a security risk; but OTOH, its pretty convienient.

--- tables
CREATE OR REPLACE SYNONYM supplier_scorecard_user.databasechangelog 
FOR supplier_scorecard.databasechangelog
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.databasechangeloglock 
FOR supplier_scorecard.databasechangeloglock
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.default_metric_multiplier 
FOR supplier_scorecard.default_metric_multiplier
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.default_metric_weight 
FOR supplier_scorecard.default_metric_weight
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.client_metric_coefficient
FOR supplier_scorecard.client_metric_coefficient
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.client_metric_conversion
FOR supplier_scorecard.client_metric_conversion
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.excluded_candidate 
FOR supplier_scorecard.excluded_candidate
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.excluded_requisition 
FOR supplier_scorecard.excluded_requisition
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.load_history 
FOR supplier_scorecard.load_history
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.metric 
FOR supplier_scorecard.metric
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.processing_log 
FOR supplier_scorecard.processing_log
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.supplier_release 
FOR supplier_scorecard.supplier_release
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.supplier_release_gtt 
FOR supplier_scorecard.supplier_release_gtt
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.supplier_submission 
FOR supplier_scorecard.supplier_submission
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.supplier_submission_gtt 
FOR supplier_scorecard.supplier_submission_gtt
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.transaction_log 
FOR supplier_scorecard.transaction_log
/

--- packages
CREATE OR REPLACE SYNONYM supplier_scorecard_user.logger_pkg
FOR supplier_scorecard.logger_pkg
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.supplier_data_utility
FOR supplier_scorecard.supplier_data_utility
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.client_metric_settings_util
FOR supplier_scorecard.client_metric_settings_util
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.client_exclusion_util
FOR supplier_scorecard.client_exclusion_util
/

--- views
CREATE OR REPLACE SYNONYM supplier_scorecard_user.supp_data_and_exclusions_vw
FOR supplier_scorecard.supp_data_and_exclusions_vw
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.client_visibility_list_vw
FOR supplier_scorecard.client_visibility_list_vw
/
--- Mviews
CREATE OR REPLACE SYNONYM supplier_scorecard_user.supplier_name_mv
FOR supplier_scorecard.supplier_name_mv
/
CREATE OR REPLACE SYNONYM supplier_scorecard_user.metric_data_mv
FOR supplier_scorecard.metric_data_mv
/
