CREATE OR REPLACE PACKAGE BODY lego_validate  AS
  /******************************************************************************
     NAME:      LEGO_VALIDATE
     PURPOSE:   The TEST_LEGOS procedure will run a series of tests on the legos
                to ensure that they are being built to our expectations.  Hopefully
                we can catch any issues before our customers do.

     REVISIONS:
     Ver     Date        Author        Description
     ------  ----------  ------------  ------------------------------------
     1.0     05/07/2013  pmuller and   Created package.
                         jpullifrone
     1.1     2/21/2014   pmuller       modified logging calls, added tests
                                       for toggle base tables.
     1.2     6/24/2014   hmajid        Added join_test procedure.

  ******************************************************************************/

  lc_source       CONSTANT VARCHAR2(30) := 'LEGO_VALIDATE';
  gc_curr_schema  CONSTANT VARCHAR2(30) := sys_context('USERENV','CURRENT_SCHEMA');

  --------------------------------------------------------------------------------
  FUNCTION ok_to_test (pi_refresh_object_name IN VARCHAR2) RETURN CHAR IS

    lv_ok_to_test      CHAR(1) := 'N';

  BEGIN

    --has this table/object been refresh before?  If so, has it been refreshed
    --since the last time we tested it?
    BEGIN

      SELECT CASE  WHEN last_tested_ts >= last_release_ts THEN 'N'
                   WHEN last_tested_ts <  last_release_ts THEN 'Y'
                   WHEN last_release_ts IS NULL           THEN 'N'
                   WHEN last_release_ts IS NOT NULL AND last_tested_ts IS NULL THEN 'Y'
                   ELSE 'N'
              END AS ok_to_test
        INTO lv_ok_to_test
        FROM (
              SELECT /*+parallel(2)*/
                     MAX(lvh.validation_timestamp)                   AS last_tested_ts,
                     MAX(lrh.release_time)                           AS last_release_ts
                FROM lego_refresh_history lrh LEFT OUTER JOIN lego_validation_history lvh ON lrh.object_name = lvh.refresh_object_name
               WHERE lrh.object_name = pi_refresh_object_name
             );

      RETURN lv_ok_to_test;

    EXCEPTION
      WHEN OTHERS THEN
        RETURN lv_ok_to_test;
    END;

  END ok_to_test;

  --------------------------------------------------------------------------------
  FUNCTION get_rowcount(pi_table_name IN VARCHAR2) RETURN NUMBER IS
    lv_dummy  VARCHAR2(30);
    lv_query  VARCHAR2(1024);
    lv_result NUMBER;
  BEGIN
    /* Check if the table passed is a valid object.  */
    lv_dummy := dbms_assert.sql_object_name(pi_table_name);

    /* Build and execute query to get the rowcount of the table. */
    lv_query := 'select count(*) from ' || pi_table_name;

    logger_pkg.debug('Counting rows in ' || pi_table_name);
    EXECUTE IMMEDIATE lv_query INTO lv_result;
    logger_pkg.debug('Counting rows in ' || pi_table_name ||
                     ' completed - ' || to_char(lv_result),
                     TRUE);

    RETURN lv_result;

  END get_rowcount;

  --------------------------------------------------------------------------------
  PROCEDURE unique_test(pi_table_name IN VARCHAR2,
                        pi_unique_key IN VARCHAR2) IS

    lv_dummy  VARCHAR2(30);
    lv_query  VARCHAR2(1024);
    lv_result NUMBER;

  BEGIN
    /* Checks for uniqueness of the key in the table.
    Unlike an Oracle unique constraint, multiple rows where the key is all NULL
    WILL count as duplicates and cause this check to fail. */
    logger_pkg.debug('Starting unique_test with table_name:' ||
                     pi_table_name || '  unique_key:' || pi_unique_key);

    /* Check if the table passed is a valid object.
    Should add error checking for the key here.  */
    lv_dummy := dbms_assert.SQL_OBJECT_NAME(pi_table_name);

    /* Build and execute query to check for uniqueness.
    If any rows are found, then the key is not unique. */
    lv_query := 'select /*+parallel(2,2)*/ count(*)' ||
                '  from (select ' || pi_unique_key ||
                '          from ' || pi_table_name ||
                '         group by ' ||   pi_unique_key ||
                '        having count(*) > 1)';

    logger_pkg.debug(lv_query);
    logger_pkg.info('unique test for ' || pi_table_name || ' running');
    EXECUTE IMMEDIATE lv_query INTO lv_result;
    logger_pkg.info('unique test for ' || pi_table_name || ' complete', TRUE);

    IF lv_result > 0
    THEN
      raise_application_error(-20201,
                              pi_unique_key || ' is not unique in ' ||
                              pi_table_name);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      CASE SQLCODE
        WHEN -20201 THEN
          /* Duplicate rows found. */
          logger_pkg.error(pi_unique_key || ' is not unique in ' ||
                           pi_table_name);
        WHEN -44002 THEN
          /* Bad input for tablename */
          logger_pkg.error(pi_table_name || ' does not exist or is an invalid name');
        ELSE
          NULL;  -- unknown error.  not logged here, but it will be reraised and captured above.
      END CASE;

      RAISE;

  END unique_test;

  --------------------------------------------------------------------------------
  PROCEDURE rowcount_test(pi_table_name        IN VARCHAR2,
                          pi_expected_rowcount IN NUMBER) IS

    lv_row_count NUMBER;

  BEGIN
    /* Checks to see if rowcount matches expected value.  */
    logger_pkg.info('Starting rowcount_test with table_name:' ||
                    pi_table_name || '  expected_rowcount:' ||
                    to_char(pi_expected_rowcount));

    IF pi_expected_rowcount IS NULL OR pi_expected_rowcount < 0
    THEN
      logger_pkg.error('Bad input for expected rowcount for ' || pi_table_name);
      raise_application_error(-20203, 'Bad input for expected rowcount');
    END IF;

    lv_row_count := get_rowcount(pi_table_name);

    IF lv_row_count <> pi_expected_rowcount
    THEN
      logger_pkg.warn('Rowcount of ' || pi_table_name ||
                      ' does not match expected rowcount');
      raise_application_error(-20202,
                              'Rowcount of ' || pi_table_name ||
                              ' does not match expected rowcount');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      CASE SQLCODE
        WHEN -20202 THEN
          /* Rowcount does not match expected value. */
          logger_pkg.error('Rowcount of ' || pi_table_name ||
                           ' does not match expected rowcount');
        WHEN -20203 THEN
          /* Bad input for expected rowcount */
          logger_pkg.error('Bad input for expected rowcount.');
        WHEN -44002 THEN
          /* Bad input for tablename */
          logger_pkg.error(pi_table_name ||
                           ' does not exist or is an invalid name');
        ELSE
          NULL;  -- unknown error.  not logged here, but it will be reraised and captured above.
      END CASE;

      RAISE;

  END rowcount_test;

  --------------------------------------------------------------------------------
  PROCEDURE rowcount_test(pi_table_name  IN VARCHAR2,
                          pi_upper_bound IN NUMBER,
                          pi_lower_bound IN NUMBER) IS

    lv_row_count NUMBER;

  BEGIN
    /* Checks to see if rowcount is between upper and lower bound. */
    logger_pkg.info('Starting rowcount_test with table_name:' ||
                    pi_table_name || '  upper bound:' ||
                    to_char(pi_upper_bound) || '  lower bound:' ||
                    to_char(pi_lower_bound));

    IF (pi_upper_bound IS NULL OR
        pi_lower_bound IS NULL OR
        pi_upper_bound < 0 OR
        pi_lower_bound < 0 OR
        pi_lower_bound >= pi_upper_bound)
    THEN
      logger_pkg.error('Bad input for upper and lower rowcount bounds for ' || pi_table_name);
      raise_application_error(-20203,
                              'Bad input for upper and lower bounds');
    END IF;

    lv_row_count := get_rowcount(pi_table_name);

    IF lv_row_count < pi_lower_bound OR lv_row_count > pi_upper_bound
    THEN
      logger_pkg.warn('Rowcount of ' || pi_table_name || ' not in range');
      raise_application_error(-20202,
                              'Rowcount of ' || pi_table_name ||
                              ' not in range');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      CASE SQLCODE
        WHEN -20202 THEN
          /* Rowcount does not match expected value. */
          logger_pkg.error('Rowcount of ' || pi_table_name ||
                           ' not in range');
        WHEN -20203 THEN
          /* Bad input for upper and/or lower bounds */
          logger_pkg.error('Bad input for upper and/or lower bound.');
        WHEN -44002 THEN
          /* Bad input for tablename */
          logger_pkg.error(pi_table_name ||
                           ' does not exist or is an invalid name');
        ELSE
          NULL;  -- unknown error.  not logged here, but it will be reraised and captured above.
      END CASE;

      RAISE;

  END rowcount_test;

  --------------------------------------------------------------------------------
  PROCEDURE failure_notification(pi_run_time IN DATE) IS

    lv_email_message VARCHAR2(32676);
    lv_environment   email_dist_lists.environment%TYPE := fo_inv_extract_util.get_environment;
    lv_email_subject VARCHAR2(125) := 'Lego Validation Failures: ' ||
                                      gc_curr_schema || '@' ||
                                      sys_context('userenv', 'db_name') ||
                                      ' - ' || pi_run_time;

  BEGIN
    --start building HTML tag
    lv_email_message := '<html><body><table border="1"><tr><th>Object Name</th><th>Validation Type</th><th>Error Message</th></tr>';

    --loop through the errors, grabbing the object name, validation type and error message
    FOR y IN (SELECT refresh_object_name, validation_type, error_message
                FROM lego_validation_history
               WHERE validation_result <> 'passed'
                 AND validation_timestamp = pi_run_time) LOOP

      --wrap each row in table row tags
      logger_pkg.debug('adding info for ' || y.refresh_object_name ||
                       ' failure to email');
      lv_email_message := substr(lv_email_message || '<tr><td>' ||
                                 y.refresh_object_name || '</td>' ||
                                 ' <td>' || y.validation_type || '</td>' ||
                                 ' <td>' || y.error_message || '</td>' ||
                                 '</tr>',
                                 1,
                                 32676);

    END LOOP;

    -- add final HTML tags
    lv_email_message := substr(lv_email_message || '</table></body></html>',
                               1,
                               32676);

    logger_pkg.debug('About to send emails.  Environment: ' || lv_environment);
    FOR i IN (SELECT email_address
                FROM email_dist_lists
               WHERE process = 'lego_refresh'
                 AND environment = lv_environment) LOOP

      logger_pkg.debug('sending email to: ' || i.email_address ||
                       ' message: ' || lv_email_message);
      send_email(sender    => 'DONOTREPLY@iqnavigator.com',
                 recipient => i.email_address,
                 subject   => lv_email_subject,
                 message   => substr('MIME-Version: 1.0' || utl_tcp.crlf ||
                                     'Content-type:text/html;charset=iso-8859-1' ||
                                     utl_tcp.crlf || lv_email_message ||
                                     '<p>Message sent at: ' ||
                                     to_char(SYSDATE,
                                             'YYYY-Mon-DD hh24:mi:ss') ||
                                     '</p>',
                                     1,
                                     32676));

    END LOOP;

  END failure_notification;

  /*------------------------------------------------------------------------------
    There will be a public procedure for each test of type ROWCOUNT or DATA.
    Please place those procedures below this comment.
  ------------------------------------------------------------------------------*/
  PROCEDURE lego_assignment_rowcount IS
    lv_table_rowcount NUMBER := get_rowcount('assignment_edition');
  BEGIN
    /* Test the number of rows in LEGO_ASSIGNMENT_VW.

    We know that the front office table ASSIGNMENT_EDITION is the driving table and the
    source of most of the data in this lego, so we should never have more rows in the
    lego than we do in the FO table.  Also, the lego should have AT LEAST half the number
    of rows in the FO table.  That number (half) is just a best guess.  I picked that
    number because it is true now and if would be good to know if it ever became untrue.
    Alternativly, we could choose any any other clever formula for min and max number of rows.  */

    rowcount_test(pi_table_name  => 'LEGO_ASSIGNMENT_VW',
                  pi_upper_bound => lv_table_rowcount,
                  pi_lower_bound => floor(0.5 * lv_table_rowcount));

  END lego_assignment_rowcount;
  
    
   PROCEDURE join_test(pi_driving_table_name        IN VARCHAR2,
                       pi_driving_col_name          IN VARCHAR2,
                       pi_detail_table_name         IN VARCHAR2,  
                       pi_detail_col_name           IN VARCHAR2,
                       pi_join_operator   IN VARCHAR2) IS
   
    ln_detail_col_count  NUMBER;
    ln_driving_tbl_count NUMBER;
    lv_sql varchar2(32767);
    v_source  VARCHAR2(30) := 'lego_validation.join_test';


  BEGIN
  
    /* Instantiate the Logger */
    logger_pkg.instantiate_logger;
    logger_pkg.set_source(v_source);
                           
    lv_sql := 'SELECT count(*), count(de.'||pi_detail_col_name||') '||          
           '   FROM  ' || pi_driving_table_name || ' dr,'
                      || pi_detail_table_name || ' de ' || 
           'WHERE   dr.'||pi_driving_col_name || ' =  ' || '  de.'||pi_detail_col_name || '(+)';
           
   
     
    logger_pkg.info('join test for ' || pi_driving_table_name || ' - ' || pi_detail_table_name || ' running',TRUE);
    EXECUTE IMMEDIATE lv_sql INTO ln_driving_tbl_count, ln_detail_col_count;    
    logger_pkg.info('join test test for ' || pi_driving_table_name || ' - ' || pi_detail_table_name || ' complete', TRUE);

   
   IF pi_join_operator = 'INNER JOIN' THEN
           CASE WHEN ln_detail_col_count = ln_driving_tbl_count THEN 
              logger_pkg.info(' Inner Join test passed detail table = driving table -  ' || pi_driving_table_name || ' and ' || pi_detail_table_name ||' using column ' || pi_detail_col_name,TRUE); 
           ELSE 
              logger_pkg.error('Inner Join test failed detail table <> driving table -  ' || pi_driving_table_name || ' and ' || pi_detail_table_name ||' using column ' || pi_detail_col_name,TRUE); 
            --  raise_application_error(-20203,'Inner Join Failed!');
           END CASE;
      ELSIF pi_join_operator = 'OUTER JOIN' THEN
          CASE WHEN ln_detail_col_count = ln_driving_tbl_count THEN  
             logger_pkg.error('Outer Join test failed detail table = driving table - ' || pi_driving_table_name || ' and ' || pi_detail_table_name ||' using column ' || pi_detail_col_name,TRUE); 
          --   raise_application_error(-20203,'Outer Join Failed!');
          WHEN ln_detail_col_count < ln_driving_tbl_count THEN
             logger_pkg.info('Outer join test passed detail table < driving table -  ' || pi_driving_table_name || ' and ' || pi_detail_table_name ||' using column ' || pi_detail_col_name,TRUE); 
          WHEN ln_detail_col_count > ln_driving_tbl_count THEN
             logger_pkg.error('Outer Join test failed detail table > driving table  -' || pi_driving_table_name || ' and ' || pi_detail_table_name ||' using column ' || pi_detail_col_name,TRUE); 
             -- raise_application_error(-20203,'Outer Join Failed!');
          ELSE
           NULL;
          END CASE;
      END IF;
       
       
    EXCEPTION
      WHEN OTHERS THEN  
        CASE sqlcode 
        WHEN -942   THEN --'table or view does not exist' 
               logger_pkg.error('Invalid SQL -  Due to table Name or column names - ' || lv_sql,TRUE);  
        WHEN  -20203 THEN
              logger_pkg.error('Join Test Failure between' || pi_driving_table_name || ' and ' || pi_detail_table_name,TRUE);
        ELSE NULL;
        END CASE;
   

  END join_test;

  /*------------------------------------------------------------------------------
    There will be a public procedure for each test of type ROWCOUNT or DATA.
    Please place those procedures above this comment.
  ------------------------------------------------------------------------------*/

  --------------------------------------------------------------------------------
  PROCEDURE test_legos IS
    lv_source             VARCHAR2(61) := lc_source || '.test_legos';
    lv_error_msg          VARCHAR2(512);
    lv_run_time           lego_validation_history.validation_timestamp%TYPE := SYSDATE;
    lv_failure_count      NUMBER := 0;
    lv_test_start_time    TIMESTAMP;
    lv_actual_object_name VARCHAR2(30);

  BEGIN
    /* This procedure will run all enabled tests configured in the LEGO_VALIDATION table. */

    logger_pkg.instantiate_logger;
    logger_pkg.set_level(lego_refresh_mgr_pkg.get_lego_parameter_text_value('logging_level'));
    logger_pkg.set_source(lv_source);
    logger_pkg.debug('starting validation run');

    FOR i IN (SELECT refresh_object_name,
                     database_object_name,
                     validate_base_table,
                     validation_type,
                     cardinality_columns,
                     rowcount_validation_proc_name,
                     data_validation_proc_name,
                     driving_table,
                     driving_column,
                     detail_table,
                     detail_column,
                     join_operation
                FROM lego_validation a
               WHERE enabled = 'Y'
               ORDER BY refresh_object_name) LOOP

      lv_test_start_time := systimestamp;
      IF ok_to_test(i.refresh_object_name) = 'Y'
      THEN
        lv_actual_object_name := CASE
                                   WHEN i.validate_base_table = 'N'
                                     THEN i.database_object_name
                                   ELSE lego_util.most_recently_loaded_table(i.refresh_object_name)
                                 END;

        logger_pkg.debug('Running test for lego:' || i.refresh_object_name ||
                         ' checking object: ' || lv_actual_object_name);
        BEGIN
          CASE i.validation_type
            WHEN 'CARDINALITY' THEN
              unique_test(pi_table_name => lv_actual_object_name,
                          pi_unique_key => i.cardinality_columns);

            WHEN 'DATA' THEN
                null;
            WHEN 'JOIN' THEN            
              join_test(i.driving_table, i.driving_column, i.detail_table, i.detail_column, i.join_operation );
             
            WHEN 'ROWCOUNT' THEN
              EXECUTE IMMEDIATE 'begin ' || i.rowcount_validation_proc_name ||
                                '; end;';

            ELSE
              raise_application_error(-20002, 'Invalid validation type.');

          END CASE;

          /* If we get here the test has passed. */
          INSERT INTO lego_validation_history
            (refresh_object_name,
             database_object_name,
             validation_type,
             validation_timestamp,
             validation_duration,
             validation_result)
          VALUES
            (i.refresh_object_name,
             lv_actual_object_name,
             i.validation_type,
             lv_run_time,
             systimestamp - lv_test_start_time,
             'passed');

        EXCEPTION
          WHEN OTHERS THEN
            lv_error_msg     := SQLERRM;
            lv_failure_count := lv_failure_count + 1;

            INSERT INTO lego_validation_history
              (refresh_object_name,
               database_object_name,
               validation_type,
               validation_timestamp,
               validation_duration,
               validation_result,
               error_message)
            VALUES
              (i.refresh_object_name,
               lv_actual_object_name,
               i.validation_type,
               lv_run_time,
               systimestamp - lv_test_start_time,
               'failed',
               lv_error_msg);

        END;
        /* Pass or fail, either way we must commit the row. */
        COMMIT;
        logger_pkg.debug('test for ' || i.refresh_object_name ||
                         ' complete.  Runtime is ' || to_char(lv_run_time,'YYYY-Mon-DD hh24:mi:ss'));

      ELSE
        logger_pkg.info('Test for ' || i.refresh_object_name ||
                        ' skipped because the lego has not been released since last test.');

      END IF; -- ok_to_test = 'Y'

    END LOOP;

    /* If there were errors call procedure to send alert email. */
    logger_pkg.debug('error count: ' || to_char(lv_failure_count) ||
                     '  time: ' ||
                     to_char(lv_run_time, 'YYYY-Mon-DD hh24:mi:ss'));
    IF lv_failure_count > 0
    THEN
      failure_notification(lv_run_time);
    END IF;

    logger_pkg.unset_source(lv_source);

  END test_legos;


END lego_validate; 
/

