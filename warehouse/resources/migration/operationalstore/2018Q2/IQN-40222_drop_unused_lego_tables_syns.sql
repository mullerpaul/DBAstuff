DECLARE
  -- create an array TYPE to hold the names of the 55 legos we will remove
  TYPE object_names_to_cleanup_array IS
    VARRAY ( 55 ) OF VARCHAR2(30);

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
  logger_pkg.set_source('IQN-40222 migration');
  logger_pkg.set_code_location('Remove unused legos and their objects');

  logger_pkg.info('Starting script to remove unused lego along with their tables and synonyms.');

  /* Initialize list of legos to remove.  
     With the exception of LEGO_CAC_COLLECTION_CURRENT, none of these have EVER been refreshed 
     in the OPERATIONALSTORE schema.  Thats in US prod (regular and WF) and EMEA prod.
     LEGO_CAC_COLLECTION_CURRENT was an attempt to get a CAC lego in operationalstore; but it
     has not been used.  The others shouldn't have copied them over fom IQPRODD to start with!
     Most of these are CDF legos; but there are a few others.  This will delete their 
     configuration data and associated objects. */
  la_objects   := object_names_to_cleanup_array(
    'LEGO_APPROVAL',
    'LEGO_ASSGNMNT_UDF_ENUM',
    'LEGO_ASSGNMNT_UDF_NOENUM',
    'LEGO_ASSGNMNT_WOV_UDF_ENUM',
    'LEGO_ASSGNMNT_WOV_UDF_NOENUM',
    'LEGO_BUS_ORG_UDF_ENUM',
    'LEGO_BUS_ORG_UDF_NOENUM',
    'LEGO_CAC_COLLECTION_CURRENT',
    'LEGO_CAND_SEARCH',
    'LEGO_CAND_SEARCH_IDX',
    'LEGO_CANDIDATE_UDF_ENUM',
    'LEGO_CANDIDATE_UDF_NOENUM',
    'LEGO_EXPENSE_ER_UDF_ENUM',
    'LEGO_EXPENSE_ER_UDF_NOENUM',
    'LEGO_EXPENSE_ERLI_UDF_ENUM',
    'LEGO_EXPENSE_ERLI_UDF_NOENUM',
    'LEGO_JOB_UDF_ENUM',
    'LEGO_JOB_UDF_NOENUM',
    'LEGO_LOCALE_PREF_SCORE',
    'LEGO_LOCALES_BY_BUYER_ORG',
    'LEGO_MISSING_TIME',
    'LEGO_PA_CAC',
    'LEGO_PA_CHANGE_REQUEST',
    'LEGO_PA_GEO_DESC',
    'LEGO_PAYMENT_REQUEST',
    'LEGO_PERSON_UDF_ENUM',
    'LEGO_PERSON_UDF_NOENUM',
    'LEGO_PROJ_AGREEMENT_PYMNT',
    'LEGO_PROJ_AGRMT_PA_UDF_ENUM',
    'LEGO_PROJ_AGRMT_PA_UDF_NOENUM',
    'LEGO_PROJECT_CAC',
    'LEGO_PROJECT_UDF_ENUM',
    'LEGO_PROJECT_UDF_NOENUM',
    'LEGO_PYMNT_REQ_MI_UDF_ENUM',
    'LEGO_PYMNT_REQ_MI_UDF_NOENUM',
    'LEGO_PYMNT_REQ_MID_UDF_ENUM',
    'LEGO_PYMNT_REQ_MID_UDF_NOENUM',
    'LEGO_REMITTANCE',
    'LEGO_REQUEST_TO_BUY',
    'LEGO_REQUEST_TO_BUY_CAC',
    'LEGO_RFX',
    'LEGO_RFX_CAC',
    'LEGO_RFX_UDF_ENUM',
    'LEGO_RFX_UDF_NOENUM',
    'LEGO_RQ_TO_BUY_RTB_UDF_ENUM',
    'LEGO_RQ_TO_BUY_RTB_UDF_NOENUM',
    'LEGO_TENURE',
    'LEGO_TIMECARD',
    'LEGO_TIMECARD_FUTURE',
    'LEGO_TIMECARD_T_UDF_ENUM',
    'LEGO_TIMECARD_T_UDF_NOENUM',
    'LEGO_TIMECARD_TE_UDF_ENUM',
    'LEGO_TIMECARD_TE_UDF_NOENUM',
    'LEGO_WORKER_ED_UDF_ENUM',
    'LEGO_WORKER_ED_UDF_NOENUM'
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
    DELETE FROM lego_refresh_index       WHERE object_name = la_objects(i);
    DELETE FROM lego_refresh_toggle_priv WHERE object_name = la_objects(i);
    DELETE FROM lego_refresh             WHERE object_name = la_objects(i);
    logger_pkg.info('DELETED ' || to_char(SQL%rowcount) || ' row(s) from LEGO_REFRESH for ' || la_objects(i));

  END LOOP;

  COMMIT;  -- most of the work was already committed with all the DDL; but we need to catch those last deletes.
  logger_pkg.unset_source('IQN-40222 migration');

EXCEPTION
  WHEN OTHERS THEN
    /* There are so many strange things that could get us here that there is nothing 
       sensible to do in this handler except log the error and re-raise it. */
    logger_pkg.fatal(pi_transaction_result => NULL,
                     pi_error_code         => SQLCODE,
                     pi_message            => SQLERRM);
    logger_pkg.unset_source('IQN-40222 migration');
    RAISE;

END;
/

