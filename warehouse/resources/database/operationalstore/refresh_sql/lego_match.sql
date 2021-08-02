/*******************************************************************************
SCRIPT NAME         lego_match.sql 
 
LEGO OBJECT NAME    LEGO_MATCH
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

02/11/2014 - J.Pullifrone - IQN-11955 Release 12.0.1 New Column added, interview_requested_date
03/27/2014 - E.Clark      - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
07/09/2014 - J.Pullifrone - IQN-18729 - added 31035 event_name_fk for InterviewScheduledMatchEventDescription - Release 12.1.2 
07/11/2014 - J.Pullifrone - IQN-18303 - added new column, job_opportunity_id - Release 12.1.2 
03/11/2016 - jpullifrone  -           - Modifications for DB links, multiple sources, and remote SCN
07/12/2016 - jpullifrone  - IQN-33436 - replacing FO tables with legos (job_opportunity and job)
05/07/2018 - pmuller      - IQN-40125 - Added match_state_id column for convergence search
*******************************************************************************/  

--Do not have to expressly exclude job_state_id = 1 since under development jobs will have no matches
--Not sure we want to exlude job_state_id = 5 either since a job could be canceled after having been successfully filled many times
--Not sure we want to limit source_of_record to just GUI here.  Maybe down the line but here we should bring everything in.

DECLARE

  v_source           VARCHAR2(64) := 'lego_match.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_MATCH'; 

  v_clob CLOB :=            
   q'{SELECT        
       jo.buyer_org_id,
       jo.supplier_org_id,
       jo.job_id, 
       jo.job_opportunity_id,
       m.candidate_fk       AS candidate_id,
       m.match_id,
       m.match_state_fk     AS match_state_id,
       m.offer_fk           AS offer_id, --only populated with agreement type 3, traditional workflow
       m.assignment_continuity_fk, --only populated with agreement type 1 and 2, express assignments
       m.bill_rate,
       m.ot_bill_rate, 
       m.dt_bill_rate,
       m.bill_rate_unit,
       m.salary_rate,
       m.salary_rate_unit,
       m.pay_rate,
       m.ot_pay_rate,
       m.dt_pay_rate,             
       m.markup,
       m.ot_markup,
       m.dt_markup,      
       m.currency_unit_fk AS currency_unit_id,
       m.rates_negotiable,
       m.candidate_rank,
       m.creation_date,
       m.last_update_date,
       MAX(CASE ed.event_name_fk WHEN 31000 THEN  ed.timestamp ELSE NULL END) as automatch,
       MAX(CASE ed.event_name_fk WHEN 31001 THEN  ed.TIMESTAMP ELSE NULL END) AS interested_in_cand,          
       MAX(case ed.event_name_fk WHEN 31002 THEN  ed.timestamp ELSE NULL END) AS interested_in_job,
       MAX(CASE ed.event_name_fk WHEN 31003 THEN  ed.TIMESTAMP ELSE NULL END) AS not_interested_in_cand,  
       MAX(CASE ed.event_name_fk WHEN 31004 THEN  ed.TIMESTAMP ELSE NULL END) AS not_interested_in_job,
       MAX(CASE ed.event_name_fk WHEN 31008 THEN  ed.TIMESTAMP ELSE NULL END) AS declined_cand, 
       MAX(CASE ed.event_name_fk WHEN 31009 THEN  ed.TIMESTAMP ELSE NULL END) AS declined_job,
       MAX(CASE ed.event_name_fk WHEN 31010 THEN  ed.TIMESTAMP ELSE NULL END) AS direct_submit,
       MAX(CASE ed.event_name_fk WHEN 31011 THEN  ed.TIMESTAMP ELSE NULL END) AS cand_offered_position,
       MAX(CASE ed.event_name_fk WHEN 31014 THEN  ed.TIMESTAMP ELSE NULL END) AS offer_canceled, 
       MAX(case ed.event_name_fk WHEN 31017 THEN  ed.timestamp ELSE NULL END) AS draft_match,
       MAX(case ed.event_name_fk WHEN 31018 THEN  ed.timestamp ELSE NULL END) AS draft_match_removed,
       MAX(CASE ed.event_name_fk WHEN 31022 THEN  ed.TIMESTAMP ELSE NULL END) AS assignment_date_added,
       MAX(CASE ed.event_name_fk WHEN 31023 THEN  ed.TIMESTAMP ELSE NULL END) AS assignment_date_removed,
       MAX(CASE ed.event_name_fk WHEN 31026 THEN  ed.TIMESTAMP ELSE NULL END) AS job_closed,
       MAX(CASE ed.event_name_fk WHEN 31028 THEN  ed.TIMESTAMP ELSE NULL END) AS cand_inactivated,            
       MAX(CASE ed.event_name_fk WHEN 31030 THEN  ed.TIMESTAMP ELSE NULL END) AS cand_passed_screening,        
       MAX(CASE ed.event_name_fk WHEN 31031 THEN  ed.TIMESTAMP ELSE NULL END) AS cand_failed_screening,        
       MAX(CASE ed.event_name_fk WHEN 31032 THEN  ed.TIMESTAMP ELSE NULL END) AS cand_approved_date,
       MAX(CASE WHEN ed.event_name_fk IN (31015,31024) THEN ed.timestamp ELSE NULL END) AS assignment_terminated, --MatchAssignmentTerminatedEvent and TerminateWorkOrderMatchEventDescription
       MAX(CASE WHEN ed.event_name_fk IN (31013,31035) THEN ed.timestamp ELSE NULL END) AS schedule_interview, --ScheduleInterviewEventDescription and InterviewScheduledMatchEventDescription
       MAX(CASE ed.event_name_fk WHEN 31033 THEN  ed.timestamp ELSE NULL END)           AS interview_requested, 
       MAX(CASE ed.event_name_fk WHEN 31036 THEN  ed.timestamp ELSE NULL END)           AS interview_canceled 
       --jcl.constant_description AS current_match_state, placeholder for LEGO_JAVA_CONSTANT_LOOKUP       
       --pw.requisition_type, 
       --j.source_of_record,
       --CASE TO_CHAR(pw.agreement_creation_type) 
       --  WHEN '1' THEN 'Supplier-initiated Express Workflow'
       --  WHEN '2' THEN 'Buyer-initiated Express Workflow'
       --  WHEN '3' THEN 'Traditional Workflow'
       --ELSE NULL
       --END procurement_wf_type,       
  FROM match@db_link_name                   AS OF SCN source_db_SCN m,
       match_event_description@db_link_name AS OF SCN source_db_SCN med,
       event_description@db_link_name       AS OF SCN source_db_SCN ed,        
       job_opportunity_sourceNameShort                              jo
       --lego_java_constant_lookup jcl       
       --procurement_wkfl_edition pw,      
 WHERE m.match_id                    = med.match_fk(+)
   AND med.identifier                = ed.identifier
   AND ed.event_type_fk              = 31   
   AND jo.job_opportunity_id         = m.job_opportunity_fk              
   --AND j.procurement_wkfl_edition_fk = pw.procurement_wkfl_edition_id(+)   
   --AND jcl.constant_value(+)         = m.match_state_fk              
   --AND jcl.constant_type             = 'MATCH_STATE'
   --AND jcl.locale_fk                 = 'en_US'   
 GROUP BY jo.buyer_org_id,
          jo.supplier_org_id,
          jo.job_id, 
          jo.job_opportunity_id, 
          m.candidate_fk,          
          m.match_id,
          m.match_state_fk,
          m.creation_date, 
          m.offer_fk,
          m.assignment_continuity_fk,
          m.candidate_rank,
          m.bill_rate,
          m.ot_bill_rate, 
          m.dt_bill_rate,
          m.bill_rate_unit,
          m.salary_rate,
          m.salary_rate_unit,
          m.pay_rate,
          m.ot_pay_rate,
          m.dt_pay_rate,             
          m.markup,
          m.ot_markup,
          m.dt_markup,      
          m.currency_unit_fk,
          m.rates_negotiable,
          m.candidate_rank,
          m.creation_date,
          m.last_update_date
          --jcl.constant_description, 
          --pw.requisition_type, 
          --j.source_of_record,
          --CASE TO_CHAR(pw.agreement_creation_type) 
          --  WHEN '1' THEN 'Supplier-initiated Express Workflow'
          --  WHEN '2' THEN 'Buyer-initiated Express Workflow'
          --  WHEN '3' THEN 'Traditional Workflow'
          --ELSE NULL
          --END }';        
         
         

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

