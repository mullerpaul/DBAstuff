/*******************************************************************************
SCRIPT NAME         lego_blone_linked_fo_accounts.sql
 
LEGO OBJECT NAME    LEGO_BLONE_LINKED_FO_ACCOUNT
 
CREATED             10/18/2018
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

10/18/2018 - Paul Muller - IQN-41512 - created
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_blone_linked_fo_accounts.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_BLONE_LINKED_FO_ACCOUNT'; 

  v_clob CLOB :=
      q'{SELECT c.account_service_guid, c.account_id, c.service_user_name, c.service_user_domain
  FROM auth.one_service@db_link_name p,   -- no AS OF clauses because we don't have the FLASHBACK priv in this source.
       auth.one_account_service@db_link_name c
 WHERE p.one_service_guid = c.service_guid
   AND p.provider = 'IQN'  -- I had assumed the parent table represented the BLone account and the child table the linked VMS 
   AND p.name = 'IQN'      -- accounts; but thats not true.  Apparently there is no master table with 1 row per account_id.
}';

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

