--
-- Package to handle Jasper currency conversion activities
--
-- author: jmiller
--
CREATE OR REPLACE PACKAGE BODY jasper_currency_conversion_pkg AS

--
-- Manages the jasper_currency_conv_gtt global temporary table
--
PROCEDURE set_currency_conversion(pi_currency IN NUMBER, pi_from_conversion_date IN DATE, pi_to_conversion_date IN DATE) IS
BEGIN
    DELETE FROM jasper_currency_conv_gtt;

    INSERT INTO jasper_currency_conv_gtt (
      to_currency_fk,
      to_currency_code,
      from_conversion_date,
      to_conversion_date
    )
    SELECT pi_currency,
           (SELECT description FROM currency_unit WHERE value = pi_currency),
           pi_from_conversion_date,
           pi_to_conversion_date
      FROM DUAL;

END set_currency_conversion;

END jasper_currency_conversion_pkg;
/




