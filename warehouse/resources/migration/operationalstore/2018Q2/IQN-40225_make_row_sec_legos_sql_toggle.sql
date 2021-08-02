----- convert some proc toggle legos to SQL toggle

-- This is possible because the procedural part of these legos' refreshes is there only to know
-- which of the parent legos' two toggle tables is the "most  recently refreshed".
-- Since we eliminated the release step and each toggle lego now switches its own synonym,
-- there is no need for any fancy code to know which table is most recently refreshed, instead
-- we can just point at the synonym and be gaurenteed to get the latest!

-- first ensure we are only doing this for "USPROD" legos (no wells fargo)
DELETE FROM lego_refresh
 WHERE object_name IN ('LEGO_ASSIGN_MANAGED_CAC','LEGO_JOB_MANAGED_CAC','LEGO_ASSIGNMENT_ROW_SECURITY','LEGO_JOB_ROW_SECURITY')
   AND source_name <> 'USPROD'
/

UPDATE lego_refresh
   SET refresh_method         = 'SQL TOGGLE',
       refresh_procedure_name = NULL
 WHERE object_name IN ('LEGO_ASSIGN_MANAGED_CAC','LEGO_JOB_MANAGED_CAC','LEGO_ASSIGNMENT_ROW_SECURITY','LEGO_JOB_ROW_SECURITY')
/

COMMIT
/
