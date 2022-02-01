select s.name as SchemaName, 
       o.name as ObjectName, o.type_desc as ObjectType, o.is_ms_shipped,
       c.name as ColumnName, c.column_id, c.is_nullable
  from sys.objects o
       inner join sys.schemas s on o.schema_id = s.schema_id
       inner join sys.columns c on o.object_id = c.object_id
 where 1=1
   --and s.name = 'dbo'
   --and t.name = 'VW_Sales_Activity'
   and c.name like '%pipeline%callback%'
 order by s.name, o.name, c.column_id
;
