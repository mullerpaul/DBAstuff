CREATE OR REPLACE PACKAGE dm_headcount_fact_process
/******************************************************************************
 * Name:   dm_headcount_fact_process
 * Desc:   This package contains all the procedures required to process the Headcount FACT
 * Source: Front office Tables
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Sajeev  02/11/2011    Initial
 *******************************************************************************/
AS
  PROCEDURE process_fo_headcount_fact(in_msg_id        	IN number,
                              	  id_last_processed_id 	IN number,
                                  in_data_source_code   IN varchar2);

  PROCEDURE populate_headcount_fact(in_msg_id 		IN NUMBER,
				  			in_process_date 	IN DATE, 
                                     in_last_process_date  IN DATE);

  PROCEDURE process_dm_headcount_fact(in_msg_id            IN number,
				  			p_data_source_code  IN VARCHAR2,
                                  	iv_first_time_flag   IN varchar2,
				  			in_process_date  IN DATE);

  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                   ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));

END dm_headcount_fact_process;
/