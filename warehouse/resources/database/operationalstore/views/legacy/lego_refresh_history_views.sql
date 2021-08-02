/*******************************************************************************
 *DESCRIPTION:  Create views to combine lego_refresh_history with  
 *              DBMS_SCHEDULER views.
 *              1)lego_refresh_current_vw - most current job(s) running or ran
 *              2)lego_refresh_all_vw - all jobs running and ran 
 *MODIFICATIONS:  
 *      
 *  29 Mar 2013 J.Pullifrone Changed from USER_* to DBA_* Scheduler views. Rel 11.2
 *
*******************************************************************************/
CREATE OR REPLACE FORCE VIEW lego_refresh_current_vw
AS
     SELECT lrh.object_name,
            lrh.dbms_scheduler_log_id,
            lrh.job_runtime,
            lrh.status                                                                      AS lego_refresh_status,
            NVL (jrd.status, DECODE (lrh.status, 'started refresh', 'RUNNING'))             AS dbms_scheduler_status,
            lrh.refresh_start_time,
            CASE 
              WHEN lrh.status = 'error'   AND refresh_start_time IS NOT NULL THEN jrd.log_date
              WHEN lrh.status = 'stopped' AND refresh_start_time IS NOT NULL THEN jrd.log_date
              WHEN lrh.status = 'stopped' AND refresh_start_time IS NULL THEN NULL
            ELSE
              lrh.refresh_end_time
            END                                                                             AS refresh_end_time,
            CASE 
              WHEN lrh.refresh_start_time IS NOT NULL 
               AND lrh.refresh_end_time IS NULL 
               AND lrh.status = 'started refresh'        THEN SYSTIMESTAMP - lrh.refresh_start_time 
              WHEN lrh.refresh_start_time IS NOT NULL 
               AND lrh.refresh_end_time IS NULL 
               AND lrh.status = 'error'                  THEN jrd.log_date - lrh.refresh_start_time
              WHEN lrh.refresh_start_time IS NOT NULL 
               AND jrd.log_date IS NOT NULL 
               AND lrh.status = 'stopped'                THEN jrd.log_date - lrh.refresh_start_time
              ELSE
                lrh.refresh_end_time - lrh.refresh_start_time
            END                                                                             AS load_duration,
            jrd.additional_info,
            lrh.refresh_method,
            lrh.refresh_group,
            lrh.refresh_dependency_order,
            lrh.release_time,
            lrh.toggle_refreshed_table,
            TO_NUMBER(lrh.refresh_scn)                                                       AS refresh_scn,
            NVL (running.job_name, jrd.job_name)                                             AS job_name,
            running.sid,
            running.running_instance  
   FROM(
        SELECT ja1.value AS lego, ja2.value AS scn, rj.job_name, rj.session_id AS SID, rj.running_instance, TRUNC(rj.log_id) AS log_id, rj.owner 
          FROM dba_scheduler_job_args ja1, dba_scheduler_job_args ja2, dba_scheduler_job_args ja3, dba_scheduler_running_jobs rj 
         WHERE ja1.job_name = rj.job_name 
           AND ja2.job_name = rj.job_name
           AND ja3.job_name = rj.job_name
           AND ja1.argument_name = 'REFRESH_OBJECT_NAME' 
           AND ja2.argument_name = 'SCN' 
           AND ja3.argument_name = 'RUNTIME' 
           ) running, lego_refresh_history lrh, dba_scheduler_job_run_details jrd
  WHERE (running.owner = 'IQPRODD' OR jrd.owner = 'IQPRODD') 
    AND running.log_id(+)            = lrh.dbms_scheduler_log_id
    AND running.scn(+)               = lrh.refresh_scn
    AND jrd.log_id(+)                = lrh.dbms_scheduler_log_id
    AND lrh.job_runtime              = (SELECT MAX(lrh2.job_runtime)
                                          FROM lego_refresh_history lrh2)                                         
    ORDER BY lrh.refresh_group, lrh.refresh_dependency_order
/
    
CREATE OR REPLACE FORCE VIEW lego_refresh_all_vw
AS
     SELECT lrh.object_name,
            lrh.dbms_scheduler_log_id,
            lrh.job_runtime,
            lrh.status                                                                      AS lego_refresh_status,
            NVL (jrd.status, DECODE (lrh.status, 'started refresh', 'RUNNING'))             AS dbms_scheduler_status,
            lrh.refresh_start_time,
            CASE 
              WHEN lrh.status = 'error'   AND refresh_start_time IS NOT NULL THEN jrd.log_date
              WHEN lrh.status = 'stopped' AND refresh_start_time IS NOT NULL THEN jrd.log_date
              WHEN lrh.status = 'stopped' AND refresh_start_time IS NULL THEN NULL
            ELSE
              lrh.refresh_end_time
            END                                                                             AS refresh_end_time,
            CASE 
              WHEN lrh.refresh_start_time IS NOT NULL 
               AND lrh.refresh_end_time IS NULL 
               AND lrh.status = 'started refresh'        THEN SYSTIMESTAMP - lrh.refresh_start_time 
              WHEN lrh.refresh_start_time IS NOT NULL 
               AND lrh.refresh_end_time IS NULL 
               AND lrh.status = 'error'                  THEN jrd.log_date - lrh.refresh_start_time
              WHEN lrh.refresh_start_time IS NOT NULL 
               AND jrd.log_date IS NOT NULL 
               AND lrh.status = 'stopped'                THEN jrd.log_date - lrh.refresh_start_time
              ELSE
                lrh.refresh_end_time - lrh.refresh_start_time
            END                                                                             AS load_duration,
            jrd.additional_info,
            lrh.refresh_method,
            lrh.refresh_group,
            lrh.refresh_dependency_order,
            lrh.release_time,
            lrh.toggle_refreshed_table,
            TO_NUMBER(lrh.refresh_scn)                                                       AS refresh_scn,
            NVL (running.job_name, jrd.job_name)                                             AS job_name,
            running.sid,
            running.running_instance  
   FROM(
        SELECT ja1.value AS lego, ja2.value AS scn, rj.job_name, rj.session_id AS SID, rj.running_instance, TRUNC(rj.log_id) AS log_id, rj.owner 
          FROM dba_scheduler_job_args ja1, dba_scheduler_job_args ja2, dba_scheduler_job_args ja3, dba_scheduler_running_jobs rj 
         WHERE ja1.job_name = rj.job_name 
           AND ja2.job_name = rj.job_name
           AND ja3.job_name = rj.job_name
           AND ja1.argument_name = 'REFRESH_OBJECT_NAME' 
           AND ja2.argument_name = 'SCN' 
           AND ja3.argument_name = 'RUNTIME' 
           ) running, lego_refresh_history lrh, dba_scheduler_job_run_details jrd
  WHERE (running.owner = 'IQPRODD' OR jrd.owner = 'IQPRODD') 
    AND running.log_id(+)            = lrh.dbms_scheduler_log_id
    AND running.scn(+)               = lrh.refresh_scn
    AND jrd.log_id(+)                = lrh.dbms_scheduler_log_id                                    
    ORDER BY lrh.job_runtime DESC, lrh.refresh_group, lrh.refresh_dependency_order
/

