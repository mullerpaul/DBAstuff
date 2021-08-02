CREATE OR REPLACE PACKAGE BODY dm_buyer_supp_agmt_process
/******************************************************************************
 * Name:   dm_buyer_supp_agmt_process
 * Desc:   This package contains all the procedures required for buyer supplier agreement
 * Source: Front office Tables 
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Sajeev  04/14/2011    Initial
 * Sajeev  12/19/2011    Commented out update dm_cube_objects
 * Sajeev  03/09/2012    Added make_indexes_visible
 * JoeP    02/01/2016    Hard-code dblink
 *******************************************************************************/
AS
 PROCEDURE process_buyer_supp_agmt(in_msg_id        		IN number,
                              	  id_last_processed_date 	IN DATE,
                              	  on_err_num      		OUT number,
                              	  ov_err_msg      		OUT varchar2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_buyer_supp_agmt_process.process_buyer_supp_agmt' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
 BEGIN
     on_err_num := 0;
     ov_err_msg := NULL;

dm_cube_utils.make_indexes_visible;

     --
     -- execute the procedure to get FO Buyer Supplier agmt data (this is a remote procedure that resides in FO reporting)
     -- this procedure gets the data since the last run

     EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_buyer_supplier_agmt_tmp';

     BEGIN
       FO_dm_buyer_supp_agmt_process.p_main@FO_R(in_msg_id,id_last_processed_date); 
     EXCEPTION
       WHEN OTHERS THEN
            lv_app_err_msg := 'Unable to execute the procedure to get the Buyer Supplier agmt data from FO !';
            lv_db_err_msg := SQLERRM;
	    RAISE le_exception;
     END;

     --
     -- check for any errors in remote procedure
     --
     BEGIN
       SELECT err_msg
         INTO lv_err_msg
         FROM fo_dm_err_msg_tmp@FO_R;

          IF lv_err_msg IS NOT NULL THEN
             lv_app_err_msg := 'Errors occured in the procedure to get Buyer Supplier data ! ';
             lv_db_err_msg := lv_err_msg||' '||SQLERRM;
             RAISE le_exception;
          END IF;

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
             lv_err_msg := NULL;
     END;

    --
    -- Pull the data from Front office to a temp table
    --

    BEGIN
      INSERT INTO dm_buyer_supplier_agmt_tmp( buyer_org_id,supplier_org_id )
        SELECT DISTINCT buyer_org_id,supplier_org_id
      FROM fo_dm_buyer_supplier_agmt_tmp@FO_R;

    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into temp table dm_buyer_supplier_agmt_tmp the data from FO! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
    END;

    BEGIN
    	INSERT INTO dm_buyer_supplier_agmt( buyer_org_id,supplier_org_id)
    	SELECT  DISTINCT buyer_org_id,supplier_org_id
 	FROM dm_buyer_supplier_agmt_tmp d
         WHERE NOT EXISTS --Insert only non-existing records.
             	(SELECT 'X'
                 FROM dm_buyer_supplier_agmt d1
                 WHERE d1.buyer_org_id = d.buyer_org_id
                 AND d1.supplier_org_id = d.supplier_org_id);
     EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into dm_buyer_supplier_agmt! ';
        lv_db_err_msg := SQLERRM;
        RAISE le_exception;
    END;
    

  EXCEPTION
    WHEN le_exception THEN
      --
      -- user defined exception, Log and raise the application error.
      --
      on_err_num := DM_UTIL_LOG.f_log_error(in_msg_id,
                                             lv_app_err_msg,
                                             lv_db_err_msg,
                                             lv_proc_name);

      ov_err_msg := lv_app_err_msg;
    WHEN OTHERS THEN
      --
      -- Unknown exception, Log and raise the application error.
      --
      Rollback;
      lv_app_err_msg := 'Unknown Error !';
      lv_db_err_msg  := SQLERRM;
      on_err_num     := DM_UTIL_LOG.f_log_error(in_msg_id,
                                                 lv_app_err_msg,
                                                 lv_db_err_msg,
                                                 lv_proc_name);
      ov_err_msg     := lv_app_err_msg;
  END process_buyer_supp_agmt;

 /******************************************************************************************
  * Name: p_main
  * Desc: This procedure contains all the steps involved in loading buyer supplier agmt
  ******************************************************************************************/
  PROCEDURE p_main(p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
  IS
    ln_msg_id            	NUMBER;
    ln_err_num           	NUMBER;
    lv_err_msg           	VARCHAR2(4000)  := NULL;
    gv_proc_name         	VARCHAR2(100)   := 'dm_buyer_supp_agmt_process.p_main' ;
    gv_app_err_msg       	VARCHAR2(2000)  := NULL;
    gv_db_err_msg        	VARCHAR2(2000)  := NULL;
    ln_err               	NUMBER; 
    ld_last_process_date 	DATE;
    ln_last_processed_date 	DATE;
    ge_exception         	EXCEPTION;

  BEGIN
     --
     -- Get the sequence reuired for logging messages
     --

     ln_last_processed_date := sysdate;

     BEGIN
       SELECT DM_MSG_LOG_SEQ.nextval
         INTO ln_msg_id
         FROM dual;
     END;

     BEGIN
     	SELECT  last_update_date
       	INTO  ld_last_process_date
       	FROM dm_cube_objects
      	WHERE object_name = 'DM_BUYER_SUPPLIER_AGMT';

     EXCEPTION
      	WHEN NO_DATA_FOUND THEN
            gv_app_err_msg := 'No Entry for DM_BUYER_SUPPLIER_AGMT in dm_cube_objects';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'dm_buyer_supp_agmt_process',gv_proc_name,'I'); -- log the start of main process

     --
     -- Step 1 : Run the FO process to gather the data related to Buyer Supplier Agmt
     --

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Process the FO to get Buyer Supplier Data',gv_proc_name,'I');

     BEGIN
       process_buyer_supp_agmt(ln_msg_id,ld_last_process_date,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure process_buyer_supp_agmt!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --

     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to gather the data related to Buyer Supplier from FO!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

  /*  Commented out the following UPDATE to pull all the data from FO  
     UPDATE dm_cube_objects
     SET LAST_UPDATE_DATE = ln_last_processed_date
     WHERE object_name = 'DM_BUYER_SUPPLIER_AGMT'
     AND object_source_code ='REGULAR'; 
   */
   
     COMMIT;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');

     DM_UTIL_LOG.p_log_cube_load_status('DM_BUYER_SUPPLIER_AGMT',
                                               'REGULAR',
                                               'CUBE-DIM',
                                               'COMPLETED',
                                               p_date_id);
  EXCEPTION
      WHEN ge_exception THEN
           --
           -- user defined exception, Log and raise the application error.
           --
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_buyer_supp_agmt_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
            ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_app_err_msg,
                                               gv_db_err_msg,
                                               gv_proc_name);

          DM_UTIL_LOG.p_log_cube_load_status('DM_BUYER_SUPPLIER_AGMT',
                                               'REGULAR',
                                               'CUBE-DIM',
                                               'FAILED',
                                               p_date_id);

      WHEN OTHERS THEN
           --
           -- Unknown exception, Log and raise the application error.
           --
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_buyer_supp_agmt_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
           gv_app_err_msg := 'Unknown Error !';
           gv_db_err_msg  := SQLERRM;
           ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                        gv_app_err_msg,
                                                        gv_db_err_msg,
                                                        gv_proc_name);
    	   DM_UTIL_LOG.p_log_cube_load_status('DM_BUYER_SUPPLIER_AGMT',
                                               'REGULAR',
                                               'CUBE-DIM',
                                               'FAILED',
                                               p_date_id);
  END p_main;
END dm_buyer_supp_agmt_process;
/