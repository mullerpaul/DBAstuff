BEGIN
  /* Setting the global variable such that failing tests will raise an unhadled exception back to 
     this block, and since we don't catch it here; it will go up to liquibase and stop the deploy. */
  data_test.gv_raise_error_on_test_fail := TRUE;

  /* Run the tests (these should NOT be order dependant)  */
 /* data_test.default_score_ranges_invalid;*/
  
END;
/
