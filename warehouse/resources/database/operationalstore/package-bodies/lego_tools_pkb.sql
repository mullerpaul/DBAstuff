CREATE OR REPLACE PACKAGE BODY lego_tools AS
/******************************************************************************
   NAME:       lego_tools
   PURPOSE:    public functions and procedures which can be used by refresh code

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
              01/11/2016  Paul Muller      Created this package.
   IQN-33702  10/12/2016  Joe Pullifrone   Added proc, refresh_mv.   
   IQN-40224  09/17/2018  Paul Muller      refactored many units into this package.
   IQN-41594  11/06/2018  Paul Muller      new boolean functions get_refresh_run_running and get_refresh_run_hit_error.
   
******************************************************************************/

  gc_curr_schema             CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');
  gc_source                  CONSTANT VARCHAR2(30) := 'lego_tools';
  gc_refresh_job_name_prefix CONSTANT  VARCHAR2(8) := 'LEGO_REF';

  --------------------------------------------------------------------------------
  FUNCTION get_lego_parameter_text_value(pi_parameter_name IN VARCHAR2) 
  RETURN VARCHAR2 IS
    lv_result  lego_parameter.text_value%TYPE;
  BEGIN
    
    SELECT text_value
      INTO lv_result
      FROM lego_parameter
     WHERE parameter_name = lower(pi_parameter_name);

    RETURN lv_result;
    
  EXCEPTION
    WHEN no_data_found
      THEN RETURN NULL;
      
  END get_lego_parameter_text_value;
  
  --------------------------------------------------------------------------------
  FUNCTION get_lego_parameter_num_value(pi_parameter_name IN VARCHAR2) 
  RETURN NUMBER IS 
    lv_result  lego_parameter.number_value%TYPE;
  BEGIN
    
    SELECT number_value
      INTO lv_result
      FROM lego_parameter
     WHERE parameter_name = lower(pi_parameter_name);

    RETURN lv_result;
    
  EXCEPTION
    WHEN no_data_found
      THEN RETURN NULL;
      
  END get_lego_parameter_num_value;

  --------------------------------------------------------------------------------
  PROCEDURE setup_session_logging(
      pi_log_source IN VARCHAR
  )
  IS
  BEGIN
      /* Call this to set up the logger package in your session.  
         It should only be called once per session!  */
      /* Instantiate the logger, set the source, and set the logging level to the parameter. */
      logger_pkg.instantiate_logger;
      logger_pkg.set_level(
          get_lego_parameter_text_value('logging_level')
      );
      logger_pkg.set_source(pi_log_source);
  
  END setup_session_logging;

  --------------------------------------------------------------------------------
  FUNCTION get_db_link_status(fi_link_name IN VARCHAR2) RETURN VARCHAR2 IS
    lv_sql   VARCHAR2(50);
    lv_dummy VARCHAR2(1);
  
  BEGIN
    lv_sql := 'select dummy from dual@' || fi_link_name;
    EXECUTE IMMEDIATE lv_sql
      INTO lv_dummy;
  
    RETURN 'working';
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'not working';
    
  END get_db_link_status;

  --------------------------------------------------------------------------------
  FUNCTION get_db_link_name(fi_source_name IN lego_source.source_name%TYPE) RETURN VARCHAR2 IS
    lv_db_link_name lego_source.db_link_name%TYPE;
  
  BEGIN
  
    SELECT db_link_name 
      INTO lv_db_link_name 
      FROM lego_source 
     WHERE source_name = fi_source_name;
  
    RETURN lv_db_link_name;
  
  EXCEPTION
    WHEN no_data_found THEN
      logger_pkg.fatal(pi_error_code         => SQLCODE,
                       pi_message            => 'Could not find dblink name for ' || fi_source_name,
                       pi_transaction_result => NULL);
      RAISE;
    
  END get_db_link_name;

  --------------------------------------------------------------------------------
  FUNCTION get_src_name_short(fi_source_name IN lego_source.source_name%TYPE) RETURN VARCHAR2 IS
    lv_src_name_short lego_source.source_name_short%TYPE;
  
  BEGIN
  
    SELECT source_name_short 
      INTO lv_src_name_short 
      FROM lego_source 
     WHERE source_name = fi_source_name;
  
    RETURN lv_src_name_short;
  
  EXCEPTION
    WHEN no_data_found THEN
      logger_pkg.fatal(pi_error_code         => SQLCODE,
                       pi_message            => 'Could not find source name short for ' || fi_source_name,
                       pi_transaction_result => NULL);
      RAISE;
    
  END get_src_name_short;  
    
  --------------------------------------------------------------------------------
  PROCEDURE get_remote_db_as_of_info (
      pi_source_name IN  lego_source.source_name%TYPE,
      po_as_of_scn   OUT lego_refresh_run_history.remote_db_as_of_scn%TYPE,
      po_as_of_time  OUT lego_refresh_run_history.remote_db_as_of_time%TYPE
  ) IS
      lv_current_time TIMESTAMP;
      lv_current_scn  NUMBER;
  BEGIN
      EXECUTE IMMEDIATE ('SELECT systimestamp, timestamp_to_scn(systimestamp) FROM dual@' 
                           || get_db_link_name(pi_source_name))
         INTO lv_current_time, lv_current_scn;

      po_as_of_time := lv_current_time;
      po_as_of_scn := lv_current_scn;

  END get_remote_db_as_of_info;    

  --------------------------------------------------------------------------------
  FUNCTION get_storage_clause(fi_object_name IN lego_refresh.object_name%TYPE,
                              fi_source_name IN lego_refresh.source_name%TYPE) RETURN VARCHAR2 IS
    lv_result lego_refresh.storage_clause%TYPE;
  
  BEGIN
  
    SELECT storage_clause
      INTO lv_result
      FROM lego_refresh
     WHERE object_name = fi_object_name
       AND source_name = fi_source_name;
  
    RETURN lv_result;
  
  EXCEPTION
    WHEN no_data_found THEN
      logger_pkg.fatal(pi_error_code         => SQLCODE,
                       pi_message            => 'Could not find storage clause for ' || fi_object_name || ' source ' ||
                                                fi_source_name,
                       pi_transaction_result => NULL);
      RAISE;
    
  END get_storage_clause;

  --------------------------------------------------------------------------------
  FUNCTION get_partition_clause(fi_object_name IN lego_refresh.object_name%TYPE,
                                fi_source_name IN lego_refresh.source_name%TYPE) RETURN VARCHAR2 IS
    lv_result lego_refresh.partition_clause%TYPE;
  
  BEGIN
  
    SELECT partition_clause
      INTO lv_result
      FROM lego_refresh
     WHERE object_name = fi_object_name
       AND source_name = fi_source_name;
  
    RETURN lv_result;
  
  EXCEPTION
    WHEN no_data_found THEN
      /* We may decide later to change this to "log a warning and return NULL"
         instead of "crash and burn". */
      logger_pkg.fatal(pi_error_code         => SQLCODE,
                       pi_message            => 'Could not find partition clause for ' || fi_object_name || ' source ' ||
                                                fi_source_name,
                       pi_transaction_result => NULL);
      RAISE;
    
  END get_partition_clause;

  --------------------------------------------------------------------------------
  FUNCTION get_synonym_name(fi_object_name IN lego_refresh.object_name%TYPE,
                            fi_source_name IN lego_refresh.source_name%TYPE) RETURN VARCHAR2 IS
    lv_result lego_refresh.synonym_name%TYPE;
  
  BEGIN
  
    SELECT synonym_name
      INTO lv_result
      FROM lego_refresh
     WHERE object_name = fi_object_name
       AND source_name = fi_source_name;
  
    RETURN lv_result;
  
  EXCEPTION
    WHEN no_data_found THEN
      /* We may decide later to change this to "log a warning and return NULL"
         instead of "crash and burn". */
      logger_pkg.fatal(pi_error_code         => SQLCODE,
                       pi_message            => 'Could not find synonym name for ' || fi_object_name || ' source ' ||
                                                fi_source_name,
                       pi_transaction_result => NULL);
      RAISE;
    
  END get_synonym_name;

  --------------------------------------------------------------------------------
  PROCEDURE repoint_db_link(pi_link_name    IN VARCHAR2,
                            pi_schemaname   IN VARCHAR2,
                            pi_password     IN VARCHAR2,
                            pi_database_sid IN VARCHAR2) IS
  
    le_no_such_db_link EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_no_such_db_link, -2024);
  
    lv_sql VARCHAR2(128);
  
  BEGIN
    /* Do we need to initialize the logger here???  
    Also, add security checking so users can't create bunches of db links and mess up the DB via too many 
    objects or by changing name resolution! */
  
    /* There is no "create or replace" DB link syntax, so we must first drop the DB link if it exists. */
    BEGIN
      EXECUTE IMMEDIATE ('DROP DATABASE LINK ' || pi_link_name);
    EXCEPTION
      WHEN le_no_such_db_link THEN
        NULL;
    END;
  
    /* Now create our DDL string and execute it. */
    lv_sql := 'CREATE DATABASE LINK ' || pi_link_name || 
              ' CONNECT TO ' || pi_schemaname || 
              ' IDENTIFIED BY ' || pi_password || 
              ' USING ''' || pi_database_sid || '''';
  
    BEGIN
      logger_pkg.info('About to create database link using the following DDL: ' || lv_sql);
      EXECUTE IMMEDIATE lv_sql;
      logger_pkg.info('Created database link using the following DDL: ' || lv_sql, TRUE);
      logger_pkg.info('Current link status is: ' || get_db_link_status(fi_link_name => pi_link_name));
    
    EXCEPTION
      WHEN OTHERS THEN
        logger_pkg.fatal(pi_error_code         => SQLCODE,
                         pi_message            => 'Could not create and test DB link ' || SQLERRM,
                         pi_transaction_result => NULL);
        RAISE;
    END;
  
  END repoint_db_link;
  
  --------------------------------------------------------------------------------
  FUNCTION get_safe_to_start_refresh_flag RETURN BOOLEAN IS
      lv_temp   NUMBER;
  BEGIN
      /* Returns TRUE if there are no refresh jobs running.
         If this query returns anything other than 0, some legos are running.  */
      SELECT COUNT(*)
        INTO lv_temp
        FROM user_scheduler_jobs
       WHERE job_name LIKE gc_refresh_job_name_prefix || '%' ;

      RETURN (lv_temp = 0);

  END get_safe_to_start_refresh_flag;
    
  --------------------------------------------------------------------------------
  FUNCTION get_refresh_run_running(fi_run_timestamp IN lego_refresh_run_history.job_runtime%TYPE)
  RETURN BOOLEAN 
  IS
    lv_max_run_time  lego_refresh_run_history.job_runtime%TYPE;
    lv_jobs_running  BOOLEAN;
  BEGIN
    /* We will assume that if the passed in time is the MAX in the table AND if
       there are jobs running, then it is still running.  If either of those is 
       false, then it is not still running.   
       This methodology will be incorrect if we ever allow more than one concurrent run! */

    /* Validate valid input. */
    IF fi_run_timestamp IS NULL
    THEN
        raise_application_error(-20002, 'lego_tools.get_refresh_run_running cannot accept NULL input');
    END IF;

    /* We need to flip this function output to get what we want */
    lv_jobs_running := NOT get_safe_to_start_refresh_flag;

    SELECT MAX(lrrh.job_runtime)
      INTO lv_max_run_time
      FROM lego_refresh_run_history lrrh;
      
    RETURN (lv_jobs_running AND (fi_run_timestamp = lv_max_run_time));

  END get_refresh_run_running;
  
  --------------------------------------------------------------------------------
  FUNCTION get_refresh_run_hit_error (
    fi_run_timestamp   IN lego_refresh_run_history.job_runtime%TYPE
  ) RETURN BOOLEAN IS
    lv_result           BOOLEAN := FALSE;
    lv_legos_started    NUMBER;
    lv_legos_released   NUMBER;
    lv_legos_errored    NUMBER;
  BEGIN
    /* Return true if any lego in the run errored out.
       Raise an error if the input finds no legos.  A NO_DATA_FOUND 
       error is NOT raised in that case because our query only has 
       aggregate functions (COUNT) in the select list, so we have to 
       raise it "manually".  */
    SELECT COUNT(*),
           COUNT(CASE WHEN lrh.status = 'released' THEN 'x' END),
           COUNT(CASE WHEN lrh.status IN ('error', 'error in prerequisite', 'timeout', 'stopped') THEN 'x' END)
      INTO lv_legos_started, 
           lv_legos_released, 
           lv_legos_errored
      FROM lego_refresh_history lrh
     WHERE lrh.job_runtime = fi_run_timestamp;

    CASE
      WHEN lv_legos_started = 0 THEN 
        /* Invalid input. */
        raise_application_error(-20001,'Invalid Input - no rows found');
      WHEN lv_legos_started = lv_legos_released THEN 
        /* all legos released.  "hit error" is false. */
        lv_result := FALSE;
      WHEN lv_legos_errored > 0 THEN
        /* error encountered */
        lv_result := TRUE;
      ELSE
        /* Legos still running. They are probably in 'scheduled' or 'started refresh'.
           However, its also possible that the rows in in LEGO_REFRESH_HISTORY are "dead"
           and no longer have a job running; but that is outside the scope of this function.
           We'll assume its the former not the latter, and there is no error. */
        lv_result := FALSE;
    END CASE;

    RETURN lv_result;

  END get_refresh_run_hit_error;  

  --------------------------------------------------------------------------------
  FUNCTION get_most_recent_ref_as_of_time (
      pi_object_name IN lego_refresh.object_name%TYPE, 
      pi_source_name IN lego_refresh.source_name%TYPE
  )
  RETURN TIMESTAMP
  IS 
      lv_result lego_refresh_run_history.remote_db_as_of_time%TYPE;
  BEGIN
      /* Look back at most two days and find the as-of time of the most recent 
         successful refresh.  If there were no successful refreshes in those 
         two days, return NULL.  */
      SELECT MAX(p.remote_db_as_of_time)
        INTO lv_result
        FROM lego_refresh_run_history p,
             lego_refresh_history c
       WHERE p.job_runtime = c.job_runtime
         AND p.job_runtime >= systimestamp - INTERVAL '2' DAY
         AND c.object_name = pi_object_name
         AND c.source_name = pi_source_name
         AND c.status = 'released';

      RETURN lv_result;

  END get_most_recent_ref_as_of_time;  

  --------------------------------------------------------------------------------
  PROCEDURE insert_history_parent_row (
      pi_refresh_runtime   IN lego_refresh_run_history.job_runtime%TYPE,
      pi_source_as_of_time IN lego_refresh_run_history.remote_db_as_of_time%TYPE,
      pi_source_as_of_scn  IN lego_refresh_run_history.remote_db_as_of_scn%TYPE,
      pi_caller_id         IN lego_refresh_run_history.caller_name%TYPE,
      pi_latency_input     IN lego_refresh_run_history.allowable_per_lego_latency_min%TYPE
  ) IS
  BEGIN
      INSERT INTO lego_refresh_run_history
        (job_runtime, remote_db_as_of_time, remote_db_as_of_scn, caller_name, allowable_per_lego_latency_min)
      VALUES
        (pi_refresh_runtime, pi_source_as_of_time, pi_source_as_of_scn, pi_caller_id, pi_latency_input);

      COMMIT;  --not sure about the transaction semantics yet.  Review later.

  END insert_history_parent_row;
  
  ------------------------------------------------------------------------------------
  PROCEDURE start_scheduler_job_for_lego (
      pi_object_name   IN VARCHAR2,
      pi_source        IN VARCHAR2,
      pi_job_runtime   IN TIMESTAMP,
      pi_scn           IN NUMBER,
      pi_unique_id     IN NUMBER
  ) IS
      lv_job_name VARCHAR2(30);
  BEGIN
      /* Start a scheduler job for the lego.  Also insert a 
         row into LEGO_REFRESH_HISTORY with status = 'scheduled'.
         First, create a job name.  */
      lv_job_name := gc_refresh_job_name_prefix
                      || '_' 
                      || substr(pi_source,1,2)
                      || '_'
                      || substr(pi_object_name, 6, 14)
                      || '_'
                      || TO_CHAR(pi_unique_id);  

      logger_pkg.debug(
          'Starting dbms_scheduler job: '
           || lv_job_name
           || ' for object: '
           || pi_object_name
           || ' source: '
           || pi_source
           || ' with runtime: '
           || TO_CHAR(pi_job_runtime, 'YYYY-Mon-DD hh24:mi:ss')
           || ' and remote SCN: '
           || TO_CHAR(pi_scn) );

      dbms_scheduler.create_job(
          job_name        => lv_job_name, 
          program_name    => 'LEGO_REFRESH_OBJECT_PROGRAM', -- This "program" knows to call lego_refresh_mgr_pkg.refresh_object with correct params.
          start_date      => SYSDATE, -- start now
          repeat_interval => NULL, -- only run once
          enabled         => false  -- we will enable it later
      );

      dbms_scheduler.set_job_argument_value(
          job_name => lv_job_name,
          argument_name => 'REFRESH_OBJECT_NAME',
          argument_value => pi_object_name
      );

      dbms_scheduler.set_job_argument_value(
          job_name => lv_job_name, 
          argument_name => 'SOURCE', 
          argument_value => pi_source
      );

      dbms_scheduler.set_job_argument_value(
          job_name => lv_job_name, 
          argument_name => 'RUNTIME', 
          argument_value => pi_job_runtime
      );

      dbms_scheduler.set_job_argument_value(
          job_name => lv_job_name, 
          argument_name => 'SCN', 
          argument_value => pi_scn
      );

      logger_pkg.debug(
          'Inserting row into LEGO_REFRESH_HISTORY for object: '
            || pi_object_name
            || ' source: '
            || pi_source
            || ' for the: '
            || TO_CHAR(pi_job_runtime, 'YYYY-Mon-DD hh24:mi:ss') 
            || ' run.  Remote DB as-of SCN: '
            || TO_CHAR(pi_scn)
      );

      INSERT INTO lego_refresh_history (
          object_name,
          job_runtime,
          source_name,
          status
      ) VALUES (
          pi_object_name,
          pi_job_runtime,
          pi_source,
          'scheduled'
      );

      COMMIT;
      dbms_scheduler.enable(
          name => lv_job_name
      );

  END start_scheduler_job_for_lego;

  --------------------------------------------------------------------------------
  PROCEDURE drop_running_job(pi_object_name IN lego_refresh.object_name%TYPE,
                             pi_source_name IN lego_refresh.source_name%TYPE) IS
    v_source              VARCHAR2(61) := 'lego_tools.drop_running_job';
    lv_scheduler_job_name VARCHAR2(30);
  BEGIN
    /* This is provided for operational concerns.  Its called manually from 
      SQL*Plus or someone's laptop.  So we need to ensure that logging is set up. */
    logger_pkg.instantiate_logger;
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('drop_running_job');
    logger_pkg.debug('Entering drop_running_job proc with inputs ' || pi_object_name || ' and ' || pi_source_name);
  
    /* Look at running jobs to find the name of the scheduler job for that object & source. */
    BEGIN
      SELECT rj.job_name
        INTO lv_scheduler_job_name
        FROM user_scheduler_running_jobs rj, 
             user_scheduler_job_args ja1, 
             user_scheduler_job_args ja2
       WHERE rj.job_name = ja1.job_name
         AND ja1.argument_name = 'REFRESH_OBJECT_NAME'
         AND ja1.value = upper(pi_object_name)
         AND rj.job_name = ja2.job_name
         AND ja2.argument_name = 'SOURCE'
         AND ja2.value = upper(pi_source_name);
    
    EXCEPTION
      WHEN no_data_found THEN
        logger_pkg.unset_source(v_source);
        raise_application_error(-20012, 'Could not find a scheduler job running for that object.');
    END;
  
    dbms_scheduler.drop_job(job_name => lv_scheduler_job_name, force => TRUE);
    logger_pkg.info('Killed job ' || lv_scheduler_job_name || ' for object ' || pi_object_name);
    logger_pkg.unset_source(v_source);
  
  END drop_running_job;

  --------------------------------------------------------------------------------
  PROCEDURE drop_running_job(pi_scheduler_job_name IN VARCHAR2) IS
    v_source              VARCHAR2(61) := 'lego_tools.drop_running_job';
    lv_scheduler_job_name VARCHAR2(30);
  BEGIN
    /* This is provided for operational concerns.  Its called manually from 
       SQL*Plus or someone's laptop.  So we need to ensure that logging is set up. */
    logger_pkg.instantiate_logger;
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('drop_running_job');
    logger_pkg.debug('Entering drop_running_job proc with input ' || pi_scheduler_job_name);
  
    /* Look at user_scheduler_jobs to confirm the job is there. */
    BEGIN
      SELECT job_name
        INTO lv_scheduler_job_name
        FROM user_scheduler_jobs
       WHERE job_name = UPPER(pi_scheduler_job_name)
         AND job_name <> 'LEGO_REFRESH_KICKOFF';  -- dont drop the kickoff job!
    
    EXCEPTION
      WHEN no_data_found THEN
        logger_pkg.unset_source(v_source);
        raise_application_error(-20012, 'Could not find that job');
    END;
  
    dbms_scheduler.drop_job(job_name => lv_scheduler_job_name, force => TRUE);
    logger_pkg.info('Killed job ' || lv_scheduler_job_name);
    logger_pkg.unset_source(v_source);
  
  END drop_running_job;

  --------------------------------------------------------------------------------
  PROCEDURE enable_parallel_dml_in_session
    IS
  BEGIN
    NULL;  -- To Do:  get this working!!
  END enable_parallel_dml_in_session;    
   
  --------------------------------------------------------------------------------
  PROCEDURE enable_automatic_refresh_job (
      pi_ssc           IN BOOLEAN DEFAULT false,
      pi_conv_search   IN BOOLEAN DEFAULT false,
      pi_dash          IN BOOLEAN DEFAULT false,
      pi_smartview     IN BOOLEAN DEFAULT false,
      pi_invoice       IN BOOLEAN DEFAULT false
  ) IS
  BEGIN
      IF pi_ssc THEN
          dbms_scheduler.enable(NAME => 'TEMP_REFRESH_SSC_LEGOS');
      END IF;
      IF pi_conv_search THEN
          dbms_scheduler.enable(NAME => 'TEMP_REFRESH_CONV_SEARCH_LEGOS');
      END IF;
      IF pi_dash THEN
          dbms_scheduler.enable(NAME => 'TEMP_REFRESH_DASH_LEGOS');
      END IF;
      IF pi_smartview THEN
          dbms_scheduler.enable(NAME => 'TEMP_REFRESH_SSC_SMARTVW_LEGOS');
      END IF;
      IF pi_invoice THEN
          dbms_scheduler.enable(NAME => 'TEMP_REFRESH_INVOICE_LEGOS');
      END IF;


  END enable_automatic_refresh_job;    
  
  --------------------------------------------------------------------------------
  PROCEDURE disable_automatic_refresh_job (
      pi_ssc           IN BOOLEAN DEFAULT false,
      pi_conv_search   IN BOOLEAN DEFAULT false,
      pi_dash          IN BOOLEAN DEFAULT false,
      pi_smartview     IN BOOLEAN DEFAULT false,
      pi_invoice       IN BOOLEAN DEFAULT false
  ) IS
  BEGIN
      IF pi_ssc THEN
          dbms_scheduler.disable(name => 'TEMP_REFRESH_SSC_LEGOS');
      END IF;
      IF pi_conv_search THEN
          dbms_scheduler.disable(name => 'TEMP_REFRESH_CONV_SEARCH_LEGOS');
      END IF;
      IF pi_dash THEN
          dbms_scheduler.disable(name => 'TEMP_REFRESH_DASH_LEGOS');
      END IF;
      IF pi_smartview THEN
          dbms_scheduler.disable(name => 'TEMP_REFRESH_SSC_SMARTVW_LEGOS');
      END IF;
      IF pi_invoice THEN
          dbms_scheduler.disable(NAME => 'TEMP_REFRESH_INVOICE_LEGOS');
      END IF;

  END disable_automatic_refresh_job;
  
  --------------------------------------------------------------------------------
  FUNCTION most_recently_loaded_table(i_lego_name lego_refresh.object_name%TYPE,
                                      i_source_name lego_refresh.source_name%TYPE)
    /* Function which returns the name of the most recently built base table for toggle 
     legos.  Use this in a refresh procedure to find the name of a table built for a lego 
     in the same refresh group but with a lower refresh_dependency_order.  */
    RETURN VARCHAR2 IS
    lv_return              VARCHAR2(30) := NULL;
    lv_older_base_table    VARCHAR2(30);

    le_invalid_object_name EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_invalid_object_name, -44002);
  BEGIN
    /* For SQL toggle, PROC toggle, and PROC toggle args legos, we can get the name of the 
    most recently loaded base table from lego_refresh_history.toggle_refreshed_table. */ 
    SELECT toggle_refreshed_table
      INTO lv_return
      FROM (SELECT job_runtime,
                   toggle_refreshed_table,
                   MAX(job_runtime) over() AS max_runtime
              FROM lego_refresh_history
             WHERE object_name = i_lego_name
               AND source_name = i_source_name
               AND toggle_refreshed_table IS NOT NULL
               AND status IN ('released','refresh complete'))
     WHERE job_runtime = max_runtime;
  
    RETURN dbms_assert.sql_object_name(lv_return);
  
    EXCEPTION
      WHEN no_data_found
        THEN
          /*  Probably an incorrect input.  But this can also happen if we are checking  
          for a lego that is not a parent to this lego which hasn't run yet, or we are looking a
          for a lego which has not refreshed yet but has empty dummy tables.  To get an answer 
          in those cases, we look at the synonym and see if it points to a real table.  */
          BEGIN
            logger_pkg.warn('most recently loaded table not found for ' || i_lego_name || 
                            ' source ' || i_source_name || ' trying alternate method.');
            SELECT t.table_name
              INTO lv_return
              FROM lego_refresh lr,
                   user_synonyms s,
                   user_tables t
             WHERE lr.synonym_name = s.synonym_name
               AND s.table_name    = t.table_name
               AND lr.object_name = i_lego_name
               AND lr.source_name = i_source_name;

            RETURN lv_return;  

          EXCEPTION
            WHEN no_data_found
              THEN
                /* Now we are in trouble and must fail.  */
                logger_pkg.fatal('Cannot find most recently refreshed table for ' || 
                                 i_lego_name || ' source ' || i_source_name);
                raise_application_error(-20100, 'Cannot find most recently refreshed table for ' || 
                                        i_lego_name || ' source ' || i_source_name); 
          END;          

      WHEN le_invalid_object_name
        THEN
        /* The table to be returned does not actually exist! We've seen this happen in the 
           following (extremely particular) circumstance: 
             A lego in a allow_partial_release group refreshes but does not release.
             Then, the lego is restarted, dropping and recreating the toggle base table.
             While our lego is being refreshed, a lego in a different group which depends on our 
             lego calls this function.  This function returns the name of the table built in the 
             previous refresh; but that doesn't exist because its being re-built now.
           To fix this, I've added a call to dbms_assert and this exception block.  This will 
           return the other base table name. */
          BEGIN
            logger_pkg.warn('most recently refreshed table for ' || i_lego_name ||
                            ' source ' || i_source_name || ' is ' || lv_return || 
                            ' but that table does not exist!');

            SELECT base_table_name
              INTO lv_older_base_table
              FROM (SELECT refresh_object_name_1 AS base_table_name
                      FROM lego_refresh
                     WHERE object_name = i_lego_name
                       AND source_name = i_source_name
                     UNION ALL
                    SELECT refresh_object_name_2 AS base_table_name
                      FROM lego_refresh
                     WHERE object_name = i_lego_name
                       AND source_name = i_source_name)
             WHERE base_table_name <> lv_return;

            RETURN lv_older_base_table;

          EXCEPTION
            WHEN no_data_found
              THEN
                /* Now we are really in trouble and must fail.  */
                logger_pkg.fatal('Cannot find most recently refreshed table for ' || 
                                 i_lego_name || ' source ' || i_source_name);
                raise_application_error(-20101, 'Cannot find most recently refreshed table for ' || 
                                        i_lego_name || ' source ' || i_source_name); 
          END;    

  END most_recently_loaded_table;                            
                             
  --------------------------------------------------------------------------------
  FUNCTION create_temp_clob RETURN CLOB IS
    lv_return_clob CLOB;
  BEGIN
    dbms_lob.createtemporary(lv_return_clob, TRUE, dbms_lob.session);
    dbms_lob.open(lv_return_clob, dbms_lob.lob_readwrite);
  
    RETURN lv_return_clob;
  END create_temp_clob;

  --------------------------------------------------------------------------------
  PROCEDURE close_temp_clob(pio_temp_clob IN OUT NOCOPY CLOB) IS
  
  BEGIN
    IF pio_temp_clob IS NOT NULL AND dbms_lob.isopen(pio_temp_clob) = 1
    THEN
      dbms_lob.close(pio_temp_clob);
      dbms_lob.freetemporary(pio_temp_clob);
    END IF;
  
  END close_temp_clob;
  
  --------------------------------------------------------------------------------
  PROCEDURE ctas(pi_table_name         IN VARCHAR2,
                 pi_stmt_clob          IN CLOB,
                 pi_storage_clause     IN VARCHAR2 DEFAULT NULL, -- storage, compression, and tablespace
                 pi_compression_clause IN VARCHAR2 DEFAULT NULL, -- all be specified separately!
                 pi_tablespace_clause  IN VARCHAR2 DEFAULT NULL, -- but this may be a pipe dream.
                 pi_partition_clause   IN VARCHAR2 DEFAULT NULL,
                 pi_iot_flag           IN BOOLEAN DEFAULT FALSE,
                 pi_clobber_flag       IN BOOLEAN DEFAULT TRUE,
                 pi_gather_stats_flag  IN BOOLEAN DEFAULT TRUE,
                 po_row_count          OUT NUMBER) IS
    /* A new version of CTAS. Not used yet, but someday... 
      The main new features are:
         row count out variable
         separate inputs for tablespace, compression, IOT stuff
         a clobber flag
         perhaps a execution plan output?? */
  
    le_non_exadata EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_non_exadata, -64307);
    le_invalid_storage_option EXCEPTION;
    PRAGMA EXCEPTION_INIT(le_non_exadata, -02143);
  
    lv_sql       VARCHAR2(32767);
    lv_stmt_clob CLOB;
    lv_rowcount  NUMBER;
  
  BEGIN
    /* This procedure can be called from many different places, so there are a few ground rules...
    We will assume that logging has been initialized before this is called.  Also note this proc
    does NOT modify the logger_pkg SOURCE or CODE_LOCATION settings.  Please set those appropriately 
    in the calling code!
    
    The previous version of this procedure retried the CTAS without a storage clause if it failed 
    with a storage clause error.  This version will NOT retry.  Instead, it will just fail and pass 
    back the exception. */
  
    /* Validate our inputs. */
    IF (pi_table_name IS NULL OR pi_stmt_clob IS NULL OR pi_iot_flag IS NULL OR pi_clobber_flag IS NULL OR
       pi_gather_stats_flag IS NULL)
    THEN
      logger_pkg.error(pi_error_code         => -20001,
                       pi_message            => 'Invalid inputs to CTAS procedure',
                       pi_transaction_result => NULL);
      raise_application_error(-20001, 'Invalid inputs to CTAS procedure');
    
    END IF;
  
    lv_stmt_clob := create_temp_clob;
    IF pi_iot_flag
    THEN
      /*
      TODO: owner="pmuller" category="Finish" priority="2 - Medium" created="9/25/2015"
      text="Allow for the creation of IOTs"
      */
      raise_application_error(-20001, 'IOTs not supported yet!!!');
    ELSE
      /* Not an IOT */
      lv_sql := 'CREATE TABLE ' || pi_table_name || ' ' || pi_storage_clause || ' ' || pi_tablespace_clause || ' ' ||
                pi_partition_clause || ' AS ';
    END IF;
  
    dbms_lob.writeappend(lv_stmt_clob, length(lv_sql), lv_sql);
    lv_stmt_clob := lv_stmt_clob || pi_stmt_clob;
  
    logger_pkg.debug(lv_stmt_clob);
  
    IF pi_clobber_flag
    THEN
      /*
      TODO: owner="pmuller" category="Finish" priority="1 - High" created="9/25/2015"
      text="Code to drop table here.
            Be careful about security!!  Don't want to drop important tables!"
      */
      NULL;
    END IF;
  
    logger_pkg.info('CREATING TABLE ' || pi_table_name || ' using supplied inputs...');
    EXECUTE IMMEDIATE lv_stmt_clob;
    lv_rowcount := SQL%ROWCOUNT;
    logger_pkg.info('CREATE TABLE ' || pi_table_name || ' using supplied inputs - SUCCESS! ' ||
                    to_char(lv_rowcount) || ' rows.',
                    TRUE);
  
    po_row_count := lv_rowcount;
  
    IF pi_gather_stats_flag
    THEN
      /*
      TODO: owner="pmuller" category="Finish" priority="2 - Medium" created="9/25/2015"
      text="gather table stats"
      */
      NULL;
    END IF;
    
    /* Grant SELECT on the new table to READONLY and OPS schemas. 
    We could do this somewhere else (in toggle, or refresh_object); but I'm thinking
    its best here at this low level.  I can't think of a case where we create a table
    and DONT want privs granted.  */
    BEGIN
      EXECUTE IMMEDIATE('GRANT SELECT ON ' || pi_table_name || ' TO readonly, ops');
    EXCEPTION
      WHEN OTHERS
        THEN logger_pkg.warn('Grant on ' || pi_table_name || 
                             ' to readonly and ops schema failed with error ' || SQLERRM);
    END;
    
  EXCEPTION
    WHEN OTHERS THEN
      close_temp_clob(lv_stmt_clob);
      logger_pkg.fatal(pi_error_code         => SQLCODE,
                       pi_message            => 'Error creating table ' || pi_table_name || ' ' || SQLERRM,
                       pi_transaction_result => NULL);
    
      RAISE;
    
  END ctas;

  --------------------------------------------------------------------------------
  PROCEDURE ctas(pi_table_name         IN VARCHAR2,
                 pi_stmt_clob          IN CLOB,
                 pi_storage_clause     IN VARCHAR2 DEFAULT NULL,
                 pi_compression_clause IN VARCHAR2 DEFAULT NULL,
                 pi_tablespace_clause  IN VARCHAR2 DEFAULT NULL,
                 pi_partition_clause   IN VARCHAR2 DEFAULT NULL,
                 pi_iot_flag           IN BOOLEAN DEFAULT FALSE,
                 pi_clobber_flag       IN BOOLEAN DEFAULT TRUE,
                 pi_gather_stats_flag  IN BOOLEAN DEFAULT TRUE) IS
  
    lv_out NUMBER;
  BEGIN
    /* Providing this overload so that callers which don't care about 
    row count can use the procedure without making code changes.  */
    ctas(pi_table_name         => pi_table_name,
         pi_stmt_clob          => pi_stmt_clob,
         pi_storage_clause     => pi_storage_clause,
         pi_compression_clause => pi_compression_clause,
         pi_tablespace_clause  => pi_tablespace_clause,
         pi_partition_clause   => pi_partition_clause,
         pi_iot_flag           => pi_iot_flag,
         pi_clobber_flag       => pi_clobber_flag,
         pi_gather_stats_flag  => pi_gather_stats_flag,
         po_row_count          => lv_out); -- This return variable goes into the bit bucket!
  
  END ctas;

  --------------------------------------------------------------------------------
  FUNCTION replace_placeholders_in_sql(fi_sql_in            IN CLOB,
                                       fi_months_in_refresh IN NUMBER,
                                       fi_db_link_name      IN VARCHAR2,
                                       fi_source_db_scn     IN VARCHAR2,
                                       fi_source_name_short IN VARCHAR2) RETURN CLOB IS
    lv_result CLOB;
  
  BEGIN
    /*  We use text processing to place varrying values into the refresh SQL.  We could/should use
        bind variables for the SCN and months in refresh instead.  (can't bind in a db link name).
        But thats a project for a later date!  I'm justifying it to myself by saying these queries 
        are run only twice a day and since they are really big queries, the extra parse time we incur 
        by not using binds is only a very very small portion of the execution time.  */
  
    /* Replace the placeholder string "months_in_refresh" in the refresh_sql with the number of months */
    lv_result := REPLACE(fi_sql_in, 'months_in_refresh', to_char(fi_months_in_refresh));

    /* Replace the string "db_link_name" in the refresh_sql with the name of the db link */
    lv_result := REPLACE(lv_result, 'db_link_name', fi_db_link_name);

    /* Replace the placeholder string "source_db_SCN" in the refresh_sql with the remote SCN */
    lv_result := REPLACE(lv_result, 'source_db_SCN', to_char(fi_source_db_scn));
    
    /* Replace the placeholder string "sourceNameShort" in the refresh_sql with the source name short */
    lv_result := REPLACE(lv_result, 'sourceNameShort', to_char(fi_source_name_short));    
    
    RETURN lv_result;

  END replace_placeholders_in_sql;
  
  --------------------------------------------------------------------------------
  PROCEDURE refresh_mv (pi_mv_name  VARCHAR2,
                        pi_method   VARCHAR2,
                        pi_start_ts TIMESTAMP DEFAULT SYSTIMESTAMP) IS
                        
  lv_source           VARCHAR2(61) := gc_source || '.refresh_mv';
  lv_job_name         VARCHAR2(30) := SUBSTR('MV_'||UPPER(pi_mv_name),1,30);
  lv_job_str          VARCHAR2(3000);
  
  BEGIN
  
    logger_pkg.instantiate_logger;
    logger_pkg.set_level('INFO');
    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('refresh_mv');  
  
    lv_job_str :=
      'BEGIN
        logger_pkg.instantiate_logger;
        logger_pkg.set_source('''||lv_job_name||''');
        DBMS_MVIEW.REFRESH('''||pi_mv_name||''','''||pi_method||''');
        logger_pkg.unset_source('''||lv_job_name||''');
      EXCEPTION
        WHEN OTHERS THEN                                       
          logger_pkg.unset_source('''||lv_job_name||''');                                       
      END;';

    logger_pkg.info(lv_job_str);
    
    DBMS_SCHEDULER.CREATE_JOB (
          job_name             => lv_job_name,
          job_type             => 'PLSQL_BLOCK',
          job_action           => lv_job_str,
          start_date           => pi_start_ts,
          enabled              => TRUE,
          comments             => 'Refresh Materialized View, '||pi_mv_name||' - Refresh method = '||pi_method);
  
    logger_pkg.unset_source(lv_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.unset_source(lv_source);
      RAISE;                        
                        
  END refresh_mv;  
  
END lego_tools;
/
