/*******************************************************************************
SCRIPT NAME         lego_assgn_atom_detail.sql.sql
 
LEGO OBJECT NAME    LEGO_ASSGN_ATOM_DETAIL
 
***************************MODIFICATION HISTORY ********************************

05/23/2018 - Paul Muller    - IQN-40327 - Initial version. SQL taken from Joe Pullifrone's procedure in LEGO_DASHBOARD_REFRESH
10/29/2018 - Paul Muller    - IQN-41588 - Changes to use "minimal" assignment legos.

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assgn_atom_detail.sql.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSGN_ATOM_DETAIL'; 

  /* When converting this to a SQL toggle, I hard-coded the filters on iqprodm.dm_atom_place and 
     iqprodm.dm_atom_job_title_cat such that they will always return data from the 'REGULAR' 
     (non wells fargo) data in the mart.  The proc toggle version was able to set this correctly based on the
     source_name; but we have never run the lego for WFPROD, so I feel fine taking away that functionality. */
  v_clob CLOB :=
      q'{WITH assgn_per AS(   
      SELECT assgn.buyer_org_id, assgn.supplier_org_id, assgn.assignment_continuity_id,
             assgn.hiring_mgr_person_id, cp.display_name AS contractor_name, 
             hmp.display_name AS hiring_manager_name, assgn.assignment_type, assgn.assignment_start_dt, 
             assgn.assignment_end_dt, assgn.assignment_actual_end_dt, assgn.assignment_duration, 
             assgn.assignment_state_id, assgn.current_phase_type_id
        FROM person_iqp cp,
             person_iqp hmp,
            (SELECT buyer_org_id, supplier_org_id, assignment_continuity_id, hiring_mgr_person_id,
                     contractor_person_id, assignment_type, assignment_start_dt, assignment_end_dt, 
                     assignment_actual_end_dt, assignment_duration, assignment_state_id, 
                     current_phase_type_id
                FROM minimal_assignment_wo_iqp
              UNION ALL
              SELECT buyer_org_id, supplier_org_id, assignment_continuity_id, hiring_mgr_person_id,
                     contractor_person_id, assignment_type, assignment_start_dt, assignment_end_dt, 
                     assignment_actual_end_dt, assignment_duration, assignment_state_id, 
                     current_phase_type_id
                FROM minimal_assignment_ea_ta_iqp) assgn
       WHERE assgn.contractor_person_id     = cp.person_id
         AND assgn.hiring_mgr_person_id     = hmp.person_id) 
  
      SELECT assgn_per.buyer_org_id, assgn_per.supplier_org_id, assgn_per.assignment_continuity_id,
             assgn_per.hiring_mgr_person_id, assgn_per.contractor_name, assgn_per.hiring_manager_name,
             assgn_per.assignment_type, assgn_per.assignment_start_dt, assgn_per.assignment_end_dt,
             assgn_per.assignment_actual_end_dt, assgn_per.assignment_duration, assgn_per.assignment_state_id, 
             assgn_per.current_phase_type_id, ap.std_buyerorg_name, ap.std_supplierorg_name,
             ap.std_state, ap.std_city, ap.std_country, ap.std_postal_code, ap.std_region, 
             ap.cmsa_name, ap.metro_name, ap.cmsa_primary_state_code, ap.cmsa_primary_city_name, 
             ap.cmsa_primary_city_lat, ap.cmsa_primary_city_long, ajtc.std_job_title_desc,
             ajtc.std_job_category_desc
        FROM iqprodm.dm_atom_place ap,
             iqprodm.dm_atom_job_title_cat ajtc,
             assgn_per
       WHERE assgn_per.assignment_continuity_id = ap.assignment_continuity_id
         AND ap.data_source_code                = 'REGULAR'
         AND assgn_per.assignment_continuity_id = ajtc.assignment_continuity_id
         AND ajtc.data_source_code              = 'REGULAR' }';

BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');

  UPDATE lego_refresh
     SET refresh_sql = v_clob
   WHERE object_name = v_lego_object_name;  

  COMMIT;

  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  

EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   

END;
/

