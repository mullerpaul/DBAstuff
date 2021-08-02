CREATE OR REPLACE PACKAGE lego_refresh_dashboards
AUTHID definer IS
/******************************************************************************
   NAME:       lego_refresh_dashboards
   PURPOSE:    Public-facing entrypoint to launch Horizon dashboard lego refreshes.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   IQN-40224  09/17/2018  Paul Muller      Created this package using the 
                                           lego_convergence_search package as a template.

   ******************************************************************************/
    PROCEDURE start_refresh_run (
        allowable_latency_minutes IN NUMBER DEFAULT 60
    );

END lego_refresh_dashboards;
/