use PaulAzuraSQLDatabase
-- confirm row_number() works like oracle ROWNUM.  
select ROW_NUMBER() OVER (ORDER BY a.object_id) as id
  from sys.all_objects a cross join sys.all_objects b
  ;
-- Yes, but it appears to be an analytic function instead of a pseudocolumn.  That might make it relatively slow.  We'll see.


-- load table with sample data
-- note wierd syntax:  The INTO clause causes this to create a table without using the CREATE TABLE syntax!!
select ROW_NUMBER() OVER (ORDER BY a.object_id) as id,
       CAST(DATEADD(second, cast(crypt_gen_random(2) as INT), DATEADD(day, cast(crypt_gen_random(1) as INT), '2019-01-01')) as datetime2) as message_timestamp,
	   newid() as message_guid,
	   cast(NULL as uniqueidentifier) as client_guid,
	   cast(NULL as uniqueidentifier) as object_guid
  into data_unclustered
  from sys.all_objects a cross join sys.all_objects b
  ;

-- check data
select count(*), 
       count(id), count(distinct id),
       count(message_timestamp), count(distinct message_timestamp),
       count(message_guid), count(distinct message_guid),
       count(client_guid), count(distinct client_guid),
       count(object_guid), count(distinct object_guid)
  from data_unclustered;
-- looks good.  Got some dupes for timestamp!  Thats good


-- make and load table of sample clients
CREATE TABLE client_master
 (client_id INT,
  client_name varchar(30),
  client_guid uniqueidentifier);

begin transaction;
INSERT INTO client_master VALUES (1, 'Amazon', newid());
INSERT INTO client_master VALUES (2, 'Accenture', newid());
INSERT INTO client_master VALUES (3, 'Shell', newid());
INSERT INTO client_master VALUES (4, 'Microsoft', newid());
INSERT INTO client_master VALUES (5, 'Jeppesen', newid());
INSERT INTO client_master VALUES (6, 'Schwab', newid());
INSERT INTO client_master VALUES (7, 'Caterpillar', newid());
INSERT INTO client_master VALUES (8, 'Marsh and McClellan', newid());
INSERT INTO client_master VALUES (9, 'DeLoit', newid());
INSERT INTO client_master VALUES (10, 'NG', newid());
commit transaction;

-- use those guids to update the client_guid col in the main table
UPDATE data_unclustered du
   SET du.client_guid = (select client_guid 
                        from client_master c 
                       where c.client_id = CASE 
					                         WHEN du.id % 20 < 5 THEN 2
					                         WHEN du.id % 20 < 9 THEN 3
					                         WHEN du.id % 20 < 11 THEN 1
					                         WHEN du.id % 20 < 13 THEN 4
					                         WHEN du.id % 20 < 14 THEN 5
--					                         WHEN < 15 THEN 6
	--				                         WHEN < 16 THEN 7
		--			                         WHEN < 17 THEN 8
			--		                         WHEN < 18 THEN 9
					                         ELSE 10
                                           END),
       object_guid = newid();
-- I cant figure out this correlated subquery update!  It must be possible; but I'm doing something wrong.
-- Instead try doing it as an updateable join
  with joined_data
    as (select du.id, du.client_guid, du.object_guid, c.client_name, c.client_guid as client_guid_source
          from data_unclustered du join client_master c 
            on c.client_id = CASE 
        	                   WHEN du.id % 20 < 5 THEN 2
	                           WHEN du.id % 20 < 9 THEN 3
	                           WHEN du.id % 20 < 11 THEN 1
	                           WHEN du.id % 20 < 13 THEN 4
        	                   WHEN du.id % 20 < 14 THEN 5
	                           WHEN du.id % 20 < 15 THEN 6
	                           WHEN du.id % 20 < 16 THEN 7
	                           WHEN du.id % 20 < 17 THEN 8
        	                   WHEN du.id % 20 < 18 THEN 9
	                           ELSE 10
                             END)
update joined_data
   SET client_guid = client_guid_source,
       object_guid = newid ();
-- that worked!
commit;

-- check data distribution
select c.client_name,count(*)
  from data_unclustered du join client_master c on du.client_guid = c.client_guid
 group by c.client_name
 order by 2 desc;
-- looks like we got a nice skew there!


-- add some constraints - just to see if I can
-- more wierd syntax - it appears you HAVE TO include the datatype in these statements, even if (as here) you are not changing it.
-- Also, I can't find a way to do this in one statement.  Thats a problem here as this will now require 5 full table scans instead of one.
alter table data_unclustered alter column id bigint not null;
alter table data_unclustered alter column message_timestamp datetime2 not null;
alter table data_unclustered alter column message_guid uniqueidentifier not null;
alter table data_unclustered alter column client_guid uniqueidentifier not null;
alter table data_unclustered alter column object_guid uniqueidentifier not null;

         
-- a little experimetning with system tables so we can see storage details about our table (and any partitions/indexes we add later)
select * from sys.schemas;
select * from sys.tables;
select * from sys.partitions;
select * from sys.allocation_units;

-- modified this query from one created by Jonathan Lewis here: https://www.red-gate.com/simple-talk/sql/learn-sql-server/oracle-to-sql-server-crossing-the-great-divide-part-3/
select t.name, t.type, t.create_date, 
       p.partition_id, p.partition_number, p.index_id, p.rows, 
	   au.allocation_unit_id, au.type_desc, au.data_space_id, 
	   8 * au.total_pages as total_kb, 
	   8 * au.used_pages as used_kb, 
	   8 * au.data_pages as data_kb
  from sys.tables t 
       inner join sys.partitions p on p.object_id = t.object_id
	   inner join sys.allocation_units au on au.container_id = p.partition_id
 order by t.name, p.partition_id, p.index_id, au.allocation_unit_id;       

-- OK, I've been reading SQLServer docs and realized I need to understand Heap tables,
-- clustered indexes, and unclustered iondexes.  
-- BTW, "heap table" means something similar to; but not exactly same as what it means in Oracle RDBMS

--So, to understand, lets create 3 versions of our data:
-- 1. "heap table" with no indexes
-- 2. same table but with an unclustered index.  I think this still makes it a heap table
-- 3. same table but with a clustered index.  I think this makes it NOT a heap any longer.

select id,
       message_timestamp,
	   message_guid,
	   client_guid,
	   object_guid
  into data_heap
  from data_unclustered;

select id,
       message_timestamp,
	   message_guid,
	   client_guid,
	   object_guid
  into data_non_heap
  from data_unclustered;


create nonclustered index data_heap_idx01     on data_heap     ( message_guid );
create    clustered index data_non_heap_idx01 on data_non_heap ( message_guid );

-- now lets use that query again to see how the three tables are different.
select t.name, t.type, t.create_date, 
       p.partition_id, p.partition_number, p.index_id, p.rows, 
	   au.allocation_unit_id, au.type_desc, au.data_space_id, 
	   8 * au.total_pages as total_kb, 
	   8 * au.used_pages as used_kb, 
	   8 * au.data_pages as data_kb
  from sys.tables t 
       inner join sys.partitions p on p.object_id = t.object_id
	   inner join sys.allocation_units au on au.container_id = p.partition_id
 where t.name like 'data%'
-- order by t.name, p.partition_id, p.index_id, au.allocation_unit_id
 order by t.create_date, p.partition_id, p.index_id, au.allocation_unit_id
;

-- so with the indexes, we have 2 partitions and allocation units for the heap table with index.  Not suprising.
-- also, only 1 partition/allocation unit for the clustered index.  This confirms that "clustered index" tables are similar to 
-- Oracle "IOT"s (index-organized tables) in that the "table" is actually kind-of an index in that the rows are located or sorted 
-- on disk in order of the index key. So i expect that like Oracle IOTs, the clustered index makes access by index very fast.

-- lets do a few access by index queries againt all three copies.

-- also have to figure out how to look at execution plans and execution statistics now.
select * from data_unclustered where message_guid = '73F12C03-AD01-4D82-B3AB-A8ADC0EDBA37';
select * from data_heap        where message_guid = '73F12C03-AD01-4D82-B3AB-A8ADC0EDBA37';
select * from data_non_heap    where message_guid = '73F12C03-AD01-4D82-B3AB-A8ADC0EDBA37';

-- As expected, the tables where the query can use an indexes are a lot faster than the one without. 

-- After much googling, I figured out a way to get text-based execution plans instead of the GUI based ones available in SSMS.
-- I created a SQL script and ran it via SQLCMD, the SQL*Plus-like command line tool for SQL Server.
-- here is the output from SQLCMD - using "set showplan all" to get the plans.
Changed database context to 'PaulAzureSQLDatabase'.
StmtText                                                                                                                                                                                     StmtId      NodeId      Parent      PhysicalOp                     LogicalOp                      Argument                                                                                                                                                                    DefinedValues                                                                                                                                                                                                                                                                                                            EstimateRows   EstimateIO     EstimateCPU    AvgRowSize  TotalSubtreeCost OutputList                                                                                                                                                                                                                                                                                                               Warnings Type                                                             Parallel EstimateExecutions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------- ----------- ----------- ------------------------------ ------------------------------ --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ -------------- -------------- -------------- ----------- ---------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ -------- ---------------------------------------------------------------- -------- ------------------

select * from data_unclustered where message_guid = '73F12C03-AD01-4D82-B3AB-A8ADC0EDBA37'                                                                                                           1           1           0 NULL                           NULL                           1                                                                                                                                                                           NULL                                                                                                                                                                                                                                                                                                                          1.0000564           NULL           NULL        NULL        10.674526 NULL                                                                                                                                                                                                                                                                                                                     NULL     SELECT                                                                  0               NULL
  |--Table Scan(OBJECT:([PaulAzureSQLDatabase].[dbo].[data_unclustered]), WHERE:([PaulAzureSQLDatabase].[dbo].[data_unclustered].[message_guid]=CONVERT_IMPLICIT(uniqueidentifier,[@1],0)))            1           2           1 Table Scan                     Table Scan                     OBJECT:([PaulAzureSQLDatabase].[dbo].[data_unclustered]), WHERE:([PaulAzureSQLDatabase].[dbo].[data_unclustered].[message_guid]=CONVERT_IMPLICIT(uniqueidentifier,[@1],0))  [PaulAzureSQLDatabase].[dbo].[data_unclustered].[id], [PaulAzureSQLDatabase].[dbo].[data_unclustered].[message_timestamp], [PaulAzureSQLDatabase].[dbo].[data_unclustered].[message_guid], [PaulAzureSQLDatabase].[dbo].[data_unclustered].[client_guid], [PaulAzureSQLDatabase].[dbo].[data_unclustered].[object_guid]       1.0000564      9.3794212      1.2951045          71        10.674526 [PaulAzureSQLDatabase].[dbo].[data_unclustered].[id], [PaulAzureSQLDatabase].[dbo].[data_unclustered].[message_timestamp], [PaulAzureSQLDatabase].[dbo].[data_unclustered].[message_guid], [PaulAzureSQLDatabase].[dbo].[data_unclustered].[client_guid], [PaulAzureSQLDatabase].[dbo].[data_unclustered].[object_guid]  NULL     PLAN_ROW                                                                0                1.0

(2 rows affected)
StmtText                                                                                                                                                                                                                StmtId      NodeId      Parent      PhysicalOp                     LogicalOp                      Argument                                                                                                                                                                                          DefinedValues                                                                                                                                                                                                                EstimateRows   EstimateIO     EstimateCPU    AvgRowSize  TotalSubtreeCost OutputList                                                                                                                                                                                                                                                                            Warnings Type                                                             Parallel EstimateExecutions
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------- ----------- ----------- ------------------------------ ------------------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -------------- -------------- -------------- ----------- ---------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -------- ---------------------------------------------------------------- -------- ------------------

select * from data_heap        where message_guid = '73F12C03-AD01-4D82-B3AB-A8ADC0EDBA37'                                                                                                                                      1           1           0 NULL                           NULL                           1                                                                                                                                                                                                 NULL                                                                                                                                                                                                                                    1.0           NULL           NULL        NULL     6.5703802E-3 NULL                                                                                                                                                                                                                                                                                  NULL     SELECT                                                                  0               NULL
  |--Nested Loops(Inner Join, OUTER REFERENCES:([Bmk1000]))                                                                                                                                                                       1           2           1 Nested Loops                   Inner Join                     OUTER REFERENCES:([Bmk1000])                                                                                                                                                                      NULL                                                                                                                                                                                                                                    1.0            0.0   4.1799999E-6          71     6.5703802E-3 [PaulAzureSQLDatabase].[dbo].[data_heap].[id], [PaulAzureSQLDatabase].[dbo].[data_heap].[message_timestamp], [PaulAzureSQLDatabase].[dbo].[data_heap].[message_guid], [PaulAzureSQLDatabase].[dbo].[data_heap].[client_guid], [PaulAzureSQLDatabase].[dbo].[data_heap].[object_guid]  NULL     PLAN_ROW                                                                0                1.0
       |--Index Seek(OBJECT:([PaulAzureSQLDatabase].[dbo].[data_heap].[data_heap_idx01]), SEEK:([PaulAzureSQLDatabase].[dbo].[data_heap].[message_guid]={guid'73F12C03-AD01-4D82-B3AB-A8ADC0EDBA37'}) ORDERED FORWARD)            1           3           2 Index Seek                     Index Seek                     OBJECT:([PaulAzureSQLDatabase].[dbo].[data_heap].[data_heap_idx01]), SEEK:([PaulAzureSQLDatabase].[dbo].[data_heap].[message_guid]={guid'73F12C03-AD01-4D82-B3AB-A8ADC0EDBA37'}) ORDERED FORWARD  [Bmk1000], [PaulAzureSQLDatabase].[dbo].[data_heap].[message_guid]                                                                                                                                                                      1.0       0.003125      0.0001581          31        0.0032831 [Bmk1000], [PaulAzureSQLDatabase].[dbo].[data_heap].[message_guid]                                                                                                                                                                                                                    NULL     PLAN_ROW                                                                0                1.0
       |--RID Lookup(OBJECT:([PaulAzureSQLDatabase].[dbo].[data_heap]), SEEK:([Bmk1000]=[Bmk1000]) LOOKUP ORDERED FORWARD)                                                                                                        1           5           2 RID Lookup                     RID Lookup                     OBJECT:([PaulAzureSQLDatabase].[dbo].[data_heap]), SEEK:([Bmk1000]=[Bmk1000]) LOOKUP ORDERED FORWARD                                                                                              [PaulAzureSQLDatabase].[dbo].[data_heap].[id], [PaulAzureSQLDatabase].[dbo].[data_heap].[message_timestamp], [PaulAzureSQLDatabase].[dbo].[data_heap].[client_guid], [PaulAzureSQLDatabase].[dbo].[data_heap].[object_guid]             1.0       0.003125      0.0001581          55        0.0032831 [PaulAzureSQLDatabase].[dbo].[data_heap].[id], [PaulAzureSQLDatabase].[dbo].[data_heap].[message_timestamp], [PaulAzureSQLDatabase].[dbo].[data_heap].[client_guid], [PaulAzureSQLDatabase].[dbo].[data_heap].[object_guid]                                                           NULL     PLAN_ROW                                                                0                1.0

(4 rows affected)
StmtText                                                                                                                                                                                                                              StmtId      NodeId      Parent      PhysicalOp                     LogicalOp                      Argument                                                                                                                                                                                                   DefinedValues                                                                                                                                                                                                                                                                                             EstimateRows   EstimateIO     EstimateCPU    AvgRowSize  TotalSubtreeCost OutputList                                                                                                                                                                                                                                                                                                Warnings Type                                                             Parallel EstimateExecutions
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------- ----------- ----------- ------------------------------ ------------------------------ ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -------------- -------------- -------------- ----------- ---------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -------- ---------------------------------------------------------------- -------- ------------------

select * from data_non_heap    where message_guid = '73F12C03-AD01-4D82-B3AB-A8ADC0EDBA37'                                                                                                                                                    1           1           0 NULL                           NULL                           1                                                                                                                                                                                                          NULL                                                                                                                                                                                                                                                                                                                 1.0           NULL           NULL        NULL        0.0032831 NULL                                                                                                                                                                                                                                                                                                      NULL     SELECT                                                                  0               NULL
  |--Clustered Index Seek(OBJECT:([PaulAzureSQLDatabase].[dbo].[data_non_heap].[data_non_heap_idx01]), SEEK:([PaulAzureSQLDatabase].[dbo].[data_non_heap].[message_guid]=CONVERT_IMPLICIT(uniqueidentifier,[@1],0)) ORDERED FORWARD)            1           2           1 Clustered Index Seek           Clustered Index Seek           OBJECT:([PaulAzureSQLDatabase].[dbo].[data_non_heap].[data_non_heap_idx01]), SEEK:([PaulAzureSQLDatabase].[dbo].[data_non_heap].[message_guid]=CONVERT_IMPLICIT(uniqueidentifier,[@1],0)) ORDERED FORWARD  [PaulAzureSQLDatabase].[dbo].[data_non_heap].[id], [PaulAzureSQLDatabase].[dbo].[data_non_heap].[message_timestamp], [PaulAzureSQLDatabase].[dbo].[data_non_heap].[message_guid], [PaulAzureSQLDatabase].[dbo].[data_non_heap].[client_guid], [PaulAzureSQLDatabase].[dbo].[data_non_heap].[object_guid]             1.0       0.003125      0.0001581          71        0.0032831 [PaulAzureSQLDatabase].[dbo].[data_non_heap].[id], [PaulAzureSQLDatabase].[dbo].[data_non_heap].[message_timestamp], [PaulAzureSQLDatabase].[dbo].[data_non_heap].[message_guid], [PaulAzureSQLDatabase].[dbo].[data_non_heap].[client_guid], [PaulAzureSQLDatabase].[dbo].[data_non_heap].[object_guid]  NULL     PLAN_ROW                                                                0                1.0

(2 rows affected)


--The clusterred index just needs one operation since the index and the table are the same object (the table is re-orged to be ordered by the index)
--The non-clustered index takes two lookups - one to hit the index and get the row location, the other to go to that location and get the row.  
--Even with two I/Os, this is still orders of magnitude faster than no index, as that has to read the whole table to find the row!  (about 100Mb)


-- I've been wondering about clustered indexes and if they are always the table PK.  Then this morning I found this in the doc:
-- https://docs.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide?view=sqlallproducts-allversions

-- "If not specified differently, when creating a PRIMARY KEY constraint, SQL Server creates a clustered index to support that constraint. 
--  Although a uniqueidentifier can be used to enforce uniqueness as a PRIMARY KEY, it is not an efficient clustering key. If using a 
--  uniqueidentifier as PRIMARY KEY, the recommendation is to create it as a nonclustered index, and use another column such as an IDENTITY 
--  to create the clustered index."

-- BOOM!  Glad to know that has been considered, and that is an option.
-- Incidentally, I'm not sure its possible in Oracle to create an IOT and have the index NOT be the PK.  Will look into it later.


--anyway, now lets try some partitioning strategies
-- I don't yet know if we can partition indexes as well as tables.  Lets see
-- also experiment with partitions with cluster indexes
-- and partitions with SUB-partitions (does that exist?)

-- partitioning is much harder in SQLServer as compared to Oracle.  Oracle DOES have some convoluted syntax; but in SQLServer
-- it appears we have to create new objects to accomplish the partitioning.
CREATE PARTITION FUNCTION paulPartRange (datetime2)
AS RANGE RIGHT 
FOR VALUES ( '20190101','20190201','20190301','20190401','20190501','20190601',
             '20190701','20190801','20190901','20191001','20191101','20191201' );

-- test it out!
select $PARTITION.paulPartRange ('20191004');  -- 11
select $PARTITION.paulPartRange ('20191101');  -- 12 
select $PARTITION.paulPartRange ('20181101');  -- 1  I guess anything before Jan 01 2019 is partition 1
select $PARTITION.paulPartRange ('20210202');  -- 13 and anything after Dec 1st 2019 is partition 13 
-- good enough for now!


-- I don't yet fully understand this statement.  
-- got syntax here: https://docs.microsoft.com/en-us/sql/t-sql/statements/create-partition-scheme-transact-sql?view=sql-server-2017
CREATE PARTITION SCHEME paulPartScheme
AS PARTITION paulPartRange
ALL TO ( [PRIMARY] );

-- now create table using the scheme
CREATE TABLE data_partition
  (id                bigint,
   message_timestamp datetime2,
   message_guid      uniqueidentifier,
   client_guid       uniqueidentifier,
   object_guid       uniqueidentifier)
ON paulPartScheme (message_timestamp);

INSERT INTO data_partition
SELECT id,
       message_timestamp,
       message_guid,
       client_guid,
       object_guid
  from data_unclustered;

-- now lets use that query again to see how the three tables are different.
select t.name, t.type, t.create_date, 
       p.partition_id, p.partition_number, p.index_id, p.rows, 
	   au.allocation_unit_id, au.type_desc, au.data_space_id, 
	   8 * au.total_pages as total_kb, 
	   8 * au.used_pages as used_kb, 
	   8 * au.data_pages as data_kb
  from sys.tables t 
       inner join sys.partitions p on p.object_id = t.object_id
	   inner join sys.allocation_units au on au.container_id = p.partition_id
 where t.name like 'data%'
-- order by t.name, p.partition_id, p.index_id, au.allocation_unit_id
 order by t.create_date, p.partition_id, p.index_id, au.allocation_unit_id
;





--scratch queries
select ROW_NUMBER() OVER (ORDER BY a.object_id) as id,
       round(rand() * 365, 0) as random_offset,
	   cast(crypt_gen_random(2) as INT) as random_bytes	   
  from sys.all_objects a
  order by 3 desc;

-- One can do arithmatic without the "FROM dual" which is required in Oracle!  Thats nice.
-- I used these calculations to figure out the randomized time setup in the data creation step.
select 256*256  as two_byte_random,  -- 65536
       24*60    as minutes_per_day,  -- 1440
	   24*60*60 as sec_per_day       -- 86400
	   ;


select 	id , id % 20 from data_unclustered;

select * from client_master;



CREATE TABLE client_master
 (client_id INT,
  client_name varchar(30),
  client_guid uniqueidentifier);

CREATE TABLE timecard
  (client_id        uniqueidentifier not null,
   timecard_id      uniqueidentifier not null,
   create_timestamp datetime2        not null,
   status           varchar(12),
   contractor_name  varchar(60));

 -- A "clustered index" forces the DB engine to store table data on disk in the order specified in the key.
 -- its often good to specify an order/query key that is used frequently in queries.
 -- in this case, I've chosen client_id as the leading edge so that data from a given client will be 
 -- stored "near" other data from the client (in the same page).
 
create clustered index timecard_pk on timecard ( client_id, timecard_id );
