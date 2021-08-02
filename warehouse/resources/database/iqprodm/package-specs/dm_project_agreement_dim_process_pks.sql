CREATE OR REPLACE PACKAGE dm_project_agreement_dim_prcs
/******************************************************************************
 * Name:   dm_project_agreement_dim_prcs
 * Desc:   This package contains all the procedures required to
 *         migrate/process the Project agreement Dimension
 * Source: Front office Tables (Project Agreement and Project Agreement Version)
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Manoj   07/12/2010    Initial
 *******************************************************************************/
AS

 /*****************************************************************
  * Name: process_fo_pa_dim
  * Desc: This procedure calls a procedure residing in Front office
  *       to gather the data needed for PA dim into a work table in
  *       FO and later pulls the data into data mart work table
  *
  *****************************************************************/
  PROCEDURE process_fo_pa_dim(in_msg_id        IN number,
                              id_last_run_date IN DATE,
                              on_err_num      OUT number,
                              ov_err_msg      OUT varchar2);

 /*****************************************************************
  * Name: process_dm_pa_dim
  * Desc: This procedure pulls the data from temp table and
  *       performs the following tasks in data mart
  *       1. First time load all the data from temp table
  *       2. All loads after the initial load needs to check
  *          data existence. if the row exists update the is_effective
  *          to 'N' and make the new row 'Y'
  * Notes: Since we are taking only the effective PAs any change to the
  *        values will create a new version in FO. so no need to compare
  *        every column to see anything has changed.
  *****************************************************************/
  PROCEDURE process_dm_pa_dim(in_msg_id            IN number,
                              iv_first_time_flag   IN varchar2,
                              on_err_num          OUT number,
                              ov_err_msg          OUT varchar2);

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the project agreement
  *       dimension data from Front office.
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                   ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));

END dm_project_agreement_dim_prcs;
/