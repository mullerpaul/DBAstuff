-- what is the ANSI_NULLS setting?
SET ANSI_NULLS ON
SET ANSI_NULLS OFF

  with dual
    as (select 'x' as dummy)
select CASE WHEN count(*) = 0 then 'ANSI NULL' else 'NON ANSI NULL' end as ANSI_Null_status
  from dual
 where 1=1
   and null = null  -- shoudn't be doing this!
--   and null is null  -- this is good.
;
 -- basically, its only an issue if you use operators you shouldn't with NULLs! ( =, >, <, etc)



