/*******************************************************************************
SCRIPT NAME         lego_assignment_slots.sql 
 
LEGO OBJECT NAME    LEGO_ASSIGNMENT_SLOTS
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

03/31/2014 - E.Clark - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2 
08/15/2014 - pmuller - IQN-19828 - added comments - Release 12.2
01/27/2016 - pmuller             - Modifications for DB links, multiple sources, and remote SCN
04/19/2016 - pmuller             - renamed from LEGO_SECURE_ASSIGNMENT, removed dependency on LEGO_ASSIGNMENT.
                                   Added months_in_refresh filter instead.
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_assignment_slots.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_ASSIGNMENT_SLOTS'; 

  v_clob CLOB :=
   q'{SELECT assignment_continuity.assignment_continuity_id assignment_id,
       firm_role.business_org_fk business_organization_id,
       never_null_person_fk user_id
  FROM firm_worker@db_link_name AS OF SCN source_db_SCN,
       assignment_continuity@db_link_name AS OF SCN source_db_SCN,
       assignment_edition@db_link_name AS OF SCN source_db_SCN,
       firm_role@db_link_name AS OF SCN source_db_SCN
 WHERE assignment_continuity.current_edition_fk       = assignment_edition.assignment_edition_id
   AND assignment_continuity.owning_buyer_firm_fk     = firm_role.firm_id
   AND firm_worker.firm_worker_id IN
                    (assignment_edition.hiring_mgr_fk,        -- the hiring manager can see the assignment.
                     assignment_edition.assignment_admin_fk,  -- the assignment admin can see the assignment.
                     assignment_edition.cam_firm_worker_fk)   -- the CAM can see the assignment.
   AND (assignment_edition.actual_end_date IS NULL OR   -- not sure what NULL means here.  Keeping those rows included just in case. 
        assignment_edition.actual_end_date >= ADD_MONTHS(TRUNC(SYSDATE), -months_in_refresh))
 UNION  -- the upper half is for buyer side slots, the bottom half is for supplier side slots.
SELECT assignment_continuity.assignment_continuity_id assignment_id,
       firm_role.business_org_fk business_organization_id,
       never_null_person_fk user_id
  FROM firm_worker@db_link_name AS OF SCN source_db_SCN,
       assignment_continuity@db_link_name AS OF SCN source_db_SCN,
       assignment_edition@db_link_name AS OF SCN source_db_SCN,
       firm_role@db_link_name AS OF SCN source_db_SCN
 WHERE assignment_continuity.current_edition_fk       = assignment_edition.assignment_edition_id
   AND assignment_continuity.owning_supply_firm_fk    = firm_role.firm_id
   AND firm_worker.firm_worker_id IN
                    (assignment_edition.supplier_account_rep,  -- the supplier account rep can see the assignment.
                     assignment_edition.supplier_agent_fk)     -- the supplier agent can see the assignment.
   AND (assignment_edition.actual_end_date IS NULL OR   -- not sure what NULL means here.  Keeping those rows included just in case. 
        assignment_edition.actual_end_date >= ADD_MONTHS(TRUNC(SYSDATE), -months_in_refresh))}';

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

