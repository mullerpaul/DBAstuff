CREATE OR REPLACE PACKAGE BODY data_test 
AS
/******************************************************************************
   NAME:      data_test
   PURPOSE:   Collection of unit tests to confirm SSC data exists as expected
              and conforms to any assumptions baked into our code. 
              The idea is to look for data conditions which might break our code
              or cause our code to return incorrect or confusing results.  
  
   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   MSVC-2714  03/16/2018  Paul Muller      Created this package.

   MSVC-2693  03/27/2018  Hassina Majid    Add automated test to search for clients
                                           with multiple score point values 
                                           for a given letter grade. 
   MSVC-2876  04/16/2018  Hassina Majid    add automated test to search for score settings
                                           with date range gaps or overlaps as 
                                           it relates to effective and termination
                                           dates.   Added the following five procedures
                                           client_ccc_effec_date_check, 
                                           client_cme_effec_date_check, 
                                           client_cmc_effec_date_check,
                                           client_rge_grd_effec_date_chk
                                           and client_rge_grd_term_date_chk to validate
                                           invalid data in all client related tables. Some
                                           examples are provided below.
                                           
 ******************************************************************************/
 
/******************************************************************************
  Some things to keep in mind when writing tests:

    Tests should not mimic / duplicate the logic of tested code.
    Tests should contain zero logic. (or as close to zero as possible)
    The 3A rule:
      Arrange (setup inputs/data/environment for the tested code)
      Act (execute code under test)
      Assert (validate the outcomes of the execution)
    Each tested procedure/function/trigger (code block) should have more than one test.
    Each test should check only one behavior (one requirement) of the code block under test.
    Tests should be maintained as thoroughly as production code.
    Every test needs to be built so that it can fail, tests that do not fail when needed are useless!
    Tests are only valuable if they are executed frequently; ideally with every change to the 
      project code.
    Tests need to run "reasonably" fast; the slower the tests, the longer you wait. Build tests 
      with performance in mind. (do you really need to have 10k rows to run the tests?)
    Tests that are executed infrequently can quickly become stale and end up adding overhead 
      rather than value. Maintain tests as you would maintain code.
    Tests that are failing need to be addressed immediately. How can you trust your tests when 139 
      of 1000 tests are failing for a month? Will you recognise each time that it is still the 
      same 139 tests?
      
  client_multiple_scores_check - For this procedure the purpose is to find any client who setup a
  metric where an A is represented by 40 points, and they have setup another metric where an A is 50 points. 
  
  client_ccc_effec_date_check, client_cme_effec_date_check, client_cmc_effec_date_check, client_rge_grd_effec_date_chk,
   client_rge_grd_term_date_chk  procedures -
  Check to make sure effective and termination date are valide for following client tables
  client_category_coefficient, client_metric_coefficient, client_metric_converesion and it will validate that all 
  the score setting changes are effective and dated correctly. This means no overlaps or gaps between 
  values for the coefficient values(metric and category) and the conversion ranges. 
  Also, all five of the conversion rows should have the same effective date and term dates!
  
  These procedures client_ccc_effec_date_check, client_cme_effec_date_check, client_cmc_effec_date_check all
  validate the following scnarios - 
  
  Valid data cases -  Below are the valid data scnarios.
  
    If previous termination date equal to current effective date or previous termination date
    equal to effective date  + 1 second.  
    
    If both previous effective and previous termination dates are null then
    this is the very first row of data and no previous data to validate it against.
    
    If the termination date is null then this is the latest data or data that is effective.
    
  Invalid data cases - When there are gaps between previous termination dates and next effective date 
  or vice versa.
 
  For example, below show a client with all grade ranges where termination date is 3/21/2018 while 
  new data added has an effective date is 3/25/2018, in this case there is a four day gap.  So, this
  case will be flagged as an issue.  
  
  client guid                      Metric Id range grade  effective date        termination date 
  1C3524A932B82ABAE053CC0FD30AF093    12    A    3/21/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
  1C3524A932B82ABAE053CC0FD30AF093    12    B    3/21/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
  1C3524A932B82ABAE053CC0FD30AF093    12    C    3/21/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
  1C3524A932B82ABAE053CC0FD30AF093    12    D    3/21/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
  1C3524A932B82ABAE053CC0FD30AF093    12    F    3/21/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
 
  1C3524A932B82ABAE053CC0FD30AF093    12    A    3/25/2018 8:05:12 PM        
  1C3524A932B82ABAE053CC0FD30AF093    12    B    3/25/2018 8:05:12 PM        
  1C3524A932B82ABAE053CC0FD30AF093    12    C    3/25/2018 8:05:12 PM        
  1C3524A932B82ABAE053CC0FD30AF093    12    D    3/25/2018 8:05:12 PM        
  1C3524A932B82ABAE053CC0FD30AF093    12    F    3/25/2018 8:05:12 PM        
 
  The client_rge_grd_effec_date_chk and client_rge_grd_term_date_chk procedures validates
  that effective and termination date ranges for range of grades A through F are the same same effective
  and termination dates.  For example, below the data is flagged as an issue since grade D does not have 
  the same effective date as A,B,C, and F.
  
  client guid                      Metric Id range grade  effective date        termination date 
  1C3524A932B82ABAE053CC0FD30AF093    12    A    3/21/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
  1C3524A932B82ABAE053CC0FD30AF093    12    B    3/21/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
  1C3524A932B82ABAE053CC0FD30AF093    12    C    3/21/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
  1C3524A932B82ABAE053CC0FD30AF093    12    D    3/18/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
  1C3524A932B82ABAE053CC0FD30AF093    12    F    3/21/2018 8:05:12 PM    3/21/2018 8:09:14 PM    
 
  These points were copied from the utPLSQL project page.  
  See http://utplsql.org/utPLSQL/
 ******************************************************************************/
  PROCEDURE pass(pi_message IN VARCHAR2)
  IS
  BEGIN
    logger_pkg.info(pi_message => pass.pi_message);

  END pass;
  
  PROCEDURE fail(pi_message IN VARCHAR2)
  IS
  BEGIN
    logger_pkg.warn(pi_message => fail.pi_message);
    
    IF gv_raise_error_on_test_fail
    THEN 
      RAISE_APPLICATION_ERROR(-20001, fail.pi_message);
    END IF;
  END fail;

  ------------------------------------------------------------------------------
  PROCEDURE client_names_guids_1_to_1
  IS
    lv_guids_with_multiple_names NUMBER;
    lv_names_with_multiple_guids NUMBER;

  BEGIN
    logger_pkg.set_code_location('client_names_guids_1_to_1');
    logger_pkg.info('Test to see if any given client_guid has only one client_name.');
    
    /* This test used to check for client_names with multiple client_guids as well; but we eliminated 
       that test after deciding to load IQN data with the low level org guid in "client_guid".
       At that point, seeing multiple client_guids for a given client_name became acceptable. */
    SELECT COUNT(*)
      INTO lv_guids_with_multiple_names
      FROM (SELECT client_guid
              FROM supplier_release
             GROUP BY client_guid
            HAVING COUNT(DISTINCT client_name) > 1);
      
    logger_pkg.info('Test to see if any given client_guid has only one client_name. COMPLETE', TRUE);
    
    IF lv_guids_with_multiple_names > 0 
      THEN fail('Client GUIDs with multiple different values for client_name exist'); 
      ELSE pass('Client GUIDs with multiple different values for client_name do not exist');
    END IF;
    
  END client_names_guids_1_to_1;  

  ------------------------------------------------------------------------------
  PROCEDURE supplier_names_guids_1_to_1
  IS
    lv_guids_with_multiple_names NUMBER;

  BEGIN
    logger_pkg.set_code_location('supplier_names_guids_1_to_1');
    logger_pkg.info('Test to see if any given client_guid has only one client_name.');

    SELECT COUNT(*)
      INTO lv_guids_with_multiple_names
      FROM (SELECT supplier_guid
              FROM supplier_release
             GROUP BY supplier_guid
            HAVING COUNT(DISTINCT supplier_name) > 1);
    
    logger_pkg.info('Test to see if any given client_guid has only one client_name. COMPLETE', TRUE);

    IF lv_guids_with_multiple_names > 0 
      THEN fail('Supplier GUIDs with multiple different values for supplier_name exist'); 
      ELSE pass('Supplier GUIDs with multiple different values for supplier_name do not exist');
    END IF;

  END supplier_names_guids_1_to_1;  
  
  ------------------------------------------------------------------------------
  PROCEDURE default_score_ranges_invalid
  IS
    lv_invalid_default_ranges NUMBER;
  BEGIN
    logger_pkg.set_code_location('default_score_ranges_invalid');
    logger_pkg.info('Test to see if any of the default score ranges have duplicate grades, range gaps or overlaps, points and grades dont correspond)');

    /* This query looks at "adjacent" rows and checks to see if:
         the range boundries are identical (range_configuration)
         any grades are repeated (grade_check)
         score for 'A' is greater than score for 'B', wich is greater than 'C' etc (score_configuration) */
    SELECT COUNT(*) 
      INTO lv_invalid_default_ranges
      from (
    SELECT metric_id, range_grade,
           CASE
             WHEN prev_grade IS NULL THEN NULL
             WHEN prev_grade < range_grade THEN NULL
             ELSE 'repeated grade'
           END AS grade_check,
           CASE
             WHEN prev_score IS NULL THEN NULL       
             WHEN range_score < prev_score THEN NULL
             ELSE 'inconsistant score'
           END AS score_configuration,
           CASE
             WHEN prev_gte IS NULL AND prev_lt IS NULL THEN NULL
             WHEN greater_than_or_equal = prev_lt THEN NULL  -- smaller is better
             WHEN less_than = prev_gte            THEN NULL  -- bigger is better
             ELSE 'invalid range boundries'
           END AS range_configuration
      FROM (SELECT metric_id,
                   greater_than_or_equal,
                   less_than,
                   range_grade,
                   range_score,
                   LAG(greater_than_or_equal) OVER(PARTITION BY metric_id ORDER BY range_grade) AS prev_gte,
                   LAG(less_than) OVER(PARTITION BY metric_id ORDER BY range_grade) AS prev_lt,
                   LAG(range_score) OVER(PARTITION BY metric_id ORDER BY range_grade) AS prev_score,
                   LAG(range_grade) OVER(PARTITION BY metric_id ORDER BY range_grade) AS prev_grade
              FROM default_metric_conversion)
     ORDER BY metric_id, range_grade)
     WHERE (grade_check IS NOT NULL OR score_configuration IS NOT NULL OR range_configuration IS NOT NULL);

    logger_pkg.info('Test to see if any given client_guid has only one client_name. COMPLETE', TRUE);
    
    IF lv_invalid_default_ranges > 0 
      THEN fail('One or more default score ranges are configured improperly.');
      ELSE pass('All default score ranges are configured logically!');
    END IF;

  END default_score_ranges_invalid;  
  
  ------------------------------------------------------------------------------
  PROCEDURE client_score_ranges_invalid
  IS
    lv_invalid_client_ranges NUMBER;
  BEGIN
    logger_pkg.set_code_location('client_score_ranges_invalid');
    logger_pkg.info('Test to see if any given client_guid has only one client_name.');

    /* This query looks at "adjacent" rows and checks to see if:
         the range boundries are identical (range_configuration)
         any grades are repeated (grade_check)
         score for 'A' is greater than score for 'B', wich is greater than 'C' etc (score_configuration) */
    SELECT COUNT(*)
      INTO lv_invalid_client_ranges
      FROM (
    SELECT client_guid,
           metric_id,
           range_grade,
           CASE
             WHEN prev_grade IS NULL THEN NULL
             WHEN prev_grade < range_grade THEN NULL
             ELSE 'repeated grade'
           END AS grade_check,
           CASE
             WHEN prev_score IS NULL THEN NULL
             WHEN range_score < prev_score THEN NULL
             ELSE 'inconsistant score'
           END AS score_configuration,
           CASE
             WHEN prev_gte IS NULL AND prev_lt IS NULL THEN NULL
             WHEN greater_than_or_equal = prev_lt THEN NULL  -- smaller is better
             WHEN less_than = prev_gte            THEN NULL  -- bigger is better
             ELSE 'invalid range boundries'
           END AS range_configuration
      FROM (SELECT client_guid,
                   metric_id,
                   greater_than_or_equal,
                   less_than,
                   range_grade,
                   range_score,
                   LAG(greater_than_or_equal) OVER(PARTITION BY client_guid, metric_id ORDER BY range_grade) AS prev_gte,
                   LAG(less_than) OVER(PARTITION BY client_guid, metric_id ORDER BY range_grade) AS prev_lt,
                   LAG(range_score) OVER(PARTITION BY client_guid, metric_id ORDER BY range_grade) AS prev_score,
                   LAG(range_grade) OVER(PARTITION BY client_guid, metric_id ORDER BY range_grade) AS prev_grade
              FROM client_metric_conversion)
     ORDER BY client_guid, metric_id, range_grade)
     WHERE (grade_check IS NOT NULL OR score_configuration IS NOT NULL OR range_configuration IS NOT NULL);

    logger_pkg.info('Test to see if any given client_guid has only one client_name. COMPLETE', TRUE);

    IF lv_invalid_client_ranges > 0 
      THEN fail('One or more clients have score ranges configured improperly.');
      ELSE pass('All clients have score ranges configured logically.');
    END IF;

  END client_score_ranges_invalid;  
  
    PROCEDURE client_multiple_scores_check
   IS
    lv_invalid_client_ranges NUMBER;
   BEGIN 
   
      SELECT COUNT(*)
       INTO lv_invalid_client_ranges
       FROM (      
      SELECT client_guid, range_grade, COUNT(distinct c.range_score)
        FROM supplier_scorecard.client_metric_conversion c
      GROUP BY client_guid, range_grade
      HAVING COUNT(distinct c.range_score) > 1);
   
    logger_pkg.info('Test to see if any given client_guid has multiple score ranges', TRUE);
 
     IF lv_invalid_client_ranges > 0 
       THEN 
         fail('Total number of clients with multiple score ranges  = ' || lv_invalid_client_ranges);
       ELSE
         pass('All clients have score ranges configured logically.');
     END IF;
  END client_multiple_scores_check;

   -- This procedure validaes the effective and termination dates in client_category_coefficient table  
    PROCEDURE client_ccc_effec_date_check
   IS
    lv_invalid_client_date_cnt NUMBER;
   BEGIN 
   
     SELECT COUNT(distinct client_guid)
      INTO lv_invalid_client_date_cnt
            FROM ( 
          SELECT client_guid,
                 metric_category,
                 category_coefficient,
                 effective_date,
                 prev_effective_date,
                 termination_date,
                 prev_termination_date,
            CASE  WHEN ( prev_termination_date = effective_date  OR
                       prev_termination_date = effective_date + interval '1' second)  THEN NULL  
                  WHEN prev_termination_date > effective_date  + interval '1' second  THEN 'Gap Exists'
                  WHEN prev_effective_date IS NULL and prev_termination_date IS NULL THEN  NULL  -- Very First row
                  WHEN termination_date IS NULL THEN NULL   -- very last row 
                  ELSE 'effective_date is not valid for grade range'
             END AS effective_date_check
           FROM (SELECT client_guid,
                        metric_category,
                        category_coefficient,
                        effective_date,
                        termination_date,
                        LAG(effective_date) OVER(PARTITION BY client_guid,metric_category ORDER by  effective_date ) as prev_effective_date,
                        LAG(termination_date) OVER(PARTITION BY client_guid,metric_category ORDER by  effective_date ) as prev_termination_date
                   FROM supplier_scorecard.client_category_coefficient
                  order by client_guid,metric_category, effective_date, category_coefficient
                  )
          ORDER BY client_guid, metric_category, effective_date, category_coefficient)
     where effective_date_check IS NOT NULL;
   
    logger_pkg.info('Test to see if any given client_guid has multiple score ranges', TRUE);
 
     IF lv_invalid_client_date_cnt > 0 
       THEN 
         fail('Total number of clients invalid effective and/or termination date in client_category_coefficient = ' || lv_invalid_client_date_cnt);
       ELSE
         pass('All clients have valid effective and/or termination dates in client_category_coefficient.');
     END IF;
  END client_ccc_effec_date_check;
  
  -- This procedure validaes the effective and termination dates in client_metric_coefficient table  
  PROCEDURE client_cme_effec_date_check
  IS
      lv_invalid_client_date_cnt NUMBER;
     BEGIN 
     
       SELECT COUNT(distinct client_guid)
         INTO  lv_invalid_client_date_cnt
             FROM ( 
           SELECT client_guid,
                 metric_id,
                 metric_coefficient,
                 prev_effective_date,
                 effective_date,
                 prev_termination_date,
                 termination_date,
              CASE  WHEN ( prev_termination_date = effective_date  OR
                        prev_termination_date = effective_date + interval '1' second)  THEN NULL  
                    WHEN prev_termination_date > effective_date  + interval '1' second  THEN 'Gap Exists'
                    WHEN prev_effective_date IS NULL and prev_termination_date IS NULL THEN  NULL  -- Very First row
                    WHEN termination_date IS NULL THEN NULL   -- very last row 
                    ELSE 'effective_date is not valid for grade range'
              END AS effective_date_check
            FROM (SELECT client_guid,
                         metric_id,
                         metric_coefficient,
                         effective_date,
                         termination_date,
                         LAG(effective_date) OVER(PARTITION BY client_guid,metric_id ORDER by  effective_date ) as prev_effective_date,
                         LAG(termination_date) OVER(PARTITION BY client_guid,metric_id ORDER by  effective_date ) as prev_termination_date
                    FROM supplier_scorecard.client_metric_coefficient     
                    order by client_guid,metric_id, effective_date, metric_coefficient
                   )
           ORDER BY client_guid, metric_id, effective_date, metric_coefficient)
     where effective_date_check IS NOT NULL;
     
      logger_pkg.info('Test to see if any given client_guid has multiple score ranges', TRUE);
   
       IF lv_invalid_client_date_cnt > 0 
         THEN 
           fail('Total number of clients invalid effective and/or termination date in client_metric_coefficient = ' || lv_invalid_client_date_cnt);
         ELSE
           pass('All clients have valid effective and/or termination dates in client_metric_coefficient.');
       END IF;
  END client_cme_effec_date_check;
  
  -- This procedure validaes the effective and termination dates in client_metric_conversion table  
  PROCEDURE client_cmc_effec_date_check
  IS
        lv_invalid_client_date_cnt NUMBER;
       BEGIN 
       
        SELECT COUNT(distinct client_guid)
         INTO  lv_invalid_client_date_cnt
             FROM ( 
           SELECT client_guid,
                 metric_id,
                 range_grade,
                 prev_effective_date,
                 effective_date,
                 prev_termination_date,
                 termination_date,
             CASE  WHEN ( prev_termination_date = effective_date  OR
                        prev_termination_date = effective_date + interval '1' second)  THEN NULL  
                   WHEN prev_termination_date > effective_date  + interval '1' second  THEN 'Gap Exists'
                   WHEN prev_effective_date IS NULL and prev_termination_date IS NULL THEN  NULL  -- Very First row
                   WHEN termination_date IS NULL THEN NULL   -- very last row 
                   ELSE 'effective_date is not valid for grade range'
             END AS effective_date_check
            FROM (SELECT client_guid,
                         metric_id,
                         range_grade,
                         effective_date,
                         termination_date,
                         LAG(effective_date) OVER(PARTITION BY client_guid,metric_id, range_grade  ORDER by  effective_date ) as prev_effective_date,
                         LAG(termination_date) OVER(PARTITION BY client_guid,metric_id, range_grade ORDER by  effective_date ) as prev_termination_date
                    FROM supplier_scorecard.client_metric_conversion        
                    order by client_guid,metric_id, effective_date, range_grade
                   )
           ORDER BY client_guid, metric_id, effective_date, range_grade)
           where effective_date_check IS NOT NULL;
       
        logger_pkg.info('Test to see if any given client_guid has multiple score ranges', TRUE);
     
         IF lv_invalid_client_date_cnt > 0 
           THEN 
             fail('Total number of clients invalid effective and/or termination date in client_metric_conversion = ' || lv_invalid_client_date_cnt);
           ELSE
             pass('All clients have valid effective and/or termination dates in client_metric_conversion.');
         END IF;
  END client_cmc_effec_date_check;
  
   -- This procedure validaes the effective for range grades A-F and if they don't match in all five rows
   -- it will flag it as an issue.   
   PROCEDURE client_rge_grd_effec_date_chk
   IS
    lv_count NUMBER;
    
       BEGIN 
        SELECT COUNT(*)
          INTO lv_count
         FROM (
           SELECT client_guid,
                  metric_id,
                  effective_date,
                  COUNT (*)
             FROM supplier_scorecard.client_metric_conversion
         GROUP BY client_guid, metric_id, effective_date
  HAVING COUNT (*) <> 5);
  
   IF lv_count > 0  THEN 
       fail('Clients where the effective date for range grade A-F is not the same = ' || lv_count);
   ELSE
      pass('All clients have same effective date for sets of range grades A-F.');
   END IF;
  END client_rge_grd_effec_date_chk;
  
  -- This procedure validaes the effective for range grades A-F and if they don't match in all five rows
  -- it will flag it as an issue.   
  PROCEDURE client_rge_grd_term_date_chk
  IS
      lv_count NUMBER;
      
         BEGIN 
          SELECT COUNT(*)
            INTO lv_count
           FROM (
              SELECT client_guid,
                     metric_id,
                     termination_date,
                     COUNT (*)
                FROM supplier_scorecard.client_metric_conversion
            GROUP BY client_guid, metric_id, termination_date
         HAVING COUNT (*) <> 5
       );
    
     IF lv_count > 0  THEN 
         fail('Clients where the termination date for range grade A-F is not the same = ' || lv_count);
     ELSE
        pass('All clients have same termination date for sets of range grades A-F.');
     END IF;
  END client_rge_grd_term_date_chk;
  ------------------------------------------------------------------------------
  BEGIN  
    /* Execution section for package
       do stuff here that needs to happen in the session before any tests run.  */
   
    /* Instantiate the logger and set the level as specified by the global variable  */
    logger_pkg.instantiate_logger;
    logger_pkg.set_source('DATA_TEST');
    logger_pkg.set_level(gv_logging_level);

END data_test;
/
