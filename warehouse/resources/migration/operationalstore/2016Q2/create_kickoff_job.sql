BEGIN
  /* Will have to change the start_date if/when we deploy to EMEA databases. */
  
  dbms_scheduler.create_job(job_name        => 'LEGO_refresh_kickoff',
                            job_type        => 'PLSQL_BLOCK',
                            job_action      => 'BEGIN lego_refresh_mgr_pkg.refresh; END;',
                            start_date      => to_timestamp_tz('America/Denver ' || to_char(TRUNC(SYSDATE) + 14/24, 'YYYY-Mon-DD hh24:mi'),
                                                               'TZR YYYY-Mon-DD hh24:mi'),
                            repeat_interval => 'freq=daily; byhour=2,6,10,14,18,22',
                            enabled         => TRUE,
                            comments        => 'Master refresh job for LEGOs');
                            
END;
/
