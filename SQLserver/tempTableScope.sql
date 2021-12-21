--- need a demo to better understand the scope of SQL Server temp tables
use Paul
SELECT 1 as id, getdate() as c1 into #paultemp;

select * from tempdb.sys.tables;  
select * from tempdb.sys.objects where type = 'U';

--- from doc:  https://docs.microsoft.com/en-us/sql/relational-databases/tables/tables?view=sql-server-ver15
-- Temporary tables are stored in tempdb. There are two types of temporary tables: local and global. 
-- They differ from each other in their names, their visibility, and their availability. Local temporary 
-- tables have a single number sign (#) as the first character of their names; they are visible only to 
-- the current connection for the user, and they are deleted when the user disconnects from the instance 
-- of SQL Server. Global temporary tables have two number signs (##) as the first characters of their names; 
-- they are visible to any user after they are created, and they are deleted when all users referencing the
-- table disconnect from the instance of SQL Server.

-- lets run this select into in a few concurrent sessions using SQLcmd
-- sqlcmd -S localhost -d paul -q "select 1 as id into #paultemp"
-- done!  without any duplicate name errors.  And now I get 3 rows from above queries!  

-- now try with two hashes, for a global temp table
-- sqlcmd -S localhost -d paul -q "select 1 as id into ##paultemp"
--Msg 2714, Level 16, State 6, Server CMS620, Line 1
--There is already an object named '##paultemp' in the database.

--lets try withing a procedure
CREATE OR ALTER PROCEDURE runme
AS
BEGIN
  select 1 as id into #tempTableInProc;
END;

-- I ran that in a few different sessions and never got errors
-- also learned you can use the "GO" batch terminator in sqlcmd with a number argument to run something many times.
--  1> exec runme;
--  2> go 5

--  (1 rows affected)

--  (1 rows affected)

--  (1 rows affected)

--  (1 rows affected)

--  (1 rows affected)


exec runme

drop procedure runme;
drop table #paultemp;
-- apparently temp tables withing procedures are given som system-defined name when run.  So for MULITPLE reasons, we
-- don't need to manually drop them before or after use.
-- reason 1.  They are local temporary if they have one hashmark at the start of the name.  Invisible to other sessions
-- reason 2.  The name is unknown (unpredicatable) anyway.

