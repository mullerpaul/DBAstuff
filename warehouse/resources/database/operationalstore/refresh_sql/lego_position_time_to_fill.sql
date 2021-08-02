/*******************************************************************************
SCRIPT NAME         lego_position_time_to_fill.sql
 
LEGO OBJECT NAME    LEGO_POSITION_TIME_TO_FILL
 
CREATED             11/10/2016
 
ORIGINAL AUTHOR     Joe Pullifrone & Paul Muller

***************************MODIFICATION HISTORY ********************************

11/09/2016 - IQN-35651  Initial version.
05/04/2017 - IQN-37567  Renamed this to from LEGO_TIME_TO_FILL to LEGO_POSITION_TIME_TO_FILL.
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_position_time_to_fill.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_POSITION_TIME_TO_FILL';

  v_clob CLOB :=            
   q'{SELECT bo.enterprise_bus_org_id AS buyer_enterprise_bus_org_id,
       bo.enterprise_name       AS buyer_enterprise_name,  
       bo.bus_org_id            AS buyer_org_id,
       bo.bus_org_name          AS buyer_name,
       j.job_id                 AS job_id,
       j.pwfe_agreement_creation_type AS procurement_wflw_agree_type,   --see: https://jira.iqn.com/confluence/display/ISR/Procurement+Workflow (1,2,3)
       j.job_requisition_type   AS job_requisition_type, --see: https://jira.iqn.com/confluence/display/ISR/Procurement+Workflow (DAILY, LTR, LTNR)
       pttf.position_pool_id,
       pttf.position_id,
       pttf.position_history_id,
       DECODE(pttf.date_offer_accepted, NULL, 0, 1) AS position_filled_flag,  
       ROUND(COALESCE(pttf.date_offer_accepted, pttf.date_eliminated, pttf.date_abandoned, SYSDATE) - pttf.date_available, 2) AS days_to_position_close,
       pttf.position_state,
       pttf.date_available      AS position_available_date,
       pttf.date_offer_accepted AS position_offer_accepted_date,
       pttf.date_eliminated     AS position_eliminated_date,
       pttf.date_abandoned      AS position_abandoned_date,   
       SYSDATE                  AS reference_date,  
       j.jc_description         AS job_category_desc,
       j.job_position_title     AS job_title,
       jr.job_currency          AS job_currency,
       jr.rate_type_new         AS job_rate_type,
       jr.rate_min              AS rate_min,
       jr.rate_max              AS rate_max,
       pl.city                  AS custom_city, 
       pl.standard_city         AS standard_city, 
       pl.state                 AS custom_state, 
       pl.standard_state        AS standard_state, 
       pl.postal_code           AS postal_code, 
       pl.country               AS custom_country, 
       pl.standard_country      AS standard_country, 
       pl.country_code          AS custom_country_code, 
       pl.standard_country_code AS standard_country_code
  FROM job_sourceNameShort j,
       job_rates_sourceNameShort jr,
       bus_org_sourceNameShort bo,
       job_work_location_sourceNameShort jwl,
       lego_place_sourceNameShort pl,
       position_history_sourceNameShort pttf 
 WHERE j.buyer_org_id = bo.bus_org_id
   AND j.job_id       = jr.job_id
   AND j.job_id       = pttf.job_id
   AND j.job_id       = jwl.job_id
   AND jwl.place_id   = pl.place_id
   AND j.job_id IN (SELECT job_id        -- limit to jobs with only 1 place location for now
                      FROM job_work_location_sourceNameShort
                     GROUP BY job_id
                    HAVING COUNT(*) = 1)
   AND j.job_state != 'Closed'           -- exclude closed jobs
   AND j.template_availability IS NULL   -- exclude job templates
   AND j.job_source_of_record = 'GUI'    -- only include job reqs created through the application, which excludes manual loads
   AND j.job_requisition_type <> 'DAILY' -- excluding DAILY fills because the same job gets filled over and over 
   AND bo.enterprise_name <> 'FOR TESTING ONLY! Buyer Org'  -- remove test data}';        

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

