CREATE MATERIALIZED VIEW DASH_INVOICE_CUBE_MV
TABLESPACE MART_USERS50M
LOGGING
BUILD IMMEDIATE
USING INDEX TABLESPACE MART_USERS50M
REFRESH FORCE ON DEMAND
WITH PRIMARY KEY
ENABLE QUERY REWRITE
AS 
select /*+ FULL(f) FULL(b) FULL(s) FULL(d) FULL(geo) FULL(c) FULL(c1) FULL(c2) FULL(j) FULL(geo1) FULL(geo2) FULL(eng) FULL(exp) PARALLEL(f,64) */ 
       NVL(b.ORG_ID,-1)    								buyer_org_id,
       NVL(b.ORG_NAME,'NONE')                                        buyer_org_name,
       NVL(b.LATEST_ORG_NAME,'NONE')                                 buyer_latest_org_name,
       NVL(s.ORG_ID ,-1)                                             supplier_org_id,
       NVL(s.ORG_NAME,'NONE')                                        supplier_org_name,
       NVL(s.LATEST_ORG_NAME,'NONE')                                 supplier_latest_org_name,
       NVL(c.currency_code,'N/A')                                    local_currency_code,
       NVL(f.engagement_classification,'NONE')                       engagement_classification,
       NVL(eng.engagement_type,'NONE')                               engagement_type,
       CASE WHEN exp.expenditure_category = 'Payment Request' THEN
                 'Payment Request'
            ELSE NVL(exp.expenditure_type,'NONE')
       END                                                           expenditure_type,
       NVL(exp.expenditure_category,'NONE')                          expenditure_category,
       d.day_dt                                                      invoice_date,
       'ALL'                                                         shard_name,
       NVL(d.year_id_disp,'NONE')                                    calendar_year,
       NVL(NVL(d.fiscal_year_id_disp,d.year_id_disp),'NONE')         fiscal_year,
       CASE
          WHEN d.quarter_name IS NOT NULL AND d.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d.year_id_disp
              WHEN UPPER(d.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d.year_id_disp
              WHEN UPPER(d.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d.year_id_disp
              WHEN UPPER(d.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d.year_id_disp
           END
          ELSE
           'NONE'
       END                                                         calendar_quarter,
       CASE
          WHEN NVL(d.fiscal_quarter_name,d.quarter_name) IS NOT NULL AND NVL(d.fiscal_year_id_disp,d.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
            END
          ELSE
           'NONE'
          END                                                   fiscal_quarter,
       CASE
           WHEN d.month_name IS NOT NULL AND d.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d.month_name), 1, 3) || '-' || d.year_id_disp
           ELSE
                'NONE'
           END                                                  calendar_month,
       CASE
           WHEN NVL(d.fiscal_month_name,d.month_name) IS NOT NULL AND NVL(d.fiscal_year_id_disp,d.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d.fiscal_month_name,d.month_name)), 1, 3) || '-' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
           ELSE
                'NONE'
        END                                                     fiscal_month,
       NVL(j.job_id,-1)                                              job_id,
       NVL(j.job_category_desc,'NONE')                               job_category,
       NVL(j.job_title,'NONE')                                       job_title,
       NVL(j.job_level_desc,'NONE')                                  job_level,
       NVL(j.job_category_id,-1)                                     job_category_id,
       NVL(j.job_level_id,-1)                                        job_level_id,
       a.custom_place_id                                custom_place_id,
       a.standard_place_id                                standard_place_id,
       NVL(a.sourcing_method,'NONE')                        sourcing_method,
	  NVL(NVL(a.CUSTOM_COUNTRY_NAME,a.ADDRESS_COUNTRY_NAME),'NONE') 			LOCATION_COUNTRY,
	  NVL(NVL(a.CUSTOM_ADDRESS_STATE,a.ADDRESS_STATE),'NONE') 					LOCATION_STATE,
	  NVL(NVL(a.CUSTOM_ADDRESS_CITY,a.ADDRESS_CITY),'NONE') 					LOCATION_CITY,
       f.EXPENDITURE_NUMBER                                     expenditure_number,
       f.INVOICE_NUMBER                                          invoice_number,
       SUM(f.DT_HOURS)                                                   doubletime_hours,
       SUM(f.DT_HOURS_SUPP_REIMB_AMT)                             doubletime_hours_amt_local,
       SUM(f.DT_HOURS_SUPP_REIMB_AMT_USD)                         doubletime_hours_amt_usd,
       SUM(f.DT_HOURS_SUPP_REIMB_AMT_EUR)                         doubletime_hours_amt_eur,
       SUM(f.DT_HOURS_SUPP_REIMB_AMT_GBP)                         doubletime_hours_amt_gbp,
       SUM(f.OT_HOURS)                                                   overtime_hours,     
       SUM(f.OT_HOURS_SUPP_REIMB_AMT)                             overtime_hours_amt_local,
       SUM(f.OT_HOURS_SUPP_REIMB_AMT_USD)                         overtime_hours_amt_usd,
       SUM(f.OT_HOURS_SUPP_REIMB_AMT_EUR)                         overtime_hours_amt_eur,
       SUM(f.OT_HOURS_SUPP_REIMB_AMT_GBP)                         overtime_hours_amt_gbp,
       SUM(f.REG_HOURS)                                                  regular_hours,
       SUM(f.REG_HOURS_SUPP_REIMB_AMT)                            regular_hours_amt_local,
       SUM(f.REG_HOURS_SUPP_REIMB_AMT_USD)                           regular_hours_amt_usd,
       SUM(f.REG_HOURS_SUPP_REIMB_AMT_EUR)                           regular_hours_amt_eur,
       SUM(f.REG_HOURS_SUPP_REIMB_AMT_GBP)                           regular_hours_amt_gbp,
       SUM(f.CS_HOURS)                                                   custom_hours,
       SUM(f.CS_HOURS_SUPP_REIMB_AMT)                            custom_hours_amt_local,
       SUM(f.CS_HOURS_SUPP_REIMB_AMT_USD)                         custom_hours_amt_usd,
       SUM(f.CS_HOURS_SUPP_REIMB_AMT_EUR)                         custom_hours_amt_eur,
       SUM(f.CS_HOURS_SUPP_REIMB_AMT_GBP)                         custom_hours_amt_gbp,
       SUM(f.SUPP_REIMB_AMT)                                      total_spend_amt_local,
       SUM(f.SUPP_REIMB_AMT_USD)                                  total_spend_amt_usd,
       SUM(f.SUPP_REIMB_AMT_EUR)                                  total_spend_amt_eur,
       SUM(f.SUPP_REIMB_AMT_GBP)                                  total_spend_amt_gbp,
       SUM(f.TAX_AMT)                                             tax_amt_local,
       SUM(f.TAX_AMT_USD)                                         tax_amt_usd,
       SUM(f.TAX_AMT_EUR)                                         tax_amt_eur,
       SUM(f.TAX_AMT_GBP)                                         tax_amt_gbp,
       SUM(f.TOTAL_FEE)                                              total_fee_local,
       SUM(f.TOTAL_FEE_USD)                                          total_fee_usd,
       SUM(f.TOTAL_FEE_EUR)                                          total_fee_eur,
       SUM(f.TOTAL_FEE_GBP)                                          total_fee_gbp,
       SUM(f.buyer_fee)                                              buyer_fee_local,
       SUM(f.buyer_fee_usd)                                          buyer_fee_usd,
       SUM(f.buyer_fee_eur)                                          buyer_fee_eur,
       SUM(f.buyer_fee_gbp)                                          buyer_fee_gbp,
       SUM(f.supplier_fee)                                           supplier_fee_local,
       SUM(f.supplier_fee_usd)                                       supplier_fee_usd,
       SUM(f.supplier_fee_eur)                                       supplier_fee_eur,
       SUM(f.supplier_fee_gbp)                                       supplier_fee_gbp
from   dm_invoice_fact_v f, 
       dm_buyer_dim b,  
       dm_supplier_dim s,
       dm_date_dim d, 
       dm_geo_dim geo, 
       dm_country_dim c,
       dm_country_dim c1,
       dm_job_dim j,
       dm_geo_dim geo1,
       DM_ENGAGEMENT_TYPE_DIM eng,
       dm_expenditure_dim exp,
       dm_assignment_dim a
where   f.buyer_org_dim_id = b.org_dim_id
and f.supplier_org_dim_id = s.org_dim_id
and f.invoice_date_dim_id = d.date_dim_id
and f.BUYER_GEO_DIM_ID = geo.geo_dim_id(+)
and f.job_dim_id = j.job_dim_id(+)
and f.ENGAGEMENT_TYPE_DIM_ID  = eng.ENGAGEMENT_TYPE_DIM_ID(+)
and f.expenditure_dim_id  = exp.expenditure_dim_id(+)
and f.SUPPLIER_GEO_DIM_ID=geo1.geo_dim_id(+) 
and geo.country_dim_id = c.COUNTRY_DIM_ID(+)  
and geo1.country_dim_id = c1.COUNTRY_DIM_ID(+)      
and f.assignment_dim_id = a.assignment_dim_id(+)
group by NVL(b.ORG_ID,-1) ,
       NVL(b.ORG_NAME,'NONE'),
       NVL(b.LATEST_ORG_NAME,'NONE'),
       NVL(s.ORG_ID ,-1),
       NVL(s.ORG_NAME,'NONE'),
       NVL(s.LATEST_ORG_NAME,'NONE'),
       NVL(c.currency_code,'N/A'),
       NVL(f.engagement_classification,'NONE'),
       NVL(eng.engagement_type,'NONE'),
       CASE WHEN exp.expenditure_category = 'Payment Request' THEN
                 'Payment Request'
            ELSE NVL(exp.expenditure_type,'NONE')
       END ,
       NVL(exp.expenditure_category,'NONE'),
       d.day_dt,
       'ALL' ,
       NVL(d.year_id_disp,'NONE') ,
       NVL(NVL(d.fiscal_year_id_disp,d.year_id_disp),'NONE') ,
       CASE
          WHEN d.quarter_name IS NOT NULL AND d.year_id_disp IS NOT NULL THEN
           CASE
              WHEN UPPER(d.quarter_name) = 'FIRST QUARTER' THEN 'Q1 ' || d.year_id_disp
              WHEN UPPER(d.quarter_name) = 'SECOND QUARTER' THEN 'Q2 ' || d.year_id_disp
              WHEN UPPER(d.quarter_name) = 'THIRD QUARTER' THEN 'Q3 ' || d.year_id_disp
              WHEN UPPER(d.quarter_name) = 'FOURTH QUARTER' THEN 'Q4 ' || d.year_id_disp
           END
          ELSE
           'NONE'
       END  ,
       CASE
          WHEN NVL(d.fiscal_quarter_name,d.quarter_name) IS NOT NULL AND NVL(d.fiscal_year_id_disp,d.year_id_disp) IS NOT NULL THEN
            CASE
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'FIRST QUARTER' THEN 'Q1 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'SECOND QUARTER' THEN 'Q2 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'THIRD QUARTER' THEN 'Q3 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
              WHEN UPPER(NVL(d.fiscal_quarter_name,d.quarter_name)) = 'FOURTH QUARTER' THEN 'Q4 ' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
            END
          ELSE
           'NONE'
          END,
       CASE
           WHEN d.month_name IS NOT NULL AND d.year_id_disp IS NOT NULL THEN
                SUBSTR (UPPER(d.month_name), 1, 3) || '-' || d.year_id_disp
           ELSE
                'NONE'
           END,
       CASE
           WHEN NVL(d.fiscal_month_name,d.month_name) IS NOT NULL AND NVL(d.fiscal_year_id_disp,d.year_id_disp) IS NOT NULL THEN
                 SUBSTR (UPPER(NVL(d.fiscal_month_name,d.month_name)), 1, 3) || '-' || NVL(d.fiscal_year_id_disp,d.year_id_disp)
           ELSE
                'NONE'
        END   ,
       NVL(j.job_id,-1) ,
       NVL(j.job_category_desc,'NONE') ,
       NVL(j.job_title,'NONE')      ,
       NVL(j.job_level_desc,'NONE') ,
       NVL(j.job_category_id,-1)    ,
       NVL(j.job_level_id,-1)       ,
       a.custom_place_id            ,
       a.standard_place_id          ,
       NVL(a.sourcing_method,'NONE'),
	   NVL(NVL(a.CUSTOM_COUNTRY_NAME,a.ADDRESS_COUNTRY_NAME),'NONE') ,
	  NVL(NVL(a.CUSTOM_ADDRESS_STATE,a.ADDRESS_STATE),'NONE') ,
	  NVL(NVL(a.CUSTOM_ADDRESS_CITY,a.ADDRESS_CITY),'NONE') ,		
       f.EXPENDITURE_NUMBER,
       f.INVOICE_NUMBER     
/


