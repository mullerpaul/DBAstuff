INSERT INTO lego_parameter 
  (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES 
  ('convergence_srch_load_candidates_flag',NULL,'OFF',NULL,
   'Will the convergence search lego load candidate data.  Must be "OFF" or "ON".')
/

INSERT INTO lego_parameter 
  (parameter_name, number_value, text_value, date_value, parameter_description)
VALUES 
  ('convergence_srch_users_per_listagg_batch',100,NULL,NULL,
   'How many users will be included in each listagg batch.  We have to break it down into batches since it exceeds the listagg limit of 4K.  Reasonalble numbers are 50-150')
/

COMMIT
/