CREATE OR REPLACE PACKAGE dm_currency_conversion_data
/****************************************************
 * Package to populate currency conversion
 ***************************************************/
AS
  PROCEDURE populate_rates;
  
END dm_currency_conversion_data;
/