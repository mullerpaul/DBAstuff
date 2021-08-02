/*******************************************************************************
SCRIPT NAME         lego_cac_collection_current.sql 
 
LEGO OBJECT NAME    LEGO_CAC_COLLECTION_CURRENT
 
CREATED             08/08/2016
 
ORIGINAL AUTHOR     Paul Muller

***************************MODIFICATION HISTORY ********************************


*******************************************************************************/  

DECLARE
  v_source           VARCHAR2(64) := 'lego_cac_collection_current.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_CAC_COLLECTION_CURRENT';

  v_clob CLOB := q'{SELECT cac_id,
       'sourceNameShort' AS source_name,
       cac_collection_id,
       cac_guid,
       bus_org_id,
       cac_kind,
       start_date,
       end_date,
       SYSDATE AS load_date,
       RAWTOHEX(dbms_crypto.hash(typ => 2,  -- magic number "2" means MD5 cryptographic hash algorithm.
                                 src => to_clob(TO_CHAR(cac_id) || '^' ||
                                                TO_CHAR(cac_collection_id) || '^' || 
                                                RAWTOHEX(cac_guid) || '^' ||
                                                TO_CHAR(bus_org_id) || '^' || 
                                                TO_CHAR(cac_kind) || '^' || 
                                                TO_CHAR(start_date, 'YYYYMMDDhh24:mi:ss') || '^' ||
                                                TO_CHAR(end_date, 'YYYYMMDDhh24:mi:ss')))) AS attribute_md5_hash
  FROM lego_cac_collection@db_link_name AS OF SCN source_db_SCN}';

BEGIN

  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for ' || v_lego_object_name);
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
    logger_pkg.fatal(pi_transaction_result => NULL,
                     pi_error_code         => SQLCODE,
                     pi_message            => 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' ||
                                              SQLERRM,
                     pi_update_log         => TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;
  
END;
/

