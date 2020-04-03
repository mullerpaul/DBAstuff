select s.sid,s.serial#,p.spid as os_process_id,s.status,s.username,
       round(p.pga_used_mem/(1024*1024),2) as pga_used_mb, 
       round(p.pga_max_mem/(1024*1024),2) as pga_max_mb
from v$session s, v$process p
where p.addr=s.paddr
order by 6
/
