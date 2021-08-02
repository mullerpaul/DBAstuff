DECLARE
  PROCEDURE drop_object(pi_type IN VARCHAR2, pi_name IN VARCHAR2) IS
    le_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_not_exist, -942);
  
    lv_sql VARCHAR2(100);
  
  BEGIN
    /* This is part of a migration script, so no need to worry about this unsafe code!
    If this was "real code" in a stored procedure, callable by other processes then
    we'd want to add some validation! */
    lv_sql := 'DROP ' || pi_type || ' ' || pi_name;
    logger_pkg.info('Running ' || lv_sql);
    EXECUTE IMMEDIATE lv_sql;
    logger_pkg.info('Running ' || lv_sql || ' - complete!', TRUE);
  
  EXCEPTION
    WHEN le_not_exist THEN
      logger_pkg.info('Running ' || lv_sql || ' - object didn''t exist.', TRUE);
    
    WHEN OTHERS THEN
      logger_pkg.error(pi_message            => 'Running ' || lv_sql || ' - ERROR - ' || SQLERRM,
                       pi_error_code         => SQLCODE,
                       pi_transaction_result => NULL);
  END;

BEGIN
  /* setup */
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('MIGRATION SCRIPT');

  /* delete lego_refresh rows */
  logger_pkg.set_code_location('deleting old unused CAC lego metadata');
  logger_pkg.info('removing rows from lego_refresh - started');
  DELETE FROM lego_refresh
   WHERE object_name IN ('INIT_LEGO_CAC_CDC', 'INIT_LEGO_CAC_COLLECTION', 'LEGO_CAC_COLLECTION');
  COMMIT;
  logger_pkg.info('removing rows from lego_refresh - complete - ' || to_char(SQL%ROWCOUNT) || ' rows deleted',
                  TRUE);

  /* remove unused objects */
  logger_pkg.set_code_location('dropping old unused CAC objects');
  drop_object('TABLE', 'lego_cac_cdc');
  drop_object('TABLE', 'lego_cac_collection_cdc');
  drop_object('VIEW', 'lego_cac1_vw');
  drop_object('VIEW', 'lego_cac2_vw');

  logger_pkg.unset_source('MIGRATION SCRIPT');

END;
/

