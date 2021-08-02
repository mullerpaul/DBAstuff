CREATE OR REPLACE FORCE VIEW dm_rate_summary_lv
(
 GEOGRAPHIC_LEVEL,                    
 STD_REGION_ID,
 STD_REGION_TYPE_ID,
 STD_REGION_DESC,
 CMSA_CODE,
 CMSA_NAME,
 PERIOD_NUMBER,                  
 PERIOD_TYPE,                    
 STD_JOB_TITLE_ID,
 STD_JOB_TITLE_DESC,
 STD_JOB_DESC,
 STD_JOB_CATEGORY_ID,
 STD_JOB_CATEGORY_DESC, 
 STD_JOB_LEVEL_ID,
 EXPERIENCE_LEVEL,
 EXP_LEVEL_BILL_RATE,
 ASSIGNMENT_DATA_POINTS,           
 AVG_REG_BILL_RATE,                          
 REG_BILL_RATE_10_PCTL,               
 REG_BILL_RATE_25_PCTL,                   
 REG_BILL_RATE_50_PCTL,               
 REG_BILL_RATE_75_PCTL,                   
 REG_BILL_RATE_90_PCTL,                   
 CURRENCY_DESCRIPTION,
 MIN_EXP_YEARS,
 MAX_EXP_YEARS,
 GEOGRAPHIC_LEVEL_ID
)
AS
SELECT CASE
       WHEN gr.geographic_level = 'R1' THEN
         'Geographic Region'
       WHEN gr.geographic_level = 'R5' THEN
         'COLA Region'         
       WHEN gr.geographic_level = 'JCN' THEN
         'Job Category at National Level'
       WHEN gr.geographic_level = 'JCR1' THEN
         'Job Category at Geographic Region Level'
       WHEN gr.geographic_level = 'JCR5' THEN
         'Job Category at COLA Region Level'         
       WHEN gr.geographic_level = 'JCC' THEN
         'Job Category at Metro Area Level'
       WHEN gr.geographic_level = 'C' THEN
         'Metro Area'
       WHEN gr.geographic_level = 'N' THEN
         'National'
       END                                                                     geographic_level,
       gr.std_region_id                                                        std_region_id,
       r.std_region_type_id                                                    std_region_type_id,
       r.std_region_desc                                                       std_region_desc,
       gr.cmsa_code                                                            cmsa_code,
       c.metro_name                                                             cmsa_name,
       gr.period_number                                                        period_number,
       CASE
       WHEN gr.period_type = 'M' THEN
         'Month'
       WHEN gr.period_type = 'Q' THEN
         'Quarter'
       WHEN gr.period_type = 'Y' THEN
         'Year/YTD'
       END                                                                     period_type,
       gr.std_job_title_id                                                     std_job_title_id,
       jt.std_job_title_desc                                                   std_job_title_desc,
       jt.std_job_desc                                                         std_job_desc,
       gr.std_job_category_id                                                  std_job_category_id,
       jc.std_job_category_desc                                                std_job_category_desc,
       lvl.std_job_level_id                                                    std_job_level_id,
       lvl.std_job_level_desc                                                  experience_level,
       CASE
       WHEN lvl.level_pctl = 10 THEN
         gr.reg_bill_rate_10_pctl
       WHEN lvl.level_pctl = 25 THEN
         gr.reg_bill_rate_25_pctl
       WHEN lvl.level_pctl = 50 THEN
         gr.reg_bill_rate_50_pctl
       WHEN lvl.level_pctl = 75 THEN
         gr.reg_bill_rate_75_pctl
       WHEN lvl.level_pctl = 90 THEN
         gr.reg_bill_rate_90_pctl
       END                                                                     exp_level_bill_rate,
       gr.assignment_data_points                                               assignment_data_points,
       gr.avg_reg_bill_rate                                                    avg_reg_bill_rate,
       gr.reg_bill_rate_10_pctl                                                reg_bill_rate_10_pctl,
       gr.reg_bill_rate_25_pctl                                                reg_bill_rate_25_pctl,
       gr.reg_bill_rate_50_pctl                                                reg_bill_rate_50_pctl,
       gr.reg_bill_rate_75_pctl                                                reg_bill_rate_75_pctl,
       gr.reg_bill_rate_90_pctl                                                reg_bill_rate_90_pctl,
       gr.currency_description                                                 currency_description,
       lvl.min_exp_years                                                       min_exp_years,
       lvl.max_exp_years                                                       max_exp_years,
       gr.geographic_level                                                     geographic_level
  FROM dm_geographic_rates_summary gr,
       dm_regions                  r,
       dm_cmsa                     c,
       dm_job_category             jc,
       dm_job_titles               jt,
       dm_job_title_levels         lvl
 WHERE gr.STD_JOB_TITLE_ID    =  lvl.STD_JOB_TITLE_ID(+)
   AND gr.STD_REGION_ID       =  r.STD_REGION_ID(+)
   AND gr.cmsa_code           =  c.cmsa_code(+)
   AND gr.std_job_category_id =  jc.std_job_category_id
   AND gr.std_job_title_id    =  jt.std_job_title_id(+)
   AND gr.new_assignment_flag =  'N'  
/

DECLARE 
  lv_status VARCHAR2(30);
BEGIN
  SELECT status 
    INTO lv_status
    FROM user_objects 
   WHERE object_name = 'DM_RATE_SUMMARY_LV';
  
  IF lv_status = 'VALID' THEN
    EXECUTE IMMEDIATE 'GRANT SELECT ON DM_RATE_SUMMARY_LV TO PUBLIC';
  END IF;
END;
/ 

