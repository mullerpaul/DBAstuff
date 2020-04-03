-- Finds locks which prevent other session from compiling packages.
-- Run these three queries in sequence.  The second needs output from
-- the first, and the third needs output from the second.
--
-- I've often seen the session holding the lock have a status of KILLED.
-- In these cases, I don't know what to do other than restart the database.

select sid,event, p1raw, p2raw from v$session_wait where event like 'library%';

select * from dba_kgllock where kgllkreq != 0 or kgllkhdl = 'P1RAW from above';

select sid,serial#,status,username,osuser from v$session where saddr in ('KGLLKUSE from above');

-- OR to combine those into just one query....

select sid,serial#,status,username,osuser
from v$session
where saddr in
 (select KGLLKUSE 
  from dba_kgllock 
  where kgllkreq != 0 or kgllkhdl in
  (select p1raw 
   from v$session_wait 
   where event like 'library%'));

