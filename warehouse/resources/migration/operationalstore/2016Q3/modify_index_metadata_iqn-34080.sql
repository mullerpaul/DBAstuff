-- Delete 4 rows.  Two of these four are now IOTs and dont need additional indexes!
DELETE FROM lego_refresh_index
 WHERE object_name LIKE 'LEGO_ASSGN_LOC%ATOM__R'
/

-- reinsert the other two with different column list
INSERT INTO lego_refresh_index
 (object_name, source_name, index_name, column_list)
VALUES
 ('LEGO_ASSGN_LOC_CMSA_ATOM_RR','USPROD','ASSGN_LOC_CMSA_ATOM_RR_NI01','LOGIN_USER_ID, LOGIN_ORG_ID')
/
INSERT INTO lego_refresh_index
 (object_name, source_name, index_name, column_list)
VALUES
 ('LEGO_ASSGN_LOC_CMSA_ATOM_OR','USPROD','ASSGN_LOC_CMSA_ATOM_OR_NI01','LOGIN_USER_ID, LOGIN_ORG_ID')
/

-- When you care enough to modify data... commit!
COMMIT
/
 

