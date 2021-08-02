CREATE OR REPLACE PACKAGE data_test AS
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
                                           dates. 
 ******************************************************************************/

  /* This variable controls the behaviour in case a test fails.  I've made it
     a public variable so that it can be modified by the caller per session.
     When FALSE, a failing test will write a waringing message to the PROCESSING_LOG table.  
     When TRUE, a failing test will raise a PL/SQL exception to the caller.    */
  gv_raise_error_on_test_fail BOOLEAN := FALSE;
  
  /* This sets the minimum level to write log messages. 
     WARN excludes INFO and DEBUG,
     INFO excludes DEBUG,
     DEBUG writes all messages. */
  gv_logging_level processing_log.trace_level%TYPE := 'INFO';
 
  /* List test procedures here.  In general, test procedures should (or should not):
       Not depend on a specific order to run.
       Not depend on other tests to execute.
       Not depend on specific database state, they should setup the expected state before being run.
       Keep the environment unchanged post execution.  */

  ------------------------------------------------------------------------------
  /* Tests to check business data - requisitions, candidates, buyers, suppliers etc. */
  PROCEDURE client_names_guids_1_to_1;

  PROCEDURE supplier_names_guids_1_to_1;
  
  ------------------------------------------------------------------------------
  /* Tests to check SSC config data - score configurations, version tracking, etc. */
  PROCEDURE default_score_ranges_invalid;
  
  PROCEDURE client_score_ranges_invalid;

  PROCEDURE client_multiple_scores_check;
  
  PROCEDURE client_ccc_effec_date_check;
 
  PROCEDURE client_cme_effec_date_check;
  
  PROCEDURE client_cmc_effec_date_check;
  
  PROCEDURE client_rge_grd_effec_date_chk;
  
  PROCEDURE client_rge_grd_term_date_chk;
   
 
END data_test;
/
  