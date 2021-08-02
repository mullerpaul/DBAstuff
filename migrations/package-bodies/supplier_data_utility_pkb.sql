CREATE OR REPLACE PACKAGE BODY supplier_data_utility
AS
/******************************************************************************
   NAME:       supplier_data_utility
   PURPOSE:    public functions and procedures which maintain the detailed data 
               used for grading and ranking suppleirs.

   REVISIONS:
   Jira       Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
              04/13/2017  Paul Muller      Created this package.
   MSCV-667   05/09/2017  Paul Muller      logging changes for loading many clients at once.
   MSVC-886   06/06/2017  Paul Muller      fixed bug with release_tier column.
   MSVC-899   06/08/2017  Joe Pullifrone   add call to load default metrics in data load.   
   MSVC-900   06/12/2017  Joe Pullifrone   do not fail when there is no data in GTTs.
   MSVC-1019  06/28/2017  Paul Muller      Adding a few new columns.
   MSVC-1268  08/30/2017  Joe Pullifrone   Add MV refreshes to move_data_to_perm_tables.
   MSVC-1344  09/07/2017  Joe Pullifrone   atomic_refresh = false for MVs and special exception handling.
   MSVC-1666  10/31/2017  Paul Muller      load visibility data into client_visibility_list
   MSVC-1997  11/17/2017  Jack Cutiongco   Added database_name field
   MSVC-1915  12/04/2017  Paul and Joe     Use visibility list for copying defaults
   MSVC-2014  12/04/2017  Jack Cutiongco   Added insertion of found duplicate data between supplier_release_gtt and supplier_release
   MSVC-2776  03/12/2018  Hassina Majid	   Add a reference to the new column in client_visibility_list to supplier_data_utility.move_data_to_perm_tables.
                                           Load for Beeline and IQN data. 
   MSVC-3864  07/20/2018  Paul Muller      Fix bug in finding dupliate data. 
   MSVC-3906  08/11/2018  Hassina Majid    Remove the MView refreshes from this routine to a dbms_scheduler.

******************************************************************************/

  --------------------------------------------------------------------------------
  PROCEDURE initialize_logger IS
  BEGIN
    /* Instantiate the logger and set the level to INFO.
      Do we want to parameterize the logging level instead?  
      Perhaps have it passed by the caller in each client DB?
      Investigate later. */
    logger_pkg.instantiate_logger;
    logger_pkg.set_source('SUPPLIER_DATA_UTILITY');
    logger_pkg.set_level('DEBUG');

  END initialize_logger;
  
  --------------------------------------------------------------------------------
  PROCEDURE insert_history_row (pi_legacy_source    IN  load_history.legacy_source%TYPE,
                                po_load_history_id  OUT load_history.load_id%TYPE)
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;

    lv_load_id load_history.load_id%TYPE := load_history_seq.nextval;
    
  BEGIN
    INSERT INTO load_history
      (load_id,
       legacy_source,
       load_status,
       load_start_timestamp) 
    VALUES 
      (lv_load_id,
       pi_legacy_source,
       'running',
       SYSTIMESTAMP);

    COMMIT;
    po_load_history_id := lv_load_id;

  END insert_history_row;  

  --------------------------------------------------------------------------------
  PROCEDURE update_history_row (pi_load_id                    IN load_history.load_id%TYPE,
                                pi_load_status                IN load_history.load_status%TYPE,
                                pi_error_message              IN load_history.error_message%TYPE,
                                pi_merged_rows_parent_table   IN load_history.merged_rows_parent_table%TYPE,
                                pi_merged_rows_child_table    IN load_history.merged_rows_child_table%TYPE,
                                pi_merged_rows_visibility_tab IN load_history.merged_rows_visibility_table%TYPE)
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;

  BEGIN
    UPDATE load_history
       SET load_status = pi_load_status,
           load_end_timestamp = SYSTIMESTAMP,
           error_message = pi_error_message,
           merged_rows_parent_table = pi_merged_rows_parent_table,
           merged_rows_child_table = pi_merged_rows_child_table,
           merged_rows_visibility_table = pi_merged_rows_visibility_tab
     WHERE load_id = pi_load_id;  
     
    COMMIT;

  END update_history_row;  

  --------------------------------------------------------------------------------
  FUNCTION temp_tables_contain_data
  RETURN BOOLEAN
  IS
    lv_result BOOLEAN := FALSE;
    lv_dummy  VARCHAR2(10);
    
  BEGIN  
    BEGIN
      /*  Quickly check for data in parent table without doing a full scan. */
      SELECT 'dataexists'
        INTO lv_dummy
        FROM dual
       WHERE EXISTS (SELECT * FROM supplier_release_gtt);
      
      /* If we found a row, we're done */ 
      lv_result := TRUE;
      
    EXCEPTION
      WHEN no_data_found THEN
        BEGIN
          /* no data in the parent, how about the child table? */
          SELECT 'dataexists'
            INTO lv_dummy
            FROM dual
           WHERE EXISTS (SELECT * FROM supplier_submission_gtt);

          lv_result := TRUE; 
        
        EXCEPTION 
          WHEN no_data_found THEN
            lv_result := FALSE;
        END;
    END;  
    
    RETURN lv_result;

  END temp_tables_contain_data;  
        
  --------------------------------------------------------------------------------
  PROCEDURE move_data_to_perm_tables (pi_legacy_source IN VARCHAR2)
  IS
    lv_history_table_pk    load_history.load_id%TYPE;
    lv_visibility_rowcount NUMBER;
    lv_release_rowcount    NUMBER;
    lv_candidate_rowcount  NUMBER;
    lv_error_code          NUMBER;
    lv_error_message       load_history.error_message%TYPE;
    lv_bulk_session_guid   RAW(16) := sys_guid();
    e_mv_refresh           EXCEPTION;
    e_copy_client_defaults EXCEPTION;
    lv_load_date           DATE := SYSDATE;

    
  BEGIN
    /* Prepare logging system */
    initialize_logger;

    /* Confirm the legacy source is either Beeline or IQN */
    IF (pi_legacy_source IS NULL OR
        pi_legacy_source NOT IN ('Beeline','IQN'))
    THEN
      raise_application_error(-20002, 'Legacy source must be "Beeline" or "IQN"');
    END IF;

    /* Check for data in temp tables.  Although no data is rare, it is not invalid. 
       Log message about it but do not fail. */
    IF temp_tables_contain_data
    THEN
      logger_pkg.info('Start SSC load from ' || pi_legacy_source);
                    
      insert_history_row (pi_legacy_source   => pi_legacy_source,
                          po_load_history_id => lv_history_table_pk);
    
      /* Now do the "real work" - merge the data from the temp tables into the perm tables. 
         First the visibility info. (org tree) */
      logger_pkg.DEBUG('merge into client_visibility_list - ' || pi_legacy_source);
      CASE pi_legacy_source
        WHEN 'IQN' THEN 
          MERGE INTO client_visibility_list t
          USING client_visibility_list_gtt s
             ON (t.log_in_client_guid = s.log_in_client_guid AND
                 t.visible_client_guid = s.visible_client_guid               
               )
           WHEN NOT MATCHED THEN 
         INSERT (log_in_client_guid, visible_client_guid,score_config_owner_guid)
         VALUES (s.log_in_client_guid, s.visible_client_guid,s.score_config_owner_guid);

        WHEN 'Beeline' THEN 
          /* Find any new client_guids in legacy Beeline data and then insert a "self row" 
             (where log_in_client_guid = visibile_client_guid) into the visibility table.
             Thie existance of these rows allow us to join through the visibility table to the data.  */
          MERGE INTO client_visibility_list t
          USING (SELECT DISTINCT client_guid AS new_client_guid
                   FROM supplier_release_gtt) s
             ON (t.log_in_client_guid = s.new_client_guid) 
           WHEN NOT MATCHED THEN 
         INSERT (log_in_client_guid, visible_client_guid,score_config_owner_guid)
         VALUES (s.new_client_guid, s.new_client_guid,s.new_client_guid);
             
      END CASE;
      
      lv_visibility_rowcount := SQL%rowcount;
      logger_pkg.DEBUG('merge into client_visibility_list - ' || pi_legacy_source || ' - complete', TRUE);

      IF pi_legacy_source = 'Beeline'
      THEN
        /* Inserts duplicate data found between supplier_release_gtt and supplier_release.  These will then be excluded
           from the merge into SUPPLIER_RELEASE.  This process is needed to ensure no record with the same cliend_guid, 
           supplier_guid, and requisition_guid but with a different release_guid will be inserted into supplier_release, 
           causing unique constraint errors. This type of scenario could happen in Beeline's lower environments since a 
           client DB is often copied in to multiple lower environment DBs, and then those would all be loaded back into 
           one SSC environment.  */
        logger_pkg.debug('Mark CWS duplicates');
        INSERT INTO supplier_release_duplicates (release_guid,
             client_guid,
             client_name,
             supplier_guid,
             supplier_name,
             release_date,
             release_tier,
             requisition_guid,
             requisition_id,
             requisition_create_date,
             requisition_currency,
             requisition_title,
             requisition_industry,
             requisition_country,
             requisition_state,
             requisition_city,
             requisition_positions,
             requisition_rate,
             database_name,
             insert_date)
        SELECT t.release_guid,
            t.client_guid,
            t.client_name,
            t.supplier_guid,
            t.supplier_name,
            t.release_date,
            t.release_tier,
            t.requisition_guid,
            t.requisition_id,
            t.requisition_create_date,
            t.requisition_currency,
            t.requisition_title,
            t.requisition_industry,
            t.requisition_country,
            t.requisition_state,
            t.requisition_city,
            t.requisition_positions,
            t.requisition_rate,
            t.database_name,
            lv_load_date
        FROM supplier_release_gtt t
        JOIN supplier_release s ON 
          (t.client_guid = s.client_guid AND 
           t.supplier_guid = s.supplier_guid AND
           t.requisition_guid = s.requisition_guid AND
           t.release_guid <> s.release_guid);

        logger_pkg.debug('Mark CWS duplicates - complete', TRUE);
      END IF;

      logger_pkg.debug('merge into supplier_release');
      MERGE INTO supplier_release t
      USING (SELECT release_guid,
                client_guid,
                client_name,
                supplier_guid,
                supplier_name,
                release_date,
                requisition_guid,
                requisition_id,
                requisition_create_date,
                requisition_currency,
                requisition_title,
                requisition_industry,
                requisition_country,
                requisition_state,
                requisition_city,
                release_tier,
                requisition_positions,
                requisition_rate,
                database_name 
            FROM supplier_release_gtt s 
           WHERE NOT EXISTS (SELECT 1 FROM supplier_release_duplicates d 
                              WHERE d.release_guid = s.release_guid 
                                AND d.insert_date = lv_load_date)) s
         ON (t.release_guid = s.release_guid)
       WHEN MATCHED THEN 
     UPDATE SET t.client_name = s.client_name,
                t.client_guid = s.client_guid,           -- get rid of this?
                t.legacy_source_vms = pi_legacy_source,  -- get rid of this?
                t.supplier_guid = s.supplier_guid,       -- get rid of this?
                t.supplier_name = s.supplier_name,
                t.release_date = s.release_date,
                t.release_tier = s.release_tier,
                t.requisition_guid = s.requisition_guid,   -- get rid of this?
                t.requisition_id = s.requisition_id,       -- get rid of this?
                t.requisition_create_date = s.requisition_create_date,
                t.requisition_currency = s.requisition_currency,
                t.requisition_title = s.requisition_title,
                t.requisition_industry = s.requisition_industry,
                t.requisition_country = s.requisition_country,
                t.requisition_state = s.requisition_state,
                t.requisition_city = s.requisition_city,
                t.requisition_positions = s.requisition_positions,
                t.requisition_rate = s.requisition_rate,
                t.database_name = s.database_name,
                t.last_modified_date = SYSDATE
       WHEN NOT MATCHED THEN 
     INSERT (release_guid,
             client_guid,
             legacy_source_vms,
             client_name,
             supplier_guid,
             supplier_name,
             release_date,
             release_tier,
             requisition_guid,
             requisition_id,
             requisition_create_date,
             requisition_currency,
             requisition_title,
             requisition_industry,
             requisition_country,
             requisition_state,
             requisition_city,
             requisition_positions,
             requisition_rate,
             database_name,
             last_modified_date) 
     VALUES (s.release_guid,
             s.client_guid,
             pi_legacy_source,
             s.client_name,
             s.supplier_guid,
             s.supplier_name,
             s.release_date,
             s.release_tier,
             s.requisition_guid,
             s.requisition_id,
             s.requisition_create_date,
             s.requisition_currency,
             s.requisition_title,
             s.requisition_industry,
             s.requisition_country,
             s.requisition_state,
             s.requisition_city,
             s.requisition_positions,
             s.requisition_rate,
             s.database_name,
             SYSDATE);

      lv_release_rowcount := SQL%ROWCOUNT;
      logger_pkg.debug('merge into supplier_release - complete', TRUE);
    
      logger_pkg.debug('merge into supplier_submission');
      MERGE INTO supplier_submission t
      USING (SELECT submission_guid,
				submission_date,
				release_guid,
				candidate_name,
				submitted_bill_rate,
				offer_made_date,
				offer_accepted_date,
				offer_rejected_date,
				offer_accepted_rate,
				interview_requested_date,
				interview_scheduled_date,
				interview_date,
				avg_interview_rating,
				assignment_id,
				assignment_status_id,
				assignment_status,
				assignment_start_date,
				assignment_pay_rate,
				assignment_bill_rate,
				assignment_unfav_term_date,
				assignment_end_date,
				assignment_end_type
			 FROM supplier_submission_gtt s 
      WHERE NOT EXISTS (SELECT 1 FROM supplier_release_duplicates d 
                         WHERE d.release_guid = s.release_guid 
                           AND d.insert_date = lv_load_date)) s
         ON (t.submission_guid = s.submission_guid)
       WHEN MATCHED THEN 
     UPDATE SET t.submission_date = s.submission_date,
                t.release_guid = s.release_guid,
                t.candidate_name = s.candidate_name,
                t.submitted_bill_rate = s.submitted_bill_rate,
                t.offer_made_date = s.offer_made_date,
                t.offer_accepted_date = s.offer_accepted_date,
                t.offer_rejected_date = s.offer_rejected_date,
                t.offer_accepted_rate = s.offer_accepted_rate,
                t.interview_requested_date = s.interview_requested_date,
                t.interview_scheduled_date = s.interview_scheduled_date,
                t.interview_date = s.interview_date,
                t.avg_interview_rating = s.avg_interview_rating,
                t.assignment_id = s.assignment_id,
                t.assignment_status_id = s.assignment_status_id,
                t.assignment_status = s.assignment_status,
                t.assignment_start_date = s.assignment_start_date,
                t.assignment_pay_rate = s.assignment_pay_rate,
                t.assignment_bill_rate = s.assignment_bill_rate,
                t.assignment_unfav_term_date = s.assignment_unfav_term_date,
                t.assignment_end_date = s.assignment_end_date,
                t.assignment_end_type = s.assignment_end_type,
                t.last_modified_date = SYSDATE
       WHEN NOT MATCHED THEN 
     INSERT (submission_guid,
             submission_date,
             release_guid,
             candidate_name,
             submitted_bill_rate,
             offer_made_date,
             offer_accepted_date,
             offer_rejected_date,
             offer_accepted_rate,
             interview_requested_date,
             interview_scheduled_date,
             interview_date,
             avg_interview_rating,
             assignment_id,
             assignment_status_id,
             assignment_status,
             assignment_start_date,
             assignment_pay_rate,
             assignment_bill_rate,
             assignment_unfav_term_date,
             assignment_end_date,
             assignment_end_type,
             last_modified_date)
     VALUES (s.submission_guid,
             s.submission_date,
             s.release_guid,
             s.candidate_name,
             s.submitted_bill_rate,
             s.offer_made_date,
             s.offer_accepted_date,
             s.offer_rejected_date,
             s.offer_accepted_rate,
             s.interview_requested_date,
             s.interview_scheduled_date,
             s.interview_date,
             s.avg_interview_rating,
             s.assignment_id,
             s.assignment_status_id,
             s.assignment_status,
             s.assignment_start_date,
             s.assignment_pay_rate,
             s.assignment_bill_rate,
             s.assignment_unfav_term_date,
             s.assignment_end_date,
             s.assignment_end_type,
             SYSDATE);

      lv_candidate_rowcount := SQL%Rowcount;
      logger_pkg.debug('merge into supplier_submission - complete', TRUE);
    
      update_history_row (pi_load_id => lv_history_table_pk,
                          pi_load_status => 'completed',
                          pi_error_message => NULL,
                          pi_merged_rows_parent_table => lv_release_rowcount,
                          pi_merged_rows_child_table => lv_candidate_rowcount,
                          pi_merged_rows_visibility_tab => lv_visibility_rowcount);

      logger_pkg.info('SSC load from ' || pi_legacy_source || '  complete.');

      /* Commit work done up to this point.  Errors raised after this point will indicate that the data load did complete.  */
      COMMIT;
    
      /* Now do the "administrative work" - copy settings for any new clients and refresh MVs.  */
      BEGIN
	    logger_pkg.info('copy client default metrics');

        FOR j IN (SELECT DISTINCT log_in_client_guid
                    FROM client_visibility_list
                   MINUS
                  SELECT client_guid AS log_in_client_guid
                    FROM client_metric_coefficient) LOOP
                
          client_metric_settings_util.copy_defaults_to_client ( pi_client_guid  => j.log_in_client_guid,
                                                                pi_session_guid => lv_bulk_session_guid,
                                                                pi_request_guid => sys_guid() );    
    
        END LOOP;
    
        COMMIT;
    
        logger_pkg.info('copy client default metrics - complete', TRUE);    
      EXCEPTION
	    WHEN OTHERS THEN
          lv_error_code := SQLCODE;
          lv_error_message := SQLERRM; 		
		  RAISE e_copy_client_defaults;
      END;
    
 --     BEGIN      
 --       logger_pkg.info('refresh materialized view for '||pi_legacy_source);
	
 --       CASE pi_legacy_source
 --         WHEN 'IQN'     THEN dbms_mview.refresh('RELEASE_SUBMISSION_IQN_MV','C', atomic_refresh => false);
 --         WHEN 'Beeline' THEN dbms_mview.refresh('RELEASE_SUBMISSION_BEELINE_MV','C', atomic_refresh => false);
 --         ELSE NULL;
 --       END CASE;	

 --       logger_pkg.info('materialized view refresh complete for '||pi_legacy_source, TRUE);	
 --     EXCEPTION
 --       WHEN OTHERS THEN
 --         lv_error_code := SQLCODE;
 --         lv_error_message := SQLERRM; 
 --         RAISE e_mv_refresh;
 --     END;	
		
  	ELSE 
      /* No data in temp tables.  This is rare but not an error. 
         Log message, but do not fail. */
      logger_pkg.warn('No data in temp tables to load');
    END IF;  
    
  EXCEPTION
    WHEN e_copy_client_defaults THEN 
      ROLLBACK;	
      update_history_row (pi_load_id => lv_history_table_pk,
                          pi_load_status => 'completed',
                          pi_error_message => 'Copy client defaults error: '||lv_error_message,
                          pi_merged_rows_parent_table => lv_release_rowcount,
                          pi_merged_rows_child_table => lv_candidate_rowcount,
                          pi_merged_rows_visibility_tab => lv_visibility_rowcount);                            
      logger_pkg.error(pi_transaction_result => 'ROLLBACK',
                       pi_error_code => lv_error_code,
                       pi_message    => 'Copy client defaults for ' || pi_legacy_source || ' failed. ' || lv_error_message, 
                       pi_update_log => TRUE);   
                       
    WHEN e_mv_refresh THEN    
      update_history_row (pi_load_id => lv_history_table_pk,
                          pi_load_status => 'completed',
                          pi_error_message => 'MV error: '||lv_error_message,
                          pi_merged_rows_parent_table => lv_release_rowcount,
                          pi_merged_rows_child_table => lv_candidate_rowcount,
                          pi_merged_rows_visibility_tab => lv_visibility_rowcount);                            
      logger_pkg.error(pi_transaction_result => 'COMMIT',
                       pi_error_code => lv_error_code,
                       pi_message    => 'SSC materialized view refresh load for ' || pi_legacy_source || ' failed. ' || lv_error_message, 
                       pi_update_log => TRUE);  
                       
    WHEN others THEN
      lv_error_code := SQLCODE;
      lv_error_message := SQLERRM;
      
      /* An error occured in the loading of data into one of the three tables.  
         Rollback any data which was merged, then record the failure in the log table and the history table. */
      ROLLBACK;
      update_history_row (pi_load_id => lv_history_table_pk,
                          pi_load_status => 'failed',
                          pi_error_message => lv_error_message,
                          pi_merged_rows_parent_table => NULL,
                          pi_merged_rows_child_table => NULL,
                          pi_merged_rows_visibility_tab => NULL);
      logger_pkg.error(pi_message => 'SSC load from ' || pi_legacy_source || 
                                     ' failed. ' || lv_error_message,
                       pi_transaction_result => 'ROLLBACK',
                       pi_error_code => lv_error_code);
      RAISE;

  END move_data_to_perm_tables;  

END supplier_data_utility;
/
