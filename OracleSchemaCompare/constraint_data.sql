--constraint info query
SELECT dc.owner, CASE WHEN dc.constraint_name LIKE 'SYS\_%' ESCAPE '\' THEN 'system_generated_name' ELSE dc.constraint_name END AS constraint_name, 
       dc.constraint_type, dc.table_name, dc.status, dc.deferrable, dc.deferred, dc.validated, dcc.column_name, dcc.position
  FROM dba_constraints@test_location dc, 
       dba_cons_columns@test_location dcc
 WHERE dc.constraint_name = dcc.constraint_name
   AND dc.owner = dcc.owner
   AND dc.owner IN ('IQPROD','IQPRODD','IQPRODR')
   AND dc.table_name NOT LIKE 'BIN$%'
   AND dc.table_name NOT LIKE 'SOS%'
   AND NOT (dc.owner = 'IQPRODD' AND (dc.table_name LIKE '%1' OR dc.table_name LIKE '%2'))
                     
          
      
