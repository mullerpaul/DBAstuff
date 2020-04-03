SELECT username, session_num AS serial#, tablespace, 
       segtype, extents, blocks/64 AS mbytes
FROM v$tempseg_usage
/
