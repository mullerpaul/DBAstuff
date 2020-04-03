select sn.class, sn.name, ss.value
  from v$sesstat ss, v$statname sn
 where sn.statistic# = ss.statistic#
   and ss.value > 0
   and ss.sid = 224
 order by sn.class, sn.statistic#
/
