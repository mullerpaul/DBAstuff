CREATE OR REPLACE FORCE VIEW address_vw
AS     
SELECT 'USPROD' AS source_name,
       addy.address_guid,
       addy.city,
       addy.country,
       addy.country_code,
       addy.line1,
       addy.line2,
       addy.line3,
       addy.line4,
       addy.postal_code,
       addy.standard_place_desc,
       addy.state
  FROM lego_address_iqp addy
UNION ALL    
SELECT 'WFPROD' AS source_name,
       addy.address_guid,
       addy.city,
       addy.country,
       addy.country_code,
       addy.line1,
       addy.line2,
       addy.line3,
       addy.line4,
       addy.postal_code,
       addy.standard_place_desc,
       addy.state
  FROM lego_address_wf addy
/