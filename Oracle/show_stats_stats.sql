col method_opt for a30
col granularity for a30
col estimate_percent for a30
col degree for a30
col cascade for a30
col no_invalidate for a30

select dbms_stats.get_param('method_opt') as method_opt,
       dbms_stats.get_param('granularity') as granularity,
       dbms_stats.get_param('estimate_percent') as estimate_percent,
       dbms_stats.get_param('degree') as degree,
       dbms_stats.get_param('cascade') as cascade,
       dbms_stats.get_param('no_invalidate') as no_invalidate
from dual
/

col method_opt clear
col granularity clear
col estimate_percent clear
col degree clear
col cascade clear
col no_invalidate clear

