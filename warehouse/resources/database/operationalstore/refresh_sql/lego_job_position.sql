/*******************************************************************************
SCRIPT NAME         lego_job_position.sql 
 
LEGO OBJECT NAME    LEGO_JOB_POSITION
 
CREATED             3/08/2016
 
ORIGINAL AUTHOR     Joe Pullifrone

***************************MODIFICATION HISTORY ********************************

08/15/2016 - J.Pullifrone - IQN-34051 - adding job canceled and closed dates 
10/30/2017 - hmajid       - IQN-38536 - Add new job related events 29017, 29022
*******************************************************************************/  

DECLARE

  v_source           VARCHAR2(64) := 'lego_job_position.sql';
  v_lego_object_name VARCHAR2(64) := 'LEGO_JOB_POSITION'; 

  v_clob CLOB :=
q'{
WITH pft AS (
  SELECT pp.job_fk,
         COUNT(pttfh.offer_id)  AS positions_filled 
         --this one seems to work also but we will stick with the tried and true
         --COUNT(pttfh.date_offer_accepted) AS offers_accepted,
         --we can look into resources_on_board - not sure what this means but do not want to forget about it
         --COUNT(p.date_resource_on_board)  AS resources_on_board
    FROM position@db_link_name                      AS OF SCN source_db_SCN p,
         position_pool@db_link_name                 AS OF SCN source_db_SCN pp,
         position_time_to_fill_history@db_link_name AS OF SCN source_db_SCN pttfh --if the offer is in this table, it has been accepted
   WHERE pttfh.position_fk  = p.position_id
     AND p.position_pool_fk = pp.position_pool_id
   GROUP BY pp.job_fk
),
pp AS (
  SELECT job_fk,
         SUM(total_positions)                  AS total_positions,
         SUM(number_overfill_positions)        AS overfill_positions,
         SUM(available_positions_cur)          AS available_positions_cur,
         SUM(available_positions_nf)           AS available_positions_nf,
         SUM(num_canceled_closed_positions)    AS positions_closed
    FROM (SELECT pp.job_fk,
                 pp.position_pool_id,
                 pp.number_available_positions              AS available_positions_cur,
                 pp.total_number_positions                  AS total_positions,
                 pp.number_overfill_positions,
                 CASE WHEN pp.start_date <= TRUNC(SYSDATE) 
                   THEN pp.number_available_positions 
                 ELSE 0 
                 END                                        AS available_positions_nf,
                 pps.num_canceled_closed_positions
            FROM position_pool@db_link_name AS OF SCN source_db_SCN pp,
                 (SELECT position_pool_fk, num_canceled_closed_positions
                    FROM (SELECT ppss.position_pool_fk, 
                                 ppss.num_canceled_closed_positions, 
                                 RANK () OVER (PARTITION BY ppss.position_pool_fk ORDER BY ppss.start_time DESC) rk
                            FROM position_pool_stat_snapshot@db_link_name AS OF SCN source_db_SCN ppss
                           WHERE ppss.end_time IS NULL)
                   WHERE rk = 1)  pps
           WHERE pp.position_pool_id = pps.position_pool_fk (+) 
         )
   GROUP BY job_fk),
event_dates AS (SELECT j.job_owner_id AS job_id,
                       MAX(CASE WHEN event_name_fk = 29003 THEN ed.timestamp ELSE NULL END) job_canceled_date,
                       MAX(CASE WHEN event_name_fk = 29004 THEN ed.timestamp ELSE NULL END) job_closed_date,
                       Max(CASE WHEN event_name_fk = 29017 THEN ed.timestamp ELSE NULL END) job_rejected_date, 
                       MAX(CASE WHEN event_name_fk = 29022 THEN ed.timestamp ELSE NULL END) job_closed_to_new_matches
                  FROM job_event_description@db_link_name AS OF SCN source_db_SCN j, 
                       event_description@db_link_name AS OF SCN source_db_SCN ed
                 WHERE j.identifier  = ed.identifier
                   AND ed.event_name_fk IN (29003, 29004, 29017, 29022)
                 GROUP BY j.job_owner_id)  

SELECT bfr.business_org_fk AS buyer_org_id,
       j.job_id,
       NVL(CASE WHEN j.proposed_approvable_aspects_fk IS NULL 
             THEN pp.total_positions
           ELSE paj.total_number_positions
           END,0)                                                 AS positions_total,
       NVL(pp.overfill_positions,0)                               AS overfill_positions,
       NVL(pft.positions_filled,0)                                AS positions_filled,
       NVL(pp.available_positions_cur,0)                          AS positions_available_cur,
       NVL(pp.available_positions_nf,0)                           AS positions_available_nf,
       NVL(CASE WHEN j.proposed_approvable_aspects_fk IS NULL 
             THEN 0
           ELSE (paj.total_number_positions - pp.total_positions)
           END,0)                                                 AS positions_pending,
       NVL(pp.positions_closed,0)                                 AS positions_closed,
       event_dates.job_canceled_date,
       event_dates.job_closed_date,
       event_dates.job_rejected_date,
       event_dates.job_closed_to_new_matches
 FROM job@db_link_name                            AS OF SCN source_db_SCN j,
      firm_role@db_link_name                      AS OF SCN source_db_SCN bfr,
      proposed_approvable_jobaspects@db_link_name AS OF SCN source_db_SCN paj,
      pft,
      pp,
      event_dates
WHERE bfr.firm_id                      = j.buyer_firm_fk
  AND j.proposed_approvable_aspects_fk = paj.identifier(+)
  AND j.job_id                         = pp.job_fk(+)
  AND j.job_id                         = pft.job_fk(+)
  AND j.job_id                         = event_dates.job_id(+)
  AND (j.archived_date IS NULL OR 
       j.archived_date >= ADD_MONTHS(TRUNC(SYSDATE),- months_in_refresh))}';


BEGIN
   
  logger_pkg.instantiate_logger;
  logger_pkg.set_level('INFO');   
  logger_pkg.set_source(v_source);
  logger_pkg.set_code_location('Updating Refresh SQL for '|| v_lego_object_name);
  logger_pkg.info(v_clob);
  logger_pkg.info('Begin - UPDATE LEGO_REFRESH');
   
  UPDATE lego_refresh
     SET refresh_sql = v_clob
   WHERE object_name = v_lego_object_name;  
  
  COMMIT;
    
  logger_pkg.info('Update Complete', TRUE); 
  logger_pkg.unset_source(v_source);  
  
EXCEPTION
  WHEN OTHERS THEN
    logger_pkg.fatal(NULL, SQLCODE, 'Error Updating Refresh SQL for ' || v_lego_object_name || ' - ' || SQLERRM, TRUE);
    logger_pkg.unset_source(v_source);
    RAISE;   
   
END;
/

