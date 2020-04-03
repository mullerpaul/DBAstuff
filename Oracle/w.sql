col username for a22
col user_action for a54

select sid,serial#,status,username,osuser||':'||program as user_action
from v$session
where username is not null
order by username,sid
/

col username for a30

