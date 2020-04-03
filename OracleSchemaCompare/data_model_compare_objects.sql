--------------------------------------------------------------------------------------
-- Build objects required for schema compare.
-- 
-- You must edit the schema, password, and SID (or alias) in the create database link
-- commands below.  The schema must have access to dba_tables, dba_view, etc.
--------------------------------------------------------------------------------------
-- database links
DROP DATABASE LINK baseline_location;

CREATE DATABASE LINK baseline_location
CONNECT TO xxxxx          -- schema name
IDENTIFIED BY yyyyy       -- schema password
USING 'qa3_fo';           -- database sid or alias

DROP DATABASE LINK test_location;

CREATE DATABASE LINK test_location
CONNECT TO xxxxx          -- schema name
IDENTIFIED BY yyyyy       -- schema password
USING 'dev1_fo';          -- database sid or alias

-- temp tables
CREATE GLOBAL TEMPORARY TABLE compare_tables_gtt
AS
SELECT 'baseline' AS location_identifier, 
       dt.owner, dt.table_name, dt.tablespace_name, dt.iot_name, dt.iot_type, dt.partitioned, dt.temporary
  FROM dba_tables dt 
 WHERE 1=0; 
 
CREATE GLOBAL TEMPORARY TABLE compare_table_columns_gtt
AS
SELECT 'baseline' AS location_identifier,
       dt.owner, dt.table_name, dtc.column_name, dtc.data_type, 
       dtc.data_length, dtc.data_precision, dtc.data_scale, dtc.nullable
  FROM dba_tables dt,
       dba_tab_columns dtc
 WHERE 1=0;

CREATE GLOBAL TEMPORARY TABLE compare_views_gtt
AS
SELECT 'baseline' AS location_identifier, 
       dv.owner, dv.view_name
  FROM dba_views dv 
 WHERE 1=0;

CREATE GLOBAL TEMPORARY TABLE compare_view_columns_gtt
AS
SELECT 'baseline' AS location_identifier, 
       dv.owner, dv.view_name, dtc.column_name, dtc.data_type, 
       dtc.data_length, dtc.data_precision, dtc.data_scale, dtc.nullable
  FROM dba_views dv, 
       dba_tab_columns dtc 
 WHERE 1=0;
           
CREATE GLOBAL TEMPORARY TABLE compare_indexes_gtt
AS
SELECT 'baseline' AS location_identifier, 
       di.owner, di.index_name, di.index_type, di.table_name, 
       di.table_owner, di.uniqueness, di.compression, di.prefix_length, 
       di.tablespace_name, di.status, di.partitioned, di.temporary, 
       listagg(dic.column_name, ', ') WITHIN GROUP (ORDER BY dic.column_position) AS column_list
  FROM dba_indexes di,
       dba_ind_columns dic
 WHERE 1=0
 GROUP BY di.owner, di.index_name, di.index_type, di.table_name, 
          di.table_owner, di.uniqueness, di.compression, di.prefix_length, 
          di.tablespace_name, di.status, di.partitioned, di.temporary;

CREATE GLOBAL TEMPORARY TABLE compare_synonyms_gtt
AS
SELECT 'baseline' AS location_identifier, 
       owner, synonym_name, table_owner, table_name, db_link
  FROM dba_synonyms
 WHERE 1=0;


--------------------------------------------------------------------------------------
-- Cleanup.  In case we ever need to change the definition of these tables, or you just
-- want to be rid of them, run the following:
--------------------------------------------------------------------------------------
--DROP TABLE compare_tables_gtt;
--DROP TABLE compare_table_columns_gtt;
--DROP TABLE compare_views_gtt;
--DROP TABLE compare_view_columns_gtt;
--DROP TABLE compare_indexes_gtt;
--DROP TABLE compare_synonyms_gtt;

