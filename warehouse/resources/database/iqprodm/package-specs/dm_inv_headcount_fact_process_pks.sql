CREATE OR REPLACE PACKAGE  dm_inv_headcount_fact_process
/********************************************************************
 * Name: dm_inv_headcount_fact_process
 * Desc: This package contains all the procedures required to
 *       populate the invoiced Headcount FACT
 *
 *
 * Author  Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   02/14/11    Initial
 ********************************************************************/
AS
 /**************************************************************************
  * Name: get_invoiced_assignments
  * Desc: This proccedure gets all the invoiced assignments
  *       from dm_invoiced_spend_all ( source of all invoices in data mart)
  **************************************************************************/
  PROCEDURE get_invoiced_assignments(in_msg_id              IN  NUMBER,
                                     id_last_process_date   IN  DATE,
                                     od_cur_process_date   OUT  DATE);
  /*************************************************************************
  * Name: process_fact
  * Desc: This proccedure inserts the records into the invoiced headcount 
  *       FACT after getting data from the invoiced assignments temp table
  *************************************************************************/
  PROCEDURE process_fact(in_msg_id               IN NUMBER);
                        
 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in creating invoiced headcount FACT
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR');
END dm_inv_headcount_fact_process;
/