CREATE OR REPLACE PACKAGE BODY logger_pkg IS
   -------------------------------------------------------------------------------
   --
   --   Version 2.0
   --
   -------------------------------------------------------------------------------
   --  This owner of this package needs the following explicit grants executed as SYS:
   --      GRANT SELECT ON gv_$mystat TO owner_name;
   --      GRANT SELECT ON gv_$session TO owner_name;
   --      GRANT SELECT ON v_$mystat TO owner_name;
   --      GRANT SELECT ON v_$session TO owner_name;
   --      GRANT SELECT ON v_$instance TO owner_name;
   --
   --  Updates don't occur without a prior call to SET_SOURCE.
   -------------------------------------------------------------------------------
   --
   -- Latest Changes Include:
   -- 03/02/2012 - Updated to include Millisecond precision, and new column naming.
   --
   --
   -------------------------------------------------------------------------------
   g_level                   processing_log.trace_level%TYPE := c_level_error;
   g_output                  processing_log.trace_level%TYPE := c_output_both;
   g_initialized_flag        BOOLEAN := FALSE;
   gc_curr_schema   CONSTANT VARCHAR2 (30) := SYS_CONTEXT ('USERENV', 'CURRENT_SCHEMA');

   -------------------------------------------------------------------------------

   TYPE session_info_rec IS RECORD
   (
      sid             processing_log.sid%TYPE,
      serial#         processing_log.serial#%TYPE,
      username        processing_log.username%TYPE,
      osuser          processing_log.osuser%TYPE,
      instance_name   processing_log.instance_name%TYPE
   );

   g_session_info_rec        session_info_rec;

   -------------------------------------------------------------------------------
   TYPE call_entry_rec IS RECORD
   (
      log_guid        RAW (16),
      source          processing_log.source%TYPE,
      code_location   processing_log.code_location%TYPE,
      init_console    BOOLEAN
   );

   TYPE t_call_stack IS TABLE OF call_entry_rec;

   g_call_stack              t_call_stack := t_call_stack ();

   -------------------------------------------------------------------------------
   PROCEDURE push_to_call_stack (pi_source IN processing_log.source%TYPE) IS
      v_call_entry   call_entry_rec;
   BEGIN
      v_call_entry.log_guid := NULL;
      v_call_entry.source := pi_source;
      v_call_entry.code_location := NULL;
      v_call_entry.init_console := TRUE;
      g_call_stack.EXTEND (1);
      g_call_stack (g_call_stack.LAST) := v_call_entry;
   END push_to_call_stack;

   -------------------------------------------------------------------------------
   PROCEDURE pop_from_call_stack IS
      v_call_entry   call_entry_rec;
   BEGIN
      IF g_call_stack.COUNT > 0 THEN
         v_call_entry := g_call_stack (g_call_stack.LAST);
         g_call_stack.TRIM (1);
      END IF;
   END pop_from_call_stack;

   -------------------------------------------------------------------------------
   FUNCTION get_stack_info (pi_position IN NUMBER)
      RETURN call_entry_rec IS
      v_call_entry   call_entry_rec;
   BEGIN
      IF g_call_stack.EXISTS (pi_position) THEN
         v_call_entry := g_call_stack (pi_position);
      ELSE
         v_call_entry.log_guid := NULL;
         v_call_entry.source := 'UNKNOWN';
         v_call_entry.code_location := 'UNKNOWN';
      END IF;

      RETURN v_call_entry;
   END get_stack_info;

   -------------------------------------------------------------------------------
   PROCEDURE set_level (pi_level IN NUMBER) IS
   BEGIN
      g_level := pi_level;
   END set_level;

   -------------------------------------------------------------------------------
   PROCEDURE set_level (pi_level IN VARCHAR2) IS
   BEGIN
      CASE
         WHEN pi_level = c_level_all_str THEN
            g_level := c_level_all;
         WHEN pi_level = c_level_debug_str THEN
            g_level := c_level_debug;
         WHEN pi_level = c_level_info_str THEN
            g_level := c_level_info;
         WHEN pi_level = c_level_warn_str THEN
            g_level := c_level_warn;
         WHEN pi_level = c_level_error_str THEN
            g_level := c_level_error;
         WHEN pi_level = c_level_fatal_str THEN
            g_level := c_level_fatal;
         WHEN pi_level = c_level_none_str THEN
            g_level := c_level_none;
         ELSE
            g_level := c_level_debug;
      END CASE;
   END set_level;

   -------------------------------------------------------------------------------
   FUNCTION get_level
      RETURN NUMBER IS
   BEGIN
      RETURN g_level;
   END get_level;

   -------------------------------------------------------------------------------
   PROCEDURE set_output (pi_output IN VARCHAR2) IS
   BEGIN
      g_output := pi_output;
   END set_output;

   -------------------------------------------------------------------------------
   FUNCTION get_output
      RETURN VARCHAR2 IS
   BEGIN
      RETURN g_output;
   END;

   -------------------------------------------------------------------------------
   PROCEDURE set_log_guid (pi_log_guid IN RAW) IS
   BEGIN
      IF g_call_stack.EXISTS (g_call_stack.LAST) THEN
         g_call_stack (g_call_stack.LAST).log_guid := pi_log_guid;
      END IF;
   END set_log_guid;

   -------------------------------------------------------------------------------
   FUNCTION get_log_guid
      RETURN RAW IS
      v_call_entry   call_entry_rec;
   BEGIN
      v_call_entry := get_stack_info (g_call_stack.LAST);
      RETURN v_call_entry.log_guid;
   END get_log_guid;

   -------------------------------------------------------------------------------
   FUNCTION get_parent_log_guid
      RETURN RAW IS
      v_call_entry   call_entry_rec;
   BEGIN
      v_call_entry := get_stack_info (g_call_stack.LAST - 1);
      RETURN v_call_entry.log_guid;
   END get_parent_log_guid;

   -------------------------------------------------------------------------------
   PROCEDURE set_source (pi_source IN VARCHAR2) IS
      v_call_entry   call_entry_rec;
   BEGIN
      v_call_entry := get_stack_info (g_call_stack.LAST);

      IF v_call_entry.source <> pi_source THEN
         push_to_call_stack (pi_source);
      END IF;

      DBMS_APPLICATION_INFO.set_module (pi_source, 'NONE');
   END set_source;

   -------------------------------------------------------------------------------
   PROCEDURE unset_source (pi_source IN VARCHAR2) IS
      v_call_entry   call_entry_rec;
   BEGIN
      v_call_entry := get_stack_info (g_call_stack.LAST);

      IF v_call_entry.source = pi_source THEN
         pop_from_call_stack;
      END IF;
   END unset_source;

   -------------------------------------------------------------------------------
   FUNCTION get_source
      RETURN VARCHAR2 IS
      v_call_entry   call_entry_rec;
   BEGIN
      v_call_entry := get_stack_info (g_call_stack.LAST);
      RETURN v_call_entry.source;
   END get_source;

   -------------------------------------------------------------------------------
   PROCEDURE set_code_location (pi_code_location IN VARCHAR2) IS
   BEGIN
      IF g_call_stack.EXISTS (g_call_stack.LAST) THEN
         g_call_stack (g_call_stack.LAST).code_location := pi_code_location;
         DBMS_APPLICATION_INFO.set_action (pi_code_location);
      END IF;
   END set_code_location;

   -------------------------------------------------------------------------------
   FUNCTION get_code_location
      RETURN VARCHAR2 IS
      v_call_entry   call_entry_rec;
   BEGIN
      v_call_entry := get_stack_info (g_call_stack.LAST);
      RETURN v_call_entry.code_location;
   END get_code_location;

   -------------------------------------------------------------------------------
   PROCEDURE set_init_console (pi_init_console IN BOOLEAN) IS
   BEGIN
      IF g_call_stack.EXISTS (g_call_stack.LAST) THEN
         g_call_stack (g_call_stack.LAST).init_console := pi_init_console;
      END IF;
   END set_init_console;

   -------------------------------------------------------------------------------
   FUNCTION get_init_console
      RETURN BOOLEAN IS
      v_call_entry   call_entry_rec;
   BEGIN
      v_call_entry := get_stack_info (g_call_stack.LAST);
      RETURN v_call_entry.init_console;
   END get_init_console;

   -------------------------------------------------------------------------------
   FUNCTION is_table_output_enabled
      RETURN BOOLEAN IS
   BEGIN
      RETURN g_output <> 'CONSOLE';
   END is_table_output_enabled;

   -------------------------------------------------------------------------------
   FUNCTION is_console_output_enabled
      RETURN BOOLEAN IS
   BEGIN
      RETURN g_output <> 'LOG';
   END is_console_output_enabled;

   -------------------------------------------------------------------------------
   FUNCTION is_debug_enabled
      RETURN BOOLEAN IS
   BEGIN
      RETURN g_level <= c_level_debug;
   END is_debug_enabled;

   -------------------------------------------------------------------------------
   FUNCTION is_info_enabled
      RETURN BOOLEAN IS
   BEGIN
      RETURN g_level <= c_level_info;
   END is_info_enabled;

   -------------------------------------------------------------------------------
   FUNCTION is_warn_enabled
      RETURN BOOLEAN IS
   BEGIN
      RETURN g_level <= c_level_warn;
   END is_warn_enabled;

   -------------------------------------------------------------------------------
   FUNCTION is_error_enabled
      RETURN BOOLEAN IS
   BEGIN
      RETURN g_level <= c_level_error;
   END is_error_enabled;

   -------------------------------------------------------------------------------
   FUNCTION is_fatal_enabled
      RETURN BOOLEAN IS
   BEGIN
      RETURN g_level <= c_level_fatal;
   END is_fatal_enabled;

   -------------------------------------------------------------------------------
   PROCEDURE instantiate_logger IS
   BEGIN
      BEGIN
         -- Check gv$ tables --
         EXECUTE IMMEDIATE
            'SELECT NVL (sid, 0) sid, NVL (serial#, 0) serial#, NVL (username, ''ORACLE'') username, NVL (osuser, ''ORACLE'') osuser FROM gv$session  WHERE sid = (SELECT sid FROM gv$mystat WHERE ROWNUM = 1)'
            INTO g_session_info_rec.sid, g_session_info_rec.serial#, g_session_info_rec.username, g_session_info_rec.osuser;
      EXCEPTION
         WHEN OTHERS THEN
            BEGIN
               -- Check v$ tables --
               EXECUTE IMMEDIATE
                  'SELECT NVL (sid, 0) sid, NVL (serial#, 0) serial#, NVL (username, ''ORACLE'') username, NVL (osuser, ''ORACLE'') osuser FROM v$session  WHERE sid = (SELECT sid FROM v$mystat WHERE ROWNUM = 1)'
                  INTO g_session_info_rec.sid, g_session_info_rec.serial#, g_session_info_rec.username, g_session_info_rec.osuser;
            EXCEPTION
               WHEN OTHERS THEN
                  -- No access to the v$ tables, so use the defaults --
                  g_session_info_rec.sid := 0;
                  g_session_info_rec.serial# := 0;
                  g_session_info_rec.username := 'ORACLE';
                  g_session_info_rec.osuser := 'ORACLE';
            END;
      END;

      BEGIN
         -- Get Instance Name --
         EXECUTE IMMEDIATE 'SELECT instance_name FROM V$INSTANCE' INTO g_session_info_rec.instance_name;
      EXCEPTION
         WHEN OTHERS THEN
            g_session_info_rec.instance_name := 'UNKNOWN';
      END;

      WHILE g_call_stack.COUNT > 0 LOOP
         pop_from_call_stack;
      END LOOP;

      set_source ('DEFAULT');
      g_initialized_flag := TRUE;
   END instantiate_logger;

   -------------------------------------------------------------------------------
   PROCEDURE write_to_console (pi_trace_level     IN processing_log.trace_level%TYPE,
                               pi_message         IN processing_log.MESSAGE%TYPE DEFAULT NULL,
                               pi_source          IN processing_log.source%TYPE DEFAULT NULL,
                               pi_log_time        IN processing_log.start_time%TYPE DEFAULT NULL,
                               pi_code_location   IN processing_log.code_location%TYPE DEFAULT NULL,
                               pi_init_console    IN BOOLEAN DEFAULT NULL) IS
      v_source          processing_log.source%TYPE := NULL;
      v_code_location   processing_log.code_location%TYPE := NULL;
      v_log_time        processing_log.start_time%TYPE := NULL;
      v_trace_level     processing_log.trace_level%TYPE := NULL;
      v_message         processing_log.MESSAGE%TYPE := NULL;
   BEGIN
      v_source := TRIM (NVL (pi_source, get_source));
      v_code_location := TRIM (NVL (pi_code_location, get_code_location));
      v_log_time := NVL (pi_log_time, SYS_EXTRACT_UTC (SYSTIMESTAMP));
      v_trace_level := RPAD (NVL (pi_trace_level, 'UNKNOWN'), 12, ' ');
      v_message := NVL (pi_message, 'NO MESSAGE');

      IF NVL (pi_init_console, get_init_console) THEN
         DBMS_OUTPUT.put_line ('');
         DBMS_OUTPUT.put_line ('');
         DBMS_OUTPUT.put_line ('EXECUTION BLOCK: ' || v_source || '.' || v_code_location);
         DBMS_OUTPUT.put_line ('');
         DBMS_OUTPUT.put_line (RPAD ('TRACE_LEVEL', 14, ' ') || RPAD ('TIMESTAMP', 22, ' ') || 'MESSAGE');
         DBMS_OUTPUT.put_line ('--------------------------------------------------------------------------------');
         set_init_console (FALSE);
      END IF;

      DBMS_OUTPUT.put_line (
         SUBSTR (v_trace_level || ' | ' || TO_CHAR (v_log_time, 'MM/DD/YYYY HH24:MI:SS') || ' | ' || v_message, 1, 255));
   EXCEPTION
      WHEN OTHERS THEN
         NULL;
   END write_to_console;

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
                           pi_message_clob         IN     processing_log.message_clob%TYPE) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      IF pio_log_guid IS NULL THEN
         IF NOT g_initialized_flag THEN
            instantiate_logger;
         END IF;

         pio_log_guid := SYS_GUID ();

         INSERT INTO processing_log (log_guid,
                                     trace_level,
                                     instance_name,
                                     sid,
                                     serial#,
                                     username,
                                     osuser,
                                     source,
                                     start_time,
                                     parent_log_guid,
                                     transaction_result,
                                     ERROR_CODE,
                                     code_location,
                                     MESSAGE,
                                     message_clob)
              VALUES (
                        pio_log_guid,
                        NVL (pi_trace_level, 'UNKNOWN'),
                        g_session_info_rec.instance_name,
                        g_session_info_rec.sid,
                        g_session_info_rec.serial#,
                        g_session_info_rec.username,
                        g_session_info_rec.osuser,
                        pi_source,
                        pi_log_time,
                        pi_parent_log_guid,
                        pi_transaction_result,
                        pi_error_code,
                        pi_code_location,
                        pi_message,
                        pi_message_clob);
      ELSE
         UPDATE processing_log
            SET trace_level = pi_trace_level,
                end_time = pi_log_time,
                transaction_result = pi_transaction_result,
                ERROR_CODE = pi_error_code,
                code_location = pi_code_location,
                MESSAGE = pi_message,
                message_clob = pi_message_clob
          WHERE log_guid = pio_log_guid;
      END IF;

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
   END write_to_log;

   -------------------------------------------------------------------------------
   PROCEDURE LOG (pi_trace_level          IN processing_log.trace_level%TYPE,
                  pi_transaction_result   IN processing_log.transaction_result%TYPE,
                  pi_error_code           IN processing_log.ERROR_CODE%TYPE,
                  pi_message              IN processing_log.MESSAGE%TYPE,
                  pi_update_log           IN BOOLEAN DEFAULT FALSE) IS
      v_call_entry   call_entry_rec;
      v_message      processing_log.MESSAGE%TYPE := NULL;
   BEGIN
      IF is_console_output_enabled THEN
         IF pi_error_code IS NULL THEN
            v_message := pi_message;
         ELSE
            v_message := pi_error_code || ': ' || pi_message;
         END IF;

         write_to_console (pi_trace_level, v_message);
      END IF;

      IF is_table_output_enabled THEN
         v_call_entry := get_stack_info (g_call_stack.LAST);

         IF NOT pi_update_log THEN
            v_call_entry.log_guid := NULL;
         END IF;

         write_to_log (v_call_entry.log_guid,
                       pi_trace_level,
                       v_call_entry.source,
                       get_parent_log_guid,
                       SYS_EXTRACT_UTC (SYSTIMESTAMP),
                       pi_transaction_result,
                       pi_error_code,
                       v_call_entry.code_location,
                       pi_message,
                       NULL);
         set_log_guid (v_call_entry.log_guid);
      END IF;
   END LOG;

   -------------------------------------------------------------------------------
   PROCEDURE LOG (pi_trace_level          IN processing_log.trace_level%TYPE,
                  pi_transaction_result   IN processing_log.transaction_result%TYPE,
                  pi_error_code           IN processing_log.ERROR_CODE%TYPE,
                  pi_message_clob         IN CLOB,
                  pi_update_log           IN BOOLEAN DEFAULT FALSE) IS
      v_call_entry   call_entry_rec;
      v_message      processing_log.MESSAGE%TYPE := NULL;
   BEGIN
      IF is_console_output_enabled THEN
         IF pi_error_code IS NULL THEN
            v_message := DBMS_LOB.SUBSTR (pi_message_clob, 200, 1);
         ELSE
            v_message := pi_error_code || ': ' || DBMS_LOB.SUBSTR (pi_message_clob, 200, 1);
         END IF;

         write_to_console (pi_trace_level, v_message);
      END IF;

      IF is_table_output_enabled THEN
         v_call_entry := get_stack_info (g_call_stack.LAST);

         IF NOT pi_update_log THEN
            v_call_entry.log_guid := NULL;
         END IF;

         write_to_log (v_call_entry.log_guid,
                       pi_trace_level,
                       v_call_entry.source,
                       get_parent_log_guid,
                       SYS_EXTRACT_UTC (SYSTIMESTAMP),
                       pi_transaction_result,
                       pi_error_code,
                       v_call_entry.code_location,
                       DBMS_LOB.SUBSTR (pi_message_clob, 2000, 1),
                       pi_message_clob);
         set_log_guid (v_call_entry.log_guid);
      END IF;
   END LOG;


   -------------------------------------------------------------------------------
   PROCEDURE debug (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_debug_enabled THEN
         LOG (c_level_debug_str,
              NULL,
              NULL,
              pi_message,
              pi_update_log);
      END IF;
   END debug;

   -------------------------------------------------------------------------------
   PROCEDURE debug (pi_message_clob IN CLOB, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_debug_enabled THEN
         LOG (c_level_debug_str,
              NULL,
              NULL,
              pi_message_clob,
              pi_update_log);
      END IF;
   END debug;

   -------------------------------------------------------------------------------
   PROCEDURE info (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_info_enabled THEN
         LOG (c_level_info_str,
              NULL,
              NULL,
              pi_message,
              pi_update_log);
      END IF;
   END info;

   -------------------------------------------------------------------------------
   PROCEDURE info (pi_message_clob IN CLOB, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_info_enabled THEN
         LOG (c_level_info_str,
              NULL,
              NULL,
              pi_message_clob,
              pi_update_log);
      END IF;
   END info;

   -------------------------------------------------------------------------------
   PROCEDURE warn (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_warn_enabled THEN
         LOG (c_level_warn_str,
              NULL,
              NULL,
              pi_message,
              pi_update_log);
      END IF;
   END warn;

   -------------------------------------------------------------------------------
   PROCEDURE warn (pi_message_clob IN CLOB, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_warn_enabled THEN
         LOG (c_level_warn_str,
              NULL,
              NULL,
              pi_message_clob,
              pi_update_log);
      END IF;
   END warn;

   -------------------------------------------------------------------------------
   PROCEDURE error (pi_transaction_result   IN VARCHAR2,
                    pi_error_code           IN NUMBER,
                    pi_message              IN VARCHAR2,
                    pi_update_log           IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_error_enabled THEN
         LOG (c_level_error_str,
              pi_transaction_result,
              pi_error_code,
              pi_message,
              pi_update_log);
      END IF;
   END error;

   -------------------------------------------------------------------------------
   PROCEDURE error (pi_transaction_result   IN VARCHAR2,
                    pi_error_code           IN NUMBER,
                    pi_message_clob         IN CLOB,
                    pi_update_log           IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_error_enabled THEN
         LOG (c_level_error_str,
              pi_transaction_result,
              pi_error_code,
              pi_message_clob,
              pi_update_log);
      END IF;
   END error;

   -------------------------------------------------------------------------------
   PROCEDURE error (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      error ('NONE', NULL, pi_message, pi_update_log);
   END error;

   -------------------------------------------------------------------------------
   PROCEDURE error (pi_message_clob IN CLOB, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      error ('NONE', NULL, pi_message_clob, pi_update_log);
   END error;

   -------------------------------------------------------------------------------
   PROCEDURE fatal (pi_transaction_result   IN VARCHAR2,
                    pi_error_code           IN NUMBER,
                    pi_message              IN VARCHAR2,
                    pi_update_log           IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_fatal_enabled THEN
         LOG (c_level_fatal_str,
              pi_transaction_result,
              pi_error_code,
              pi_message,
              pi_update_log);
      END IF;
   END fatal;

   -------------------------------------------------------------------------------
   PROCEDURE fatal (pi_transaction_result   IN VARCHAR2,
                    pi_error_code           IN NUMBER,
                    pi_message_clob         IN CLOB,
                    pi_update_log           IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      IF is_fatal_enabled THEN
         LOG (c_level_fatal_str,
              pi_transaction_result,
              pi_error_code,
              pi_message_clob,
              pi_update_log);
      END IF;
   END fatal;

   -------------------------------------------------------------------------------
   PROCEDURE fatal (pi_message IN VARCHAR2, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      fatal ('NONE', NULL, pi_message, pi_update_log);
   END fatal;

   -------------------------------------------------------------------------------
   PROCEDURE fatal (pi_message_clob IN CLOB, pi_update_log IN BOOLEAN DEFAULT FALSE) IS
   BEGIN
      fatal ('NONE', NULL, pi_message_clob, pi_update_log);
   END fatal;

   -------------------------------------------------------------------------------
   PROCEDURE truncate_log (pi_start_date IN DATE DEFAULT TRUNC (SYSDATE) - 7) IS
   BEGIN
      --  Partitioning Not Currently supported, so performing Delete instead.
      DELETE FROM processing_log
            WHERE start_time <= pi_start_date;

      COMMIT;
   END truncate_log;

   -------------------------------------------------------------------------------
   PROCEDURE partition_prune (pi_start_date IN DATE DEFAULT ADD_MONTHS (LAST_DAY (TRUNC (SYSDATE)) + 1, -4)) IS
      /*---------------------------------------------------------------------------*\
      || PROCEDURE NAME       : partition_prune
      || AUTHOR               : Erik Clark
      || DATE CREATED         : 02/14/2014
      || PURPOSE              : This procedure auto prune's the processing_log table.
      ||                      : It is called in each deployment in the the post-deployment operations with the default date.
      ||                      : The default date string will keep 3 full months of logs plus the current partial month at deployment time.
      || MODIFICATION HISTORY :
      \*---------------------------------------------------------------------------*/

      v_drop   PLS_INTEGER := 0;
   BEGIN
      FOR x IN (SELECT table_owner,
                       table_name,
                       partition_name,
                       high_value,
                       partition_position
                  FROM all_tab_partitions
                 WHERE table_name = 'PROCESSING_LOG' AND table_owner = gc_curr_schema) LOOP
         IF (TO_DATE (SUBSTR (x.high_value, 11, 10), 'YYYY-MM-DD') <= TRUNC (pi_start_date)) AND x.partition_position != 1 THEN
            IF v_drop = 0 THEN
               EXECUTE IMMEDIATE 'ALTER TABLE PROCESSING_LOG DROP CONSTRAINT PROCESSING_LOG_FK';
            END IF;

            v_drop := v_drop + 1;

            EXECUTE IMMEDIATE
                  'ALTER TABLE '
               || x.table_owner
               || '.'
               || x.table_name
               || ' DROP PARTITION '
               || x.partition_name
               || ' UPDATE GLOBAL INDEXES';
         END IF;
      END LOOP;

      IF v_drop > 0 THEN
         EXECUTE IMMEDIATE 'ALTER TABLE PROCESSING_LOG
                                  ADD CONSTRAINT PROCESSING_LOG_FK FOREIGN KEY (PARENT_LOG_GUID)
                                  REFERENCES PROCESSING_LOG (LOG_GUID)
                                  ON DELETE CASCADE
                                  NOVALIDATE';
      END IF;
   END partition_prune;
-------------------------------------------------------------------------------

END logger_pkg;
/
