/*******************************************************************************
SCRIPT NAME         lego_person.sql 
 
LEGO OBJECT NAME    LEGO_PERSON
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Derek Reiner

***************************MODIFICATION HISTORY ********************************

01/27/2016 pmuller               modifications for DB links, multiple sources, and remote SCN
03/07/2016 jpullifrone           removed address, email and phone informatoin
08/15/2016 jpullifrone IQN-34018 removed parallel hint
04/30/2018 pmuller     IQN-39946 replaced complex logic to get DISPLAY_NAME with the FO virtual column.

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_person.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_PERSON'; 

  v_clob CLOB :=
       q'{WITH dnr_candidates
    AS (SELECT DISTINCT c.candidate_id,
                           bf.track_res_over_suppliers,
                           c.fed_id,
                           c.fed_id_type_fk
             FROM candidate@db_link_name                  AS OF SCN source_db_SCN c,
                  buyer_firm@db_link_name                 AS OF SCN source_db_SCN bf,
                  assignment_continuity@db_link_name      AS OF SCN source_db_SCN ac,
                  firm_role@db_link_name                  AS OF SCN source_db_SCN fr,
                  business_organization@db_link_name      AS OF SCN source_db_SCN bo,
                  cand_ineligible_for_rehire@db_link_name AS OF SCN source_db_SCN cifr
            WHERE bf.firm_id         = ac.owning_buyer_firm_fk
              AND c.candidate_id     = ac.candidate_fk
              AND fr.firm_id         = ac.owning_buyer_firm_fk
              AND fr.business_org_fk = bo.business_organization_id
              AND c.candidate_id     = cifr.candidate_fk
              AND bo.enterprise_fk   = cifr.enterprise_fk),
       user_names_and_domains
    AS (SELECT iu.person_fk AS user_id, 
               iu.user_name, 
               CASE 
                 WHEN iu.last_login_time >= add_months(sysdate, -3) THEN 1
                 WHEN iu.last_login_time <  add_months(sysdate, -3) THEN 0
                 ELSE NULL
               END AS user_three_months_login_flag,
               und.domain_name
          FROM iq_user@db_link_name           AS OF SCN source_db_SCN iu,
               user_name_domain@db_link_name  AS OF SCN source_db_SCN und
         WHERE iu.user_name_domain_fk = und.user_name_domain_id)
SELECT  
          DISTINCT NVL (p.business_organization_fk, -1) bus_org_id,  -- ToDo : get rid of this DISTINCT
          p.person_id,
          c.candidate_id,
          u.user_name,
          u.domain_name,
          u.user_three_months_login_flag,  
          CASE 
            WHEN INSTR (p.last_name, '&#') > 0 THEN CAST (REGEXP_REPLACE (p.last_name, '([&#[:digit:]]*)+;', ('\1')) AS VARCHAR2 (100)) 
            ELSE CAST (p.last_name AS VARCHAR2 (100)) 
          END AS last_name,
          CASE 
            WHEN INSTR (p.first_name, '&#') > 0 THEN CAST (REGEXP_REPLACE (p.first_name, '([&#[:digit:]]*)+;', ('\1')) AS VARCHAR2 (100)) 
            ELSE CAST (p.first_name AS VARCHAR2 (100)) 
          END AS first_name,
          p.middle_name,
          p.display_name,
          p.title,
          contact_info_fk     AS contact_info_id,
          p.udf_collection_fk AS udf_collection_id,
          c.udf_collection_fk AS candidate_udf_collection_id,
          CAST (CASE WHEN dnr.TRACK_RES_OVER_SUPPLIERS = 0 AND c.candidate_id = dnr.candidate_id 
                       THEN 'Y' 
                     WHEN dnr.TRACK_RES_OVER_SUPPLIERS = 1 AND c.candidate_id = dnr.candidate_id AND NVL (c.fed_id, 'x') = NVL (dnr.fed_id, 'x') AND NVL (c.fed_id_type_fk, -1) = NVL (dnr.fed_id_type_fk, -1) 
                       THEN 'Y' 
                     ELSE 'N' END AS CHAR) AS do_not_rehire_flag
     FROM person@db_link_name    AS OF SCN source_db_SCN p,
          candidate@db_link_name AS OF SCN source_db_SCN c,
          user_names_and_domains u,
          dnr_candidates dnr
    WHERE p.person_id    = c.person_fk(+)
      AND p.person_id    = u.user_id(+)
      AND c.candidate_id = dnr.candidate_id(+)  
 ORDER BY bus_org_id, person_id}';

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

