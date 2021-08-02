/*******************************************************************************
SCRIPT NAME         lego_sow_services_rate_table_rates.sql 
 
LEGO OBJECT NAME    LEGO_SOW_SERVICE_RATETBL_RATES
 
CREATED             08/29/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

JIRA STORY          IQN-33506

***************************MODIFICATION HISTORY ********************************

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_sow_services_rate_table_rates.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_SOW_SERVICE_RATETBL_RATES'; 

  v_clob CLOB :=
q'{ SELECT rtc.rate_table_continuity_id,
           rte.rate_table_edition_id,          
           sr.service_rate_id,       
           s.service_id,
           DECODE(rtc.is_resource_type,1,'Resource Rate Table','Standard Rate Table') services_rate_table_type,
           rte.name               AS rate_table_name,          
           s.identifier           AS service_name,
           NVL(sr.effective_from, TO_DATE('01/01/1900','MM/DD/YYYY')) AS effective_from,
           NVL(sr.effective_to, TO_DATE('12/31/2099','MM/DD/YYYY')) AS effective_to,
           sext.description       AS service_expenditure_type,       
           sr.is_negotiable, 
           sr.lower_rate          AS lower_service_rate, 
           sr.upper_rate          AS upper_service_rate, 
           DECODE(sr.rate_type,1,'Flat',2,'Cost Plus (%)',3,'Range') AS rate_table_rate_type, 
           sr.fee_classification,
           sr.job_template_fk AS job_template_id,
           CASE mu.identifier
             WHEN 1 THEN 'Acres'
             WHEN 2 THEN 'Daily'
             WHEN 3 THEN 'Each'
             WHEN 4 THEN 'Feet'
             WHEN 5 THEN 'Hourly'
             WHEN 6 THEN 'Kilometers'
             WHEN 7 THEN 'Meters'
             WHEN 8 THEN 'Miles'
             WHEN 9 THEN 'Monthly'
             WHEN 10 THEN 'Square Feet'
             WHEN 11 THEN 'Square Yards'
             WHEN 12 THEN 'Tons'
             WHEN 13 THEN 'Yearly'
             WHEN 14 THEN 'Weekly'
             WHEN 15 THEN 'Bi-Weekly'
             ELSE lte.text1           
           END AS rate_unit_type
       FROM rate_table_continuity@db_link_name AS OF SCN source_db_SCN rtc,
            rate_table_edition@db_link_name AS OF SCN source_db_SCN rte,
            rate_table_edition_srv_rate_x@db_link_name AS OF SCN source_db_SCN x,
            service_rate@db_link_name AS OF SCN source_db_SCN sr,
            service@db_link_name AS OF SCN source_db_SCN s,
            measurement_unit@db_link_name AS OF SCN source_db_SCN mu,
            localizable_text_entry@db_link_name AS OF SCN source_db_SCN lte,
            service_expenditure_type@db_link_name AS OF SCN source_db_SCN sext   
     WHERE rtc.rate_table_continuity_id = rte.rate_table_continuity_fk
       AND rte.rate_table_edition_id = x.rate_table_edition_fk
       AND x.service_rate_fk = sr.service_rate_id
       AND sr.service_fk = s.service_id(+)
       AND s.service_expenditure_type_fk = sext.identifier(+)
       AND sr.measurement_unit_fk = mu.identifier(+)
       AND mu.description_fk = lte.localizable_text_fk
       AND lte.locale_preference = 0}';

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

