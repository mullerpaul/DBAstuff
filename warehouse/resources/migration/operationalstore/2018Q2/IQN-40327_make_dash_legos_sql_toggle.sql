----- convert some proc toggle legos to SQL toggle

-- This is possible because the procedural part of these legos' refreshes is there only to know
-- which of the parent legos' two toggle tables is the "most  recently refreshed".
-- Since we eliminated the release step and each toggle lego now switches its own synonym,
-- there is no need for any fancy code to know which table is most recently refreshed, instead
-- we can just point at the synonym and be gaurenteed to get the latest!

-- first ensure we are only doing this for "USPROD" legos (no wells fargo)
DELETE FROM lego_refresh
 WHERE object_name IN (
 'LEGO_REQ_BY_STATUS_DETAIL',
 'LEGO_REQ_BY_STATUS_ORG_ROLLUP',
 'LEGO_REQ_BY_STATUS_ROW_ROLLUP',
 'LEGO_ASSGN_ATOM_DETAIL',
 'LEGO_MONTHLY_ASSIGNMENT_LIST',
 'LEGO_UPCOMING_ENDS_DETAIL',
 'LEGO_ASSGN_LOC_CMSA_ATOM_OR',
 'LEGO_ASSGN_LOC_CMSA_ATOM_RR',
 'LEGO_ASSGN_LOC_ST_ATOM_OR',
 'LEGO_ASSGN_LOC_ST_ATOM_RR',
 'LEGO_MNTH_ASSGN_LIST_SPEND_DET',
 'LEGO_UPCOMING_ENDS_ORG_ROLLUP',
 'LEGO_UPCOMING_ENDS_ROW_ROLLUP',
 'LEGO_MNTH_ASGN_CNTSPND_ORGROLL',
 'LEGO_MNTH_ASGN_CNTSPND_ROWROLL'
)
   AND source_name <> 'USPROD'
/

UPDATE lego_refresh
   SET refresh_method         = 'SQL TOGGLE',
       refresh_procedure_name = NULL
 WHERE object_name IN (
 'LEGO_REQ_BY_STATUS_DETAIL',
 'LEGO_REQ_BY_STATUS_ORG_ROLLUP',
 'LEGO_REQ_BY_STATUS_ROW_ROLLUP',
 'LEGO_ASSGN_ATOM_DETAIL',
 'LEGO_MONTHLY_ASSIGNMENT_LIST',
 'LEGO_UPCOMING_ENDS_DETAIL',
 'LEGO_ASSGN_LOC_CMSA_ATOM_OR',
 'LEGO_ASSGN_LOC_CMSA_ATOM_RR',
 'LEGO_ASSGN_LOC_ST_ATOM_OR',
 'LEGO_ASSGN_LOC_ST_ATOM_RR',
 'LEGO_MNTH_ASSGN_LIST_SPEND_DET',
 'LEGO_UPCOMING_ENDS_ORG_ROLLUP',
 'LEGO_UPCOMING_ENDS_ROW_ROLLUP',
 'LEGO_MNTH_ASGN_CNTSPND_ORGROLL',
 'LEGO_MNTH_ASGN_CNTSPND_ROWROLL'
)
/

COMMIT
/

