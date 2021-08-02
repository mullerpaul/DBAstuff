CREATE OR REPLACE FORCE VIEW DM_HEADCOUNT_FACT_V
  					AS
					SELECT ASSIGNMENT_ID,
       					ASSIGNMENT_DIM_ID,
       					ASSIGNMENT_TYPE,
       					ASSIGNMENT_DATE_DIM_ID,
       					WORKER_ID,
       					WORKER_DIM_ID,
       					JOB_DIM_ID,
       					WORK_LOC_GEO_DIM_ID,
       					BUYER_GEO_DIM_ID,
       					SUPPLIER_ORG_DIM_ID,
       					BUYER_ORG_DIM_ID,
       					ASSIGNMENT_DATE_ID,
       					BUYER_ORG_ID,
       					WORKER_COUNT,
       					DELETE_FLAG,
       					DATA_SOURCE_CODE,
                                TOP_PARENT_BUYER_ORG_ID,
       					FACT_SEQUENCE,
       					LAST_UPDATE_DATE
  					FROM 
  					   ( SELECT ASSIGNMENT_ID,
               					ASSIGNMENT_DIM_ID,
               					ASSIGNMENT_TYPE,
               					data.date_dim_id AS assignment_date_dim_id,
               					WORKER_ID,
               					WORKER_DIM_ID,
               					JOB_DIM_ID,
               					WORK_LOC_GEO_DIM_ID,
               					BUYER_GEO_DIM_ID,
               					SUPPLIER_ORG_DIM_ID,
               					BUYER_ORG_DIM_ID,
               					TO_NUMBER(TO_CHAR(TRUNC(data.day_dt),'YYYYMMDD')) AS assignment_date_id,
               					BUYER_ORG_ID,
               					WORKER_COUNT,
               					DELETE_FLAG,
               					DATA_SOURCE_CODE,
                                     a.TOP_PARENT_BUYER_ORG_ID,
               					FACT_SEQUENCE,
               					LAST_UPDATE_DATE
          					FROM dm_hc_fact a,(select dd.date_dim_id,dd.top_parent_buyer_org_id,dd.day_dt from dm_date_dim dd ) data
         					WHERE delete_flag = 'N'
           				AND assignment_start_date < TRUNC (SYSDATE) + 1
           				AND a.TOP_PARENT_BUYER_ORG_ID = data.top_parent_buyer_org_id
           				AND data.day_dt between assignment_start_date and assignment_end_date
     						)
					WHERE  assignment_date_id <= TO_CHAR (TRUNC (SYSDATE),'YYYYMMDD')
/

DECLARE 
  lv_status VARCHAR2(30);
BEGIN
  SELECT status 
    INTO lv_status
    FROM user_objects 
   WHERE object_name = 'DM_HEADCOUNT_FACT_V';
  
  IF lv_status = 'VALID' THEN
    EXECUTE IMMEDIATE 'GRANT SELECT ON DM_HEADCOUNT_FACT_V TO PUBLIC';
  END IF;
END;
/ 

