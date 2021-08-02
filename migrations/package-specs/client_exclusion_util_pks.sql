CREATE OR REPLACE PACKAGE client_exclusion_util
AS
/******************************************************************************
   NAME:       client_exclusion_util
   PURPOSE:    public functions and procedures which maintain client specific
               exclusions to scoring.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   MSVC-608   04/24/2017  Paul Muller      Created this package.
   MSVC-613   05/08/2017  Paul Muller      Added writes to transaction_log table.
                                           Also got rif of the remove_all_exclusions
                                           procedure since logging to TXN_LOG correctly
                                           would be a pain.
   
******************************************************************************/

  PROCEDURE add_exclusion (pi_client_guid    IN RAW,
                           pi_exclusion_type IN VARCHAR2,
                           pi_exclusion_guid IN RAW,
                           pi_txn_guid       IN RAW,
                           pi_session_guid   IN RAW,
                           pi_request_guid   IN RAW);

  PROCEDURE remove_exclusion (pi_client_guid    IN RAW,
                              pi_exclusion_type IN VARCHAR2,
                              pi_exclusion_guid IN RAW,
                              pi_txn_guid       IN RAW,
                              pi_session_guid   IN RAW,
                              pi_request_guid   IN RAW);

END client_exclusion_util;
/
