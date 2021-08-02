CREATE OR REPLACE PACKAGE BODY lego_refresh_dashboards AS

    gc_logging_source                CONSTANT VARCHAR2(27) := 'LEGO_REFRESH_DASHBOARDS';
    gc_main_environment_sourcename   CONSTANT VARCHAR2(6) := 'USPROD';

    ------------------------------------------------------------------------------------
    PROCEDURE start_refresh_run (
        allowable_latency_minutes IN NUMBER DEFAULT 60
    ) IS
        /* This will be used as the PK/FK value in refresh history tables. */
        lc_job_runtime      CONSTANT    lego_refresh_run_history.job_runtime%TYPE := sys_extract_utc(systimestamp);

        lv_remote_db_as_of_scn          lego_refresh_run_history.remote_db_as_of_scn%TYPE;
        lv_remote_db_as_of_time         lego_refresh_run_history.remote_db_as_of_time%TYPE;
        lv_previous_as_of_time          lego_refresh_run_history.remote_db_as_of_time%TYPE;
        lv_allowable_latency_interval   INTERVAL DAY TO SECOND;
        lv_job_name                     VARCHAR2(30);
    BEGIN
        lego_tools.setup_session_logging(pi_log_source   => gc_logging_source);
        logger_pkg.set_code_location('dashboards');
        IF NOT lego_tools.get_safe_to_start_refresh_flag THEN
            raise_application_error(
                -20001,
                'Other legos are currently being refreshed. Cannot start more refreshes until previous run is complete.'
            );
        END IF;
        IF NOT ( allowable_latency_minutes BETWEEN 0 AND 1440 ) THEN
            raise_application_error(
                -20002,
                'Invalid input.  Allowable_latency_minutes must be between 0 and 1440.'
            );
        END IF;

        logger_pkg.info('starting lego refreshes for dashboards');
        
        /* Convert the input to an interval datatype for ease of computation inside the loop. */
        lv_allowable_latency_interval := allowable_latency_minutes * INTERVAL '1' MINUTE;

        /* First get remote DB as-of time and SCN to use in refresh.  */
        lego_tools.get_remote_db_as_of_info(
            pi_source_name   => gc_main_environment_sourcename,
            po_as_of_scn     => lv_remote_db_as_of_scn,
            po_as_of_time    => lv_remote_db_as_of_time
        );

        /* now insert a row in the refresh history parent table for this run. */
        lego_tools.insert_history_parent_row(
            pi_refresh_runtime     => lc_job_runtime,
            pi_source_as_of_time   => lv_remote_db_as_of_time,
            pi_source_as_of_scn    => lv_remote_db_as_of_scn,
            pi_caller_id           => 'Dashboards',
            pi_latency_input       => allowable_latency_minutes
        );

        /* Make a list of all legos which need to be refreshed in order to refresh fully refresh 
           the dashboard data.  Then loop over that list, inserting a history row and starting 
           a job for each.  */
        /* This loop query uses the LEVEL function to try to order the loop such that low-level legos are started
           first in hopes of avoiding a situation where the governor creates a "deadlock" where the running legos
           are waiting for "scheduled" legos.  This is more and more likely when the governor is small and the number
           of legos to refresh is large. */   
        FOR lego IN (
            WITH top_level_legos   --entries for the "top-level" lego(s)
              AS ( SELECT object_name,
                          source_name
                     FROM lego_refresh
                    WHERE object_name IN 
                          ('LEGO_ASSGN_LOC_CMSA_ATOM_OR','LEGO_ASSGN_LOC_CMSA_ATOM_RR','LEGO_ASSGN_LOC_ST_ATOM_OR',
                           'LEGO_ASSGN_LOC_ST_ATOM_RR','LEGO_MNTH_ASGN_CNTSPND_ORGROLL','LEGO_MNTH_ASGN_CNTSPND_ROWROLL',
                           'LEGO_REQ_BY_STATUS_ORG_ROLLUP','LEGO_REQ_BY_STATUS_ROW_ROLLUP','LEGO_UPCOMING_ENDS_ORG_ROLLUP',
                           'LEGO_UPCOMING_ENDS_ROW_ROLLUP')
                      AND source_name = gc_main_environment_sourcename
                 )
          SELECT object_name, rownum AS unique_id
            FROM ( SELECT relies_on_object_name AS object_name,
                          MAX(tree_depth)       AS depth
                     FROM ( SELECT lrd.object_name,
                                   lrd.relies_on_object_name,
                                   LEVEL + 1 AS tree_depth
                              FROM lego_refresh_dependency lrd 
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
                pi_source_name   => gc_main_environment_sourcename
            );

            IF ( lv_previous_as_of_time IS NULL OR lv_previous_as_of_time + lv_allowable_latency_interval < lv_remote_db_as_of_time

            ) THEN
                /* No recent enough refresh.  Insert a history row and create a scheduler job for the lego. */
                lego_tools.start_scheduler_job_for_lego(
                    pi_object_name   => lego.object_name,
                    pi_source        => gc_main_environment_sourcename,
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

END lego_refresh_dashboards;
/
