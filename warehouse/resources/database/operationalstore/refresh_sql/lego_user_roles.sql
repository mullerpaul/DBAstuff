/*******************************************************************************
SCRIPT NAME         lego_user_roles.sql 
 
LEGO OBJECT NAME    LEGO_USER_ROLES
 
CREATED             4/25/2018
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

04/24/2018 - P.Muller    - IQN-39925  - created this script based on SQL I got from Kathy Formanek
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_user_roles.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_USER_ROLES'; 

  v_clob CLOB := q'{  WITH role_data_to_pivot
    AS (SELECT x.user_fk AS person_id, 
               rc.type   AS role_name
          FROM user_role_constant_x@db_link_name AS OF SCN source_db_SCN x, 
               role_constant@db_link_name        AS OF SCN source_db_SCN rc
         WHERE x.role_constant_fk = rc.value
           AND rc.type IN 
             ('Org Unit Assignment Manager','Work Order and Assignment Manager','Org Unit Job/WO/EA/Project Approver',
              'Assignment Administrator','MSP Administrator','Buyer Firm Executive','ENTERPRISE_ADMIN','IQ Firm Admin',
              'Buyer Firm Admin'))
SELECT *
  FROM role_data_to_pivot
 PIVOT (COUNT(*) FOR role_name IN   -- we can use COUNT to get 0 or 1 due to the multi-column PK on user_role_constant_x
          ('Org Unit Assignment Manager'         AS org_unit_assignment_mgr,
           'Work Order and Assignment Manager'   AS work_order_and_assignment_mgr,
           'Org Unit Job/WO/EA/Project Approver' AS org_unit_job_wo_ea_proj_apprvr,
           'Assignment Administrator'            AS assignment_administrator ,
           'MSP Administrator'                   AS msp_administrator,
           'Buyer Firm Executive'                AS buyer_firm_executive,
           'ENTERPRISE_ADMIN'                    AS enterprise_admin,
           'IQ Firm Admin'                       AS iq_firm_admin,
           'Buyer Firm Admin'                    AS buyer_firm_admin))}';

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

