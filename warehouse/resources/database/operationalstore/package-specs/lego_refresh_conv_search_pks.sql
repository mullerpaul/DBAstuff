CREATE OR REPLACE PACKAGE lego_refresh_conv_search
AUTHID definer IS
/******************************************************************************
   NAME:       lego_refresh_conv_search
   PURPOSE:    Public-facing entrypoint to launch convergence search lego refreshes.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   IQN-40224  09/17/2018  Paul Muller      Created this package using the 
                                           lego_convergence_search package as a template.
   IQN-41594  11/06/2018  Paul Muller      Changes in preparation for refreshes to be 
                                           initiated and managed by mircoservice code.

   ******************************************************************************/
    PROCEDURE start_refresh_run (
        allowable_latency_minutes IN  NUMBER DEFAULT 60,
        refresh_runtime_utc_out   OUT TIMESTAMP
    );

    FUNCTION get_refresh_run_status (
        refresh_runtime_utc IN TIMESTAMP
    ) RETURN VARCHAR2;

END lego_refresh_conv_search;
/
