/* Joe Pullifrone 
   04/25/2017
   IQN-37495

*/

BEGIN

  EXECUTE IMMEDIATE 'DROP TABLE finance_revenue PURGE';
     
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE finance_revenue (
    invoiceable_expenditure_txn_id NUMBER(38),
	trans_create_date              DATE, 
	trans_last_update_date         DATE, 
	buyer_org_id                   NUMBER(38), 
	supplier_org_id                NUMBER(38), 
	assignment_continuity_id       NUMBER(38), 
	expenditure_date               DATE, 
	week_ending_date               DATE, 
	invoice_date                   DATE, 
	invoice_create_date            DATE, 
	invoice_appr_date              DATE, 
	invoice_number                 NUMBER(38), 
	spend                          NUMBER(38,2), 
	currency                       VARCHAR2(6), 
	rate_identifier_id             NUMBER(38), 
	timecard_id                    NUMBER(38), 
	payment_request_id             NUMBER(38), 
	assignment_bonus_id            NUMBER(38), 
	milestone_invoice_id           NUMBER(38), 
	iqn_management_fee             NUMBER(38,2), 
	expenditure_approval_date      DATE, 
	buyer_adjusted_bill_rate       NUMBER(38,2), 
	supplier_reimbursement_rate    NUMBER(38,2), 
	accounting_code                VARCHAR2(50), 
	project_agreement_id           NUMBER(38), 
	cac1_id                        NUMBER(38), 
	conversion_rate                NUMBER(38,4), 
	exch_spend                     NUMBER(38,2), 
	exch_iqn_management_fee        NUMBER(38,2), 
	gl_period                      VARCHAR2(25),
    etl_load_date                  DATE,
    etl_update_date                DATE	
   )  
   PARTITION BY RANGE (trans_create_date)                
     INTERVAL (NUMTOYMINTERVAL(1,'MONTH'))                
       (                
        PARTITION VALUES LESS THAN (TO_DATE('01-JAN-2003','DD-MON-YYYY'))                
       )
/

ALTER TABLE finance_revenue 
ADD CONSTRAINT finance_revenue_pk PRIMARY KEY (invoiceable_expenditure_txn_id)
/
