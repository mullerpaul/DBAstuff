/* Formatted on 4/4/2019 1:22:58 PM (QP5 v5.267.14150.38599) */
DECLARE
   wf_db_link_name     VARCHAR2 (30);
   ln_delete_count     PLS_INTEGER;
   ln_wf_link_cnt      PLS_INTEGER := 0;
   ls_value            CHAR (1);
   lc_logging_source   VARCHAR2 (300)
                          := 'Lego dependency correction - MigrationScript';
BEGIN
   logger_pkg.instantiate_logger;
   logger_pkg.set_source (lc_logging_source);
   logger_pkg.set_code_location ('Migration Script');
   logger_pkg.set_level ('INFO');
   logger_pkg.info ('Checking DB Name');

   SELECT  COUNT (*)
     INTO ln_wf_link_cnt
     FROM user_db_links
    WHERE HOST = 'WAP';  

   IF ln_wf_link_cnt = 0  THEN
         logger_pkg.info ('Deleting WF rows from lego_refresh_dependency');

         DELETE FROM lego_refresh_dependency
               WHERE source_name = 'WFPROD';

         ln_delete_count := SQL%ROWCOUNT;

         COMMIT;
         logger_pkg.info (
               'Deleted '
            || ln_delete_count
            || ' WF rows from lego_refresh_dependency');
      ELSE
         logger_pkg.info ('This WF production database.');
      END IF;
 

   logger_pkg.info ('Lego dependency correction - MigrationScript Completed');
   logger_pkg.unset_source (lc_logging_source);
EXCEPTION
   WHEN OTHERS
   THEN
      logger_pkg.fatal (pi_transaction_result   => NULL,
                        pi_error_code           => SQLCODE,
                        pi_message              => SQLERRM);

      logger_pkg.unset_source (lc_logging_source);
      RAISE;
END;
/





