DELETE FROM operationalstore.lego_invoiced_expd_detail
WHERE (buyer_org_id, invoice_id) IN
(SELECT ied.buyer_org_id, lia.invoice_id
   FROM operationalstore.lego_invoice_approved lia,
        operationalstore.lego_invoiced_expd_detail ied
  WHERE lia.invoice_id = ied.invoice_id
    AND lia.invoice_date  = ied.invoice_date
    AND lia.source_name  = ied.source_name
    AND lia.owning_buyer_org_id = ied.owning_buyer_org_id
    AND lia.buyer_enterprise_bus_org_id = ied.buyer_enterprise_bus_org_id
    AND TRUNC(lia.load_date) = TO_DATE('10/06/2016','mm/dd/yyyy')
    AND lia.source_name = 'USPROD')
/    
    
DELETE FROM operationalstore.lego_invoice_approved
WHERE TRUNC(load_date) = TO_DATE('10/06/2016','mm/dd/yyyy')
  AND source_name = 'USPROD'
  AND object_name = 'LEGO_INVOICED_EXPD_DETAIL'
/  
  
COMMIT
/
    
DELETE FROM operationalstore.lego_invd_expd_date_ru
WHERE (buyer_org_id, invoice_id) IN
(SELECT ied.buyer_org_id, lia.invoice_id
   FROM operationalstore.lego_invoice_approved lia,
        operationalstore.lego_invd_expd_date_ru ied
  WHERE lia.invoice_id = ied.invoice_id
    AND lia.invoice_date  = ied.invoice_date
    AND lia.source_name  = ied.source_name
    AND lia.owning_buyer_org_id = ied.owning_buyer_org_id
    AND lia.buyer_enterprise_bus_org_id = ied.buyer_enterprise_bus_org_id
    AND TRUNC(lia.load_date) = TO_DATE('10/06/2016','mm/dd/yyyy')
    AND lia.source_name = 'USPROD')
/    

DELETE FROM operationalstore.lego_invoice_approved
WHERE TRUNC(load_date) = TO_DATE('10/06/2016','mm/dd/yyyy')
  AND source_name = 'USPROD'
  AND object_name = 'LEGO_INVD_EXPD_DATE_RU'
/  

COMMIT
/ 
