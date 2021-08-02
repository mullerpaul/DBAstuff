/*******************************************************************************
SCRIPT NAME         lego_eval_proj_agreement.sql 
 
LEGO OBJECT NAME    LEGO_EVAL_PROJ_AGREEMENT
 
CREATED             3/24/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************
--Negative = 0
--Positive = 1

*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_eval_proj_agreement.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_EVAL_PROJ_AGREEMENT'; 

  v_clob CLOB :=
q'{
SELECT buyer_org_id,
       supplier_org_id,
       project_agreement_id,
       CASE 
         WHEN SUM(number_of_negative_evals) > 0 THEN 'Negative'
         WHEN SUM(number_of_negative_evals) = 0 AND SUM(number_of_positive_evals) > 0 THEN 'Positive'        
         ELSE NULL
       END AS overall_evaluation  
  FROM (       
        SELECT buyer_org_id,
               supplier_org_id,
               project_agreement_id,
               COUNT(CASE WHEN overall_rating = 0 THEN overall_rating ELSE NULL END) number_of_negative_evals,
               COUNT(CASE WHEN overall_rating = 1 THEN overall_rating ELSE NULL END) number_of_positive_evals
          FROM (
                SELECT DISTINCT 
                       bfr.business_org_fk AS buyer_org_id,
                       sfr.business_org_fk AS supplier_org_id,
                       pa.contract_id AS project_agreement_id,
                       evalu.overall_rating
                  FROM firm_role@db_link_name AS OF SCN source_db_SCN  bfr,
                       firm_role@db_link_name AS OF SCN source_db_SCN  sfr,
                       project@db_link_name AS OF SCN source_db_SCN p,
                       project_agreement@db_link_name AS OF SCN source_db_SCN pa,
                       evaluation_process@db_link_name AS OF SCN source_db_SCN  ep,
                       evaluation@db_link_name AS OF SCN source_db_SCN evalu
                 WHERE sfr.firm_id                   = pa.supply_firm_fk     
                   AND bfr.firm_id                   = p.buyer_firm_fk     
                   AND ep.evaluation_process_id      = evalu.evaluation_process_fk
                   AND p.project_id                  = pa.project_fk
                   AND pa.contract_id                = ep.evaluatable_fk
                   AND evalu.overall_rating IS NOT NULL)
          GROUP BY buyer_org_id,
                   supplier_org_id,
                   project_agreement_id)
GROUP BY buyer_org_id,
         supplier_org_id,
         project_agreement_id}';


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
