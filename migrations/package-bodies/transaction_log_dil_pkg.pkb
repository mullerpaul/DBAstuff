/* Formatted on 4/13/2016 10:30:07 AM (QP5 v5.287) */
CREATE OR REPLACE PACKAGE BODY transaction_log_dil_pkg AS
   /******************************************************************************
      NAME:       transaction_log_dil_pkg
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        12/2/2016      jlooney       Created this package.

   ******************************************************************************/



   g_source   CONSTANT VARCHAR2 (30) := 'TRANSACTION_LOG_DIL_PKG';

   PROCEDURE create_txn_log (pi_session_guid        IN transaction_log.session_guid%TYPE,
                             pi_request_guid        IN transaction_log.request_guid%TYPE,
                             pi_txn_guid            IN transaction_log.txn_guid%TYPE,
                             pi_request_timestamp   IN transaction_log.request_timestamp%TYPE,
                             pi_bus_org_guid        IN transaction_log.bus_org_guid%TYPE,
                             pi_entity_name         IN transaction_log.entity_name%TYPE,
                             pi_entity_guid_1       IN transaction_log.entity_guid_1%TYPE,
                             pi_entity_guid_2       IN transaction_log.entity_guid_2%TYPE DEFAULT NULL,
                             pi_login_person_guid   IN transaction_log.login_person_guid%TYPE DEFAULT NULL,
                             pi_proxy_person_guid   IN transaction_log.proxy_person_guid%TYPE DEFAULT NULL,
                             pi_workflow_guid       IN transaction_log.workflow_guid%TYPE DEFAULT NULL,
                             pi_request_method      IN transaction_log.request_method%TYPE DEFAULT NULL,
                             pi_request_uri         IN transaction_log.request_uri%TYPE DEFAULT NULL,
                             pi_message_text        IN transaction_log.MESSAGE_TEXT%TYPE DEFAULT NULL) IS
      v_source   VARCHAR2 (61) := g_source || '.CREATE_TXN_LOG';
   BEGIN
      logger_pkg.set_source (v_source);
      logger_pkg.set_code_location ('INSERT INTO TRANSACTION_LOG');

      INSERT INTO transaction_log (txn_guid,
                                   txn_date,
                                   session_guid,
                                   request_guid,
                                   request_timestamp,
                                   processed_timestamp,
                                   bus_org_guid,
                                   entity_name,
                                   entity_guid_1,
                                   entity_guid_2,
                                   login_person_guid,
                                   proxy_person_guid,
                                   workflow_guid,
                                   request_method,
                                   request_uri,
                                   MESSAGE_TEXT)
           VALUES (pi_txn_guid,
                   pi_request_timestamp,
                   pi_session_guid,
                   pi_request_guid,
                   pi_request_timestamp,
                   SYS_EXTRACT_UTC (SYSTIMESTAMP),
                   pi_bus_org_guid,
                   pi_entity_name,
                   pi_entity_guid_1,
                   pi_entity_guid_2,
                   pi_login_person_guid,
                   pi_proxy_person_guid,
                   pi_workflow_guid,
                   pi_request_method,
                   pi_request_uri,
                   pi_message_text);

      logger_pkg.unset_source (v_source);
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
         logger_pkg.info (
               'Transaction Already Processed!  SESSION_GUID='
            || pi_session_guid
            || ' REQUEST_GUID='
            || pi_request_guid
            || ' TRANSACTION_GUID='
            || pi_txn_guid);
         RAISE;
      WHEN OTHERS THEN
         logger_pkg.fatal ('ROLLBACK', SQLCODE, SQLERRM);
         logger_pkg.unset_source (v_source);
         RAISE;
   END create_txn_log;

END transaction_log_dil_pkg;
/