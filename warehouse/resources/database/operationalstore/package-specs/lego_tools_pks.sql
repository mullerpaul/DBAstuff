CREATE OR REPLACE PACKAGE lego_tools AS
  /******************************************************************************
     NAME:       lego_tools
     PURPOSE:    public functions and procedures to be used by refresh code
  
     REVISIONS:
     Jira       Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
                01/11/2016  Paul Muller      Created this package.
     IQN-33702  10/12/2016  Joe Pullifrone   Added proc, refresh_mv.
     IQN-40224  09/19/2018  Paul Muller      Added some new units and removed obsolete ones.
     IQN-41594  11/06/2018  Paul Muller      New boolean functions get_refresh_run_running and get_refresh_run_hit_error.

  ******************************************************************************/

  --------------------------------------------------------------------------------
  FUNCTION get_lego_parameter_text_value(pi_parameter_name IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION get_lego_parameter_num_value(pi_parameter_name IN VARCHAR2) RETURN NUMBER;

  --------------------------------------------------------------------------------
  FUNCTION get_db_link_status(fi_link_name IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION get_db_link_name(fi_source_name IN lego_source.source_name%TYPE) RETURN VARCHAR2;
  
  FUNCTION get_src_name_short(fi_source_name IN lego_source.source_name%TYPE) RETURN VARCHAR2;

  FUNCTION get_storage_clause(fi_object_name IN lego_refresh.object_name%TYPE,
                              fi_source_name IN lego_refresh.source_name%TYPE) RETURN VARCHAR2;

  FUNCTION get_partition_clause(fi_object_name IN lego_refresh.object_name%TYPE,
                                fi_source_name IN lego_refresh.source_name%TYPE) RETURN VARCHAR2;

  FUNCTION get_synonym_name(fi_object_name IN lego_refresh.object_name%TYPE,
                            fi_source_name IN lego_refresh.source_name%TYPE) RETURN VARCHAR2;
                            
  FUNCTION get_safe_to_start_refresh_flag 
  RETURN BOOLEAN;
  
  FUNCTION get_refresh_run_running(fi_run_timestamp IN lego_refresh_run_history.job_runtime%TYPE)
  RETURN BOOLEAN;

  FUNCTION get_refresh_run_hit_error(fi_run_timestamp IN lego_refresh_run_history.job_runtime%TYPE) 
  RETURN BOOLEAN;

  FUNCTION get_most_recent_ref_as_of_time (
      pi_object_name IN lego_refresh.object_name%TYPE, 
      pi_source_name IN lego_refresh.source_name%TYPE
  )
  RETURN TIMESTAMP;
  
  --------------------------------------------------------------------------------
  PROCEDURE get_remote_db_as_of_info (
      pi_source_name IN  lego_source.source_name%TYPE,
      po_as_of_scn   OUT lego_refresh_run_history.remote_db_as_of_scn%TYPE,
      po_as_of_time  OUT lego_refresh_run_history.remote_db_as_of_time%TYPE
  );
  
  --------------------------------------------------------------------------------
  PROCEDURE repoint_db_link(pi_link_name    IN VARCHAR2,
                            pi_schemaname   IN VARCHAR2,
                            pi_password     IN VARCHAR2,
                            pi_database_sid IN VARCHAR2);

  --------------------------------------------------------------------------------
  PROCEDURE insert_history_parent_row (
      pi_refresh_runtime   IN lego_refresh_run_history.job_runtime%TYPE,
      pi_source_as_of_time IN lego_refresh_run_history.remote_db_as_of_time%TYPE,
      pi_source_as_of_scn  IN lego_refresh_run_history.remote_db_as_of_scn%TYPE,
      pi_caller_id         IN lego_refresh_run_history.caller_name%TYPE,
      pi_latency_input     IN lego_refresh_run_history.allowable_per_lego_latency_min%TYPE
  );
  
  --------------------------------------------------------------------------------
  PROCEDURE drop_running_job(pi_object_name IN lego_refresh.object_name%TYPE,
                             pi_source_name IN lego_refresh.source_name%TYPE);

  PROCEDURE drop_running_job(pi_scheduler_job_name IN VARCHAR2);

  --------------------------------------------------------------------------------
  --PROCEDURE enable_parallel_dml_in_session;

  --------------------------------------------------------------------------------
  PROCEDURE enable_automatic_refresh_job (
      pi_ssc           IN BOOLEAN DEFAULT false,
      pi_conv_search   IN BOOLEAN DEFAULT false,
      pi_dash          IN BOOLEAN DEFAULT false,
      pi_smartview     IN BOOLEAN DEFAULT false,
      pi_invoice       IN BOOLEAN DEFAULT false
  );

  PROCEDURE disable_automatic_refresh_job (
      pi_ssc           IN BOOLEAN DEFAULT false,
      pi_conv_search   IN BOOLEAN DEFAULT false,
      pi_dash          IN BOOLEAN DEFAULT false,
      pi_smartview     IN BOOLEAN DEFAULT false,
      pi_invoice       IN BOOLEAN DEFAULT false
  );

  --------------------------------------------------------------------------------
  PROCEDURE setup_session_logging(
      pi_log_source IN VARCHAR
  );

  --------------------------------------------------------------------------------
  FUNCTION most_recently_loaded_table(i_lego_name   lego_refresh.object_name%TYPE,
                                      i_source_name lego_refresh.source_name%TYPE) RETURN VARCHAR2;
                                      
  --------------------------------------------------------------------------------
  PROCEDURE start_scheduler_job_for_lego (
      pi_object_name   IN VARCHAR2,
      pi_source        IN VARCHAR2,
      pi_job_runtime   IN TIMESTAMP,
      pi_scn           IN NUMBER,
      pi_unique_id     IN NUMBER
  );

  --------------------------------------------------------------------------------
  PROCEDURE ctas(pi_table_name         IN VARCHAR2,
                 pi_stmt_clob          IN CLOB,
                 pi_storage_clause     IN VARCHAR2 DEFAULT NULL,
                 pi_compression_clause IN VARCHAR2 DEFAULT NULL, --can we combine this and storage?
                 pi_tablespace_clause  IN VARCHAR2 DEFAULT NULL,
                 pi_partition_clause   IN VARCHAR2 DEFAULT NULL,
                 pi_iot_flag           IN BOOLEAN DEFAULT FALSE,
                 pi_clobber_flag       IN BOOLEAN DEFAULT TRUE,
                 pi_gather_stats_flag  IN BOOLEAN DEFAULT TRUE,
                 po_row_count          OUT NUMBER);

  --------------------------------------------------------------------------------
  PROCEDURE ctas(pi_table_name         IN VARCHAR2,
                 pi_stmt_clob          IN CLOB,
                 pi_storage_clause     IN VARCHAR2 DEFAULT NULL,
                 pi_compression_clause IN VARCHAR2 DEFAULT NULL, --can we combine this and storage?
                 pi_tablespace_clause  IN VARCHAR2 DEFAULT NULL,
                 pi_partition_clause   IN VARCHAR2 DEFAULT NULL,
                 pi_iot_flag           IN BOOLEAN DEFAULT FALSE,
                 pi_clobber_flag       IN BOOLEAN DEFAULT TRUE,
                 pi_gather_stats_flag  IN BOOLEAN DEFAULT TRUE);
                 
  --------------------------------------------------------------------------------
  FUNCTION replace_placeholders_in_sql(fi_sql_in            IN CLOB,
                                       fi_months_in_refresh IN NUMBER,
                                       fi_db_link_name      IN VARCHAR2,
                                       fi_source_db_scn     IN VARCHAR2,
                                       fi_source_name_short IN VARCHAR2) RETURN CLOB;
  
  --------------------------------------------------------------------------------                 
  PROCEDURE refresh_mv (pi_mv_name  VARCHAR2,
                        pi_method   VARCHAR2,
                        pi_start_ts TIMESTAMP DEFAULT SYSTIMESTAMP);
                        
END lego_tools;
/
