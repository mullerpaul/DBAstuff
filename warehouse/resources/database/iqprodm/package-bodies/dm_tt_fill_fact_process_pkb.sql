CREATE OR REPLACE PACKAGE BODY dm_tt_fill_fact_process
/**************************************************************************************************
 * Name:   dm_tt_fill_fact_process
 * Desc:   This package contains all the procedures required to process time to fill FACT
 * Source: Front office Tables 
 *
 * Author  Date          Version   History
 * ------------------------------------------------------------------------------------------------
 * Sajeev  06/14/2011    Initial
 * Sajeev  04/10/2012    Added NVL for get_top_parent_org_id
 * Sajeev  06/07/2012    Added TRUNC(in_process_date) - 5  
 * Sajeev  08/08/2012    Added sqlerrm before rollback
 * JoeP    02/01/2016    Hard-coded dblink
 ****************************************************************************************************/
AS
    gv_app_err_msg       VARCHAR2(2000)  := NULL;
    gv_db_err_msg        VARCHAR2(2000)  := NULL;
    ge_exception         EXCEPTION;
 
 /*****************************************************************
  * Name: process_fo_tt_fill_fact
  * Desc: This procedure calls a procedure residing in Front office
  *       to gather the data needed for Assignments ( WO  ) in
  *       FO and later pulls the data into data mart Assignment table
  *****************************************************************/
  PROCEDURE process_fo_tt_fill_fact(in_msg_id        	  IN number,
                              	    id_last_processed_id  IN number,
                                    in_data_source_code   IN varchar2)
  IS
    ln_err_num           NUMBER;
    lv_err_msg           VARCHAR2(2000)          := NULL;
    ln_count             NUMBER;
  BEGIN
     BEGIN
        fo_dm_tt_fill_process.p_main@FO_R(in_msg_id,id_last_processed_id,in_data_source_code);  
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'process_fo_tt_fill_fact: Unable to execute the procedure to get the time to fill Assignment data from FO';
            gv_db_err_msg := SQLERRM;
            Rollback;
	       RAISE ge_exception;
     END;

     BEGIN
       SELECT err_msg
         INTO lv_err_msg
         FROM fo_dm_err_msg_tmp@FO_R;

          IF lv_err_msg IS NOT NULL THEN
             gv_app_err_msg := 'process_fo_tt_fill_fact: Errors occured in the procedure to get the time to fill Assignment data from FO';
             gv_db_err_msg := lv_err_msg||' '||SQLERRM;
             RAISE ge_exception;
          END IF;

     EXCEPTION
        WHEN NO_DATA_FOUND THEN
             lv_err_msg := NULL;
     END;

     BEGIN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_tt_fill_tmp'; 
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'process_fo_tt_fill_fact: Unable to trunacte dm_tt_fill_tmp!';
            gv_db_err_msg := SQLERRM;
            RAISE ge_exception;
     END;

    BEGIN
      INSERT INTO dm_tt_fill_tmp t
              ( BUYER_ORG_ID,
  		  	SUPPLIER_ORG_ID,
  		  	JOB_ID,
  		  	PERSON_ID,
  		  	ASSIGNMENT_ID,
  		  	ASSIGNMENT_STATUS,
  		  	CANDIDATE_ID,
  		  	JOB_CATEGORY_ID,
  		  	BUYER_JOB_APPR_DATE,
  		  	BUYER_JOB_CREATE_DATE,
  		  	JOB_RELEASE_SUPP_DATE,
  		  	MATCH_SUBMITTED_DATE,
  		  	MATCH_CREATED_DATE,
  		  	FWD_HM_DATE,
  		  	CAND_INTERVIEW_DATE,
  		  	WO_RELEASE_TO_SUPP_DATE,
  		  	WO_ACCEPT_BY_SUPP_DATE,
  		  	ASSIGNMENT_CREATED_DATE,
  		  	ASSIGNMENT_START_DATE,
  		  	ASSIGNMENT_EFFECT_DATE,
  		  	LAST_ASSIGNMENT_EDITION_ID,
  		  	DATA_SOURCE_CODE,
  		  	LAST_UPDATE_DATE
               )
        SELECT  BUYER_ORG_ID,
  		  	SUPPLIER_ORG_ID,
  		  	JOB_ID,
  		  	PERSON_ID,
  		  	ASSIGNMENT_ID,
  		  	ASSIGNMENT_STATUS,
  		  	CANDIDATE_ID,
  		  	JOB_CATEGORY_ID,
  		  	BUYER_JOB_APPR_DATE,
  		  	BUYER_JOB_CREATE_DATE,
  		  	JOB_RELEASE_SUPP_DATE,
  		  	MATCH_SUBMITTED_DATE,
  		  	MATCH_CREATED_DATE,
  		  	FWD_HM_DATE,
  		  	CAND_INTERVIEW_DATE,
  		  	WO_RELEASE_TO_SUPP_DATE,
  		  	WO_ACCEPT_BY_SUPP_DATE,
  		  	ASSIGNMENT_CREATED_DATE,
  		  	ASSIGNMENT_START_DATE,
  		  	ASSIGNMENT_EFFECT_DATE,
  		  	LAST_ASSIGNMENT_EDITION_ID,
  		  	DATA_SOURCE_CODE,
  		  	LAST_UPDATE_DATE
       FROM fo_dm_tt_fill_tmp@FO_R;

    EXCEPTION
      WHEN OTHERS THEN
        gv_app_err_msg := 'process_fo_tt_fill_fact: Unable to insert into temp table dm_tt_fill_tmp the data from FO';
        gv_db_err_msg := SQLERRM;
        Rollback;
        RAISE ge_exception;
    END;

  EXCEPTION
    WHEN OTHERS THEN
      gv_app_err_msg := 'Unknown Error !';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;
 END process_fo_tt_fill_fact;

 /*****************************************************************
  * Name: process_dm_tt_fill_fact
  * Desc: This procedure pulls the data from temp table and
  *       performs the following tasks in data mart
  *****************************************************************/
  PROCEDURE process_dm_tt_fill_fact(in_msg_id            IN number,
				  			p_data_source_code  IN VARCHAR2,
                                  	iv_first_time_flag   IN varchar2,
				  			in_process_date  IN DATE)
  IS
    ln_count             NUMBER := 0;
    ln_version_id        NUMBER := 0;
    ln_fact_version_id   NUMBER := 0;

 	TYPE hc_assign_tab_type IS TABLE OF dm_tt_fill_fact_staging%ROWTYPE;
 	hc_assign_tab  hc_assign_tab_type;

  CURSOR assignment_cur IS
    SELECT distinct   a.BUYER_ORG_ID BUYER_ORG_ID,
  		      a.SUPPLIER_ORG_ID SUPPLIER_ORG_ID,
  		      a.JOB_ID JOB_ID,
  		      a.PERSON_ID PERSON_ID,
  		      a.ASSIGNMENT_ID ASSIGNMENT_ID,
  		      a.ASSIGNMENT_STATUS ASSIGNMENT_STATUS,
  		      a.CANDIDATE_ID CANDIDATE_ID,
  		      a.JOB_CATEGORY_ID JOB_CATEGORY_ID,
  		      a.BUYER_JOB_APPR_DATE BUYER_JOB_APPR_DATE,
  		      a.BUYER_JOB_CREATE_DATE BUYER_JOB_CREATE_DATE,
  		      a.JOB_RELEASE_SUPP_DATE JOB_RELEASE_SUPP_DATE,
  		      a.MATCH_SUBMITTED_DATE MATCH_SUBMITTED_DATE,
  		      a.MATCH_CREATED_DATE MATCH_CREATED_DATE,
  		      a.FWD_HM_DATE FWD_HM_DATE,
  		      a.CAND_INTERVIEW_DATE CAND_INTERVIEW_DATE,
  		      a.WO_RELEASE_TO_SUPP_DATE WO_RELEASE_TO_SUPP_DATE,
  		      a.WO_ACCEPT_BY_SUPP_DATE WO_ACCEPT_BY_SUPP_DATE,
  		      a.ASSIGNMENT_CREATED_DATE ASSIGNMENT_CREATED_DATE,
  		      a.ASSIGNMENT_START_DATE ASSIGNMENT_START_DATE,
  		      a.ASSIGNMENT_EFFECT_DATE ASSIGNMENT_EFFECT_DATE,
  		      a.DATA_SOURCE_CODE DATA_SOURCE_CODE,
                 CASE WHEN b.delete_flag = 'N' THEN 1 ELSE 0 END as assign_count 
       FROM dm_tt_fill_fact_staging b,
           dm_tt_fill_tmp a
     WHERE a.assignment_id = b.assignment_id
       AND a.data_source_code = b.data_source_code
     ORDER BY a.assignment_id,a.assignment_start_date;

  BEGIN

   IF iv_first_time_flag = 'N' THEN --Incremental Load Only

     FOR assignment_cur_rec IN assignment_cur
       LOOP
        IF assignment_cur_rec.assign_count = 0 THEN
           ln_version_id := 0 ;

           --Invalidate Persisted Assignment Table

           BEGIN
               	UPDATE dm_tt_fill_fact_staging
                SET delete_flag     = 'Y',
                    valid_to_date    = sysdate, --(assignment_cur_rec.valid_from_date -(1/86400)),
                    process_date = in_process_date,
                    last_update_date = sysdate
              	WHERE assignment_id  = assignment_cur_rec.assignment_id
                AND delete_flag     = 'N'
		     AND data_source_code = p_data_source_code
                RETURN MAX(version_id) INTO ln_version_id ;

           EXCEPTION
             WHEN OTHERS THEN
              gv_app_err_msg := 'Unable to update dm_tt_fill_fact_staging for '|| to_char(assignment_cur_rec.assignment_id);
              gv_db_err_msg := SQLERRM;
              Rollback;
              RAISE ge_exception;
           END;

         --Invalidate FACT Records.

          BEGIN
            UPDATE dm_tt_fill_fact
            SET delete_flag     = 'Y',last_update_date = sysdate
            WHERE assignment_id  = assignment_cur_rec.assignment_id
            AND delete_flag     = 'N'
	       AND data_source_code = p_data_source_code;

           EXCEPTION
             WHEN OTHERS THEN
              gv_app_err_msg := 'Unable to update dm_tt_fill_fact! ';
              gv_db_err_msg := SQLERRM;
              Rollback;
              RAISE ge_exception;
           END;

           --Insert into Persisted Assignment Table dm_tt_fill_fact_staging

              BEGIN
                     INSERT INTO dm_tt_fill_fact_staging 
	                 SELECT assignment_cur_rec.BUYER_ORG_ID BUYER_ORG_ID,
  		      		assignment_cur_rec.SUPPLIER_ORG_ID SUPPLIER_ORG_ID,
  		      		assignment_cur_rec.JOB_ID JOB_ID,
  		      		assignment_cur_rec.PERSON_ID PERSON_ID,
  		      		assignment_cur_rec.ASSIGNMENT_ID ASSIGNMENT_ID,
  		      		assignment_cur_rec.ASSIGNMENT_STATUS ASSIGNMENT_STATUS,
  		      		assignment_cur_rec.CANDIDATE_ID CANDIDATE_ID,
  		      		assignment_cur_rec.JOB_CATEGORY_ID JOB_CATEGORY_ID,
  		      		assignment_cur_rec.BUYER_JOB_APPR_DATE BUYER_JOB_APPR_DATE,
  		      		assignment_cur_rec.BUYER_JOB_CREATE_DATE BUYER_JOB_CREATE_DATE,
  		      		assignment_cur_rec.JOB_RELEASE_SUPP_DATE JOB_RELEASE_SUPP_DATE,
  		      		assignment_cur_rec.MATCH_SUBMITTED_DATE MATCH_SUBMITTED_DATE,
  		      		assignment_cur_rec.MATCH_CREATED_DATE MATCH_CREATED_DATE,
  		      		assignment_cur_rec.FWD_HM_DATE FWD_HM_DATE,
  		      		assignment_cur_rec.CAND_INTERVIEW_DATE CAND_INTERVIEW_DATE,
  		      		assignment_cur_rec.WO_RELEASE_TO_SUPP_DATE WO_RELEASE_TO_SUPP_DATE,
  		      		assignment_cur_rec.WO_ACCEPT_BY_SUPP_DATE WO_ACCEPT_BY_SUPP_DATE,
  		      		assignment_cur_rec.ASSIGNMENT_CREATED_DATE ASSIGNMENT_CREATED_DATE,
  		      		assignment_cur_rec.ASSIGNMENT_START_DATE ASSIGNMENT_START_DATE,
  		      		assignment_cur_rec.ASSIGNMENT_EFFECT_DATE ASSIGNMENT_EFFECT_DATE,
		      		sysdate, --valid from date
                      		NULL,
                      		'N',
                      		in_process_date,
		      		ln_version_id+1,
		      		in_msg_id,
  		      		assignment_cur_rec.data_source_code,
                      		sysdate FROM DUAL;

              EXCEPTION
	      	WHEN OTHERS THEN
	        	gv_app_err_msg := 'Unable to insert into dm_tt_fill_fact_staging for the latest version of Assignment records ! ';
	        	gv_db_err_msg := SQLERRM;
                Rollback;
                RAISE ge_exception;
            END;
        END IF;
       END LOOP;
    END IF; --Incremental Load Only


    	--Insert new records for both Incremental and Initial Loading.
  
      BEGIN
			SELECT 	w.BUYER_ORG_ID BUYER_ORG_ID,
  		      		w.SUPPLIER_ORG_ID SUPPLIER_ORG_ID,
  		      		w.JOB_ID JOB_ID,
  		      		w.PERSON_ID PERSON_ID,
  		      		w.ASSIGNMENT_ID ASSIGNMENT_ID,
  		      		w.ASSIGNMENT_STATUS ASSIGNMENT_STATUS,
  		      		w.CANDIDATE_ID CANDIDATE_ID,
  		      		w.JOB_CATEGORY_ID JOB_CATEGORY_ID,
  		      		w.BUYER_JOB_APPR_DATE BUYER_JOB_APPR_DATE,
  		      		w.BUYER_JOB_CREATE_DATE BUYER_JOB_CREATE_DATE,
  		      		w.JOB_RELEASE_SUPP_DATE JOB_RELEASE_SUPP_DATE,
  		      		w.MATCH_SUBMITTED_DATE MATCH_SUBMITTED_DATE,
  		      		w.MATCH_CREATED_DATE MATCH_CREATED_DATE,
  		      		w.FWD_HM_DATE FWD_HM_DATE,
  		      		w.CAND_INTERVIEW_DATE CAND_INTERVIEW_DATE,
  		      		w.WO_RELEASE_TO_SUPP_DATE WO_RELEASE_TO_SUPP_DATE,
  		      		w.WO_ACCEPT_BY_SUPP_DATE WO_ACCEPT_BY_SUPP_DATE,
  		      		w.ASSIGNMENT_CREATED_DATE ASSIGNMENT_CREATED_DATE,
  		      		w.ASSIGNMENT_START_DATE ASSIGNMENT_START_DATE,
  		      		w.ASSIGNMENT_EFFECT_DATE ASSIGNMENT_EFFECT_DATE,
				sysdate, --Valid from date
				NULL,
				'N',
				in_process_date,
				1,
                                in_msg_id,
                                w.data_source_code,
                                sysdate
			BULK COLLECT INTO hc_assign_tab
         		FROM dm_tt_fill_tmp w
         		WHERE NOT EXISTS --Insert only non-existing records.
             			(SELECT 'X'
                 		 FROM dm_tt_fill_fact_staging w1
                 		 WHERE w1.assignment_id = w.assignment_id
                 		 AND w1.data_source_code = w.data_source_code);

  			FORALL i in hc_assign_tab.first .. hc_assign_tab.last
          		INSERT INTO dm_tt_fill_fact_staging VALUES hc_assign_tab(i);

          EXCEPTION
	   WHEN OTHERS THEN
	        gv_app_err_msg := 'Unable to insert into dm_tt_fill_fact_staging for new records ! ';
	        gv_db_err_msg := SQLERRM;
             Rollback;
             RAISE ge_exception;
         END;

  EXCEPTION
    WHEN OTHERS THEN
      gv_app_err_msg := 'process_dm_tt_fill_fact: Unknown Error';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;
 END process_dm_tt_fill_fact;

 /*****************************************************************
  * Name: populate_tt_fill_fact
  * Desc: Populate the FACT table for new and existing Assignments
  *****************************************************************/
 PROCEDURE populate_tt_fill_fact(in_msg_id 		IN NUMBER,
				  		 in_process_date 	IN DATE, 
                                 in_last_process_date  IN DATE)
  IS
    ln_count             NUMBER;
    v_new_date           DATE;
    ln_fact_version_id   NUMBER;
    ln_assignment_count  NUMBER := 0 ;
    v_work_loc_dim_id    NUMBER;
    l_count              NUMBER := 0;          

 BEGIN
 	INSERT INTO DM_TT_FILL_STAGING_DELTA
          SELECT DISTINCT   BUYER_ORG_ID,
  			    SUPPLIER_ORG_ID,
  			    JOB_ID,
  			    PERSON_ID,
  			    ASSIGNMENT_ID,
  			    ASSIGNMENT_STATUS,
  			    CANDIDATE_ID,
  			    JOB_CATEGORY_ID,
  			    BUYER_JOB_APPR_DATE,
  			    BUYER_JOB_CREATE_DATE,
  			    JOB_RELEASE_SUPP_DATE,
  			    MATCH_SUBMITTED_DATE,
  			    MATCH_CREATED_DATE,
  			    FWD_HM_DATE,
  			    CAND_INTERVIEW_DATE,
  			    WO_RELEASE_TO_SUPP_DATE,
  			    WO_ACCEPT_BY_SUPP_DATE,
  			    ASSIGNMENT_CREATED_DATE,
  			    ASSIGNMENT_START_DATE,
  			    ASSIGNMENT_EFFECT_DATE,
  			    VERSION_ID,
  			    DATA_SOURCE_CODE 
	FROM dm_tt_fill_fact_staging
    	 WHERE TRUNC(process_date) >= TRUNC(in_process_date) - 5  /***5 is added to reprocess last 5 days data in case of missing wo due to job failure */
      AND delete_flag = 'N' 
	 AND assignment_id NOT IN ( select a.assignment_id 
				 		 from   dm_tt_fill_fact a 
				 		 where a.delete_flag = 'N' 
				 		 and a.assignment_id = assignment_id 
				 		 and a.data_source_code = data_source_code
                                 and a.ASSIGNMENT_START_DATE_DIM_ID =to_number(to_char(TRUNC(ASSIGNMENT_START_DATE),'YYYYMMDD')||to_char(DM_CUBE_UTILS.get_data_source_id(data_source_code))||to_char(NVL(DM_CUBE_UTILS.get_top_parent_org_id(BUYER_ORG_ID),0)))
                                  ) ;  

        INSERT INTO DM_TT_FILL_FACT_DELTA(TIME_PERIOD_DATE_DIM_ID ,
  					   BUYER_ORG_DIM_ID,
                                           BUYER_ORG_ID,
  					   SUPPLIER_ORG_DIM_ID,
  					   JOB_DIM_ID,
  					   PERSON_DIM_ID,
  					   ASSIGNMENT_ID,
  					   ASSIGNMENT_STATUS,
  					   CANDIDATE_ID,
  					   JOB_CATEGORY_ID,
  					   BUYER_JOB_APPR_DATE_DIM_ID,
  					   BUYER_JOB_CREATE_DATE_DIM_ID,
  					   JOB_RELEASE_SUPP_DATE_DIM_ID,
  					   MATCH_SUBMITTED_DATE_DIM_ID,
  					   MATCH_CREATED_DATE_DIM_ID,
  					   FWD_HM_DATE_DIM_ID,
  					   CAND_INTERVIEW_DATE_DIM_ID,
  					   WO_RELEASE_TO_SUPP_DATE_DIM_ID,
  					   WO_ACCEPT_BY_SUPP_DATE_DIM_ID,
  					   ASSIGNMENT_CREATED_DATE_DIM_ID,
  					   ASSIGNMENT_START_DATE_DIM_ID,
  					   ASSIGNMENT_EFFECT_DATE_DIM_ID,
  					   TT_JOB_APPROVAL,
  					   TT_JOB_RELEASED,
  					   TT_MATCH_FOR_SUPP,
  					   TT_FWD_TO_HM,
  					   TT_CREATE_ASSIGNMENT,
  					   TT_START_ASSIGNMENT,
  					   TT_EFFECTIVE_ASSIGNMENT,
  					   TT_FILL_ASSIGNMENT,
  					   TIME_X1,
  					   TIME_X2,
  					   TIME_X3,
  					   TIME_X4,
  					   TIME_X5,
  					   TIME_X6,
  					   TIME_X7,
  					   TIME_X8,
  					   TIME_X9A,
  					   TIME_X9B,
  					   DELETE_FLAG,
  					   VERSION_ID,
  					   BATCH_ID,
  					   DATA_SOURCE_CODE,
  					   LAST_UPDATE_DATE,
                                           FACT_SEQUENCE)
        SELECT  (CASE WHEN NVL(to_number(to_char(ASSIGNMENT_START_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(ASSIGNMENT_START_DATE),'YYYYMMDD')||time_id) 
                END) as TIME_PERIOD_DATE_DIM_ID,
		DM_CUBE_UTILS.get_organization_dim_id(buyer_org_id,assignment_start_date,data_source_code)   as buyer_org_dim_id,
                buyer_org_id,
                DM_CUBE_UTILS.get_organization_dim_id(supplier_org_id,assignment_start_date,data_source_code) as supplier_org_dim_id,
		DM_CUBE_UTILS.get_job_dim_id(job_id,assignment_start_date,data_source_code,buyer_org_id) as job_dim_id,
                DM_CUBE_UTILS.get_person_dim_id(person_id,assignment_start_date,data_source_code,buyer_org_id) as person_dim_id,
		assignment_id,
		ASSIGNMENT_STATUS,
		CANDIDATE_ID,
		JOB_CATEGORY_ID,
		(CASE WHEN NVL(to_number(to_char(BUYER_JOB_APPR_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(BUYER_JOB_APPR_DATE),'YYYYMMDD')||time_id) 
                END) as BUYER_JOB_APPR_DATE_DIM_ID,
		(CASE WHEN NVL(to_number(to_char(BUYER_JOB_CREATE_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(BUYER_JOB_CREATE_DATE),'YYYYMMDD')||time_id) 
                END) as BUYER_JOB_CREATE_DATE_DIM_ID,
                (CASE WHEN NVL(to_number(to_char(JOB_RELEASE_SUPP_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(JOB_RELEASE_SUPP_DATE),'YYYYMMDD')||time_id) 
                END) as JOB_RELEASE_SUPP_DATE_DIM_ID,
		(CASE WHEN NVL(to_number(to_char(MATCH_SUBMITTED_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(MATCH_SUBMITTED_DATE),'YYYYMMDD')||time_id) 
                END) as MATCH_SUBMITTED_DATE_DIM_ID,
                (CASE WHEN NVL(to_number(to_char(MATCH_CREATED_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(MATCH_CREATED_DATE),'YYYYMMDD')||time_id) 
                END) as MATCH_CREATED_DATE_DIM_ID,
                (CASE WHEN NVL(to_number(to_char(FWD_HM_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(FWD_HM_DATE),'YYYYMMDD')||time_id) 
                END) as FWD_HM_DATE_DIM_ID,
               (CASE WHEN NVL(to_number(to_char(CAND_INTERVIEW_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(CAND_INTERVIEW_DATE),'YYYYMMDD')||time_id) 
                END) as CAND_INTERVIEW_DATE_DIM_ID,
               (CASE WHEN NVL(to_number(to_char(WO_RELEASE_TO_SUPP_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(WO_RELEASE_TO_SUPP_DATE),'YYYYMMDD')||time_id) 
                END) as WO_RELEASE_TO_SUPP_DATE_DIM_ID,
               (CASE WHEN NVL(to_number(to_char(WO_ACCEPT_BY_SUPP_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(WO_ACCEPT_BY_SUPP_DATE),'YYYYMMDD')||time_id) 
                END) as WO_ACCEPT_BY_SUPP_DATE_DIM_ID,
               (CASE WHEN NVL(to_number(to_char(ASSIGNMENT_CREATED_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(ASSIGNMENT_CREATED_DATE),'YYYYMMDD')||time_id) 
                END) as ASSIGNMENT_CREATED_DATE_DIM_ID,
               (CASE WHEN NVL(to_number(to_char(ASSIGNMENT_START_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(ASSIGNMENT_START_DATE),'YYYYMMDD')||time_id) 
                END) as ASSIGNMENT_START_DATE_DIM_ID,
               (CASE WHEN NVL(to_number(to_char(ASSIGNMENT_EFFECT_DATE,'YYYYMMDD')),0) = 0 THEN  ( -1 * org_time_id)
                     ELSE  to_number(to_char(TRUNC(ASSIGNMENT_EFFECT_DATE),'YYYYMMDD')||time_id) 
                END) as ASSIGNMENT_EFFECT_DATE_DIM_ID,
		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(buyer_job_create_date,buyer_job_appr_date),0),2) as TT_JOB_APPROVAL,
		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(buyer_job_create_date,buyer_job_appr_date),JOB_RELEASE_SUPP_DATE),0),2) as TT_JOB_RELEASED,
		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),MATCH_SUBMITTED_DATE),0),2) as TT_MATCH_FOR_SUPP,
		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(MATCH_SUBMITTED_DATE,JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),FWD_HM_DATE),0),2) as TT_FWD_TO_HM,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(FWD_HM_DATE,MATCH_SUBMITTED_DATE,JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),ASSIGNMENT_CREATED_DATE),0),2) as  TT_CREATE_ASSIGNMENT,
  		--ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(buyer_job_appr_date,buyer_job_create_date),ASSIGNMENT_START_DATE),0),2) as TT_START_ASSIGNMENT,
		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(buyer_job_create_date,ASSIGNMENT_START_DATE),0),2) as TT_START_ASSIGNMENT,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(buyer_job_create_date,ASSIGNMENT_EFFECT_DATE),0),2) as TT_EFFECTIVE_ASSIGNMENT,
  		--ROUND(NVL(WO_ACCEPT_BY_SUPP_DATE - buyer_job_create_date,0),2) as TT_FILL_ASSIGNMENT,
           ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(buyer_job_appr_date,ASSIGNMENT_CREATED_DATE),0),2) as TT_FILL_ASSIGNMENT,
		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(buyer_job_create_date,buyer_job_appr_date),0),2) as TIME_X1,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(buyer_job_appr_date,buyer_job_create_date),JOB_RELEASE_SUPP_DATE),0),2) as TIME_X2,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),MATCH_SUBMITTED_DATE),0),2) as TIME_X3,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(MATCH_SUBMITTED_DATE,JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),FWD_HM_DATE),0),2) as TIME_X4,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(FWD_HM_DATE,MATCH_SUBMITTED_DATE,JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),CAND_INTERVIEW_DATE),0),2) as TIME_X5,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(CAND_INTERVIEW_DATE,FWD_HM_DATE,MATCH_SUBMITTED_DATE,JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),ASSIGNMENT_CREATED_DATE),0),2) as TIME_X6,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(ASSIGNMENT_CREATED_DATE,CAND_INTERVIEW_DATE,FWD_HM_DATE,MATCH_SUBMITTED_DATE,JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),WO_RELEASE_TO_SUPP_DATE),0),2) as TIME_X7,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(WO_RELEASE_TO_SUPP_DATE,ASSIGNMENT_CREATED_DATE,CAND_INTERVIEW_DATE,FWD_HM_DATE,MATCH_SUBMITTED_DATE,JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),WO_ACCEPT_BY_SUPP_DATE),0),2) as TIME_X8,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(WO_ACCEPT_BY_SUPP_DATE,WO_RELEASE_TO_SUPP_DATE,ASSIGNMENT_CREATED_DATE,CAND_INTERVIEW_DATE,FWD_HM_DATE,MATCH_SUBMITTED_DATE,JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),ASSIGNMENT_EFFECT_DATE),0),2) as TIME_X9A,
  		ROUND(NVL(dm_cube_utils.GET_BUSINESS_DAYS(coalesce(WO_ACCEPT_BY_SUPP_DATE,WO_RELEASE_TO_SUPP_DATE,ASSIGNMENT_CREATED_DATE,CAND_INTERVIEW_DATE,FWD_HM_DATE,MATCH_SUBMITTED_DATE,JOB_RELEASE_SUPP_DATE,buyer_job_appr_date,buyer_job_create_date),ASSIGNMENT_START_DATE),0),2) as TIME_X9B,
		'N',
  		VERSION_ID,
  		in_msg_id,
  		DATA_SOURCE_CODE,
  		sysdate,
                tt_fill_fact_seq.NEXTVAL
                FROM ( SELECT DISTINCT to_char(DM_CUBE_UTILS.get_data_source_id(data_source_code))||to_char(NVL(DM_CUBE_UTILS.get_top_parent_org_id(BUYER_ORG_ID),0)) time_id,
                            to_char(NVL(DM_CUBE_UTILS.get_top_parent_org_id(BUYER_ORG_ID),0)) org_time_id,
			    BUYER_ORG_ID,
  			    SUPPLIER_ORG_ID,
  			    JOB_ID,
  			    PERSON_ID,
  			    ASSIGNMENT_ID,
  			    ASSIGNMENT_STATUS,
  			    CANDIDATE_ID,
  			    JOB_CATEGORY_ID,
  			    BUYER_JOB_APPR_DATE,
  			    BUYER_JOB_CREATE_DATE,
  			    JOB_RELEASE_SUPP_DATE,
  			    MATCH_SUBMITTED_DATE,
  			    MATCH_CREATED_DATE,
  			    FWD_HM_DATE,
  			    CAND_INTERVIEW_DATE,
  			    WO_RELEASE_TO_SUPP_DATE,
  			    WO_ACCEPT_BY_SUPP_DATE,
  			    ASSIGNMENT_CREATED_DATE,
  			    ASSIGNMENT_START_DATE,
  			    ASSIGNMENT_EFFECT_DATE,
  			    VERSION_ID,
  			    DATA_SOURCE_CODE 
                        FROM DM_TT_FILL_STAGING_DELTA 
                     ); 

 	 SELECT COUNT(*)  into l_count
          FROM ( SELECT BUYER_ORG_DIM_ID,
                    SUPPLIER_ORG_DIM_ID,
                    JOB_DIM_ID,
                    ASSIGNMENT_ID,
                    DATA_SOURCE_CODE,
                    VERSION_ID,
                    TIME_PERIOD_DATE_DIM_ID,
                    DELETE_FLAG
                FROM  DM_TT_FILL_FACT_DELTA  
     	        GROUP BY   BUYER_ORG_DIM_ID,
                    SUPPLIER_ORG_DIM_ID,
                    JOB_DIM_ID,
                    ASSIGNMENT_ID,
                    DATA_SOURCE_CODE,
                    VERSION_ID,
                    TIME_PERIOD_DATE_DIM_ID,
                    DELETE_FLAG 
                HAVING COUNT(*) > 1);

  	IF ( l_count > 0 ) THEN --Delete only if there are duplicates.
    		DELETE DM_TT_FILL_FACT_DELTA
           		WHERE ROWID IN
                 	(
                   	SELECT ROWID
                     	FROM (
                            SELECT a.rowid
                                   , ROW_NUMBER() OVER ( PARTITION BY A.BUYER_ORG_DIM_ID,A.SUPPLIER_ORG_DIM_ID ,A.JOB_DIM_ID,A.ASSIGNMENT_ID,A.DATA_SOURCE_CODE ,A.VERSION_ID, A.TIME_PERIOD_DATE_DIM_ID,A.DELETE_FLAG
                                                             ORDER BY A.BUYER_ORG_DIM_ID,A.SUPPLIER_ORG_DIM_ID ,A.JOB_DIM_ID,A.ASSIGNMENT_ID,A.DATA_SOURCE_CODE ,A.VERSION_ID, A.TIME_PERIOD_DATE_DIM_ID,A.DELETE_FLAG,
                                                             A.BUYER_JOB_CREATE_DATE_DIM_ID DESC,A.BUYER_JOB_APPR_DATE_DIM_ID DESC,A. JOB_RELEASE_SUPP_DATE_DIM_ID  DESC,A.MATCH_SUBMITTED_DATE_DIM_ID  DESC,A.MATCH_CREATED_DATE_DIM_ID DESC,
                                                             A.FWD_HM_DATE_DIM_ID   DESC,A.CAND_INTERVIEW_DATE_DIM_ID DESC,A.ASSIGNMENT_CREATED_DATE_DIM_ID  DESC,A.WO_RELEASE_TO_SUPP_DATE_DIM_ID  DESC, A.WO_ACCEPT_BY_SUPP_DATE_DIM_ID  DESC, 
                                                             A.ASSIGNMENT_EFFECT_DATE_DIM_ID DESC, A.ASSIGNMENT_START_DATE_DIM_ID DESC
                                                       ) AS rnk
                              FROM DM_TT_FILL_FACT_DELTA a
                          ) WHERE rnk > 1 
                       );

  	END IF;

     INSERT INTO DM_TT_FILL_FACT f SELECT  a.* FROM DM_TT_FILL_FACT_DELTA a; 

  EXCEPTION
    WHEN OTHERS THEN
      gv_app_err_msg := 'populate_tt_fill_fact: Unknown Error';
      gv_db_err_msg  := SQLERRM;
      Rollback;
      RAISE ge_exception;
  END populate_tt_fill_fact;

 /***********************************************************************************************
  * Name: p_main
  * Desc: This procedure contains all the steps involved in gathering and migrating the Time To Fill
  *       fact data from Front office.
  ***********************************************************************************************/
  PROCEDURE p_main(in_data_source_code IN VARCHAR2 DEFAULT 'REGULAR'
                   ,p_date_id     IN NUMBER DEFAULT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')))
  IS
    ln_msg_id            	NUMBER;
    gv_proc_name         	VARCHAR2(100)   := 'dm_tt_fill_fact_process.p_main' ;
    ln_err               	NUMBER;
    ln_err_num           NUMBER;
    ld_last_processed_id 	NUMBER;
    ld_last_process_date 	DATE;
    lv_first_time_flag   	VARCHAR2(1);
    ld_last_update_date  	DATE;
    ln_last_processed_id 	NUMBER;
    ln_last_processed_date DATE;
    ln_dim_count         	NUMBER := 0;
    v_process_date       	DATE := sysdate; --Set the Start Date as the day we pull the data from the FO. 

    email_sender         	VARCHAR2(32) := 'mart_processing@iqnavigator.com';
    email_recipients     	VARCHAR2(64) := 'data_warehouse@iqnavigator.com';
    email_subject        	VARCHAR2(64) := 'Time To Fill Cube FACT Errors';

    c_crlf               	VARCHAR2(2)  := chr(13) || chr(10);

  BEGIN
    ln_msg_id := DM_MSG_LOG_SEQ.nextval;

    dm_cube_utils.make_indexes_visible;

    BEGIN
       SELECT count(1)
         INTO ln_dim_count
         FROM dm_cube_jobs_log a,
              dm_cube_jobs b
        WHERE a.cube_job_id      = b.cube_job_id
          AND b.cube_object_type = 'SPEND_CUBE-DIM'
          AND a.date_id between TO_NUMBER(TO_CHAR((SYSDATE-6),'YYYYMMDD')) and TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
          AND a.load_status     = 'FAILED';

    END;

    IF ln_dim_count <> 0 THEN -- this means errors in DIM loads in last 7 days
       gv_app_err_msg := 'FACT did not load due to FAILED DIM process in last 7 days!';
       gv_db_err_msg  := 'Please check dm_cube_jobs_log and fix the DIM loads and then change the load status to COMPLETED from FAILED to process FACT';
       RAISE ge_exception;
    END IF;

     EXECUTE IMMEDIATE 'TRUNCATE TABLE DM_TT_FILL_STAGING_DELTA'; 
     EXECUTE IMMEDIATE 'TRUNCATE TABLE DM_TT_FILL_FACT_DELTA';


     BEGIN
     	SELECT last_identifier,last_update_date
       	INTO ld_last_processed_id,ld_last_process_date
       	FROM dm_cube_objects
      	WHERE UPPER(object_name) = 'DM_TT_FILL_FACT'
      	AND object_source_code =in_data_source_code;

     EXCEPTION
      	WHEN NO_DATA_FOUND THEN
            gv_app_err_msg := 'No Entry for DM_TT_FILL_FACT in dm_cube_objects';
            gv_db_err_msg := SQLERRM;
            Rollback;
            RAISE ge_exception;
     END;

     IF TRUNC(ld_last_process_date) = '01-JAN-1999' THEN
        lv_first_time_flag := 'Y';
     ELSE
        lv_first_time_flag := 'N';
     END IF;
 
     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,'Time To Fill Cube Process',gv_proc_name,'I'); -- log the start of main process

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,'Get Time To Fill Assignment Data from FO',gv_proc_name,'I');

     BEGIN
       process_fo_tt_fill_fact(ln_msg_id,ld_last_processed_id,in_data_source_code);   
  
       EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to gather the data related to Time To Fill Assignment from FO!';
            gv_db_err_msg := SQLERRM;
            Rollback;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,2,null,null,'U');

     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,'Populate Time To Fill Staging Table',gv_proc_name,'I');

     BEGIN
       process_dm_tt_fill_fact(ln_msg_id,in_data_source_code,lv_first_time_flag,v_process_date);
     EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure process_dm_tt_fill_fact to process the Time To Fill FACT in data mart!';
            gv_db_err_msg := SQLERRM;
            Rollback;
            RAISE ge_exception;
     END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,3,null,null,'U');

     DM_UTIL_LOG.p_log_msg(ln_msg_id,4,'Populate Time To Fill FACT',gv_proc_name,'I');

      BEGIN
         populate_tt_fill_fact(ln_msg_id,v_process_date,ld_last_process_date); 
      EXCEPTION
       WHEN OTHERS THEN
            gv_app_err_msg := 'Unable to execute the procedure to process the Time To Fill FACT in data mart!';
            gv_db_err_msg := SQLERRM;
            Rollback;
            RAISE ge_exception;
      END;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,4,null,null,'U');

     DM_UTIL_LOG.p_log_msg(ln_msg_id,5,'Updating cube objects for Time To Fill FACT',gv_proc_name,'I');

     SELECT max(last_assignment_edition_id)
      INTO ln_last_processed_id
      FROM dm_tt_fill_tmp;

     IF  ( ln_last_processed_id IS NOT NULL )  THEN
     	UPDATE dm_cube_objects
        SET last_identifier =ln_last_processed_id
      	WHERE object_name = 'DM_TT_FILL_FACT'
      	AND object_source_code =in_data_source_code;
     END IF;

     IF  ( v_process_date IS NOT NULL )  THEN
     	UPDATE dm_cube_objects
        SET LAST_UPDATE_DATE = v_process_date
      	WHERE object_name = 'DM_TT_FILL_FACT'
      	AND object_source_code =in_data_source_code;
     END IF;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,5,null,null,'U');

     IF ltrim(rtrim(to_char(sysdate,'DAY'))) IN ('SATURDAY','SUNDAY') THEN
     		BEGIN
    			DM_UTIL_LOG.p_log_msg(ln_msg_id,6,'Analyze Time To Fill FACT',gv_proc_name,'I');
      		DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=>USER, TABNAME=>'DM_TT_FILL_FACT', ESTIMATE_PERCENT=>5, METHOD_OPT=>'FOR ALL COLUMNS SIZE 1', CASCADE=>TRUE, no_invalidate=>FALSE);
     			DM_UTIL_LOG.p_log_msg(ln_msg_id,6,null,null,'U');
     		EXCEPTION
       		WHEN OTHERS THEN
           	gv_app_err_msg := 'Unable to analyze the Time To Fill Fact! ';
           	gv_db_err_msg  := SQLERRM;
                Rollback;
           	RAISE ge_exception;
     		END;
     END IF;

     COMMIT;

     DM_UTIL_LOG.p_log_msg(ln_msg_id,1,null,null,'U');

     DM_UTIL_LOG.p_log_cube_load_status('DM_TT_FILL_FACT',
                                               in_data_source_code,
                                               'CUBE-FACT',
                                               'COMPLETED',
                                               p_date_id);

     COMMIT;

  EXCEPTION
      WHEN ge_exception THEN
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_tt_fill_fact_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');

           ln_err  := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                               gv_app_err_msg,
                                               gv_db_err_msg,
                                               gv_proc_name);
          DM_UTIL_LOG.p_log_cube_load_status('DM_TT_FILL_FACT',
                                               in_data_source_code,
                                               'CUBE-FACT',
                                               'FAILED',
                                               p_date_id);
 	    DM_UTILS.send_email(email_sender,email_recipients,email_subject,'Time To Fill FACT load processing Failed!'||c_crlf||'Please see the tables dm_msg_log and dm_error_log for details');
      WHEN OTHERS THEN
           gv_db_err_msg  := SQLERRM;
           Rollback;
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,'dm_tt_fill_fact_process-ERROR..Please see the dm_error_log for details',gv_proc_name,'I');
           DM_UTIL_LOG.p_log_msg(ln_msg_id,99,null,null,'U');

           gv_app_err_msg := 'Unknown Error !';
           ln_err         := DM_UTIL_LOG.f_log_error(ln_msg_id,
                                                        gv_app_err_msg,
                                                        gv_db_err_msg,
                                                        gv_proc_name);
    	     DM_UTIL_LOG.p_log_cube_load_status('DM_TT_FILL_FACT',
                                               in_data_source_code,
                                               'CUBE-FACT',
                                               'FAILED',
                                               p_date_id);
 	    DM_UTILS.send_email(email_sender, email_recipients, email_subject,'Time To Fill FACT load processing Failed!'||c_crlf||'Please see the tables dm_msg_log and dm_error_log for details');
  END p_main;
END dm_tt_fill_fact_process;
/