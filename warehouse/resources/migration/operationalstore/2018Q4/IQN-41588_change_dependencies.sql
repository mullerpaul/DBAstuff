-- Dashboard and Convergence search can use the "minimal" assignment legos
-- instead of the regular assignment legos.  Since the "minimal" legos can be
-- refreshed A LOT faster than the regular assignment legos, the duration of the
-- dashboard and conv. search refreshes will be reduced quite a bit.
-- Hopefully that will lead to easier scheduling and more reliable refresh requests.


-- first remove existing dashboard and conv search dependencies on assignment legos.
DELETE 
  FROM lego_refresh_dependency
 WHERE object_name IN ('LEGO_ASSGN_ATOM_DETAIL','LEGO_MONTHLY_ASSIGNMENT_LIST','LEGO_UPCOMING_ENDS_DETAIL', 'LEGO_CONVERGENCE_SEARCH')
   AND relies_on_object_name IN ('LEGO_ASSIGNMENT_EA','LEGO_ASSIGNMENT_TA','LEGO_ASSIGNMENT_WO')
/

-- now add the new deps.
INSERT INTO lego_refresh_dependency
 (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
 ('LEGO_ASSGN_ATOM_DETAIL', 'USPROD', 'LEGO_MINIMAL_ASSIGNMENT_EA_TA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
 (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
 ('LEGO_ASSGN_ATOM_DETAIL', 'USPROD', 'LEGO_MINIMAL_ASSIGNMENT_WO', 'USPROD')
/

INSERT INTO lego_refresh_dependency
 (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
 ('LEGO_MONTHLY_ASSIGNMENT_LIST', 'USPROD', 'LEGO_MINIMAL_ASSIGNMENT_EA_TA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
 (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
 ('LEGO_MONTHLY_ASSIGNMENT_LIST', 'USPROD', 'LEGO_MINIMAL_ASSIGNMENT_WO', 'USPROD')
/

INSERT INTO lego_refresh_dependency
 (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
 ('LEGO_UPCOMING_ENDS_DETAIL', 'USPROD', 'LEGO_MINIMAL_ASSIGNMENT_EA_TA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
 (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
 ('LEGO_UPCOMING_ENDS_DETAIL', 'USPROD', 'LEGO_MINIMAL_ASSIGNMENT_WO', 'USPROD')
/

INSERT INTO lego_refresh_dependency
 (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
 ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_MINIMAL_ASSIGNMENT_EA_TA', 'USPROD')
/
INSERT INTO lego_refresh_dependency
 (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
 ('LEGO_CONVERGENCE_SEARCH', 'USPROD', 'LEGO_MINIMAL_ASSIGNMENT_WO', 'USPROD')
/


-- commit the changes!
COMMIT
/
