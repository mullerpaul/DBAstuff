/*******************************************************************************
SCRIPT NAME         lego_cac_current.sql 
 
LEGO OBJECT NAME    LEGO_CAC_CURRENT
 
CREATED             08/10/2016
 
ORIGINAL AUTHOR     Paul Muller 

***************************MODIFICATION HISTORY ********************************


*******************************************************************************/  

DECLARE
  v_source           VARCHAR2(64) := 'lego_cac_current.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_CAC_CURRENT';

  v_clob CLOB := q'{SELECT cac_guid,
       'sourceNameShort' AS source_name,
       cac_oid,
       cac_value,
       cac_desc,
       cac_segment_1_id,
       cac_segment_1_value,
       cac_segment_1_desc,
       cac_segment_2_id,
       cac_segment_2_value,
       cac_segment_2_desc,
       cac_segment_3_id,
       cac_segment_3_value,
       cac_segment_3_desc,
       cac_segment_4_id,
       cac_segment_4_value,
       cac_segment_4_desc,
       cac_segment_5_id,
       cac_segment_5_value,
       cac_segment_5_desc,
       SYSDATE AS load_date,
       RAWTOHEX(dbms_crypto.hash(typ => 2,  -- magic number "2" means MD5 cryptographic hash algorithm.
                                 src => to_clob(cac_oid || '^' || 
                                                cac_value || '^' || 
                                                cac_desc || '^' || 
                                                TO_CHAR(cac_segment_1_id) || '^' || 
                                                cac_segment_1_value || '^' || 
                                                cac_segment_1_desc || '^' || 
                                                TO_CHAR(cac_segment_2_id) || '^' || 
                                                cac_segment_2_value || '^' || 
                                                cac_segment_2_desc || '^' || 
                                                TO_CHAR(cac_segment_3_id) || '^' || 
                                                cac_segment_3_value || '^' || 
                                                cac_segment_3_desc || '^' || 
                                                TO_CHAR(cac_segment_4_id) || '^' || 
                                                cac_segment_4_value || '^' || 
                                                cac_segment_4_desc || '^' || 
                                                TO_CHAR(cac_segment_5_id) || '^' || 
                                                cac_segment_5_value || '^' || 
                                                cac_segment_5_desc))) AS attribute_md5_hash
  FROM lego_cac@db_link_name AS OF SCN source_db_SCN}';

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

