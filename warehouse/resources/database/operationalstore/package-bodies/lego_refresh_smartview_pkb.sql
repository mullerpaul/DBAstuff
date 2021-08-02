CREATE OR REPLACE PACKAGE BODY operationalstore.lego_refresh_smartview AS

    gc_logging_source                CONSTANT VARCHAR2(27) := 'LEGO_REFRESH_SMARTVIEW';

    ------------------------------------------------------------------------------------
    PROCEDURE start_refresh_run (
        allowable_latency_minutes   IN NUMBER DEFAULT 60
        , p_environment_source_name IN VARCHAR2 DEFAULT NULL
        , p_object_name             IN VARCHAR2 DEFAULT NULL
    ) IS
    
     /* This will be used as the PK/FK value in refresh history tables. */
      lc_job_runtime     CONSTANT    lego_refresh_run_history.job_runtime%TYPE := sys_extract_utc(systimestamp);

      lv_remote_db_as_of_scn         lego_refresh_run_history.remote_db_as_of_scn%TYPE;
      lv_remote_db_as_of_time        lego_refresh_run_history.remote_db_as_of_time%TYPE;
      lv_previous_as_of_time         lego_refresh_run_history.remote_db_as_of_time%TYPE;
      lv_allowable_latency_interval  INTERVAL DAY TO SECOND;
      lv_job_name                    VARCHAR2(30);
      
      CURSOR lego_source_cur IS
        SELECT * FROM operationalstore.lego_source
        WHERE source_name = NVL(p_environment_source_name, source_name);
        
    BEGIN
      lego_tools.setup_session_logging(pi_log_source   => gc_logging_source);
      logger_pkg.set_code_location('smartview refresh');
      IF NOT lego_tools.get_safe_to_start_refresh_flag THEN
          raise_application_error(
              -20001,
              'Other legos are currently being refreshed. Cannot start more refreshes until previous run is complete.'
          );
      END IF;
      IF NOT ( allowable_latency_minutes BETWEEN 0 AND 1440 ) THEN
          raise_application_error(
              -20002,
              'Invalid input.  allowable_latency_minutes must be between 0 and 1440.'
          );
      END IF;
      
      logger_pkg.info('starting lego refreshes for smart view');
      
      /* Convert the input to an interval datatype for ease of computation inside the loop. */
        lv_allowable_latency_interval := allowable_latency_minutes * INTERVAL '1' MINUTE;
    
      FOR lego_source_rec IN lego_source_cur LOOP
      
        logger_pkg.info('get_remote_db_as_of_info: ' || lego_source_rec.source_name);
      
        /* First get remote DB as-of time and SCN to use in refresh. */
        lego_tools.get_remote_db_as_of_info(
            pi_source_name   => lego_source_rec.source_name,
            po_as_of_scn     => lv_remote_db_as_of_scn,
            po_as_of_time    => lv_remote_db_as_of_time
        );
        
        logger_pkg.info('insert_history_parent_row: ' || lego_source_rec.source_name);
        /* now insert a row in the refresh history parent table for this run. */
        lego_tools.insert_history_parent_row(
            pi_refresh_runtime     => lc_job_runtime,
            pi_source_as_of_time   => lv_remote_db_as_of_time,
            pi_source_as_of_scn    => lv_remote_db_as_of_scn,
            pi_caller_id           => 'Smartview Refresh',
            pi_latency_input       => allowable_latency_minutes
        );
        
        /* Make a list of all legos which need to be refreshed in order to refresh fully refresh the 
           supplier scorecard data.  Then loop over that list, inserting a history row and starting 
           a job for each.  */
          FOR lego IN (
              WITH top_level_legos   --entries for the "top-level" lego(s)
                AS ( SELECT object_name,
                            source_name
                       FROM operationalstore.lego_refresh
                      WHERE object_name = p_object_name
                        AND source_name = lego_source_rec.source_name
                   )
            SELECT object_name,
                   ROWNUM AS unique_id
              FROM ( SELECT relies_on_object_name AS object_name,
                            MAX(tree_depth)       AS depth
                       FROM ( SELECT lrd.object_name,
                                     lrd.relies_on_object_name,
                                     LEVEL + 1 AS tree_depth
                                FROM operationalstore.lego_refresh_dependency lrd
                               START WITH ( lrd.object_name, lrd.source_name ) IN
                                          ( SELECT object_name, source_name
                                              FROM top_level_legos
                                          )
                             CONNECT BY PRIOR lrd.relies_on_object_name = object_name
                                          AND lrd.relies_on_source_name = source_name
                               UNION ALL  -- add in "self-rows"
                              SELECT object_name   AS object_name,
                                     object_name   AS relies_on_object_name,
                                     1             AS tree_depth
                                FROM top_level_legos
                            )
                      GROUP BY relies_on_object_name
                      ORDER BY depth DESC
                   )
          ) LOOP

              /* For each lego to be started, first determine if its been already been refreshed recently enough.
                 If so, we don't need to do it again. If not, insert a history row then create and start a job. */
              lv_previous_as_of_time := lego_tools.get_most_recent_ref_as_of_time(
                  pi_object_name   => lego.object_name,
                  pi_source_name   => lego_source_rec.source_name
              );

              IF ( lv_previous_as_of_time IS NULL OR lv_previous_as_of_time + lv_allowable_latency_interval < lv_remote_db_as_of_time

              ) THEN
                  /* No recent enough refresh.  Insert a history row and create a scheduler job for the lego. */
                  lego_tools.start_scheduler_job_for_lego(
                      pi_object_name   => lego.object_name,
                      pi_source        => lego_source_rec.source_name,
                      pi_job_runtime   => lc_job_runtime,
                      pi_scn           => lv_remote_db_as_of_scn,
                      pi_unique_id     => lego.unique_id
                  );

              ELSE 
                  /* The lego has been refreshed recently enough - no need to start a new run. */
                  logger_pkg.info('Avoided refresh for '
                                    || lego.object_name
                                    || ' because it was refreshed less than '
                                    || TO_CHAR(allowable_latency_minutes)
                                    || ' minutes ago as of: '
                                    || TO_CHAR(lv_previous_as_of_time, 'YYYY-Mon-DD hh24:mi:ss')
                  );
              END IF;

          END LOOP;

          logger_pkg.unset_source(gc_logging_source);
      
      END LOOP;
    
   
    EXCEPTION
      WHEN OTHERS THEN
        logger_pkg.fatal(
            pi_transaction_result   => NULL,
            pi_error_code           => sqlcode,
            pi_message              => sqlerrm
        );

        logger_pkg.unset_source(gc_logging_source);
        RAISE;

    END start_refresh_run;
    
END lego_refresh_smartview;
/
