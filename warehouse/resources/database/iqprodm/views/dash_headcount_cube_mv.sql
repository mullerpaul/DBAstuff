CREATE MATERIALIZED VIEW DASH_HEADCOUNT_CUBE_MV
TABLESPACE MART_USERS50M
LOGGING
BUILD IMMEDIATE
USING INDEX TABLESPACE MART_USERS50M
REFRESH FORCE ON DEMAND
WITH PRIMARY KEY
AS 
    SELECT NVL(buyer_org_id,-1)                   buyer_org_id,
             NVL(buyer_org_name,'NONE')             buyer_org_name,
             NVL(buyer_latest_org_name,'NONE')         buyer_latest_org_name,
             NVL(supplier_org_id,-1)                 supplier_org_id,
             NVL(supplier_org_name,'NONE')             supplier_org_name,
             NVL(supplier_latest_org_name,'NONE')         supplier_latest_org_name,
             NVL(engagement_type,'NONE')             engagement_type,
             NVL(job_id,-1)                         job_id,
             NVL(job_category,'NONE')                   job_category,
             NVL(job_title,'NONE')                      job_title,
             NVL(job_level,'NONE')                      job_level,
             NVL(job_category_id,-1)                 job_category_id,
             NVL(job_level_id,-1)                     job_level_id,
             NVL(assignment_country,'NONE')             location_country,
             NVL(assignment_state,'NONE')             location_state,
             NVL(assignment_city,'NONE')             location_city, 
             assignment_start_date,
             assignment_end_date,
		  assignment_month_start_date,
             assignment_month_end_date,
             worker_id,
             NVL(NVL(d.fiscal_year_id_disp,d.year_id_disp),'NONE')     fiscal_year,
        CASE
          WHEN NVL (d.fiscal_quarter_name, d.quarter_name) IS NOT NULL
               AND NVL (d.fiscal_year_id_disp, d.year_id_disp) IS NOT NULL
          THEN
             CASE
                WHEN UPPER (NVL (d.fiscal_quarter_name, d.quarter_name)) =
                        'FIRST QUARTER'
                THEN
                   'Q1 ' || NVL (d.fiscal_year_id_disp, d.year_id_disp)
                WHEN UPPER (NVL (d.fiscal_quarter_name, d.quarter_name)) =
                        'SECOND QUARTER'
                THEN
                   'Q2 ' || NVL (d.fiscal_year_id_disp, d.year_id_disp)
                WHEN UPPER (NVL (d.fiscal_quarter_name, d.quarter_name)) =
                        'THIRD QUARTER'
                THEN
                   'Q3 ' || NVL (d.fiscal_year_id_disp, d.year_id_disp)
                WHEN UPPER (NVL (d.fiscal_quarter_name, d.quarter_name)) =
                        'FOURTH QUARTER'
                THEN
                   'Q4 ' || NVL (d.fiscal_year_id_disp, d.year_id_disp)
             END
          ELSE
             'NONE'
       END
          fiscal_quarter,
           CASE
          WHEN NVL (d.fiscal_month_name, d.month_name) IS NOT NULL
               AND NVL (d.fiscal_year_id_disp, d.year_id_disp) IS NOT NULL
          THEN
             SUBSTR (UPPER (NVL (d.fiscal_month_name, d.month_name)), 1, 3)
             || '-'
             || NVL (d.fiscal_year_id_disp, d.year_id_disp)
          ELSE
             'NONE'
       END
          fiscal_month
     FROM ( 
             WITH data as (select level lv from dual connect by level <= 1000)
             SELECT 	assignment_id,
                 	buyer_org_id,
                	buyer_org_name,
                 	buyer_latest_org_name,
                 	supplier_org_id,
                	supplier_org_name,
                	supplier_latest_org_name,
                	engagement_type,
                	job_id,
                	job_category,
                	job_title,
                	job_level,
                	job_category_id,
                	job_level_id,
                	assignment_country,
                	assignment_state,
                	assignment_city,
                	worker_id,
                	assignment_start_date,
                	assignment_end_date,
                     GREATEST(assignment_start_date,TRUNC(add_months(assignment_start_date,(lv - 1)),'MONTH')) AS assignment_month_start_date,
                     LEAST(assignment_end_date,TRUNC(last_day(add_months(assignment_start_date,(lv - 1)))))    AS assignment_month_end_date,
                     to_char(GREATEST(assignment_start_date,TRUNC(add_months(assignment_start_date,(lv - 1)),'MONTH')),'YYYYMMDD') ||to_char(data_source_id)||to_char(top_parent_buyer_org_id) as assignment_m_start_date_dim_id
                  -- to_char(LEAST(assignment_end_date,TRUNC(last_day(add_months(assignment_start_date,(lv - 1))))),'YYYYMMDD') ||to_char(data_source_id)||to_char(top_parent_buyer_org_id) as assignment_m_end_date_dim_id
            FROM ( SELECT /*+ PARALLEL(f,8) */ f.assignment_id               assignment_id,
                               b.ORG_ID                                      buyer_org_id,
                               b.ORG_NAME                                    buyer_org_name,
                               b.LATEST_ORG_NAME                             buyer_latest_org_name,
                               s.ORG_ID                                      supplier_org_id,
                               s.ORG_NAME                                    supplier_org_name,
                               s.LATEST_ORG_NAME                             supplier_latest_org_name,
                               eng.engagement_type                           engagement_type,
                               j.job_id                                      job_id,
                               j.job_category_desc                           job_category,
                               j.job_title                                   job_title,
                               j.job_level_desc                              job_level,
                               j.job_category_id                             job_category_id,
                               j.job_level_id                                job_level_id,
                               c.iso_country_name                            assignment_country,
                               geo.state_name                                assignment_state,
                               geo.city_name                                 assignment_city,
                               f.worker_id                            	  worker_id,
                               f.assignment_start_date                       assignment_start_date,
                               f.assignment_end_date                         assignment_end_date,
                               f.data_source_id                              data_source_id,
                               f.top_parent_buyer_org_id                     top_parent_buyer_org_id
                    FROM   DM_HC_FACT f, 
                             dm_buyer_dim b,  
                             dm_supplier_dim s,
                              dm_country_dim c,
                             dm_job_dim j,
                             dm_geo_dim geo,
                             DM_ENGAGEMENT_TYPE_DIM eng
                    where f.delete_flag = 'N'  
                    and      f.buyer_org_dim_id = b.org_dim_id
                    and   f.supplier_org_dim_id = s.org_dim_id
                    and   f.job_dim_id = j.job_dim_id(+)
                    and   f.WORK_LOC_GEO_DIM_ID=geo.geo_dim_id(+)
                    and  geo.country_dim_id = c.COUNTRY_DIM_ID(+)
                    and  f.ENGAGEMENT_TYPE_DIM_ID  = eng.ENGAGEMENT_TYPE_DIM_ID(+)
                   ), data where lv <= FLOOR(MONTHS_BETWEEN(TRUNC(assignment_end_date,'MONTH'),TRUNC(assignment_start_date,'MONTH')) + 1 )
        ) a, dm_date_dim d
     WHERE a.assignment_m_start_date_dim_id = d.date_dim_id;