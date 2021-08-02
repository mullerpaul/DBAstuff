--- take a look at Ben's query.
-- here is the query we loop over
      select max(q.work_order_effectivity_view_id),
             min(q.work_order_effectivity_view_id)
--             into curr_woev_id,
  --                prev_woev_id
          from (select work_order_effectivity_view_id
                  from work_order_effectivity_view iwovs
                  where iwovs.work_order_fk=wordr_id
                  order by create_date desc) q
          where rownum <= 2;

-- not familiar with that view.  Whats in it?
select * from work_order_effectivity_view iwovs;

-- whats the SQL on that view? (assuming its a view)
select * from all_objects where object_name = 'WORK_ORDER_EFFECTIVITY_VIEW';
-- its actually a table!!

-- IF we trust this *table* named work_order_effectivity_view to be current (how is it's data maintained?), 
-- then we can write a query to check each row (wo version) against the previous version.
-- verify that is actually what want to do.

-- first lets be sure we really understand the data
select count(*) as all_row_count, 
       count(work_order_effectivity_view_id) as view_id_NN_count, count(distinct work_order_effectivity_view_id) as view_id_distinct_count, 
       count(work_order_fk) as work_order_fk_nn_count, count(distinct work_order_fk) as work_order_fk_unique_count
  from work_order_effectivity_view iwovs;       
-- so at least in this DB, both those columns have no nulls.  work_order_effectivity_id is unique, work_order_fk is NOT n=unique.
-- how about constraints?
select * from all_constraints where table_name = 'WORK_ORDER_EFFECTIVITY_VIEW';
select * from all_cons_columns where table_name = 'WORK_ORDER_EFFECTIVITY_VIEW' order by constraint_name;
-- pretty much as i suspected; but its good to confirm.

-- look at the data again
select * from work_order_effectivity_view iwovs order by iwovs.work_order_fk;


--- how many work orders have 1 version?  how about 2?  more?
select version_count, count(*) as work_order_count
  from (
        select work_order_fk, count(*) as version_count
          from work_order_effectivity_view
         group by work_order_fk
  --      having count(*) > 1   -- HAVING clause is like a filter on an aggregate
       )
 group by version_count 
 order by 1;
-- over half the work orders have only one version.  I think we can exclude them.



-- get a list of only work_orders with multiple versions because we dont care about wo with only one version (right?)
-- then join that list with the data table as a filter.
  with multiple_wo_versions
    as (select work_order_fk, count(*) as version_count
          from work_order_effectivity_view
         group by work_order_fk
        having count(*) > 1) 
select iwovs.work_order_effectivity_view_id, iwovs.work_order_fk, 
       iwovs.create_date, --iwovs.valid_to_date, iwovs.last_update_date,
       lag(iwovs.create_date) over (partition by iwovs.work_order_fk order by iwovs.create_date) as previous_create_date
  from work_order_effectivity_view iwovs,
       multiple_wo_versions m
 where iwovs.work_order_fk = m.work_order_fk      
   and iwovs.work_order_fk in (3405627,3405851,3405855,3405859)  -- I picked these WO IDs because they have lots of versions.
 order by iwovs.work_order_fk, iwovs.create_date;      


--- in case we CANT trust that "veiw" , lets look at work_order_version_Schedule
select * from work_order_version_schedule
 order by work_order_effectivity_view_fk
 ;

-- same routine - check the data, check the constraints
select * from all_cons_columns where table_name = 'WORK_ORDER_VERSION_SCHEDULE' order by constraint_name;
-- yep - a table

-- first lets be sure we really understand the data
select count(*) as all_row_count, 
       count(work_order_version_schedule_id) as wovs_id_NN_count, count(distinct work_order_version_schedule_id) as wovs_id_distinct_count, 
       count(work_order_effectivity_view_fk) as woev_fk_NN_count, count(distinct work_order_effectivity_view_fk) as woev_fk_distinct_count, 
       count(work_order_version_fk) as wov_fk_nn_count,           count(distinct work_order_version_fk) as wov_fk_unique_count
  from WORK_ORDER_VERSION_SCHEDULE wovs;

-- so at least in this DB, all three of those columns have no nulls.  
-- how about constraints?
select * from all_constraints where table_name = 'WORK_ORDER_VERSION_SCHEDULE' order by constraint_name;
select * from all_cons_columns where table_name = 'WORK_ORDER_VERSION_SCHEDULE' order by constraint_name;
-- again, pretty much as i suspected; but its good to confirm.

-- lets try a similar query.  Filter on work_order_version_fk that have more than one row.
-- hmmm -is that correct?  I can understand filtering on work orders; but work order VERSIONS??
  with multiple_wo_versions
    as (select work_order_effectivity_view_fk, count(*) as version_count
          from WORK_ORDER_VERSION_SCHEDULE
         where create_date > to_date('2019-Mar-01','YYYY-Mon-DD') 
         group by work_order_effectivity_view_fk
        having count(*) > 1) 
select * from 
(
select wovs.*,
       --wovs.work_order_effectivity_view_id, wovs.work_order_fk, 
       --wovs.create_date, 
       lag(wovs.valid_from) over (partition by wovs.work_order_effectivity_view_fk order by wovs.work_order_version_fk) as previous_valid_from,  --dont need this
       lag(wovs.valid_to) over (partition by wovs.work_order_effectivity_view_fk order by wovs.work_order_version_fk) as previous_valid_to
  from WORK_ORDER_VERSION_SCHEDULE wovs,
       multiple_wo_versions m
 where wovs.work_order_effectivity_view_fk = m.work_order_effectivity_view_fk      
   --and wovs.work_order_fk in (3405627,3405851,3405855,3405859)  -- I picked these WO IDs because they have lots of versions.
)
--where (valid_from <> previous_valid_to + 1)
order by work_order_effectivity_view_fk, work_order_version_fk;
