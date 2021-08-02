/*******************************************************************************
SCRIPT NAME         lego_job_work_location.sql 
 
LEGO OBJECT NAME    LEGO_JOB_WORK_LOCATION
 
CREATED             2/13/2014
 
ORIGINAL AUTHOR     Erik Clark

***************************MODIFICATION HISTORY ********************************

03/27/2014 - E.Clark      - IQN-14482 - added months_in_refresh for a hard limit on data going into the lego - Release 12.0.2  
03/11/2016 - jpullifrone  -           - Modifications for DB links, multiple sources, and remote SCN

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_job_work_location.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JOB_WORK_LOCATION'; 

  v_clob CLOB :=            
   q'{SELECT j.job_id,
             fr.business_org_fk           AS buyer_org_id,
             p.value                      AS place_id
             --loc.constant_description     AS work_location,             
             --addy.address_guid
        FROM job@db_link_name               AS OF SCN source_db_SCN j,
             job_profile@db_link_name       AS OF SCN source_db_SCN jprof,
             location_place_x@db_link_name  AS OF SCN source_db_SCN lpx,
             place@db_link_name             AS OF SCN source_db_SCN p,       
             buyer_firm@db_link_name        AS OF SCN source_db_SCN bf,
             firm_role@db_link_name         AS OF SCN source_db_SCN fr
            /*(SELECT constant_value, constant_description
                FROM java_constant_lookup 
               WHERE constant_type    = 'PLACE'
                 AND UPPER(locale_fk) = UPPER('en_US')) loc,             
             (SELECT place_id, address_guid
                FROM (SELECT place_id, address_guid, RANK () OVER (PARTITION BY place_id ORDER BY contact_info_id DESC) rk
                        FROM lego_contact_address_vw
                       WHERE address_type = 'Primary')
               WHERE rk = 1) addy */
       WHERE j.job_profile_fk  = jprof.job_profile_id
         AND jprof.location_fk = lpx.location_fk
         AND lpx.place_fk      = p.value
         AND j.buyer_firm_fk   = bf.firm_id
         AND bf.firm_id        = fr.firm_id
         AND NVL(j.archived_date,SYSDATE) >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh)         
         --AND p.value           = addy.place_id(+)
         --AND p.value           = loc.constant_value}';         
         
         

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

