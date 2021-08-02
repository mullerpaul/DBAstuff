DECLARE
  le_table_not_exist EXCEPTION;
  PRAGMA exception_init(le_table_not_exist, -00942);
  le_col_already_exist EXCEPTION;
  PRAGMA exception_init(le_col_already_exist, -01430);
  
  lc_source CONSTANT VARCHAR2(30) := 'IQN-40930 migration';

  PROCEDURE add_column (lv_table_name IN VARCHAR)
    IS
  BEGIN
    EXECUTE IMMEDIATE ( 'ALTER TABLE '
                        || lv_table_name
                        || ' ADD (domain_name VARCHAR2(20))' );
  EXCEPTION
    WHEN le_table_not_exist OR le_col_already_exist THEN
      NULL;  -- ignore these errors.
  END add_column;

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source(lc_source);
  logger_pkg.set_code_location('Add dummy domain column to person and msp_user_available_org tables');

  FOR i IN ( SELECT table_name AS table_to_add_column
               FROM user_tables
              WHERE table_name IN ( SELECT refresh_object_name_1 AS table_name
                                      FROM lego_refresh
                                     WHERE object_name IN ('LEGO_PERSON','LEGO_MSP_USER_AVAILABLE_ORG')
                                     UNION ALL
                                    SELECT refresh_object_name_2 AS table_name
                                      FROM lego_refresh
                                     WHERE object_name IN ('LEGO_PERSON','LEGO_MSP_USER_AVAILABLE_ORG')
                                  )
           ) LOOP

    logger_pkg.info('Adding column to ' || i.table_to_add_column);
    add_column(i.table_to_add_column);
    logger_pkg.info('Adding column to ' || i.table_to_add_column || ' - complete.', TRUE);

  END LOOP;
  logger_pkg.unset_source(lc_source);

END;
/


