CREATE OR REPLACE PACKAGE lego_refresh_invoice_data
AUTHID definer IS
/******************************************************************************
   NAME:       lego_refresh_invoice_data
   PURPOSE:    Public-facing entrypoint to launch convergence search lego refreshes.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   IQN-41371  09/26/2018  Paul Muller      Created this package using the 
                                           lego_refresh_conv_search package as a template.
   IQN-41371  09/26/2018  McKay Dunlap		Added Back WFPROD to invoicing data was erroneously removed. 
   ******************************************************************************/
    PROCEDURE start_refresh_run (
        allowable_latency_minutes IN NUMBER DEFAULT 60
    );

END lego_refresh_invoice_data;
/