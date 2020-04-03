COLUMN event FORMAT   a50
COLUMN wait_class FORMAT   a16

select WAIT_CLASS, EVENT, TOTAL_WAITS, TIME_WAITED, AVERAGE_WAIT
from v$session_event
where sid= &sid
order by 4
/

