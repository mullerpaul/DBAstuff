/*******************************************************************************
SCRIPT NAME         lego_bus_org_views.sql 
 
LEGO OBJECT NAME    LEGO_BUS_ORG
 
CREATED             2/12/2014
 
ORIGINAL AUTHOR     Derek Reiner

***************************MODIFICATION HISTORY ********************************
 
07/02/2014 - J.Pullifrone - IQN-18303 - added bus_rule_org_id column - Release 12.1.2 
   
*******************************************************************************/  
CREATE OR REPLACE FORCE VIEW lego_buyer_org_vw
AS
   SELECT bus_org_id                  AS buyer_org_id,
          bus_org_name                AS buyer_name,
          parent_bus_org_id           AS buyer_parent_bus_org_id,
          bus_rule_org_id             AS buyer_rule_org_id,
          enterprise_id               AS buyer_enterprise_id,
          enterprise_bus_org_id       AS buyer_enterprise_bus_org_id,
          enterprise_name             AS buyer_enterprise_name,
          managing_organization_name  AS buyer_managing_org_name,
          shard_name                  AS buyer_shard_name,
          firm_id                     AS buyer_firm_id,
          marketplace_id              AS buyer_marketplace_id,
          bus_org_type                AS buyer_bus_org_type,
          buyer_udf_collection_id,
          contact_info_id             AS buyer_contact_info_id,
          primary_phone_number        AS buyer_primary_phone_number,
          fax_number                  AS buyer_fax_number,
          onsite_email_address        AS buyer_onsite_email_address,
          business_url                AS buyer_business_url,
          primary_address_guid        AS buyer_primary_address_guid,
          hq_address_guid             AS buyer_hq_address_guid,
          payment_address_guid        AS buyer_payment_address_guid,
          notice_address_guid         AS buyer_notice_address_guid,
          inheritance_mode          
     FROM lego_bus_org
    WHERE bus_org_type = 'Buyer'
/

CREATE OR REPLACE FORCE VIEW lego_supplier_org_vw
AS
   SELECT bus_org_id                  AS supplier_org_id,
          bus_org_name                AS supplier_name,
          parent_bus_org_id           AS supplier_parent_bus_org_id,
          bus_rule_org_id             AS supplier_rule_org_id,
          enterprise_id               AS supplier_enterprise_id,
          enterprise_bus_org_id       AS supplier_enterprise_bus_org_id,
          enterprise_name             AS supplier_enterprise_name,
          managing_organization_name  AS supplier_managing_org_name,
          shard_name                  AS supplier_shard_name,
          firm_id                     AS supplier_firm_id,
          marketplace_id              AS supplier_marketplace_id,
          bus_org_type                AS supplier_bus_org_type,
          supplier_udf_collection_id,
          contact_info_id             AS supplier_contact_info_id,
          primary_phone_number        AS supplier_primary_phone_number,
          fax_number                  AS supplier_fax_number,
          onsite_email_address        AS supplier_onsite_email_address,
          business_url                AS supplier_business_url,
          primary_address_guid        AS supplier_primary_address_guid,
          hq_address_guid             AS supplier_hq_address_guid,
          payment_address_guid        AS supplier_payment_address_guid,
          notice_address_guid         AS supplier_notice_address_guid,
          inheritance_mode
     FROM lego_bus_org
    WHERE bus_org_type = 'Supplier'
/


CREATE OR REPLACE FORCE VIEW LEGO_BUS_ORG_PRIMARY_ADDR_VW
AS
   SELECT bus_org_id,
          bus_org_name,
          parent_bus_org_id,
          enterprise_id,
          enterprise_bus_org_id,
          enterprise_name,
          managing_organization_name,
          shard_name,
          bus_org_type,
          line1 PRIMARY_ADDRESS_LINE1,
          line2 PRIMARY_ADDRESS_LINE2,
          line3 PRIMARY_ADDRESS_LINE3,
          line4 PRIMARY_ADDRESS_LINE4,
          city PRIMARY_ADDRESS_CITY,
          state PRIMARY_ADDRESS_STATE,
          postal_code PRIMARY_ADDRESS_POSTAL_CODE,
          country PRIMARY_ADDRESS_COUNTRY
     FROM lego_bus_org lbo,
          lego_address a
    WHERE lbo.primary_address_guid = A.ADDRESS_GUID
/


CREATE OR REPLACE FORCE VIEW LEGO_BUS_ORG_HQ_ADDR_VW
AS
   SELECT bus_org_id,
          bus_org_name,
          parent_bus_org_id,
          enterprise_id,
          enterprise_bus_org_id,
          enterprise_name,
          managing_organization_name,
          shard_name,
          bus_org_type,
          line1 HQ_ADDRESS_LINE1,
          line2 HQ_ADDRESS_LINE2,
          line3 HQ_ADDRESS_LINE3,
          line4 HQ_ADDRESS_LINE4,
          city HQ_ADDRESS_CITY,
          state HQ_ADDRESS_STATE,
          postal_code HQ_ADDRESS_POSTAL_CODE,
          country HQ_ADDRESS_COUNTRY
     FROM lego_bus_org lbo,
          lego_address a
    WHERE lbo.HQ_address_guid = A.ADDRESS_GUID
/

CREATE OR REPLACE FORCE VIEW LEGO_BUS_ORG_PAYMENT_ADDR_VW
AS
   SELECT bus_org_id,
          bus_org_name,
          parent_bus_org_id,
          enterprise_id,
          enterprise_bus_org_id,
          enterprise_name,
          managing_organization_name,
          shard_name,
          bus_org_type,
          line1 PAYMENT_ADDRESS_LINE1,
          line2 PAYMENT_ADDRESS_LINE2,
          line3 PAYMENT_ADDRESS_LINE3,
          line4 PAYMENT_ADDRESS_LINE4,
          city PAYMENT_ADDRESS_CITY,
          state PAYMENT_ADDRESS_STATE,
          postal_code PAYMENT_ADDRESS_POSTAL_CODE,
          country PAYMENT_ADDRESS_COUNTRY
     FROM lego_bus_org lbo,
          lego_address a
    WHERE lbo.PAYMENT_address_guid = A.ADDRESS_GUID
/

CREATE OR REPLACE FORCE VIEW LEGO_BUS_ORG_NOTICE_ADDR_VW
AS
   SELECT bus_org_id,
          bus_org_name,
          parent_bus_org_id,
          enterprise_id,
          enterprise_bus_org_id,
          enterprise_name,
          managing_organization_name,
          shard_name,
          bus_org_type,
          line1 NOTICE_ADDRESS_LINE1,
          line2 NOTICE_ADDRESS_LINE2,
          line3 NOTICE_ADDRESS_LINE3,
          line4 NOTICE_ADDRESS_LINE4,
          city NOTICE_ADDRESS_CITY,
          state NOTICE_ADDRESS_STATE,
          postal_code NOTICE_ADDRESS_POSTAL_CODE,
          country NOTICE_ADDRESS_COUNTRY
     FROM lego_bus_org lbo,
          lego_address a
    WHERE lbo.NOTICE_address_guid = A.ADDRESS_GUID
/
