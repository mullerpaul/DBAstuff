-- When this goes out, we will be adding a new column to all of the rollup tables and views.
-- This leads to 2 different issues:
-- 1. adding the columns to the views before they are on the toggle tables will make the views 
--    invalid, which will cause the grant script to fail during migration.  We can get 
--    around this by adding empty columns to the toggle tables.  (see other migration script)
--    But those empty columns lead to the other problem!
-- 2. While that column is empty, no dashboards will be able to get any results.
--    To get around that, we will schedule and start a refresh.

-- This script is for part 2 above.  It lives in postops and starts a refresh.
-- We need to be careful so that this:
--    Does the desired thing in PROD, 
--    AND doesn't mess things up in non-refreshing environments, 
--    AND works in "from-scratch" deploys.

-- This update works well since refresh_or_or_after_time will remain NULL if it started off as NULL.
-- In prod, we can assume refresh_on_or_after_time is in the range sysdate plus or minus 1 day, so this 
-- update should put it into the past.
-- In non-refreshing envs where its not null, it doesn't really matter what this is set to.  If the call to
-- refresh_mgr_pkg.refresh fails there, we will catch, log and ignore the error!
UPDATE lego_refresh
   SET refresh_on_or_after_time = refresh_on_or_after_time - 2
 WHERE source_name = 'USPROD'
   AND object_name IN ('LEGO_REQ_BY_STATUS_ORG_ROLLUP','LEGO_REQ_BY_STATUS_ROW_ROLLUP',
                       'LEGO_MNTH_ASGN_CNTSPND_ORGROLL','LEGO_MNTH_ASGN_CNTSPND_ROWROLL',
                       'LEGO_UPCOMING_ENDS_ORG_ROLLUP','LEGO_UPCOMING_ENDS_ROW_ROLLUP',
                       'LEGO_ASSGN_LOC_ST_ATOM_OR','LEGO_ASSGN_LOC_ST_ATOM_RR',
                       'LEGO_ASSGN_LOC_CMSA_ATOM_OR','LEGO_ASSGN_LOC_CMSA_ATOM_RR')
/

COMMIT
/

-- now start refresh
DECLARE
  lv_group_list lego_group_list_type := lego_group_list_type(8, 11); -- job and assignment groups

BEGIN
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source('POSTOPS');
  logger_pkg.set_code_location('Calling refresh procedure');

  logger_pkg.info('calling refresh for groups 8 and 11 - starting');
  lego_refresh_mgr_pkg.refresh(pi_refresh_group => lv_group_list);
  logger_pkg.info('calling refresh for groups 8 and 11 - complete', TRUE);

  logger_pkg.unset_source('POSTOPS');

EXCEPTION
  WHEN OTHERS THEN
    /* We might reasonable expect the following errors:
          Refreshes already running
          No database link
       In both cases, there is nothing we can do but log the error.
       Unlike most cases, we do NOT want to re-raise the error here!   */
    logger_pkg.error(pi_transaction_result => NULL,
                     pi_error_code         => SQLCODE,
                     pi_message            => 'Could not start refresh job!! ' || SQLERRM);

    logger_pkg.unset_source('POSTOPS');
END;
/
