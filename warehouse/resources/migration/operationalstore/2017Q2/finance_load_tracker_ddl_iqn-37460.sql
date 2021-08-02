/* Joe Pullifrone 
   04/20/2017
   IQN-37460

*/

BEGIN

  EXECUTE IMMEDIATE 'DROP TABLE finance_load_tracker PURGE';
     
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE finance_load_tracker (
start_date                     DATE,
end_date                       DATE,
run_flag                       CHAR(1) DEFAULT 'N'
)     
/

ALTER TABLE finance_load_tracker 
ADD CONSTRAINT finance_load_tracker_pk PRIMARY KEY (start_date,end_date)
/
