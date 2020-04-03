-- tables
SELECT dt.owner, dt.table_name, dt.tablespace_name, dt.iot_name, dt.iot_type, dt.partitioned, dt.temporary
  FROM dba_tables dt 
 WHERE dt.owner IN ('IQPROD','IQPRODD','IQPRODR')
   AND dt.table_name NOT LIKE 'SOS%'
   AND NOT (dt.owner = 'IQPRODD' AND (dt.table_name LIKE '%1' OR dt.table_name LIKE '%2'));
   
-- columns
SELECT dtc.owner, dtc.table_name, dtc.column_name, dtc.column_id, dtc.data_type, 
       dtc.data_length, dtc.data_precision, dtc.data_scale, dtc.nullable
  FROM dba_tab_columns dtc
 WHERE dtc.owner IN ('IQPROD','IQPRODD','IQPRODR')
   AND dtc.table_name NOT LIKE 'SOS%'
   AND dtc.table_name NOT LIKE 'BIN$%'
   AND NOT (dtc.owner = 'IQPRODD' AND (dtc.table_name LIKE '%1' OR dtc.table_name LIKE '%2'));
   
-- views and columns
SELECT dv.owner, dv.view_name, dtc.column_name, dtc.column_id, dtc.data_type, 
       dtc.data_length, dtc.data_precision, dtc.data_scale, dtc.nullable
  FROM dba_views dv, 
       dba_tab_columns dtc 
 WHERE dv.view_name = dtc.table_name
   AND dv.owner = dtc.owner
   AND dv.owner IN ('IQPROD','IQPRODD','IQPRODR')
   AND NOT (dt.owner = 'IQPRODD' AND dv.view_name LIKE 'UDF%');
   
-- indexes and indexed columns
SELECT di.owner, CASE WHEN di.index_name LIKE 'SYS\_%' ESCAPE '\' THEN 'system_generated_name' ELSE di.index_name END AS index_name, 
       di.index_type, di.table_name, di.table_owner, di.uniqueness, di.compression, di.prefix_length, 
       di.tablespace_name, di.status, di.partitioned, di.temporary, dic.column_position, dic.column_name
  FROM dba_indexes di,
       dba_ind_columns dic
 WHERE di.index_name = dic.index_name
   AND di.owner = dic.index_owner
   AND di.table_owner IN ('IQPROD','IQPRODD','IQPRODR')
   AND di.table_name NOT LIKE 'SOS%'
   AND NOT (di.owner = 'IQPRODD' AND (di.table_name LIKE '%1' OR di.table_name LIKE '%2'));
       
-- constraints and constraint columns
SELECT dc.owner, CASE WHEN dc.constraint_name LIKE 'SYS\_%' ESCAPE '\' THEN 'system_generated_name' ELSE dc.constraint_name END AS constraint_name, 
       dc.constraint_type, dc.table_name, dc.status, dc.deferrable, dc.deferred, dc.validated, dcc.column_name, dcc.position
  FROM dba_constraints dc, 
       dba_cons_columns dcc
 WHERE dc.constraint_name = dcc.constraint_name
   AND dc.owner = dcc.owner
   AND dc.owner IN ('IQPROD','IQPRODD','IQPRODR')
   AND dc.table_name NOT LIKE 'BIN$%'
   AND dc.table_name NOT LIKE 'SOS%'
   AND NOT (dc.owner = 'IQPRODD' AND (dc.table_name LIKE '%1' OR dc.table_name LIKE '%2'));

-- synonyms
SELECT owner, synonym_name, table_owner, table_name, db_link
  FROM dba_synonyms
 WHERE table_owner IN ('IQPROD','IQPRODD','IQPRODR')  -- only synonyms for application objects
   AND owner IN ('IQPROD','IQPRODD','IQPRODR','RO_IQPROD','RO_IQPRODD','RO_IQPRODR','PUBLIC');  --only synonyms for these 6 schema and public synonyms


