/* Joe Pullifrone 
   04/20/2017
   IQN-37460

*/

BEGIN

  EXECUTE IMMEDIATE 'DROP TABLE finance_approved_invoice PURGE';
     
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE GLOBAL TEMPORARY TABLE finance_approved_invoice (
invoice_id                     NUMBER(38),
approved_date                  DATE
) ON COMMIT PRESERVE ROWS   
/

ALTER TABLE finance_approved_invoice 
ADD CONSTRAINT finance_approved_invoice_pk PRIMARY KEY (invoice_id)
/
