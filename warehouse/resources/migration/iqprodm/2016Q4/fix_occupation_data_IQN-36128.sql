update dm_job_titles set is_deleted ='Y', last_update_date = sysdate where std_job_title_id in (29,35,66,88,90,91,101,102,103,104,120,121,126)
/
update dm_job_titles set std_job_category_id = 4 where std_job_title_id in (96,128)
/
update dm_job_titles set std_job_category_id = 2 where std_job_title_id in (70,110)
/
update dm_occupation_hierarchy set std_job_category_id = 2 where std_job_title_id in (70,110)
/
update dm_occupation_hierarchy set std_job_category_id = 4 where std_job_title_id in (96,128)
/
update dm_occupation_hierarchy set std_sub_category_id = 7 where std_job_title_id = 39
/
update dm_occupation_hierarchy set std_sub_category_id = 18 where std_job_title_id in (20,53,64,89)
/
delete dm_occupation_hierarchy where std_job_title_id in (35,126)
/
commit
/