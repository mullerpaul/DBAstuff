-- understand SQL server privileges.
-- this page seems like a good starting point:  https://dba.stackexchange.com/questions/131137/effective-sql-server-permissions-when-user-is-in-several-ad-groups
-- descriptions of these views: https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/security-catalog-views-transact-sql?view=sql-server-ver15

--use CCMS
select count(*) from [Salesforce].[VW_ConsultInventory] where 1=0;

select * from sys.login_token;
select * from sys.user_token;

select * from sys.server_principals;
select * from sys.database_principals;

select * from sys.server_permissions;
select * from sys.database_permissions;

select CASE WHEN ut.sid = lt.sid THEN 'Join on SID' ELSE 'Join on Principal_ID' END as joinType,
       lt.*, 
       ut.*
  from sys.user_token ut
       inner join sys.login_token lt 
       on (ut.sid = lt.sid  OR  ut.principal_id = lt.principal_id)
       -- In local DB, SID join returned 1 row, principal join returned 0.
       -- In DW04, neither join returned rows
;