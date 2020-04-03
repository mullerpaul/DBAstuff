col name for a54
select disktype, name, phyrds as total_reads, singleblkrds as single_block_reads,
       10*singleblkrdtim/singleblkrds as avg_single_block_read_time_ms,
       10*maxiortm as max_single_read_time_ms
from v$filestat,
    (select file#, name,
            case when substr(name,2,2) = 'sd' then 'SATA'
                 when substr(name,2,1) = 's' then 'FC'
                 when substr(name,2,1) = 'd' then 'INTERNAL'
                 else 'UNKNOWN'
            end as disktype
     from v$datafile) filelist
where v$filestat.file# = filelist.file#
order by 5
/
