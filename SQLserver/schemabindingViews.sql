DROP TABLE base_t;
DROP VIEW view_schemabinding;
DROP VIEW view_noschemabinding;

CREATE TABLE base_t (
  ID    int not null,
  attr1 date,
  attr2 varchar(20),
  constraint bast_t_pk primary key (id)
  );

CREATE VIEW view_schemabinding
WITH schemabinding
AS
SELECT ID, attr1, attr2 
--  FROM base_t
  FROM dbo.base_t   -- need to specify dbo for the schemabinding to work
;

CREATE VIEW view_noschemabinding
AS
SELECT ID, attr1, attr2 
  FROM base_t  -- this works for no schemabinding
--  FROM dbo.base_t
;

-- also CREATE VIEW must be first command in batch - so either run those one at a time, or put a "GO" between them

-- we can add a column if either view is present
alter table base_t add attr3 int not null;

-- but removing a referenced column fails with the following error if the schemabinding view exists: 
alter table base_t drop column attr1; 
--Msg 5074, Level 16, State 1, Line 32
--The object 'view_schemabinding' is dependent on column 'attr1'.

select * from view_schemabinding;

-- Now, with no schema binding, if we make a change which invalidates the view, we get the following error AT QUERY TIME (not DDL time)
select * from view_noschemabinding;
-- Msg 207, Level 16, State 1, Procedure view_noschemabinding, Line 3 [Batch Start Line 37]
-- Invalid column name 'attr1'.
-- Msg 4413, Level 16, State 1, Line 38
-- Could not use view or function 'view_noschemabinding' because of binding errors.

-- how can we know in advance if a view is schemabinding or not?
select * from INFORMATION_SCHEMA.VIEWS;  -- strangely not here!
select * from INFORMATION_SCHEMA.TABLES WHERE table_type = 'VIEW';  --not here either

select * from sys.views;  --not here
select * from sys.tables;  --not here

select * from sys.sql_modules;  -- yes!  the is_schema_bound column!  and a few other useful columns

select s.[name] as SchemaName, 
       v.[name] as ViewName,
       sm.is_schema_bound,
       sm.uses_ansi_nulls,
       sm.uses_quoted_identifier,
       CASE WHEN EXISTS (select 1 from sys.indexes i where i.[object_id] = v.[object_id]) THEN 1 ELSE 0 END as is_indexed
  from sys.views v
       inner join sys.schemas s on s.[schema_id] = v.[schema_id]
       left outer join sys.sql_modules sm on sm.[object_id] = v.[object_id]  -- perhaps inner is OK here?
 order by 1,2;

-- can we reproduce the data conversion runtime errors mike and I saw?
-- it looked more like a date conversion error - i thought it was bad data in a text field which we were trying to cast to date.