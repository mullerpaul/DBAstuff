CREATE OR REPLACE PACKAGE dm_invoiced_spend
/********************************************************************
 * Name: dm_invoiced_spend
 * Desc: This package contains all the procedures required to
 *       migrate/process FO and BO invoiced data to be used in
 *       Invoiced spend Data mart
 *
 * Author  Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   11/20/08    Initial
 ********************************************************************/
AS

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the FO and BO invoiced data
  *       to the data mart temp tables
  ****************************************************************/
  PROCEDURE p_main(iv_section IN VARCHAR2 DEFAULT 'BOTH');

/**************************************************************
  * Name: p_get_fo_invoiced_data
  * Desc: This proccedure is used to gather all the FO invoiced
  *       information required for the data mart temp tables
  **************************************************************/
  PROCEDURE p_get_fo_invoiced_data(in_msg_id   IN NUMBER,
                                   on_err_num OUT NUMBER,
                                   ov_err_msg OUT VARCHAR2);

/**************************************************************
  * Name: p_get_bo_invoiced_data
  * Desc: This proccedure is used to gather all the BO invoiced
  *       information required for the data mart temp tables
  **************************************************************/
  PROCEDURE p_get_bo_invoiced_data(in_msg_id   IN NUMBER,
                                   on_err_num OUT NUMBER,
                                   ov_err_msg OUT VARCHAR2);
/**************************************************************
  * Name: p_bo_deletes
  * Desc: This proccedure is used to delete the cancelled invoices
  *       in back office from the data mart tables
  **************************************************************/
  PROCEDURE p_bo_deletes(in_msg_id   IN NUMBER,
                                   on_err_num OUT NUMBER,
                                   ov_err_msg OUT VARCHAR2);

END dm_invoiced_spend;
/
