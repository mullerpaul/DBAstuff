DECLARE
    lv_bulk_session_guid RAW(16) := sys_guid();  

BEGIN
    logger_pkg.instantiate_logger;
    logger_pkg.set_source('MSVC-777 Copy default to client-specific tables');
    logger_pkg.set_level('INFO');
    logger_pkg.info('copy client default metrics');

    FOR j IN (SELECT DISTINCT client_guid
                FROM supplier_release
               WHERE client_guid = hextoraw('1C392FD9119C42D3E0530A62CA0AC690')) LOOP
        client_metric_settings_util.copy_defaults_to_client(
            pi_client_guid    => j.client_guid,
            pi_session_guid   => lv_bulk_session_guid,
            pi_request_guid   => sys_guid()
        );

    END LOOP;

    COMMIT;
    logger_pkg.info('copy client default metrics - complete',TRUE);
    
END;
/
