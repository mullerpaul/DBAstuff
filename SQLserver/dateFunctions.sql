  with sampleData
    as (select getdate() as x union all
	    select dateadd(day, -1, getdate()) union all
		select dateadd(day, -2, getdate()) union all
		select dateadd(day, 5, getdate()) union all
		select dateadd(day, 4, getdate()) union all
		select '2020-Dec-31' union all
		select '2021-Jan-01' )
select x, DATENAME(Weekday, x), DATEPART(dw, x), dateadd(m, datediff(m, 0, x), 0), dateadd(m, datediff(m, 0, x) - 18, 0)
  from sampleData
 order by 1;


 -- datepart with dw argument:  Sunday-> 1  Saturday-> 7

