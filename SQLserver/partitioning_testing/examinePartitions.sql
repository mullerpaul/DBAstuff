---- DDL to add NEW partition key to partitioning scheme and function
--ALTER PARTITION SCHEME EnvironmentNamePs NEXT USED [Primary];
--ALTER PARTITION FUNCTION EnvironmentNamePf() SPLIT RANGE (@NewClientEnvName);

---- look at existing partitions in partitioning function
SELECT pf.name, pf.type_desc, pf.fanout,
       prv.boundary_id, prv.value 
  FROM sys.partition_range_values prv 
       JOIN sys.partition_functions pf ON pf.function_id = prv.function_id
 WHERE pf.name = 'EnvironmentNamePf'
;

---- look at existing partitions on TABLES
SELECT o.name as [tableName], o.type_desc as [objectType], 
       p.partition_number, 
       CASE
         WHEN p.partition_number = 1 then 'QA217'
         WHEN p.partition_number = 2 then 'QA218'
         ELSE '??'
       END,  
       --p.index_id, 
       p.rows
  FROM sys.partitions p
       JOIN sys.objects o on (p.object_id = o.object_id)
 WHERE o.name in ('Stage','Target')
 ORDER by o.name, p.partition_number
;

SELECT * FROM [Stage];
SELECT * FROM [Target];

