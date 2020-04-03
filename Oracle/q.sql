select f.name as filename, bytes/(1024*1024) as mbytes, t.name as tablespace
from v$datafile f, v$tablespace t
where f.ts#=t.ts#
and t.name like '%' || upper('&tablespace_name') || '%'
order by 3
/
undefine tablespace_name
