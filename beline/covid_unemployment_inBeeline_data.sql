-- any assignment legos refreshed recently? 
select object_name, job_runtime, status, 
       toggle_refreshed_table, refresh_end_time-refresh_start_time as refresh_duration
  from iqprodd.lego_refresh_history
 where job_runtime > sysdate -5
   and object_name like 'LEGO_AS%'
 order by 2 desc;
 
select *
  from iqprodd.lego_refresh
 where object_name like 'LEGO_AS%'
 ;

-- yes; but I don't think the legos has what we want AND since we only have the 
-- current and 1 previous copy, we cant only look backwards more than 1 refresh
-- for recent changes 
-- if we want to see # of assignments ended, cancelled, or terminated this period vs 
-- the same period last month, we'll have to look to the FO tables.  
-- To see when assignments were ended, we'll have to look at either the assignment_edition table
-- or the event tables (yuk).

-- Another alternative is look at timecards: counts of timecards, sums of timecard hours, counts of assignments
-- or look at assignments active per week - like a headcount query across all orgs
-- OR, we can look at the number of assignments active (by date) and group by week.


-- Assignment Edition approach
select * from assignment_edition
 where assignment_continuity_fk > 14100000
 order by assignment_continuity_fk, revision;
 
-- from a look at lego logic, it looks like ae.actual_end_date is something we can 
-- look at to find changes due to early ending assignments 
select ac.assignment_continuity_id,
       CASE 
         WHEN ac.work_order_fk is not null then 'WO'
         WHEN ac.work_order_fk is     null AND ac.is_targeted_assignment = 1 THEN 'TA'
         WHEN ac.work_order_fk is     null AND ac.is_targeted_assignment <> 1 THEN 'EA'
         ELSE 'Unk'
       END AS assignment_type,
       ac.has_ever_been_effective,
       ac.phase_type_id                 AS current_phase_type_id,
       ae.assignment_edition_id, ae.assignment_state_fk, ae.revision, ae.create_date, ae.actual_end_date
  from assignment_continuity ac,
       assignment_edition ae
 where ac.assignment_continuity_id = ae.assignment_continuity_fk
   and assignment_continuity_fk > 14100000
   order by 1, 7;

--what kind of assignments are most common?
select assignment_type, assgn_count, 
       round(100 * ratio_to_report(assgn_count) over (), 2) as percentage_of_total
  from (select assignment_type, count(*) as assgn_count
          from (select CASE 
                         WHEN ac.work_order_fk is not null then 'WO'
                         WHEN ac.work_order_fk is     null AND ac.is_targeted_assignment = 1 THEN 'TA'
                         WHEN ac.work_order_fk is     null AND ac.is_targeted_assignment <> 1 THEN 'EA'
                         ELSE 'Unk'
                       END AS assignment_type
                  from assignment_continuity ac)
         group by assignment_type)
 order by 2 desc;
-- EA is two thirds of all assignments


-- how about the amendments data source?  Its kinda like what we want?
select * from all_dependencies 
 where owner like 'IQPROD%' and type = 'VIEW' and referenced_name = 'ASSIGNMENT_EDITION'
 order by 1,3,2;

select * from all_views
 where owner = 'IQPRODR' and view_name = 'WORK_ORDER_VERSION_V';  
--  it uses a GTT, so we'd have to look at code

-- lets just look into this set of tables
assignment_continuity
assignment_edition
asgmt_edition_position_asgmt_x  -- multiple here???
position_assignment


--- looking into endings by month/week   -this takes about 60sec
with assgn_states
as (SELECT 0 as state_id, 'In Process' as state_text FROM dual UNION ALL
    SELECT 1, 'Approval In Process' FROM dual UNION ALL
    SELECT 3, 'Awaiting Start Date' FROM dual UNION ALL
    SELECT 7, 'Canceled' FROM dual UNION ALL
    SELECT 10, 'Completed' FROM dual UNION ALL
    SELECT 12, 'Terminated' FROM dual UNION ALL
    SELECT 13, 'Effective' FROM dual UNION ALL
    SELECT 14, 'Under Development' FROM dual),
     testing
as (
select ac.assignment_continuity_id, ac.has_ever_been_effective,
       --ae.assignment_edition_id, --ae.assignment_state_fk, 
       s.state_text as assignment_state,
       ae.revision, ae.create_date as ae_create_date, ae.actual_end_date,
      -- aepax.*,
       --pa.position_assignment_id, pa.start_date, pa.end_date, 
       pa.create_date as pa_create_date,
       NVL(ae.actual_end_date, pa.end_date) as point_in_time_actual_end_date,
       MIN(CASE when ae.revision = 1 then ae.create_date END) over (partition by assignment_continuity_id) as assgn_create_date,
       MAX(CASE when s.state_text in ('Terminated','Canceled','Completed') then ae.create_date END) over (partition by assignment_continuity_id) as assgn_end_date,
       MAX(CASE when s.state_text = 'Terminated' then 'x' END) over (partition by assignment_continuity_id) as teminated_flag,
       MAX(CASE when s.state_text = 'Canceled' then 'x' END) over (partition by assignment_continuity_id) as canceled_flag,
       MAX(CASE when s.state_text = 'Completed' then 'x' END) over (partition by assignment_continuity_id) as completed_flag
  from assignment_continuity ac,
       assignment_edition ae,
       asgmt_edition_position_asgmt_x aepax,  -- multiple here???  yep!
       position_assignment pa,
       assgn_states s
 where ac.assignment_continuity_id = ae.assignment_continuity_fk  -- does this need a filter for wo is null??
   and ae.assignment_state_fk      = s.state_id(+)
   and ae.assignment_edition_id    = aepax.assignment_edition_fk
   and aepax.position_assignment_fk = pa.position_assignment_id
   and ac.assignment_continuity_id between 12100000 and 15000000   --assuming this gives us most assignments which were active in 2019 or later
   ),
   term_or_canceled_assgn
as (select assignment_continuity_id,
           max(assgn_create_date) as assgn_create_date,
           max(assgn_end_date) as assgn_end_date,
           max(teminated_flag) as terminated_flag,
           max(canceled_flag) as cancelled_flag,
           max(completed_flag) as completed_flag
      from testing t
     group by assignment_continuity_id 
    having max(assgn_end_date) is not null
       and max(assgn_end_date) > to_Date('2019-Jan-01','YYYY-Mon-DD')
   )
select trunc(assgn_end_date, 'DAY') as week_start,
       count(terminated_flag) as terminated_Assgn,
       count(cancelled_flag) as cancelled_assgn,
       count(completed_flag) as completed_assgn
  from term_or_canceled_assgn
 group by trunc(assgn_end_date, 'DAY') 
 order by 1;

--- some assignments are both "terminated" and "completed".   don't know why.
select * from term_or_canceled_assgn
 where (terminated_flag is     null and cancelled_flag is     null and completed_flag is     null) OR 
       (terminated_flag is     null and cancelled_flag is not null and completed_flag is not null) OR 
       (terminated_flag is not null and cancelled_flag is     null and completed_flag is not null) OR 
       (terminated_flag is not null and cancelled_flag is not null and completed_flag is     null) OR 
       (terminated_flag is not null and cancelled_flag is not null and completed_flag is not null) ;
    


select assignment_continuity_id , 
       count(*) as rowcount, 
       count(distinct assignment_edition_id) as dist_ae_ids, 
       count(distinct position_assignment_fk) as dist_pa_ids
 from testing
group by  assignment_continuity_id
having count(*) <> count(distinct assignment_edition_id) OR
       count(distinct position_assignment_fk) > 1;


SELECT constant_type, to_number(constant_value), constant_description
  FROM iqprodr.java_constant_lookup
 WHERE constant_type    in ('ASGNMT_STATE','ASSIGNMENT_PHASE')
   AND UPPER(locale_fk) = 'EN_US'
 ORDER BY 1,2;  



-- FO events approach.
-- legos consider some FO events.  Lets use that SQL as a starting point
select object_name, refresh_sql from iqprodd.lego_refresh where object_name like 'LEGO_ASSIGNMENT___';




-- timecard approach
select * from all_indexes where table_name = 'TIMECARD';
select * from all_ind_columns where table_name = 'TIMECARD' order by 2,6;

select * from timecard 
 where week_ending_date > to_date('2019-Jan-01','YYYY-Mon-DD')
   and rownum < 100;
   
-- we could look at total count and distinct assignment count by month (or week)
-- if we add timecard_entry, what more do we get?
select * from all_ind_columns where table_name = 'TIMECARD_ENTRY' order by 2,6;
select * from timecard_entry
where rownum < 100;
--we'd get hours.  Lets leave that out for a first cut.  

-- Just TIMECARD, grouped by week  -- about 16 sec
select trunc(week_ending_date, 'DAY') as week_start,
       count(*) as timecards,
       count(distinct assignment_continuity_fk) as assignments
  from timecard 
 where week_ending_date >= to_date('2018-Jan-01','YYYY-Mon-DD')
   and week_ending_date <  to_date('2020-Aug-01','YYYY-Mon-DD')
   and state_code in (4, 9)  -- approved or submitted
 group by trunc(week_ending_date, 'DAY')
 order by 1;

--- what timecard states do we want to exclude?
SELECT constant_value, constant_description
  FROM iqprodr.java_constant_lookup
 WHERE constant_type    = 'TIMECARD_STATE'
   AND UPPER(locale_fk) = 'EN_US'
   
-- active assignments by week - all orgs
-- what states to exclude?
select state, assgn_count, round(100 * ratio_to_report(assgn_count) over (), 2) as percentage_of_total
  from (
select la.assignment_state as state, count(*)  as assgn_count
  from iqprodd.LEGO_ASSIGNMENT_vw la 
 group by la.assignment_state )
 order by 2 desc;

select la.assignment_continuity_id,
       la.assignment_start_dt, la.assignment_actual_end_dt,
       la.assignment_state
  from iqprodd.LEGO_ASSIGNMENT_vw la,
       iqprodd.lego_buyer_org_vw lbo
 where la.buyer_org_id = lbo.buyer_org_id
   and lbo.buyer_enterprise_bus_org_id = 2612  -- exclude test org
   and la.assignment_state in ('Completed','Effective','Terminated','Canceled','Effective - On Board','Position Offered','Approval In Process','Awaiting Start Date')
   ;

-- Sunday - Sunday week boundries for 2019 and 2020 Jan-Apr
select trunc(to_date('2019-Jan-01','YYYY-Mon-DD') + 7 * (rownum - 1), 'DAY') as week_start,
       trunc(to_date('2019-Jan-01','YYYY-Mon-DD') + 7 * (rownum ), 'DAY') as week_end
 from dual 
 connect by level < 68;
 
-- combine and count  --50-60 sec
  with week_boundries  -- Sunday to Sunday weeks from Dec 30, 2018 to Apr 26, 2020
    as (select trunc(to_date('2019-Jan-01','YYYY-Mon-DD') + 7 * (rownum - 1), 'DAY') as week_start,
               trunc(to_date('2019-Jan-01','YYYY-Mon-DD') + 7 * (rownum ), 'DAY') as week_end
          from dual 
       connect by level < 86),
       assignment_data  --use lego synonyms to avoid both FO tables AND lego views which do a lot of work unnecessay for this analysis
    as (select assignment_continuity_id, assignment_start_dt, assignment_actual_end_dt
          from iqprodd.LEGO_ASSIGNMENT_EA
         where assignment_actual_end_dt > to_date('2018-Dec-30','YYYY-Mon-DD')
           and assignment_start_dt < to_date('2020-Sep-01','YYYY-Mon-DD')
         UNION ALL
        select assignment_continuity_id, assignment_start_dt, assignment_actual_end_dt
          from iqprodd.LEGO_ASSIGNMENT_TA
         where assignment_actual_end_dt > to_date('2018-Dec-30','YYYY-Mon-DD')
           and assignment_start_dt < to_date('2020-Sep-01','YYYY-Mon-DD')
         UNION ALL
        select assignment_continuity_id, assignment_start_dt, assignment_actual_end_dt
          from iqprodd.LEGO_ASSIGNMENT_WO
         where assignment_actual_end_dt > to_date('2018-Dec-30','YYYY-Mon-DD')
           and assignment_start_dt < to_date('2020-Sep-01','YYYY-Mon-DD')),
       weekly_rollups
    as (select w.week_start,
               to_char(w.week_start,'IYYY') as ISO_year,
               to_char(w.week_start,'IW') as ISO_week,
               to_number(to_char(w.week_start,'IYYY')) as ISO_year_num,
               to_number(to_char(w.week_start,'IW')) as ISO_week_num,
               count(*) as assignments_active,
               count(case when assignment_start_dt >= w.week_start and assignment_start_dt < w.week_end then 'x' end) as assignments_starting,
               count(case when assignment_actual_end_dt >= w.week_start and assignment_actual_end_dt < w.week_end then 'x' end) as assignments_ending
          from week_boundries w,
               assignment_data a
         where w.week_start < a.assignment_actual_end_dt
           and w.week_end > a.assignment_start_dt
         group by w.week_start)
select to_char(week_start, 'YYYY-Mon-DD') as week_start_date,
       iso_week,
       assignments_active, 
--       previous_year_active,
       ROUND(100 * (assignments_active/previous_year_active - 1), 2) as active_pct_chng_from_2019,
       assignments_starting,
--       previous_year_starting,
       ROUND(100 * (assignments_starting / previous_year_starting -1), 2) as starting_pct_chng_from_2019
  from (select week_Start, ISO_week, iso_week_num, iso_year, iso_year_num,
               assignments_active, 
               lag(assignments_active) over (partition by iso_week order by iso_year_num) as previous_year_active,
               assignments_starting,
               lag(assignments_starting) over (partition by iso_week order by iso_year_num) as previous_year_starting
          from weekly_rollups)
--where iso_year_num = 2020
 order by week_start;
 
 
       
having to_char(w.week_start,'IYYY') = 2020 OR to_char(w.week_start,'IW') <= 30
-- order by 1;
 order by 3,2
 ;

-- any NULLS?
select count(*) , count(assignment_actual_end_dt) from iqprodd.lego_assignment_vw;
-- nope!



-- group assignments by enterprise
-- find top 5 enterprises by assignment count for 2019
  with assignment_data  --use lego synonyms to avoid both FO tables AND lego views which do a lot of work unnecessay for this analysis
    as (select buyer_org_id, assignment_continuity_id, assignment_start_dt, assignment_actual_end_dt
          from iqprodd.LEGO_ASSIGNMENT_EA
         where assignment_actual_end_dt >= to_date('2019-Jan-01','YYYY-Mon-DD')
           and assignment_start_dt < to_date('2020-Jan-01','YYYY-Mon-DD')
         UNION ALL
        select buyer_org_id, assignment_continuity_id, assignment_start_dt, assignment_actual_end_dt
          from iqprodd.LEGO_ASSIGNMENT_TA
         where assignment_actual_end_dt >= to_date('2019-Jan-01','YYYY-Mon-DD')
           and assignment_start_dt < to_date('2020-Jan-01','YYYY-Mon-DD')
         UNION ALL
        select buyer_org_id, assignment_continuity_id, assignment_start_dt, assignment_actual_end_dt
          from iqprodd.LEGO_ASSIGNMENT_WO
         where assignment_actual_end_dt >= to_date('2019-Jan-01','YYYY-Mon-DD')
           and assignment_start_dt < to_date('2020-Jan-01','YYYY-Mon-DD'))
select lbo.buyer_enterprise_name, count(*) as assignments_in_2019
  from assignment_data a,
       iqprodd.lego_buyer_org_vw lbo
 where a.buyer_orG_id = lbo.buyer_org_id
 group by lbo.buyer_enterprise_name
 order by 2 desc
 ;

-- top 7.  I stoped at seven because:
-- 1. I wanted to get Shell even though it has relativly few assignments (for a large customer)
-- 2. there is a larger difference between 7 and 8 than there is between 6 and 7, or 8 and 9
'Menasha Enterprise','Irving Oil Limited','ARAMARK Company Reports',
'Accenture','Disney Enterprise','Royal Dutch / Shell Group','UPS Enterprise'

-- now add this join and filter into the above query:
  with week_boundries  -- Sunday to Sunday weeks from Dec 30, 2018 to Apr 26, 2020
    as (select trunc(to_date('2019-Jan-01','YYYY-Mon-DD') + 7 * (rownum - 1), 'DAY') as week_start,
               trunc(to_date('2019-Jan-01','YYYY-Mon-DD') + 7 * (rownum ), 'DAY') as week_end
          from dual 
       connect by level < 80),
       assignment_data  --use lego synonyms to avoid both FO tables AND lego views which do a lot of work unnecessay for this analysis
    as (select buyer_org_id, assignment_continuity_id, assignment_start_dt, assignment_actual_end_dt
          from iqprodd.LEGO_ASSIGNMENT_EA
         where assignment_actual_end_dt > to_date('2018-Dec-30','YYYY-Mon-DD')
           and assignment_start_dt < to_date('2020-Jul-01','YYYY-Mon-DD')
         UNION ALL
        select buyer_org_id, assignment_continuity_id, assignment_start_dt, assignment_actual_end_dt
          from iqprodd.LEGO_ASSIGNMENT_TA
         where assignment_actual_end_dt > to_date('2018-Dec-30','YYYY-Mon-DD')
           and assignment_start_dt < to_date('2020-Jul-01','YYYY-Mon-DD')
         UNION ALL
        select buyer_org_id, assignment_continuity_id, assignment_start_dt, assignment_actual_end_dt
          from iqprodd.LEGO_ASSIGNMENT_WO
         where assignment_actual_end_dt > to_date('2018-Dec-30','YYYY-Mon-DD')
           and assignment_start_dt < to_date('2020-Jul-01','YYYY-Mon-DD')),
       assgn_data_by_enterprise
    as (select lbo.buyer_enterprise_name, a.assignment_start_dt, a.assignment_actual_end_dt
          from assignment_data a,
               iqprodd.lego_buyer_org_vw lbo
         where a.buyer_org_id = lbo.buyer_org_id
           and lbo.buyer_enterprise_name in ('Menasha Enterprise','Irving Oil Limited','ARAMARK Company Reports',
                                             'Accenture','Disney Enterprise','Royal Dutch / Shell Group','UPS Enterprise')),
       weekly_rollups_by_ent
    as (select w.week_start, a.buyer_enterprise_name,
               to_char(w.week_start,'IYYY') as ISO_year,
               to_char(w.week_start,'IW') as ISO_week,
               to_number(to_char(w.week_start,'IYYY')) as ISO_year_num,
               to_number(to_char(w.week_start,'IW')) as ISO_week_num,
               count(*) as assignments_active,
               count(case when assignment_start_dt >= w.week_start and assignment_start_dt < w.week_end then 'x' end) as assignments_starting,
               count(case when assignment_actual_end_dt >= w.week_start and assignment_actual_end_dt < w.week_end then 'x' end) as assignments_ending
          from week_boundries w,
               assgn_data_by_enterprise a
         where w.week_start < a.assignment_actual_end_dt
           and w.week_end > a.assignment_start_dt
         group by w.week_start, a.buyer_enterprise_name)
select iso_week, buyer_enterprise_name,
       iso_year_num,
       to_char(week_start, 'Mon-DD') as week_start_date_2020,
       assignments_active, 
--       previous_year_active,
       ROUND(100 * (assignments_active/previous_year_active - 1), 2) as active_pct_chng_from_2019,
       assignments_starting,
--       previous_year_starting,
       ROUND(100 * (assignments_starting / previous_year_starting -1), 2) as starting_pct_chng_from_2019
  from (select week_Start, buyer_enterprise_name, ISO_week, iso_week_num, iso_year, iso_year_num,
               assignments_active, 
               lag(assignments_active) over (partition by iso_week, buyer_enterprise_name order by iso_year_num) as previous_year_active,
               assignments_starting,
               lag(assignments_starting) over (partition by iso_week, buyer_enterprise_name order by iso_year_num) as previous_year_starting
          from weekly_rollups_by_ent)
 where iso_year_num = 2020
 order by 1,2,3;
