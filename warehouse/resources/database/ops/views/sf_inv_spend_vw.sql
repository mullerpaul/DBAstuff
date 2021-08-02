
  CREATE OR REPLACE FORCE VIEW "OPS"."SF_INV_SPEND_VW" ("BUYER_ENTERPRISE", "BUYER_NAME", "YR", "MO", "INVOICE_DATE", "DATADTS", "LOAD_DATE", "SUPPLIER_ENTERPRISE", "SUPPLIER_NAME", "SOURCE_NAME", "BUYER_MANAGING_ORG", "SUPPLIER_MANAGING_ORG", "ASSIGNMENT_CONTINUITY_ID", "BUYER_ORG_ID", "SUPPLIER_ORG_ID", "PRODUCT", "INDUSTRY_NAME", "BUYER_MANAGE_NAME", "SUPPLIER_MANAGE_NAME", "CURRENCY", "SOW_SPEND_CATEGORY", "SOW_SPEND_TYPE", "SPEND_CATEGORY", "SPEND_TYPE", "SPEND_USD", "SPEND_ORIG", "TRANSACTION_TYPE", "JOB_CATEGORY", "DS", "JOB_ID_LOC", "BUYER_ORG_ID_JOB_LOC", "PLACE_ID", "JOBLOCCT", "COUNTRY", "COUNTRY_CODE", "COUNTRY_ID", "STATE", "CITY", "POSTAL_CODE", "ADDRCT") AS 
  select bw.enterprise_name buyer_enterprise, bw.bus_org_name buyer_name, 
         EXTRACT(YEAR FROM i.INVOICE_DATE) YR, EXTRACT(MONTH FROM i.INVOICE_DATE) MO,
         i.INVOICE_DATE, sysdate DATADTS, i.load_date,
         sw.enterprise_name supplier_enterprise, sw.bus_org_name supplier_name, i.source_Name, 
         bw.Managing_organization_name buyer_managing_org, sw.Managing_organization_name supplier_managing_org, 
         i.work_order_id assignment_continuity_id, bw.bus_org_id buyer_org_id, sw.bus_org_id supplier_org_id, 
         CASE WHEN i.PROJECT_AGREEMENT_ID is not NULL THEN 'SOW' ELSE 'Contingent' END Product, 
         dmb.Industry_name, bw.managing_organization_name Buyer_Manage_name, sw.managing_organization_name supplier_manage_name, 
         i.CURRENCY, SOW_SPEND_CATEGORY, SOW_SPEND_Type,SPEND_CATEGORY, SPEND_Type,
         SUM(BUYER_ADJUSTED_AMOUNT *(NVL(ccr.CONVERSION_RATE, 1))) SPEND_USD, SUM(BUYER_ADJUSTED_AMOUNT) SPEND_ORIG,
         i.transaction_type, i.job_category ,
         jwl2.DS,jwl2.job_id job_id_loc, jwl2.buyer_org_id_job_loc, jwl2.place_id, jwl2.jobLocCt,
                 jwl2.COUNTRY, jwl2.country_code, jwl2.country_id, jwl2.STATE, jwl2.CITY, jwl2.postal_code, jwl2.AddrCt
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
  GROUP BY  bw.enterprise_name , bw.bus_org_name , EXTRACT(YEAR FROM i.INVOICE_DATE) , EXTRACT(MONTH FROM i.INVOICE_DATE) ,
         i.INVOICE_DATE, sysdate , i.load_date,
         sw.enterprise_name , sw.bus_org_name , i.source_Name, 
         bw.Managing_organization_name , sw.Managing_organization_name , 
         i.work_order_id , bw.bus_org_id , sw.bus_org_id , 
         CASE WHEN i.PROJECT_AGREEMENT_ID is not NULL THEN 'SOW' ELSE 'Contingent' END , 
         dmb.Industry_name, bw.managing_organization_name , sw.managing_organization_name , 
         i.CURRENCY, SOW_SPEND_CATEGORY, SOW_SPEND_Type, SPEND_CATEGORY, SPEND_Type,
         i.transaction_type, i.job_category ,
         jwl2.DS, jwl2.job_id, jwl2.buyer_org_id_job_loc , jwl2.place_id, jwl2.jobLocCt,
         jwl2.COUNTRY, jwl2.country_code, jwl2.country_id, jwl2.STATE, jwl2.CITY, jwl2.postal_code, jwl2.AddrCt
UNION
select bw.enterprise_name buyer_enterprise, bw.bus_org_name buyer_name, 
         EXTRACT(YEAR FROM i.INVOICE_DATE) YR, EXTRACT(MONTH FROM i.INVOICE_DATE) MO,
         i.INVOICE_DATE
        , NULL DATADTS, NULL load_date,
         sw.enterprise_name supplier_enterprise
         , NULL supplier_name
         , i.source_Name, 
         bw.Managing_organization_name buyer_managing_org
          , NULL supplier_managing_org,          
         NULL assignment_continuity_id, NULL buyer_org_id, NULL supplier_org_id, 
         CASE WHEN i.PROJECT_AGREEMENT_ID is not NULL THEN 'Services Procurement' ELSE 'Contingent Staffing' END Product, 
         dmb.Industry_name
         , NULL Buyer_Manage_name, NULL supplier_manage_name, 
         i.CURRENCY
         , NULL SOW_SPEND_CATEGORY, NULL SOW_SPEND_Type
         ,SPEND_CATEGORY
         , NULL SPEND_Type,
         SUM(BUYER_ADJUSTED_AMOUNT *(NVL(ccr.CONVERSION_RATE, 1))) SPEND_USD, SUM(BUYER_ADJUSTED_AMOUNT) SPEND_ORIG,
         NULL transaction_type
         , i.job_category ,
         NULL DS,NULL job_id_loc, NULL buyer_org_id_job_loc, NULL place_id, 0 jobLocCt,
                 jwl2.COUNTRY
                 , NULL country_code, NULL country_id, NULL STATE, NULL CITY, NULL postal_code, 0 AddrCt
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
      ) ) jwl2    --> Operational Store Data:
  WHERE i.INVOICE_CREATION_DATE >= TRUNC (ADD_MONTHS (TRUNC (SYSDATE,'yyyy'), -36),'Y')
    AND i.source_name = 'WFPROD' 
    AND i.buyer_org_id = bw.bus_org_id
    AND i.job_id = jwl2.job_id(+) 
    AND i.supplier_org_id = sw.bus_org_id (+)
    AND bw.enterprise_bus_org_id = dmb.std_buyerorg_id (+) 
    AND (i.CURRENCY = ccr.FROM_CURRENCY_CODE (+) and TRUNC(i.INVOICE_DATE) = ccr.CONVERSION_DATE (+))
  GROUP BY  bw.enterprise_name 
  , bw.bus_org_name 
  , EXTRACT(YEAR FROM i.INVOICE_DATE) , EXTRACT(MONTH FROM i.INVOICE_DATE) ,
         i.INVOICE_DATE
         , i.load_date,
         sw.enterprise_name 
         , i.source_Name, 
         bw.Managing_organization_name  
         ,CASE WHEN i.PROJECT_AGREEMENT_ID is not NULL THEN 'Services Procurement' ELSE 'Contingent Staffing' END , i.PROJECT_AGREEMENT_ID
         ,dmb.Industry_name, bw.managing_organization_name , sw.managing_organization_name , 
         i.CURRENCY
         , SPEND_CATEGORY
         , i.job_category ,
         jwl2.COUNTRY
         ,i.PROJECT_AGREEMENT_ID
/
