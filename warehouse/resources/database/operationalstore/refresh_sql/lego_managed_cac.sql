/*******************************************************************************
SCRIPT NAME         lego_managed_cac.sql 
 
LEGO OBJECT NAME    LEGO_MANAGED_CAC
 
CREATED             6/13/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

01/27/2016 - P.Muller                 - Modifications for DB links, multiple sources, and remote SCN
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_managed_cac.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MANAGED_CAC'; 

  v_clob CLOB :=
            q'{SELECT DISTINCT
       fw.never_null_person_fk AS user_id,     
       cn.categorizable_fk     AS cac_value_id
  FROM category_node@db_link_name AS OF SCN source_db_SCN            cn,
       cat_node_lineage@db_link_name AS OF SCN source_db_SCN         l,
       category_node@db_link_name AS OF SCN source_db_SCN            cnr,  -- for ROOT node
       cat_node_lineage@db_link_name AS OF SCN source_db_SCN         lr,   -- to find ROOT node
       category_node_managers_x@db_link_name AS OF SCN source_db_SCN m,
       firm_worker@db_link_name AS OF SCN source_db_SCN              fw
 WHERE cn.categorizable_type   = 'CACValue'
   AND cn.category_node_id     = l.descendant_cat_node_fk
   AND l.ancestor_cat_node_fk  = m.category_node_fk
   AND m.manager_fk            = fw.firm_worker_id
   AND cn.category_node_id     = lr.descendant_cat_node_fk 
   AND lr.ancestor_cat_node_fk = cnr.category_node_id 
   AND cnr.node_type           = 'ROOT'
 ORDER BY 1,2}';

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

