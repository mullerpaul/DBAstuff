/*******************************************************************************
SCRIPT NAME         lego_managed_person.sql 
 
LEGO OBJECT NAME    LEGO_MANAGED_PERSON
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

01/27/2016 - P.Muller                 - Modifications for DB links, multiple sources, and remote SCN
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_managed_person.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MANAGED_PERSON'; 

  v_clob CLOB :=
            q'{SELECT m.categorizable_fk AS manager_person_id,
                   g.categorizable_fk AS employee_person_id
              FROM category_node@db_link_name AS OF SCN source_db_SCN    m,  -- manager
                   category_node@db_link_name AS OF SCN source_db_SCN    g,  -- employee
                   category_node@db_link_name AS OF SCN source_db_SCN    r,  -- to find ROOT level and exclude orphan branches
                   cat_node_lineage@db_link_name AS OF SCN source_db_SCN l,  -- between manager and employee
                   cat_node_lineage@db_link_name AS OF SCN source_db_SCN l2, -- between manager and root node
                   iq_user@db_link_name AS OF SCN source_db_SCN          u   -- only users who might log in to Jasper
             WHERE g.category_node_id   = l.descendant_cat_node_fk
               AND m.category_node_id   = l.ancestor_cat_node_fk
               AND m.category_node_id   = l2.descendant_cat_node_fk
               AND r.category_node_id   = l2.ancestor_cat_node_fk
               AND m.categorizable_fk   = u.person_fk
               AND r.node_type          = 'ROOT'
               AND g.categorizable_type = 'Person'
               AND m.categorizable_type = 'Person'
             UNION  -- not UNION ALL since we need a distinct list
            SELECT person_fk AS manager_person_id,  -- This block adds a self row for users who may not be in a heirarchy
                   person_fk AS employee_person_id
              FROM iq_user@db_link_name AS OF SCN source_db_SCN}';

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

