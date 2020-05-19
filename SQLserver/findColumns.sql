select s.name as schemaName, 
       o.name as tableName, 
	   c.name as columnName, c.column_id
  from sys.schemas s 
       join sys.objects o on (s.schema_id = o.schema_id)
	   join sys.columns c on (o.object_id = c.object_id)
 where 1=1
   and s.name = 'dbo'
   and c.name like '%REMOVAL_TI%'
 order by 1,2,4;
