/* Formatted on 12/2/2016 1:01:30 PM (QP5 v5.300) */
CREATE OR REPLACE PACKAGE transaction_log_dil_pkg AS
    /******************************************************************************
       NAME:       transaction_log_dil_pkg
       PURPOSE:

       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        6/19/2015      jlooney       1. Created this package.

    ******************************************************************************/



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
                              pi_message_text        IN transaction_log.MESSAGE_TEXT%TYPE DEFAULT NULL);
END transaction_log_dil_pkg;
/


DECLARE
BEGIN
    EXECUTE IMMEDIATE
        'CREATE OR REPLACE SYNONYM ' || USER || '_user.transaction_log_dil_pkg FOR ' || USER || '.module_config_dil_pkg';

    EXECUTE IMMEDIATE
        'GRANT EXECUTE ON ' || USER || '.transaction_log_dil_pkg TO DADMIN, FALCON_READONLY, ' || USER || '_READWRITE';
END;
/