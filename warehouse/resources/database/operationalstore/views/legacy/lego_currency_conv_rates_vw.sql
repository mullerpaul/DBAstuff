-- LEGO_CURRENCY_CONV_RATES_VW

-- This view shows conversion rates to the one selected currency from all currencies for 
-- which we have data during the chosen interval. 
-- The view will be empty if no currency conversion is selected, or if no data exists 
-- for the chosen currency in the chosen date range.

-- note there must be AT MOST one distinct value of converted_currency_id in the view results.
-- the equals sign in the first clause in the WHERE clause ensures this.

CREATE OR REPLACE FORCE VIEW lego_currency_conv_rates_vw
AS
SELECT original_currency_id,
       converted_currency_id,
       converted_currency_code,
       AVG(conversion_rate) AS conversion_rate
  FROM lego_currency_conv_rates
 WHERE converted_currency_id = (SELECT to_currency_fk       FROM jasper_currency_conv_gtt)
   AND conversion_date BETWEEN (SELECT from_conversion_date FROM jasper_currency_conv_gtt)
                           AND (SELECT to_conversion_date   FROM jasper_currency_conv_gtt)
 GROUP BY original_currency_id, 
          converted_currency_id, 
          converted_currency_code
/

