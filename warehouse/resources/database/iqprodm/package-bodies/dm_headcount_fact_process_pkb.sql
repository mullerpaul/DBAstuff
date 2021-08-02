CREATE OR REPLACE PACKAGE BODY dm_headcount_fact_process
/*******************************************************************************************************************
 * Name:   dm_headcount_fact_process
 * Desc:   This package contains all the procedures required to migrate/process the Headcount FACT
 * Source: Front office Tables 
 *
 * Author  Date          Version   History
 * -----------------------------------------------------------------------------------------------------------------
 * Sajeev  02/11/2011    Initial
 * Sajeev  03/28/2012    Removed the create/drop index/mv procedures
 * Sajeev  04/05/2012    commented out TRUNC(f.process_date) = TRUNC(in_process_date),added delta table,added worker_id in the check
 * Sajeev  04/04/2012    commented out TRUNC(f.process_date) = TRUNC(in_process_date)
 * Sajeev  08/08/2012    Added sqlerrm before rollback
 * JoeP    02/01/2016    Hard-code dblink
 ***********************************************************************************************************************/
AS
  gv_app_err_msg       	VARCHAR2(2000)  := NULL;
  gv_db_err_msg        	VARCHAR2(2000)  := NULL;
  ge_exception         	EXCEPTION;

 /*****************************************************************
  * Name: process_fo_headcount_fact
  * Desc: This procedure calls a procedure residing in Front office
  *       to gather the data needed for Assignments ( WO and EA) in
  *       FO and later pulls the data into data mart Assignment table
  *****************************************************************/
  PROCEDURE process_fo_headcount_fact(in_msg_id        	IN number,
                              	  	id_last_processed_id 	IN number,
                                  	in_data_source_code   IN varchar2)
  IS
    ln_count             NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
  BEGIN
     --
     -- execute the procedure to get FO Assignment data (WO and EA) (this is a remote procedure that resides in FO reporting)
     -- this procedure gets the data since the last run
     --

     BEGIN
       FO_dm_headcount_fact_process.p_main@FO_R(in_msg_id,id_last_processed_id,in_data_source_code);  
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'process_fo_headcount_fact: Unable to execute the procedure to get the HeadCount Assignment data from FO !';
            gv_db_err_msg := SQLERRM;
	       RAISE ge_exception;
     END;

     BEGIN
       SELECT err_msg
         INTO lv_err_msg
         FROM fo_dm_err_msg_tmp@FO_R;

          IF lv_err_msg IS NOT NULL THEN
             gv_app_err_msg := 'process_fo_headcount_fact: Errors occured in the procedure to get the HeadCount Assignment data from FO';
             gv_db_err_msg := lv_err_msg||' '||SQLERRM;
             RAISE ge_exception;
          END IF;

       EXCEPTION
        WHEN NO_DATA_FOUND THEN
             lv_err_msg := NULL;
     END;

     BEGIN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_headcount_tmp'; 
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'process_fo_headcount_fact: Unable to truncate dm_headcount_tmp!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

    --
    -- Pull the data from Front office to a temp table
    --

    BEGIN
      INSERT INTO dm_headcount_tmp t
              ( assignment_id,
  		  	assignment_type,
  		  	assignment_start_date,
  		  	assignment_end_date,
		  	worker_id,
  		  	job_id,
  		  	buyer_org_id,
  		  	buyer_org_name,
  		  	supplier_org_id,
  		  	supplier_org_name,
  		  	location_city,
  		  	location_state,
  		  	location_postal_code,
  		  	location_country,
  		  	last_assignment_edition_id,
  		  	data_source_code,
  		  	last_update_date
               )
        SELECT  assignment_id,
  		  	assignment_type,
  		  	assignment_start_date,
  		  	assignment_end_date,
		  	worker_id,
  		  	job_id,
  		  	buyer_org_id,
  		  	buyer_org_name,
  		  	supplier_org_id,
  		  	supplier_org_name, 		 
  		  	location_city,
  		  	location_state,
  		  	location_postal_code,
  		  	location_country,
  		  	last_assignment_edition_id,
  		  	data_source_code,
  		  	last_update_date
        FROM fo_dm_headcount_tmp@FO_R;

    EXCEPTION
      WHEN OTHERS THEN
        gv_app_err_msg := 'process_fo_headcount_fact: Unable to insert into temp table dm_headcount_tmp the data from FO';
        gv_db_err_msg := SQLERRM;
        RAISE ge_exception;
    END;

  EXCEPTION
     WHEN OTHERS THEN
      gv_app_err_msg := 'process_fo_headcount_fact: Unknown Error';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;
  END process_fo_headcount_fact;

 /*****************************************************************
  * Name: process_dm_headcount_fact
  * Desc: This procedure pulls the data from temp table and
  *       performs the following tasks in data mart
  *****************************************************************/
  PROCEDURE process_dm_headcount_fact(in_msg_id            	IN number,
				  			 p_data_source_code  		IN VARCHAR2,
                                  	 iv_first_time_flag   	IN varchar2,
				  			 in_process_date  		IN DATE)
  IS
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER := 0;
    ln_version_id        NUMBER := 0;
    ln_fact_version_id   NUMBER := 0;

 TYPE hc_assign_tab_type IS TABLE OF dm_headcount_fact_staging%ROWTYPE;
 hc_assign_tab  hc_assign_tab_type;

  CURSOR assignment_cur IS
    SELECT distinct   a.assignment_id assignment_id,
  		  a.assignment_type assignment_type,
  		  a.assignment_start_date assignment_start_date,
  		  a.assignment_end_date assignment_end_date,
		  a.worker_id worker_id,
  		  a.job_id job_id,
  		  a.buyer_org_id buyer_org_id,
  		  a.buyer_org_name buyer_org_name,
  		  a.supplier_org_id supplier_org_id,
  		  a.supplier_org_name supplier_org_name,  		
  		  a.location_city location_city,
  		  a.location_state location_state,
  		  a.location_postal_code location_postal_code,
  		  a.location_country location_country,
  		  a.data_source_code data_source_code
      FROM dm_headcount_fact_staging b,
           dm_headcount_tmp a
     WHERE a.assignment_id = b.assignment_id
       AND a.data_source_code = b.data_source_code
     ORDER BY a.assignment_id,a.assignment_start_date;

  BEGIN
    IF iv_first_time_flag = 'N' THEN --Incremental Load Only
     FOR assignment_cur_rec IN assignment_cur
       LOOP
        SELECT count(1)
          INTO ln_count
          FROM dm_headcount_fact_staging
         WHERE assignment_id  = assignment_cur_rec.assignment_id
           AND data_source_code = assignment_cur_rec.data_source_code
           AND assignment_start_date = assignment_cur_rec.assignment_start_date 
           AND assignment_end_date = assignment_cur_rec.assignment_end_date
           AND worker_id = assignment_cur_rec.worker_id;

        IF ln_count = 0 THEN
           ln_version_id := 0 ;

           --Invalidate Persisted Assignment Table

           BEGIN
            --Assumption: All the records for an assignment_id should be invalidated only for WO. If it is an EA there can be some edition ids with multiple positions.
            --In that case we should not invalidate previous positions. Here I assume that the daily positions have same start date and end dates and all others are long term EA.

            IF ( assignment_cur_rec.assignment_type = 'WO' OR (assignment_cur_rec.assignment_type = 'EA' AND assignment_cur_rec.assignment_start_date <> assignment_cur_rec.assignment_end_date)) THEN  
             	UPDATE dm_headcount_fact_staging
                SET delete_flag     = 'Y',
                    valid_to_date    = sysdate, --(assignment_cur_rec.valid_from_date -(1/86400)),
                    process_date = in_process_date,
                    last_update_date = sysdate
              	WHERE assignment_id  = assignment_cur_rec.assignment_id
                AND delete_flag     = 'N'
			AND data_source_code = p_data_source_code
                RETURN MAX(version_id) INTO ln_version_id ;

             END IF;
           EXCEPTION
             WHEN OTHERS THEN
              gv_app_err_msg := 'process_dm_headcount_fact: Unable to update dm_headcount_fact_staging for '|| to_char(assignment_cur_rec.assignment_id);
              gv_db_err_msg := SQLERRM;
              RAISE ge_exception;
           END;

         --Invalidate FACT Records.

 	  	BEGIN
          	   IF ( assignment_cur_rec.assignment_type = 'WO' OR (assignment_cur_rec.assignment_type = 'EA' AND assignment_cur_rec.assignment_start_date <> assignment_cur_rec.assignment_end_date)) THEN 
       		insert into dm_hc_change_assignment values(assignment_cur_rec.assignment_id);
              END IF;
           EXCEPTION
             WHEN OTHERS THEN
              gv_app_err_msg := 'process_dm_headcount_fact: Unable to insert into dm_hc_change_assignment';
              gv_db_err_msg := SQLERRM;
              RAISE ge_exception;
           END;

           --Insert into Persisted Assignment Table dm_headcount_fact_staging

           BEGIN
	         SELECT assignment_cur_rec.assignment_id,
  		  		assignment_cur_rec.assignment_type,
  		  		assignment_cur_rec.assignment_start_date,
  		  		assignment_cur_rec.assignment_end_date,
				assignment_cur_rec.worker_id,
  		  		assignment_cur_rec.job_id,
  		  		assignment_cur_rec.buyer_org_id,
  		  		assignment_cur_rec.buyer_org_name,
  		  		assignment_cur_rec.supplier_org_id,
  		  		assignment_cur_rec.supplier_org_name,  		  		
  		  		assignment_cur_rec.location_city,
  		  		assignment_cur_rec.location_state,
  		  		assignment_cur_rec.location_postal_code,
  		  		assignment_cur_rec.location_country,
				sysdate, --valid from date
                     NULL,
                     'N',
                     in_process_date,
				ln_version_id+1,
				in_msg_id,
  		  		assignment_cur_rec.data_source_code,
                                sysdate
	         BULK COLLECT INTO hc_assign_tab
              FROM DUAL;

			   FORALL i in hc_assign_tab.first .. hc_assign_tab.last
          		   INSERT INTO dm_headcount_fact_staging VALUES hc_assign_tab(i);

              EXCEPTION
	           WHEN OTHERS THEN
	        		gv_app_err_msg := 'process_dm_headcount_fact: Unable to insert into dm_headcount_fact_staging for the latest version of Assignment records';
	        		gv_db_err_msg := SQLERRM;
                	RAISE ge_exception;
            END;
        END IF;
       END LOOP;

       --Invalidate Fact for all changed assignments.

        BEGIN
		UPDATE DM_HC_FACT
           SET delete_flag     = 'Y',last_update_date = sysdate
           WHERE assignment_id  in ( select assignment_id from dm_hc_change_assignment)
           AND delete_flag     = 'N'
		AND data_source_code = p_data_source_code;

        EXCEPTION
             WHEN OTHERS THEN
              gv_app_err_msg := 'Unable to update dm_hc_fact! ';
              gv_db_err_msg := SQLERRM;
              RAISE ge_exception;
        END;     
    END IF; --Incremental Load Only

    	--Insert new records for both Incremental and Initial Loading.
     --Assumption: The fact table is populated everyday and the entry is made only for sysdate. If due to some reason the fact is not populated yesterday,
     -- there will not be any entry in the fact table for existing assignments for yesterday.

         BEGIN
		   SELECT 	w.assignment_id,
  		  		w.assignment_type,
  		  		w.assignment_start_date,
  		  		w.assignment_end_date,
				w.worker_id,
  		  		w.job_id,
  		  		w.buyer_org_id,
  		  		w.buyer_org_name,
  		  		w.supplier_org_id,
  		  		w.supplier_org_name,  		  		
  		  		w.location_city,
  		  		w.location_state,
  		  		w.location_postal_code,
  		  		w.location_country,
				sysdate, --Valid from date
				NULL,
				'N',
				in_process_date,
				1,
                      in_msg_id,
                      w.data_source_code,
                      sysdate
			BULK COLLECT INTO hc_assign_tab
         		FROM dm_headcount_tmp w
         		WHERE NOT EXISTS --Insert only non-existing records.
             			(SELECT 'X'
                 		 FROM dm_headcount_fact_staging w1
                 		 WHERE w1.assignment_id = w.assignment_id
                 		 AND w1.data_source_code = w.data_source_code
                            AND w1.worker_id = w.worker_id );

  			FORALL i in hc_assign_tab.first .. hc_assign_tab.last
          		INSERT INTO dm_headcount_fact_staging VALUES hc_assign_tab(i);


          EXCEPTION
	       WHEN OTHERS THEN
	        gv_app_err_msg := 'process_dm_headcount_fact: Unable to insert into dm_headcount_fact_staging for new records ! ';
	        gv_db_err_msg := SQLERRM;
              RAISE ge_exception;
         END;

  EXCEPTION
     WHEN OTHERS THEN
      gv_app_err_msg := 'Unknown Error !';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;
  END process_dm_headcount_fact;

 /*****************************************************************
  * Name: populate_headcount_fact
  * Desc: Populate the FACT table for new and existing Assignments
  *****************************************************************/

 PROCEDURE populate_headcount_fact(in_msg_id 			IN NUMBER,
				  		   in_process_date 		IN DATE, 
                                   in_last_process_date  	IN DATE)
  IS
    l_count              NUMBER := 0;          

 BEGIN
	INSERT /*+ PARALLEL(b,8) */  INTO DM_HC_FACT_DELTA b
  	(
   		ASSIGNMENT_ID ,
   		ASSIGNMENT_DIM_ID,
   		ASSIGNMENT_TYPE ,
   		ASSIGNMENT_START_DATE ,
   		ASSIGNMENT_END_DATE,
   		ASSIGNMENT_START_DATE_DIM_ID ,
   		ASSIGNMENT_END_DATE_DIM_ID ,
   		WORKER_ID  ,
   		WORKER_DIM_ID  ,
   		JOB_DIM_ID  ,
   		WORK_LOC_GEO_DIM_ID  ,
   		BUYER_GEO_DIM_ID   ,
   		SUPPLIER_ORG_DIM_ID  ,
   		BUYER_ORG_DIM_ID    ,
   		BUYER_ORG_ID  ,
   		DATA_SOURCE_ID ,
   		WORKER_COUNT  ,
   		DELETE_FLAG   ,
   		VERSION_ID  ,
   		BATCH_ID  ,
   		DATA_SOURCE_CODE   ,
   		LAST_UPDATE_DATE  ,
   		FACT_SEQUENCE ,
           TOP_PARENT_BUYER_ORG_ID
  	)
    SELECT ASSIGNMENT_ID ,
           ASSIGNMENT_DIM_ID,
           ASSIGNMENT_TYPE ,
           ASSIGNMENT_START_DATE ,
           ASSIGNMENT_END_DATE,
           ASSIGNMENT_START_DATE_DIM_ID ,
           ASSIGNMENT_END_DATE_DIM_ID ,
           WORKER_ID  ,
           WORKER_DIM_ID  ,
           JOB_DIM_ID  ,
           WORK_LOC_GEO_DIM_ID  ,
           BUYER_GEO_DIM_ID   ,
           SUPPLIER_ORG_DIM_ID  ,
           BUYER_ORG_DIM_ID    ,
           BUYER_ORG_ID  ,
           DATA_SOURCE_ID ,
           WORKER_COUNT  ,
           DELETE_FLAG   ,
           VERSION_ID  ,
           BATCH_ID  ,
           DATA_SOURCE_CODE   ,
                 sysdate LAST_UPDATE_DATE ,
                headcount_fact_SEQ.NEXTVAL FACT_SEQUENCE,TOP_PARENT_BUYER_ORG_ID
    FROM (
     SELECT  /*+  FULL(f) FULL(a) PARALLEL(f,8) */  DISTINCT  f.assignment_id,
          		NVL(a.assignment_dim_id,0) assignment_dim_id,
          		f.assignment_type,
          		f.ASSIGNMENT_START_DATE,
          		f.ASSIGNMENT_END_DATE,
          		to_number(to_char(TRUNC(f.ASSIGNMENT_START_DATE),'YYYYMMDD')||to_char(ds.data_source_id)||to_char(NVL(DM_CUBE_UTILS.get_top_parent_org_id(BUYER_ORG_ID),0)))  AS ASSIGNMENT_START_DATE_DIM_ID,
          		to_number(to_char(TRUNC(f.ASSIGNMENT_END_DATE),'YYYYMMDD')||to_char(ds.data_source_id)||to_char(NVL(DM_CUBE_UTILS.get_top_parent_org_id(BUYER_ORG_ID),0)))  AS ASSIGNMENT_END_DATE_DIM_ID,
          		f.worker_id,
         		DM_CUBE_UTILS.get_worker_dim_id(WORKER_ID,assignment_start_date,f.data_source_code) worker_dim_id,
         		DM_CUBE_UTILS.get_job_dim_id(job_id,assignment_start_date,f.data_source_code,buyer_org_id) job_dim_id,
         		DM_CUBE_UTILS.get_geo_dim_id(location_country,location_state,location_city,location_postal_code) work_loc_geo_dim_id,
         		DM_CUBE_UTILS.get_org_geo_dim_id(buyer_org_id,assignment_start_date,f.data_source_code)   buyer_geo_dim_id,
         		DM_CUBE_UTILS.get_organization_dim_id(supplier_org_id,assignment_start_date,f.data_source_code) supplier_org_dim_id,
         		DM_CUBE_UTILS.get_organization_dim_id(buyer_org_id,assignment_start_date,f.data_source_code)    buyer_org_dim_id,
         		f.buyer_org_id,
        		to_char(ds.data_source_id) DATA_SOURCE_ID,
        		1 WORKER_COUNT,
        		'N' DELETE_FLAG,
        		f.version_id,
        		in_msg_id BATCH_ID,
        		f.data_source_code,
                 to_number(to_char(NVL(DM_CUBE_UTILS.get_top_parent_org_id(BUYER_ORG_ID),0)))  TOP_PARENT_BUYER_ORG_ID
	FROM DM_HEADCOUNT_FACT_STAGING f, dm_assignment_dim a,DM_DATA_SOURCE ds
  	WHERE f.assignment_start_date < (TRUNC(in_process_date)+1)
 	-- AND  TRUNC(f.process_date) = TRUNC(in_process_date)
  	AND  f.delete_flag = 'N'
 	AND f.data_source_code = ds.data_source_code(+)
  	AND not exists ( select a.assignment_id
	 		  	 from  DM_HC_FACT a
	 		  	 where a.delete_flag = 'N'
	 		  	 and a.assignment_id = f.assignment_id
         		     	 and a.data_source_code = f.data_source_code
     	 		 	 and TRUNC(a.assignment_start_date) =  TRUNC(f.ASSIGNMENT_START_DATE)
                      and TRUNC(a.assignment_end_date) =  TRUNC(f.assignment_end_date )
                      and a.worker_id = f.worker_id)
	AND f.assignment_id = a.assignment_id(+)) ;


     --This below delete is to get rid of the duplicates which might not have handled in the above distinct.

 	DELETE dm_hc_fact_delta
 	WHERE ROWID IN  (  SELECT ROWID
                                FROM (SELECT a.rowid, ROW_NUMBER() OVER ( PARTITION BY ASSIGNMENT_START_DATE_DIM_ID,ASSIGNMENT_END_DATE_DIM_ID ,JOB_DIM_ID,WORK_LOC_GEO_DIM_ID,BUYER_GEO_DIM_ID,SUPPLIER_ORG_DIM_ID ,BUYER_ORG_DIM_ID ,DELETE_FLAG,VERSION_ID,DATA_SOURCE_CODE,WORKER_ID,ASSIGNMENT_ID
                                            ORDER BY  ASSIGNMENT_START_DATE_DIM_ID,ASSIGNMENT_END_DATE_DIM_ID ,JOB_DIM_ID,WORK_LOC_GEO_DIM_ID,BUYER_GEO_DIM_ID,SUPPLIER_ORG_DIM_ID ,BUYER_ORG_DIM_ID ,DELETE_FLAG,VERSION_ID,DATA_SOURCE_CODE,WORKER_ID,ASSIGNMENT_ID) AS rnk
                                        FROM dm_hc_fact_delta a  
                                 ) WHERE rnk > 1 );

     INSERT /*+ PARALLEL(a,8) */   INTO dm_hc_fact a select * from dm_hc_fact_delta;

 EXCEPTION
    WHEN OTHERS THEN
      gv_app_err_msg := 'Unknown Error !';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;
 END populate_headcount_fact;



 /***********************************************************************************************
  * Name: p_main
  * Desc: This procedure contains all the steps involved in gathering and migrating the headcount
  *       fact data from Front office.
  ***********************************************************************************************/
 PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR',p_date_id IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
  IS
    ln_msg_id            		NUMBER;
    gv_proc_name         		VARCHAR2(100) := 'dm_headcount_fact_process.p_main' ;
    ln_err               		NUMBER;
    ld_last_processed_id 		NUMBER;
    ld_last_process_date 		DATE;
    lv_first_time_flag   		VARCHAR2(1);
    ld_last_update_date  		DATE;
    ln_last_processed_id 		NUMBER;
    ln_last_processed_date 	DATE;
    c_crlf               		VARCHAR2(2)  := chr(13) || chr(10);
    ln_dim_count         		NUMBER := 0;
    v_process_date       		DATE := sysdate; --Set the Start Date as the day we pull the data from the FO. 

    email_sender         		VARCHAR2(32) := 'mart_processing@iqnavigator.com';
    email_recipients     		VARCHAR2(64) := 'data_warehouse@iqnavigator.com';
    email_subject        		VARCHAR2(64) := 'Headcount Cube FACT Errors ';
 BEGIN
     ln_msg_id := DM_MSG_LOG_SEQ.nextval;

     dm_cube_utils.make_indexes_visible;
   
     BEGIN
       SELECT count(1)
         INTO ln_dim_count
         FROM dm_cube_jobs_log a,
              dm_cube_jobs b
        WHERE a.cube_job_id = b.cube_job_id
          AND b.cube_object_type in ( 'SPEND_CUBE-DIM','CUBE-DIM')
          AND a.date_id between TO_NUMBER(TO_CHAR((SYSDATE-6),'YYYYMMDD')) and TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
          AND a.load_status     = 'FAILED';
     END;

     IF ln_dim_count <> 0 THEN -- this means errors in DIM loads in last 7 days
       gv_app_err_msg := 'FACT did not load due to FAILED DIM process in last 7 days!';
       gv_db_err_msg  := 'Please check dm_cube_jobs_log and fix the DIM loads and then change the load status to COMPLETED from FAILED to process FACT';
       RAISE ge_exception;
     END IF;

     EXECUTE IMMEDIATE 'TRUNCATE TABLE DM_HC_CHANGE_ASSIGNMENT'; 
     EXECUTE IMMEDIATE 'TRUNCATE TABLE DM_HC_FACT_DELTA'; 
     EXECUTE IMMEDIATE 'ALTER SESSION SET SKIP_UNUSABLE_INDEXES = TRUE';

     IF TRUNC(ld_last_process_date) = '01-JAN-1999' THEN
        lv_first_time_flag := 'Y';
     ELSE
        lv_first_time_flag := 'N';
     END IF;

     BEGIN
  	   	SELECT last_identifier,last_update_date
       	INTO ld_last_processed_id,ld_last_process_date
       	FROM dm_cube_objects
      	WHERE object_name = 'DM_HEADCOUNT_FACT'
      	AND object_source_code =in_data_source_code;
      EXCEPTION
      	WHEN NO_DATA_FOUND THEN
            gv_app_err_msg := 'No Entry for DM_HEADCOUNT_FACT in dm_cube_objects';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;
 
     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'HeadCount Cube Process',gv_proc_name,'I'); -- log the start of main process

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Get HeadCount Assignment Data from FO',gv_proc_name,'I');

     BEGIN
       process_fo_headcount_fact(ln_msg_id,ld_last_processed_id,in_data_source_code);  

       EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to gather the data related to Headcount Assignment from FO!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Populate Headcount Staging Table',gv_proc_name,'I');

     BEGIN
       process_dm_headcount_fact(ln_msg_id,in_data_source_code,lv_first_time_flag,v_process_date);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure process_dm_headcount_fact to process the Headcount FACT in data mart!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

      DM_UTIL_LOG.p_log_msg(ln_msg_id,4,'Populate Headcount FACT',gv_proc_name,'I');

      BEGIN
         populate_headcount_fact(ln_msg_id,v_process_date,ld_last_process_date); 
      EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to process the Headcount FACT in data mart!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
      END;

      DM_UTIL_LOG.p_log_msg(ln_msg_id,4,null,null,'U');


    DM_UTIL_LOG.p_log_msg(ln_msg_id,5,'Updating cube objects for Headcount FACT',gv_proc_name,'I');

     SELECT max(last_assignment_edition_id)
      INTO ln_last_processed_id
      FROM dm_headcount_tmp;

     IF  ( ln_last_processed_id IS NOT NULL )  THEN
     		UPDATE dm_cube_objects
        	SET last_identifier =ln_last_processed_id
      	WHERE object_name = 'DM_HEADCOUNT_FACT'
      	AND object_source_code =in_data_source_code;
     END IF;

     IF  ( v_process_date IS NOT NULL )  THEN
     	UPDATE dm_cube_objects
        SET LAST_UPDATE_DATE = v_process_date
      	WHERE object_name = 'DM_HEADCOUNT_FACT'
      	AND object_source_code =in_data_source_code;
     END IF;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,5,null,null,'U');

     COMMIT;

     IF ltrim(rtrim(to_char(sysdate,'DAY'))) IN ('SATURDAY','SUNDAY') THEN   

       DM_UTIL_LOG.p_log_msg(ln_msg_id,6,'Gather Stats on DM_HC_FACT ',gv_proc_name,'I');
  
     	  DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_HC_FACT', ESTIMATE_PERCENT=>2, METHOD_OPT=>'FOR ALL COLUMNS SIZE 1', CASCADE=>TRUE, no_invalidate=>FALSE);

       DM_UTIL_LOG.p_log_msg(ln_msg_id,6,null,null,'U');
     END IF;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');

     DM_UTIL_LOG.p_log_cube_load_status('DM_HEADCOUNT_FACT',
                                               in_data_source_code,
                                               'HEADCOUNT_CUBE-FACT',
                                               'COMPLETED',
                                               p_date_id);

     COMMIT;

  EXCEPTION
      WHEN ge_exception THEN
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_headcount_fact_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
           ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_app_err_msg,
                                               gv_db_err_msg,
                                               gv_proc_name);
           DM_UTIL_LOG.p_log_cube_load_status('DM_HEADCOUNT_FACT',
                                               in_data_source_code,
                                               'HEADCOUNT_CUBE-FACT',
                                               'FAILED',
                                               p_date_id);
 	 	DM_UTILS.send_email(email_sender,email_recipients, email_subject,'Headcount FACT load processing Failed!'|| c_crlf ||'Please see the tables dm_msg_log and dm_error_log for details'); 
      WHEN OTHERS THEN
           gv_db_err_msg  := SQLERRM;
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_headcount_fact_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');
           gv_app_err_msg := 'Unknown Error !';
           ln_err         := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                     gv_app_err_msg,
                                                     gv_db_err_msg,
                                                     gv_proc_name);
    	     DM_UTIL_LOG.p_log_cube_load_status('DM_HEADCOUNT_FACT',
                                              in_data_source_code,
                                              'HEADCOUNT_CUBE-FACT',
                                              'FAILED',
                                              p_date_id);
 	    DM_UTILS.send_email(email_sender, email_recipients, email_subject,'Headcount FACT load processing Failed!'||c_crlf||'Please see the tables dm_msg_log and dm_error_log for details'); 
  END p_main;
END dm_headcount_fact_process;
/