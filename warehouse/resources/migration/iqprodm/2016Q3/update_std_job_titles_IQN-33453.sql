UPDATE dm_job_titles
   SET std_job_title_desc = 'Business Analyst (IT)', last_update_date = SYSDATE
 WHERE std_job_title_id = 10
/

UPDATE dm_job_titles
   SET std_job_title_desc = 'Events Coordinator', last_update_date = SYSDATE
 WHERE std_job_title_id = 23
/

UPDATE dm_job_titles
   SET std_job_title_desc = 'Paralegal/ Legal Assistant', last_update_date = SYSDATE
 WHERE std_job_title_id = 45
/

UPDATE dm_job_titles
   SET std_job_title_desc = 'Business Analyst (non-IT)', last_update_date = SYSDATE
 WHERE std_job_title_id = 67
/

UPDATE dm_job_titles
   SET std_job_title_desc = 'Systems Integrator', last_update_date = SYSDATE
 WHERE std_job_title_id = 112
/
 
COMMIT
/

