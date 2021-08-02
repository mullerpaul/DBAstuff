

update dm_job_titles set std_job_category_id = 2 where std_job_title_id = 15
/
update dm_job_titles set std_job_category_id = 2 where std_job_title_id = 84
/
update dm_job_titles set std_job_category_id = 3 where std_job_title_id = 119
/
update dm_job_titles set std_job_category_id = 1 where std_job_title_id = 123
/
update dm_job_titles set last_update_date = sysdate where std_job_title_id in (15,84,119,123)
/
commit
/
