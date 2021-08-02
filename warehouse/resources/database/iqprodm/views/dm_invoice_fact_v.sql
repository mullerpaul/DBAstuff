CREATE OR REPLACE FORCE VIEW DM_INVOICE_FACT_V
(
   BUYER_ORG_DIM_ID,
   BUYER_GEO_DIM_ID,
   SUPPLIER_ORG_DIM_ID,
   SUPPLIER_GEO_DIM_ID,
   WORK_LOC_GEO_DIM_ID,
   TXN_CURRENCY_DIM_ID,
   CONT_PERSON_DIM_ID,
   HM_PERSON_DIM_ID,
   EXPND_APPR_PERSON_DIM_ID,
   EXPENDITURE_DIM_ID,
   ENGAGEMENT_TYPE_DIM_ID,
   INV_CAC_DIM_ID,
   JOB_DIM_ID,
   PA_DIM_ID,
   RATECARD_DIM_ID,
   ASSIGN_START_DATE_DIM_ID,
   ASSIGN_END_DATE_DIM_ID,
   ASSIGN_ACT_END_DATE_DIM_ID,
   EXPND_DATE_DIM_ID,
   EXPND_APPR_DATE_DIM_ID,
   EXPND_APPR_TIME_DIM_ID,
   INVOICE_DATE_DIM_ID,
   INVOICE_CRT_TIME_DIM_ID,
   INVOICE_CRT_DATE_DIM_ID,
   INVOICE_WK_ENDING_DATE_DIM_ID,
   INVOICE_NUMBER,
   EXPENDITURE_NUMBER,
   ENGAGEMENT_ID,
   RATE_TYPE_NAME,
   BASE_BILL_RATE,
   BASE_PAY_RATE,
   BUYER_ADJ_BILL_RATE,
   SUPP_REIMB_RATE,
   REG_BASE_BILL_RATE,
   REG_BASE_PAY_RATE,
   REG_BUYER_ADJ_BILL_RATE,
   REG_SUPP_REIMB_RATE,
   OT_BASE_BILL_RATE,
   OT_BASE_PAY_RATE,
   OT_BUYER_ADJ_BILL_RATE,
   OT_SUPP_REIMB_RATE,
   DT_BASE_BILL_RATE,
   DT_BASE_PAY_RATE,
   DT_BUYER_ADJ_BILL_RATE,
   DT_SUPP_REIMB_RATE,
   BUYER_FEE,
   SUPPLIER_FEE,
   TOTAL_FEE,
   REG_HOURS,
   OT_HOURS,
   DT_HOURS,
   CS_HOURS,
   BUYER_ADJ_AMT,
   SUPP_REIMB_AMT,
   REG_HOURS_BUYER_ADJ_AMT,
   OT_HOURS_BUYER_ADJ_AMT,
   DT_HOURS_BUYER_ADJ_AMT,
   CS_HOURS_BUYER_ADJ_AMT,
   REG_HOURS_SUPP_REIMB_AMT,
   OT_HOURS_SUPP_REIMB_AMT,
   DT_HOURS_SUPP_REIMB_AMT,
   CS_HOURS_SUPP_REIMB_AMT,
   TAX_AMT,
   BATCH_ID,
   LAST_UPDATE_DATE,
   DATA_SOURCE_CODE,
   INV_OBJECT_SOURCE,
   BUYER_BUS_ORG_FK,
   SUPPLIER_BUS_ORG_FK,
   INVOICE_FACT_SEQUENCE,
   INVOICE_DATE_ID,
   EXPENDITURE_DATE_ID,
   BUYER_FEE_USD,
   BUYER_FEE_EUR,
   BUYER_FEE_GBP,
   SUPPLIER_FEE_USD,
   SUPPLIER_FEE_EUR,
   SUPPLIER_FEE_GBP,
   TOTAL_FEE_USD,
   TOTAL_FEE_EUR,
   TOTAL_FEE_GBP,
   BUYER_ADJ_AMT_USD,
   BUYER_ADJ_AMT_EUR,
   BUYER_ADJ_AMT_GBP,
   SUPP_REIMB_AMT_USD,
   SUPP_REIMB_AMT_EUR,
   SUPP_REIMB_AMT_GBP,
   TAX_AMT_USD,
   TAX_AMT_EUR,
   TAX_AMT_GBP,
   CONVERSION_RATE_USD,
   CONVERSION_RATE_EUR,
   CONVERSION_RATE_GBP,
   REG_HOURS_BUYER_ADJ_AMT_USD,
   REG_HOURS_BUYER_ADJ_AMT_EUR,
   REG_HOURS_BUYER_ADJ_AMT_GBP,
   OT_HOURS_BUYER_ADJ_AMT_USD,
   OT_HOURS_BUYER_ADJ_AMT_EUR,
   OT_HOURS_BUYER_ADJ_AMT_GBP,
   DT_HOURS_BUYER_ADJ_AMT_USD,
   DT_HOURS_BUYER_ADJ_AMT_EUR,
   DT_HOURS_BUYER_ADJ_AMT_GBP,
   CS_HOURS_BUYER_ADJ_AMT_USD,
   CS_HOURS_BUYER_ADJ_AMT_EUR,
   CS_HOURS_BUYER_ADJ_AMT_GBP,
   REG_HOURS_SUPP_REIMB_AMT_USD,
   REG_HOURS_SUPP_REIMB_AMT_EUR,
   REG_HOURS_SUPP_REIMB_AMT_GBP,
   OT_HOURS_SUPP_REIMB_AMT_USD,
   OT_HOURS_SUPP_REIMB_AMT_EUR,
   OT_HOURS_SUPP_REIMB_AMT_GBP,
   DT_HOURS_SUPP_REIMB_AMT_USD,
   DT_HOURS_SUPP_REIMB_AMT_EUR,
   DT_HOURS_SUPP_REIMB_AMT_GBP,
   CS_HOURS_SUPP_REIMB_AMT_USD,
   CS_HOURS_SUPP_REIMB_AMT_EUR,
   CS_HOURS_SUPP_REIMB_AMT_GBP,
   CURR_CONV_USD_DIM_ID,
   CURR_CONV_EUR_DIM_ID,
   CURR_CONV_GBP_DIM_ID,
   ASSIGNMENT_DIM_ID,
   ENGAGEMENT_CLASSIFICATION,
   DISCOUNT_AMT_LOCAL,
   DISCOUNT_AMT_USD,
   DISCOUNT_AMT_EUR,
   DISCOUNT_AMT_GBP,
   REBATE_AMT_LOCAL,
   REBATE_AMT_USD,
   REBATE_AMT_EUR,
   REBATE_AMT_GBP,
   BUYER_FEE_CAD,
   SUPPLIER_FEE_CAD,
   TOTAL_FEE_CAD,
   BUYER_ADJ_AMT_CAD,
   SUPP_REIMB_AMT_CAD,
   TAX_AMT_CAD,
   CONVERSION_RATE_CAD,
   REG_HOURS_BUYER_ADJ_AMT_CAD,
   OT_HOURS_BUYER_ADJ_AMT_CAD,
   DT_HOURS_BUYER_ADJ_AMT_CAD,
   CS_HOURS_BUYER_ADJ_AMT_CAD,
   REG_HOURS_SUPP_REIMB_AMT_CAD,
   OT_HOURS_SUPP_REIMB_AMT_CAD,
   DT_HOURS_SUPP_REIMB_AMT_CAD,
   CS_HOURS_SUPP_REIMB_AMT_CAD,
   CURR_CONV_CAD_DIM_ID,
   DISCOUNT_AMT_CAD,
   REBATE_AMT_CAD 
)
AS
   SELECT BUYER_ORG_DIM_ID,
          BUYER_GEO_DIM_ID,
          SUPPLIER_ORG_DIM_ID,
          SUPPLIER_GEO_DIM_ID,
          WORK_LOC_GEO_DIM_ID,
          TXN_CURRENCY_DIM_ID,
          CONT_PERSON_DIM_ID,
          HM_PERSON_DIM_ID,
          EXPND_APPR_PERSON_DIM_ID,
          f.EXPENDITURE_DIM_ID,
          ENGAGEMENT_TYPE_DIM_ID,
          INV_CAC_DIM_ID,
          JOB_DIM_ID,
          PA_DIM_ID,
          RATECARD_DIM_ID,
          ASSIGN_START_DATE_DIM_ID,
          ASSIGN_END_DATE_DIM_ID,
          ASSIGN_ACT_END_DATE_DIM_ID,
          EXPND_DATE_DIM_ID,
          EXPND_APPR_DATE_DIM_ID,
          EXPND_APPR_TIME_DIM_ID,
          INVOICE_DATE_DIM_ID,
          INVOICE_CRT_TIME_DIM_ID,
          INVOICE_CRT_DATE_DIM_ID,
          INVOICE_WK_ENDING_DATE_DIM_ID,
          INVOICE_NUMBER,
          EXPENDITURE_NUMBER,
          ENGAGEMENT_ID,
          RATE_TYPE_NAME,
          BASE_BILL_RATE,
          BASE_PAY_RATE,
          BUYER_ADJ_BILL_RATE,
          SUPP_REIMB_RATE,
          REG_BASE_BILL_RATE,
          REG_BASE_PAY_RATE,
          REG_BUYER_ADJ_BILL_RATE,
          REG_SUPP_REIMB_RATE,
          OT_BASE_BILL_RATE,
          OT_BASE_PAY_RATE,
          OT_BUYER_ADJ_BILL_RATE,
          OT_SUPP_REIMB_RATE,
          DT_BASE_BILL_RATE,
          DT_BASE_PAY_RATE,
          DT_BUYER_ADJ_BILL_RATE,
          DT_SUPP_REIMB_RATE,
          BUYER_FEE,
          SUPPLIER_FEE,
          TOTAL_FEE,
          REG_HOURS,
          OT_HOURS,
          DT_HOURS,
          CS_HOURS,
          BUYER_ADJ_AMOUNT,
          SUPP_REIMB_AMOUNT,
          REG_HOURS_BUYER_ADJ_AMOUNT,
          OT_HOURS_BUYER_ADJ_AMOUNT,
          DT_HOURS_BUYER_ADJ_AMOUNT,
          CS_HOURS_BUYER_ADJ_AMOUNT,
          REG_HOURS_SUPP_REIMB_AMOUNT,
          OT_HOURS_SUPP_REIMB_AMOUNT,
          DT_HOURS_SUPP_REIMB_AMOUNT,
          CS_HOURS_SUPP_REIMB_AMOUNT,
          TAX_AMOUNT,
          BATCH_ID,
          f.LAST_UPDATE_DATE,
          f.DATA_SOURCE_CODE,
          f.INV_OBJECT_SOURCE,
          BUYER_BUS_ORG_FK,
          SUPPLIER_BUS_ORG_FK,
          INVOICE_FACT_SEQUENCE,
          INVOICE_DATE_ID,
          EXPENDITURE_DATE_ID,
          buyer_fee * NVL (c1.CONVERSION_RATE, 1) AS buyer_fee_usd,
          buyer_fee * NVL (c2.CONVERSION_RATE, 1) AS buyer_fee_eur,
          buyer_fee * NVL (c3.CONVERSION_RATE, 1) AS buyer_fee_gbp,
          supplier_fee * NVL (c1.CONVERSION_RATE, 1) AS supplier_fee_usd,
          supplier_fee * NVL (c2.CONVERSION_RATE, 1) AS supplier_fee_eur,
          supplier_fee * NVL (c3.CONVERSION_RATE, 1) AS supplier_fee_gbp,
          total_fee * NVL (c1.CONVERSION_RATE, 1) AS total_fee_usd,
          total_fee * NVL (c2.CONVERSION_RATE, 1) AS total_fee_eur,
          total_fee * NVL (c3.CONVERSION_RATE, 1) AS total_fee_gbp,
          buyer_adj_amount * NVL (c1.CONVERSION_RATE, 1) AS buyer_adj_amt_usd,
          buyer_adj_amount * NVL (c2.CONVERSION_RATE, 1) AS buyer_adj_amt_eur,
          buyer_adj_amount * NVL (c3.CONVERSION_RATE, 1) AS buyer_adj_amt_gbp,
          supp_reimb_amount * NVL (c1.CONVERSION_RATE, 1)
             AS supp_reimb_amt_usd,
          supp_reimb_amount * NVL (c2.CONVERSION_RATE, 1)
             AS supp_reimb_amt_eur,
          supp_reimb_amount * NVL (c3.CONVERSION_RATE, 1)
             AS supp_reimb_amt_gbp,
          tax_amount * NVL (c1.CONVERSION_RATE, 1) AS tax_amt_usd,
          tax_amount * NVL (c2.CONVERSION_RATE, 1) AS tax_amt_eur,
          tax_amount * NVL (c3.CONVERSION_RATE, 1) AS tax_amt_gbp,
          NVL (c1.CONVERSION_RATE, 1) AS conversion_rate_usd,
          NVL (c2.CONVERSION_RATE, 1) AS conversion_rate_eur,
          NVL (c3.CONVERSION_RATE, 1) AS conversion_rate_gbp,
          REG_HOURS_BUYER_ADJ_AMOUNT * NVL (c1.CONVERSION_RATE, 1)
             AS REG_HOURS_BUYER_ADJ_AMT_USD,
          REG_HOURS_BUYER_ADJ_AMOUNT * NVL (c2.CONVERSION_RATE, 1)
             AS REG_HOURS_BUYER_ADJ_AMT_EUR,
          REG_HOURS_BUYER_ADJ_AMOUNT * NVL (c3.CONVERSION_RATE, 1)
             AS REG_HOURS_BUYER_ADJ_AMT_GBP,
          OT_HOURS_BUYER_ADJ_AMOUNT * NVL (c1.CONVERSION_RATE, 1)
             AS OT_HOURS_BUYER_ADJ_AMT_USD,
          OT_HOURS_BUYER_ADJ_AMOUNT * NVL (c2.CONVERSION_RATE, 1)
             AS OT_HOURS_BUYER_ADJ_AMT_EUR,
          OT_HOURS_BUYER_ADJ_AMOUNT * NVL (c3.CONVERSION_RATE, 1)
             AS OT_HOURS_BUYER_ADJ_AMT_GBP,
          DT_HOURS_BUYER_ADJ_AMOUNT * NVL (c1.CONVERSION_RATE, 1)
             AS DT_HOURS_BUYER_ADJ_AMT_USD,
          DT_HOURS_BUYER_ADJ_AMOUNT * NVL (c2.CONVERSION_RATE, 1)
             AS DT_HOURS_BUYER_ADJ_AMT_EUR,
          DT_HOURS_BUYER_ADJ_AMOUNT * NVL (c3.CONVERSION_RATE, 1)
             AS DT_HOURS_BUYER_ADJ_AMT_GBP,
          CS_HOURS_BUYER_ADJ_AMOUNT * NVL (c1.CONVERSION_RATE, 1)
             AS CS_HOURS_BUYER_ADJ_AMT_USD,
          CS_HOURS_BUYER_ADJ_AMOUNT * NVL (c2.CONVERSION_RATE, 1)
             AS CS_HOURS_BUYER_ADJ_AMT_EUR,
          CS_HOURS_BUYER_ADJ_AMOUNT * NVL (c3.CONVERSION_RATE, 1)
             AS CS_HOURS_BUYER_ADJ_AMT_GBP,
          REG_HOURS_SUPP_REIMB_AMOUNT * NVL (c1.CONVERSION_RATE, 1)
             AS REG_HOURS_SUPP_REIMB_AMT_USD,
          REG_HOURS_SUPP_REIMB_AMOUNT * NVL (c2.CONVERSION_RATE, 1)
             AS REG_HOURS_SUPP_REIMB_AMT_EUR,
          REG_HOURS_SUPP_REIMB_AMOUNT * NVL (c3.CONVERSION_RATE, 1)
             AS REG_HOURS_SUPP_REIMB_AMT_GBP,
          OT_HOURS_SUPP_REIMB_AMOUNT * NVL (c1.CONVERSION_RATE, 1)
             AS OT_HOURS_SUPP_REIMB_AMT_USD,
          OT_HOURS_SUPP_REIMB_AMOUNT * NVL (c2.CONVERSION_RATE, 1)
             AS OT_HOURS_SUPP_REIMB_AMT_EUR,
          OT_HOURS_SUPP_REIMB_AMOUNT * NVL (c3.CONVERSION_RATE, 1)
             AS OT_HOURS_SUPP_REIMB_AMT_GBP,
          DT_HOURS_SUPP_REIMB_AMOUNT * NVL (c1.CONVERSION_RATE, 1)
             AS DT_HOURS_SUPP_REIMB_AMT_USD,
          DT_HOURS_SUPP_REIMB_AMOUNT * NVL (c2.CONVERSION_RATE, 1)
             AS DT_HOURS_SUPP_REIMB_AMT_EUR,
          DT_HOURS_SUPP_REIMB_AMOUNT * NVL (c3.CONVERSION_RATE, 1)
             AS DT_HOURS_SUPP_REIMB_AMT_GBP,
          CS_HOURS_SUPP_REIMB_AMOUNT * NVL (c1.CONVERSION_RATE, 1)
             AS CS_HOURS_SUPP_REIMB_AMT_USD,
          CS_HOURS_SUPP_REIMB_AMOUNT * NVL (c2.CONVERSION_RATE, 1)
             AS CS_HOURS_SUPP_REIMB_AMT_EUR,
          CS_HOURS_SUPP_REIMB_AMOUNT * NVL (c3.CONVERSION_RATE, 1)
             AS CS_HOURS_SUPP_REIMB_AMT_GBP,
          f.CURR_CONV_USD_DIM_ID CURR_CONV_USD_DIM_ID,
          f.CURR_CONV_EUR_DIM_ID CURR_CONV_EUR_DIM_ID,
          f.CURR_CONV_GBP_DIM_ID CURR_CONV_GBP_DIM_ID,
          f.assignment_dim_id assignment_dim_id,
          f.engagement_classification engagement_classification,
          CASE WHEN e.expenditure_category =   'Discount' THEN 
                    NVL(f.buyer_adj_amount,0)   
               ELSE 0
          END                                                      AS DISCOUNT_AMT_LOCAL,
	  CASE WHEN e.expenditure_category =   'Discount' THEN 
                    NVL(f.buyer_adj_amount,0)   * NVL (c1.CONVERSION_RATE, 1)
               ELSE 0
          END                                                      AS DISCOUNT_AMT_USD,
	  CASE WHEN e.expenditure_category =   'Discount' THEN 
                    NVL(f.buyer_adj_amount,0)   * NVL (c2.CONVERSION_RATE, 1)
               ELSE 0
          END                                                      AS DISCOUNT_AMT_EUR,
	  CASE WHEN e.expenditure_category =   'Discount' THEN 
                    NVL(f.buyer_adj_amount,0)   * NVL (c3.CONVERSION_RATE, 1)
               ELSE 0
          END                                                      AS DISCOUNT_AMT_GBP,
	  CASE WHEN e.expenditure_category =   'Rebate' THEN 
                    NVL(f.buyer_adj_amount,0)   
               ELSE 0
          END                                                      AS REBATE_AMT_LOCAL,
	  CASE WHEN e.expenditure_category =   'Rebate' THEN 
                    NVL(f.buyer_adj_amount,0)   * NVL (c1.CONVERSION_RATE, 1)
               ELSE 0
          END                                                      AS REBATE_AMT_USD,
	  CASE WHEN e.expenditure_category =   'Rebate' THEN 
                    NVL(f.buyer_adj_amount,0)   * NVL (c2.CONVERSION_RATE, 1)
               ELSE 0
          END                                                      AS REBATE_AMT_EUR,
	  CASE WHEN e.expenditure_category =   'Rebate' THEN 
                    NVL(f.buyer_adj_amount,0)   * NVL (c3.CONVERSION_RATE, 1)
               ELSE 0
          END                                                      AS REBATE_AMT_GBP  ,
		buyer_fee * NVL (c4.CONVERSION_RATE, 1) AS buyer_fee_cad,
		supplier_fee * NVL (c4.CONVERSION_RATE, 1) AS supplier_fee_cad,
		total_fee * NVL (c4.CONVERSION_RATE, 1) AS total_fee_cad,
		buyer_adj_amount * NVL (c4.CONVERSION_RATE, 1) AS buyer_adj_amt_cad,
		supp_reimb_amount * NVL (c4.CONVERSION_RATE, 1) AS supp_reimb_amt_cad,
		tax_amount * NVL (c4.CONVERSION_RATE, 1) AS tax_amt_cad,
		NVL (c4.CONVERSION_RATE, 1) AS conversion_rate_cad,
		REG_HOURS_BUYER_ADJ_AMOUNT * NVL (c4.CONVERSION_RATE, 1)        AS REG_HOURS_BUYER_ADJ_AMT_CAD,
		OT_HOURS_BUYER_ADJ_AMOUNT * NVL (c4.CONVERSION_RATE, 1)         AS OT_HOURS_BUYER_ADJ_AMT_CAD,
		DT_HOURS_BUYER_ADJ_AMOUNT * NVL (c4.CONVERSION_RATE, 1)         AS DT_HOURS_BUYER_ADJ_AMT_CAD,
		CS_HOURS_BUYER_ADJ_AMOUNT * NVL (c4.CONVERSION_RATE, 1)         AS CS_HOURS_BUYER_ADJ_AMT_CAD,
		REG_HOURS_SUPP_REIMB_AMOUNT * NVL (c4.CONVERSION_RATE, 1)       AS REG_HOURS_SUPP_REIMB_AMT_CAD,
		OT_HOURS_SUPP_REIMB_AMOUNT * NVL (c4.CONVERSION_RATE, 1)        AS OT_HOURS_SUPP_REIMB_AMT_CAD,
		DT_HOURS_SUPP_REIMB_AMOUNT * NVL (c4.CONVERSION_RATE, 1)        AS DT_HOURS_SUPP_REIMB_AMT_CAD,
		CS_HOURS_SUPP_REIMB_AMOUNT * NVL (c4.CONVERSION_RATE, 1)        AS CS_HOURS_SUPP_REIMB_AMT_CAD,
		f.CURR_CONV_CAD_DIM_ID 								AS CURR_CONV_CAD_DIM_ID,
          CASE WHEN e.expenditure_category =   'Discount' THEN 
                    NVL(f.buyer_adj_amount,0)   * NVL (c4.CONVERSION_RATE, 1)
               ELSE 0
          END                                                      		AS DISCOUNT_AMT_CAD,
          CASE WHEN e.expenditure_category =   'Rebate' THEN 
                    NVL(f.buyer_adj_amount,0)   * NVL (c4.CONVERSION_RATE, 1)
               ELSE 0
          END                                                      		AS REBATE_AMT_CAD          
     FROM dm_invoice_fact f,
          dm_currency_conversion_rates c1,
          dm_currency_conversion_rates c2,
          dm_currency_conversion_rates c3,
          dm_currency_conversion_rates c4,
          dm_expenditure_dim e
    WHERE     f.CURR_CONV_USD_DIM_ID = c1.CURR_CONV_DIM_ID(+)
          AND f.CURR_CONV_EUR_DIM_ID = c2.CURR_CONV_DIM_ID(+)
          AND f.CURR_CONV_GBP_DIM_ID = c3.CURR_CONV_DIM_ID(+)
          AND f.expenditure_dim_id = e.expenditure_dim_id(+)
          AND f.CURR_CONV_CAD_DIM_ID = c4.CURR_CONV_DIM_ID(+)
/

DECLARE 
  lv_status VARCHAR2(30);
BEGIN
  SELECT status 
    INTO lv_status
    FROM user_objects 
   WHERE object_name = 'DM_INVOICE_FACT_V';
  
  IF lv_status = 'VALID' THEN
    EXECUTE IMMEDIATE 'GRANT SELECT ON DM_INVOICE_FACT_V TO PUBLIC';
  END IF;
END;
/ 