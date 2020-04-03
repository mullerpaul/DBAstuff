--------------------------------------------------------------------------------------
-- Before starting, make sure the database links are working.
--------------------------------------------------------------------------------------
SELECT * FROM dual@baseline_location;
SELECT * FROM dual@test_location;

--------------------------------------------------------------------------------------
-- Load temp tables with diff information.
--------------------------------------------------------------------------------------
-- tables
INSERT INTO compare_tables_gtt
  WITH baseline_schema 
    AS (SELECT dt.owner, dt.table_name, dt.tablespace_name, dt.iot_name, dt.iot_type, dt.partitioned, dt.temporary
          FROM dba_tables@baseline_location dt 
         WHERE dt.owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND dt.table_name NOT LIKE 'SOS%'
           AND NOT (dt.owner = 'IQPRODD' AND (dt.table_name LIKE '%1' OR dt.table_name LIKE '%2'))),
       test_schema
    AS (SELECT dt.owner, dt.table_name, dt.tablespace_name, dt.iot_name, dt.iot_type, dt.partitioned, dt.temporary
          FROM dba_tables@test_location dt 
         WHERE dt.owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND dt.table_name NOT LIKE 'SOS%'
           AND NOT (dt.owner = 'IQPRODD' AND (dt.table_name LIKE '%1' OR dt.table_name LIKE '%2')))
SELECT 'baseline' AS location_identifier, a.*
  FROM (SELECT * FROM baseline_schema
         MINUS       
        SELECT * FROM test_schema) a 
 UNION ALL        
SELECT 'test' AS location_identifier, b.*
  FROM (SELECT * FROM test_schema
         MINUS       
        SELECT * FROM baseline_schema) b
/

-- table columns
INSERT INTO compare_table_columns_gtt
  WITH baseline_schema 
    AS (SELECT dt.owner, dt.table_name, dtc.column_name, dtc.data_type, 
               dtc.data_length, dtc.data_precision, dtc.data_scale, dtc.nullable
          FROM dba_tables@baseline_location dt,
               dba_tab_columns@baseline_location dtc
         WHERE dt.table_name = dtc.table_name
           AND dt.owner = dtc.owner
           AND dt.owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND dt.table_name NOT LIKE 'SOS%'
           AND dt.table_name NOT LIKE 'BIN$%'
           AND NOT (dt.owner = 'IQPRODD' AND (dt.table_name LIKE '%1' OR dt.table_name LIKE '%2'))),
       test_schema
    AS (SELECT dt.owner, dt.table_name, dtc.column_name, dtc.data_type, 
               dtc.data_length, dtc.data_precision, dtc.data_scale, dtc.nullable
          FROM dba_tables@test_location dt,
               dba_tab_columns@test_location dtc
         WHERE dt.table_name = dtc.table_name
           AND dt.owner = dtc.owner
           AND dt.owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND dt.table_name NOT LIKE 'SOS%'
           AND dt.table_name NOT LIKE 'BIN$%'
           AND NOT (dt.owner = 'IQPRODD' AND (dt.table_name LIKE '%1' OR dt.table_name LIKE '%2')))
SELECT 'baseline' AS location_identifier, a.*
  FROM (SELECT * FROM baseline_schema
         MINUS       
        SELECT * FROM test_schema) a 
 UNION ALL        
SELECT 'test' AS location_identifier, b.*
  FROM (SELECT * FROM test_schema
         MINUS       
        SELECT * FROM baseline_schema) b
/

-- views
INSERT INTO compare_views_gtt
  WITH baseline_schema 
    AS (SELECT dv.owner, dv.view_name
          FROM dba_views@baseline_location dv 
         WHERE dv.owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND NOT (dv.owner = 'IQPRODD' AND dv.view_name LIKE 'UDF%')),
       test_schema
    AS (SELECT dv.owner, dv.view_name
          FROM dba_views@test_location dv 
         WHERE dv.owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND NOT (dv.owner = 'IQPRODD' AND dv.view_name LIKE 'UDF%'))
SELECT 'baseline' AS location_identifier, a.*
  FROM (SELECT * FROM baseline_schema
         MINUS       
        SELECT * FROM test_schema) a 
 UNION ALL        
SELECT 'test' AS location_identifier, b.*
  FROM (SELECT * FROM test_schema
         MINUS       
        SELECT * FROM baseline_schema) b
/

-- view columns
INSERT INTO compare_view_columns_gtt
  WITH baseline_schema 
    AS (SELECT dv.owner, dv.view_name, dtc.column_name, dtc.data_type, 
               dtc.data_length, dtc.data_precision, dtc.data_scale, dtc.nullable
          FROM dba_views@baseline_location dv, 
               dba_tab_columns@baseline_location dtc
         WHERE dv.view_name = dtc.table_name
           AND dv.owner = dtc.owner
           AND dv.owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND NOT (dv.owner = 'IQPRODD' AND dv.view_name LIKE 'UDF%')),
       test_schema
    AS (SELECT dv.owner, dv.view_name, dtc.column_name, dtc.data_type, 
               dtc.data_length, dtc.data_precision, dtc.data_scale, dtc.nullable
          FROM dba_views@test_location dv, 
               dba_tab_columns@test_location dtc
         WHERE dv.view_name = dtc.table_name
           AND dv.owner = dtc.owner
           AND dv.owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND NOT (dv.owner = 'IQPRODD' AND dv.view_name LIKE 'UDF%'))
SELECT 'baseline' AS location_identifier, a.*
  FROM (SELECT * FROM baseline_schema
         MINUS       
        SELECT * FROM test_schema) a 
 UNION ALL        
SELECT 'test' AS location_identifier, b.*
  FROM (SELECT * FROM test_schema
         MINUS       
        SELECT * FROM baseline_schema) b
/


-- indexes and indexed columns
INSERT INTO compare_indexes_gtt
  WITH baseline_schema 
    AS (SELECT di.owner, CASE WHEN di.index_name LIKE 'SYS\_%' ESCAPE '\' THEN 'system_generated_name' ELSE di.index_name END AS index_name, 
               di.index_type, di.table_name, di.table_owner, di.uniqueness, di.compression, 
               di.prefix_length, di.tablespace_name, di.status, di.partitioned, di.temporary, 
               listagg(dic.column_name, ', ') WITHIN GROUP (ORDER BY dic.column_position) AS column_list
          FROM dba_indexes@baseline_location di,
               dba_ind_columns@baseline_location dic
         WHERE di.index_name = dic.index_name
           AND di.owner = dic.index_owner
           AND di.table_owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND di.index_type <> 'LOB'
           AND di.table_name NOT LIKE 'SOS%'
           AND NOT (di.owner = 'IQPRODD' AND (di.table_name LIKE '%1' OR di.table_name LIKE '%2'))
         GROUP BY di.owner, CASE WHEN di.index_name LIKE 'SYS\_%' ESCAPE '\' THEN 'system_generated_name' ELSE di.index_name END, 
                  di.index_type, di.table_name, di.table_owner, di.uniqueness, di.compression, 
                  di.prefix_length, di.tablespace_name, di.status, di.partitioned, di.temporary),
       test_schema
    AS (SELECT di.owner, CASE WHEN di.index_name LIKE 'SYS\_%' ESCAPE '\' THEN 'system_generated_name' ELSE di.index_name END AS index_name, 
               di.index_type, di.table_name, di.table_owner, di.uniqueness, di.compression, 
               di.prefix_length, di.tablespace_name, di.status, di.partitioned, di.temporary, 
               listagg(dic.column_name, ', ') WITHIN GROUP (ORDER BY dic.column_position) AS column_list
          FROM dba_indexes@test_location di,
               dba_ind_columns@test_location dic
         WHERE di.index_name = dic.index_name
           AND di.owner = dic.index_owner
           AND di.table_owner IN ('IQPROD','IQPRODD','IQPRODR')
           AND di.index_type <> 'LOB'
           AND di.table_name NOT LIKE 'SOS%'
           AND NOT (di.owner = 'IQPRODD' AND (di.table_name LIKE '%1' OR di.table_name LIKE '%2'))
         GROUP BY di.owner, CASE WHEN di.index_name LIKE 'SYS\_%' ESCAPE '\' THEN 'system_generated_name' ELSE di.index_name END, 
                  di.index_type, di.table_name, di.table_owner, di.uniqueness, di.compression, 
                  di.prefix_length, di.tablespace_name, di.status, di.partitioned, di.temporary)
SELECT 'baseline' AS location_identifier, a.*
  FROM (SELECT * FROM baseline_schema
         MINUS       
        SELECT * FROM test_schema) a 
 UNION ALL        
SELECT 'test' AS location_identifier, b.*
  FROM (SELECT * FROM test_schema
         MINUS       
        SELECT * FROM baseline_schema) b
/


-- synonyms
INSERT INTO compare_synonyms_gtt
  WITH baseline_schema 
    AS (SELECT owner, synonym_name, table_owner, table_name, db_link
          FROM dba_synonyms@baseline_location
         WHERE table_owner IN ('IQPROD','IQPRODD','IQPRODR')  -- only synonyms for application objects
           AND owner IN ('IQPROD','IQPRODD','IQPRODR','RO_IQPROD','RO_IQPRODD','RO_IQPRODR','PUBLIC')),  --private and public synonyms
       test_schema
    AS (SELECT owner, synonym_name, table_owner, table_name, db_link
          FROM dba_synonyms@test_location
         WHERE table_owner IN ('IQPROD','IQPRODD','IQPRODR')  -- only synonyms for application objects
           AND owner IN ('IQPROD','IQPRODD','IQPRODR','RO_IQPROD','RO_IQPRODD','RO_IQPRODR','PUBLIC'))  --private and public synonyms
SELECT 'baseline' AS location_identifier, a.*
  FROM (SELECT * FROM baseline_schema
         MINUS       
        SELECT * FROM test_schema) a 
 UNION ALL        
SELECT 'test' AS location_identifier, b.*
  FROM (SELECT * FROM test_schema
         MINUS       
        SELECT * FROM baseline_schema) b
/


--------------------------------------------------------------------------------------
-- Now that we have loaded the diff information, we can report on those diffs.
--------------------------------------------------------------------------------------
-- tables 
SELECT COALESCE(b.owner, t.owner) AS owner,
       COALESCE(b.table_name, t.table_name) AS table_name,
       CASE 
         WHEN b.table_name IS NOT NULL AND t.table_name IS NOT NULL THEN 'Table exists in both but attributes are different'
         WHEN b.table_name IS NULL THEN 'Table does not exist in baseline'
         WHEN t.table_name IS NULL THEN 'Table does not exist in test'
       END               AS table_status,    
       b.tablespace_name AS baseline_tablespace,  t.tablespace_name AS test_tablespace,
       b.iot_name        AS baseline_iot_name,    t.iot_name        AS test_iot_name,
       b.iot_type        AS baseline_iot_type,    t.iot_type        AS test_iot_type,
       b.partitioned     AS baseline_partitioned, t.partitioned     AS test_partitioned,
       b.temporary       AS baseline_temporary,   t.temporary       AS test_temporary
  FROM (SELECT * FROM compare_tables_gtt WHERE location_identifier = 'baseline') b
  FULL OUTER JOIN
       (SELECT * FROM compare_tables_gtt WHERE location_identifier = 'test') t
    ON (b.owner = t.owner AND b.table_name = t.table_name)
 ORDER BY 1,2
/


-- table columns - For readability, this will NOT print missing columns in cases where a table simply 
--                 doesn't exist in the schema.  See the above report for that information.
  WITH column_diffs
    AS (SELECT * 
          FROM compare_table_columns_gtt 
         WHERE (owner, table_name) NOT IN
               (SELECT owner, table_name
                  FROM compare_tables_gtt
                 GROUP BY owner, table_name
                HAVING COUNT(*) = 1))
SELECT COALESCE(b.owner, t.owner)             AS owner,
       COALESCE(b.table_name, t.table_name)   AS table_name, 
       COALESCE(b.column_name, t.column_name) AS column_name, 
       CASE 
         WHEN b.column_name IS NOT NULL AND t.column_name IS NOT NULL THEN 'column exists in both but attributes are changed'
         WHEN b.column_name IS NULL THEN 'column does not exist in baseline'
         WHEN t.column_name IS NULL THEN 'column does not exist in test'  
       END               AS column_status,      
       b.data_type       AS baseline_data_type,      t.data_type       AS test_data_type, 
       b.data_length     AS baseline_data_length,    t.data_length     AS test_data_length,
       b.data_precision  AS baseline_data_precision, t.data_precision  AS test_data_precision,
       b.data_scale      AS baseline_data_scale,     t.data_scale      AS test_data_scale,
       b.nullable        AS baseline_nullable,       t.nullable        AS test_nullable
  FROM (SELECT * FROM column_diffs WHERE location_identifier = 'baseline') b
  FULL OUTER JOIN
       (SELECT * FROM column_diffs WHERE location_identifier = 'test') t
    ON (b.owner = t.owner AND b.table_name= t.table_name AND b.column_name = t.column_name)
 ORDER BY 1,2,3
/
 
          
--views
SELECT COALESCE(b.owner, t.owner) AS owner,
       COALESCE(b.view_name, t.view_name) AS view_name,
       CASE 
         WHEN b.view_name IS NOT NULL AND t.view_name IS NOT NULL THEN 'View exists in both'  --this should not happen
         WHEN b.view_name IS NULL THEN 'View does not exist in baseline'
         WHEN t.view_name IS NULL THEN 'View does not exist in test'
       END AS view_status
  FROM (SELECT * FROM compare_views_gtt WHERE location_identifier = 'baseline') b
  FULL OUTER JOIN
       (SELECT * FROM compare_views_gtt WHERE location_identifier = 'test') t
    ON (b.owner = t.owner AND b.view_name = t.view_name)
 ORDER BY 1,2
/


--view columns
  WITH view_data
    AS (SELECT * FROM compare_view_columns_gtt
         WHERE (owner, view_name) NOT IN
               (SELECT owner, view_name
                  FROM compare_views_gtt))
SELECT COALESCE(b.owner, t.owner)             AS owner,
       COALESCE(b.view_name, t.view_name)     AS view_name, 
       COALESCE(b.column_name, t.column_name) AS column_name, 
       CASE 
         WHEN b.column_name IS NOT NULL AND t.column_name IS NOT NULL THEN 'view column exists in both but attributes are changed'
         WHEN b.column_name IS NULL THEN 'column does not exist in baseline'
         WHEN t.column_name IS NULL THEN 'column does not exist in test'  
       END              AS column_status,      
       b.data_type      AS baseline_data_type,      t.data_type      AS test_data_type,
       b.data_length    AS baseline_data_length,    t.data_length    AS test_data_length,
       b.data_precision AS baseline_data_precision, t.data_precision AS test_data_precision,
       b.data_scale     AS baseline_data_scale,     t.data_scale     AS test_data_scale,
       b.nullable       AS baseline_nullable,       t.nullable       AS test_nullable
  FROM (SELECT * FROM view_data WHERE location_identifier = 'baseline') b
  FULL OUTER JOIN
       (SELECT * FROM view_data WHERE location_identifier = 'test') t
    ON (b.owner = t.owner AND b.view_name = t.view_name AND b.column_name = t.column_name)
 ORDER BY 1,2
/


-- indexes - For readability, this will NOT print missing indexes in cases where a table simply 
--           doesn't exist in the schema.  See the tables report for a list of which tables are missing.
  WITH index_diffs
    AS (SELECT * FROM compare_indexes_gtt
         WHERE (owner, table_name) NOT IN
               (SELECT owner, table_name
                  FROM compare_tables_gtt
                 GROUP BY owner, table_name
                HAVING COUNT(*) = 1))
SELECT COALESCE(b.owner, t.owner)             AS index_owner,
       COALESCE(b.index_name, t.index_name)   AS index_name, 
       COALESCE(b.table_owner, t.table_owner) AS table_owner, 
       COALESCE(b.table_name, t.table_name)   AS table_name, 
       CASE
         WHEN b.index_name IS NOT NULL AND t.index_name IS NOT NULL THEN 'index exists in both but attributes or column list is different'
         WHEN b.index_name IS NULL THEN 'index exists in test but not baseline'
         WHEN t.index_name IS NULL THEN 'index exists in baseline but not test'
       END AS index_status,    
       b.index_type      AS baseline_index_type,      t.index_type      AS test_index_type, 
       b.uniqueness      AS baseline_uniqueness,      t.uniqueness      AS test_uniqueness, 
       b.compression     AS baseline_compression,     t.compression     AS test_compression, 
       b.prefix_length   AS baseline_prefix_length,   t.prefix_length   AS test_prefix_length, 
       b.tablespace_name AS baseline_tablespace_name, t.tablespace_name AS test_tablespace_name, 
       b.status          AS baseline_status,          t.status          AS test_status, 
       b.partitioned     AS baseline_partitioned,     t.partitioned     AS test_partitioned, 
       b.temporary       AS baseline_temporary,       t.temporary       AS test_temporary, 
       b.column_list     AS baseline_column_list,     t.column_list     AS test_column_list
  FROM (SELECT * FROM index_diffs WHERE location_identifier = 'baseline') b
  FULL OUTER JOIN
       (SELECT * FROM index_diffs WHERE location_identifier = 'test') t
    ON (b.table_owner = t.table_owner AND b.table_name = t.table_name AND b.owner = t.owner AND b.index_name = t.index_name)
 ORDER BY 3,4,2
/


--synonmys
  WITH synonym_diffs 
    AS (SELECT * FROM compare_synonyms_gtt
         WHERE (table_owner, table_name) NOT IN
               (SELECT owner, table_name
                          FROM compare_tables_gtt
                         GROUP BY owner, table_name
                        HAVING COUNT(*) = 1)
           AND table_name NOT LIKE 'SOS%'
           AND NOT (table_owner = 'IQPRODD' AND (table_name like 'UDF%VW' OR table_name LIKE '%1' OR table_name LIKE '%2')))
SELECT COALESCE(b.owner, t.owner) AS owner,
       COALESCE(b.synonym_name, t.synonym_name) AS synonym_name,
       CASE
         WHEN b.synonym_name IS NOT NULL AND t.synonym_name IS NOT NULL THEN 'synonym exists in both but points to different object!'
         WHEN b.synonym_name IS NULL THEN 'synonym exists in test but not in baseline'
         WHEN t.synonym_name IS NULL THEN 'synonym exists in baseline but not in test'
       END AS synonym_status,    
       b.table_owner AS baseline_table_owner, t.table_owner AS test_table_owner,
       b.table_name  AS baseline_table_name,  t.table_name  AS test_table_name, 
       b.db_link     AS baseline_db_link,     t.db_link     AS test_db_link
  FROM (SELECT * FROM synonym_diffs WHERE location_identifier='baseline') b
  FULL OUTER JOIN
       (SELECT * FROM synonym_diffs WHERE location_identifier='test') t
    ON (b.owner = t.owner AND b.synonym_name = t.synonym_name)
 ORDER BY 1,3,2
/


