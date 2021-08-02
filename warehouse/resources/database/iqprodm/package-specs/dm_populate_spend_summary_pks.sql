CREATE OR REPLACE PACKAGE dm_populate_spend_summary
/********************************************************************
 * Name: dm_populate_spend_summary
 * Desc: This package contains all the procedures required to
 *       populate the spend summary
 *
 *
 * Author  Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   10/13/09    Initial
 ********************************************************************/
AS

 /**************************************************************
  * Name: p_create_summary
  * Desc: This proccedure populates the spend summary table
  *       from invoiced spend table.
  **************************************************************/
  PROCEDURE p_create_summary(in_msg_id   IN  NUMBER,
                             on_err_num  OUT NUMBER,
                             ov_err_msg  OUT VARCHAR2);

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the FO and BO invoiced data
  *       to the data mart temp tables
  ****************************************************************/
  PROCEDURE p_main;

END dm_populate_spend_summary;
/