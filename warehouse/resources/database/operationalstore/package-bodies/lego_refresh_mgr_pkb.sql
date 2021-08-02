CREATE OR REPLACE PACKAGE BODY lego_refresh_mgr_pkg AS
  /******************************************************************************
     NAME:       LEGO_REFRESH_MGR_PKG
     PURPOSE:    To manage refresh of LEGO objects.
  
     Ver    Date        Author       Description
     -----  ----------  -----------  ------------------------------------
     1.0    8/15/2012   jlooney      Created this package.
     2.0    11/08/2012  pmuller      Renamed package and modified it to support 
                                     multi-threaded execution, syncronized refreshes, 
                                     and syncronized releases of objects to Jasper.
     2.1    02/26/2013  pmuller      Added procedures for operational administration.
     2.2    04/15/2013  pmuller      Two new refresh methods, grant select on toggle 
                                     base tables, constants stored in LEGO_PARAMETER table.
     2.3    07/16/2013  jpullifrone  In ctas proc, added logic to handle PK name for IOT tables. 
     2.4    08/05/2013  jpullifrone  Implemented "THE GOVENATOR" - logic to govern the number of
                                     refreshes that can run simultaneously.  This is set by a 
                                     parameter in lego_parameter.  If set to zero, this will allow
                                     for unlimited simultenous runs.  IQN-6296 - Rel 11.3.1 
     2.5    09/11/2013  jpullifrone  Added new procedure, run_lego_refresh_stats. IQN-6746 Rel 11.4
     2.6    10/15/2013  jpullifrone  Added new procedure, refresh_incremental_lego. IQN-8454 Rel 11.4.1   
     2.7    12/02/2013  jpullifrone  Added logic to refresh_incremental_lego to drop and recreate the 
                                     incremental table even if there is no data.  Rel 11.4.2.
     2.8    12/29/2013  pmuller      Prevent "jobs are already running" error from going unhandled and 
                                     showing up in the database alert log.
     2.9    01/08/2014  jpullifrone  Added additional update logic to release_worker to update all first 
                                     pass legos if one or more second pass legos fail. The update will 
                                     "back-out" the NRT update. Also added the extra argument in the calls 
                                     to release_worker DBMS_SCHEDULER job in all three release procedure. 
                                     One other "unrelated" change was to add a call to logger_pkg.instantiate_logger 
                                     in the initialize_parameter procedure of this package. This will ensure the 
                                     logger pkg is instantiated and populate all pertinent columns in the 
                                     PROCESSING_LOG table - IQN-11522 Release 12.0. 
     3.0    01/24/2014  jpullifrone  Change to release_worker to prevent failed Legos from being released.
                                     IQN-12503 Release 12.0. 
     3.1    03/03/2014  jpullifrone  In run_lego_refresh_stats, changed ORDER BY for crsr_stddev to job_runtime ASC.
                                     IQN-14186 Release 12.0.1. 
     3.2    03/26/2014  jpullifrone  When checking to see if data exists in lego for refresh_incremental_lego, don't 
                                     try to count all the rows, just see if a row exists.  IQN-14532 Release 12.0.2. 
     3.3    03/26/2014  pmuller      Added code to modify refresh_sql for SQL_TOGGLE legos such that inactive data 
                                     older than a certain number of months will not be included.  IQN-14482 release 12.0.2
     3.4    05/08/2014  pmuller      Improved logging by removing many of the calls to the logger_pkg procedures 
                                     set_source and set_code_location.   IQN-16328 Release 12.1   
     3.5    05/31/2016  jpullifrone  IQN-32537 Major change: release_worker and 1st/2nd pass has been retired.  A relic from Jasper 
                                     Reporting days, it used to be a requirement of the refresh manager to release (switch 
                                     the synonyms from one base table to another) all Lego objects within a given pass all
                                     at the same time.  The downside to this methodology is that it defeats an important
                                     purpose of a 2-table, synonym-switching mechanism, which is to make a newly refreshed 
                                     object available to be used by subsequent objects being refreshed, by always referring 
                                     to the synonym name, and not worrying about which base table was recently refreshed.
                                     This lead to the "most_recently_loaded_table" concept (and function), where we would
                                     ask a Lego object which of the base tables was the most recently loaded so that we 
                                     could use it as a souce for another Lego object refresh.  No more.  As of now and in
                                     terms of relasing (synonym switching), each Lego object is an island, meaning that once
                                     the refresh completes for a given object, the synonym will switch for that object making 
                                     it available for immediate use.  There is no more DBMS_SCHEDULER release_worker that will
                                     run in the background polling and waiting for all 1st pass or 2nd objects to complete.
                                     In its place, so to speak, is a release_me procedure that is called once the new base table
                                     has been created, to a) switch the synonym to point to the new base table b) set the new
                                     refresh_on_or_after time and c) update the started_refresh and status flags on lego_refresh
                                     and lego_refresh_history respectively.  It would have been acceptable to simply end with the
                                     status of "refresh complete," but it seemed prudent to maintain a final status of "released"
                                     since their is a separate call to release, which performs the steps mentioned previous that 
                                     could potentially result in failure and thereby leaving the object in a "refresh complete"
                                     status without having been "released."
     3.6    07/08/2016  jpullifrone  IQN-33328 added new character replacement input parameter for SQL TOGGLE Legos for source_name_short
                                     value of lego_source. 
     3.7    08/22/2016  jpullifrone  IQN-34162 changed calling signature in procedural_load proc to include object_name as well as source_name.
	 3.8    04/25/2017  jpullifrone  IQN-37461 apply select grant to finance.
	 3.9    04/28/2017  jpullifrone  IQN-37523 undoing IQN-37461 and doing it differently by tablizing which schemas get select privs on which tables.     
     4.0    09/12/2018  pmuller      IQN-40224 Removing concepts of refresh groups, refresh dependency order, and scheduled refreshes.
                                     To that end, all of the REFRESH entrypoints have been moved to a new package, and all stuff relating to
                                     refresh groups, scheduling, and RDO have been removed.
                                     Also removed the following procedures and functions:
                                     running_job_count, is_initial_load_group, load_source_scn_array, start_scheduler_job_for_lego,
                                     initial_load, and run_lego_refresh_stats.
  
     The following system and object privileges are required for this package 
     to function:
  
     GRANT CREATE JOB, CREATE SYNONYM, CREATE TABLE
        TO user;
     GRANT execute ON dbms_lock 
        TO user;
     GRANT select, flashback ON <each Front Office table used for Lego refreshes>
        TO user;  
  ******************************************************************************/

  g_source             CONSTANT VARCHAR2(30) := 'LEGO_REFRESH_MGR_PKG';
  g_scheduler_job_name CONSTANT VARCHAR2(30) := 'LEGO_REFRESH_JOB';
--  g_context_name       CONSTANT VARCHAR2(30) := 'LEGO_SCN_CONTEXT';
  gv_error_stack                VARCHAR2(1000);

  /* These variables are initialized in the code section of the package. */
  g_polling_interval            NUMBER;  -- seconds to sleep between polls
  g_refresh_timeout_interval    NUMBER;  -- seconds of queueing before a refresh times out
  g_start_init_load_timeout_int NUMBER;  -- seconds of queueing before an initial load times out

  /* This package creates two kinds of scheduler jobs.  
  1.  Object jobs refresh a single lego object.   
  2.  The initial job is run during deployment only.  
      
  If you change these, ensure that the total length of a job name does not exceed 30 characters.  */
  g_job_name_prefix_object  CONSTANT VARCHAR2(8)  := 'LEGO_OBJ';
  g_job_name_prefix_initial CONSTANT VARCHAR2(9)  := 'LEGO_INIT';

  /* Character delimiter between statements in release_sql. Don't pick a REGEXP "special character" */
  g_release_ddl_delimiter CONSTANT VARCHAR2(1) := ';';

  /* Refresh method codes.  
  These must match the enumerated values in check constraint lego_refresh_rm_ck */
  g_sql_toggle_method        CONSTANT lego_refresh.refresh_method%TYPE := 'SQL TOGGLE';
  g_proc_toggle_method       CONSTANT lego_refresh.refresh_method%TYPE := 'PROC TOGGLE';
  g_proc_toggle_args_method  CONSTANT lego_refresh.refresh_method%TYPE := 'PROC TOGGLE ARGS';
  g_procedure_only_method    CONSTANT lego_refresh.refresh_method%TYPE := 'PROCEDURE ONLY';
  g_procedure_release_method CONSTANT lego_refresh.refresh_method%TYPE := 'PROCEDURE ONLY RELEASE';
  g_partition_swap_method    CONSTANT lego_refresh.refresh_method%TYPE := 'PARTITION SWAP';

  /* Refresh job status codes.  
  These must match the enumerated values in check constraint lego_refresh_history_status_ck */
  g_job_status_scheduled    CONSTANT lego_refresh_history.status%TYPE := 'scheduled';
  g_job_status_started      CONSTANT lego_refresh_history.status%TYPE := 'started refresh';
  g_job_status_complete     CONSTANT lego_refresh_history.status%TYPE := 'refresh complete';
  g_job_status_released     CONSTANT lego_refresh_history.status%TYPE := 'released';
  g_job_status_error        CONSTANT lego_refresh_history.status%TYPE := 'error';
  g_job_status_parent_error CONSTANT lego_refresh_history.status%TYPE := 'error in prerequisite';
  g_job_status_timeout      CONSTANT lego_refresh_history.status%TYPE := 'timeout';
  g_job_status_stopped      CONSTANT lego_refresh_history.status%TYPE := 'stopped';
  
  /* An array to hold the current SCNs at all remote databases. 
     This is kind of a cache - since there are many legos which need this; but only a few sources
     we will load this array once and save lots of remote calls to get the scn. */
  TYPE source_scns IS TABLE OF NUMBER
    INDEX BY lego_source.source_name%TYPE;

  ga_source_scn_array source_scns;

  /*Refresh governor count.
  Determines how many refreshes can occur at the same time. */  
  g_job_governor_cnt        PLS_INTEGER;  
  
  /* General Support Email Addy */
  g_support_email_addy      VARCHAR2(64);
  
  /*Lego Refresh Stats    
  These values will drive the procedure, run_lego_refresh_stats */
  g_stats_flag              CHAR(1); 
  g_stddev_multiplier       NUMBER; 
  g_lookback_days           PLS_INTEGER;    

  --------------------------------------------------------------------------------
  FUNCTION create_temp_clob RETURN CLOB IS
    v_return_clob CLOB;
  BEGIN
    dbms_lob.createtemporary(v_return_clob, TRUE, dbms_lob.session);
    dbms_lob.open(v_return_clob, dbms_lob.lob_readwrite);

    RETURN v_return_clob;
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
  PROCEDURE drop_table(pi_table_name IN VARCHAR2) IS
    e_table_does_not_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_table_does_not_exist, -942);

  BEGIN
    logger_pkg.info('Drop table ' || pi_table_name);
    EXECUTE IMMEDIATE ('DROP TABLE ' || pi_table_name || ' purge');
    logger_pkg.info('Drop table ' || pi_table_name || ' complete',
                    TRUE);

  EXCEPTION
    WHEN e_table_does_not_exist THEN
      logger_pkg.info('Table ' || pi_table_name || ' does not exist.');

    WHEN OTHERS THEN
      gv_error_stack := SQLERRM || chr(10) ||
                        dbms_utility.format_error_backtrace;
      logger_pkg.fatal(NULL,
                       SQLCODE,
                       'Error dropping table ' || pi_table_name || ' ' ||
                       SQLERRM);

      RAISE;
  END drop_table;

  --------------------------------------------------------------------------------
  PROCEDURE create_indexes(pi_object_name IN lego_refresh.object_name%TYPE,
                           pi_source_name IN lego_refresh.source_name%TYPE, 
                           pi_table_name  IN lego_refresh.refresh_object_name_1%TYPE) IS

    v_sql               VARCHAR2(2000);
    v_index_type        VARCHAR2(20);
    v_new_index_name    VARCHAR2(30);
    v_tablespace_clause VARCHAR2(200);
  
    CURSOR get_index_cur IS
      SELECT * FROM lego_refresh_index 
       WHERE object_name = pi_object_name 
         AND source_name = pi_source_name;
  BEGIN

    FOR get_index_row IN get_index_cur LOOP
      IF get_index_row.index_type = 'UNIQUE'
      THEN
        v_index_type := 'UNIQUE';
      ELSE
        v_index_type := NULL;
      END IF;
    
      IF get_index_row.tablespace_name IS NOT NULL
      THEN
        v_tablespace_clause := 'TABLESPACE ' ||
                               get_index_row.tablespace_name;
      ELSE
        v_tablespace_clause := NULL;
      END IF;
    
      /*  Protect against ORA-00955 "name is already used by an existing object"
      errors by choosing the index name to be the first 29 characters of data in 
      LEGO_REFRESH_INDEX.index_name and then append the LAST character of the 
      table name passed to the procedure.  The table names will usually end 
      with '1' or '2' for toggles.  */
      v_new_index_name := substr(get_index_row.index_name, 1, 29) ||
                          substr(pi_table_name, -1, 1);
    
      v_sql := 'CREATE ' || v_index_type || ' INDEX ' || v_new_index_name ||
               ' ON ' || pi_table_name || ' (' || get_index_row.column_list || ') ' ||
               v_tablespace_clause;
    
      logger_pkg.debug(v_sql);
      logger_pkg.info('CREATE INDEX ' || v_new_index_name || ' ON ' ||
                      pi_table_name || ' - Processing...');
    
      EXECUTE IMMEDIATE v_sql;
    
      logger_pkg.info('CREATE INDEX ' || v_new_index_name || ' ON ' ||
                      pi_table_name || ' - DONE!',
                      TRUE);
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      gv_error_stack := SQLERRM || chr(10) ||
                        dbms_utility.format_error_backtrace;
      logger_pkg.fatal(NULL,
                       SQLCODE,
                       'Error creating index for ' || pi_object_name || ' ' ||
                       SQLERRM);

      RAISE;
  END create_indexes;

  --------------------------------------------------------------------------------
  PROCEDURE analyze_table(pi_table_name IN VARCHAR2) IS
    v_owner_name VARCHAR2(30);
  BEGIN
    logger_pkg.info('Gathering statistics on table: ' || pi_table_name ||
                    ' - Processing...');
  
    SELECT owner
      INTO v_owner_name
      FROM (SELECT owner
              FROM all_tables
             WHERE table_name = pi_table_name
               AND owner NOT IN ('SYS',
                                 'SYSTEM',
                                 'DBSNMP',
                                 'WMSYS',
                                 'APPQOSSYS',
                                 'OUTLN',
                                 'EXFSYS',
                                 'XDB',
                                 'CTXSYS',
                                 'ORDDATA',
                                 'ORDSYS',
                                 'OWBSYS',
                                 'SCOTT',
                                 'MDSYS',
                                 'OLAPSYS',
                                 'SYSMAN',
                                 'APEX_030200',
                                 'FLOWS_FILES')
             ORDER BY CASE
                        WHEN owner = sys_context('USERENV', 'CURRENT_SCHEMA') THEN
                         1
                        ELSE
                         2
                      END,
                      owner)
     WHERE rownum = 1;
  
    IF SQL%FOUND
    THEN
      BEGIN
        dbms_stats.gather_table_stats(ownname          => v_owner_name,
                                      tabname          => pi_table_name,
                                      estimate_percent => dbms_stats.auto_sample_size,
                                      granularity      => 'ALL',
                                      cascade          => TRUE,
                                      method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
                                      degree           => 4);
        COMMIT;
        logger_pkg.info('Gathering statistics on table: ' || pi_table_name || ' - DONE!',
                        TRUE);
      EXCEPTION
        WHEN OTHERS THEN
          logger_pkg.info('Gathering statistics on table: ' || pi_table_name ||
                          ' - FAILED!  ' || SQLERRM,
                          TRUE);
      END;
    ELSE
      logger_pkg.info('Gathering statistics on table: ' || pi_table_name ||
                      ' - FAILED!  TABLE NOT FOUND!',
                      TRUE);
    END IF;
  
  EXCEPTION
    WHEN no_data_found THEN
      logger_pkg.info('Gathering statistics on table: ' || pi_table_name ||
                      ' - FAILED!  TABLE NOT FOUND!',
                      TRUE);
    WHEN OTHERS THEN
      gv_error_stack := SQLERRM || chr(10) ||
                        dbms_utility.format_error_backtrace;
      logger_pkg.fatal(pi_error_code => SQLCODE,
                       pi_message => 'Error gathering statistics for table ' || pi_table_name || ' ' || SQLERRM,
                       pi_transaction_result => NULL);
      RAISE;
  END analyze_table;

  -------------------------------------------------------------------------------
  PROCEDURE ctas(pi_table_name         IN VARCHAR2,
                 pi_stmt_clob          IN CLOB,
                 pi_storage_clause     IN VARCHAR2 DEFAULT NULL,
                 pi_partition_clause   IN VARCHAR2 DEFAULT NULL) IS
    e_non_exadata EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_non_exadata, -64307);
    e_invalid_storage_option EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_non_exadata, -02143);
  
    v_sql       VARCHAR2(32767);
    v_stmt_clob CLOB;
    v_rowcount  NUMBER;
  BEGIN
    v_stmt_clob := create_temp_clob;
  
    /* IOT Lego Toggles will have a Primary Key name defaulted to LEGO_IOT_PK in the Exadata storage
       clause of LEGO_REFRESH.  When we go to build the table here, we will replace the defaulted 
       name with the name of the table with PK appended to it.  In this way, there will be no chance
       of getting the "object already exists" error. */ 
    v_sql := 'CREATE TABLE ' || pi_table_name || ' ' ||
             REPLACE(pi_storage_clause,'LEGO_IOT_PK',pi_table_name||'PK') || ' ' || pi_partition_clause ||
             ' AS ';
    dbms_lob.writeappend(v_stmt_clob, length(v_sql), v_sql);
    v_stmt_clob := v_stmt_clob || pi_stmt_clob;

    logger_pkg.debug(v_stmt_clob);
  
    BEGIN
      logger_pkg.info('CREATE TABLE ' || pi_table_name ||
                      ' using supplied storage clause...');
    
      EXECUTE IMMEDIATE v_stmt_clob;
      v_rowcount := SQL%ROWCOUNT;
    
      logger_pkg.info('CREATE TABLE ' || pi_table_name ||
                      ' using supplied storage clause - SUCCESS! ' ||
                      to_char(v_rowcount) || ' rows.',
                      TRUE);
    EXCEPTION
      WHEN e_non_exadata OR e_invalid_storage_option THEN
        logger_pkg.info('CREATE TABLE ' || pi_table_name ||
                        ' using supplied storage clause - FAILED!',
                        TRUE);
        logger_pkg.info('CREATE TABLE ' || pi_table_name ||
                        ' without supplied storage clause...');
      
        close_temp_clob(v_stmt_clob);
        v_stmt_clob := create_temp_clob;
        v_sql       := 'CREATE TABLE ' || pi_table_name || ' ' ||
                       pi_partition_clause || ' AS ';
        dbms_lob.writeappend(v_stmt_clob, length(v_sql), v_sql);
        v_stmt_clob := v_stmt_clob || pi_stmt_clob;

        EXECUTE IMMEDIATE v_stmt_clob;
        v_rowcount := SQL%ROWCOUNT;

        logger_pkg.info('CREATE TABLE ' || pi_table_name ||
                        ' without supplied storage clause - SUCCESS! ' ||
                        to_char(v_rowcount) || ' rows.',
                        TRUE);
    END;
  
    /* Grant SELECT on the new table to READONLY and OPS schemas. Grants to other 
       schemas will occur through LEGO_REFRESH_TOGGLE_PRIV. */
    BEGIN
      
      --specific grants to specific tables and schemas as defined in lego_refresh_toggle_priv
	  FOR obj_name IN (SELECT p.grantee_user_name, p.object_name, DECODE(p.grant_option, 1,' WITH GRANT OPTION', NULL) AS grant_option
                         FROM lego_refresh_toggle_priv p, lego_refresh r
                        WHERE p.object_name = r.object_name)
      LOOP
        
        BEGIN      

	      EXECUTE IMMEDIATE('GRANT SELECT ON ' || pi_table_name || ' TO '||obj_name.grantee_user_name||obj_name.grant_option);  
      
	    EXCEPTION
          WHEN OTHERS
            THEN logger_pkg.warn('Grant on ' || pi_table_name ||' to '||obj_name.grantee_user_name||obj_name.grant_option||' schema failed with error ' || SQLERRM);	  
        END;
	  
	  END LOOP;

      --general grant script here since all objects get select to readonly and ops
      EXECUTE IMMEDIATE('GRANT SELECT ON ' || pi_table_name || ' TO readonly, ops');
  
  EXCEPTION
      WHEN OTHERS
        THEN logger_pkg.warn('Grant on ' || pi_table_name || 
                             ' to readonly, ops, and iqprodm schema failed with error ' || SQLERRM);
    END;
          
  EXCEPTION
    WHEN OTHERS THEN
      close_temp_clob(v_stmt_clob);
      gv_error_stack := SQLERRM || chr(10) ||
                        dbms_utility.format_error_backtrace;
      logger_pkg.fatal(pi_error_code => SQLCODE,
                       pi_message => 'Error creating table ' || pi_table_name || ' ' || SQLERRM,
                       pi_transaction_result => NULL);

      RAISE;
  END ctas;

  --------------------------------------------------------------------------------
  PROCEDURE initialize_parameters (pi_init_timeouts IN BOOLEAN DEFAULT FALSE) IS
  BEGIN
    
    /* Instantiate the Logger */
    logger_pkg.instantiate_logger;
    
    /* Load parameters from LEGO_PARAMETER table into package global variables.
    First get minimum logging level.  Messages "below" this level will not be logged.  */
    logger_pkg.set_level(get_lego_parameter_text_value('logging_level'));
    
    /* Get governor limit.  If = 0, then there is no restriction on how many will run at the same time. 
       A default of 0 is added in case the value is not set for whatever reason. */ 
    g_job_governor_cnt := NVL(lego_refresh_mgr_pkg.get_lego_parameter_num_value('lego_refresh_governor_cnt'),0);   
    
    /* Get support email addy */
    g_support_email_addy := lego_refresh_mgr_pkg.get_lego_parameter_text_value('support_email_addy');
    
    /* Get Lego Status information */
    g_stats_flag         := NVL(lego_refresh_mgr_pkg.get_lego_parameter_text_value('lego_refresh_stats_flag'),'N');  
    g_stddev_multiplier  := NVL(lego_refresh_mgr_pkg.get_lego_parameter_num_value('lego_refresh_stats_stddev_multiplier'),3); 
    g_lookback_days      := NVL(lego_refresh_mgr_pkg.get_lego_parameter_num_value('lego_refresh_stats_lookback_days'),7);      

    IF pi_init_timeouts
      THEN
        /* Get polling interval and timeout information. */
        g_polling_interval            := get_lego_parameter_num_value('polling_interval');
        g_refresh_timeout_interval    := get_lego_parameter_num_value('refresh_timeout_interval');
        g_start_init_load_timeout_int := get_lego_parameter_num_value('start_init_load_timeout_interval');
    END IF;    
  
  END initialize_parameters;

  --------------------------------------------------------------------------------
  FUNCTION get_lego_parameter_text_value(pi_parameter_name IN VARCHAR2) 
  RETURN VARCHAR2 IS
    v_result  lego_parameter.text_value%TYPE;
  BEGIN
    
    SELECT text_value
      INTO v_result
      FROM lego_parameter
     WHERE parameter_name = lower(pi_parameter_name);

    RETURN v_result;
    
  EXCEPTION
    WHEN no_data_found
      THEN RETURN NULL;
      
  END get_lego_parameter_text_value;
  
  --------------------------------------------------------------------------------
  FUNCTION get_lego_parameter_num_value(pi_parameter_name IN VARCHAR2) 
  RETURN VARCHAR2 IS
    v_result  lego_parameter.number_value%TYPE;
  BEGIN
    
    SELECT number_value
      INTO v_result
      FROM lego_parameter
     WHERE parameter_name = lower(pi_parameter_name);

    RETURN v_result;
    
  EXCEPTION
    WHEN no_data_found
      THEN RETURN NULL;
      
  END get_lego_parameter_num_value;
  
  --------------------------------------------------------------------------------
  PROCEDURE update_history_table(pi_object_name     IN lego_refresh_history.object_name%TYPE,
                                 pi_refresh_time    IN lego_refresh_history.job_runtime%TYPE,
                                 pi_source          IN lego_refresh_history.source_name%TYPE,
                                 pi_status          IN lego_refresh_history.status%TYPE,
                                 pi_error_message   IN VARCHAR2 DEFAULT NULL,
                                 pi_refreshed_table IN VARCHAR2 DEFAULT NULL) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    /* This is called when an object refresh has errored, timed out, or been killed 
    and we need to put the status message into lego_refresh_history. 
    This is an update by PK (we specify all three PK cols) so either 1 or 0 row(s) are changed. */
    UPDATE lego_refresh_history
       SET status                 = pi_status,
           error_message          = pi_error_message,
           toggle_refreshed_table = pi_refreshed_table
     WHERE object_name = pi_object_name
       AND job_runtime = pi_refresh_time
       AND source_name = pi_source;
  
    COMMIT;
  END update_history_table;

  --------------------------------------------------------------------------------
  PROCEDURE log_and_email_fatal_error(pi_object_name    IN lego_refresh.object_name%TYPE DEFAULT NULL,
                                      pi_source_name    IN lego_refresh_history.source_name%TYPE DEFAULT NULL,
                                      pi_top_level_proc IN VARCHAR DEFAULT NULL,
                                      pi_error_message  IN VARCHAR2,
                                      pi_argument       IN VARCHAR DEFAULT NULL) IS
    lv_database_name VARCHAR2(256) := sys_context('USERENV', 'DB_NAME');
    lv_log_message   processing_log.message%TYPE;
    lv_email_subject VARCHAR2(512);
    lv_email_message VARCHAR2(4000);
  BEGIN
    /*  Called from the top-level procs REFRESH and INITIAL_LOAD, and from mid-level REFRESH_OBJECT.  */
    CASE
      WHEN pi_object_name IS NOT NULL THEN
        /*  Called by REFRESH_OBJECT  */
        lv_log_message   := 'Error while refreshing ' || pi_object_name;
        lv_email_subject := 'Error while refreshing ' || pi_object_name ||
                            ' source ' || pi_source_name || ' in ' || lv_database_name;
      
        lv_email_message := pi_error_message;
      ELSE
        /* Called by INITIAL_LOAD, REFRESH, RELEASE_WORKER, or START_SECOND_PASS  */
        lv_log_message   := 'Error in ' || pi_top_level_proc;
        lv_email_subject := 'Error in ' || pi_top_level_proc || ' in ' ||
                            lv_database_name;
      
        IF pi_argument IS NOT NULL
        THEN
          lv_email_message := pi_top_level_proc || ' called with argument ' ||
                              pi_argument;
        ELSE
          lv_email_message := pi_top_level_proc ||
                              ' called with no arguments';
        
        END IF;
        lv_email_message := lv_email_message || chr(10) || pi_error_message;
    END CASE;
  
    logger_pkg.fatal(lv_log_message || '  ' || pi_error_message);
    /*
    send_email(sender    => 'DONOTREPLY@beeline.com',
               recipient => g_support_email_addy,
               subject   => lv_email_subject,
               message   => chr(10) || lv_email_message || chr(10) ||
                              ' Message sent at: ' ||
                              to_char(SYSDATE, 'YYYY-Mon-DD hh24:mi:ss'));
    */
  END log_and_email_fatal_error;

  --------------------------------------------------------------------------------     
  PROCEDURE toggle(pi_object_name            IN lego_refresh.object_name%TYPE,
                   pi_refresh_time           IN TIMESTAMP,
                   pi_source                 IN lego_refresh.source_name%TYPE,
                   pi_refresh_scn            IN NUMBER,
                   pi_refresh_method         IN lego_refresh.refresh_method%TYPE,
                   pi_storage_clause         IN lego_refresh.storage_clause%TYPE,
                   pi_partition_clause       IN lego_refresh.partition_clause%TYPE,
                   pi_refresh_sql            IN lego_refresh.refresh_sql%TYPE,
                   pi_refresh_procedure_name IN lego_refresh.refresh_procedure_name%TYPE,
                   pi_refresh_object_name_1  IN lego_refresh.refresh_object_name_1%TYPE,
                   pi_refresh_object_name_2  IN lego_refresh.refresh_object_name_2%TYPE,
                   pi_synonym_name           IN lego_refresh.synonym_name%TYPE,
                   po_release_ddl            OUT VARCHAR2,
                   po_refreshed_table        OUT VARCHAR) IS

    v_pointed_table         VARCHAR2(30);
    v_refresh_table         VARCHAR2(30);
    v_anon_block            VARCHAR2(128);
    lv_db_link_name         lego_source.db_link_name%TYPE;
    lv_src_name_short       lego_source.source_name_short%TYPE;
    lv_modified_refresh_sql lego_refresh.refresh_sql%TYPE;
  BEGIN
    /* This procedure does the following:
     1)  Get the name of the DB link to use to reach the remote source.
     2)  Check to see where the synonym is pointing.
     3)  DROP the other table. 
     4)  recreate it and load it. This can be via SQL or procedure.  This is determined
         by the REFRESH_METHOD.  TOGGLE = SQL, PROCEDURAL = stored procedure.
     5)  create indexes on the new table
     6)  gather statistics on the new table
     7)  grant SELECT on the table to the RO_ user.
     8)  log the DDL required to perform the synonym switch (release) from one base table to the other.
    Any errors should be logged, re-raised, and propagated up to the caller
    (refresh_object).  If the errors are masked, refresh_object will wrongly 
    assume successful completion.   */
  
    logger_pkg.debug('Starting toggle procedure for object: ' || pi_object_name);
  
    /* Ensure metadata is correct. SQL TOGGLE legos need REFRESH_SQL set.  
    PROCEDURAL TOGGLE and proc toggle args legos need REFRESH_PROCEDURE_NAME set.  */
    IF NOT
        ((pi_refresh_method = g_sql_toggle_method AND
        pi_refresh_sql IS NOT NULL AND pi_refresh_procedure_name IS NULL) OR
        (pi_refresh_method IN (g_proc_toggle_method, g_proc_toggle_args_method)  AND
        pi_refresh_sql IS NULL AND pi_refresh_procedure_name IS NOT NULL))
    THEN
      raise_application_error(-20005,
                              'Configuration for ' || pi_object_name ||
                              ' source ' || pi_source || ' is incorrect.' ||
                              ' refresh_sql must be populated for ' ||
                              g_sql_toggle_method ||
                              '.  refresh_procedure_name must be populated for ' ||
                              g_proc_toggle_method || ' and ' || g_proc_toggle_args_method);
    END IF;
    
    /* Get name of database link to use in refresh. */
    lv_db_link_name := lego_tools.get_db_link_name(fi_source_name => upper(pi_source));
    lv_src_name_short := lego_tools.get_src_name_short(fi_source_name => upper(pi_source));
  
    /* Find which toggle table the synonym points to now. */
    BEGIN
      SELECT table_name
        INTO v_pointed_table
        FROM user_synonyms
       WHERE synonym_name = pi_synonym_name;
    EXCEPTION
      WHEN no_data_found THEN
        /* No synonym with that name exists. This must be "boot up".  Set
        pointed table to REFRESH_OBJECT_NAME_2 so REFRESH_OBJECT_NAME_1
        is dropped, created, and loaded.  The synonym will be created below.  */
        v_pointed_table := pi_refresh_object_name_2;
        logger_pkg.info('Synonym ' || pi_synonym_name ||
                        ' does not exist. It will be created as part of this refresh.');
    END;
  
    IF pi_synonym_name IS NULL OR
       (v_pointed_table != pi_refresh_object_name_1 AND
       v_pointed_table != pi_refresh_object_name_2)
    THEN
      /* Bad data in LEGO_REFRESH or synonym pointing somewhere unknown  */
      raise_application_error(-20004,
                              'Synonym configuration for ' || pi_object_name || 
                              ' source ' || pi_source || ' is incorrect.');
    END IF;
  
    IF v_pointed_table = pi_refresh_object_name_1
    THEN
      v_refresh_table := pi_refresh_object_name_2;
    ELSE
      v_refresh_table := pi_refresh_object_name_1;
    END IF;
  
    /* Now we have determined which table will be dropped and recreated.  */
    drop_table(v_refresh_table);
  
    CASE pi_refresh_method
      WHEN g_proc_toggle_method THEN
        /* pass the proc toggle procedure the new table name and the source name */
        v_anon_block := 'BEGIN ' || pi_refresh_procedure_name || '(''' ||
                        v_refresh_table || ''', ''' || pi_source || ''', ''' ||
                        to_char(pi_refresh_scn) || '''); END;';
        logger_pkg.debug(v_anon_block);
        logger_pkg.info('Running PL/SQL block for ' || v_refresh_table);
      
        EXECUTE IMMEDIATE (v_anon_block);
      
        logger_pkg.info('Running PL/SQL block for ' || v_refresh_table ||
                        ' - complete',
                        TRUE);
        COMMIT;
      
/*      WHEN g_proc_toggle_args_method THEN
        \* need to add source parameter!! *\
        v_anon_block := 'BEGIN ' || 
                        REPLACE (pi_refresh_procedure_name, 'placeholder', v_refresh_table) || 
                        '; END;';
        
        logger_pkg.debug(v_anon_block);
        logger_pkg.info('Running PL/SQL block for ' || v_refresh_table);
      
        EXECUTE IMMEDIATE (v_anon_block);
      
        logger_pkg.info('Running PL/SQL block for ' || v_refresh_table ||
                        ' - complete',
                        TRUE);
        COMMIT;
*/
      WHEN g_sql_toggle_method THEN
        lv_modified_refresh_sql := lego_tools.replace_placeholders_in_sql
                                       (fi_sql_in            => pi_refresh_sql,
                                        fi_months_in_refresh => NVL(get_lego_parameter_num_value(pi_parameter_name => 'months_in_refresh'), 120),
                                        fi_db_link_name      => lv_db_link_name,
                                        fi_source_db_scn     => pi_refresh_scn,
                                        fi_source_name_short => lv_src_name_short);
        ctas(v_refresh_table,
             lv_modified_refresh_sql,
             pi_storage_clause,
             pi_partition_clause);

      ELSE
        logger_pkg.fatal(pi_message => 'Have not yet implemented refresh method ' || pi_refresh_method ||
                                       ' for object ' || pi_object_name || ' source ' || pi_source,
                         pi_error_code => -20007,
                         pi_transaction_result => NULL);
        raise_application_error(-20007, 'Have not yet implemented refresh method ' || pi_refresh_method ||
                                       ' for object ' || pi_object_name || ' source ' || pi_source);

    END CASE;
  
    create_indexes(pi_object_name, pi_source, v_refresh_table);
  
    analyze_table(v_refresh_table);
    
    /*  ToDo - Add call to grants procedure */

    po_refreshed_table := v_refresh_table;
    po_release_ddl := 'CREATE OR REPLACE SYNONYM ' || pi_synonym_name ||
                            ' FOR ' || v_refresh_table;
  
    logger_pkg.debug('Release DDL: ' || po_release_ddl ||
                     ' Refreshed table: ' || po_refreshed_table);
                     
    logger_pkg.debug('Exiting toggle procedure');
  
  EXCEPTION
    WHEN OTHERS THEN
      IF gv_error_stack IS NULL
      THEN
        gv_error_stack := SQLERRM || chr(10) ||
                          dbms_utility.format_error_backtrace;
      END IF;
    
      logger_pkg.fatal(pi_transaction_result => NULL,
                       pi_error_code         => SQLCODE,
                       pi_message            => gv_error_stack);
    
      update_history_table(pi_object_name     => pi_object_name,
                           pi_refresh_time    => pi_refresh_time,
                           pi_source          => pi_source,
                           pi_status          => g_job_status_error,
                           pi_error_message   => gv_error_stack,
                           pi_refreshed_table => v_refresh_table);
      RAISE;

  END toggle;

  --------------------------------------------------------------------------------     
  PROCEDURE procedural_load(pi_object_name            IN lego_refresh.object_name%TYPE,
                            pi_refresh_time           IN TIMESTAMP,
                            pi_source                 IN lego_refresh.source_name%TYPE,
                            pi_refresh_procedure_name IN lego_refresh.refresh_procedure_name%TYPE) IS

    v_anon_block VARCHAR2(200);
  
  BEGIN
    /* This procedure calls the procedure which loads data.  If there are no
    errors during the procedure, commit the changes.  If there is an error, the
    changes will be rolled back and the error will be re-raised and propagated 
    up to the caller (refresh_object).  If errors are masked, refresh_object
    will wrongly assume successful completion and the history table will be 
    updated incorrectly.   */
  
    v_anon_block := 'BEGIN '||pi_refresh_procedure_name||'(:1,:2); END;';
    logger_pkg.debug(v_anon_block);
    logger_pkg.info('Running PL/SQL block for ' || pi_object_name ||
                    ' source ' || pi_source);
  
    EXECUTE IMMEDIATE v_anon_block USING  pi_object_name, pi_source;
  
    logger_pkg.info('Running PL/SQL block for ' || pi_object_name ||
                    ' source ' || pi_source || ' - complete');  --Dont use the update flag here since we prob. have logging in the proc!
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK; -- undo anything done in update procedure
    
      IF gv_error_stack IS NULL
      THEN
        gv_error_stack := SQLERRM || chr(10) ||
                          dbms_utility.format_error_backtrace;
      END IF;
    
      logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                       pi_error_code         => SQLCODE,
                       pi_message            => gv_error_stack);
    
      update_history_table(pi_object_name   => pi_object_name,
                           pi_refresh_time  => pi_refresh_time,
                           pi_source        => pi_source,
                           pi_status        => g_job_status_error,
                           pi_error_message => gv_error_stack);
    
      RAISE;
    
  END procedural_load;

  --------------------------------------------------------------------------------     
  PROCEDURE procedural_load_release(pi_object_name            IN  lego_refresh.object_name%TYPE,
                                    pi_refresh_time           IN  TIMESTAMP,
                                    pi_refresh_procedure_name IN  lego_refresh.refresh_procedure_name%TYPE,
                                    po_release_ddl            OUT VARCHAR2) IS
    v_anon_block VARCHAR2(200);
    v_ddl        VARCHAR2(4000) := NULL;
  
  BEGIN
    /* This procedure calls a procedure which loads data or performs some process 
    too complicated for a toggle.  The procedure will return the release DDL.  
    If there are no errors during the procedure, commit the changes.  If there is 
    an error, the changes will be rolled back and the error will be re-raised and 
    propagated up to the caller (refresh_object).  If errors are masked, refresh_object
    will wrongly assume successful completion and the history table will be 
    updated incorrectly.   */
  
    v_anon_block := 'BEGIN ' || pi_refresh_procedure_name || '(:1); END;';
    logger_pkg.debug(v_anon_block);
    logger_pkg.info('Running PL/SQL block for ' || pi_object_name);
  
    EXECUTE IMMEDIATE (v_anon_block)
      USING OUT v_ddl;
  
    logger_pkg.info('Running PL/SQL block for ' || pi_object_name ||
                    ' - complete',
                    TRUE);
    COMMIT;
    
    po_release_ddl := v_ddl;
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK; -- undo anything done in update procedure
    
      IF gv_error_stack IS NULL
      THEN
        gv_error_stack := SQLERRM || chr(10) ||
                          dbms_utility.format_error_backtrace;
      END IF;
    
      logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                       pi_error_code         => SQLCODE,
                       pi_message            => gv_error_stack);
    
      update_history_table(pi_object_name,
                           pi_refresh_time,
                           g_job_status_error,
                           gv_error_stack);
    
      RAISE;
    
  END procedural_load_release;

  --------------------------------------------------------------------------------     
  PROCEDURE partition_swap(pi_object_name            IN lego_refresh.object_name%TYPE,
                           pi_refresh_sql            IN lego_refresh.refresh_sql%TYPE,
                           pi_storage_clause         IN lego_refresh.storage_clause%TYPE,
                           pi_refresh_time           IN TIMESTAMP,
                           pi_partition_col_name     IN lego_refresh.partition_column_name%TYPE,
                           pi_num_partitions_to_swap IN lego_refresh.num_partitions_to_swap%TYPE,
                           po_release_ddl            OUT VARCHAR2) IS
  
    v_temp_table_name    VARCHAR2(30) := NULL;
    v_temp_refresh_month VARCHAR2(60);
    v_sql                VARCHAR2(32767);
    v_stmt_clob          CLOB;
    v_release_ddl        VARCHAR2(4000);
  
  BEGIN
    /* Build a string to hold "to_date(<first day of current month>,'<format mask>')"
    This will be used later along with the ADD_MONTHS function to operate on partitions 
    for different months.  */
    v_temp_refresh_month := 'to_date(''' ||
                            to_char(trunc(pi_refresh_time, 'MM'),
                                    'YYYY-Mon-DD hh24:mi:ss') ||
                            ''',''YYYY-Mon-DD hh24:mi:ss'')';
  
    /* This first "LOCK TABLE" statement in the release DDL will create the 
    partition if it does not yet exist.  (for interval partitioning)  */
    v_release_ddl := 'LOCK TABLE ' || pi_object_name || ' PARTITION FOR (' ||
                     v_temp_refresh_month || ') IN SHARE MODE' ||
                     g_release_ddl_delimiter;
  
    FOR i IN 0 .. (pi_num_partitions_to_swap - 1) LOOP
      logger_pkg.set_code_location('Building statement- partition: ' ||
                                   to_char(i));
      v_temp_table_name := substr(pi_object_name, 1, 24) || '_tmp' ||
                           to_char(i);
      v_stmt_clob       := create_temp_clob;
      v_sql             := 'SELECT * FROM (';
    
      dbms_lob.writeappend(v_stmt_clob,
                           dbms_lob.getlength(v_sql || pi_refresh_sql),
                           v_sql || pi_refresh_sql);
    
      /* Build where clause which limits data to the correct month. This assumes 
      that all partitions start/end on the first of the month at midnight.  */
      v_sql := ') WHERE add_months(' || v_temp_refresh_month || ',' ||
               to_char(i * -1) || ') <= ' || pi_partition_col_name ||
               ' AND ' || pi_partition_col_name || ' < add_months(' ||
               v_temp_refresh_month || ',' || to_char((i * -1) + 1) || ')';
    
      dbms_lob.writeappend(v_stmt_clob, dbms_lob.getlength(v_sql), v_sql);

      logger_pkg.debug('Create table - partition: ' || to_char(i));
      logger_pkg.debug(v_stmt_clob);

      drop_table(v_temp_table_name);
      ctas(v_temp_table_name, v_stmt_clob, pi_storage_clause);
      --create_indexes(pi_object_name, v_temp_table_name);
      analyze_table(v_temp_table_name);
    
      close_temp_clob(v_stmt_clob);
    
      v_sql := 'alter table ' || pi_object_name ||
               ' exchange partition for (add_months(' ||
               v_temp_refresh_month || ',' || to_char(i * -1) ||
               ')) with table ' || v_temp_table_name ||
               g_release_ddl_delimiter || 'drop table ' ||
               v_temp_table_name || ' purge' || g_release_ddl_delimiter;
    
      v_release_ddl := v_release_ddl || v_sql;
      logger_pkg.debug(v_release_ddl);
    
    END LOOP;
    po_release_ddl := v_release_ddl;
  
    logger_pkg.debug('Exiting partition swap');
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK; -- undo anything done in update procedure
    
      IF gv_error_stack IS NULL
      THEN
        gv_error_stack := SQLERRM || chr(10) ||
                          dbms_utility.format_error_backtrace;
      END IF;
    
      logger_pkg.fatal(pi_transaction_result => NULL,
                       pi_error_code         => SQLCODE,
                       pi_message            => gv_error_stack);
    
      update_history_table(pi_object_name,
                           pi_refresh_time,
                           g_job_status_error,
                           gv_error_stack);
      RAISE;
    
  END partition_swap;

  --------------------------------------------------------------------------------
  PROCEDURE update_status_for_stopped_jobs (pi_runtime IN TIMESTAMP) IS
  BEGIN
    /* This procedure used to live inside the release_worker procedure but now lives 
       on its own since the release worker concept is gone.  Since this is an important
       step in the refresh process, it survived and now will be called as a "last" step 
       in the refresh procedure once all refresh jobs have been created.  Since the
       refresh job creation happens so quickly, it won't handle STOPPED jobs for the 
       current run, but by changing the job_runtime from "= pi_runtime" to 
       "< pi_runtime" it will handled STOPPED jobs from prior runs.  By selecting job_runtime
       now in the cursor, we can take advantage of the looping structure since the cursor
       could pick-up rows from multiple job runtimes.  That's really the best we can do right 
       now absent any type of meta job running like the old release_worker.
    
       Jobs that appear to be running in LEGO_REFRESH_HISTORY but stopped in
       user_scheduler_job_log have probably been stopped/killed/dropped manually.  
       Set their status accordingly. */
       
    FOR i IN (SELECT lrh.object_name,
                     lrh.source_name,
                     usjd.job_name,
                     usjd.additional_info,
                     usjd.log_date,
                     lrh.job_runtime
                FROM user_scheduler_job_run_details usjd,
                     lego_refresh_history           lrh
               WHERE usjd.log_id = lrh.dbms_scheduler_log_id
                 AND usjd.status = 'STOPPED'
                 AND lrh.job_runtime < pi_runtime
                 AND lrh.status IN
                     (g_job_status_scheduled, g_job_status_started)) LOOP
    
      logger_pkg.warn('Job ' || i.job_name || ' to refresh ' ||
                      i.object_name || ' source: ' || i.source_name || 
                      ' appears to have been stopped. Updating status in LEGO_REFRESH_HISTORY table.');
      update_history_table(pi_object_name   => i.object_name,
                           pi_refresh_time  => i.job_runtime,
                           pi_source        => i.source_name,
                           pi_status        => g_job_status_stopped,
                           pi_error_message => i.additional_info);
    
    END LOOP;
  END update_status_for_stopped_jobs;

  --------------------------------------------------------------------------------
  PROCEDURE release_me(pi_object_rec     IN lego_refresh%ROWTYPE,
                       pi_refresh_object IN lego_refresh.object_name%TYPE,
                       pi_source         IN lego_refresh.source_name%TYPE,
                       pi_runtime        IN TIMESTAMP,
                       pi_release_ddl    IN VARCHAR2) IS

    v_source        VARCHAR2(61) := g_source || '.release_me';
  
  BEGIN
    logger_pkg.set_code_location('Release me');
    logger_pkg.debug('release_me started');
                                       
    CASE
      WHEN pi_object_rec.refresh_method IN (g_sql_toggle_method, g_proc_toggle_method, g_proc_toggle_args_method) THEN
        IF pi_release_ddl IS NOT NULL
        THEN
          logger_pkg.debug('Releasing object: ' || pi_object_rec.object_name ||
                           ' source: ' || pi_object_rec.source_name || 
                           ' with SQL: ' || pi_release_ddl);
          EXECUTE IMMEDIATE (pi_release_ddl);
        ELSE
          logger_pkg.error('Release SQL for object: ' || pi_object_rec.object_name ||
                           ' source: ' || pi_object_rec.source_name || ' is NULL');
        END IF;
      
      WHEN pi_object_rec.refresh_method IN (g_partition_swap_method, g_procedure_release_method) THEN
        IF pi_release_ddl IS NULL
        THEN
          logger_pkg.error('Release SQL for object: ' || pi_object_rec.object_name ||
                           ' source: ' || pi_object_rec.source_name || ' is NULL');
        ELSE
          /* Parse the release_sql and run each statement.  Thanks to Joe 
          for this nice string parsing code!  */
          DECLARE
            TYPE t_chunk IS TABLE OF VARCHAR2(4000) INDEX BY PLS_INTEGER;
            v_chunk        t_chunk;
            v_str          VARCHAR2(4000) := RTRIM(pi_release_ddl);
            v_no_of_chunks PLS_INTEGER;
            v_pos          PLS_INTEGER;
          BEGIN
            v_no_of_chunks := regexp_count(v_str, g_release_ddl_delimiter);
            IF v_no_of_chunks = 0
            THEN
              v_str          := v_str || g_release_ddl_delimiter;
              v_no_of_chunks := 1;
            END IF;
            v_pos := instr(v_str, g_release_ddl_delimiter, 1, 1);
            FOR i IN 1 .. v_no_of_chunks LOOP
              v_chunk(i) := substr(v_str, 1, v_pos - 1);
              v_str := substr(v_str, v_pos + 1, length(v_str));
              v_pos := instr(v_str, g_release_ddl_delimiter, 1, 1);
              IF v_pos = 0
              THEN
                v_chunk(i + 1) := v_str;
              END IF;
            END LOOP;
            FOR x IN 1 .. v_chunk.count LOOP
              logger_pkg.debug('Releasing object: ' || pi_object_rec.object_name ||
                               ' source: ' || pi_object_rec.source_name || ' with DDL: ' || v_chunk(x));
              EXECUTE IMMEDIATE v_chunk(x);
            END LOOP;
          END;
        END IF;
        
      WHEN pi_object_rec.refresh_method = g_procedure_only_method THEN
        IF pi_release_ddl IS NULL
        THEN
          logger_pkg.debug('Object: ' || pi_object_rec.object_name ||
                           ' source: ' || pi_object_rec.source_name || ' has no release DDL.');
        ELSE
          logger_pkg.warn('Release DDL for object: ' || pi_object_rec.object_name ||
                          ' source: ' || pi_object_rec.source_name || ' unused.');
        END IF;
      
      ELSE
        /* This should not occur.  Probably caused by bad data in LEGO_REFRESH.refresh_method.
        Examine check constraint lego_refresh_rm_ck.  */
        logger_pkg.error('Unknown refresh type for object: ' ||
                         pi_object_rec.object_name || ' source: ' || pi_object_rec.source_name);
    END CASE;
    
    logger_pkg.set_code_location('release_me updating refresh metadata');
    logger_pkg.debug('Updating lego_refresh_history for object: ' ||
                     pi_object_rec.object_name || ' source: ' || pi_object_rec.source_name);

    UPDATE lego_refresh_history
       SET status      = g_job_status_released
     WHERE object_name = pi_refresh_object
       AND job_runtime = pi_runtime
       AND source_name = pi_source;
    
    COMMIT;  
    logger_pkg.info('release_me complete.');
    
  EXCEPTION
    WHEN OTHERS THEN
      IF gv_error_stack IS NULL
      THEN
        gv_error_stack := SQLERRM || chr(10) ||
                          dbms_utility.format_error_backtrace;
      END IF;
    
      log_and_email_fatal_error(pi_top_level_proc => 'RELEASE_ME',
                                pi_error_message  => gv_error_stack);

      logger_pkg.unset_source(v_source);
      RAISE;
  END release_me;
 
   --------------------------------------------------------------------------------
  PROCEDURE refresh_object(pi_refresh_object IN lego_refresh.object_name%TYPE,
                           pi_source         IN lego_refresh.source_name%TYPE,
                           pi_runtime        IN TIMESTAMP,
                           pi_refresh_scn    IN NUMBER) IS
    /* This procedure is called by the scheduler.  There will be many instances of 
    this running simultaneously - one for every object to be refreshed.  */
    v_source                  VARCHAR2(61) := g_source || '.refresh_object';
    v_object_rec              lego_refresh%ROWTYPE;
    v_sleep_counter           NUMBER := 0;
    v_object_timeout          NUMBER;
    v_loop_status             VARCHAR2(20);
    v_log_id                  lego_refresh_history.dbms_scheduler_log_id%TYPE;
    v_refreshed_table         lego_refresh_history.toggle_refreshed_table%TYPE := NULL;
    v_release_ddl             VARCHAR2(4000) := NULL;
  
    FUNCTION relies_on_object_status (
      fi_runtime   IN TIMESTAMP,
      fi_source    IN VARCHAR2,
      fi_object    IN VARCHAR2
    )
    RETURN VARCHAR2 
    IS
      lv_relies_on_cnt              NUMBER;
      lv_completed_cnt              NUMBER;
      lv_errored_ct                 NUMBER;
      lv_current_active_refresh_cnt NUMBER;
      lv_result                     VARCHAR2(14);

    BEGIN
      /* Look at the refresh status of the legos which need to run before our lego. (if any) */
        WITH these_go_first
          AS ( SELECT lrd.relies_on_object_name, 
                      lrd.relies_on_source_name
                 FROM lego_refresh_dependency lrd 
                START WITH (lrd.object_name = fi_object AND lrd.source_name = fi_source)
              CONNECT BY PRIOR lrd.relies_on_object_name = object_name
                           AND lrd.relies_on_source_name = source_name
             )
      SELECT COUNT(*)   AS relies_on_lego_cnt,
             COUNT(CASE 
                     WHEN status = g_job_status_released THEN 'x' 
                   END) AS relies_on_lego_completed_cnt,
             COUNT(CASE 
                     WHEN status IN (g_job_status_error, g_job_status_parent_error, g_job_status_timeout, g_job_status_stopped) 
                       THEN 'x' 
                   END) AS relies_on_lego_errored_cnt
        INTO lv_relies_on_cnt, lv_completed_cnt, lv_errored_ct                   
        FROM ( SELECT t.relies_on_object_name,
                      t.relies_on_source_name,
                      lrh.status
                 FROM lego_refresh_history lrh,
                      these_go_first t
                WHERE lrh.object_name = t.relies_on_object_name
                  AND lrh.source_name = t.relies_on_source_name
                  AND lrh.job_runtime = fi_runtime
             );

      IF g_job_governor_cnt = 0
      THEN
        /* "governer" is off. */
        CASE
          WHEN lv_errored_ct > 0
            /* failure in one or more required legos */
            THEN lv_result := 'parent failure';

          WHEN lv_relies_on_cnt = lv_completed_cnt
            /* all prereqs completed (or none exist) */
            THEN lv_result := 'OK to start';

          ELSE
            /* not all prereqs are complete yet. */
            lv_result := 'wait';

        END CASE;
      ELSE
        /* "governor" is on.  Need to find out how many legos are 
           running at this moment and take that into account. */
        SELECT count(*) 
          INTO lv_current_active_refresh_cnt
          FROM lego_refresh_history lrh
         WHERE lrh.job_runtime = fi_runtime
           AND lrh.status = g_job_status_started;  -- this is the status of jobs "actively" refreshing (not waiting - but running SQL)
           
        CASE
          WHEN lv_errored_ct > 0
            /* failure in one or more required legos */
            THEN lv_result := 'parent failure';

          WHEN lv_relies_on_cnt = lv_completed_cnt AND lv_current_active_refresh_cnt < g_job_governor_cnt
            /* all prereqs completed (or none exist) and we are under the limit. */
            THEN lv_result := 'OK to start';

          WHEN lv_relies_on_cnt = lv_completed_cnt AND lv_current_active_refresh_cnt >= g_job_governor_cnt
            /* all prereqs completed (or none exist), but we are over the limit. */
            THEN lv_result := 'governor limit';

          ELSE
            /* not all prereqs are complete yet. */
            lv_result := 'wait';

        END CASE;
      END IF;  --governator on  
      
      RETURN lv_result;
      
    END relies_on_object_status;    

  BEGIN
    initialize_parameters(TRUE);
    logger_pkg.set_source(v_source);
    logger_pkg.set_code_location('refresh_object');
  
    /*  sleep for a bit to ensure that all jobs have rows in lego_refresh_history before first one starts. */
    dbms_lock.sleep(5);
  
    /* I choose to look up this information rather than passing it in so that this procedure 
    may be run stand-alone.  We can select * since we declared the variable with the %ROWTYPE
    attribute above.  There is no error-handling for this select since we are selecting via 
    table PK and we want the process to terminate if the select fails. */
    logger_pkg.debug('Get metadata for object: ' || pi_refresh_object);
    SELECT *
      INTO v_object_rec
      FROM lego_refresh
     WHERE object_name = pi_refresh_object
       AND source_name = pi_source;
  
    /* Get the log_id information from the user_scheduler_running_jobs table.  This should
    succeed since we know the job is running (we are here, after all!).  But since strange 
    things are known to sometimes occur, I've wrapped this select with an error handler. 
    The trunc is there since log_id has a fractional component in 11.2.0.3  */
    /* Had to wrap this query inside execute immediate since the rj.LOG_ID column does NOT EXIST
    in oracle 11.2.0.1 databases and most developer workstation DBs are on 11.2.0.1.  The error 
    handler will ensure this column will be NULL in those databases.  So the LEGO_REFRESH_ALL_VW 
    and LEGO_REFRESH_CURRENT_VW views will not work there.  Tough cookies!  */ 
    BEGIN
      EXECUTE IMMEDIATE 'SELECT trunc(rj.log_id)' ||
                        '  FROM user_scheduler_running_jobs rj,' ||
                        '       user_scheduler_job_args ja1,' ||
                        '       user_scheduler_job_args ja2' ||
                        ' WHERE rj.job_name = ja1.job_name' || 
                        '   AND ja1.argument_name = ''REFRESH_OBJECT_NAME''' ||
                        '   AND ja1.value = :1' ||
                        '   AND rj.job_name = ja2.job_name' || 
                        '   AND ja2.argument_name = ''SOURCE''' ||
                        '   AND ja2.value = :2'
         INTO v_log_id
        USING pi_refresh_object, pi_source;
    EXCEPTION
      WHEN OTHERS THEN   --catch ORA-00904 on 11.2.0.1 databases and no_data_found in weird cases.
        v_log_id := NULL;
    END;
  
    UPDATE lego_refresh_history
       SET dbms_scheduler_log_id = v_log_id,
           queue_start_time      = sys_extract_utc(systimestamp)
     WHERE object_name = pi_refresh_object
       AND job_runtime = pi_runtime
       AND source_name = pi_source;
  
    COMMIT;
  
    /* Set wait timeout appropriately. */
    v_object_timeout := g_refresh_timeout_interval;
    
    /* Here we wait.  We will wait until one of the following is true:
       1. There are no other legos this lego depends on.
       2. All legos we depend on are released.
       3. A lego that we depend on fails.
       4. A timeout occurs.  (set by g_timeout_interval)  */
    logger_pkg.set_code_location('refresh_object - waiting to start');
    v_loop_status := relies_on_object_status(fi_runtime => pi_runtime,
                                             fi_source  => pi_source,
                                             fi_object  => pi_refresh_object);
    logger_pkg.debug('Waiting to start refresh for: ' || pi_refresh_object ||
                     ' Relies on object status is: ' || v_loop_status);
  
    WHILE (v_sleep_counter <= v_object_timeout AND v_loop_status IN('wait','governor limit')) LOOP
    
      dbms_lock.sleep(g_polling_interval);
      v_sleep_counter := v_sleep_counter + g_polling_interval;
      v_loop_status   := relies_on_object_status(fi_runtime => pi_runtime,
                                                 fi_source  => pi_source,
                                                 fi_object  => pi_refresh_object);
      logger_pkg.debug('Waiting to start ' || pi_refresh_object ||
                       ' source: ' || pi_source ||
                       '.  Waited ' || to_char(v_sleep_counter) ||
                       ' seconds so far.  Relies on object status is: ' ||
                       v_loop_status);
    END LOOP;
  
    /* Out of the loop.  Was it due to a timeout or an error, or are we ready to run?  */
    IF v_sleep_counter > v_object_timeout
    THEN
      update_history_table(pi_refresh_object,
                           pi_runtime,
                           pi_source,
                           g_job_status_timeout);
      raise_application_error(-20002,
                              'refresh_object timeout after waiting ' || v_sleep_counter || 
                              ' seconds to refresh ' || pi_refresh_object ||
                              ' source: ' || pi_source);
    END IF;
  
    IF v_loop_status = 'parent failure'
    THEN
      /* Failure in a parent object.  Do not refresh. 
      We could choose to raise an error here like we do with timeouts which would lead to 
      child legos sending email when a parent failed.  If we ever decide to do this, just 
      add a "raise_application_error" statement and replace the ELSE below with END IF. */
      logger_pkg.error('Object: ' || pi_refresh_object || ' source: ' || pi_source ||
                       ' did not run due to failure in relied upon object.  Updating lego_refresh_history');
      update_history_table(pi_refresh_object,
                           pi_runtime,
                           pi_source,
                           g_job_status_parent_error);
    
    ELSE
      /*  Start refresh.  */
      logger_pkg.set_code_location('refresh_object start refresh');
    
      UPDATE lego_refresh_history
         SET refresh_start_time = sys_extract_utc(systimestamp),
             status             = g_job_status_started
       WHERE object_name = pi_refresh_object
         AND job_runtime = pi_runtime
         AND source_name = pi_source;
     
      COMMIT;
    
      /* Call appropriate procedure based on refresh_method.  */
      CASE
        WHEN v_object_rec.refresh_method = g_procedure_only_method THEN
          logger_pkg.debug('Starting incremental load for object: ' ||
                           pi_refresh_object || ' source: ' || pi_source);
          procedural_load(pi_refresh_object,
                          pi_runtime,
                          pi_source,
                          v_object_rec.refresh_procedure_name);
          v_refreshed_table := NULL;
          v_release_ddl := NULL;
        
/*        WHEN v_object_rec.refresh_method = g_procedure_release_method THEN
          logger_pkg.debug('Starting procedural load for object: ' || 
                           pi_refresh_object || ' source: ' || pi_source);
          procedural_load_release(pi_refresh_object,
                                  pi_runtime,
                                  pi_source,
                                  v_object_rec.refresh_procedure_name,
                                  v_release_ddl);
          v_refreshed_table := NULL;

        WHEN v_object_rec.refresh_method = g_partition_swap_method THEN
          logger_pkg.debug('Starting partition swap for object: ' ||
                           pi_refresh_object || ' source: ' || pi_source);
          partition_swap(pi_refresh_object,
                         pi_runtime,
                         pi_source,
                         v_object_rec.refresh_sql,
                         v_object_rec.storage_clause,
                         v_object_rec.partition_column_name,
                         v_object_rec.num_partitions_to_swap,
                         v_release_ddl);
          v_refreshed_table := NULL;
*/        
        WHEN v_object_rec.refresh_method IN
             (g_sql_toggle_method, g_proc_toggle_method, g_proc_toggle_args_method) THEN
          logger_pkg.debug('Starting toggle for object: ' ||
                           pi_refresh_object || ' source: ' || pi_source);
          toggle(pi_object_name => pi_refresh_object,
                 pi_refresh_time => pi_runtime,
                 pi_source => pi_source,
                 pi_refresh_scn => pi_refresh_scn,
                 pi_refresh_method => v_object_rec.refresh_method,
                 pi_storage_clause => v_object_rec.storage_clause,
                 pi_partition_clause => v_object_rec.partition_clause,
                 pi_refresh_sql => v_object_rec.refresh_sql,
                 pi_refresh_procedure_name => v_object_rec.refresh_procedure_name,
                 pi_refresh_object_name_1 => v_object_rec.refresh_object_name_1,
                 pi_refresh_object_name_2 => v_object_rec.refresh_object_name_2,
                 pi_synonym_name => v_object_rec.synonym_name,
                 po_release_ddl => v_release_ddl,
                 po_refreshed_table => v_refreshed_table);

        ELSE
          /* If we hit this then there is an unknown refresh_method in LEGO_REFRESH.
          Look at status of check constraint lego_refresh_rm_ck.  */
          logger_pkg.fatal(pi_message => 'Refresh method configuration error for object: ' ||
                                         pi_refresh_object  || ' source: ' || pi_source,
                           pi_error_code => -20008,
                           pi_transaction_result => NULL);
          raise_application_error(-20008,'Refresh method configuration error for object: ' ||
                                         pi_refresh_object  || ' source: ' || pi_source);
      END CASE;
    
      /* Errors during refresh will have raised an unhandled exception and so 
      at this point in the code we are safe to assume there were no errors. */
      logger_pkg.debug('Update lego_refresh and lego_refresh_history for object: ' ||
                       pi_refresh_object || ' source: ' || pi_source);
      
      UPDATE lego_refresh_history
         SET refresh_end_time       = sys_extract_utc(systimestamp),
             status                 = g_job_status_complete,
             error_message          = NULL,
             toggle_refreshed_table = v_refreshed_table
       WHERE object_name = pi_refresh_object
         AND job_runtime = pi_runtime
         AND source_name = pi_source;      
        
      COMMIT;
        
      /* Refresh is complete for this object - release the hounds! */
      release_me (pi_object_rec     => v_object_rec, 
                  pi_refresh_object => pi_refresh_object,
                  pi_source         => pi_source,
                  pi_runtime        => pi_runtime,
                  pi_release_ddl    => v_release_ddl);   

    END IF;  --parent failure or ready to refresh?
  
    logger_pkg.unset_source(v_source);
  
  EXCEPTION
    WHEN OTHERS THEN
      IF gv_error_stack IS NULL
      THEN
        gv_error_stack := SQLERRM || chr(10) ||
                          dbms_utility.format_error_backtrace;
      END IF;
    
      log_and_email_fatal_error(pi_object_name   => pi_refresh_object,
                                pi_error_message => gv_error_stack);
  
      logger_pkg.unset_source(v_source);
      RAISE;
    
  END refresh_object;

  --------------------------------------------------------------------------------
  PROCEDURE refresh_incremental_lego (pi_scheduler_job_name       VARCHAR2,
                                      pi_current_table_name       VARCHAR2,
                                      pi_old_table_name           VARCHAR2,
                                      pi_synonym_name             VARCHAR2,                                                                            
                                      pi_create_new_table_text    CLOB,
                                      pi_proc_call_for_data_load  VARCHAR2,
                                      pi_start_date               TIMESTAMP WITH TIME ZONE,    
                                      pi_drop_old_table           CHAR       DEFAULT 'Y',
                                      pi_is_retry                 CHAR       DEFAULT 'N') IS
                                    
  lv_source                   VARCHAR2(61) := 'refresh_incremental_lego';
  v_tbl_cnt                   PLS_INTEGER  := 0;
  lv_drop_tbl_stmnt           VARCHAR2(100);

  /*****************************************************************************
   ****NOTE**** 
   * It is important to note that along with using this procedure for the first
   * time to do an incremental lego refresh, there is an additional script/step
   * needed to change the existing view which currently points directly to the 
   * incremental table. This script will need to be changed to point the view at 
   * the newly created synonym instead. 
   * 
   ****Below is a sample call script to execute this procedure****
   *
   DECLARE
     lv_scheduler_job_name       VARCHAR2(30)   := 'LEGO_INVOICE_DETAIL_RELOAD';                --DBMS Scheduler Job Name that user chooses - make sure it's 30 char or less
     lv_current_table_name       VARCHAR2(30)   := 'LEGO_INVOICE_DETAIL';                       --Name of the incremental table that we are reloading
     lv_old_table_name           VARCHAR2(30)   := 'LEGO_INVOICE_DETAIL_OLD';                   --Temporary store table name - what reporting will look at while reloading
     lv_synonym_name             VARCHAR2(30)   := 'LEGO_INVOICE_DETAIL_SYN';                   --Name of the synonym that the view will point to                   
     lv_proc_call_for_data_load  VARCHAR2(1000) := q'{lego_util.load_lego_invoice_detail('Y')}';--Procedure call for the incremental load - lego specific
     lv_start_date               TIMESTAMP WITH TIME ZONE  := SYSTIMESTAMP + INTERVAL '2' HOUR; --Date/Time that you want the incremental load to start - should not be sysdate--schedule for 2 hours in the future
     lv_drop_old_table           CHAR(1)        := 'Y';                                         --Indicator as to whether you want to drop the temporary store table
     lv_is_retry                 CHAR(1)        := 'N';                                         --Indicator as to whether this is an incremental load retry
     lv_create_new_table_text    CLOB;

   BEGIN     
     --many java developers and Jason's hypermax have the server on a different timezone - 
     --this will ensure the job is created in the right timezone
     EXECUTE IMMEDIATE 'ALTER SESSION SET TIME_ZONE=DBTIMEZONE';
        lv_create_new_table_text :=
              q'{CREATE TABLE }'||lv_current_table_name||q'{ (
                  INVOICE_ID                      NUMBER,
                  EXTRACT_ID                      VARCHAR2(50 CHAR),
                  MSG_ID                          NUMBER,
                  INVOICE_DETAIL_ID               NUMBER,
                  INVOICE_HEADER_ID               NUMBER,
                  INVOICEABLE_EXPENDITURE_ID      NUMBER,
                  INVOICEABLE_EXPENDITURE_TXN_ID  NUMBER,
                  EXPENSE_REPORT_ID               NUMBER,
                  TIMECARD_ID                     NUMBER,
                  PAYMENT_REQUEST_ID              NUMBER,
                  ...etc
                      )                 
                        PARTITION BY RANGE (INVOICE_DATE)                
                        INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))                
                        (                
                        PARTITION VALUES LESS THAN (TO_DATE('01-JAN-2000','DD-MON-YYYY'))                
                        )
                        }';
   
   
     lego_refresh_mgr_pkg.refresh_incremental_lego 
                          (pi_scheduler_job_name       => lv_scheduler_job_name,
                           pi_current_table_name       => lv_current_table_name,
                           pi_old_table_name           => lv_old_table_name,
                           pi_synonym_name             => lv_synonym_name,                                                                            
                           pi_create_new_table_text    => lv_create_new_table_text,
                           pi_proc_call_for_data_load  => lv_proc_call_for_data_load,   
                           pi_start_date               => lv_start_date,   
                           pi_drop_old_table           => lv_drop_old_table,
                           pi_is_retry                 => lv_is_retry);
    

      
   END;
     
   ****************************************************************************/

BEGIN

  logger_pkg.set_level('DEBUG');
  logger_pkg.set_source(lv_source);
  --write out input parameters to log 
  logger_pkg.debug('pi_refresh_object_name='     ||pi_scheduler_job_name     ||'; '|| --DBMS Scheduler Job Name that user chooses - make sure it's 30 char or less
                   'pi_current_table_name='      ||pi_current_table_name     ||'; '|| --Name of the incremental table that we are reloading
                   'pi_old_table_name='          ||pi_old_table_name         ||'; '|| --Temporary store table name - what reporting will look at while reloading
                   'pi_synonym_name='            ||pi_synonym_name           ||'; '|| --Name of the synonym that the view will point to
                   'pi_proc_call_for_data_load=' ||pi_proc_call_for_data_load||'; '|| --Procedure call for the incremental load - lego specific
                   'pi_start_date='              ||pi_start_date             ||'; '|| --Date/Time that you want the incremental load to start - should not be sysdate
                   'pi_drop_old_table='          ||pi_drop_old_table         ||'; '|| --Indicator as to whether you want to drop the temporary store table
                   'pi_is_retry='                ||pi_is_retry               ||'; '); --Indicator as to whether this is an incremental load retry                 
 
  --make sure there is data already in the current incremental table
  --if there isn't then we obviously haven't refreshed in this schema
  --and don't need to perform this action.
  logger_pkg.set_code_location('Check for data');
  EXECUTE IMMEDIATE 'SELECT COUNT(*) '||
                      'FROM (SELECT NULL '||
                             ' FROM '||pi_current_table_name||
                            ' WHERE rownum < 2)'
                       INTO v_tbl_cnt;
  
  logger_pkg.debug('v_tbl_cnt='||v_tbl_cnt||' pi_is_retry='||pi_is_retry);
  --if this is a retry than it's possible there is no data in the new table - perhaps the load failed right out of the gate.
  --In this case, continue on even if there is no data in the table.  
  IF v_tbl_cnt > 0 OR pi_is_retry = 'Y' THEN  
  
    --It's possible that your incremental load failed.  In that case, you can submit the same script as the initial one but with pi_is_retry = 'Y'.
    --In this way, the logic will skip right down to the incremental load.
    IF pi_is_retry = 'N' THEN
  
      logger_pkg.set_code_location('Rename table, create synonym, create new table');
    
      --rename the current table to something else.  this new table will be the temporary store 
      --that the view will point to so that reporting can continue while the new table is 
      --reloaded
      EXECUTE IMMEDIATE 'RENAME '||pi_current_table_name||' TO '||pi_old_table_name;
    
      --point the synonym to the temporary store table
      EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM '||pi_synonym_name||' FOR '||pi_old_table_name;
  
      --create the new table with the new/changed columns or whatever changes are occurring
      logger_pkg.debug(pi_create_new_table_text);
      EXECUTE IMMEDIATE pi_create_new_table_text;
   
    END IF;
    
    --create a drop statement if the input parameter indicates the desire to drop 
    IF pi_drop_old_table = 'Y' THEN    
      lv_drop_tbl_stmnt := 'EXECUTE IMMEDIATE ''DROP TABLE '||pi_old_table_name||''';';  
    END IF;
  
    logger_pkg.set_code_location('Call DBMS_SCHEDULER to create job for the incremental reload');
    logger_pkg.debug('Start Date of Job will be: '||pi_start_date);
    --Create a job to perform the data reload into the new table, repoint the synonym and drop the old table

    DBMS_SCHEDULER.CREATE_JOB (
         job_name             => pi_scheduler_job_name,
         job_type             => 'PLSQL_BLOCK',
         job_action           => 'BEGIN '||
                                    pi_proc_call_for_data_load||'; '||
                                    'EXECUTE IMMEDIATE ''CREATE OR REPLACE SYNONYM '||pi_synonym_name||' FOR '||pi_current_table_name||''';'||
                                    lv_drop_tbl_stmnt||' '||
                                 'END;',
         start_date           =>  pi_start_date,
         enabled              =>  TRUE,
         comments             => 'Incremental Reload for '||pi_scheduler_job_name||' - this will take a while'); 
  
  ELSE --in this case, it is true that there is no data in the incremental table and this is not a retry,
       --therefore, we want to simply drop the table and recreate it so the new structure exists.
       --since there was no data in the original table, we do not need to reload it.
    EXECUTE IMMEDIATE 'DROP TABLE '||pi_current_table_name;  
    
    --create the new table with the new/changed columns or whatever changes are occurring
    logger_pkg.debug(pi_create_new_table_text);
    EXECUTE IMMEDIATE pi_create_new_table_text; 
    
    --point the synonym to the original, current table
    EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM '||pi_synonym_name||' FOR '||pi_current_table_name;      
  
  END IF;
  
END refresh_incremental_lego;
  
END lego_refresh_mgr_pkg;
/
