  with refresh_data
    as (select p.job_runtime, p.caller_name, --c.*
               c.object_name, c.status, c.refresh_start_time, c.refresh_end_time, c.error_message
          from operationalstore.lego_refresh_run_history p,
               operationalstore.lego_refresh_history c
         where p.job_runtime = c.job_runtime
           and p.job_runtime > sysdate - 14)
select job_runtime, caller_name,
       count(*) as legos_started,
       count(case when status='released' then 'x' end) as legos_released,
       max(refresh_end_time) as refresh_end_time,
       max(refresh_end_time) - job_runtime as duration
  from refresh_data
 group by job_runtime, caller_name 
 order by job_runtime desc;

