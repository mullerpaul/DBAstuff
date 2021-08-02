CREATE OR REPLACE FORCE VIEW bo_curr_conv_gl_daily_rates_vw
AS
(SELECT from_currency_fk, 
        to_currency_fk, 
        AVG(conversion_rate) AS conversion_rate
   FROM bo_curr_conv_gl_daily_rates a
  WHERE conversion_date BETWEEN (SELECT from_conversion_date FROM jasper_currency_conv_gtt) 
                            AND (SELECT to_conversion_date   FROM jasper_currency_conv_gtt)
  GROUP BY from_currency_fk, to_currency_fk)
/

