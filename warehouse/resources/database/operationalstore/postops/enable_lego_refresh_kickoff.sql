BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('enable_lego_refresh_kickoff');
  logger_pkg.set_code_location('Calling enable refresh');

  logger_pkg.info('enabling automatic refresh job - starting');
  lego_tools.enable_automatic_refresh_job;
  logger_pkg.info('enableing automatic refresh job - complete', TRUE);

  logger_pkg.unset_source('enable_lego_refresh_kickoff');

EXCEPTION
  WHEN OTHERS THEN
    /* We might reasonably expect the following errors:
          The job does not exist
          No database link
       In both cases, there is nothing we can do but log the error.
       Unlike most cases, we do NOT want to re-raise the error here!   */
    logger_pkg.error(pi_transaction_result => NULL,
                     pi_error_code         => SQLCODE,
                     pi_message            => 'Could not enable automatic refresh!! ' || SQLERRM);

    logger_pkg.unset_source('enable_lego_refresh_kickoff');
END;
/
