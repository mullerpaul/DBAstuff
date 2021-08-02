/*******************************************************************************
SCRIPT NAME         lego_secure_project_agreement.sql 
 
LEGO OBJECT NAME    LEGO_SECURE_PROJECT_AGREEMENT
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

04/01/2014 - E.Clark - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2 
08/15/2014 - pmuller - IQN-19828 - added comments - Release 12.2
01/27/2016 - pmuller             - Modifications for DB links, multiple sources, and remote SCN

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_secure_project_agreement.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_SECURE_PROJECT_AGREEMENT'; 

  v_clob CLOB :=
    q'{SELECT project_agreement.contract_id project_agreement_id,
       firm_worker.never_null_person_fk user_id,
       firm_role.business_org_fk business_organization_id
  FROM firm_worker@db_link_name AS OF SCN source_db_SCN,
       project_agreement@db_link_name AS OF SCN source_db_SCN,
       firm_role@db_link_name AS OF SCN source_db_SCN,
       project@db_link_name AS OF SCN source_db_SCN,
       lego_project_agreement  -- gotta point this at the correct synonym.  perhaps make this a proc toggle? or remove this dependency?
 WHERE project_agreement.contract_id = lego_project_agreement.project_agreement_id
   AND project_agreement.project_fk = project.project_id
   AND ( (project.buyer_firm_fk = firm_role.firm_id
              AND firm_worker.firm_worker_id IN
                     (project_agreement.customer_manager_fk,               -- customer manager can see the PA.
                      project_agreement.org_unit_proj_agmt_mgr_fk,         -- org unit project amount manager can see the PA.
                      project_agreement.project_manager_fk))               -- project manager can see the PA.
            OR (project_agreement.supply_firm_fk = firm_role.firm_id  -- Performance improvement idea: change this to another UNION block
                AND firm_worker.firm_worker_id IN
                       (project_agreement.milestone_invoice_submitter_fk,  -- milestone invoice submitter can see the PA.
                        project_agreement.supplier_project_manager_fk)))   -- supplier project maanger can see the PA.
 UNION   -- planned approver on milestone invoice
SELECT project_agreement.contract_id project_agreement_id,
       firm_worker.never_null_person_fk user_id,
       firm_role.business_org_fk business_organization_id
  FROM firm_worker@db_link_name AS OF SCN source_db_SCN,
       project_agreement@db_link_name AS OF SCN source_db_SCN,
       named_approver@db_link_name AS OF SCN source_db_SCN,
       firm_role@db_link_name AS OF SCN source_db_SCN,
       project@db_link_name AS OF SCN source_db_SCN,
       lego_project_agreement  -- gotta point this at the correct synonym.  perhaps make this a proc toggle? or remove this dependency?
 WHERE project_agreement.contract_id = lego_project_agreement.project_agreement_id
   AND project_agreement.billevt_approval_proc_spec_fk = named_approver.approval_process_spec_fk
   AND named_approver.approver_fk = firm_worker.firm_worker_id
   AND project_agreement.project_fk = project.project_id
   AND project.buyer_firm_fk = firm_role.firm_id
 UNION   -- actual approver on milestone invoice.  no RBAW data here.
SELECT project_agreement.contract_id project_agreement_id,
       firm_worker.never_null_person_fk user_id,
       firm_role.business_org_fk business_organization_id
  FROM firm_worker@db_link_name AS OF SCN source_db_SCN,
       project_agreement@db_link_name AS OF SCN source_db_SCN,
       named_approver@db_link_name AS OF SCN source_db_SCN,
       firm_role@db_link_name AS OF SCN source_db_SCN,
       project@db_link_name AS OF SCN source_db_SCN,
       milestone_invoice@db_link_name AS OF SCN source_db_SCN,
       lego_project_agreement  -- gotta point this at the correct synonym.  perhaps make this a proc toggle? or remove this dependency?
 WHERE project_agreement.contract_id = lego_project_agreement.project_agreement_id
   AND project_agreement.contract_id = milestone_invoice.project_agreement_fk
   AND milestone_invoice.billevt_approval_proc_spec_fk = named_approver.approval_process_spec_fk
   AND named_approver.approver_fk = firm_worker.firm_worker_id
   AND project_agreement.project_fk = project.project_id
   AND project.buyer_firm_fk = firm_role.firm_id
 UNION   -- CAMs
SELECT project_agreement.contract_id project_agreement_id,
       firm_worker.never_null_person_fk user_id,
       firm_role.business_org_fk business_organization_id
  FROM firm_worker@db_link_name AS OF SCN source_db_SCN,
       project_agreement@db_link_name AS OF SCN source_db_SCN,
       project_agreement_cams_x@db_link_name AS OF SCN source_db_SCN,
       project@db_link_name AS OF SCN source_db_SCN,
       firm_role@db_link_name AS OF SCN source_db_SCN,
       lego_project_agreement  -- gotta point this at the correct synonym.  perhaps make this a proc toggle? or remove this dependency?
 WHERE project_agreement.contract_id = lego_project_agreement.project_agreement_id
   AND project_agreement.contract_id = project_agreement_cams_x.project_agreement_fk
   AND project_agreement_cams_x.firm_worker_fk = firm_worker.firm_worker_id
   AND project_agreement.project_fk = project.project_id
   AND project.buyer_firm_fk = firm_role.firm_id
 UNION   -- creator of PA change request
SELECT project_agreement.contract_id project_agreement_id,
       contract_version.creator user_id,
       firm_role.business_org_fk business_organization_id
  FROM project_agreement@db_link_name AS OF SCN source_db_SCN,
       contract_version@db_link_name AS OF SCN source_db_SCN,
       project@db_link_name AS OF SCN source_db_SCN,
       firm_role@db_link_name AS OF SCN source_db_SCN,
       lego_project_agreement  -- gotta point this at the correct synonym.  perhaps make this a proc toggle? or remove this dependency?
 WHERE project_agreement.contract_id = lego_project_agreement.project_agreement_id
       AND project_agreement.contract_id = contract_version.contract_fk
       AND project_agreement.project_fk = project.project_id
       AND project.buyer_firm_fk = firm_role.firm_id
 UNION   -- project manager on RFX
SELECT project_agreement.contract_id project_agreement_id,
       firm_worker.never_null_person_fk user_id,
       firm_role.business_org_fk business_organization_id
  FROM project_agreement@db_link_name AS OF SCN source_db_SCN,
       project_rfx_response@db_link_name AS OF SCN source_db_SCN,
       project_rfx_opportunity@db_link_name AS OF SCN source_db_SCN,
       project_rfx_version@db_link_name AS OF SCN source_db_SCN,
       firm_worker@db_link_name AS OF SCN source_db_SCN,
       project@db_link_name AS OF SCN source_db_SCN,
       firm_role@db_link_name AS OF SCN source_db_SCN,
       lego_project_agreement  -- gotta point this at the correct synonym.  perhaps make this a proc toggle? or remove this dependency?
 WHERE project_agreement.contract_id = lego_project_agreement.project_agreement_id
   AND project_agreement.source_project_rfx_response_fk = project_rfx_response.response_id
   AND project_rfx_response.opportunity_fk = project_rfx_opportunity.opportunity_id
   AND project_rfx_opportunity.project_rfx_fk = project_rfx_version.project_rfx_fk
   AND project_rfx_version.object_version_state = 2
   AND project_rfx_version.project_manager_fk = firm_worker.firm_worker_id
   AND project_agreement.project_fk = project.project_id
   AND project.buyer_firm_fk = firm_role.firm_id}';

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

