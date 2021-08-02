/*******************************************************************************
SCRIPT NAME         lego_interview.sql 
 
LEGO OBJECT NAME    LEGO_INTERVIEW
 
CREATED             7/12/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

JIRA STORY          IQN-33436

***************************MODIFICATION HISTORY ********************************

05/24/2017 - J.Pullifrone - IQN-37693 Added confirmed interview dates timezone.
                                      Removed join to match lego and associated
                                      columns - too slow.

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_interview.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_INTERVIEW'; 

v_clob CLOB :=
q'{ 
SELECT intv.match_id,
       intv.job_id,
       --created_date is requested date - status could change so cannot use interview_status = REQUESTED
       MAX(CASE WHEN intv.interview_type = 'IN_PERSON' THEN intv.created_date END) AS interview_requested_in_person,
       MAX(CASE WHEN intv.interview_type = 'VIRTUAL'   THEN intv.created_date END) AS interview_requested_virtual,
       MAX(CASE WHEN intv.interview_type = 'PHONE'     THEN intv.created_date END) AS interview_requested_phone,
       --created_date and updated_date are equal when status is canceled but will use updated_date to differentiate from REQUESTED status
       MAX(CASE WHEN intv.interview_type = 'IN_PERSON' AND intv.interview_status = 'CANCELED'  THEN intv.updated_date END) AS interview_canceled_in_person,
       MAX(CASE WHEN intv.interview_type = 'VIRTUAL'   AND intv.interview_status = 'CANCELED'  THEN intv.updated_date END) AS interview_canceled_virtual,
       MAX(CASE WHEN intv.interview_type = 'PHONE'     AND intv.interview_status = 'CANCELED'  THEN intv.updated_date END) AS interview_canceled_phone,         
       
       MAX(CASE WHEN intv.interview_type = 'IN_PERSON' AND intv.interview_status = 'SCHEDULED' THEN intd.updated_date END) AS interview_scheduled_in_person,
       MAX(CASE WHEN intv.interview_type = 'VIRTUAL'   AND intv.interview_status = 'SCHEDULED' THEN intd.updated_date END) AS interview_scheduled_virtual,
       MAX(CASE WHEN intv.interview_type = 'PHONE'     AND intv.interview_status = 'SCHEDULED' THEN intd.updated_date END) AS interview_scheduled_phone,
       
       MAX(CASE WHEN intv.interview_type = 'IN_PERSON' AND intv.interview_status = 'SCHEDULED' THEN intd_selected.intd.start_date END) AS interview_date_in_person,
       MAX(CASE WHEN intv.interview_type = 'VIRTUAL'   AND intv.interview_status = 'SCHEDULED' THEN intd_selected.intd.start_date END) AS interview_date_virtual,
       MAX(CASE WHEN intv.interview_type = 'PHONE'     AND intv.interview_status = 'SCHEDULED' THEN intd_selected.intd.start_date END) AS interview_date_phone,
       MAX(intd_selected.timezone_id) AS date_of_interview_tz_selected
  FROM interview@db_link_name AS OF SCN source_db_SCN intv
       LEFT OUTER JOIN interview_date@db_link_name AS OF SCN source_db_SCN intd          ON (intv.id               = intd.interview_id)  --when no interview date has been selected
       LEFT OUTER JOIN interview_date@db_link_name AS OF SCN source_db_SCN intd_selected ON (intv.selected_date_id = intd_selected.id AND intv.interview_status = 'SCHEDULED')   --when interview date has been selected      
 GROUP BY intv.match_id,
          intv.job_id}';    

  BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
  
  UPDATE lego_refresh
     SET refresh_sql = v_clob
   WHERE object_name = v_lego_object_name;  
  
  COMMIT;
    
  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/
