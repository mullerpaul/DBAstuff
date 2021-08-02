--J.Pullifrone
--IQN-7781
--Rel 11.4

CREATE OR REPLACE FORCE VIEW lego_inv_supplier_subset_vw 
AS
  SELECT supplier_org_id,
         invoice_id,
         invoice_detail_id,
         supplier_invoice_number,
         supplier_invoice_date
    FROM lego_inv_supplier_subset
/

COMMENT ON COLUMN lego_inv_supplier_subset_vw.supplier_org_id             IS 'Supplier Business Organization ID FK to LEGO_SUPPLIER_ORG_VW'
/
COMMENT ON COLUMN lego_inv_supplier_subset_vw.invoice_id                  IS 'Invoice ID FK to LEGO_INVOICE_DETAIL_VW'
/
COMMENT ON COLUMN lego_inv_supplier_subset_vw.invoice_detail_id           IS 'Invoice Detail ID FK to LEGO_INVOICE_DETAIL_VW'
/
COMMENT ON COLUMN lego_inv_supplier_subset_vw.supplier_invoice_number     IS 'Supplier-provided Invoice Number'
/    
COMMENT ON COLUMN lego_inv_supplier_subset_vw.supplier_invoice_date       IS 'Supplier-provided Invoice Date'
/


 