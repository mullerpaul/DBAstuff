SELECT
 bs.username "Blocking User", 
 bs.username "DB User", 
 ws.username "Waiting User", 
 bs.sid "SID", 
 ws.sid "WSID", 
 bs.osuser "Blocking OS User", 
 ws.osuser "Waiting OS User", 
 DECODE(wk.TYPE, 
	'MR', 'Media Recovery',
 	'RT', 'Redo Thread',
	'UN', 'USER Name', 
	'TX', 'Transaction',
 	'TM', 'DML',
	'UL', 'PL/SQL USER LOCK', 
	'DX', 'Distributed Xaction', 
	'CF', 'Control FILE',
	'IS', 'Instance State', 
	'FS', 'FILE SET',
	'IR', 'Instance Recovery',
	'ST', 'Disk SPACE Transaction', 
	'TS', 'Temp Segment', 
	'IV', 'Library Cache Invalidation', 
	'LS', 'LOG START OR Switch',
	'RW', 'ROW Wait',
	'SQ', 'Sequence Number', 
	'TE', 'Extend TABLE',
	'TT', 'Temp TABLE',	wk.TYPE) lock_type, 
DECODE(hk.lmode, 
	0, 'None',
	1, 'NULL',
 	2, 'ROW-S (SS)',
 	3, 'ROW-X (SX)', 
 	4, 'SHARE',
	5, 'S/ROW-X (SSX)',
	6, 'EXCLUSIVE', TO_CHAR(hk.lmode)) mode_held, 
DECODE(wk.request,
	0, 'None',
	1, 'NULL',
 	2, 'ROW-S (SS)',
	3, 'ROW-X (SX)', 
	4, 'SHARE',
	5, 'S/ROW-X (SSX)',
	6, 'EXCLUSIVE', TO_CHAR(wk.request)) mode_requested, 
TO_CHAR(hk.id1) lock_id1, TO_CHAR(hk.id2) lock_id2 
FROM 
   v$lock hk,  v$session bs, v$lock wk,  v$session ws 
WHERE hk.block   = 1
AND  hk.lmode  != 0
AND  hk.lmode  != 1
AND  wk.request  != 0
AND  wk.TYPE (+) = hk.TYPE
AND  wk.id1  (+) = hk.id1
AND  wk.id2  (+) = hk.id2
AND  hk.sid    = bs.sid(+)
AND  wk.sid    = ws.sid(+)
ORDER BY 1;


