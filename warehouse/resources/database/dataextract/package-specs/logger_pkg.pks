CREATE OR REPLACE PACKAGE logger_pkg IS
   -------------------------------------------------------------------------------
   --
   --  Version 2.0
   --
   -------------------------------------------------------------------------------

   c_level_none         CONSTANT NUMBER := 32;
   c_level_fatal        CONSTANT NUMBER := 16;
   c_level_error        CONSTANT NUMBER := 8;
   c_level_warn         CONSTANT NUMBER := 4;
   c_level_info         CONSTANT NUMBER := 2;
   c_level_debug        CONSTANT NUMBER := 1;
   c_level_all          CONSTANT NUMBER := 0;
   c_level_none_str     CONSTANT VARCHAR2 (5) := 'NONE';
   c_level_fatal_str    CONSTANT VARCHAR2 (5) := 'FATAL';
   c_level_error_str    CONSTANT VARCHAR2 (5) := 'ERROR';
   c_level_warn_str     CONSTANT VARCHAR2 (5) := 'WARN';
   c_level_info_str     CONSTANT VARCHAR2 (5) := 'INFO';
   c_level_debug_str    CONSTANT VARCHAR2 (5) := 'DEBUG';
   c_level_all_str      CONSTANT VARCHAR2 (5) := 'ALL';
   c_output_log_table   CONSTANT VARCHAR2 (10) := 'TABLE';
   c_output_console     CONSTANT VARCHAR2 (10) := 'CONSOLE';
   c_output_both        CONSTANT VARCHAR2 (10) := 'BOTH';

   -------------------------------------------------------------------------------
   PROCEDURE set_level (pi_level IN NUMBER);

   -------------------------------------------------------------------------------
   PROCEDURE set_level (pi_level IN VARCHAR2);

   -------------------------------------------------------------------------------
   FUNCTION get_level
      RETURN NUMBER;

   -------------------------------------------------------------------------------
   PROCEDURE set_output (pi_output IN VARCHAR2);

   -------------------------------------------------------------------------------
   FUNCTION get_output
      RETURN VARCHAR2;

   -------------------------------------------------------------------------------
   PROCEDURE set_source (pi_source IN VARCHAR2);

   -------------------------------------------------------------------------------
   FUNCTION get_source
      RETURN VARCHAR2;

   -------------------------------------------------------------------------------
   PROCEDURE unset_source (pi_source IN VARCHAR2);

   -------------------------------------------------------------------------------
   PROCEDURE set_code_location (pi_code_location IN VARCHAR2);

   -------------------------------------------------------------------------------
   FUNCTION get_code_location
      RETURN VARCHAR2;

   -------------------------------------------------------------------------------
   FUNCTION is_console_output_enabled
      RETURN BOOLEAN;

   -------------------------------------------------------------------------------
   FUNCTION is_table_output_enabled
      RETURN BOOLEAN;

   -------------------------------------------------------------------------------
   FUNCTION is_debug_enabled
      RETURN BOOLEAN;

   -------------------------------------------------------------------------------
   FUNCTION is_info_enabled
      RETURN BOOLEAN;

   -------------------------------------------------------------------------------
   FUNCTION is_warn_enabled
      RETURN BOOLEAN;

   -------------------------------------------------------------------------------
   FUNCTION is_error_enabled
      RETURN BOOLEAN;

   -------------------------------------------------------------------------------
   FUNCTION is_fatal_enabled
      RETURN BOOLEAN;

   -------------------------------------------------------------------------------
   PROCEDURE instantiate_logger;

   -------------------------------------------------------------------------------
   PROCEDURE write_to_console (pi_trace_level     IN processing_log.trace_level%TYPE,
                               pi_message         IN processing_log.MESSAGE%TYPE DEFAULT NULL,
                               pi_source          IN processing_log.source%TYPE DEFAULT NULL,
                               pi_log_time        IN processing_log.start_time%TYPE DEFAULT NULL,
                               pi_code_location   IN processing_log.code_location%TYPE DEFAULT NULL,
                               pi_init_console    IN BOOLEAN DEFAULT NULL);

   -------------------------------------------------------------------------------
   PROCEDURE write_to_log (pio_log_guid            IN OUT processing_log.log_guid%TYPE,
                           pi_trace_level          IN     processing_log.trace_level%TYPE,
                           pi_source               IN     processing_log.source%TYPE,
                           pi_parent_log_guid      IN     processing_log.parent_log_guid%TYPE,
                           pi_log_time             IN     processing_log.start_time%TYPE,
                           pi_transaction_result   IN     processing_log.transaction_result%TYPE,
                           pi_error_code           IN     processing_log.ERROR_CODE%TYPE,
                           pi_code_location        IN     processing_log.code_location%TYPE,
                           pi_message              IN     processing_log.MESSAGE%TYPE,
                           pi_message_clob         IN     processing_log.message_clob%TYPE);

   -------------------------------------------------------------------------------
   PROCEDURE LOG (pi_trace_level          IN processing_log.trace_level%TYPE,
                  pi_transaction_result   IN processing_log.transaction_result%TYPE,
                  pi_error_code           IN processing_log.ERROR_CODE%TYPE,
                  pi_message              IN processing_log.MESSAGE%TYPE,
                  pi_update_log           IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE LOG (pi_trace_level          IN processing_log.trace_level%TYPE,
                  pi_transaction_result   IN processing_log.transaction_result%TYPE,
                  pi_error_code           IN processing_log.ERROR_CODE%TYPE,
                  pi_message_clob         IN CLOB,
                  pi_update_log           IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE debug (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE debug (pi_message_clob IN CLOB, pi_update_log IN BOOLEAN DEFAULT FALSE);


   -------------------------------------------------------------------------------
   PROCEDURE info (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE info (pi_message_clob IN CLOB, pi_update_log IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE warn (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE warn (pi_message_clob IN CLOB, pi_update_log IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE error (pi_transaction_result   IN VARCHAR2,
                    pi_error_code           IN NUMBER,
                    pi_message              IN VARCHAR2,
                    pi_update_log           IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE error (pi_transaction_result   IN VARCHAR2,
                    pi_error_code           IN NUMBER,
                    pi_message_clob         IN CLOB,
                    pi_update_log           IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE error (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE fatal (pi_transaction_result   IN VARCHAR2,
                    pi_error_code           IN NUMBER,
                    pi_message              IN VARCHAR2,
                    pi_update_log           IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE fatal (pi_transaction_result   IN VARCHAR2,
                    pi_error_code           IN NUMBER,
                    pi_message_clob         IN CLOB,
                    pi_update_log           IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE fatal (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE fatal (pi_message_clob IN CLOB, pi_update_log IN BOOLEAN DEFAULT FALSE);

   -------------------------------------------------------------------------------
   PROCEDURE truncate_log (pi_start_date IN DATE DEFAULT TRUNC (SYSDATE) - 7);

   -------------------------------------------------------------------------------
   PROCEDURE partition_prune (pi_start_date IN DATE DEFAULT ADD_MONTHS (LAST_DAY (TRUNC (SYSDATE)) + 1, -4));
-------------------------------------------------------------------------------
END logger_pkg;
/
