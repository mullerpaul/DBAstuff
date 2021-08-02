BEGIN
  /* Run the tests (these should NOT be order dependant)  */
  data_test.client_names_guids_1_to_1;
  data_test.supplier_names_guids_1_to_1;
  data_test.client_score_ranges_invalid;
  data_test.client_multiple_scores_check;  
  data_test.client_ccc_effec_date_check;  
  data_test.client_cme_effec_date_check;  
  data_test.client_cmc_effec_date_check; 
  data_test.client_rge_grd_effec_date_chk; 
  data_test.client_rge_grd_term_date_chk;   
  data_test.default_score_ranges_invalid;
END;
/
