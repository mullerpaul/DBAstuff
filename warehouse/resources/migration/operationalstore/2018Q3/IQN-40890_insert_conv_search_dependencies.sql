--- I found that the convergence search lego was missing dependency rows 
--- for four different legos it relies upon!

INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_PERSON_AVAILABLE_ORG', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_ASSIGNMENT_ROW_SECURITY', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_USER_ROLES', 'USPROD')
/
INSERT INTO lego_refresh_dependency
  (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
  ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_JOB', 'USPROD')
/

COMMIT
/
