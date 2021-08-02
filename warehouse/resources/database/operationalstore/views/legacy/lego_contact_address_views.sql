/* Formatted on 11/14/2012 2:12:12 PM (QP5 v5.163.1008.3004) */

CREATE OR REPLACE FORCE VIEW lego_contact_address_vw
AS
   SELECT CA.BUYER_ORG_ID,
          CA.CONTACT_INFO_ID,
          CA.ADDRESS_TYPE,
          A.ADDRESS_GUID,
          A.STANDARD_PLACE_DESC,
          A.LINE1,
          A.LINE2,
          A.LINE3,
          A.LINE4,
          A.CITY,
          A.COUNTY,
          A.STATE,
          A.COUNTRY_ID,
          A.COUNTRY,
          A.COUNTRY_CODE,
          A.POSTAL_CODE,
          PLACE_ID
     FROM lego_contact_address ca, lego_address a
    WHERE CA.ADDRESS_GUID = A.ADDRESS_GUID
/



COMMENT ON TABLE lego_contact_address_vw IS
   'This view allows the user to retrieve an address_guid via the buyer_org, contact_info_id and address_type.'
/

COMMENT ON COLUMN lego_contact_address_vw.BUYER_ORG_ID IS
   'The Buyer Organization for the address.  Unknown Buyer Orgs will be -1.'
/
   
COMMENT ON COLUMN lego_contact_address_vw.CONTACT_INFO_ID IS
   'Value from ADDRESS table in front office.  Allows the application to retrieve address information with only contact info.'
/

COMMENT ON COLUMN lego_contact_address_vw.ADDRESS_TYPE IS
   'Value from ADDRESS table in front office for Physical Addresses.  Values include Work, Payment, Primary, Headquarter, Notice, and Home.'
/

COMMENT ON COLUMN lego_contact_address_vw.ADDRESS_GUID IS
   'Value from the LEGO_ADDRESS corresponding to a unique address in the system.'
/

COMMENT ON COLUMN lego_contact_address_vw.STANDARD_PLACE_DESC IS
   'Value from the PLACE table.  Corresponds to a list of standard places provided to the user in the application.'
/

COMMENT ON COLUMN lego_contact_address_vw.LINE1 IS
   'Value from the ADDRESS.LINE1 and if NULL, the value from PLACE table''s Custom Place LINE1.'
/

COMMENT ON COLUMN lego_contact_address_vw.LINE2 IS
   'Value from the ADDRESS.LINE2 and if NULL, the value from PLACE table''s Custom Place LINE2.'
/

COMMENT ON COLUMN lego_contact_address_vw.LINE3 IS
   'Value from the ADDRESS.LINE3 and if NULL, the value from PLACE table''s Custom Place LINE3.'
/

COMMENT ON COLUMN lego_contact_address_vw.LINE4 IS
   'Value from the ADDRESS.LINE4 and if NULL, the value from PLACE table''s Custom Place LINE4.'
/

COMMENT ON COLUMN lego_contact_address_vw.CITY IS
   'Value from the ADDRESS.CITY and if NULL, the value from PLACE table Custom Place CITY and if NULL the value from PLACE table Standard Place CITY.'
/

COMMENT ON COLUMN lego_contact_address_vw.COUNTY IS
   'Value from PLACE table Custom Place COUNTY.'
/

COMMENT ON COLUMN lego_contact_address_vw.STATE IS
   'Value from the ADDRESS.PROVIDENCE and if NULL, the value from PLACE table Custom Place STATE and if NULL the value from PLACE table Standard Place STATE.'
/

COMMENT ON COLUMN lego_contact_address_vw.COUNTRY_ID IS
   'Value from the ADDRESS.COUNTRY when ADDRESS attributes NOT NULL,  else the value from PLACE table Custom Place COUNTRY_ID and if NULL the value from PLACE table Standard Place COUNTRY_ID.'
/

COMMENT ON COLUMN lego_contact_address_vw.COUNTRY IS
   'Value from the COUNTRY.DESCRIPTION when ADDRESS attributes NOT NULL,  else the value from PLACE table Custom Place COUNTRY and if NULL the value from PLACE table Standard Place COUNTRY.'
/

COMMENT ON COLUMN lego_contact_address_vw.COUNTRY_CODE IS
   'Value from the COUNTRY.COUNTRY_CODE when ADDRESS attributes NOT NULL,  else the value from PLACE table Custom Place COUNTRY_CODE and if NULL the value from PLACE table Standard Place COUNTRY_CODE.'
/

COMMENT ON COLUMN lego_contact_address_vw.POSTAL_CODE IS
   'Value from the ADDRESS.POSTAL_CODE and if NULL, the value from PLACE table''s Custom Place POSTAL_CODE.'
/

COMMENT ON COLUMN lego_contact_address_vw.PLACE_ID IS
   'Value from ADDRESS.PLACE_FK.  Links to the PLACE table to retrieve Standard and Custom Place information.'
/

