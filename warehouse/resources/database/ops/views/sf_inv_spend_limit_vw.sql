/*
Modification History:
nconcepcion         06/04/2019              REP-3052 / IQN-43847 Create a smaller version of SF_INV_SPEND_VW2
*/

  CREATE OR REPLACE FORCE VIEW "OPS"."SF_INV_SPEND_LIMIT_VW" ("BUYER_ENTERPRISE", "YR", "MO", "INVOICE_DATE", "INVOICE_CREATION_DATE", "LOAD_DATE", "SUPPLIER_ENTERPRISE", "SUPPLIER_NAME", "SOURCE_NAME", "PRODUCT", "INDUSTRY_NAME", "BUYER_MANAGE_NAME", "CURRENCY", "SPEND_CATEGORY", "SPEND_USD", "SPEND_ORIG", "JOB_CATEGORY", "COUNTRY") AS 
  select bw.enterprise_name buyer_enterprise,
         EXTRACT(YEAR FROM i.INVOICE_DATE) YR, EXTRACT(MONTH FROM i.INVOICE_DATE) MO
         ,i.INVOICE_DATE, i.INVOICE_CREATION_DATE, i.load_date,
         sw.enterprise_name supplier_enterprise, sw.bus_org_name supplier_name, i.source_Name
         , CASE WHEN i.PROJECT_AGREEMENT_ID is not NULL THEN 'SOW' ELSE 'Contingent' END Product, 
         dmb.Industry_name, bw.managing_organization_name Buyer_Manage_name
         ,i.CURRENCY,SPEND_CATEGORY, 
         SUM(BUYER_ADJUSTED_AMOUNT *(NVL(ccr.CONVERSION_RATE, 1))) SPEND_USD, SUM(BUYER_ADJUSTED_AMOUNT) SPEND_ORIG,
         i.job_category ,
                 jwl2.COUNTRY
    from  OPERATIONALSTORE.LEGO_INVD_EXPD_DATE_RU i, 
        (SELECT * FROM OPERATIONALSTORE.BUS_ORG_IQP) bw,
        (SELECT * FROM OPERATIONALSTORE.BUS_ORG_IQP ) sw, 
        (SELECT * FROM IQPRODM.DM_CURRENCY_CONVERSION_RATES   where to_currency_Code = 'USD')  ccr, 
        IQPRODM.DM_BUYERS   dmb,
        ( SELECT DS,job_id, buyer_org_id buyer_org_id_job_loc, place_id, jobLocCt,
                 COUNTRY, country_code, country_id, STATE, CITY, postal_code, AddrCt
            FROM ((SELECT 'USPROD' DS, job_id, buyer_org_id, MAX(place_id) place_id , Count(*) JobLocCt
                     FROM OPERATIONALSTORE.JOB_WORK_LOCATION_IQP
                 GROUP BY job_id, buyer_org_id) jwl 
 LEFT OUTER JOIN (SELECT 'USPROD' DSloc, PLACE_ID place_id2,
                         MAX(ladd.COUNTRY) COUNTRY,
                         MAX(ladd.country_code) country_code, 
                         MAX(ladd.country_id) country_id,
                         MAX(ladd.STATE) STATE, 
                         MAX(ladd.CITY) CITY, 
                         MAX(ladd.postal_code) postal_code,
                         COUNT(*) AddrCt
                    FROM OPERATIONALSTORE.LEGO_ADDRESS_IQP ladd 
                   WHERE PLACE_ID is not null
                GROUP BY PLACE_ID) la
              ON jwl.place_id = la.place_id2 
      ) ) jwl2   
  WHERE i.INVOICE_DATE >=  TO_DATE('2015/01/01', 'YYYY/MM/DD') -- pick date 
    AND i.source_name = 'USPROD' 
    AND i.buyer_org_id = bw.bus_org_id
    AND i.job_id = jwl2.job_id(+)
    AND i.supplier_org_id = sw.bus_org_id (+)
    AND bw.enterprise_bus_org_id = dmb.std_buyerorg_id (+) 
    AND (i.CURRENCY = ccr.FROM_CURRENCY_CODE (+) and TRUNC(i.INVOICE_DATE) = ccr.CONVERSION_DATE (+))
  GROUP BY  bw.enterprise_name,
         EXTRACT(YEAR FROM i.INVOICE_DATE) , EXTRACT(MONTH FROM i.INVOICE_DATE) 
        ,i.INVOICE_DATE, i.INVOICE_CREATION_DATE, i.load_date,
         sw.enterprise_name , sw.bus_org_name , i.source_Name
         , CASE WHEN i.PROJECT_AGREEMENT_ID is not NULL THEN 'SOW' ELSE 'Contingent' END , 
         dmb.Industry_name, bw.managing_organization_name 
         ,i.CURRENCY,SPEND_CATEGORY, 
         i.job_category ,
                 jwl2.COUNTRY
UNION
select bw.enterprise_name buyer_enterprise,
         EXTRACT(YEAR FROM i.INVOICE_DATE) YR, EXTRACT(MONTH FROM i.INVOICE_DATE) MO,
         i.INVOICE_DATE, i.INVOICE_CREATION_DATE, NULL load_date,
         sw.enterprise_name supplier_enterprise
         , NULL supplier_name
         , i.source_Name,
         CASE WHEN i.PROJECT_AGREEMENT_ID IS NOT NULL THEN 'Services Procurement' ELSE 'Contingent Staffing' END Product, 
         dmb.Industry_name
         , NULL Buyer_Manage_name, 
         i.CURRENCY
         ,SPEND_CATEGORY
         ,SUM(BUYER_ADJUSTED_AMOUNT *(NVL(ccr.CONVERSION_RATE, 1))) SPEND_USD, SUM(BUYER_ADJUSTED_AMOUNT) SPEND_ORIG,
         i.job_category,
                 jwl2.COUNTRY
    from  OPERATIONALSTORE.LEGO_INVD_EXPD_DATE_RU i, 
        (SELECT * FROM OPERATIONALSTORE.BUS_ORG_WF) bw,
        (SELECT * FROM OPERATIONALSTORE.BUS_ORG_WF ) sw, 
        (SELECT * FROM IQPRODM.DM_CURRENCY_CONVERSION_RATES   where to_currency_Code = 'USD')  ccr, 
        IQPRODM.DM_BUYERS   dmb, 
        ( SELECT DS,job_id, buyer_org_id buyer_org_id_job_loc, place_id, jobLocCt,
                 COUNTRY, country_code, country_id, STATE, CITY, postal_code, AddrCt
            FROM ((SELECT 'WFPROD' DS, job_id, buyer_org_id, MAX(place_id) place_id , Count(*) JobLocCt
                     FROM OPERATIONALSTORE.JOB_WORK_LOCATION_WF
                 GROUP BY job_id, buyer_org_id) jwl 
 LEFT OUTER JOIN (SELECT 'WFPROD' DSloc, PLACE_ID place_id2,
                         MAX(ladd.COUNTRY) COUNTRY,
                         MAX(ladd.country_code) country_code, 
                         MAX(ladd.country_id) country_id,
                         MAX(ladd.STATE) STATE, 
                         MAX(ladd.CITY) CITY, 
                         MAX(ladd.postal_code) postal_code,
                         COUNT(*) AddrCt
                    FROM OPERATIONALSTORE.LEGO_ADDRESS_WF ladd 
                   WHERE PLACE_ID is not null
                GROUP BY PLACE_ID) la
              ON jwl.place_id = la.place_id2 
      ) ) jwl2    
  WHERE i.INVOICE_CREATION_DATE >= TRUNC (ADD_MONTHS (TRUNC (SYSDATE,'yyyy'), -36),'Y')
    AND i.source_name = 'WFPROD' 
    AND i.buyer_org_id = bw.bus_org_id
    AND i.job_id = jwl2.job_id(+) 
    AND i.supplier_org_id = sw.bus_org_id (+)
    AND bw.enterprise_bus_org_id = dmb.std_buyerorg_id (+) 
    AND (i.CURRENCY = ccr.FROM_CURRENCY_CODE (+) and TRUNC(i.INVOICE_DATE) = ccr.CONVERSION_DATE (+))
  GROUP BY  bw.enterprise_name,
         EXTRACT(YEAR FROM i.INVOICE_DATE), EXTRACT(MONTH FROM i.INVOICE_DATE),
         i.INVOICE_DATE, i.INVOICE_CREATION_DATE,
         sw.enterprise_name
         , i.source_Name,
         CASE WHEN i.PROJECT_AGREEMENT_ID IS NOT NULL THEN 'Services Procurement' ELSE 'Contingent Staffing' END, 
         dmb.Industry_name,
         i.CURRENCY
         ,SPEND_CATEGORY
         , i.job_category,
                 jwl2.COUNTRY;
