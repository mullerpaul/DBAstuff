CREATE OR REPLACE FORCE VIEW LEGO_ADDRESS_VW
(
   ADDRESS_GUID,
   STANDARD_PLACE_DESC,
   LINE1,
   LINE2,
   LINE3,
   LINE4,
   CITY,
   COUNTY,
   STATE,
   COUNTRY_ID,
   COUNTRY,
   COUNTRY_CODE,
   POSTAL_CODE,
   PLACE_ID, 
   ATTRIBUTE1,
   ATTRIBUTE2, 
   ATTRIBUTE3, 
   ATTRIBUTE4, 
   ATTRIBUTE5
)
AS
SELECT a.address_guid, 
       a.standard_place_desc, 
       a.line1, 
       a.line2, 
       a.line3,
       a.line4, 
       a.city, 
       a.county, 
       a.state, 
       a.country_id, 
       NVL(c_jcl.constant_description, a.country) country, 
       a.country_code, 
       a.postal_code, 
       a.place_id, 
       p.attribute1,
       p.attribute2, 
       p.attribute3, 
       p.attribute4, 
       p.attribute5
  FROM lego_address a, 
       lego_place_vw p,
       (SELECT constant_value, constant_description
          FROM lego_java_constant_lookup
         WHERE constant_type    = 'COUNTRY'
           AND locale_fk = (SELECT UPPER(IQN_SESSION_CONTEXT_PKG.get_current_locale_string) FROM dual)) c_jcl
 WHERE a.place_id   = p.place_id(+)
   AND a.country_id = c_jcl.constant_value(+)
/


COMMENT ON TABLE lego_address_vw IS
   'This view allows access to the lego_address_table which contains the unique addresses in the system.  Contains line1 through line4, city, state, etc.'
/


COMMENT ON COLUMN lego_address_vw.ADDRESS_GUID IS
   'Value from the LEGO_ADDRESS Table corresponding to a unique address in the system.'
/

COMMENT ON COLUMN lego_address_vw.STANDARD_PLACE_DESC IS
   'Value from the PLACE table.  Corresponds to a list of standard places provided to the user in the application.'
/

COMMENT ON COLUMN lego_address_vw.LINE1 IS
   'Value from the ADDRESS.LINE1 and if NULL, the value from PLACE table''s Custom Place LINE1.'
/

COMMENT ON COLUMN lego_address_vw.LINE2 IS
   'Value from the ADDRESS.LINE2 and if NULL, the value from PLACE table''s Custom Place LINE2.'
/

COMMENT ON COLUMN lego_address_vw.LINE3 IS
   'Value from the ADDRESS.LINE3 and if NULL, the value from PLACE table''s Custom Place LINE3.'
/

COMMENT ON COLUMN lego_address_vw.LINE4 IS
   'Value from the ADDRESS.LINE4 and if NULL, the value from PLACE table''s Custom Place LINE4.'
/

COMMENT ON COLUMN lego_address_vw.CITY IS
   'Value from the ADDRESS.CITY and if NULL, the value from PLACE table Custom Place CITY and if NULL the value from PLACE table Standard Place CITY.'
/

COMMENT ON COLUMN lego_address_vw.COUNTY IS
   'Value from PLACE table Custom Place COUNTY.'
/

COMMENT ON COLUMN lego_address_vw.STATE IS
   'Value from the ADDRESS.PROVIDENCE and if NULL, the value from PLACE table Custom Place STATE and if NULL the value from PLACE table Standard Place STATE.'
/

COMMENT ON COLUMN lego_address_vw.COUNTRY_ID IS
   'Value from the ADDRESS.COUNTRY when ADDRESS attributes NOT NULL,  else the value from PLACE table Custom Place COUNTRY_ID and if NULL the value from PLACE table Standard Place COUNTRY_ID.'
/

COMMENT ON COLUMN lego_address_vw.COUNTRY IS
   'Value from the COUNTRY.DESCRIPTION when ADDRESS attributes NOT NULL,  else the value from PLACE table Custom Place COUNTRY and if NULL the value from PLACE table Standard Place COUNTRY.'
/

COMMENT ON COLUMN lego_address_vw.COUNTRY_CODE IS
   'Value from the COUNTRY.COUNTRY_CODE when ADDRESS attributes NOT NULL,  else the value from PLACE table Custom Place COUNTRY_CODE and if NULL the value from PLACE table Standard Place COUNTRY_CODE.'
/

COMMENT ON COLUMN lego_address_vw.POSTAL_CODE IS
   'Value from the ADDRESS.POSTAL_CODE and if NULL, the value from PLACE table''s Custom Place POSTAL_CODE.'
/

COMMENT ON COLUMN lego_address_vw.PLACE_ID IS
   'Value from ADDRESS.PLACE_FK.  Links to the PLACE table to retrieve Standard and Custom Place information.'
/

COMMENT ON COLUMN LEGO_ADDRESS_VW.ATTRIBUTE1 IS
   'Value from the Place Table that holds the first custom description.'
/

COMMENT ON COLUMN LEGO_ADDRESS_VW.ATTRIBUTE2 IS
   'Value from the Place Table that holds the second custom description.'
/

COMMENT ON COLUMN LEGO_ADDRESS_VW.ATTRIBUTE3 IS
   'Value from the Place Table that holds the third custom description.'
/

COMMENT ON COLUMN LEGO_ADDRESS_VW.ATTRIBUTE4 IS
   'Value from the Place Table that holds the fourth custom description.'
/

COMMENT ON COLUMN LEGO_ADDRESS_VW.ATTRIBUTE5 IS
   'Value from the Place Table that holds the fifth custom description.'
/



