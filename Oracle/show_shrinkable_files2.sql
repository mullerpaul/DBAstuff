set verify off
col tablespace_name for a25
col file_name for a60
col min_size_mb for a12
REM This script assumes a 16Kb blocksize.  If run on a databse with a different blocksize,
REM you'll have to change the 64s as appropriate.
PROMPT
PROMPT shows all datafiles that can be shrunk by more than 20% for a tablespace
PROMPT or tablespaces.  

select ddf.TABLESPACE_NAME, ddf.file_name, ddf.blocks/64 as current_mb, 
       nvl(to_char(a.min_size_mb),'empty') as min_size_mb
from dba_data_files ddf,
    (select TABLESPACE_NAME, FILE_ID, ceil(max(BLOCK_ID+BLOCKS)/64) as min_size_mb
     from dba_extents
     where TABLESPACE_NAME like '%&tablespace_name%'
     group by TABLESPACE_NAME, FILE_ID) a
where ddf.file_id = a.file_id (+)
and ddf.tablespace_name = a.TABLESPACE_NAME (+)
and ddf.tablespace_name like '%&tablespace_name%'
and nvl(a.min_size_mb,0) < 0.8 * ddf.blocks/64
order by ddf.TABLESPACE_NAME, ddf.file_id
/

set verify on
undefine tablespace_name

