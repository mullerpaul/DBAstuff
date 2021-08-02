/*******************************************************************************
SCRIPT NAME         lego_locale_pref_score.sql 
 
LEGO OBJECT NAME    LEGO_LOCALE_PREF_SCORE
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************

 
   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_locale_pref_score.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_LOCALE_PREF_SCORE'; 

  v_clob CLOB :=
      q'{  WITH locales AS                   -- Assuming we can get all valid locale preferences
        (SELECT DISTINCT locale_preference   -- from the localizable_text_entry table.  This may
           FROM localizable_text_entry)      -- not be correct.
         SELECT a.locale_preference AS session_locale_pref, 
                b.locale_preference AS data_locale_pref, 
                iqn_locale.get_locale_preference_score(a.locale_preference, b.locale_preference) AS score
           FROM locales a,
                locales b   --Thats right - no where clause - cartesian join baby!
          ORDER BY a.locale_preference, b.locale_preference}';

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

