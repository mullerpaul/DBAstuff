CREATE OR REPLACE PACKAGE dm_invoiced_cac_dim_process
/********************************************************************
 * Name:   dm_invoiced_cac_dim_process
 * Desc:   This package contains all the procedures required to
 *         migrate/process the invoiced CAC dimension
 * Source: Front office and Data mart ( Invoiced Spend table)
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Manoj   06/28/2010    Initial
 ********************************************************************/
AS
 /**************************************************************
  * Name: get_hlvl_desc
  * Desc: Function to get hierachy level description
  *       based on cac segment
  **************************************************************/
  FUNCTION get_hlvl_desc (in_buyer_org_id IN number,
                          iv_cac_value    IN varchar2,
                          in_level        IN number)
  RETURN VARCHAR2;

 /**************************************************************
  * Name: get_hlvl_title
  * Desc: Function to get hierachy level title
  *       based on cac segment
  **************************************************************/
  FUNCTION get_hlvl_title (in_buyer_org_id IN number,
                           iv_cac_value    IN varchar2,
                           in_level        IN number)
  RETURN VARCHAR2;

/*****************************************************************
  * Name: bus_org_lineage_upd
  * Desc: This procedure pulls the data from FO for the current state
  *       of business org lineage and update dm business org_lineage
  *****************************************************************/
PROCEDURE bus_org_lineage_upd(in_msg_id   IN number,
                              on_err_num OUT number,
                              ov_err_msg OUT varchar2);

 /*****************************************************************
  * Name: process_fo_hierarchy
  * Desc: This procedure pulls the data from FO CAC hierarchy MV
  *       and stores the data in Data Mart and also creates history
  *       (by updating the old records to inactive)
  *****************************************************************/
  PROCEDURE process_fo_hierarchy(in_msg_id   IN number,
                                 on_err_num OUT number,
                                 ov_err_msg OUT varchar2);

 /*****************************************************************
  * Name: process_dm_invoiced_cacs
  * Desc: This procedure pulls the distinct invoiced cacs from
  *       invoiced spend (dm_invoiced_spend_all)
  *       It also gets the hierarchy values for the cac info
  *       pulled and stores it in a temp table.
  *****************************************************************/
  PROCEDURE process_dm_invoiced_cacs(in_msg_id            IN number,
                                     id_last_process_date IN DATE,
                                     on_err_num          OUT number,
                                     ov_err_msg          OUT varchar2);

 /*****************************************************************
  * Name: populate_invoiced_cac_dim
  * Desc: This procedure is used to populate the invoice cac dim
  *       table and also invalidate any old records
  *
  *****************************************************************/
  PROCEDURE populate_invoiced_cac_dim(in_msg_id           IN number,
                                      iv_data_source_code IN varchar2,
                                      on_err_num         OUT number,
                                      ov_err_msg         OUT varchar2);

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the CAC information from
  *       data mart as well as Front office
  ****************************************************************/
  PROCEDURE p_main(iv_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                   ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));

END dm_invoiced_cac_dim_process;
/