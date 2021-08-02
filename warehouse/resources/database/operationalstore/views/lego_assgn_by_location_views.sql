CREATE OR REPLACE FORCE VIEW assgn_loc_cmsa_atom_orgroll_vw
AS 
SELECT effective_assgn_count, login_org_id, login_user_id, cmsa_name, metro_name, cmsa_primary_state_code, cmsa_primary_city_name, cmsa_primary_city_lat, cmsa_primary_city_long
  FROM assgn_loc_cmsa_atom_or_iqp
/

CREATE OR REPLACE FORCE VIEW assgn_loc_st_atom_orgroll_vw
AS 
SELECT effective_assgn_count, login_org_id, login_user_id, cmsa_primary_state_code
  FROM assgn_loc_st_atom_or_iqp
/

CREATE OR REPLACE FORCE VIEW assgn_loc_st_atom_rowroll_vw
AS 
SELECT effective_assgn_count, login_org_id, login_user_id, cmsa_primary_state_code
  FROM assgn_loc_st_atom_rr_iqp
/

CREATE OR REPLACE FORCE VIEW assgn_loc_cmsa_atom_rowroll_vw
AS 
SELECT effective_assgn_count, login_org_id, login_user_id, cmsa_name, metro_name, cmsa_primary_state_code, cmsa_primary_city_name, cmsa_primary_city_lat, cmsa_primary_city_long
  FROM assgn_loc_cmsa_atom_rr_iqp
/
