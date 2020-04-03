set verify off
col file_name for a70
REM This script assumes a 16Kb blocksize.  If run on a databse with a different blocksize,
REM you'll have to change the 64s as appropriate.
PROMPT
PROMPT shows all datafiles that can be shrunk by more than 20% for a given tablespace

select ddf.file_name, ddf.blocks/64 as current_mb, a.min_size_mb
from dba_data_files ddf,
    (select FILE_ID, ceil(max(BLOCK_ID+BLOCKS)/64) as min_size_mb
     from dba_extents
     where TABLESPACE_NAME = '&&tablespace_name'
     group by FILE_ID) a
where a.file_id = ddf.file_id
and ddf.tablespace_name = '&&tablespace_name'
and a.min_size_mb < 0.8 * ddf.blocks/64
order by ddf.file_id
/

set verify on
undefine tablespace_name

