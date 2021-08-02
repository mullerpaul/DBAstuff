CREATE OR REPLACE PACKAGE operationalstore.lego_refresh_smartview
AUTHID definer IS
/******************************************************************************
   NAME:       lego_refresh_smartview
   PURPOSE:    Public-facing entrypoint to launch smartview lego refreshes.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
  IQN-40224  09/17/2018  Paul Muller      Created this package using the 
                                          lego_convergence_search package as a template.
  IQN-43704  06/24/2018  nconcepcion      Updating the package to refresh WF tables

   ******************************************************************************/
    PROCEDURE start_refresh_run (
        allowable_latency_minutes   IN NUMBER DEFAULT 60
        , p_environment_source_name IN VARCHAR2 DEFAULT NULL
        , p_object_name             IN VARCHAR2 DEFAULT NULL
    );

END lego_refresh_smartview;
/