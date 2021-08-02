CREATE OR REPLACE PACKAGE BODY dashboard_data_api AS

  /******************************************************************************
     NAME:       dashboard_data_api
     PURPOSE:    Serve as communication between dashboards and the database.
  
     REVISIONS:
     Jira       Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
                04/27/2016  Paul Muller      Created this package.
                05/20/2016  Paul & Joe       Added APIs for assignments by location
     IQN-32025  08/05/2016  Paul Muller      overhaul org security model to match FO.
     IQN-33571  "           "                "
     IQN-32066  08/05/2016  Paul Muller      add monthly assignment count API
     IQN-33725  08/05/2016  Paul Muller      get_most_recent_time works per widget
     IQN-40224  09/19/2018  Paul Muller      change get_most_recent_time to use per-consumer
                                             lego refresh method.

  ******************************************************************************/

  ----------------------------------------------------------------------------------
  PROCEDURE log_usage(pi_api_name        IN VARCHAR2,
                      pi_login_user      IN NUMBER DEFAULT NULL,
                      pi_login_org       IN NUMBER DEFAULT NULL,
                      pi_security_type   IN VARCHAR2 DEFAULT NULL,
                      pi_parameter_value IN VARCHAR2 DEFAULT NULL) AS
    PRAGMA AUTONOMOUS_TRANSACTION;
  
  BEGIN
    INSERT INTO dashboard_api_calls
      (api_name, login_user_id, login_org, security_type, parameter_value)
    VALUES
      (pi_api_name, pi_login_user, pi_login_org, pi_security_type, pi_parameter_value);
  
    COMMIT;
  END log_usage;

  ----------------------------------------------------------------------------------
  PROCEDURE upcoming_ends_rollup(pi_login_user    IN NUMBER,
                                 pi_login_org     IN NUMBER,
                                 pi_security_type IN VARCHAR,
                                 po_resultset     OUT SYS_REFCURSOR) AS
  BEGIN
    CASE pi_security_type
      WHEN 'org' THEN
        log_usage(pi_api_name      => 'upcoming ends',
                  pi_security_type => 'org',
                  pi_login_user    => pi_login_user,
                  pi_login_org     => pi_login_org);
      
        OPEN po_resultset FOR
          SELECT days_until_assignment_end, job_category, assignment_count
            FROM operationalstore.lego_upcoming_ends_org_roll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;

      WHEN 'row' THEN
        log_usage(pi_api_name      => 'upcoming ends',
                  pi_security_type => 'row',
                  pi_login_user    => pi_login_user,
                  pi_login_org     => pi_login_org);
      
        OPEN po_resultset FOR
          SELECT days_until_assignment_end, job_category, assignment_count
            FROM operationalstore.lego_upcoming_ends_row_roll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;
      
      ELSE
        raise_application_error(-20201, 'Invalid security type');
    END CASE;
  
  END upcoming_ends_rollup;

  ----------------------------------------------------------------------------------
  PROCEDURE req_by_status_rollup(pi_login_user    IN NUMBER,
                                 pi_login_org     IN NUMBER,
                                 pi_security_type IN VARCHAR,
                                 po_resultset     OUT SYS_REFCURSOR) AS
  BEGIN
    CASE pi_security_type
      WHEN 'org' THEN
        log_usage(pi_api_name      => 'req by status',
                  pi_security_type => 'org',
                  pi_login_user    => pi_login_user,
                  pi_login_org     => pi_login_org);
      
        OPEN po_resultset FOR
          SELECT current_phase, jc_description, requisition_count
            FROM operationalstore.lego_req_by_status_org_roll_vw
           WHERE login_org_id = pi_login_org
             AND login_user_id = pi_login_user; 
      
      WHEN 'row' THEN
        log_usage(pi_api_name      => 'req by status',
                  pi_security_type => 'row',
                  pi_login_user    => pi_login_user,
                  pi_login_org     => pi_login_org);
      
        OPEN po_resultset FOR
          SELECT current_phase, jc_description, requisition_count
            FROM operationalstore.lego_req_by_status_row_roll_vw
           WHERE login_org_id = pi_login_org
             AND login_user_id = pi_login_user; 
      
      ELSE
        raise_application_error(-20201, 'Invalid security type');
    END CASE;

  END req_by_status_rollup;

  ----------------------------------------------------------------------------------
  PROCEDURE monthly_assignment_count(pi_login_user    IN NUMBER,
                                     pi_login_org     IN NUMBER,
                                     pi_security_type IN VARCHAR,
                                     po_resultset     OUT SYS_REFCURSOR) AS
  BEGIN
    CASE pi_security_type
      WHEN 'org' THEN
        log_usage(pi_api_name      => 'monthly assignment count',
                  pi_security_type => 'org',
                  pi_login_user    => pi_login_user,
                  pi_login_org     => pi_login_org);
      
        OPEN po_resultset FOR
          /* uses same view as mnthly_assgn_cnt_and_inv_spend  */
          SELECT month_start                  AS month_start_date, 
                 monthly_assignment_count     AS assignment_count
            FROM operationalstore.lego_mnthasgncntspnd_orgrll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;
      
      WHEN 'row' THEN
        log_usage(pi_api_name      => 'monthly assignment count',
                  pi_security_type => 'row',
                  pi_login_user    => pi_login_user,
                  pi_login_org     => pi_login_org);
      
        OPEN po_resultset FOR
          /* uses same view as mnthly_assgn_cnt_and_inv_spend  */
          SELECT month_start                  AS month_start_date, 
                 monthly_assignment_count     AS assignment_count
            FROM operationalstore.lego_mnthasgncntspnd_rowrll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;
      
      ELSE
        raise_application_error(-20201, 'Invalid security type');

    END CASE;
  END monthly_assignment_count;

  ----------------------------------------------------------------------------------
  PROCEDURE mnthly_assgn_cnt_and_inv_spend(pi_login_user    IN NUMBER,
                                           pi_login_org     IN NUMBER,
                                           pi_security_type IN VARCHAR,
                                           po_resultset     OUT SYS_REFCURSOR) AS
  BEGIN
    CASE pi_security_type
      WHEN 'org' THEN
        log_usage(pi_api_name      => 'mnthly assgn count & inv spend',
                  pi_security_type => 'org',
                  pi_login_user    => pi_login_user,
                  pi_login_org     => pi_login_org);
      
        OPEN po_resultset FOR
          SELECT month_start                  AS month_start_date, 
                 monthly_assignment_count     AS assignment_count, 
                 monthly_invoiced_buyer_spend AS buyer_invd_assign_spend_amt
            FROM operationalstore.lego_mnthasgncntspnd_orgrll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;
      
      WHEN 'row' THEN
        log_usage(pi_api_name      => 'mnthly assgn count & inv spend',
                  pi_security_type => 'row',
                  pi_login_user    => pi_login_user,
                  pi_login_org     => pi_login_org);
      
        OPEN po_resultset FOR
          SELECT month_start                  AS month_start_date, 
                 monthly_assignment_count     AS assignment_count, 
                 monthly_invoiced_buyer_spend AS buyer_invd_assign_spend_amt
            FROM operationalstore.lego_mnthasgncntspnd_rowrll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;
      
      ELSE
        raise_application_error(-20201, 'Invalid security type');

    END CASE;
  END mnthly_assgn_cnt_and_inv_spend;

  ----------------------------------------------------------------------------------
  PROCEDURE assignments_by_country(pi_login_user    IN NUMBER,
                                   pi_login_org     IN NUMBER,
                                   pi_security_type IN VARCHAR,
                                   pi_region        IN VARCHAR DEFAULT NULL, --currently unused
                                   pi_country       IN VARCHAR,
                                   po_resultset     OUT SYS_REFCURSOR) AS
  BEGIN
    IF pi_country <> 'US'
    THEN
      /* We want to add support for UK at some point */
      raise_application_error(-20202, 'That country not supported yet!');
    END IF;
  
    CASE pi_security_type
      WHEN 'org' THEN
        log_usage(pi_api_name        => 'assignments by country',
                  pi_security_type   => 'org',
                  pi_login_user      => pi_login_user,
                  pi_login_org       => pi_login_org,
                  pi_parameter_value => pi_country);
      
        OPEN po_resultset FOR
          SELECT cmsa_primary_state_code, effective_assgn_count
            FROM operationalstore.assgn_loc_st_atom_orgroll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;

      
      WHEN 'row' THEN
        log_usage(pi_api_name        => 'assignments by country',
                  pi_security_type   => 'row',
                  pi_login_user      => pi_login_user,
                  pi_login_org       => pi_login_org,
                  pi_parameter_value => pi_country);
      
        OPEN po_resultset FOR
          SELECT cmsa_primary_state_code, effective_assgn_count
            FROM operationalstore.assgn_loc_st_atom_rowroll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;
      
      ELSE
        raise_application_error(-20201, 'Invalid security type');
    END CASE;
  
  END assignments_by_country;

  ----------------------------------------------------------------------------------
  PROCEDURE assignments_by_cmsa(pi_login_user    IN NUMBER,
                                pi_login_org     IN NUMBER,
                                pi_security_type IN VARCHAR,
                                pi_region        IN VARCHAR DEFAULT NULL, --currently unused
                                pi_country       IN VARCHAR,
                                po_resultset     OUT SYS_REFCURSOR) AS
  BEGIN
    IF pi_country <> 'US'
    THEN
      /* We want to add support for UK at some point */
      raise_application_error(-20202, 'That country not supported yet!');
    END IF;
  
    CASE pi_security_type
      WHEN 'org' THEN
        log_usage(pi_api_name        => 'assignments by cmsa',
                  pi_security_type   => 'org',
                  pi_login_user      => pi_login_user,
                  pi_login_org       => pi_login_org,
                  pi_parameter_value => pi_country);
      
        OPEN po_resultset FOR
          SELECT cmsa_primary_state_code,
                 metro_name,
                 cmsa_primary_city_name,
                 cmsa_primary_city_lat,
                 cmsa_primary_city_long,
                 effective_assgn_count
            FROM operationalstore.assgn_loc_cmsa_atom_orgroll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;

      WHEN 'row' THEN
        log_usage(pi_api_name        => 'assignments by cmsa',
                  pi_security_type   => 'row',
                  pi_login_user      => pi_login_user,
                  pi_login_org       => pi_login_org,
                  pi_parameter_value => pi_country);
      
        OPEN po_resultset FOR
          SELECT cmsa_primary_state_code,
                 metro_name,
                 cmsa_primary_city_name,
                 cmsa_primary_city_lat,
                 cmsa_primary_city_long,
                 effective_assgn_count
            FROM operationalstore.assgn_loc_cmsa_atom_rowroll_vw
           WHERE login_user_id = pi_login_user
             AND login_org_id = pi_login_org;

      ELSE
        raise_application_error(-20201, 'Invalid security type');
    END CASE;
    
  END assignments_by_cmsa;
 
  ----------------------------------------------------------------------------------
  FUNCTION get_most_recent_refresh_time(pi_widget_name IN VARCHAR2 DEFAULT 'all') RETURN DATE IS
    lv_result TIMESTAMP;
  
  BEGIN
    CASE
      WHEN lower(pi_widget_name) = 'all' THEN
        /* last time the dashboard legos were refreshed.  */
        log_usage(pi_api_name => 'most recent refresh', pi_parameter_value => pi_widget_name);
      
        /* pmuller - IQN-40224 - Sept 19, 2018
           Dramatically changing this query to take advantage of the new lego refresh methodology.
           We will likely have to tune this query once we get a reasonable amount of data.
           Perhaps we could add a "job_runtime > 5 days ago", or change indexes on the two history tables.  */
        /* pmuller - IQN-43308 - April 4, 2019
           Fixing mistake I made in previous modification.  Also adding a lookback limit of two months.
            If the legos have not been refreshed in 2 months, we could return NULL; but I've decided to instead return 
            a date 2 months ago.  I'm not 100% sure this is a good idea and could be convinced either way.  It should only
            be an issue in QA and lower envs where legos are not refreshed regularly. */
        SELECT NVL(MAX(job_runtime), TRUNC(sys_extract_utc(systimestamp) - INTERVAL '2' MONTH))
          INTO lv_result
          FROM (SELECT p.job_runtime, 
                       COUNT(*) as legos_started, 
                       COUNT(CASE WHEN c.status='released' THEN 'x' END) as legos_completed
                  FROM operationalstore.lego_refresh_run_history p,
                       operationalstore.lego_refresh_history c
                 WHERE p.job_runtime = c.job_runtime
                   AND p.caller_name = 'Dashboards'
                   AND p.job_runtime > sys_extract_utc(systimestamp) - INTERVAL '2' MONTH 
                 GROUP BY p.job_runtime)
         WHERE legos_completed = legos_started;

      ELSE
        /* pmuller - IQN-40224 - Sept 19, 2018
           We had a bunch of other possibilities here; but they were for the old (pre IQN-40224) refresh system 
           and are no longer needed.  Whats more, they are not being used and they are not even very accurate!  
           I've removed them all and replaced with an error. */
        log_usage(pi_api_name => 'most recent refresh', pi_parameter_value => pi_widget_name);

        raise_application_error(-20202, 'Nothing implemented for that input yet');
    END CASE;
  
    RETURN CAST(lv_result AS DATE);
  
  END get_most_recent_refresh_time;

END dashboard_data_api;
/
