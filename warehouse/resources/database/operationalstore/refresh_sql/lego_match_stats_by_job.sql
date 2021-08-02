/*******************************************************************************
SCRIPT NAME         lego_match_stats_by_job.sql 
 
LEGO OBJECT NAME    LEGO_MATCH_STATS_BY_JOB
 
CREATED             8/13/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

08/13/2016 - J.Pullifrone - IQN-32684 Initial
05/24/2017 - J.Pullifrone - IQN-37693 Added confirmed interview dates and avg/med 
                                      pay rates.
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_match_stats_by_job.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MATCH_STATS_BY_JOB'; 

  v_clob CLOB :=            
   q'{select match.buyer_org_id,
             jobopp.job_id,
             jobopp.suppliers_available_to_submit,
             match.suppliers_submitted,
             match.candidates_submitted,
             match.hiring_mgr_interested,
             match.hiring_mgr_declined,
             match.hiring_mgr_not_interested,
             match.candidates_offered_position,
             match.candidates_failed_screening,
             match.candidates_passed_screening,
             match.candidates_declined,
             match.candidates_not_interested,
             match.scheduled_phone_interviews,
             match.scheduled_inperson_interviews,
             match.scheduled_virtual_interviews,
             match.canceled_phone_interviews,
             match.canceled_inperson_interviews,
             match.canceled_virtual_interviews,
             match.avg_bill_rate,
             match.med_bill_rate       
       FROM (SELECT job_id,
                    COUNT(*) AS suppliers_available_to_submit
               FROM job_opportunity_sourceNameShort
              GROUP BY job_id) jobopp,
            (SELECT m.buyer_org_id, 
                    m.job_id,
                    COUNT(DISTINCT m.supplier_org_id) AS suppliers_submitted,
                    COUNT(DISTINCT m.candidate_id) AS candidates_submitted,                         
                    COUNT(CASE when m.interested_in_cand IS NOT NULL THEN 1 ELSE NULL END) AS hiring_mgr_interested,
                    COUNT(CASE when m.declined_cand IS NOT NULL THEN 1 ELSE NULL END) AS hiring_mgr_declined,
                    COUNT(CASE when m.not_interested_in_cand IS NOT NULL THEN 1 ELSE NULL END) AS hiring_mgr_not_interested,             
                    COUNT(CASE when m.cand_offered_position IS NOT NULL THEN 1 ELSE NULL END) AS candidates_offered_position,             
                    COUNT(CASE when m.cand_failed_screening IS NOT NULL THEN 1 ELSE NULL END) AS candidates_failed_screening,
                    COUNT(CASE when m.cand_passed_screening IS NOT NULL THEN 1 ELSE NULL END) AS candidates_passed_screening,
                    COUNT(CASE when m.declined_job IS NOT NULL THEN 1 ELSE NULL END) AS candidates_declined,
                    COUNT(CASE when m.not_interested_in_job IS NOT NULL THEN 1 ELSE NULL END) AS candidates_not_interested,
                    COUNT(CASE when i.interview_scheduled_phone IS NOT NULL THEN 1 ELSE NULL END) AS scheduled_phone_interviews,
                    COUNT(CASE when i.interview_scheduled_in_person IS NOT NULL THEN 1 ELSE NULL END) AS scheduled_inperson_interviews,
                    COUNT(CASE when i.interview_scheduled_virtual IS NOT NULL THEN 1 ELSE NULL END) AS scheduled_virtual_interviews,  
                    COUNT(CASE when i.interview_canceled_phone IS NOT NULL THEN 1 ELSE NULL END) AS canceled_phone_interviews,
                    COUNT(CASE when i.interview_canceled_in_person IS NOT NULL THEN 1 ELSE NULL END) AS canceled_inperson_interviews,
                    COUNT(CASE when i.interview_canceled_virtual IS NOT NULL THEN 1 ELSE NULL END) AS canceled_virtual_interviews,
                    COUNT(CASE when i.interview_date_phone IS NOT NULL THEN 1 ELSE NULL END) AS confirmed_phone_interviews,
                    COUNT(CASE when i.interview_date_in_person IS NOT NULL THEN 1 ELSE NULL END) AS confirmed_inperson_interviews,
                    COUNT(CASE when i.interview_date_virtual IS NOT NULL THEN 1 ELSE NULL END) AS confirmed_virtual_interviews,                    
                    ROUND(AVG(m.bill_rate),2) AS avg_bill_rate,
                    ROUND(MEDIAN(m.bill_rate),2) AS med_bill_rate,
                    ROUND(AVG(m.pay_rate),2) AS avg_pay_rate,
                    ROUND(MEDIAN(m.pay_rate),2) AS med_pay_rate                    
               FROM match_sourceNameShort m, interview_sourceNameShort i
              WHERE m.job_id = i.job_id(+)
              --where automatch_event is null
              GROUP BY m.buyer_org_id, 
                       m.job_id) match
      WHERE jobopp.job_id = match.job_id }';        
         
         

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

