select s.sid, s.username, t.status, to_char(sysdate,'SSSSS') as seconds_since_midnight,
       t.used_ublk as undo_blocks_used, t.used_ublk * 16 / 1024 as undo_mb_used,
       decode(bitand(t.flag,128),0,'NO','YES') rolling_back,
       to_char(logon_time,'Mon-DD hh24:mi:ss') connected,
       to_char(start_date,'Mon-DD hh24:mi:ss') started
from v$session s, v$transaction t
where s.taddr=t.addr
/
