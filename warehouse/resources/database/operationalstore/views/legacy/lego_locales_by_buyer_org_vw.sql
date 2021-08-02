CREATE OR REPLACE FORCE VIEW lego_locales_by_buyer_org_vw
AS
SELECT buyer_org_id,
       buyer_enterprise_bus_org_id,
       locale_preference
  FROM lego_locales_by_buyer_org
/

