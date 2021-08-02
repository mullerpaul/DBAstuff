INSERT INTO dm_date_dim
  (date_dim_id, day_dt, top_parent_buyer_org_id, data_source_code, 
   day_of_week, day_of_month, day_of_year, julian_day, day_name, day_abbr, 
   week_id, week_id_disp, week_of_year, week_of_month, 
   month_id, month_id_disp, month_of_year, month_name, month_abbr, month_duration, 
   quarter_id, quarter_id_disp, quarter_nbr, quarter_name, quarter_duration, 
   year_id, year_id_disp, year_duration, 
   fiscal_day_of_week, fiscal_day_of_month, fiscal_day_of_year, 
   fiscal_week_id, fiscal_week_id_disp, fiscal_week_of_year, fiscal_week_of_month, 
   fiscal_month_id, fiscal_month_id_disp, fiscal_month_of_year, fiscal_month_name, fiscal_month_abbr, fiscal_month_duration, 
   fiscal_quarter_nbr, fiscal_quarter_name, fiscal_quarter_duration, 
   fiscal_year_id, fiscal_year_id_disp, fiscal_year_duration, 
   fiscal_quarter_id, fiscal_quarter_id_disp, 
   last_update_date)
-- config set   
  WITH config_data
    AS (SELECT 7                                    AS number_of_years, -- number of years of data to build 
               TO_DATE('2017-Jan-01','YYYY-Mon-DD') AS first_new_day    -- first new date to be loaded
          FROM dual),
-- helper sets
       day_list
    AS (SELECT config_data.first_new_day + (ROWNUM - 1) AS the_day
          FROM config_data,
               all_source -- using this as a "row generator" as it will certainly have more rows than we need 
         WHERE ROWNUM <= (add_months(first_new_day, 12 * number_of_years) - first_new_day)),  -- add_months takes care of leap years for us!
       top_level_org_list
    AS (SELECT 0 AS org_id, 'REGULAR' AS data_source_code
          FROM dual)
-- main select
SELECT to_number(to_char(d.the_day, 'YYYYMMDD') || '100' || to_char(tlo.org_id)) AS date_dim_id,
       d.the_day            AS day_dt, 
       tlo.org_id           AS top_parent_buyer_org_id,
       tlo.data_source_code AS data_source_code,
       to_number(to_char(d.the_day, 'D'))   AS day_of_week,
       to_number(to_char(d.the_day, 'DD'))  AS day_of_month, 
       to_number(to_char(d.the_day, 'DDD')) AS day_of_year,
       to_number(to_char(d.the_day, 'J'))   AS julian_day,
       trim(to_char(d.the_day, 'DAY', 'NLS_DATE_LANGUAGE = AMERICAN'))   AS day_name,
       to_char(d.the_day, 'DY', 'NLS_DATE_LANGUAGE = AMERICAN')          AS day_abbr,
       to_number(to_char(d.the_day,'YY') || to_char(d.the_day, 'WW') || to_char(org_id)) AS week_id,
       to_char(d.the_day,'YYYY') || to_char(d.the_day, 'WW')             AS week_id_disp,
       to_number(to_char(d.the_day, 'WW'))  AS week_of_year,  -- where week starts on first day of year ( use 'IW' for standard weeks)
       to_number(to_char(d.the_day, 'W'))   AS week_of_month,  -- where week starts on first day of month
       to_number(to_char(d.the_day,'YY') || to_char(d.the_day, 'MM') || to_char(org_id)) AS month_id,
       to_char(d.the_day,'YYYY') || to_char(d.the_day, 'MM')             AS month_id_disp,
       to_number(to_char(d.the_day, 'MM'))  AS month_of_year,
       trim(to_char(d.the_day, 'MONTH', 'NLS_DATE_LANGUAGE = AMERICAN')) AS month_name,
       to_char(d.the_day, 'MON', 'NLS_DATE_LANGUAGE = AMERICAN')         AS month_abbr,
       to_number(to_char(last_day(d.the_day), 'DD'))                     AS month_duration,
       to_number(to_char(d.the_day,'YY') || to_char(d.the_day, 'Q') || to_char(org_id)) AS quarter_id,
       to_char(d.the_day,'YYYY') || to_char(d.the_day, 'Q') AS quarter_id_disp,
       to_number(to_char(d.the_day, 'Q'))   AS quarter_nbr,
       CASE 
         WHEN to_number(to_char(d.the_day, 'Q')) = 1 THEN 'First Quarter'
         WHEN to_number(to_char(d.the_day, 'Q')) = 2 THEN 'Second Quarter'
         WHEN to_number(to_char(d.the_day, 'Q')) = 3 THEN 'Third Quarter'
         WHEN to_number(to_char(d.the_day, 'Q')) = 4 THEN 'Fourth Quarter'
       END AS quarter_name,
       TRUNC(add_months(d.the_day, 3), 'Q') - TRUNC(d.the_day, 'Q')           AS quarter_duration, --existing data WRONGLY shows 90 for all rows!!
       to_number(to_char(d.the_day,'YY') || to_char(org_id)) AS year_id,
       to_char(d.the_day,'YYYY')            AS year_id_disp,
       TRUNC(add_months(d.the_day, 12), 'YYYY') - TRUNC(d.the_day, 'YYYY')    AS year_duration,  --existing data is WRONG in leap years!
       NULL AS fiscal_day_of_week,
       NULL AS fiscal_day_of_month,
       NULL AS fiscal_day_of_year,
       NULL AS fiscal_week_id,
       NULL AS fiscal_week_id_disp,
       NULL AS fiscal_week_of_year,
       NULL AS fiscal_week_of_month,
       0    AS fiscal_month_id,  -- update this when updating all other "FISCAL" columns.
       NULL AS fiscal_month_id_disp,
       NULL AS fiscal_month_of_year,
       NULL AS fiscal_month_name,
       NULL AS fiscal_month_abbr,
       NULL AS fiscal_month_duration,
       NULL AS fiscal_quarter_nbr,
       NULL AS fiscal_quarter_name,
       NULL AS fiscal_quarter_duration,
       NULL AS fiscal_year_id,
       NULL AS fiscal_year_id_disp,
       NULL AS fiscal_year_duration,
       NULL AS fiscal_quarter_id,
       NULL AS fiscal_quarter_id_disp,
       SYSDATE AS last_update_date
  FROM day_list d,
       top_level_org_list tlo
/
  
-- update all FISCAL stuff (here?  separate ticket?  or never? (since it appears to be unused)

COMMIT
/

 

  