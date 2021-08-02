CREATE OR REPLACE PACKAGE BODY lego_cac_procedures AS
  /******************************************************************************
     NAME:       lego_cac_procedures
     PURPOSE:    Code to refresh LEGO_CAC_HISTORY and LEGO_CAC_COLLECTION_HISTORY.
                 
     REVISIONS:
     Jira       Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
                08/30/2016  Paul Muller      This package contains code to do selectively
                                             insert records from CDC snapshots of the CAC 
                                             legos into permanent "HISTORY" tables.
                                             Regardless of source, these load into the same 
                                             table.  However, they select from different
                                             sources based on the pi_source parameter!
     
  ******************************************************************************/

  PROCEDURE load_cac_history(pi_obj_name IN lego_refresh.object_name%TYPE,  --unused but we will be passed this value
                             pi_source   IN lego_refresh.source_name%TYPE) AS

    lv_synonym_name lego_refresh.synonym_name%TYPE;
    lv_sql          VARCHAR2(4000) := q'{INSERT INTO lego_cac_history
  (cac_guid, source_name, attribute_md5_hash, load_date,
   cac_oid, cac_value, cac_desc,
   cac_segment_1_id, cac_segment_1_value, cac_segment_1_desc,
   cac_segment_2_id, cac_segment_2_value, cac_segment_2_desc,
   cac_segment_3_id, cac_segment_3_value, cac_segment_3_desc,
   cac_segment_4_id, cac_segment_4_value, cac_segment_4_desc,
   cac_segment_5_id, cac_segment_5_value, cac_segment_5_desc)
SELECT cac_guid, source_name, attribute_md5_hash, load_date,
       cac_oid, cac_value, cac_desc,
       cac_segment_1_id, cac_segment_1_value, cac_segment_1_desc,
       cac_segment_2_id, cac_segment_2_value, cac_segment_2_desc,
       cac_segment_3_id, cac_segment_3_value, cac_segment_3_desc,
       cac_segment_4_id, cac_segment_4_value, cac_segment_4_desc,
       cac_segment_5_id, cac_segment_5_value, cac_segment_5_desc
  FROM lego_cac_synonym_name a 
 WHERE NOT EXISTS
   (SELECT NULL
      FROM lego_cac_history x
     WHERE a.source_name = x.source_name
       AND a.cac_guid    = x.cac_guid
       AND a.attribute_md5_hash = x.attribute_md5_hash)}';
  
  BEGIN
    logger_pkg.set_code_location('load_cac_history');

    /* With much regret, I'm doing this as dynamic SQL instead of static SQL.
       Its only the FROM table which is changing, and there are only two possibilities;
       but since this code will be the same everywhere - even DBs without a WF source, we'd 
       then require that all databases have empty dummy WF tables.   
       Perhaps thats not as bad as having dynamic SQL?  Anyway, I'm not super excited about
       this and might be convinced otherwise later!  */

    /* get synonym name and substitute it into the insert statement */
    lv_synonym_name := lego_tools.get_synonym_name(fi_object_name => 'LEGO_CAC_CURRENT', 
                                                   fi_source_name => pi_source);
    lv_sql := REPLACE(lv_sql, 'lego_cac_synonym_name', lv_synonym_name);
    logger_pkg.debug(lv_sql);
    
    logger_pkg.info('loading lego_cac_history for source: ' || pi_source);
    EXECUTE IMMEDIATE (lv_sql);
    COMMIT;
    logger_pkg.info('loading lego_cac_history for source: ' || pi_source || 
                    ' - complete - ' || to_char(SQL%ROWCOUNT) || ' rows loaded', TRUE);

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                       pi_error_code         => SQLCODE,
                       pi_message            => 'Cannot load LEGO_CAC_HISTORY table for source ' || pi_source || ' ' ||
                                                SQLERRM);
      RAISE;
    
  END load_cac_history;

  --------------------------------------------------------------------------------
  PROCEDURE load_cac_collection_history(pi_obj_name IN lego_refresh.object_name%TYPE,  --unused but we will be passed this value
                                        pi_source   IN lego_refresh.source_name%TYPE) AS

    lv_synonym_name lego_refresh.synonym_name%TYPE;
    lv_sql          VARCHAR2(4000) := q'{INSERT INTO lego_cac_collection_history
  (cac_id, source_name, attribute_md5_hash, load_date,
   bus_org_id, cac_guid, cac_kind,
   cac_collection_id, start_date, end_date)
SELECT cac_id, source_name, attribute_md5_hash, load_date,
       bus_org_id, cac_guid, cac_kind,
       cac_collection_id, start_date, end_date
  FROM lego_cac_collection_synonym_name a 
 WHERE NOT EXISTS
   (SELECT NULL
      FROM lego_cac_collection_history x
     WHERE a.source_name = x.source_name
       AND a.cac_guid    = x.cac_guid
       AND a.attribute_md5_hash = x.attribute_md5_hash)}';
  
  BEGIN
    logger_pkg.set_code_location('load_cac_collection_history');

    /* With much regret, I'm doing this as dynamic SQL instead of static SQL.
       Its only the FROM table which is changing, and there are only two possibilities;
       but since this code will be the same everywhere - even DBs without a WF source, we'd 
       then require that all databases have empty dummy WF tables.   
       Perhaps thats not as bad as having dynamic SQL?  Anyway, I'm not super excited about
       this and might be convinced otherwise later!  */

    /* get synonym name and substitute it into the insert statement */
    lv_synonym_name := lego_tools.get_synonym_name(fi_object_name => 'LEGO_CAC_COLLECTION_CURRENT', 
                                                   fi_source_name => pi_source);
    lv_sql := REPLACE(lv_sql, 'lego_cac_collection_synonym_name', lv_synonym_name);
    logger_pkg.debug(lv_sql);
    
    logger_pkg.info('loading lego_cac_collection_history for source: ' || pi_source);
    EXECUTE IMMEDIATE (lv_sql);
    COMMIT;
    logger_pkg.info('loading lego_cac_collection_history for source: ' || pi_source || 
                    ' - complete - ' || to_char(SQL%ROWCOUNT) || ' rows loaded', TRUE);

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      logger_pkg.fatal(pi_transaction_result => 'ROLLBACK',
                       pi_error_code         => SQLCODE,
                       pi_message            => 'Cannot load LEGO_CAC_COLLECTION_HISTORY table for source ' || pi_source || ' ' ||
                                                SQLERRM);
      RAISE;
    
  END load_cac_collection_history;

END lego_cac_procedures;
/
