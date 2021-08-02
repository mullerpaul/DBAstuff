DECLARE
  lv_guid RAW(16);
  org_guid RAW(16);
  org_mult_guid RAW(16);
  
Begin
--add grades to multipliers

--candidate quality==============================================================

  --candidates_submitted
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'candidates_submitted', 'N umber of candidates submitted through supplier.', 'candidate quality');
  
  org_guid := SYS_GUID();
  
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.11);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10000, 500, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 500, 100, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 100, 50, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 50, 25, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 25, 1, 1, 'F');

  --candidates_placed
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'candidates_placed', 'Number of candidates placed in a position through supplier.', 'candidate quality');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.11);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10000, 500, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 500, 100, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 100, 50, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 50, 25, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 25, 1, 1, 'F');

  --candidates_declined
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'candidates_declined', 'Number of candidates declined to a position for a supplier.', 'candidate quality');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.11);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10, 0, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 20, 10, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 50, 20, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 100, 50, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 250, 100, 1, 'F');
  

  --cands_per_opportunity
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'cands_per_opportunity', 'Average number of candidates submitted to a single position for a supplier.', 'candidate quality');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.11);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 50, 25, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 25, 20, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 20, 15, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 15, 10, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10, 0, 1, 'F');
 
  --acceptance_rate
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'acceptance_rate', 'Candidates accepted over candidates submitted for a supplier.', 'candidate quality');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.11);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 100, 80, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 80, 60, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 60, 40, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 40, 20, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 20, 0, 1, 'F');

  --submit_hire_ratio
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'submit_hire_ratio', 'Candidates hired over candidates submitted for a supplier.', 'candidate quality');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.11);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 100, 80, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 80, 60, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 60, 40, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 40, 20, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 20, 0, 1, 'F');
  
  --unfav_terminations
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'unfav_terminations', 'Number of positions unfavorably terminated for a supplier.', 'candidate quality');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.11);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10, 0, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 50, 10, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 250, 50, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 500, 250, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 1000, 500, 1, 'F');

  --interview_rating
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'interview_rating', 'Average interview rating for a supplier.', 'candidate quality');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.11);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10, 8, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 8, 6, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 6, 4, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 4, 2, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 2, 0, 1, 'F');
  
  --interview_hire_ratio
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'interview_hire_ratio', 'Candidates hired over candidates interviewed for a supplier.', 'candidate quality');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.11);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 100, 80, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 80, 60, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 60, 40, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 40, 20, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 20, 0, 1, 'F');
  
--efficiency==============================================================

  --time_to_fill
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'time_to_fill', 'Average time to fill a position for a supplier.', 'efficiency');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.25);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 5, 0, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10, 5, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 14, 10, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 31, 14, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 45, 31, 1, 'F');
  
  --first_cand_response_time
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'first_cand_response_time', 'Average time before first response by a candidate for a req for a supplier.', 'efficiency');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.25);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 2, 0, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 5, 2, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10, 5, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 14, 10, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 21, 14, 1, 'F');
  

  --interview_response_time
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'interview_response_time', 'Average time between an interview requested and scheduled for a supplier.', 'efficiency');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.25);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 2, 0, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 5, 2, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10, 5, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 14, 10, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 21, 14, 1, 'F');

  --offer_response_time
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'offer_response_time', 'Average time between an offer made and accepted for a supplier.', 'efficiency');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.25);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 3, 0, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 7, 3, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 14, 7, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 21, 14, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 31, 21, 1, 'F');
  
--cost==============================================================

  --placements_over_req_rate
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'placements_over_req_rate', 'Number of placements for a supplier where candidate pay is over the request rate.', 'cost');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.25);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10, 0, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 25, 10, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 50, 25, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 500, 50, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 1000, 500, 1, 'F');

  --rate_competitiveness
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'rate_competitiveness', 'Average percent variation between offer accepted rate and requested rate for a supplier.', 'cost');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.25);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 10, 8, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 8, 6, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 6, 4, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 4, 2, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 2, 0, 1, 'F');
  

  --markup_percentage
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'markup_percentage', 'Average percent markup from pay rate to bill rate.', 'cost');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.25);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 20, 0, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 40, 20, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 60, 40, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 80, 60, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 100, 80, 1, 'F');

  --total_spend
  lv_guid := SYS_GUID();
  insert into metric (metric_guid, name, description, category)
  values (lv_guid, 'total_spend', 'Total amount ($) spent with a supplier.', 'cost');
  
   
  insert into org_weight (buyer_org_guid, metric_guid, weight)
  values (org_guid, lv_guid, 0.25);
  
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 100000000, 1000000, 10, 'A');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 1000000, 500000, 8, 'B');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 500000, 250000, 6, 'C');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 250000, 100000, 4, 'D');
  org_mult_guid := SYS_GUID(); 
  insert into org_multiplier(org_multiplier_guid, buyer_org_guid, metric_guid, less_than, greater_than_or_equal, calc_val, range_grade)
  values (org_mult_guid, org_guid, lv_guid, 100000, 0, 1, 'F');
  
end;
/

commit
/

  
  