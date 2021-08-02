DECLARE
  lv_bulk_session_guid RAW(16) := sys_guid();

BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_source('msvc-1383 migration');
  logger_pkg.set_level('INFO');

  /*  First remove ALL client metric settings */
  logger_pkg.info('delete all existing client-specific settings - starting');

  /*  Normally I'd truncate instead of delete a whole table; but these tables 
      are small now (both together are less than 2mb in prod), and so the slightly
      slower execution and extra redo is a reasonable price to pay for the 
      transactional nature of DELETE.  */
  DELETE FROM client_metric_conversion;
  DELETE FROM client_metric_coefficient;

  logger_pkg.info('delete all existing client-specific settings - complete', TRUE);


  /*  Now reload client-specific settings as copies of the defaults.
      copy_defaults_to_client is also transaction-safe. */ 
  logger_pkg.info('copy new metric defaults into client specific tables - starting');

  FOR i IN (SELECT DISTINCT client_guid
              FROM supplier_release ) LOOP

    client_metric_settings_util.copy_defaults_to_client ( pi_client_guid  => i.client_guid,
                                                          pi_session_guid => lv_bulk_session_guid,
                                                          pi_request_guid => sys_guid() );    
  END LOOP;
    
  /*  gotta commit all work */
  COMMIT;

  logger_pkg.info('copy new metric defaults into client specific tables - complete', TRUE);

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    logger_pkg.error(pi_transaction_result => 'ROLLBACK',
                     pi_error_code         => SQLCODE,
                     pi_message            => 'Error in migration script, rolling back. ' || SQLERRM);
    RAISE;

END;
/


