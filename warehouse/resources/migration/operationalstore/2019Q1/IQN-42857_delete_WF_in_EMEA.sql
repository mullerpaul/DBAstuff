DECLARE  
     lc_db_name        VARCHAR2(30);
     ln_delete_count   PLS_INTEGER;
     lc_logging_source VARCHAR2(30) := 'IQN-42857-MigrationScript';
BEGIN
      logger_pkg.instantiate_logger;  
      logger_pkg.set_source(lc_logging_source);
      logger_pkg.set_code_location('Migration Script');
      logger_pkg.set_level('INFO');
      logger_pkg.info('Checking DB Name');
        
     SELECT global_name
       INTO lc_db_name
       FROM global_name;
      
     IF (lc_db_name = 'PR01') 
     THEN
        -- EMEA is PR01
             
       logger_pkg.info('Deleting WF rows from lego_refresh_dependency');
        DELETE FROM lego_refresh_dependency
              WHERE source_name = 'WFPROD';
        
        ln_delete_count := SQL%ROWCOUNT;
        
        COMMIT;
        logger_pkg.info('Deleted ' ||  ln_delete_count || ' WF rows from lego_refresh_dependency');
     ELSE
        logger_pkg.info('This is not EMEA PROD database. No rows deleted.');
     
     END IF;
      
     logger_pkg.info('IQN-42857-MigrationScript Completed');
     logger_pkg.unset_source(lc_logging_source);
   
EXCEPTION
        WHEN OTHERS THEN
            logger_pkg.fatal(
                pi_transaction_result   => NULL,
                pi_error_code           => SQLCODE,
                pi_message              => SQLERRM
            );

            logger_pkg.unset_source(lc_logging_source);
            RAISE;
END;
/




