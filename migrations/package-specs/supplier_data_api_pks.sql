CREATE OR REPLACE PACKAGE supplier_data_api
AS
/******************************************************************************
   NAME:       supplier_data_api
   PURPOSE:    public functions and procedures which read the detailed data 
               used for grading and ranking suppliers.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   MSCV-707   05/12/2017  Paul Muller      Created package
******************************************************************************/

  PROCEDURE get_supplier_metric_scores (pi_client_guid         IN  RAW,
                                        pi_interval_start_date IN  DATE,
                                        pi_interval_end_date   IN  DATE,
                                        po_metric_scores       OUT SYS_REFCURSOR);

END supplier_data_api;
/
