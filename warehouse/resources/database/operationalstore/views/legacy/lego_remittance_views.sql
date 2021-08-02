CREATE OR REPLACE FORCE VIEW lego_remittance_vw 
AS
SELECT r.remittance_id,
       r.buyer_org_id,
       r.supplier_org_id,
       r.invoicing_buyer_org_id,
       r.invoice_id,
       r.invoice_header_id,
       r.custom_invoice_number,
       r.remit_payment_id,
       r.remit_allocation_id,
       r.expenditure_number,
       r.payment_number,
       r.payment_type,
       r.payment_date,
       r.payment_amount,
       ROUND(r.payment_amount * NVL(cc.conversion_rate, 1), 2) AS payment_amount_cc,
       r.posting_date,
       r.payment_term_days,
       r.comments,
       r.payment_account_name,
       r.buyer_pymt_receipt_date,
       r.payment_currency_id,
       r.payment_currency,
       NVL(cc.converted_currency_id, r.payment_currency_id) AS to_payment_currency_id,
       NVL(cc.converted_currency_code, r.payment_currency)  AS to_payment_currency,
       ROUND(NVL(cc.conversion_rate, 1), 6)                 AS conversion_rate
  FROM lego_remittance r,
       lego_currency_conv_rates_vw cc
 WHERE r.payment_currency_id = cc.original_currency_id(+)
/
 
COMMENT ON COLUMN lego_remittance_vw.buyer_org_id                  IS 'Buyer Business Organization ID FK to LEGO_BUYER_ORG_VW'
/
COMMENT ON COLUMN lego_remittance_vw.supplier_org_id               IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'
/
COMMENT ON COLUMN lego_remittance_vw.invoicing_buyer_org_id        IS 'Invoiceing Buyer Org ID FK to LEGO_BUYER_ORG_VW' 
/
COMMENT ON COLUMN lego_remittance_vw.invoice_id                    IS 'Invoice ID FK to LEGO_INVOICE_VW' 
/
COMMENT ON COLUMN lego_remittance_vw.invoice_header_id             IS 'Invoice Header ID FK to LEGO_INVOICE_DETAIL_VW' 
/
COMMENT ON COLUMN lego_remittance_vw.custom_invoice_number         IS 'Expenditure Number concatenated with Invoice ID' 
/
COMMENT ON COLUMN lego_remittance_vw.remit_payment_id              IS 'PK on remittance_payment FO table' 
/
COMMENT ON COLUMN lego_remittance_vw.remittance_id                 IS 'PK on remittance FO table' 
/
COMMENT ON COLUMN lego_remittance_vw.remit_allocation_id           IS 'PK on remittance_allocation FO table' 
/
COMMENT ON COLUMN lego_remittance_vw.expenditure_number            IS 'IQN supplier expenditure number.  Same as that on LEGO_INVOICE_DETAIL_VW' 
/
COMMENT ON COLUMN lego_remittance_vw.payment_number                IS 'Payment Number for the remittance_payment' 
/
COMMENT ON COLUMN lego_remittance_vw.payment_currency              IS 'Payment Currency for the remittance_payment' 
/
COMMENT ON COLUMN lego_remittance_vw.payment_currency_id           IS 'Payment Currency ID for the remittance_payment' 
/
COMMENT ON COLUMN lego_remittance_vw.payment_date                  IS 'Payment Date for the remittance_payment'   
/
COMMENT ON COLUMN lego_remittance_vw.payment_term_days             IS 'Payment Terms in Days for the remittance_allocation' 
/
COMMENT ON COLUMN lego_remittance_vw.comments                      IS 'Comments for the remittance_allocation' 
/
COMMENT ON COLUMN lego_remittance_vw.payment_type                  IS 'Payment Type for the remittance_payment' 
/
COMMENT ON COLUMN lego_remittance_vw.payment_account_name          IS 'Payment Account Name for the remittance_payment' 
/
COMMENT ON COLUMN lego_remittance_vw.buyer_pymt_receipt_date       IS 'Date payment was received for remittance_allocation' 
/

 
