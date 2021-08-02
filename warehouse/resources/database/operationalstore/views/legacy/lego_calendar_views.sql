CREATE OR REPLACE FORCE VIEW  lego_calendar_vw AS 
				SELECT cal.buyer_org_id,
  						 date_id,
  						 day_dt,
  						 year_id,
  						 quarter_id,
  						 month_id,
  						 week_id,
  						 day_of_week,
  						 day_of_month,
  						 day_of_year,
  						 julian_day,
  						 day_name,
  						 day_abbr,
  						 week_of_year,
  						 week_of_month,
  						 month_of_year,
  						 month_name,
  						 month_abbr,
  						 month_duration,
  						 quarter_nbr,
  						 quarter_name,
  						 quarter_duration,
  						 year_duration,
  						 NVL(fiscal_day_of_week,day_of_week) 		       AS fiscal_day_of_week,
  						 NVL(fiscal_day_of_month,day_of_month) 		     AS fiscal_day_of_month,
  						 NVL(fiscal_day_of_year,day_of_year) 		       AS fiscal_day_of_year,
  						 NVL(fiscal_week_id,week_id) 				           AS fiscal_week_id,
  						 NVL(fiscal_week_of_year,week_of_year) 		     AS fiscal_week_of_year,
  						 NVL(fiscal_week_of_month,week_of_month)  	   AS fiscal_week_of_month,
  						 NVL(fiscal_month_id,month_id)  			         AS fiscal_month_id,
  						 NVL(fiscal_month_of_year,month_of_year)  	   AS fiscal_month_of_year,
  						 NVL(fiscal_month_name,month_name)			       AS fiscal_month_name,
  						 NVL(fiscal_month_abbr,month_abbr)  			     AS fiscal_month_abbr,
  						 NVL(fiscal_month_duration,month_duration)     AS fiscal_month_duration,
  						 NVL(fiscal_quarter_nbr,quarter_nbr)           AS fiscal_quarter_nbr ,
  						 NVL(fiscal_quarter_name,quarter_name) 	 	     AS fiscal_quarter_name,
  						 NVL(fiscal_quarter_id,quarter_id)  			     AS fiscal_quarter_id,
  						 NVL(fiscal_quarter_duration,quarter_duration) AS fiscal_quarter_duration,
  						 NVL(fiscal_year_id,year_id) 				           AS fiscal_year_id,
  						 NVL(fiscal_year_duration,year_duration) 		   AS fiscal_year_duration
				  FROM lego_all_orgs_calendar     cal, 
               lego_calendar_fiscal_dates cfd 
				 WHERE cfd.calendar_id = cal.calendar_id
/




