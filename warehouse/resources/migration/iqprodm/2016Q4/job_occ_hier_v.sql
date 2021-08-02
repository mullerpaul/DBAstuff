CREATE OR REPLACE FORCE VIEW DM_JOB_OCCUPATION_HIERARCHY_V (STD_JOB_TITLE_ID, STD_JOB_TITLE_DESC, STD_OCCUPATION_ID, STD_OCCUPATION_DESC, STD_JOB_CATEGORY_ID, STD_JOB_CATEGORY_DESC, STD_SUB_CATEGORY_ID, STD_SUB_CATEGORY_DESC) AS 
select oh.std_job_title_id, jt.std_job_title_desc, oh.std_occupation_id, oc.std_occupation_desc,
oh.std_job_category_id, jc.std_job_category_desc, oh.std_sub_category_id, sc.STD_SUB_CATEGORY_DESC
from 
dm_occupation_hierarchy oh,
dm_job_titles jt,
dm_std_occupation oc,
dm_job_category jc,
dm_std_sub_category sc
where oh.std_job_title_id = jt.std_job_title_id
and oh.std_occupation_id = oc.std_occupation_id
and oh.std_job_category_id =jc.std_job_category_id
and oh.std_sub_category_id =sc.std_sub_category_id
order by std_job_title_id, std_occupation_id
/
