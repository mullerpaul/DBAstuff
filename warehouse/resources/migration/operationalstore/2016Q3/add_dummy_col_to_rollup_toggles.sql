-- When this goes out, we will be adding a new column to all of the rollup tables and views.
-- This leads to 2 different issues:
-- 1. adding the columns to the views before they are on the toggle tables will make the views 
--    invalid, which will cause the grant script to fail during migration.  We can get 
--    around this by adding empty columns to the toggle tables.  (see other migration script)
--    But those empty columns lead to the other problem!
-- 2. While that column is empty, no dashboards will be able to get any results.
--    To get around that, we will schedule and start a refresh.

-- This script is for part 1 above.  It lives in the migration folder.
-- We need to be careful so that this:
--    Does the desired thing in PROD and other DB where the toggle tables exist, 
--    AND works in "from-scratch" deploys where the toggle tables don't exist.

-- This script will loop over all the EXISTING toggle tables for the 10 rollup legos
-- and ensure each has BOTH login_user_id and login_org_id columns.

DECLARE
  le_col_already_exists EXCEPTION;
  PRAGMA EXCEPTION_INIT(le_col_already_exists, -1430);

  CURSOR existing_toggle_tables IS
    WITH toggle_table_list AS
     (SELECT object_name, refresh_object_name_1 AS toggle_table_name
        FROM lego_refresh a
       WHERE source_name = 'USPROD'
         AND object_name IN ('LEGO_REQ_BY_STATUS_ORG_ROLLUP',
                             'LEGO_REQ_BY_STATUS_ROW_ROLLUP',
                             'LEGO_MNTH_ASGN_CNTSPND_ORGROLL',
                             'LEGO_MNTH_ASGN_CNTSPND_ROWROLL',
                             'LEGO_UPCOMING_ENDS_ORG_ROLLUP',
                             'LEGO_UPCOMING_ENDS_ROW_ROLLUP',
                             'LEGO_ASSGN_LOC_ST_ATOM_OR',
                             'LEGO_ASSGN_LOC_ST_ATOM_RR',
                             'LEGO_ASSGN_LOC_CMSA_ATOM_OR',
                             'LEGO_ASSGN_LOC_CMSA_ATOM_RR')
      UNION ALL
      SELECT object_name, refresh_object_name_2 AS toggle_table_name
        FROM lego_refresh a
       WHERE source_name = 'USPROD'
         AND object_name IN ('LEGO_REQ_BY_STATUS_ORG_ROLLUP',
                             'LEGO_REQ_BY_STATUS_ROW_ROLLUP',
                             'LEGO_MNTH_ASGN_CNTSPND_ORGROLL',
                             'LEGO_MNTH_ASGN_CNTSPND_ROWROLL',
                             'LEGO_UPCOMING_ENDS_ORG_ROLLUP',
                             'LEGO_UPCOMING_ENDS_ROW_ROLLUP',
                             'LEGO_ASSGN_LOC_ST_ATOM_OR',
                             'LEGO_ASSGN_LOC_ST_ATOM_RR',
                             'LEGO_ASSGN_LOC_CMSA_ATOM_OR',
                             'LEGO_ASSGN_LOC_CMSA_ATOM_RR'))
    SELECT ttl.object_name, ttl.toggle_table_name
      FROM user_tables       ut, -- only get tables which actually exist!
           toggle_table_list ttl
     WHERE ut.table_name = ttl.toggle_table_name
     ORDER BY ttl.object_name, ttl.toggle_table_name;

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('MIGRATION SCRIPT');
  logger_pkg.set_code_location('Adding column to dashboard rollup toggle tables');

  logger_pkg.info('looping over existinig toggle tables');
  FOR i IN existing_toggle_tables LOOP
    /* Add login_user_id col */
    BEGIN
      EXECUTE IMMEDIATE('alter table ' || i.toggle_table_name || ' add (login_user_id number)');
      logger_pkg.info('Added LOGIN_USER_ID column to ' || i.toggle_table_name);
    EXCEPTION
      WHEN le_col_already_exists THEN
        logger_pkg.info('LOGIN_USER_ID column already existed on ' || i.toggle_table_name);
    END;
        
    /* Add login_org_id col */
    BEGIN
      EXECUTE IMMEDIATE('alter table ' || i.toggle_table_name || ' add (login_org_id number)');
      logger_pkg.info('Added LOGIN_ORG_ID column to ' || i.toggle_table_name);
    EXCEPTION
      WHEN le_col_already_exists THEN
        logger_pkg.info('LOGIN_ORG_ID column already existed on ' || i.toggle_table_name);
    END;

  END LOOP;  
  logger_pkg.info('completed looping over existing toggle tables and adding columns!');
  logger_pkg.unset_source('MIGRATION SCRIPT');
            
END;
/
