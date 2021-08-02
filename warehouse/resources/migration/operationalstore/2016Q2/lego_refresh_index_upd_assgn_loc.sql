UPDATE lego_refresh_index
   SET index_type = 'NONUNIQUE',
       tablespace_name = NULL,
       index_name = 'ASSGN_LOC_ST_ATOM_OR_NI01'
 WHERE object_name = 'LEGO_ASSGN_LOC_ST_ATOM_OR'
/
UPDATE lego_refresh_index
   SET index_type = 'NONUNIQUE',
       tablespace_name = NULL,
       index_name = 'ASSGN_LOC_CMSA_ATOM_OR_NI01'
 WHERE object_name = 'LEGO_ASSGN_LOC_CMSA_ATOM_OR'
/
COMMIT
/