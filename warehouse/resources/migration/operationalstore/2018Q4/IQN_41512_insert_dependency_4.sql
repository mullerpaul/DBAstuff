-- Our conv search legos is going to use the new BLONE_FO_lINKED_ACCOUNT lego.
-- insert the dependency row so the new lego is refreshed when running conv search refreshes.

INSERT INTO lego_refresh_dependency
 (object_name, source_name, relies_on_object_name, relies_on_source_name)
VALUES
 ('LEGO_CONVERGENCE_SEARCH','USPROD','LEGO_BLONE_LINKED_FO_ACCOUNT','HORIZON')
/

COMMIT
/

