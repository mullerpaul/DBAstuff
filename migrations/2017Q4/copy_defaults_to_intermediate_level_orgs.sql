DECLARE
    lv_bulk_session_guid RAW(16) := sys_guid();  

BEGIN
    logger_pkg.instantiate_logger;
    logger_pkg.set_source('MSVC-1915 Copy defaults to client-specific tables');
    logger_pkg.set_level('INFO');
    logger_pkg.info('copy client default metrics');

    FOR j IN (SELECT DISTINCT log_in_client_guid
                FROM client_visibility_list) LOOP

        client_metric_settings_util.copy_defaults_to_client(
            pi_client_guid    => j.log_in_client_guid,
            pi_session_guid   => lv_bulk_session_guid,
            pi_request_guid   => sys_guid()
        );

    END LOOP;

    COMMIT;
    logger_pkg.info('copy client default metrics - complete',TRUE);
    
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    logger_pkg.fatal(pi_message            => 'msvc-1915 failed : ' || SQLERRM,
                     pi_transaction_result => 'ROLLBACK',
                     pi_error_code         => SQLCODE );
    RAISE;

END;
/

