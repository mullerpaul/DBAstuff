/*******************************************************************************
SCRIPT NAME         lego_currency_conv_rates.sql 
 
LEGO OBJECT NAME    LEGO_CURRENCY_CONV_RATES
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

01/27/2016 - P.Muller                 - Modifications for DB links, multiple sources, and remote SCN
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_currency_conv_rates.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_CURRENCY_CONV_RATES'; 

  v_clob CLOB :=
      q'{SELECT b.from_currency_fk   AS original_currency_id,
                b.to_currency_fk     AS converted_currency_id,
                cu.description       AS converted_currency_code,
                b.conversion_date    AS conversion_date,
                b.conversion_rate    AS conversion_rate
           FROM bo_curr_conv_gl_daily_rates@db_link_name AS OF SCN source_db_SCN b,
                currency_unit@db_link_name AS OF SCN source_db_SCN               cu
          WHERE b.to_currency_fk = cu.value      
          ORDER BY b.to_currency_fk, b.conversion_date}';

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

