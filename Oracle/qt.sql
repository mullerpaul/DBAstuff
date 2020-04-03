select f.name as filename, bytes/(1024*1024) as mbytes, t.name as tablespace
from v$tempfile f, v$tablespace t
where f.ts#=t.ts#
order by 3
/
