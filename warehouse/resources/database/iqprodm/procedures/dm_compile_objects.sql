CREATE OR REPLACE procedure compile_objects
as
begin
DBMS_UTILITY.compile_schema(USER);
end;
/
