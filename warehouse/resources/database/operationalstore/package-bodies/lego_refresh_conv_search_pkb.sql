CREATE OR REPLACE PACKAGE BODY lego_refresh_conv_search 
AS
    /******************************************************************************
    NAME:       lego_refresh_conv_search
    PURPOSE:    Public-facing entrypoint to launch convergence search lego refreshes.

    REVISIONS:
    Jira       Date        Author           Description
    ---------  ----------  ---------------  ------------------------------------
    IQN-40224  09/17/2018  Paul Muller      Created this package using the 
                                            lego_convergence_search package as a template.
    IQN-41594  11/06/2018  Paul Muller      Changes in preparation for refreshes to be initiated
                                            and managed by mircoservice code.

    ******************************************************************************/

    gc_logging_source               CONSTANT  VARCHAR2(24) := 'LEGO_REFRESH_CONV_SEARCH';
    gc_main_environment_sourcename  CONSTANT  VARCHAR2(6)  := 'USPROD';

    ------------------------------------------------------------------------------------
    PROCEDURE start_refresh_run (
        allowable_latency_minutes IN  NUMBER DEFAULT 60,
        refresh_runtime_utc_out   OUT TIMESTAMP
    ) IS
        /* This will be used as the PK/FK value in refresh history tables. */
        lc_job_runtime     CONSTANT    lego_refresh_run_history.job_runtime%TYPE := sys_extract_utc(systimestamp);

        lv_remote_db_as_of_scn         lego_refresh_run_history.remote_db_as_of_scn%TYPE;
        lv_remote_db_as_of_time        lego_refresh_run_history.remote_db_as_of_time%TYPE;
        lv_previous_as_of_time         lego_refresh_run_history.remote_db_as_of_time%TYPE;
        lv_allowable_latency_interval  INTERVAL DAY TO SECOND;
        lv_job_name                    VARCHAR2(30);

    BEGIN
        lego_tools.setup_session_logging(pi_log_source => gc_logging_source);
        logger_pkg.set_code_location('convergence_search');
        IF NOT lego_tools.get_safe_to_start_refresh_flag THEN
            raise_application_error(-20001, 'Other legos are currently being refreshed. Cannot start more refreshes until previous run is complete.'
            );
        END IF;
        IF NOT (allowable_latency_minutes BETWEEN 0 AND 1440) THEN
            raise_application_error(-20002, 'Invalid input.  allowable_latency_minutes must be between 0 and 1440.'
            );
        END IF;
        logger_pkg.info('starting lego refreshes for convergence_search');

        /* Convert the input to an interval datatype for ease of computation inside the loop. */
        lv_allowable_latency_interval := allowable_latency_minutes * INTERVAL '1' MINUTE;

        /* First get remote DB as-of time and SCN to use in refresh.  */
        /* Oct 2018 - This is the only lego run where there are legos from more than one source.  As of now,
           we have no way of doing flashback queries in the horizon source so we don't even get the SCN there. */
        lego_tools.get_remote_db_as_of_info(
            pi_source_name => gc_main_environment_sourcename,
            po_as_of_scn   => lv_remote_db_as_of_scn,
            po_as_of_time  => lv_remote_db_as_of_time
        );

        /* now insert a row in the refresh history parent table for this run. */
        lego_tools.insert_history_parent_row(
            pi_refresh_runtime   => lc_job_runtime,
            pi_source_as_of_time => lv_remote_db_as_of_time,
            pi_source_as_of_scn  => lv_remote_db_as_of_scn,
            pi_caller_id         => 'Convergence Search',
            pi_latency_input     => allowable_latency_minutes
        );

        /* Make a list of all legos which need to be refreshed in order to refresh fully refresh the 
           convergence search data.  Then loop over that list, inserting a history row and starting 
           a job for each.  */
        FOR lego IN ( 
            WITH top_level_legos   --entries for the "top-level" legos
              AS ( SELECT object_name,
                          source_name
                     FROM lego_refresh
                    WHERE object_name = 'LEGO_CONVERGENCE_SEARCH'
                      AND source_name = gc_main_environment_sourcename
                 )
          SELECT object_name,
                 source_name,
                 ROWNUM AS unique_id
            FROM (SELECT relies_on_object_name AS object_name,
                         relies_on_source_name AS source_name,
                         MAX(tree_depth) AS depth
                    FROM ( SELECT lrd.object_name,
                                  lrd.relies_on_object_name,
                                  lrd.relies_on_source_name,
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
                                  source_name   AS relies_on_source_name,
                                  1             AS tree_depth
                             FROM top_level_legos 
                         )
                   GROUP BY relies_on_object_name, relies_on_source_name
                   ORDER BY depth DESC  --try to start low-level legos first
                 ) 
        ) LOOP

            /* For each lego to be started, first determine if its been already been refreshed recently enough.
               If so, we don't need to do it again. If not, insert a history row then create and start a job. */ 
            lv_previous_as_of_time := lego_tools.get_most_recent_ref_as_of_time (
                                          pi_object_name => lego.object_name, 
                                          pi_source_name => lego.source_name
                                      );

            IF (lv_previous_as_of_time IS NULL OR 
                lv_previous_as_of_time + lv_allowable_latency_interval < lv_remote_db_as_of_time
               ) 
            THEN 
                lego_tools.start_scheduler_job_for_lego (
                    pi_object_name => lego.object_name,
                    pi_source      => lego.source_name,
                    pi_job_runtime => lc_job_runtime,
                    pi_scn         => lv_remote_db_as_of_scn,  --unused in HORIZON source as of yet.
                    pi_unique_id   => lego.unique_id
                );
            ELSE 
                /* The lego has been refreshed recently enough - no need to start a new run.  Log message and go to next lego. */
                logger_pkg.info('Avoided refresh for ' 
                                 || lego.object_name 
                                 || ' source ' 
                                 || lego.source_name
                                 || ' because it was refreshed less than ' 
                                 || to_char(allowable_latency_minutes) 
                                 || ' minutes ago as of: ' 
                                 || to_char(lv_previous_as_of_time,'YYYY-Mon-DD hh24:mi:ss')
                );
            END IF;            
        
        END LOOP;

        refresh_runtime_utc_out := lc_job_runtime;
        logger_pkg.unset_source(gc_logging_source);

    EXCEPTION
        WHEN OTHERS THEN
            logger_pkg.fatal(pi_transaction_result => NULL, pi_error_code => sqlcode, pi_message => sqlerrm);

            logger_pkg.unset_source(gc_logging_source);
            RAISE;

    END start_refresh_run;

    ------------------------------------------------------------------------------------
    FUNCTION get_refresh_run_status (
        refresh_runtime_utc IN TIMESTAMP
    ) RETURN VARCHAR2 IS
        lv_result                       VARCHAR2(70);
        lv_refreshes_still_running      BOOLEAN;
        lv_refresh_encountered_errors   BOOLEAN;
    BEGIN
        /* This function needs to know two pieces of information:
              1. Is the refresh run started at the input time still running?
              2. Did any of the legos started at the input time end in error?
           With those two pieces of information, we can pass back one of four possible statuses. */

        BEGIN
            lv_refreshes_still_running := lego_tools.get_refresh_run_running(fi_run_timestamp   => refresh_runtime_utc);
            lv_refresh_encountered_errors := lego_tools.get_refresh_run_hit_error(fi_run_timestamp   => refresh_runtime_utc);

            CASE
                WHEN     lv_refreshes_still_running AND     lv_refresh_encountered_errors THEN
                    lv_result := 'Refresh failed but still running - may want to kill still running jobs';
                WHEN     lv_refreshes_still_running AND NOT lv_refresh_encountered_errors THEN
                    lv_result := 'Refresh still running - wait';
                WHEN NOT lv_refreshes_still_running AND     lv_refresh_encountered_errors THEN
                    lv_result := 'Refresh failed';
                WHEN NOT lv_refreshes_still_running AND NOT lv_refresh_encountered_errors THEN
                    lv_result := 'Refresh succeeded';
            END CASE;

        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -20001 
                    THEN lv_result := 'Invalid input';   --from get_refresh_run_hit_error call
                    ELSE RAISE;
                END IF;    
        END;    

        RETURN lv_result;

    END get_refresh_run_status;

END lego_refresh_conv_search;
/
