CREATE OR REPLACE PACKAGE dm_invoice_fact_process
/********************************************************************
 * Name: dm_invoice_fact_process
 * Desc: This package contains all the procedures required to
 *       populate the invoice FACT
 *
 * Author  Date        Version   History
 * -----------------------------------------------------------------
 * Manoj   08/10/10    Initial
 ********************************************************************/
AS
 /**************************************************************
  * Name: get_invoices
  * Desc: This proccedure gets all the invoice numbers to be
  *       processed.
  **************************************************************/
  PROCEDURE get_invoices(in_msg_id              IN  NUMBER,
                         id_last_process_date   IN  DATE,
                         od_cur_process_date    OUT DATE);

 /**************************************************************
  * Name: process_invoice_fact
  * Desc: This proccedure inserts the records into the invoice
  *       FACT after getting data from invoiced spend table
  **************************************************************/
  PROCEDURE process_invoice_fact(in_msg_id   IN NUMBER);

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in creating invoice FACT
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR');
END dm_invoice_fact_process;
/