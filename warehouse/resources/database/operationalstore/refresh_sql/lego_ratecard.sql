/*******************************************************************************
SCRIPT NAME         lego_ratecard.sql 
 
LEGO OBJECT NAME    LEGO_RATECARD
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark      - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2
08/25/2014 - J.Pullifrone - IQN-19352 - removed join ri.version = rcr.version.  It is wrong and causing rate_card_compliance
                                        counts to be wrong in supplier scorecard - Release 12.2.0  
03/14/2016 - jpullifrone  -           - Modifications for DB links, multiple sources. No remote SCN added since these rarely change.
08/15/2016 - jpullifrone  - IQN-34018 - removed parallel hint
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_ratecard.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_RATECARD'; 

  v_clob CLOB :=
      q'{SELECT 
                rc.rate_card_id,
                ri.description              AS rate_card_identifier,
                ri.rate_card_identifier_id  AS rate_card_identifier_id,
                fr.business_org_fk          AS buyer_org_id,
                rcjtx.source_template_id,
                CASE WHEN rc.active = 1 THEN 'Y' WHEN rc.active = 0 THEN 'N' END AS active,
                CASE WHEN rc.active = 1 THEN  2  WHEN rc.active = 0 THEN  1  END AS active_id,
                CASE
                   WHEN rc.uses_factors = 1 THEN 'Y'
                   WHEN rc.uses_factors = 0 THEN 'N'
                END AS uses_factors,
                CASE
                   WHEN rc.uses_ranges = 1 THEN 'Y'
                   WHEN rc.uses_ranges = 0 THEN 'N'
                END AS uses_ranges,
                NVL(cu.value,0)             AS ratecard_currency_id,
                NVL(cu.description, 'USD')  AS ratecard_currency,
                rcr.lower_rate_set_fk AS lower_rate_set_id,
                rcr.upper_rate_set_fk AS upper_rate_set_id,
                rc.rate_unit_fk       AS rate_unit_id,
                DECODE (NVL (rc.rate_unit_fk, 0),
                        0, 'Hourly',
                        1, 'Daily',
                        2, 'Annual',
                        3, 'Monthly',
                        4, 'Weekly',
                        'N/A')
                   rate_unit,
                ---START MIN RATE
                min_ratecard_rates.min_pay_rate        AS pay_rate_min,
                min_ratecard_rates.min_ot_pay_rate     AS pay_rate_ot_min,
                min_ratecard_rates.min_ot_pay_factor   AS pay_factor_ot_min,
                min_ratecard_rates.min_dt_pay_rate     AS pay_rate_dt_min,
                min_ratecard_rates.min_dt_pay_factor   AS pay_factor_dt_min,
                min_ratecard_rates.min_bill_rate       AS bill_rate_min,
                min_ratecard_rates.min_ot_bill_rate    AS bill_rate_ot_min,
                min_ratecard_rates.min_ot_bill_factor  AS bill_factor_ot_min,
                min_ratecard_rates.min_dt_bill_rate    AS bill_rate_dt_min,
                min_ratecard_rates.min_dt_bill_factor  AS bill_factor_dt_min,
                min_ratecard_rates.min_markup          AS markup_min,
                min_ratecard_rates.min_ot_markup       AS markup_ot_min,
                min_ratecard_rates.min_dt_markup       AS markup_dt_min,
                min_custom_rates.pay_rate              AS custom_pay_rate_min,
                min_custom_rates.markup                AS custom_markup_min,
                min_custom_rates.bill_rate             AS custom_bill_rate_min,
                -------START MAX RATES
                CASE WHEN NVL(min_ratecard_rates.min_pay_rate,0) > NVL(max_ratecard_rates.max_pay_rate,0) THEN
                   min_ratecard_rates.min_pay_rate
                ELSE
                   max_ratecard_rates.max_pay_rate
                END AS pay_rate_max,
                CASE WHEN NVL(min_ratecard_rates.min_ot_pay_rate,0) > NVL(max_ratecard_rates.max_ot_pay_rate,0) THEN
                   min_ratecard_rates.min_ot_pay_rate
                ELSE
                   max_ratecard_rates.max_ot_pay_rate
                END AS pay_rate_ot_max,
                CASE WHEN NVL(min_ratecard_rates.min_ot_pay_factor,0) > NVL(max_ratecard_rates.max_ot_pay_factor,0) THEN
                   min_ratecard_rates.min_ot_pay_factor
                ELSE
                   max_ratecard_rates.max_ot_pay_factor
                END AS pay_factor_ot_max,
                CASE WHEN NVL(min_ratecard_rates.min_dt_pay_rate,0) > NVL(max_ratecard_rates.max_dt_pay_rate,0) THEN
                   NVL(min_ratecard_rates.min_dt_pay_rate,0)
                ELSE
                   max_ratecard_rates.max_dt_pay_rate
                END AS pay_rate_dt_max,
                CASE WHEN NVL(min_ratecard_rates.min_dt_pay_factor,0) > NVL(max_ratecard_rates.max_dt_pay_factor,0) THEN
                   NVL(min_ratecard_rates.min_dt_pay_factor,0)
                ELSE
                   max_ratecard_rates.max_dt_pay_factor
                END AS pay_factor_dt_max,
                CASE WHEN NVL(min_ratecard_rates.min_bill_rate,0) > NVL(max_ratecard_rates.max_bill_rate,0) THEN
                   min_ratecard_rates.min_bill_rate
                ELSE
                   max_ratecard_rates.max_bill_rate
                END AS bill_rate_max,
                CASE WHEN NVL(min_ratecard_rates.min_ot_bill_rate,0) > NVL(max_ratecard_rates.max_ot_bill_rate,0) THEN
                   min_ratecard_rates.min_ot_bill_rate
                ELSE
                   max_ratecard_rates.max_ot_bill_rate
                END AS bill_rate_ot_max,
                CASE WHEN NVL(min_ratecard_rates.min_ot_bill_factor,0) > NVL(max_ratecard_rates.max_ot_bill_factor,0) THEN
                   min_ratecard_rates.min_ot_bill_factor
                ELSE
                   max_ratecard_rates.max_ot_bill_factor
                END AS bill_factor_ot_max,
                CASE WHEN NVL(min_ratecard_rates.min_dt_bill_rate,0) > NVL(max_ratecard_rates.max_dt_bill_rate,0) THEN
                   min_ratecard_rates.min_dt_bill_rate
                ELSE
                   max_ratecard_rates.max_dt_bill_rate
                END AS bill_rate_dt_max,
                CASE WHEN NVL(min_ratecard_rates.min_dt_bill_factor,0) > NVL(max_ratecard_rates.max_dt_bill_factor,0) THEN
                   min_ratecard_rates.min_dt_bill_factor
                ELSE
                   max_ratecard_rates.max_dt_bill_factor
                END AS bill_factor_dt_max,
                CASE WHEN NVL(min_ratecard_rates.min_markup,0) > NVL(max_ratecard_rates.max_markup,0) THEN
                   min_ratecard_rates.min_markup
                ELSE
                   max_ratecard_rates.max_markup
                END AS markup_max,
                CASE WHEN NVL(min_ratecard_rates.min_ot_markup,0) > NVL(max_ratecard_rates.max_ot_markup,0) THEN
                   min_ratecard_rates.min_ot_markup
                ELSE
                   max_ratecard_rates.max_ot_markup
                END AS markup_ot_max,
                CASE WHEN NVL(min_ratecard_rates.min_dt_markup,0) > NVL(max_ratecard_rates.max_dt_markup,0) THEN
                   min_ratecard_rates.min_dt_markup
                ELSE
                   max_ratecard_rates.max_dt_markup
                END AS markup_dt_max,
                CASE WHEN NVL(min_custom_rates.pay_rate,0) > NVL(max_custom_rates.pay_rate,0) THEN
                   min_custom_rates.pay_rate
                ELSE
                   max_custom_rates.pay_rate
                END AS custom_pay_rate_max,
                CASE WHEN NVL(min_custom_rates.markup,0) > NVL(max_custom_rates.markup,0) THEN
                   min_custom_rates.markup
                ELSE
                   max_custom_rates.markup
                END AS custom_markup_max,
                CASE WHEN NVL(min_custom_rates.bill_rate,0) > NVL(max_custom_rates.bill_rate,0) THEN
                   min_custom_rates.bill_rate
                ELSE
                   max_custom_rates.bill_rate
                END AS custom_bill_rate_max
           FROM rate_card@db_link_name            rc,
                rate_card_rate@db_link_name      rcr,
                firm_role@db_link_name            fr,
                rate_card_identifier@db_link_name ri,
                currency_unit@db_link_name        cu,
                (SELECT x.rate_card_fk, j.job_id AS source_template_id
                   FROM rate_card_job_template_x@db_link_name x, 
                        job@db_link_name j
                  WHERE x.job_template_fk = j.job_id
                    AND NVL(j.archived_date,SYSDATE)  > = ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh) ) rcjtx,
                (SELECT rate_set_id,
                        rs.pay_rate       AS min_pay_rate,
                        rs.ot_pay_rate    AS min_ot_pay_rate,
                        rs.dt_pay_rate    AS min_dt_pay_rate,
                        rs.bill_rate      AS min_bill_rate,
                        rs.ot_bill_rate   AS min_ot_bill_rate,
                        rs.dt_bill_rate   AS min_dt_bill_rate,
                        rs.markup         AS min_markup,
                        rs.ot_markup      AS min_ot_markup,
                        rs.dt_markup      AS min_dt_markup,
                        rs.ot_pay_factor  AS min_ot_pay_factor,
                        rs.dt_pay_factor  AS min_dt_pay_factor,
                        rs.ot_bill_factor AS min_ot_bill_factor,
                        rs.dt_bill_factor AS min_dt_bill_factor
                  FROM rate_set@db_link_name rs) min_ratecard_rates,
                (SELECT rate_set_id,
                        rs.pay_rate       AS max_pay_rate,
                        rs.ot_pay_rate    AS max_ot_pay_rate,
                        rs.dt_pay_rate    AS max_dt_pay_rate,
                        rs.bill_rate      AS max_bill_rate,
                        rs.ot_bill_rate   AS max_ot_bill_rate,
                        rs.dt_bill_rate   AS max_dt_bill_rate,
                        rs.markup         AS max_markup,
                        rs.ot_markup      AS max_ot_markup,
                        rs.dt_markup      AS max_dt_markup,
                        rs.ot_pay_factor  AS max_ot_pay_factor,
                        rs.dt_pay_factor  AS max_dt_pay_factor,
                        rs.ot_bill_factor AS max_ot_bill_factor,
                        rs.dt_bill_factor AS max_dt_bill_factor
                  FROM rate_set@db_link_name rs) max_ratecard_rates,
                (SELECT rs.rate_set_id,
                        MIN(DECODE(rcr.rate_category_fk, 1, rcr.rate)) AS pay_rate,
                        MIN(DECODE(rcr.rate_category_fk, 2, rcr.rate)) AS markup,
                        MIN(DECODE(rcr.rate_category_fk, 3, rcr.rate)) AS bill_rate
                   FROM rate_category_rate@db_link_name rcr, 
                        rate_set@db_link_name rs
                  WHERE rs.rate_identifier_rate_set_fk = rcr.rate_identifier_rate_set_fk
                    AND rcr.rate != 0
                  GROUP BY rs.rate_set_id) min_custom_rates,
                (SELECT rs.rate_set_id,
                        MAX(DECODE(rcr.rate_category_fk, 1, rcr.rate)) AS pay_rate,
                        MAX(DECODE(rcr.rate_category_fk, 2, rcr.rate)) AS markup,
                        MAX(DECODE(rcr.rate_category_fk, 3, rcr.rate)) AS bill_rate
                   FROM rate_category_rate@db_link_name rcr, 
                        rate_set@db_link_name rs
                  WHERE rs.rate_identifier_rate_set_fk = rcr.rate_identifier_rate_set_fk
                    AND rcr.rate != 0
                  GROUP BY rs.rate_set_id) max_custom_rates
          WHERE rc.rate_card_id             = rcr.rate_card_fk
            AND rc.buyer_firm_fk            = fr.firm_id
            AND rcr.rate_card_identifier_fk = ri.rate_card_identifier_id
            AND rc.currency_unit_fk         = cu.value(+)
            AND ri.buyer_firm_fk            = rc.buyer_firm_fk            
            AND rc.rate_card_id             = rcjtx.rate_card_fk
            AND rcr.lower_rate_set_fk       = min_ratecard_rates.rate_set_id (+)
            AND rcr.upper_rate_set_fk       = max_ratecard_rates.rate_set_id (+)
            AND rcr.lower_rate_set_fk       = min_custom_rates.rate_set_id (+)
            AND rcr.upper_rate_set_fk       = max_custom_rates.rate_set_id (+)
      ORDER BY buyer_org_id, rate_card_identifier_id, source_template_id}';

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

