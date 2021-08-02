/*******************************************************************************
SCRIPT NAME         lego_job_rates.sql 
 
LEGO OBJECT NAME    LEGO_JOB_RATES
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark      - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
04/11/2014 - E.Clark      - IQN-15353 - localized RATE_TYPE and JOB_PRIORITY- Release 12.0.3
07/14/2014 - J.Pullifrone - IQN-18303 - added pwfe_agreement_creation_type - Release 12.1.2  
07/15/2014 - J.Pullifrone - IQN-18303 - added proposed_approvable_aspects_id - Release 12.1.2
01/27/2016 - P.Muller                 - modifications for DB links, multiple sources, and remote SCN
03/07/2016 - P.Muller                 - get rid of position and candidate count columns, listagg columns, CAC columns
05/05/2016 - J.Pullifrone             - separated the rate data from the main job data for performance 
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_job_rates.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JOB_RATES'; 

  v_clob CLOB := q'{
WITH rate_priority_2 AS
        (SELECT j.job_id, MIN(lrsl.bill_rate) AS rate_min, MAX(lrsu.bill_rate) AS rate_max
          FROM job@db_link_name AS OF SCN source_db_SCN j,
               rate_set@db_link_name AS OF SCN source_db_SCN lrsl,
               rate_set@db_link_name AS OF SCN source_db_SCN lrsu,
               rate_card_job_template_x@db_link_name AS OF SCN source_db_SCN x,
               rate_card_rate@db_link_name AS OF SCN source_db_SCN rcr
         WHERE x.job_template_fk              = j.source_template_id
           AND x.rate_card_fk                 = rcr.rate_card_fk
           AND lrsl.rate_set_id(+)            = rcr.lower_rate_set_fk
           AND lrsu.rate_set_id(+)            = rcr.upper_rate_set_fk
           AND j.rate_card_identifier_fk      = rcr.rate_card_identifier_fk
           AND NVL(j.archived_date,SYSDATE)  >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)           
         GROUP BY j.job_id),
     --RATE MIN, RATE_MAX for j.is_fast_path =1         
     rate_priority_1 AS 
          (SELECT *
             FROM 
                 (SELECT j.job_id,
                         lrsl.bill_rate AS rate_min,
                         lrsu.bill_rate AS rate_max,
                         lrsl.ot_bill_rate,
                         lrsl.dt_bill_rate,
                         lrsl.pay_rate,
                         lrsl.ot_pay_rate,
                         lrsl.dt_pay_rate,
                         lrsl.markup,
                         lrsl.ot_markup,
                         lrsl.dt_markup,
                         COUNT(j.job_id) OVER (PARTITION BY j.job_id) AS cnt
                    FROM job@db_link_name AS OF SCN source_db_SCN           j,
                         job_submittee@db_link_name AS OF SCN source_db_SCN js,
                         historical_job_rate_cards_x@db_link_name AS OF SCN source_db_SCN x,
                         job_rate_card@db_link_name AS OF SCN source_db_SCN jrc,
                         rate_set@db_link_name AS OF SCN source_db_SCN      lrsl,
                         rate_set@db_link_name AS OF SCN source_db_SCN      lrsu
                   WHERE j.job_submission_fk            = js.job_submission_fk
                     AND NVL(j.archived_date,SYSDATE)  >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
                     AND js.historical_job_rate_card_fk = x.historical_job_rate_card_fk
                     AND x.job_rate_card_fk             = jrc.identifier
                     AND lrsl.rate_set_id(+)            = jrc.lower_rate_set_fk
                     AND lrsu.rate_set_id(+)            = jrc.upper_rate_set_fk
                    )
            WHERE cnt = 1)           
SELECT j.job_id,
       bfr.business_org_fk           AS buyer_org_id,
       CASE WHEN j.is_fast_path = 0 THEN r.lower_bound
       ELSE
          --NVL mimics the no_data_found exception in the function that was replaced
          NVL(rate_priority_1.rate_min, rate_priority_2.rate_min) --rate_min_priority_2.rate_min) -- logic from RPT_UTIL_JOB.get_exp_min_rate_job_itself
       END                          AS rate_min,
       CASE WHEN j.is_fast_path = 0 THEN r.upper_bound
       ELSE
          --NVL mimics the no_data_found exception in the function that was replaced
          NVL(rate_priority_1.rate_max, rate_priority_2.rate_max) --rate_max_priority_2.rate_max) -- logic from RPT_UTIL_JOB.get_exp_max_rate_job_itself
       END                          AS rate_max,
       CASE WHEN j.is_fast_path = 0 THEN rs.bill_rate
          ELSE rate_priority_1.rate_min
       END AS bill_rate,
       CASE WHEN j.is_fast_path = 0 THEN rs.ot_bill_rate
          ELSE rate_priority_1.ot_bill_rate
       END AS bill_rate_ot,
       CASE WHEN j.is_fast_path = 0 THEN rs.dt_bill_rate
          ELSE rate_priority_1.dt_bill_rate
       END AS bill_rate_dt,
       CASE WHEN j.is_fast_path = 0 THEN rs.pay_rate
          ELSE rate_priority_1.pay_rate
       END AS pay_rate,
       CASE WHEN j.is_fast_path = 0 THEN rs.ot_pay_rate
          ELSE rate_priority_1.ot_pay_rate
       END AS pay_rate_ot,
       CASE WHEN j.is_fast_path = 0 THEN rs.dt_pay_rate
          ELSE rate_priority_1.dt_pay_rate
       END AS pay_rate_dt,
       CASE WHEN j.is_fast_path = 0 THEN rs.markup
          ELSE rate_priority_1.markup
       END AS markup,
       CASE WHEN j.is_fast_path = 0 THEN rs.ot_markup
          ELSE rate_priority_1.ot_markup
       END AS markup_ot,
       CASE WHEN j.is_fast_path = 0 THEN rs.dt_markup
          ELSE rate_priority_1.dt_markup
       END AS markup_dt,
       r.rate_unit_fk               AS rate_type_id,
       CASE r.rate_unit_fk
          WHEN 0 THEN 'Hourly'
          WHEN 1 THEN 'Daily'
          WHEN 2 THEN 'Annual'
          WHEN 3 THEN 'Monthly'
          WHEN 4 THEN 'Weekly'
          ELSE NULL
       END                          AS rate_type_new,   
       ru.description               AS rate_type,
       j.rate_card_identifier_fk    AS rate_card_identifier_id,
       j.source_template_id,
       cu.value                     AS job_currency_id,
       cu.description               AS job_currency
  FROM job_employment_terms@db_link_name AS OF SCN source_db_SCN  jet,
       job_contr_empl_terms@db_link_name AS OF SCN source_db_SCN  jcet,  
       firm_role@db_link_name AS OF SCN source_db_SCN             bfr,
       compensation@db_link_name AS OF SCN source_db_SCN          comp,
       rate@db_link_name AS OF SCN source_db_SCN                  r,
       rate_set@db_link_name AS OF SCN source_db_SCN              rs,
       rate_unit@db_link_name AS OF SCN source_db_SCN             ru,  
       job@db_link_name AS OF SCN source_db_SCN                   j,
       currency_unit@db_link_name AS OF SCN source_db_SCN         cu,            
       rate_priority_1,
       rate_priority_2 
 WHERE NVL(j.archived_date,SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)
   AND j.buyer_firm_fk                  = bfr.firm_id
   AND j.job_employment_terms_fk        = jet.job_employment_terms_id
   AND jet.job_employment_terms_id      = jcet.job_employment_terms_fk   
   AND jcet.compensation_fk             = comp.compensation_id(+)
   AND comp.compensation_id             = r.compensation_fk(+)
   AND comp.selected_rate               = r.rate_unit_fk(+)
   AND r.rate_unit_fk                   = ru.value(+)
   AND r.currency_unit_fk               = cu.value
   AND j.expanded_contract_rate_set_fk  = rs.rate_set_id(+)
   --RATE_MIN, RATE_MAX for j.is_fast_path = 1
   AND j.job_id                         = rate_priority_1.job_id(+)
   AND j.job_id                         = rate_priority_2.job_id(+)}';

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

