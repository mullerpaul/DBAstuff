CREATE OR REPLACE PACKAGE dashboard_data_api IS

  /******************************************************************************
     NAME:       dashboard_data_api
     PURPOSE:    Serve as communication between dashboards and the database.
  
     REVISIONS:
     Jira       Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
                04/27/2016  Paul Muller      Created this package.
  ******************************************************************************/

  PROCEDURE upcoming_ends_rollup(pi_login_user    IN NUMBER,
                                 pi_login_org     IN NUMBER,
                                 pi_security_type IN VARCHAR,
                                 po_resultset     OUT SYS_REFCURSOR);

  PROCEDURE req_by_status_rollup(pi_login_user    IN NUMBER,
                                 pi_login_org     IN NUMBER,
                                 pi_security_type IN VARCHAR,
                                 po_resultset     OUT SYS_REFCURSOR);

  PROCEDURE monthly_assignment_count(pi_login_user    IN NUMBER,
                                     pi_login_org     IN NUMBER,
                                     pi_security_type IN VARCHAR,
                                     po_resultset     OUT SYS_REFCURSOR);

  PROCEDURE mnthly_assgn_cnt_and_inv_spend(pi_login_user    IN NUMBER,
                                           pi_login_org     IN NUMBER,
                                           pi_security_type IN VARCHAR,
                                           po_resultset     OUT SYS_REFCURSOR);

  PROCEDURE assignments_by_country(pi_login_user    IN NUMBER,
                                   pi_login_org     IN NUMBER,
                                   pi_security_type IN VARCHAR,
                                   pi_region        IN VARCHAR DEFAULT NULL, --currently unused
                                   pi_country       IN VARCHAR,
                                   po_resultset     OUT SYS_REFCURSOR);

  PROCEDURE assignments_by_cmsa(pi_login_user    IN NUMBER,
                                pi_login_org     IN NUMBER,
                                pi_security_type IN VARCHAR,
                                pi_region        IN VARCHAR DEFAULT NULL, --currently unused
                                pi_country       IN VARCHAR,
                                po_resultset     OUT SYS_REFCURSOR);

  FUNCTION get_most_recent_refresh_time(pi_widget_name IN VARCHAR2 DEFAULT 'all') RETURN DATE;

END dashboard_data_api;
/
