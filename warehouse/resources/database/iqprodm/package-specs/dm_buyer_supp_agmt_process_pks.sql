CREATE OR REPLACE PACKAGE dm_buyer_supp_agmt_process
/******************************************************************************
 * Name:   dm_buyer_supp_agmt_process
 * Desc:   This package contains all the procedures required for Buyer Supplier Agreement
 * Source: Front office Tables  
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Sajeev  04/14/2011    Initial
 *******************************************************************************/
AS
  PROCEDURE process_buyer_supp_agmt(in_msg_id        		IN number,
                              	  id_last_processed_date 	IN DATE,
                              	  on_err_num      		OUT number,
                              	  ov_err_msg      		OUT varchar2);
  
  PROCEDURE p_main(p_date_id IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));
END dm_buyer_supp_agmt_process;
/
