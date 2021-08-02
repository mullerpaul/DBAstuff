DECLARE
  lv_bulk_session_guid RAW(16) := sys_guid();

BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_source('msvc-1023 migration');
  logger_pkg.set_level('INFO');

  logger_pkg.info('copy new metric defaults into client specific tables - starting');

  FOR i IN (SELECT DISTINCT client_guid
              FROM supplier_release ) LOOP

    client_metric_settings_util.copy_defaults_to_client ( pi_client_guid  => i.client_guid,
                                                          pi_session_guid => lv_bulk_session_guid,
                                                          pi_request_guid => sys_guid() );    
  END LOOP;
    
  COMMIT;

  logger_pkg.info('copy new metric defaults into client specific tables - complete', TRUE);

END;
/


