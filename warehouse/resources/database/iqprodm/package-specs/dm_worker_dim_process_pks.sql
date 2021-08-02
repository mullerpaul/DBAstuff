CREATE OR REPLACE PACKAGE dm_worker_dim_process
/******************************************************************************
 * Name:   dm_worker_dim_process
 * Desc:   This package contains all the procedures required to migrate/process the Worker Dimension
 * Source: Front office Tables (worker continuity and worker edition)
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Sajeev  01/31/2011    Initial
 * removed unwanted function specs
 *******************************************************************************/
AS
 /*****************************************************************
  * Name: process_fo_worker_dim
  * Desc: This procedure calls a procedure residing in Front office
  *       to gather the data needed for worker dim into a work table in
  *       FO and later pulls the data into data mart work table
  *
  *****************************************************************/
  PROCEDURE process_fo_worker_dim(in_msg_id        	IN number,
                              	  id_last_processed_id 	IN NUMBER,
                                  in_data_source_code   IN VARCHAR2,
                              	  on_err_num      	OUT number,
                              	  ov_err_msg      	OUT varchar2);

 /*****************************************************************
  * Name: process_dm_worker_dim
  * Desc: This procedure pulls the data from temp table and
  *       performs the following tasks in data mart
  *       1. First time load all the data from temp table
  *       2. All loads after the initial load needs to check
  *          data existence. if the row exists update the is_effective
  *          to 'N' and make the new row 'Y'
  *****************************************************************/
  PROCEDURE process_dm_worker_dim(in_msg_id            IN number,
				  p_data_source_code  IN VARCHAR2,
                                  iv_first_time_flag   IN varchar2,
                                  on_err_num           OUT number,
                                  ov_err_msg           OUT varchar2);

 /***************************************************************
  * Name: p_main
  * Desc: This proccedure contains all the steps involved
  *       in gathering and migrating the project agreement
  *       dimension data from Front office.
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                   ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));

END dm_worker_dim_process;
/
