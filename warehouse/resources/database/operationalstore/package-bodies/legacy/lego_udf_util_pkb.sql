CREATE OR REPLACE PACKAGE BODY lego_udf_util IS

/******************************************************************************
     NAME:       LEGO_UDF_UTIL
     PURPOSE:    Procedures to refresh UDF legos.
  
     Ver    Date        Author        Description
     -----  ----------  -----------   ------------------------------------
     1.0    04/29/2013  pmuller and   Created this package.
                        jpullifrone
     1.1    11/18/2013  pmuller       modified create_enum to do more work in the 
                                      base table build and less in the pivot views.
     1.2    01/27/2014  pmuller       Some new udf legos and also improvement to
                                      the enum refresh SQL.                                
     1.3    05/08/2014  pmuller       Cleaned up the logging and a few comments.

******************************************************************************/

  /* Pivot views will be created with this naming convention:
  <prefix>_<code>_<enum|noenum>_<bus_org_id>_VW  
  
  Where <prefix> is 3 chars, <code> is 7 chars max, 6 for <noenum>, and 8 max for <bus_org_id>.  
  With "VW" and the underscores, thats a total of 30! 
  This constant defines the prefix. */
  lc_viewname_prefix CONSTANT VARCHAR2(4) := 'UDF_';

  --------------------------------------------------------------------------------
  PROCEDURE get_lego_metadata(i_new_toggle_table_name IN VARCHAR2,
                              o_storage_clause   OUT lego_refresh.exadata_storage_clause%TYPE,
                              o_partition_clause OUT lego_refresh.partition_clause%TYPE)
  IS
    lv_storage_clause   lego_refresh.exadata_storage_clause%TYPE := NULL;
    lv_partition_clause lego_refresh.partition_clause%TYPE := NULL;
  BEGIN
    /* Get the storage clause and partition clause from the lego_refresh table.  By the time 
    this runs, the exadata storage clause column will be updated for exadata/non exadata.  */
    SELECT exadata_storage_clause, partition_clause
      INTO lv_storage_clause, lv_partition_clause
      FROM lego_refresh
     WHERE (refresh_object_name_1 = i_new_toggle_table_name 
            OR refresh_object_name_2 = i_new_toggle_table_name);

    o_storage_clause := lv_storage_clause;
    o_partition_clause := lv_partition_clause;
    
  EXCEPTION
    WHEN no_data_found OR too_many_rows THEN
      /*  This should never happen.  There must be incorrect data in LEGO_REFRESH. */
      logger_pkg.fatal('Found data error in LEGO_REFRESH while building ' || i_new_toggle_table_name);
      raise_application_error(-20104,'Found data error in LEGO_REFRESH while building ' || i_new_toggle_table_name);
    
  END get_lego_metadata;  

  --------------------------------------------------------------------------------
  FUNCTION most_recently_loaded_table(i_lego_name lego_refresh.object_name%TYPE)
    RETURN VARCHAR2 IS
    lv_return VARCHAR2(30) := NULL;
  BEGIN
    /* For SQL toggle, PROC toggle, and PROC toggle args legos, we can get the name of the most 
    recently loaded base table from lego_refresh_history.toggle_refreshed_table.  In most cases, 
    the lego checked should be a parent lego in the same refresh group as the current lego!!  */
    SELECT toggle_refreshed_table
      INTO lv_return
      FROM (SELECT job_runtime,
                   toggle_refreshed_table,
                   MAX(job_runtime) over() AS max_runtime
              FROM lego_refresh_history
             WHERE object_name = i_lego_name
               AND toggle_refreshed_table IS NOT NULL
               AND status IN ('released','refresh complete'))
     WHERE job_runtime = max_runtime;
  
    RETURN lv_return;

    EXCEPTION
      WHEN no_data_found
        THEN
          /*  Either we have incorrect input or we are checking for a lego that hasn't ever been  
          refreshed.  There are cases where we need to find this information for legos which have
          not yet been refreshed but have empty dummy tables.  To get an answer in those cases, we 
          look at the synonym and see if it points to a real table.  */
          BEGIN
            SELECT t.table_name
              INTO lv_return
              FROM lego_refresh lr,
                   user_synonyms s,
                   user_tables t
             WHERE lr.synonym_name = s.synonym_name
               AND s.table_name = t.table_name
               AND lr.object_name = i_lego_name;

            RETURN lv_return;  

          EXCEPTION
            WHEN no_data_found
              THEN
                /* Now we are in trouble and must fail.  */
                logger_pkg.fatal('Cannot find most recently refreshed table for ' || i_lego_name);
                raise_application_error(-20100, 'Cannot find most recently refreshed table for ' || i_lego_name); 
          END;

  END most_recently_loaded_table;
  
  --------------------------------------------------------------------------------
  PROCEDURE load_distinct_udf_collctn_ids(i_select_statement IN VARCHAR2) IS
    lv_sql      VARCHAR2(4000);
    lv_rowcount NUMBER;

    /* This variable is unused, but is included to create a dependency such that
    this package will not compile if the UDF_COLLECTION_GTT table does not exist. */
    lv_unused   lego_udf_collection_gtt.udf_collection_id%TYPE;
    
  BEGIN
    /* Take a query and use it to load lego_udf_collection_gtt with UDF collection IDs. 
    That's a temp table so we know it is empty. */
    lv_sql := 'insert /*+ append */ into lego_udf_collection_gtt (udf_collection_id) ' || i_select_statement;

    logger_pkg.debug(pi_message => 'Loading lego_udf_collection_gtt with SQL: ' || lv_sql);
    logger_pkg.debug(pi_message => 'Inserting rows...');
    EXECUTE IMMEDIATE (lv_sql);
    lv_rowcount := SQL%ROWCOUNT;

    logger_pkg.debug(pi_message    => 'Insert into lego_udf_collection_gtt complete. ' || to_char(lv_rowcount) || ' rows inserted.',
                     pi_update_log => TRUE);

  END load_distinct_udf_collctn_ids;

  --------------------------------------------------------------------------------
  PROCEDURE get_lego_join_info(i_view_name       IN VARCHAR2,
                               i_column_name     IN VARCHAR2,
                               o_base_table_name OUT VARCHAR2,
                               o_join_column     OUT VARCHAR2) IS

    lv_sql       VARCHAR2(3900);
    lv_tablename VARCHAR2(30);
  BEGIN
    /* Given a lego view name and a column name, this procedure returns a table and column 
    which will be joined to in the enume or noenum refresh SQL.  This table.column must hold 
    all of the UDF_COLLECTION_ID values which should be in the leog.  Since its going to be 
    used in a join, this list must be unique and not contain any NULLs.  In cases where the 
    UDF_COLLECTION_ID column is unique and not null in the base lego, we can jsut return
    that table.column name.  In other cases, we construct a query to load a distinct set of 
    IDs into a temp table and then use that in the join.  */
    CASE
      WHEN i_view_name = 'LEGO_ASSIGNMENT_VW' THEN
        CASE
          WHEN i_column_name = 'UDF_COLLECTION_ID' THEN
            /* This column is never null but can have dupes. */
            lv_sql := 'select distinct udf_collection_id from (' ||
                      'select udf_collection_id' || 
                      ' from ' || most_recently_loaded_table('LEGO_ASSIGNMENT_WO') ||
                      ' union all ' || 
                      'select udf_collection_id' ||
                      ' from ' || most_recently_loaded_table('LEGO_ASSIGNMENT_EA') ||
                      ' union all ' ||
                      'select udf_collection_id' ||
                      ' from ' || most_recently_loaded_table('LEGO_ASSIGNMENT_TA') ||
                      ' union all ' ||
                      'select udf_collection_id' ||
                      ' from ' || most_recently_loaded_table('LEGO_WO_AMENDMENT') || ')';

          WHEN i_column_name = 'WOV_UDF_COLLECTION_ID' THEN
            /* This column can be null and there may be dupes. */
            lv_sql := 'select wov_udf_collection_id' ||
                      '  from ' || most_recently_loaded_table('LEGO_ASSIGNMENT_WO') ||
                      ' where wov_udf_collection_id is not null' ||
                      ' union ' ||   -- using UNION instead of UNION ALL to remove duplicates
                      'select wov_udf_collection_id' ||
                      '  from ' || most_recently_loaded_table('LEGO_WO_AMENDMENT') ||
                      ' where wov_udf_collection_id is not null';

          WHEN i_column_name = 'WORKER_ED_UDF_COLLECTION_ID' THEN
            /* This column has NULLs and dupes. */
            lv_sql := 'select distinct worker_ed_udf_collection_id' ||
                      '  from (select worker_ed_udf_collection_id' || 
                              '  from ' || most_recently_loaded_table('LEGO_ASSIGNMENT_WO') ||
                              ' where worker_ed_udf_collection_id is not null' ||
                              ' union all ' || 
                              'select worker_ed_udf_collection_id' ||
                              '  from ' || most_recently_loaded_table('LEGO_ASSIGNMENT_EA') ||
                              ' where worker_ed_udf_collection_id is not null' ||
                              ' union all ' ||
                              'select worker_ed_udf_collection_id' ||
                              '  from ' || most_recently_loaded_table('LEGO_ASSIGNMENT_TA') ||
                              ' where worker_ed_udf_collection_id is not null)';
            
          ELSE
            raise_application_error(-20103, 'Unknown column name');
        END CASE;

        load_distinct_udf_collctn_ids(lv_sql);

        o_base_table_name := 'lego_udf_collection_gtt';
        o_join_column     := 'udf_collection_id';

      WHEN i_view_name = 'LEGO_BUYER_ORG_VW' THEN
        /* We want just one pair of base tables for buyer and supplier (and managing) orgs.  
        The bus_org lego has separated the UDF collection data into 2 columns in the base table.  
        Here we union those back together. */
        lv_tablename := most_recently_loaded_table('LEGO_BUS_ORG');
        lv_sql := 'SELECT buyer_udf_collection_id AS udf_collection_id' ||
                  '  FROM ' || lv_tablename ||
                  ' WHERE buyer_udf_collection_id IS NOT NULL' ||
                  ' UNION ALL ' ||  --safe to use union all as there are no dupes.
                  'SELECT supplier_udf_collection_id AS udf_collection_id' ||
                  '  FROM ' || lv_tablename ||
                  ' WHERE supplier_udf_collection_id IS NOT NULL';
        load_distinct_udf_collctn_ids(lv_sql);

        o_base_table_name := 'lego_udf_collection_gtt';
        o_join_column     := 'udf_collection_id';

      WHEN i_view_name = 'LEGO_EXPENSE_VW' THEN
        CASE
          WHEN i_column_name = 'ER_UDF_COLLECTION_ID' THEN 
            /* ER_UDF_COLLECTION_ID may contain dupes. */
            lv_sql := 'select distinct er_udf_collection_id' || 
                       ' from ' || most_recently_loaded_table('LEGO_EXPENSE') ||
                      ' where er_udf_collection_id is not null';
            load_distinct_udf_collctn_ids(lv_sql);

            o_base_table_name := 'lego_udf_collection_gtt';
            o_join_column     := 'udf_collection_id';

          WHEN i_column_name = 'ERLI_UDF_COLLECTION_ID' THEN 
            o_base_table_name := most_recently_loaded_table('LEGO_EXPENSE');
            o_join_column     := i_column_name;

          ELSE
            raise_application_error(-20103, 'Unknown column name');

        END CASE;    

      WHEN i_view_name = 'LEGO_JOB_VW' THEN
        /* We need to filter out JOB_TEMPLATE cdfs. */
        lv_sql := 'select udf_collection_id' || 
                  '  from ' || most_recently_loaded_table('LEGO_JOB') ||
                  ' where template_availability is NULL';
        load_distinct_udf_collctn_ids(lv_sql);
        
        o_base_table_name := 'lego_udf_collection_gtt';
        o_join_column     := 'udf_collection_id';

      WHEN i_view_name = 'LEGO_PAYMENT_REQUEST_VW' THEN
        IF (i_column_name = 'MI_UDF_COLLECTION_ID' OR i_column_name = 'MID_UDF_COLLECTION_ID')
          THEN
            /* Both UDF_collection columns may contain dupes and Nulls. */
            lv_sql := 'select distinct ' || i_column_name ||
                       ' from ' || most_recently_loaded_table('LEGO_PAYMENT_REQUEST') ||
                      ' where ' || i_column_name || ' is not null';
                  
            load_distinct_udf_collctn_ids(lv_sql);

            o_base_table_name := 'lego_udf_collection_gtt';
            o_join_column     := 'udf_collection_id';

          ELSE
            raise_application_error(-20103, 'Unknown column name');
        END IF;    

      /* Don't need an entry for LEGO_PERSON_CONTRACTOR since it will build the same table 
         as LEGO_PERSON.  
      WHEN i_view_name = 'LEGO_PERSON_CONTRACTOR_VW' THEN
        o_base_table_name := most_recently_loaded_table('LEGO_PERSON');
        o_join_column     := i_column_name;    */

      WHEN i_view_name = 'LEGO_PERSON_VW' THEN
        CASE  
          WHEN i_column_name = 'UDF_COLLECTION_ID' THEN
          /*  not many, but some dupes in LEGO_PERSON_VW.udf_collection_id  */
          lv_sql := 'select distinct udf_collection_id' || 
                    '  from ' || most_recently_loaded_table('LEGO_PERSON') ||
                    ' where udf_collection_id is not null';

          WHEN i_column_name = 'CANDIDATE_UDF_COLLECTION_ID' THEN
          /*  not many, but some dupes in LEGO_PERSON_VW.candidate_udf_collection_id  */
          lv_sql := 'select distinct candidate_udf_collection_id' || 
                    '  from ' || most_recently_loaded_table('LEGO_PERSON') ||
                    ' where candidate_udf_collection_id is not null';
                    
          ELSE
            raise_application_error(-20103, 'Unknown column name');

        END CASE;    
        
        load_distinct_udf_collctn_ids(lv_sql);

        o_base_table_name := 'lego_udf_collection_gtt';
        o_join_column     := 'udf_collection_id';

      WHEN i_view_name = 'LEGO_PROJECT_AGREEMENT_VW' THEN
        /*  not many, but some dupes in LEGO_PROJECT_AGREEMENT_VW  */
        lv_sql := 'select distinct pa_udf_collection_id' || 
                  '  from ' || most_recently_loaded_table('LEGO_PROJECT_AGREEMENT') ||
                  ' where pa_udf_collection_id is not null';
                  
        load_distinct_udf_collctn_ids(lv_sql);

        o_base_table_name := 'lego_udf_collection_gtt';
        o_join_column     := 'udf_collection_id';

      WHEN i_view_name = 'LEGO_PROJECT_VW' THEN
        lv_sql := 'select udf_collection_id ' ||
                  '  from ' || most_recently_loaded_table('LEGO_PROJECT') ||
                  ' where udf_collection_id is not null';
        
        load_distinct_udf_collctn_ids(lv_sql);
        
        o_base_table_name := 'lego_udf_collection_gtt';
        o_join_column     := 'udf_collection_id';

      WHEN i_view_name = 'LEGO_REQUEST_TO_BUY_VW' THEN
        o_base_table_name := most_recently_loaded_table('LEGO_REQUEST_TO_BUY');
        o_join_column     := i_column_name;

      WHEN i_view_name = 'LEGO_RFX_VW' THEN
        /* UDF_COLLECTION_ID may contain dupes. */
        lv_sql := 'select distinct udf_collection_id' || 
                  '  from ' || most_recently_loaded_table('LEGO_RFX') ||
                  ' where udf_collection_id is not null';
                  
        load_distinct_udf_collctn_ids(lv_sql);

        o_base_table_name := 'lego_udf_collection_gtt';
        o_join_column     := 'udf_collection_id';

      /* Don't need an entry for LEGO_SUPPLIER_ORG_VW since we use the same base table and pivots
         as LEGO_BUYER_ORG_VW.  
      WHEN i_view_name = 'LEGO_SUPPLIER_ORG_VW' THEN
        o_base_table_name := most_recently_loaded_table('LEGO_BUS_ORG');
        o_join_column     := i_column_name;   */

      WHEN i_view_name = 'LEGO_TIMECARD_VW' THEN
        CASE 
          WHEN i_column_name = 'TE_UDF_COLLECTION_ID' THEN
            /*  TE_UDF_COLLECTION_ID contains Nulls but no dupes. */
            lv_sql := 'select TE_UDF_COLLECTION_ID' ||
                      '  from LEGO_TIMECARD_VW' || 
                      ' where TE_UDF_COLLECTION_ID is not null';

          WHEN i_column_name = 'T_UDF_COLLECTION_ID' THEN
            /* T_UDF_COLLECTION_ID may contain nulls and dupes. */
            lv_sql := 'select distinct T_UDF_COLLECTION_ID' ||
                      '  from LEGO_TIMECARD_VW' || 
                      ' where T_UDF_COLLECTION_ID is not null';
                  
          ELSE  
            raise_application_error(-20103, 'Unknown column name');

        END CASE;    

        load_distinct_udf_collctn_ids(lv_sql);

        o_base_table_name := 'lego_udf_collection_gtt';
        o_join_column     := 'udf_collection_id';

      ELSE
        /* Unknown input. */
        o_base_table_name := NULL;
        o_join_column     := NULL;
        raise_application_error(-20102, 'Unknown view name');

    END CASE;
  
    logger_pkg.debug('get_lego_join_info called with inputs: ' ||
                     i_view_name || ' ' || i_column_name ||
                     '. and returned outputs: ' || o_base_table_name || ' ' ||
                     o_join_column);
  
  END get_lego_join_info;

  --------------------------------------------------------------------------------
  PROCEDURE udf_noenum(i_new_table_name IN VARCHAR2,
                       i_join_view      IN VARCHAR2,
                       i_join_column    IN VARCHAR2) IS

    lv_join_table       VARCHAR2(30);
    lv_join_column      VARCHAR2(30);
    lv_storage_clause   lego_refresh.exadata_storage_clause%TYPE;
    lv_partition_clause lego_refresh.partition_clause%TYPE;
    lv_modified_query   CLOB;
    lv_query            CLOB := q'{  WITH 
  coll_val_def AS
   (SELECT udfd.owning_bus_org_fk        AS bus_org_id,
           udfc.identifier               AS udf_collection_id,
           udfc.bus_obj_type             AS bus_obj_type,
           udfv.value_type               AS value_type,
           udfv.number_value             AS number_value, 
           udfv.text_value               AS text_value, 
           udfv.date_value               AS date_value,
           udfv.identifier               AS udf_value_id,
           udfd.identifier               AS udf_definition_id
      FROM user_defined_field_collection AS OF SCN lego_refresh_mgr_pkg.get_scn() udfc,
           user_defined_field_value      AS OF SCN lego_refresh_mgr_pkg.get_scn() udfv,
           user_defined_field_definition AS OF SCN lego_refresh_mgr_pkg.get_scn() udfd,
           join_table_placeholder lego
     WHERE udfc.identifier             = udfv.udf_collection_fk
       AND udfv.udf_definition_fk      = udfd.identifier
       AND udfc.identifier             = lego.join_column_placeholder
       AND udfv.value_type IN (1,2,3,6,7,8))
SELECT /*+parallel(4)*/ *
  FROM (SELECT cvd.bus_org_id,
               cvd.udf_collection_id,
               cvd.udf_definition_id,
               cvd.number_value, 
               cvd.text_value, 
               cvd.date_value
          FROM coll_val_def             cvd
         WHERE cvd.value_type           IN (1,2,3,6,8)   
           AND NOT (cvd.number_value IS NULL AND cvd.text_value IS NULL AND cvd.date_value IS NULL)
         UNION ALL
        SELECT cvd.bus_org_id,
               cvd.udf_collection_id,
               cvd.udf_definition_id,
               NULL AS number_value,  -- Used to join to user_defined_field_val_doc_x, 
               NULL AS text_value,    -- document_attachment, and shared_document_attachment
               NULL AS date_value     -- in order to listagg all sda.filename values, but we hit 4k 
          FROM coll_val_def cvd       -- limit so now we NULL out all filenames for value_type 7.
         WHERE cvd.value_type = 7)
-- ORDER BY bus_org_id, udf_collection_id, udf_definition_id
 ORDER BY udf_collection_id, bus_org_id, udf_definition_id}';
  BEGIN
    logger_pkg.set_code_location('Non-Enumerated CDF lego refresh');
    logger_pkg.info('Building NOENUM table ' || i_new_table_name);
  
    get_lego_join_info(i_view_name       => UPPER(i_join_view),
                       i_column_name     => UPPER(i_join_column),
                       o_base_table_name => lv_join_table,
                       o_join_column     => lv_join_column);

    lv_modified_query := REPLACE(lv_query,
                                 'join_table_placeholder',
                                 lv_join_table);
    lv_modified_query := REPLACE(lv_modified_query,
                                 'join_column_placeholder',
                                 lv_join_column);
  
    get_lego_metadata(i_new_toggle_table_name => i_new_table_name,
                      o_storage_clause        => lv_storage_clause,
                      o_partition_clause      => lv_partition_clause);

    lego_refresh_mgr_pkg.ctas(pi_table_name             => i_new_table_name,
                              pi_stmt_clob              => lv_modified_query,
                              pi_exadata_storage_clause => lv_storage_clause,
                              pi_partition_clause       => lv_partition_clause);  -- enumerated tables are not partitioned.  Including for completeness.

    logger_pkg.info('Building NOENUM table ' || i_new_table_name || ' complete');
                                  
  END udf_noenum;

  --------------------------------------------------------------------------------
  PROCEDURE udf_enum(i_new_table_name IN VARCHAR2,
                     i_join_view      IN VARCHAR2,
                     i_join_column    IN VARCHAR2) IS

    lv_join_table          VARCHAR2(30);
    lv_join_column         VARCHAR2(30);
    lv_storage_clause      lego_refresh.exadata_storage_clause%TYPE;
    lv_partition_clause    lego_refresh.partition_clause%TYPE;
    lv_scratch_table       VARCHAR2(30);
    lv_modified_query      CLOB;
    lv_query               CLOB := q'{  WITH 
  udf_data AS 
     (SELECT udfd.owning_bus_org_fk        AS bus_org_id,
             udfc.identifier               AS udf_collection_id,
             udfv.value_type               AS value_type,
             udfv.identifier               AS udf_value_id,
             udfd.identifier               AS udf_definition_id,
             udfd.label_text_fk            AS label_text_fk,
             udfv.enumerated_value_fk      AS enumerated_value_fk
        FROM user_defined_field_collection AS OF SCN lego_refresh_mgr_pkg.get_scn() udfc,
             user_defined_field_value      AS OF SCN lego_refresh_mgr_pkg.get_scn() udfv,
             user_defined_field_definition AS OF SCN lego_refresh_mgr_pkg.get_scn() udfd,
             join_table_placeholder lego
       WHERE udfc.identifier         = udfv.udf_collection_fk
         AND udfv.udf_definition_fk  = udfd.identifier
         AND udfc.identifier         = lego.join_column_placeholder
         AND udfv.value_type IN (4,5)),
  enum_udf_data AS      
     (SELECT u.bus_org_id,
             u.udf_collection_id,
             u.udf_definition_id,
             lte2.locale_preference    AS locale_preference,
             LISTAGG(lte2.text1,'; ') WITHIN GROUP (ORDER BY udf_value_id) AS text_value
        FROM udf_data                                                               u,
             user_defined_field_val_txt_x  AS OF SCN lego_refresh_mgr_pkg.get_scn() x,
             localizable_text_entry        AS OF SCN lego_refresh_mgr_pkg.get_scn() lte2
       WHERE u.udf_value_id         = x.user_defined_field_value_fk
         AND x.localizable_text_fk  = lte2.localizable_text_fk
         AND u.value_type           = 4
       GROUP BY u.bus_org_id, 
                u.udf_collection_id, 
                u.udf_definition_id, 
                lte2.locale_preference  
       UNION ALL
      SELECT u.bus_org_id,                 
             u.udf_collection_id,
             u.udf_definition_id,
             lte2.locale_preference,
             lte2.text1                AS text_value
        FROM udf_data                                                        u,
             localizable_text_entry AS OF SCN lego_refresh_mgr_pkg.get_scn() lte,  --why join to this?
             localizable_text_entry AS OF SCN lego_refresh_mgr_pkg.get_scn() lte2
       WHERE u.label_text_fk        = lte.localizable_text_fk
         AND u.enumerated_value_fk  = lte2.localizable_text_fk 
         AND lte.locale_preference  = lte2.locale_preference
         AND u.value_type           = 5),
  enum_udf_data_buildout AS 
     (SELECT eu.bus_org_id, 
             eu.udf_collection_id, 
             eu.udf_definition_id,
             eu.locale_preference   AS data_locale,
             eu.text_value          AS data_text,
             dl.locale_preference,
             s.score
        FROM enum_udf_data eu, 
             lego_locales_by_buyer_org_vw dl,
             lego_locale_pref_score_vw s
       WHERE eu.locale_preference  = s.data_locale_pref
         AND eu.bus_org_id         = dl.buyer_org_id
         AND s.session_locale_pref = dl.locale_preference)
SELECT /*+ hint_placeholder */
       bus_org_id, 
       udf_collection_id, 
       udf_definition_id,
       locale_preference,
       MAX(data_text) as text_value
  FROM (SELECT bus_org_id, 
               udf_collection_id, 
               udf_definition_id,
               locale_preference,
               data_text,
               RANK() OVER (PARTITION BY bus_org_id, udf_collection_id, udf_definition_id, locale_preference
                                ORDER BY score DESC, data_locale) AS row_rank
          FROM enum_udf_data_buildout)
 WHERE row_rank = 1      
 GROUP BY bus_org_id, 
          udf_collection_id, 
          udf_definition_id, 
          locale_preference
 ORDER BY bus_org_id}';
 /* -- ORDER BY bus_org_id, udf_collection_id, udf_definition_id
    -- ORDER BY udf_collection_id, udf_definition_id
    -- ORDER BY udf_collection_id, bus_org_id, udf_definition_id  */
  BEGIN
    /* Possible future enhancement idea for ENUM and NOENUM tables:
    Join to LEGO_BUYER_ORG_VW to get the enterprise_bus_org_id corresponding to the bus_org_id value.
    Expose that value as a new column in the base table and then partition by that column.  This could 
    be list or hash partitioning.  The pivot views would then be changed to specify filter on the 
    enterprise_bus_org_id (equijoin) instead of the where org in (subselect).  This would ensure partition 
    elimination.  We could then subpartition on locale_preference. */
    logger_pkg.set_code_location('Enumerated CDF lego refresh');
    logger_pkg.info('Building ENUM table ' || i_new_table_name);
    
    get_lego_join_info(i_view_name       => UPPER(i_join_view),
                       i_column_name     => UPPER(i_join_column),
                       o_base_table_name => lv_join_table,
                       o_join_column     => lv_join_column);

    lv_modified_query := REPLACE(lv_query,
                                 'join_table_placeholder',
                                 lv_join_table);
    lv_modified_query := REPLACE(lv_modified_query,
                                 'join_column_placeholder',
                                 lv_join_column);
  
    get_lego_metadata(i_new_toggle_table_name => i_new_table_name,
                      o_storage_clause        => lv_storage_clause,
                      o_partition_clause      => lv_partition_clause);

    lego_refresh_mgr_pkg.ctas(pi_table_name             => i_new_table_name,
                              pi_stmt_clob              => lv_modified_query,
                              pi_exadata_storage_clause => lv_storage_clause,
                              pi_partition_clause       => lv_partition_clause);

    logger_pkg.info('Building ENUM table ' || i_new_table_name || ' complete');

  END udf_enum;

  --------------------------------------------------------------------------------
  PROCEDURE load_locales_by_buyer_org (pi_refresh_table IN VARCHAR2) IS

    c_delimiter          CONSTANT   VARCHAR2(1) := ',';
    c_num_avail_locales  CONSTANT   PLS_INTEGER := 34;

    TYPE t_chunk IS TABLE OF VARCHAR2(1000) INDEX BY PLS_INTEGER;
    v_chunk t_chunk;

    lv_storage_clause               lego_refresh.exadata_storage_clause%TYPE;
    v_refreshing_tab                VARCHAR2(30);
    v_rc_buyer_org_locale           VARCHAR2(2000);
    rc_buyer_org_locale             SYS_REFCURSOR;
    rec_buyer_entprs_bus_org_id     NUMBER(20);
    rec_delim_str                   VARCHAR2(256);
    v_rc_buyer_org                  VARCHAR2(2000);
    rc_buyer_org                    SYS_REFCURSOR;
    rec_buyer_org_id                NUMBER(20);
    v_str                           VARCHAR2(256);
    v_no_of_chunks                  PLS_INTEGER;
    v_pos                           PLS_INTEGER;
    lv_merge_stmt                   VARCHAR2(4000);
    lv_delete_stmt                  VARCHAR2(4000);

  BEGIN
    logger_pkg.set_code_location('building lego_locals_by_buyer_org');
    logger_pkg.info('Starting load_locales_by_buyer_org.  Loading table: ' || pi_refresh_table);

    /* Grab the storage clause from LEGO_REFRESH and then create the table.  We know that the refresh 
    manager package already dropped the older copy of this table.  */
    SELECT exadata_storage_clause
      INTO lv_storage_clause
      FROM lego_refresh
     WHERE object_name = 'LEGO_LOCALES_BY_BUYER_ORG';
      
    EXECUTE IMMEDIATE 'CREATE TABLE ' || pi_refresh_table ||
                      '  (buyer_org_id                 NUMBER(20),' ||
                      '   buyer_enterprise_bus_org_id  NUMBER(20),' ||
                      '   locale_preference            NUMBER(5)) ' ||
                      lv_storage_clause;

    /* Find which of the base tables for LEGO_BUS_ORG_VW we need to use. */
    v_refreshing_tab := most_recently_loaded_table('LEGO_BUS_ORG');

    /* This is the driving cursor.  return all distinct enterprise_bus_org_id values
    and their available locale preferences  */
    v_rc_buyer_org_locale := 'SELECT business_organization_id  AS buyer_enterprise_bus_org_id,' || 
                             '       avail_locale_prefs        AS delim_str' ||
                             '  FROM business_organization AS OF SCN lego_refresh_mgr_pkg.get_scn()' ||
                             ' WHERE business_organization_id IN' ||
                             '   (SELECT DISTINCT enterprise_bus_org_id' ||
                             '      FROM ' || v_refreshing_tab || ' )' ||
                             ' ORDER BY buyer_enterprise_bus_org_id';

    OPEN rc_buyer_org_locale FOR v_rc_buyer_org_locale;

    LOOP
      FETCH rc_buyer_org_locale
        INTO rec_buyer_entprs_bus_org_id, rec_delim_str;
      EXIT WHEN rc_buyer_org_locale%NOTFOUND;
  
      IF rec_delim_str IS NOT NULL
      THEN
        /* There are specified locale preferences that need to be parsed. 
        if rec_delim_str is null, there is no parsing necessary.  That scenario
        will be handled below.   */
        v_str := ltrim(REPLACE(rec_delim_str, '|', c_delimiter), c_delimiter);
    
        v_no_of_chunks := regexp_count(v_str, c_delimiter);
        v_pos          := instr(v_str, c_delimiter, 1, 1);
      
        FOR i IN 1 .. v_no_of_chunks LOOP
        
          v_chunk(i) := substr(v_str, 1, v_pos - 1);
          v_str := substr(v_str, v_pos + 1, length(v_str));
          v_pos := instr(v_str, c_delimiter, 1, 1);
        
          IF v_pos = 0
          THEN
            v_chunk(i + 1) := v_str;
          END IF;
        
        END LOOP;
      END IF;
  
      /* open a cursor for each of the child buyer orgs for this enterprise_bus_org_id  */
      v_rc_buyer_org := 'SELECT bus_org_id ' || 
                        '  FROM ' || v_refreshing_tab || 
                        ' WHERE enterprise_bus_org_id = :enterprise_id';
  
      OPEN rc_buyer_org FOR v_rc_buyer_org USING rec_buyer_entprs_bus_org_id;
  
      LOOP
        FETCH rc_buyer_org
          INTO rec_buyer_org_id;
        EXIT WHEN rc_buyer_org%NOTFOUND;
    
        /* if rec_delim_str is not null then insert a row for the enterprise_bus_org_id,
        for every child buyer_org, for every available locale preference.  */
        IF rec_delim_str IS NOT NULL
        THEN
      
          FOR x IN 1 .. v_chunk.count LOOP
        
            EXECUTE IMMEDIATE 'INSERT INTO ' || pi_refresh_table || 
                              '  (buyer_org_id, buyer_enterprise_bus_org_id, locale_preference) ' ||
                              'VALUES (:1, :2, :3)'
              USING rec_buyer_org_id, rec_buyer_entprs_bus_org_id, v_chunk(x);
        
          END LOOP;

        ELSE
          /* if rec_delim_str is null, the enterprise_bus_org_id and its children
          inherit ALL available locales.  Unfortunately, the list of all available 
          locales is only stored in the Java code.  At this point there are 0-34. 
          If this changes, edit the value of c_num_avail_locales.
          Insert a row for the enterprise_bus_org_id, for every child buyer_org, 
          for every available locale preference  */
          FOR y IN 0 .. c_num_avail_locales LOOP
        
            EXECUTE IMMEDIATE 'INSERT INTO ' || pi_refresh_table || 
                              '  (buyer_org_id, buyer_enterprise_bus_org_id, locale_preference) ' ||
                              'VALUES (:1, :2, :3)'
              USING rec_buyer_org_id, rec_buyer_entprs_bus_org_id, y;
        
          END LOOP;
        END IF;
    
      END LOOP;  -- child orgs

      /* empty the collection  */
      v_chunk.delete;
      
      CLOSE rc_buyer_org;
  
    END LOOP;  -- enterprise orgs
    CLOSE rc_buyer_org_locale;

    /* There are some cases where we have UDF data for locales which are not 
    represented in BUSINESS_ORGANIZATION.avail_locale_prefs.  Assuming that users
    might still log in to Jasper and need to see data of these locales, we will merge
    rows for these locales into the lego.  */
    lv_merge_stmt := 'MERGE INTO ' || pi_refresh_table || ' a ' ||
                     'USING (  WITH udf_locale_data AS
                                    (SELECT DISTINCT udfd.owning_bus_org_fk, lte.locale_preference  --type 4
                                       FROM user_defined_field_definition udfd,
                                            user_defined_field_value udfv,
                                            user_defined_field_val_txt_x x,
                                            localizable_text_entry lte
                                      WHERE udfd.identifier = udfv.udf_definition_fk
                                        AND udfv.identifier = x.user_defined_field_value_fk
                                        AND x.localizable_text_fk = lte.localizable_text_fk
                                      UNION   -- not union all since we want a distinct list
                                     SELECT DISTINCT udfd.owning_bus_org_fk, lte.locale_preference  --type 5
                                       FROM user_defined_field_definition udfd,
                                            user_defined_field_value udfv,
                                            localizable_text_entry lte
                                      WHERE udfd.identifier = udfv.udf_definition_fk
                                        AND udfv.enumerated_value_fk = lte.localizable_text_fk)
                             SELECT uld.owning_bus_org_fk, l2.buyer_enterprise_bus_org_id, uld.locale_preference
                               FROM ' || pi_refresh_table || ' l2,
                                    udf_locale_data uld
                              WHERE l2.buyer_org_id = uld.owning_bus_org_fk
                              GROUP BY uld.owning_bus_org_fk, l2.buyer_enterprise_bus_org_id, uld.locale_preference) b
                         ON (b.owning_bus_org_fk = a.buyer_org_id AND
                             b.locale_preference = a.locale_preference)
                       WHEN NOT MATCHED THEN
                     INSERT (buyer_org_id, buyer_enterprise_bus_org_id, locale_preference)
                     VALUES (b.owning_bus_org_fk, b.buyer_enterprise_bus_org_id, b.locale_preference)';

    logger_pkg.debug(lv_merge_stmt);                 
    logger_pkg.info('Merging locales for which we have UDF data but no data ' ||
                    'in BUSINESS_ORGANIZATION.avail_locale_prefs - starting...');
 
    EXECUTE IMMEDIATE lv_merge_stmt;
    logger_pkg.info('Merging locales for which we have UDF data but no data ' ||
                    'in BUSINESS_ORGANIZATION.avail_locale_prefs - complete. ' || 
                    to_char(SQL%ROWCOUNT) || ' rows inserted', TRUE);

    /* There are some cases where a duplicate locale shows up in the front office table 
    business_organization.avail_locale_prefs. Since we don't have any constraints on the lego,
    the duplicate data is loaded in and these dupes cause issues "downstream" in the enumerated 
    CDF legos.  The below delete removes all but one of the dupes. We eventaully may want to look at 
    putting a constraint on the lego or just making it an IOT.
    See IQN-16081 for details on fixing the FO to prevent this situation.  Once this issue is fixed,
    this delete step can be eliminated.  */
    lv_delete_stmt := 'DELETE FROM ' || pi_refresh_table ||
                      ' WHERE ROWID IN (SELECT rid' ||
                      '                   FROM (SELECT ROWID AS rid,' ||
                      '                                RANK() OVER (PARTITION BY buyer_org_id, buyer_enterprise_bus_org_id, locale_preference' ||
                      '                                                 ORDER BY ROWID) AS rn' ||
                      '                           FROM ' || pi_refresh_table || ')' ||
                      '                  WHERE rn > 1)';

    logger_pkg.debug(lv_delete_stmt);                 
    logger_pkg.info('Deleting duplicate rows - starting...');
 
    EXECUTE IMMEDIATE lv_delete_stmt;
    logger_pkg.info('Deleting duplicate rows - complete. ' || 
                    to_char(SQL%ROWCOUNT) || ' rows deleted', TRUE);

    /* Commit the merge and delete. */
    COMMIT;

    logger_pkg.debug('load_locales_by_buyer_org complete');

  END load_locales_by_buyer_org;

  --------------------------------------------------------------------------------
  PROCEDURE create_pivot_views (pi_enterprise_bus_org_id IN NUMBER,
                                pi_udf_collection_col    IN VARCHAR2,
                                pi_enum_base_lego        IN VARCHAR2,
                                pi_noenum_base_lego      IN VARCHAR2,
                                pi_name_code             IN VARCHAR2) IS

    /* The delimiter between enumerated UDF data in pivot view. */
    lc_delimiter   CONSTANT VARCHAR2(2)  := '; ';
    /* Name of the RO schema */
    lc_rod_schema                CONSTANT VARCHAR2(30) := 'RO_' || sys_context('USERENV','CURRENT_SCHEMA');
    
    lc_enum_synonym              CONSTANT VARCHAR2(30) := pi_enum_base_lego;   --synonym name is the same as lego name for toggles.
    lc_noenum_synonym            CONSTANT VARCHAR2(30) := pi_noenum_base_lego; --synonym name is the same as lego name for toggles.
    lc_recently_built_noenum_tab CONSTANT VARCHAR2(30) := most_recently_loaded_table(pi_noenum_base_lego);
  
    lv_enumviewname   VARCHAR2(30);
    lv_noenumviewname VARCHAR2(30);
    lv_enumviewtext   CLOB;
    lv_noenumviewtext CLOB;
  
    lv_notnull_number_count NUMBER;
    lv_notnull_text_count   NUMBER;
    lv_notnull_date_count   NUMBER;
    lv_total_count          NUMBER;
  
    CURSOR udf_definition_list_cur(i_field_class        NUMBER,
                                   i_view_column_name   VARCHAR,
                                   i_enterprise_bus_org NUMBER) IS
      WITH 
      bus_obj_types AS
       (SELECT DISTINCT owning_udf_fk, bus_obj_type
          FROM user_defined_field_object_assn),
      enterprise_buyer_orgs AS
       (SELECT b.business_organization_id         AS child_org,
               bo_parent.business_organization_id AS enterprise_buyer_org
          FROM business_organization b,
               bus_org_lineage       bol,
               business_organization bo_parent,
               firm_role             fr
         WHERE bol.ancestor_bus_org_fk = bo_parent.business_organization_id
           AND bol.descendant_bus_org_fk = b.business_organization_id
           AND b.business_organization_id = fr.business_org_fk(+)
           AND bo_parent.parent_business_org_fk IS NULL
           AND fr.firm_id NOT IN (1038, 4767)  -- these two records are the firm_type='D' records for the dupes in firm_role.business_org_fk
           AND fr.firm_type NOT IN ('S', 'P', 'I'))
      SELECT DISTINCT udfd.identifier AS udf_definition_id,
             udfd.field_type
        FROM user_defined_field_definition udfd,
             bus_obj_types,
             enterprise_buyer_orgs
       WHERE udfd.identifier = bus_obj_types.owning_udf_fk
         AND udfd.owning_bus_org_fk = enterprise_buyer_orgs.child_org
         AND udfd.field_class = i_field_class
         AND enterprise_buyer_orgs.enterprise_buyer_org = i_enterprise_bus_org
         AND bus_obj_types.bus_obj_type IN
             (SELECT udf_bus_obj_type
                FROM lego_udf_metadata_type
               WHERE lego_view_column_name = i_view_column_name);

  BEGIN
    /*  To Do:  
         For non-enumerated UDFs, get the udf datatype from the above cursor instead of 
         repeatedly querying the UDF base LEGO tables. See the comments in the loop 
         which creates columns in the NOENUM view for more info. */ 

    lv_enumviewname   := lc_viewname_prefix ||
                         pi_name_code || '_ENUM_' ||
                         to_char(pi_enterprise_bus_org_id) || '_VW';

    lv_noenumviewname := lc_viewname_prefix ||
                         pi_name_code || '_NOENUM_' ||
                         to_char(pi_enterprise_bus_org_id) || '_VW';
                       
    /* Enum viewtext does not need to select or group by locale_preference since it is 
    specified by an EQUALS (only one value).  */
    lv_enumviewtext := 'create or replace view ' || lv_enumviewname ||
                       ' as select udf_collection_id';  

    lv_noenumviewtext := 'create or replace view ' || lv_noenumviewname ||
                         ' as select udf_collection_id';

    /* Loop through applicable ENUM UDF definitions found in FO tables for this enterprise.  */
    FOR udf_def_index IN udf_definition_list_cur(2,  --enumerated
                                                 pi_udf_collection_col,
                                                 pi_enterprise_bus_org_id) LOOP

      logger_pkg.debug('Inside inner enum loop - udf_definition_id: ' ||
                       to_char(udf_def_index.udf_definition_id) || 
                       '  field_type: ' || to_char(udf_def_index.field_type));
      
      /* Add a column to the viewtext for each udf_definition_id. */
      lv_enumviewtext := lv_enumviewtext ||
                         ', max(decode(udf_definition_id,' ||
                         to_char(udf_def_index.udf_definition_id) ||
                         ',text_value,null)) as udf_' ||
                         pi_name_code || '_' ||
                         to_char(udf_def_index.udf_definition_id);

    END LOOP;
    
    /* Loop through applicable NOENUM UDF definitions found in FO tables for this enterprise.  */
    FOR udf_def_index IN udf_definition_list_cur(1,  --non-enumerated
                                                 pi_udf_collection_col,
                                                 pi_enterprise_bus_org_id) LOOP

      logger_pkg.debug('Inside inner noenum loop - udf_definition_id: ' ||
                       to_char(udf_def_index.udf_definition_id));
      
      /* Add a column to the viewtext for each udf_definition_id.  First we must find if 
      this udf definition is a date, text, or a number.  We do this by looking at the UDF base 
      tables.  A future enhancement would be to get this by adding udfd.field_type to our 
      cursor above and then using that.  
      This query -should- be fast due to the two AND conditions.  If it does not find any data,
      we know that this definition is either not in the udf base table (udf defined but not yet used) 
      or it is in the udf base table but all of number_value, date_value, and text_value are NULL.
      In either case total_count will be 0 and all values for that column will be NULL in the view,
      so we can just use to_char(NULL) in the viewtext.
      In cases where more than one of number_value, date_value, or text_value are not null, the 
      datatype of the column will be determined by the order of clauses in the CASE statement.  */
      EXECUTE IMMEDIATE 'SELECT COUNT(number_value), COUNT(text_value), COUNT(date_value), COUNT(*)' ||
                        '  FROM ' || lc_recently_built_noenum_tab ||
                        ' WHERE udf_definition_id = :1' ||
                        '   AND (number_value IS NOT NULL OR text_value IS NOT NULL OR date_value IS NOT NULL)' ||
                        '   AND rownum < 2'
         INTO lv_notnull_number_count, lv_notnull_text_count, lv_notnull_date_count, lv_total_count
        USING udf_def_index.udf_definition_id;

      /* Add a column to the viewtext for this udf definition. Since these are non-enumerated,
      there is just one distinct value and we can use MAX around the decode. */
      lv_noenumviewtext := lv_noenumviewtext || ', ' || 
                           CASE
                             WHEN lv_total_count = 0
                             /* Either all rows are NULL in date, text, and number cols or
                             this udf definition is not yet associated with any udf values.  
                             Either way, we can make column NULL for all rows.  */
                               THEN 'to_char(NULL)'
                             WHEN lv_notnull_text_count > 0
                             /* This is a TEXT field UDF. */
                               THEN 'max(decode(udf_definition_id,' ||
                                    to_char(udf_def_index.udf_definition_id) ||
                                    ',text_value,null))'
                             WHEN lv_notnull_date_count > 0
                             /* This is a DATE field UDF. */
                               THEN 'max(decode(udf_definition_id,' ||
                                    to_char(udf_def_index.udf_definition_id) ||
                                    ',date_value,null))'
                             WHEN lv_notnull_number_count > 0
                             /* This is a NUMBER field UDF. */
                               THEN 'max(decode(udf_definition_id,' ||
                                     to_char(udf_def_index.udf_definition_id) ||
                                     ',number_value,null))'
                           END || ' as udf_' ||
                           pi_name_code || '_' ||
                           to_char(udf_def_index.udf_definition_id);
    END LOOP;
    
    /*  SELECT clause is complete, now add FROM, WHERE, and GROUP BY clauses. 
    ENUM view used to group by locale_preference, but that is no longer required 
    since we are filtering on that column. */
    lv_enumviewtext   := lv_enumviewtext || ' from ' || lc_enum_synonym ||
                         ' where bus_org_id in (select buyer_org_id from lego_buyer_org_vw where buyer_enterprise_bus_org_id=' ||
                         to_char(pi_enterprise_bus_org_id) ||
                         ') and locale_preference = (select iqn_session_context_pkg.get_current_locale_preference from dual) ' ||
                         'group by udf_collection_id';
    lv_noenumviewtext := lv_noenumviewtext || ' from ' || lc_noenum_synonym ||
                         ' where bus_org_id in (select buyer_org_id from lego_buyer_org_vw where buyer_enterprise_bus_org_id=' ||
                         to_char(pi_enterprise_bus_org_id) ||
                         ') group by udf_collection_id';

    /* SQL created.  Execute it. */
    logger_pkg.debug(lv_enumviewtext);
    EXECUTE IMMEDIATE (lv_enumviewtext);
    EXECUTE IMMEDIATE ('grant select on ' || lv_enumviewname || ' to ' || lc_rod_schema);
    logger_pkg.debug(lv_noenumviewtext);
    EXECUTE IMMEDIATE (lv_noenumviewtext);
    EXECUTE IMMEDIATE ('grant select on ' || lv_noenumviewname || ' to ' || lc_rod_schema);

  END create_pivot_views;

  --------------------------------------------------------------------------------
  PROCEDURE create_all_pivot_views(pi_enterprise_bus_org_id IN NUMBER) IS
    lv_source  VARCHAR2(61) := 'LEGO_UDF_UTIL.create_all_pivot_views';
    lv_bus_org NUMBER;
  BEGIN
    logger_pkg.set_level(lego_refresh_mgr_pkg.get_lego_parameter_text_value('logging_level'));
    logger_pkg.set_source(lv_source);
    logger_pkg.set_code_location('creating enterprise pivot views');
    logger_pkg.info('Starting create_all_pivot_views for enterprise bus_org: ' ||
                    to_char(pi_enterprise_bus_org_id));
  
    /* Verify if that is a valid enterprise bus org id.  Must check FO tables and not
    legos so that this package will compile before initial LEGO loads and refreshes. */
    BEGIN
    
      SELECT DISTINCT bo_parent.business_organization_id AS enterprise_buyer_org
        INTO lv_bus_org
        FROM business_organization b,
             bus_org_lineage       bol,
             business_organization bo_parent,
             firm_role             fr
       WHERE bol.ancestor_bus_org_fk = bo_parent.business_organization_id
         AND bol.descendant_bus_org_fk = b.business_organization_id
         AND b.business_organization_id = fr.business_org_fk(+)
         AND bo_parent.parent_business_org_fk IS NULL
         AND fr.firm_type NOT IN ('S', 'P', 'I')
         AND bo_parent.business_organization_id = pi_enterprise_bus_org_id;
    
    EXCEPTION
      WHEN no_data_found THEN
        raise_application_error(-20101,
                                'Not a valid enterprise business org ID.');
    END;
  
    /* Loop through UDF collection columns in other LEGOs and build ENUM and NONENUM
    pivot views for each. */
    FOR i IN (SELECT lego_view_column_name,
                     enumerated_base_object_name,
                     nonenumerated_base_object_name,
                     pivot_view_name_code
                FROM lego_udf_metadata) LOOP
    
      logger_pkg.debug('calling create_pivot_views with args enterprise_bus_org_id: ' ||
                       to_char(lv_bus_org) || ' LEGO view.column: ' ||
                       i.lego_view_column_name || ' ENUM base object: ' ||
                       i.enumerated_base_object_name ||
                       ' NOENUM base object: ' ||
                       i.nonenumerated_base_object_name ||
                       ' pivot view name code: ' || i.pivot_view_name_code);
    
      create_pivot_views(pi_enterprise_bus_org_id => lv_bus_org,
                         pi_udf_collection_col    => i.lego_view_column_name,
                         pi_enum_base_lego        => i.enumerated_base_object_name,
                         pi_noenum_base_lego      => i.nonenumerated_base_object_name,
                         pi_name_code             => i.pivot_view_name_code);
    
    END LOOP;
  
    logger_pkg.info('create_all_pivot_views for enterprise bus_org: ' ||
                    to_char(pi_enterprise_bus_org_id) || ' complete!');
    logger_pkg.unset_source(lv_source);
  
  EXCEPTION
    WHEN OTHERS
      THEN 
        /* This is the top-level proc called by Jasper.  Any errors that may have occured
        need to be logged here.  */
        logger_pkg.fatal(NULL, SQLCODE, 'Error while building pivot views for enterprise: ' ||
                         to_char(pi_enterprise_bus_org_id) || chr(10) || SQLERRM || chr(10) ||
                         dbms_utility.format_error_backtrace);
        logger_pkg.unset_source(lv_source);
        RAISE;
        
  END create_all_pivot_views;

END lego_udf_util;
/

