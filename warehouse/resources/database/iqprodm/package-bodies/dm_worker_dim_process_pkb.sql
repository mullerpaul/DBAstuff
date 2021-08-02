CREATE OR REPLACE PACKAGE BODY dm_worker_dim_process
/******************************************************************************
 * Name:   dm_worker_dim_process
 * Desc:   This package contains all the procedures required to migrate/process the Worker Dimension
 * Source: Front office Tables (Worker Continuity and worker edition)
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------
 * Sajeev  01/31/2011    Initial
 * JoeP    02/01/2016    Hard-coded dblink
 *******************************************************************************/
AS
 /*****************************************************************
  * Name: process_fo_worker_dim
  * Desc: This procedure calls a procedure residing in Front office
  *       to gather the data needed for worker dim into a work table in
  *       FO and later pulls the data into data mart work table
  *****************************************************************/
  PROCEDURE process_fo_worker_dim(in_msg_id        	IN number,
                              	  id_last_processed_id 	IN NUMBER,
                                  in_data_source_code   IN VARCHAR2,
                              	  on_err_num      	OUT number,
                              	  ov_err_msg      	OUT varchar2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_worker_dim_process.process_fo_worker_dim' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER;
  BEGIN
     on_err_num := 0;
     ov_err_msg := NULL;

  dm_cube_utils.make_indexes_visible;

     --
     -- execute the procedure to get FO Worker DIM data (this is a remote procedure that resides in FO reporting)
     -- this procedure gets the data since the last run
     --
     BEGIN
       FO_DM_WORKER_DIM_PROCESS.p_main@FO_R(in_msg_id,id_last_processed_id,in_data_source_code); 
     EXCEPTION
       WHEN OTHERS THEN
            lv_app_err_msg := 'Unable to execute the procedure to get the Worker Dimension data from FO !';
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
             lv_app_err_msg := 'Errors occured in the procedure to get Worker DIM data ! ';
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
      INSERT INTO dm_worker_tmp
              ( worker_id,
  		data_source_code,
  		first_name,
  		middle_name,
  		last_name,
  		title,
		buyer_org_fk,
		buyer_org_name,
		last_worker_edition_id,
  		valid_from_date,
  		valid_to_date,
  		last_modified_date
               )
        SELECT worker_id,
  	      	data_source_code,
  	      	first_name,
  	       	middle_name,
  		last_name,
  		title,
		buyer_org_fk,
		buyer_org_name,
		last_worker_edition_id,
  		valid_from_date,
  		valid_to_date,
  		last_modified_date
      FROM fo_dm_worker_tmp@FO_R;


    EXCEPTION
      WHEN OTHERS THEN
        lv_app_err_msg := 'Unable to insert into temp table dm_worker_tmp the data from FO! ';
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
  END process_fo_worker_dim;

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
                                  ov_err_msg           OUT varchar2)
  IS
    le_exception         EXCEPTION;
    lv_proc_name         VARCHAR2(100)           := 'dm_worker_dim_process.process_dm_worker_dim' ;
    lv_app_err_msg       VARCHAR2(2000)          := NULL;
    lv_db_err_msg        VARCHAR2(2000)          := NULL;
    ln_commit            NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER := 0;
    ln_version_id        NUMBER := 0;
 
  CURSOR worker_cur IS
    SELECT distinct a.worker_id worker_id,
           a.data_source_code data_source_code,
           a.first_name first_name,
           a.middle_name middle_name,
           a.last_name last_name,
           a.title title, 
	   a.buyer_org_fk buyer_org_fk,
           a.buyer_org_name buyer_org_name,
           a.valid_from_date valid_from_date
      FROM dm_worker_dim b,
           dm_worker_tmp a
     WHERE a.worker_id = b.worker_id
       AND a.data_source_code = b.data_source_code
     ORDER BY a.worker_id,a.valid_from_date;


  BEGIN
    on_err_num := 0;
    ov_err_msg := NULL;

    IF iv_first_time_flag = 'N' THEN --Incremental Load Only
     FOR worker_cur_rec IN worker_cur
       LOOP
        SELECT count(1)
          INTO ln_count
          FROM dm_worker_dim
         WHERE worker_id  = worker_cur_rec.worker_id
           AND data_source_code = worker_cur_rec.data_source_code
            AND nvl(first_name,'x') = nvl(worker_cur_rec.first_name,'x')
           AND nvl(middle_name ,'x')= nvl(worker_cur_rec.middle_name,'x')
           AND nvl(last_name,'x') = nvl(worker_cur_rec.last_name,'x')
           AND nvl(title,'x') = nvl(worker_cur_rec.title,'x')
	   AND nvl(buyer_org_fk,-1) = nvl(worker_cur_rec.buyer_org_fk,-1)
	   AND nvl(buyer_org_name,'x') = nvl(worker_cur_rec.buyer_org_name,'x');

        IF ln_count = 0 THEN
           ln_version_id := 0 ;

           BEGIN
             UPDATE dm_worker_dim
                SET is_effective     = 'N',
                    valid_to_date    = (worker_cur_rec.valid_from_date -(1/86400)),
                    last_update_date = sysdate
              WHERE worker_id       = worker_cur_rec.worker_id
                AND is_effective     = 'Y' 
		AND data_source_code = p_data_source_code
                RETURNING version_id INTO ln_version_id;
           EXCEPTION
             WHEN OTHERS THEN
              lv_app_err_msg := 'Unable to update dm_worker_dim ! ';
              lv_db_err_msg := SQLERRM;
              RAISE le_exception;
           END;

           BEGIN
	        INSERT INTO dm_worker_dim
                   		(worker_dim_id,
                    		 worker_id,
  		    		 data_source_code,
  		    		 first_name,
  		    		 middle_name,
  		    		 last_name,
  		    		 title,
				 buyer_org_fk,
			   	 buyer_org_name,
                                 version_id,
  		    		 valid_from_date,
  		    		 valid_to_date,
		    		 is_effective,
		    		 batch_id,
  		    		 last_update_date)
                SELECT dm_worker_dim_seq.NEXTVAL,
                    		worker_cur_rec.worker_id,
  		    		worker_cur_rec.data_source_code,
  		    		worker_cur_rec.first_name,
  		    		worker_cur_rec.middle_name,
  		    		worker_cur_rec.last_name,
  		    		worker_cur_rec.title,
				worker_cur_rec.buyer_org_fk,
			   	worker_cur_rec.buyer_org_name,
				ln_version_id+1,
  		    		worker_cur_rec.valid_from_date,
  		    		NULL,
                    		'Y',
                    		in_msg_id,
                    		sysdate
                FROM DUAL;
 
            EXCEPTION
	      WHEN OTHERS THEN
	        lv_app_err_msg := 'Unable to insert into Worker dim for the latest version of Worker records ! ';
	        lv_db_err_msg := SQLERRM;
                RAISE le_exception;
            END;
        END IF;
       END LOOP;
    END IF; --Incremental Load Only

    --Insert new records for both Incremental and Initial Loading.

    BEGIN
        INSERT INTO dm_worker_dim(worker_dim_id,
                    		 worker_id,
  		    		 data_source_code,
  		    		 first_name,
  		    		 middle_name,
  		    		 last_name,
  		    		 title,
 				 buyer_org_fk,
			   	 buyer_org_name,
				 version_id,
  		    		 valid_from_date,
  		    		 valid_to_date,
		    		 is_effective,
		    		 batch_id,
  		    		 last_update_date)
         SELECT dm_worker_dim_seq.NEXTVAL,
                    		w.worker_id,
  		    		w.data_source_code,
  		    		w.first_name,
  		    		w.middle_name,
  		    		w.last_name,
  		    		w.title,
				w.buyer_org_fk,
			   	w.buyer_org_name,
                                1, 		
  		    		w.valid_from_date,
  		    		NULL,
                    		'Y',
                    		in_msg_id,
                    		sysdate
         FROM dm_worker_tmp w
         WHERE NOT EXISTS --Insert only non-existing records.
             	(SELECT 'X'
                 FROM dm_worker_dim w1
                 WHERE w1.worker_id = w.worker_id
                 AND w1.data_source_code = w.data_source_code);

        EXCEPTION
	   WHEN OTHERS THEN
	        lv_app_err_msg := 'Unable to insert into worker dim for new worker records ! ';
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
  END process_dm_worker_dim;

 /***************************************************************
  * Name: p_main
  * Desc: This procedure contains all the steps involved in gathering and migrating the workers
  *       dimension data from Front office.
  ****************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                   ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
  IS
    ln_msg_id            NUMBER;
    ln_count             NUMBER;
    ln_process_cnt       NUMBER;
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(4000)  := NULL;
    gv_proc_name         VARCHAR2(100)   := 'dm_worker_dim_process.p_main' ;
    gv_app_err_msg       VARCHAR2(2000)  := NULL;
    gv_db_err_msg        VARCHAR2(2000)  := NULL;
    ln_err               NUMBER;
    fo_ln_count          NUMBER;
    bo_ln_count          NUMBER;
    ld_last_processed_id NUMBER;
    ld_last_process_date DATE;
    lv_first_time_flag   VARCHAR2(1);
    ld_last_update_date  DATE;
    ln_last_processed_id NUMBER;
    ln_last_processed_date DATE;

    ge_exception         EXCEPTION;

  BEGIN
     --
     -- Get the sequence reuired for logging messages
     --
     BEGIN
       SELECT DM_MSG_LOG_SEQ.nextval
         INTO ln_msg_id
         FROM dual;
     END;

     BEGIN
     	SELECT last_identifier,last_update_date
       	INTO ld_last_processed_id,ld_last_process_date
       	FROM dm_cube_objects
      	WHERE object_name = 'DM_WORKER_DIM'
      	AND object_source_code =in_data_source_code;

     EXCEPTION
      	WHEN NO_DATA_FOUND THEN
            gv_app_err_msg := 'No Entry for DM_WORKER_DIM in dm_cube_objects';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     -- truncate tables
     --

     BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_worker_tmp';
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to trunacte worker table for Worker dim!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'dm_worker_dim_process',gv_proc_name,'I'); -- log the start of main process

     --
     -- Step 1 : Run the FO process to gather the data related to Worker
     --

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Process the FO to get Worker Data',gv_proc_name,'I');

     BEGIN
       process_fo_worker_dim(ln_msg_id,ld_last_processed_id,in_data_source_code,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to gather the data related to Worker from FO!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --
     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to gather the data related to Worker from FO!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

     --
     -- Step 2 : Process the Worker data in Data mart side and load it into the dimension table
     --
     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Process the Worker in data mart',gv_proc_name,'I');

     IF TRUNC(ld_last_process_date) = '01-JAN-1999' THEN
        lv_first_time_flag := 'Y';
     ELSE
        lv_first_time_flag := 'N';
     END IF;

     BEGIN
       process_dm_worker_dim(ln_msg_id,in_data_source_code,lv_first_time_flag,ln_err_num,lv_err_msg);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to process the Worker in data mart!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     --
     --  check for any errors returned after executing the procedure
     --

     IF ln_err_num > 0 THEN
        gv_app_err_msg := 'Errors occured in the procedure to process the Worker in data mart!';
        gv_db_err_msg := lv_err_msg||' '||SQLERRM;
	RAISE ge_exception;
     END IF;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

     --
     -- Step 3: Update the cube objects for last process id and Date
     --

     SELECT max(last_worker_edition_id)
      INTO ln_last_processed_id
      FROM dm_worker_tmp;

     SELECT max(LAST_MODIFIED_DATE)
      INTO ln_last_processed_date
      FROM dm_worker_tmp;

     IF  ( ln_last_processed_id IS NOT NULL )  THEN
     	UPDATE dm_cube_objects
        SET last_identifier =ln_last_processed_id
      	WHERE object_name = 'DM_WORKER_DIM'
      	AND object_source_code =in_data_source_code;
     END IF;

     IF  ( ln_last_processed_date IS NOT NULL )  THEN
     	UPDATE dm_cube_objects
        SET LAST_UPDATE_DATE = ln_last_processed_date
      	WHERE object_name = 'DM_WORKER_DIM'
      	AND object_source_code =in_data_source_code;
     END IF;

     COMMIT;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');

     DM_UTIL_LOG.p_log_cube_load_status('DM_WORKER_DIM',
                                               in_data_source_code,
                                               'CUBE-DIM',
                                               'COMPLETED',
                                               p_date_id);
  EXCEPTION
      WHEN ge_exception THEN
           --
           -- user defined exception, Log and raise the application error.
           --
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_worker_dim_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
            ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_app_err_msg,
                                               gv_db_err_msg,
                                               gv_proc_name);

          DM_UTIL_LOG.p_log_cube_load_status('DM_WORKER_DIM',
                                               in_data_source_code,
                                               'CUBE-DIM',
                                               'FAILED',
                                               p_date_id);

      WHEN OTHERS THEN
           --
           -- Unknown exception, Log and raise the application error.
           --
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_worker_dim_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
           gv_app_err_msg := 'Unknown Error !';
           gv_db_err_msg  := SQLERRM;
           ln_err            := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                        gv_app_err_msg,
                                                        gv_db_err_msg,
                                                        gv_proc_name);
    	   DM_UTIL_LOG.p_log_cube_load_status('DM_WORKER_DIM',
                                               in_data_source_code,
                                               'CUBE-DIM',
                                               'FAILED',
                                               p_date_id);
  END p_main;
END dm_worker_dim_process;
/