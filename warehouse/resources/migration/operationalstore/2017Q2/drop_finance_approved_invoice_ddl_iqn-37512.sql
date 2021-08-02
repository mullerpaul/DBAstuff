/* Joe Pullifrone 
   04/27/2017
   IQN-37512

*/

BEGIN

  EXECUTE IMMEDIATE 'DROP TABLE finance_approved_invoice PURGE';
     
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/
