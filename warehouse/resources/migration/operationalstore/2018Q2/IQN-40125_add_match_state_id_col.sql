--- add new (empty) column to any MATCH lego toggle tables which exist
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('IQN-40125 migration');
  logger_pkg.set_code_location('Add dummy columns');

  logger_pkg.info('Begin migration script - UPDATE LEGO_REFRESH');
  FOR i IN ( SELECT ut.table_name
               FROM user_tables ut,
                    (SELECT refresh_object_name_1 AS table_name
                       FROM lego_refresh
                      WHERE object_name = 'LEGO_MATCH'
                      UNION ALL
                     SELECT refresh_object_name_2 AS table_name
                       FROM lego_refresh
                      WHERE object_name = 'LEGO_MATCH') tt
              WHERE ut.table_name = tt.table_name) LOOP

    BEGIN
      EXECUTE IMMEDIATE ('ALTER TABLE ' || i.table_name ||
                         ' ADD (match_state_id NUMBER)');
      logger_pkg.info('Added MATCH_STATE_ID column to ' || i.table_name);

    EXCEPTION
      WHEN OTHERS THEN
        /* Log error then ignore it! Normally a bad practice; but its
           OK here due to the nature of these tables. */
        logger_pkg.warn('Could not add MATCH_STATE_ID column to ' || 
                        i.table_name || ' ' || SQLERRM);
    END;
  END LOOP;

  logger_pkg.unset_source('IQN-40125 migration');
END;
/

