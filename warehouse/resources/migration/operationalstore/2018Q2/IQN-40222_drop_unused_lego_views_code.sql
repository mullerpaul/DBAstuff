DECLARE
  -- create an array TYPE to hold the names of the objects we will remove
  TYPE object_to_drop_array IS
    VARRAY ( 10 ) OF VARCHAR2(30);

  -- now create variables of that TYPE
  la_view     object_to_drop_array;
  la_function object_to_drop_array;
  la_package  object_to_drop_array;
  
  -- create exceptions
  le_no_such_view    EXCEPTION;
  le_no_such_code    EXCEPTION;
  PRAGMA exception_init ( le_no_such_view,-00942 );
  PRAGMA exception_init ( le_no_such_code,-04043 );

  -- helper procedure
  PROCEDURE drop_object (pi_object_type IN VARCHAR2, 
                         pi_object_name IN VARCHAR2)
    IS
  BEGIN
    /* This is vulnerable to SQL injection; but since its just a short-lived 
       procedure inside an anonymous block, I'm not too worried!  */
    EXECUTE IMMEDIATE ( 'DROP ' || pi_object_type || ' ' || pi_object_name );
    logger_pkg.info('dropped ' || pi_object_type || ' ' || pi_object_name);
  EXCEPTION
    WHEN le_no_such_code OR le_no_such_view THEN 
      NULL;
  END drop_object;

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('IQN-40222 migration');
  logger_pkg.set_code_location('Remove unused views, types, and packages');

  logger_pkg.info('Starting script to remove unused views, functions, and packages.');
  
  /* Initialize lists of objects to remove.  
     Despite existing in OPERATIONALSTORE@IQM, none of these views are anywhere to be found 
     in the WAREHOUSE repo!  If they are important, they should be checked in.  */
  la_view  := object_to_drop_array(
    'ASSIGNMENT_BY_MONTH_VIEW',
    'ASSIGNMENT_MONTH_TREND_VEW',
    'BREAK_BY_DAY',
    'LEGO_ASSIGN_24_MO_TREND_VW_HM',
    'LEGO_ASSIGN_MONTH_TREND_VW_HM',
    'MONTH_RANGE_VIEW',
    'ORGANIZATION_UNIT_HIERARCHY',
    'ORGANIZATION_UNIT_HIERARCHY_V'
    );

  /* Despite existing in OPERATIONALSTORE@IQM, none of these functions are anywhere to be found 
     in the WAREHOUSE repo!  If they are important, they should be checked in.  */
  la_function := object_to_drop_array(
    'GET_BUSINESS_DAYS',
    'GET_ORG_LEVEL_HIERARCHY_INFO'
    );

  /* While all of these packages DO exist in the repo, they are no longer needed. */
  la_package := object_to_drop_array(
    'LEGO_CAC_PROCEDURES',
    'LEGO_TENURE',
    'LEGO_TIMECARD',
    'LEGO_UDF_UTIL',
    'LEGO_UTIL'
    );

  /*  Loop through the list of views and drop each in turn */
  FOR i IN la_view.first..la_view.last LOOP
    drop_object(pi_object_type => 'VIEW', pi_object_name => la_view(i));
  END LOOP;
  
  /*  same for list of functions */
  FOR i IN la_function.first..la_function.last LOOP
    drop_object(pi_object_type => 'FUNCTION', pi_object_name => la_function(i));
  END LOOP;

  /*  same for list of packages */
  FOR i IN la_package.first..la_package.last LOOP
    drop_object(pi_object_type => 'PACKAGE', pi_object_name => la_package(i));
  END LOOP;

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
