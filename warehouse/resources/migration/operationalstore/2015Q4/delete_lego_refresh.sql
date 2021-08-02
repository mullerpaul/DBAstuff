-- no need for the security legos in the data mart. 
DELETE FROM lego_refresh 
 WHERE refresh_group = 2
/

-- no need for Currency conversion from more than one source - this data is global across sources. 
DELETE FROM lego_refresh 
 WHERE object_name = 'LEGO_CURRENCY_CONV_RATES'
   AND source_name <> 'USPROD'
/

-- no need for JCL from more than one source - this data is global across sources. 
-- Actually it sounds like we will still need all three.  Leave for now and confirm later.
--DELETE FROM lego_refresh 
-- WHERE object_name = 'LEGO_JAVA_CONSTANT_LOOKUP'
--   AND source_name <> 'USPROD'
--/

-- we are going to use existing datamart spend table instead of lego_invoice_detail.
DELETE FROM lego_refresh 
 WHERE object_name = 'LEGO_INVOICE_DETAIL'
/

-- we don't need the candidate search legos in the mart.  
-- That info is only used by FO app and these will stay local to FO.
DELETE FROM lego_refresh 
 WHERE object_name IN ('LEGO_CAND_SEARCH','LEGO_CAND_SEARCH_IDX')
/

-- commit the changes
COMMIT
/
   
   

   
 
  
