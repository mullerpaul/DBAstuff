/* Joe Pullifrone 
   04/21/2017
   IQN-37472

*/

BEGIN

  EXECUTE IMMEDIATE 'DROP TABLE finance_org_currency PURGE';
     
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE finance_org_currency (
buyer_org_id                   NUMBER(38),
from_currency                  VARCHAR2(5),
to_currency                    VARCHAR2(5),
CONSTRAINT finance_org_currency_pk PRIMARY KEY (buyer_org_id, from_currency, to_currency)
) ORGANIZATION INDEX  
/


