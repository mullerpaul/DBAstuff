DECLARE
  le_table_not_exist EXCEPTION;
  PRAGMA exception_init(le_table_not_exist, -00942);
  le_col_already_exist EXCEPTION;
  PRAGMA exception_init(le_col_already_exist, -01430);
  
  PROCEDURE add_col (pi_table_name IN VARCHAR2) 
  IS
  BEGIN
    EXECUTE IMMEDIATE ('alter table ' || pi_table_name || ' add (user_three_months_login_flag NUMBER)');
  EXCEPTION
    WHEN le_table_not_exist OR le_col_already_exist THEN
      NULL;  -- ignore these errors
  END;
  
BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('IQN-40400 migration');
  logger_pkg.set_code_location('Add dummy column to person lego tables');

  FOR i IN (SELECT refresh_object_name_1 AS table_name
              FROM lego_refresh
             WHERE object_name = 'LEGO_PERSON'
             UNION ALL
            SELECT refresh_object_name_2 AS table_name
              FROM lego_refresh
             WHERE object_name = 'LEGO_PERSON') LOOP

    logger_pkg.info('Adding user_three_months_login_flag column to table ' || i.table_name);
    add_col(i.table_name);
    logger_pkg.info('Adding user_three_months_login_flag column to table ' || i.table_name || ' - complete', TRUE);

  END LOOP;
  
  logger_pkg.unset_source('IQN-40400 migration');
END;
/
  
  
  