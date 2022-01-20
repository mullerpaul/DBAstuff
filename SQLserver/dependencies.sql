-- try to understand dependencies listed in sys.sql_expression_dependencies
--  see https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sql-expression-dependencies-transact-sql

select * from sys.sql_expression_dependencies
select * from sys.objects

