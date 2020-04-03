col name for a78
prompt usage: @show_files <mount point>
prompt example: @show_files /d82

select filetype, size_mib, name
from
(select 'controlfile' as filetype, to_number(null) as size_mib, name from v$controlfile
 union all
 select 'logfile' as filetype, to_number(null), member from v$logfile
 union all
 select 'datafile' as filetype, bytes/(1024*1024), name from v$datafile
 union all
 select 'tempfile' as filetype, bytes/(1024*1024), name from v$tempfile)
where name like '&1%'
order by substr(name,1,instr(name,'/',1,2)-1),
         case when filetype='controlfile' then 1
              when filetype='logfile' then 2
              when filetype='tempfile' then 3
              when filetype='datafile' then 4 end
/

column name clear
