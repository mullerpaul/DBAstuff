INSERT INTO lego_invoice_object 
   VALUES ('LEGO_INVOICED_EXPD_DETAIL','USPROD','Holds invoice detail data at the lowest level of granularity','Y',SYSDATE)
/
INSERT INTO lego_invoice_object 
   VALUES ('LEGO_INVOICED_EXPD_DETAIL','WFPROD','Holds invoice detail data at the lowest level of granularity','Y',SYSDATE)
/
INSERT INTO lego_invoice_object 
   VALUES ('LEGO_INVD_EXPD_DATE_RU','USPROD','Holds rolled-up invoice data at the expenditure, expenditure_date level.  Used by CR.','Y',SYSDATE)
/
INSERT INTO lego_invoice_object 
   VALUES ('LEGO_INVD_EXPD_DATE_RU','WFPROD','Holds rolled-up invoice data at the expenditure, expenditure_date level.  Used by CR.','Y',SYSDATE)
/
COMMIT
/