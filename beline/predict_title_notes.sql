--- look at defined stoplist and the words in them
select * from ctx_stoplists;
select * from ctx_stopwords order by 2,4;

-- build PLSQL to create copy of default stoplist
select spw_word, 
       q'{CTX_DDL.ADD_STOPWORD(stoplist_name => 'job_title_stoplist', stopword => '}' || spw_word || ''');' as ddl_text
  from ctx_stopwords 
 where spw_stoplist = 'DEFAULT_STOPLIST' 
 order by spw_word;

  
--- tokin lists for each index
select * from DR$ASSIGNMENT_TITLE_INDEX$I;
select * from DR$ASSIGNMENT_DESCRIPTION_INDEX$I
-- where token_text = '3M'
 order by token_count desc
;

-- duplicates?
select token_text, count(*) from DR$ASSIGNMENT_TITLE_INDEX$I group by token_text having count(*) > 1;
select token_text, count(*) from DR$ASSIGNMENT_DESCRIPTION_INDEX$I group by token_text having count(*) > 1;

-- look at the tables created 
select * from user_objects 
 where created > trunc(sysdate) 
   and object_type = 'TABLE'
   and object_name not like 'DR$%';

-- check corpus data
select assignment_id, job_title, job_description from assignment;

--- tokins per document (job title)
select assignment_id, token, token_offset -- * 
  from JOB_TITLE_DOCUMENT_TOKEN
 order by 1,2
-- order by 2,1 
  ;

--- tokins per document (job description)
select * from JOB_DESCRIPTION_DOCUMENT_TOKEN
 order by 1,2   -- BUG? duplications WITHIN a document, why??  turns out its unique per token entry in the index NOT by token.  tokens with lots of appearances can require more than one index entry.
-- order by 2,1 
 ;

-- look at all description tokins sorted by the % of documents in which they appear.
select *
  from JOB_DESCRIPTION_TOKEN
 where included_doc_ratio < .2  -- 20% of docs threshold - a total guess - returns 7800 rows
 order by contained_in_doc_count desc ;  
  

-- about how many description token to title token relations can we expect for these predictive desc tokins?
select count(*) as relation_count  --52K for 100 assignments, 726 for 4 assignments
  from JOB_TITLE_DOCUMENT_TOKEN td,
       JOB_DESCRIPTION_DOCUMENT_TOKEN dd,
       JOB_DESCRIPTION_TOKEN dt
 where td.assignment_id = dd.assignment_id
   and dd.token = dt.token
--   and included_doc_ratio < .2    -- 390K
   and included_doc_ratio < .15    -- 347K
--   and included_doc_ratio < .1    -- 295K
--   and included_doc_ratio < .05   -- 206K
;

select --dt.*, ddt.*, tdt.*
       dt.token as description_token, dt.contained_in_doc_count as contained_in_description_count,
       dt.inverse_document_frequency, ddt.assignment_id as description_assignment_id,
       tdt.token as assignment_title_token
  from JOB_TITLE_DOCUMENT_TOKEN tdt,
       JOB_DESCRIPTION_DOCUMENT_TOKEN ddt,
       JOB_DESCRIPTION_TOKEN dt
 where tdt.assignment_id = ddt.assignment_id
   and ddt.token = dt.token
   and dt.contained_in_doc_count / dt.corpus_doc_count < .15
   and dt.token = 'DATABASE'
order by 1,3;

select * from assignment where assignment_id = 3101;



select * from user_tables;

select * from ODMR_CARS_DATA;
select * from ONET_TITLE_AND_DESCRIPTION 
 where lower(job_title) like '%engineer%' order by 2;


-- looking at word separators - / & etc
select job_title, count(*)
  from job_titles_and_descriptions
 where 1=1
--   and regexp_like(job_title, '[A-Za-z0-9][-][A-Za-z0-9]')
   and regexp_like(job_title, '[A-Za-z][-][A-Za-z]') 
   and not (lower(job_title) like '%non-%' or 
            lower(job_title) like '%co-op%') -- non-technical, non-it, etc.   This is a good clause for replacing dash with space
 group by job_title
 order by 2 desc
;

-- regex expirements
with data as (select 'x' as c from dual union all select '1' from dual union all select '$' from dual)
select c, 
       case when regexp_like(c, '[:alpha:]') then 'match' end as match_label1,
       case when regexp_like(c, '[A-Za-z0-9]') then 'match' end         as match_label2
  from data;

--- find some unnormalized titles
select industry, job_title, normalized_title, short_desc, job_description
  from job_titles_and_descriptions
 where 1=1
    and lowercase_job_title LIKE '%programmer%'  -- not writer
 order by 3 desc,2;
 
-- why did this miss accounting clerk and accounting associate?

--- use the classification model
 WITH bogus_descriptions
    AS (SELECT 'java developer' AS job_description FROM dual
         UNION ALL
        SELECT 'This position will require you to administer an oracle database' FROM dual
         UNION ALL
        SELECT 'health practitioner' AS job_description FROM dual
         UNION ALL
        SELECT 'The Data Engineer will be part of a team delivering business intelligence solutions in Finance 
        and Supply Chain. The clients technologies include a traditional Data Warehouse with Tableau / Cognos 
        reporting and a Big Data solution that we are moving to Microsoft Azure. Projects are now run in an Agile
        methodology, utilizing Rally or Jira, in addition to applying DevOps principles. The Data Engineer will be 
        working with the Development Team, developing reporting and data movement solutions. The software application 
        landscape includes many technologies:
 Data Visualization (Tableau, Cognos, Power BI). 
 Data Movement (DataStage, Informatica, Sqoop) 
 Databases technologies include: Oracle and Hadoop Databases' AS job_description FROM dual)
SELECT job_description,
       PREDICTION (job_desc_svm USING *) AS predicted_job_title,
       PREDICTION_DETAILS (job_desc_svm USING *) AS prediction_details
       --PREDICTION_SET (job_desc_svm USING *) AS prediction_set  -- gets an ORA-22833 error
  FROM bogus_descriptions
/

--- use the clustering model to show which cluster this doc _might_ go into
  WITH bogus_description
    AS (
         SELECT 'java developer' FROM dual
--         SELECT 'health care' FROM dual
--         SELECT 'accounts payable' FROM dual
       )
SELECT x.*, t.title_list
  FROM TABLE(SELECT CLUSTER_SET (job_desc_kmeans USING *) AS predicted_cluster_id
               FROM bogus_description a
            ) x,
       titles_by_cluster t     
 WHERE x.cluster_id = t.predicted_cluster_id      
 ORDER BY probability DESC            
/




-- 368 distinct "combined titles"
select COUNT(*) AS all_assignments,
       count(distinct NVL(j.normalized_title, j.job_title))
  from kmeans_model_source_v v,
       job_titles_and_descriptions j
 where v.assignment_pk = j.assignment_pk       ;

-- assignments and the cluster they sorted into
select * from assignments_to_cluster_ids;

-- now take those clusters and count the number of assignments and distinct combined titles in each.
  with clusters_and_titles
    as (select c.predicted_cluster_id, NVL(j.normalized_title, j.job_title) as combined_title
          from job_titles_and_descriptions j,
               assignments_to_cluster_ids c
         where c.assignment_pk = j.assignment_pk)
select predicted_cluster_id, 
       count(*) as assignment_count, count(distinct combined_title) as distinct_titles
  from clusters_and_titles
 group by predicted_cluster_id
 order by 2 desc; 

-- any of those titles in more than one cluster?
  with clusters_and_titles
    as (select c.predicted_cluster_id, NVL(j.normalized_title, j.job_title) as combined_title
          from job_titles_and_descriptions j,
               assignments_to_cluster_ids c
         where c.assignment_pk = j.assignment_pk)
select combined_title, 
       count(*) as assignment_count, count(distinct predicted_cluster_id) as distinct_clusters
  from clusters_and_titles
 group by combined_title
 order by 2 desc; 

  
-- even though the data doesn't really match up 1:1, lets make a list of titles per cluster
-- we can then use that when scoring new descriptions
  WITH clusters_and_titles
    AS (SELECT C.predicted_cluster_id, nvl(j.normalized_title, j.job_title) AS combined_title
          FROM job_titles_and_descriptions j,
               assignments_to_cluster_ids C
         WHERE C.assignment_pk = j.assignment_pk)
SELECT predicted_cluster_id,
       LISTAGG(combined_title, ', ') WITHIN GROUP (ORDER BY assignments DESC) AS title_list
  FROM (SELECT predicted_cluster_id,
               combined_title,
               COUNT(*) AS assignments
          FROM clusters_and_titles
         GROUP BY predicted_cluster_id, combined_title)
  GROUP BY predicted_cluster_id;
  
