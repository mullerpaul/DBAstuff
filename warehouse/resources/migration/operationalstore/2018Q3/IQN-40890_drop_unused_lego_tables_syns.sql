DECLARE
  -- I copied logic from src\main\resources\migration\operationalstore\2018Q2\IQN-40222_drop_unused_lego_tables_syns.sql

  -- logging source 
  lc_log_sourcename CONSTANT VARCHAR2(20) := 'IQN-40890 migration';

  -- create an array TYPE to hold the names of the 4 legos we will remove
  TYPE object_names_to_cleanup_array IS
    VARRAY ( 4 ) OF VARCHAR2(30);

  -- now create a variable of that TYPE
  la_objects   object_names_to_cleanup_array;
  
  -- create exceptions
  le_no_such_table EXCEPTION;
  le_no_such_synonym EXCEPTION;
  PRAGMA exception_init ( le_no_such_table,-00942 );
  PRAGMA exception_init ( le_no_such_synonym,-01434 );

  -- helper procedures
  PROCEDURE drop_table (pi_table_name IN VARCHAR2)
    IS
  BEGIN
    EXECUTE IMMEDIATE ( 'DROP TABLE ' || pi_table_name );
    logger_pkg.info('dropped table ' || pi_table_name);
  EXCEPTION
    WHEN le_no_such_table THEN
      NULL;
  END drop_table;

  PROCEDURE drop_synonym (pi_synonym_name IN VARCHAR2)
    IS
  BEGIN
    EXECUTE IMMEDIATE ( 'DROP SYNONYM ' || pi_synonym_name );
    logger_pkg.info('dropped synonym ' || pi_synonym_name);
  EXCEPTION
    WHEN le_no_such_synonym THEN
      NULL;
  END drop_synonym;

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source(lc_log_sourcename);
  logger_pkg.set_code_location('Remove unused legos and their objects');

  logger_pkg.info('Starting script to remove unused lego along with their tables and synonyms.');

  /* Initialize list of legos to remove.  */
  la_objects   := object_names_to_cleanup_array(
    'LEGO_ALL_ORGS_CALENDAR',
    'LEGO_CAC_COLLECTION_HISTORY',
    'LEGO_CAC_HISTORY',
    'LEGO_INVOICE_DETAIL'
  );

  /*  loop through that list of legos and process each in turn */
  FOR i IN la_objects.first..la_objects.last LOOP
    /* For each lego we will:
         1. drop the toggle tables if they exist
         2. drop the synonym if it exists
         3. delete the rows from lego_refresh and its child tables. */
    FOR j IN ( SELECT refresh_object_name_1 AS table_name
                 FROM lego_refresh
                WHERE object_name = la_objects(i)
                  AND refresh_object_name_1 IS NOT NULL
                UNION ALL
               SELECT refresh_object_name_2 AS table_name
                 FROM lego_refresh
                WHERE object_name = la_objects(i)
                  AND refresh_object_name_2 IS NOT NULL) LOOP

      drop_table(pi_table_name => j.table_name);
    END LOOP;
    
    /* Next, the synonyms. */
    FOR k IN ( SELECT synonym_name
                 FROM lego_refresh
                WHERE object_name = la_objects(i)
                  AND synonym_name IS NOT NULL) LOOP

      drop_synonym (pi_synonym_name => k.synonym_name);
    END LOOP;
    
    /* Finally, remove the rows.  Delete from child tables before parent. */
    /* ToDo - Add delete for the refresh_dependency_table!  */
    DELETE FROM lego_refresh_index       WHERE object_name = la_objects(i);
    DELETE FROM lego_refresh_toggle_priv WHERE object_name = la_objects(i);
    DELETE FROM lego_refresh             WHERE object_name = la_objects(i);
    logger_pkg.info('DELETED ' || to_char(SQL%rowcount) || ' row(s) from LEGO_REFRESH for ' || la_objects(i));

  END LOOP;

  COMMIT;  -- most of the work was already committed with all the DDL; but we need to catch those last deletes.
  logger_pkg.unset_source(lc_log_sourcename);

EXCEPTION
  WHEN OTHERS THEN
    /* There are so many strange things that could get us here that there is nothing 
       sensible to do in this handler except log the error and re-raise it. */
    logger_pkg.fatal(pi_transaction_result => NULL,
                     pi_error_code         => SQLCODE,
                     pi_message            => SQLERRM);
    logger_pkg.unset_source(lc_log_sourcename);
    RAISE;

END;
/

