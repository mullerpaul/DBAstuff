--
-- Package to handle Jasper currency conversion activities
--
-- author: jmiller
--
CREATE OR REPLACE PACKAGE jasper_currency_conversion_pkg AS

PROCEDURE set_currency_conversion(pi_currency IN NUMBER, pi_from_conversion_date IN DATE, pi_to_conversion_date IN DATE);

END jasper_currency_conversion_pkg;
/
