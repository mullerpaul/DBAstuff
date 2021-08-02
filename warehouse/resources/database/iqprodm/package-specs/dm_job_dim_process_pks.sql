CREATE OR REPLACE PACKAGE dm_job_dim_process
/******************************************************************************
 * Name:   dm_job_dim_process
 * Desc:   This package contains all the procedures required to
 *         migrate/process the Job Dimension
 * Source: Front office Tables (Job and related tables)
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Manoj   07/30/2010    Initial
 *******************************************************************************/
AS

 /*****************************************************************
  * Name: process_fo_job_dim
  * Desc: This procedure calls a procedure residing in Front office
  *       to gather the data needed for Job dim into a work table in
  *       FO and later pulls the data into data mart work table
  *
  *****************************************************************/
  PROCEDURE process_fo_job_dim(in_msg_id              IN  NUMBER,
                               in_last_processed_id   IN  NUMBER,
                               id_last_processed_date IN  DATE,
                               on_err_num             OUT NUMBER,
                               ov_err_msg             OUT VARCHAR2);

 /*****************************************************************
  * Name: process_dm_job_dim
  * Desc: This procedure pulls the data from temp table and
  *       performs the following tasks in data mart
  *       1. First time load all the data from temp table
  *       2. All loads after the initial load needs to check
  *          data existence. if the row exists update the is_effective
  *          to 'N' and make the new row 'Y'
  *****************************************************************/
  PROCEDURE process_dm_job_dim(in_msg_id            IN  NUMBER,
                               iv_first_time_flag   IN  VARCHAR2,
                               on_err_num           OUT NUMBER,
                               ov_err_msg           OUT VARCHAR2);

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the job
  *       dimension data from Front office.
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                  ,p_date_id           IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));

END dm_job_dim_process;
/