select s.osuser, o.object_name
from v$lock v, v$session s, dba_objects o
where v.SID = s.sid
and v.ID1 = o.object_id
and o.object_type = 'TABLE'
and o.object_name like '%GT'
/

