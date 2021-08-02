/*******************************************************************************
SCRIPT NAME         lego_mnth_assgn_list_spend_det.sql
 
LEGO OBJECT NAME    LEGO_MNTH_ASSGN_LIST_SPEND_DET
 
***************************MODIFICATION HISTORY ********************************

05/23/2018 - Paul Muller    - IQN-40327 - Initial version. SQL and comments taken from LEGO_DASHBOARD_REFRESH
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_mnth_assgn_list_spend_det.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MNTH_ASSGN_LIST_SPEND_DET'; 

    /* Changed from outer to inner join for IQN-34465.  But after making that change, I realized this lego
       doesn't even need LEGO_MONTHLY_ASSIGNMENTS anymore, so I removed it and now there is no join at all!
       That lego contains info about how many assignments WERE ACTIVE in that month; but for a syncronized line
       graph, both attributes should be measured over the same set of assignments.  So we are now counting how
       many assignments WERE INVOICED in a month instead of how many WERE ACTIVE.  */

    /*  We may later want to add more detail to this table so it can serve as a source for later
        tabular request from API.  Join to org & person legos. */
  v_clob CLOB :=
    q'{SELECT assignment_continuity_id,
       buyer_org_id,
       invoice_month_date          AS month_start,
       buyer_invd_assign_spend_amt AS invoiced_spend_per_month
  FROM buyer_invd_assign_spnd_mon_mv
 WHERE invoice_month_date >= TRUNC(add_months(SYSDATE, -12), 'MM') -- rolling 12 months window
   AND currency = 'USD'   -- only USD for now
   AND source_name = 'USPROD'}';

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

