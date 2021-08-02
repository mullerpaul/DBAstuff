/*******************************************************************************
SCRIPT NAME         lego_place.sql 
 
LEGO OBJECT NAME    LEGO_PLACE
SOURCE NAME         USPROD
 
CREATED             2/04/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

   
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_place.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_PLACE'; 
  

  v_clob CLOB :=
  q'{SELECT p.VALUE place_id,
            p.TYPE place_type,
            sp.VALUE standard_place_id,
            sp.description standard_place_desc,
            p.business_org_fk buyer_org_id,
            p.line1,
            p.line2,
            p.line3,
            p.line4,
            NVL (TRIM (TRANSLATE (p.city, ',-', '  ')), TRIM (TRANSLATE (sp.city, ',-', '  '))) city,
            p.county,
            NVL (p.state, sp.state) state,
            NVL (c.VALUE, sc.VALUE) country_id,
            NVL (c.description, sc.description) country,
            NVL (c.country_code, sc.country_code) country_code,
            p.postal_code,
            p.attribute1,
            p.attribute2,
            p.attribute3,
            p.attribute4,
            p.attribute5,
            TRIM (TRANSLATE (sp.city, ',-', '  ')) standard_city,
            sp.state standard_state,
            sc.description standard_country,
            sc.country_code standard_country_code
       FROM place@db_link_name     p, 
	        country@db_link_name   c, 
  		    place@db_link_name    sp, 
		    country@db_link_name  sc
      WHERE p.country = c.VALUE(+)
        AND p.standard_place_fk = sp.VALUE(+)
        AND sp.country = sc.VALUE(+)
	  ORDER BY p.business_org_fk, p.VALUE}';

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

