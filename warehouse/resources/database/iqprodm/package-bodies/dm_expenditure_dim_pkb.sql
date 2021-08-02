CREATE OR REPLACE PACKAGE BODY dm_expenditure_dim_process
AS
    PROCEDURE p_main
    (
      p_source_code IN VARCHAR2
    )
    IS
       p_msg_id            NUMBER;
       ln_count            NUMBER;
       lv_proc_name        user_jobs.what%TYPE := 'DM_EXPENDITURE_DIM_PROCESS.P_MAIN';
       v_crnt_proc_name    user_jobs.what%TYPE;

       lv_fo_app_err_msg   VARCHAR2(2000)  := NULL;
       lv_fo_db_err_msg    VARCHAR2(2000)  := NULL;
       lv_app_err_msg      VARCHAR2(2000)  := NULL;
       lv_db_err_msg       VARCHAR2(2000)  := NULL;

       email_sender        VARCHAR2(32) := 'mart_processing@iqnavigator.com';
       email_recipients    VARCHAR2(64) := 'data_warehouse@iqnavigator.com';
       email_subject       VARCHAR2(64) := 'DM_EXPENDITURE_DIM_PROCESS Update';

       v_inp_rec_count     NUMBER;
       
       v_cutoff_date       VARCHAR2(16);
       v_date_id           NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'));
    BEGIN
       /*
       ** Alter session so that process/optimizer
       ** can see all invisible indexes
       */
       dm_cube_utils.make_indexes_visible;

       v_crnt_proc_name := lv_proc_name;

       --
       -- Get the sequence reuired for logging messages
       --
       SELECT dm_msg_log_seq.NEXTVAL INTO p_msg_id FROM dual;

       --
       -- Check if the previous job still running
       --
       ln_count := dm_cube_utils.get_job_status(lv_proc_name);
       IF ln_count > 1 THEN
           --
           -- previous job still running log and exit
           --
           dm_util_log.p_log_msg(p_msg_id,0,gv_process || ' - PREVIOUS JOB STILL RUNNING',lv_proc_name,'I');
           dm_util_log.p_log_msg(p_msg_id,0,NULL,NULL,'U');
       ELSE

           --
           --Log initial load status
           --
           dm_util_log.p_log_load_status(p_msg_id, gv_process,'FO','STARTED',NULL,'I');

           --
           -- Call the procedure to get the FO New Expenditure information
           --
           v_crnt_proc_name := 'DM_EXPENDITURE_DIM_PROCESS.GET_NEW_EXPENDITURE_CHANGES';
           dm_util_log.p_log_msg(p_msg_id,1, p_source_code || ': FO Expenditure Dim Extract',v_crnt_proc_name,'I');
           get_new_expenditure_changes(p_msg_id, p_source_code, v_inp_rec_count);
           dm_util_log.p_log_msg(p_msg_id,1, NULL,NULL,'U');

           dm_util_log.p_log_load_status(p_msg_id, gv_process,'FO','COMPLETE',0,'U');

           dm_util_log.p_log_load_status(p_msg_id, gv_process,'DW','STARTED',NULL,'I');
           pull_and_transform(p_source_code, p_msg_id);
           dm_util_log.p_log_load_status(p_msg_id, gv_process,'DW','COMPLETE',0,'U');
       END IF;
       
           DM_UTIL_LOG.p_log_cube_load_status('DM_EXPENDITURE_DIM', p_source_code , 'SPEND_CUBE-DIM', 'COMPLETED', v_date_id);
    EXCEPTION
       WHEN OTHERS THEN
       BEGIN
             lv_fo_db_err_msg := SQLERRM;
             dm_util_log.p_log_load_status(p_msg_id, gv_process,'FO','FAILED',0,'U');
             dm_util_log.p_log_cube_load_status('DM_EXPENDITURE_DIM', p_source_code , 'SPEND_CUBE-DIM', 'FAILED', v_date_id);             
             dm_utils.send_email(email_sender, email_recipients, email_subject, p_source_code || ' Process failed due to the following ' || c_crlf || lv_fo_app_err_msg || c_crlf || lv_fo_db_err_msg || c_crlf);
       END;
    END p_main;

    PROCEDURE get_new_expenditure_changes
    (
        p_msg_id        IN  NUMBER
      , p_source_code   IN  VARCHAR2
      , p_out_rec_count OUT NUMBER  -- Records Extracted
    )
    IS
       lv_proc_name         VARCHAR2(100)  := 'GET_NEW_EXPENDITURE_CHANGES.GET_NEW_EXPENDITURE_CHANGES';

       v_sql VARCHAR2(32767);
       v_link_name   VARCHAR2(32);    -- Name of DB Link to FO Instance
    BEGIN
       CASE (p_source_code)
           WHEN 'REGULAR'  THEN v_link_name := 'FO_R';
           WHEN 'WACHOVIA' THEN v_link_name := 'WA_LINK';
       END CASE;

       EXECUTE IMMEDIATE 'TRUNCATE TABLE dm_expenditure_tmp';

       v_sql := 'INSERT INTO dm_expenditure_tmp
		(
		   expenditure_category
		 , expenditure_type
		 , data_source_code
		 , inv_object_source
		 , spend_category
		 , spend_type
		 , exp_sub_type
		 , last_update_date
		)
		SELECT DISTINCT ''Labor'', DECODE(ri.rate_identifier_id, 1, ''Regular time'', 2, ''Overtime'', 3, ''Doubletime'', ''Custom time''), 
                        ''' || p_source_code || ''', ''FOI'', ''Time'',
       			DECODE(ri.rate_identifier_id,1,''ST'',2,''OT'',3,''DT'', DECODE(ri.bo_expenditure_type, ''DT'', ''CS-DT'', ''ST'', ''CS-ST'',''OT'',''CS-OT'', ri.bo_expenditure_type)),
       			ri.bo_expenditure_type exp_sub_type, SYSDATE
		  FROM rate_identifier@LNK ri
		UNION ALL
		SELECT DISTINCT ''Expense'', ''Expense Report'',
                        ''' || p_source_code || ''', ''FOI'', ''Expense'',
			 et.name, et.name, SYSDATE
                  FROM expense_type@LNK et
		UNION ALL
		SELECT DISTINCT ''Payment Request'', ''Bonus'',
                        ''' || p_source_code || ''', ''FOI'', ''Assignment Bonus'',
			bt.description, bt.description, SYSDATE
		  FROM bonus_type@LNK bt
		UNION ALL
		SELECT DISTINCT ''Payment Request'', ''Assignment'',
                        ''' || p_source_code || ''', ''FOI'', ''Payment Requests'',
			pt.description, pt.description, SYSDATE
		  FROM payment_type@LNK pt
		 WHERE pt.category = 0
		UNION ALL
		SELECT DISTINCT ''Payment Request'', ''Ad-hoc'', 
                        ''' || p_source_code || ''', ''FOI'', ''Milestones'',
			pt.description, pt.description, SYSDATE
		  FROM payment_type@LNK pt
		 WHERE pt.category = 1
		UNION ALL
		SELECT DISTINCT ''Payment Request'', ''Rate Table'', 
                        ''' || p_source_code || ''', ''FOI'', ''Milestones'',
			''Rate Table Payment Requests'', NULL, SYSDATE
		  FROM service@LNK s
		 WHERE s.service_expenditure_type_fk IS NULL
		UNION ALL
		SELECT DISTINCT ''Payment Request'', ''Rate Table'',
                        ''' || p_source_code || ''', ''FOI'', ''Payment Requests'',
			DECODE(st.description, ''NON-TAX'', ''Proj NON-TAX'', st.description), st.description, SYSDATE
		  FROM service@LNK s, service_expenditure_type@LNK st
		 WHERE s.service_expenditure_type_fk = st.identifier
		UNION ALL
		SELECT DISTINCT ''Tax'', ''Tax'',
                        ''' || p_source_code || ''', ''FOI'', ''Tax'',
			fet.expenditure_type_name, fet.expenditure_type_name, SYSDATE
		  FROM flexrate_expenditure_type@LNK fet, flexrate_rule_action@LNK fra
		 WHERE fet.expenditure_type_name = fra.expenditure_type_name_fk
		   AND (fra.action_code = ''TAX'' OR fra.action_code = ''WITHHOLDING_TAX_ON_FEE'')
		UNION ALL
		SELECT DISTINCT ''Discount'', ''Straight'', 
                        ''' || p_source_code || ''', ''FOI'', ''Discounts'',
			''TD'', fet.expenditure_type_name, SYSDATE
		  FROM flexrate_expenditure_type@LNK fet, flexrate_rule_action@LNK fra
		 WHERE fet.expenditure_type_name = fra.expenditure_type_name_fk
		   AND fra.action_code = ''DISCOUNT''
		UNION ALL
		SELECT DISTINCT ''Rebate'', ''Management Fee'',
                        ''' || p_source_code || ''', ''FOI'', ''Rebates'',
			''Flex - MFR'', fet.expenditure_type_name, SYSDATE
		  FROM flexrate_expenditure_type@LNK fet, flexrate_rule_action@LNK fra
		 WHERE fet.expenditure_type_name = fra.expenditure_type_name_fk
		   AND fra.action_code = ''MANAGEMENT_FEE_REBATE''';

       v_sql := replace(v_sql, '@LNK', '@' || v_link_name);
       EXECUTE IMMEDIATE v_sql;
       p_out_rec_count := SQL%ROWCOUNT;
       COMMIT;
    END get_new_expenditure_changes;

    /*
    ** Pull the already extracted data
    ** from remote FO temp/stage tables
    ** into local temp/stage tables
    ** and then tranform/apply to final
    ** DM tables
    */
    PROCEDURE pull_and_transform
    (
        p_source_code IN VARCHAR2
      , p_msg_id      IN NUMBER
    )
    IS
          v_crnt_proc_name user_jobs.what%TYPE := 'DM_ASSIGNMENT_DETAILS.PULL_AND_TRANSFORM';
    BEGIN
          MERGE INTO dm_expenditure_dim t
          USING dm_expenditure_tmp s
             ON (
                      t.data_source_code  = s.data_source_code
                  AND t.inv_object_source = s.inv_object_source
                  AND t.spend_category    = s.spend_category
                  AND t.spend_type        = s.spend_type
                )
           WHEN MATCHED THEN UPDATE SET
                   t.expenditure_category = s.expenditure_category
                 , t.expenditure_type     = s.expenditure_type
                 , t.exp_sub_type         = s.exp_sub_type
                 , t.last_update_date     = SYSDATE
           WHEN NOT MATCHED THEN INSERT
           (
                   expenditure_dim_id
                 , expenditure_category
                 , expenditure_type
                 , data_source_code
                 , inv_object_source
                 , spend_category
                 , spend_type
                 , last_update_date
                 , exp_sub_type
                 , old_expenditure_dim_id
           )
           VALUES
           (
                   dm_expenditure_dim_id_seq.NEXTVAL
                 , s.expenditure_category
                 , s.expenditure_type
                 , s.data_source_code
                 , s.inv_object_source
                 , s.spend_category
                 , s.spend_type
                 , SYSDATE --LAST_UPDATE_DATE
                 , s.exp_sub_type
                 , dm_expenditure_dim_id_seq.CURRVAL
           );
          COMMIT;

          dm_util_log.p_log_msg(p_msg_id, 5, NULL, NULL, 'U');
    END pull_and_transform;

END dm_expenditure_dim_process;
/