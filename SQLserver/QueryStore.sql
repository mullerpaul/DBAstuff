--- see what SQL was captured by Query Store for a given interval
--- How to use:
---   1. edit the times in query_intervals
---   2. change or remove the where clause in main query

  WITH 
query_intervals AS
    (select runtime_stats_interval_id, start_time, end_time
       from sys.query_store_runtime_stats_interval
      where end_time > '2021-06-04 05:00'  -- interested interval begin
        and start_time < '2021-06-04 10:00'  -- interested interval end
    ),
distinct_plans AS
    (SELECT DISTINCT w.plan_id
       FROM sys.query_store_wait_stats w
            INNER JOIN query_intervals qi ON w.runtime_stats_interval_id = qi.runtime_stats_interval_id
    ),
sql_text_by_planID_and_queryID AS
    (select p.plan_id,
            q.query_id, q.query_text_id, 
            qt.query_sql_text
       from distinct_plans dp
            inner join sys.query_store_plan p on p.plan_id = dp.plan_id
            inner join sys.query_store_query q on (q.query_id = p.query_id)  -- often a few plans per query
            inner join sys.query_store_query_text qt on (q.query_text_id = qt.query_text_id)
    )
select *
  from sql_text_by_planID_and_queryID
 where query_sql_text like '%COUNT(*) FROM analytics%'  --get row count statement in PartitionSwitch
    or query_sql_text like '%SELECT rows%FROM sys.partitions%'  -- metadata row count in PartitionSwitch
    or query_sql_text like '%TRUNCATE TABLE%WITH (PARTITIONS%' -- truncate target table partition in PartitionSwitch
    or query_sql_text like '%ALTER TABLE%SWITCH PARTITION%' -- partition switch in PartitionSwitch
;


--- see wait information for given planID(s)
--- How to use:
---   1. edit the times in query_intervals
---   2. edit in any PlanIds you found with above query
---   3. change or remove CASE statement, 
---   4. change or remove execution_type_desc clause
  WITH 
query_intervals AS
    (select runtime_stats_interval_id, start_time, end_time
       from sys.query_store_runtime_stats_interval
      where end_time > '2021-06-04 05:00'  -- interested interval begin
        and start_time < '2021-06-04 10:00'  -- interested interval end
    )
SELECT qi.start_time, qi.end_time, 
       w.plan_id, 
       CASE 
         when w.plan_id = 4065 then 'metadata rowcount'
         when w.plan_id = 4247 then 'select count rowcount #1'
         when w.plan_id = 4248 then 'select count rowcount #2'
       end as query_identifier,
       w.wait_category_desc, w.execution_type_desc, w.total_query_wait_time_ms, w.avg_query_wait_time_ms,
       --ROUND(w.avg_query_wait_time_ms / 60000.0, 1) as avg_wait_time_min,
       w.total_query_wait_time_ms / w.avg_query_wait_time_ms as executionCount
  FROM sys.query_store_wait_stats w
       INNER JOIN query_intervals qi ON w.runtime_stats_interval_id = qi.runtime_stats_interval_id
 WHERE 1=1
--   AND w.plan_id = 4328 --bulk insert into spend stage
   AND w.plan_id in (4065, 4247, 4248) -- sql from spend PartitionSwitch proc
   AND execution_type_desc <> 'Regular'
-- ORDER BY 1,3,5,6  --by category
-- ORDER BY 1,3,7 desc  --by wait time
 ORDER BY 3,7 desc  -- by statement, wait time
;


--===========================
-- find SQL run in the same interval (usually hour)
--===========================

  WITH 
query_intervals AS
    (select runtime_stats_interval_id, start_time, end_time
       from sys.query_store_runtime_stats_interval
      where end_time > '2021-06-09 06:00'  -- interested interval begin
        and start_time < '2021-06-09 12:00'  -- interested interval end
    ),
distinct_plans_per_interval AS
    (SELECT DISTINCT qi.start_time, qi.end_time, qi.runtime_stats_interval_id, w.plan_id
       FROM sys.query_store_wait_stats w
            INNER JOIN query_intervals qi ON w.runtime_stats_interval_id = qi.runtime_stats_interval_id
    ),
sql_text_by_planID_and_queryID AS
    (select dp.*,
            --p.plan_id,
            q.query_id, q.query_text_id, 
            qt.query_sql_text
       from distinct_plans_per_interval dp
            inner join sys.query_store_plan p on p.plan_id = dp.plan_id
            inner join sys.query_store_query q on (q.query_id = p.query_id)  -- often a few plans per query
            inner join sys.query_store_query_text qt on (q.query_text_id = qt.query_text_id)
    )
select * 
  from sql_text_by_planID_and_queryID
 where 1=1
--   and query_sql_text like 'insert bulk%'
   --and query_sql_text like '%ExecRequestSnapshotsTemp%'
 order by 1;