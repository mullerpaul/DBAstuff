-- Initial load legos CAN have any kind of refresh; but in practice, most will be PROCEDURE ONLY.
-- We have managed with just one in the past; but there CAN be more than one initial load group.
-- It (or they) can have any ID.  We have used -1 in the past and I'll use it here.
INSERT INTO lego_refresh_group
 (refresh_group, run_in_first_pass, run_in_initial_load, allow_partial_release, comments)
VALUES 
 (-1, 'N', 'Y', 'Y', 
  'This group is to be used for initial load legos.  We can remove this group and all its legos once the system is up and running')
/


-- Initial load legos  
INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, 
 refresh_dependency_order, storage_clause, partition_clause, refresh_procedure_name)
VALUES
('INIT_LEGO_CAC_CDC', 'USPROD', 'PROCEDURE ONLY', 'INITIAL', -1, 1, 
 NULL, 
 NULL, 'lego_cac_procedures.init_lego_cac_cdc')
/

INSERT INTO lego_refresh
(object_name, source_name, refresh_method, refresh_schedule, refresh_group, 
 refresh_dependency_order, storage_clause, partition_clause, refresh_procedure_name)
VALUES
('INIT_LEGO_CAC_COLLECTION', 'USPROD', 'PROCEDURE ONLY', 'INITIAL', -1, 2, 
 NULL, 
 NULL, 'lego_cac_procedures.init_lego_cac_collection_cdc')
/

COMMIT
/
