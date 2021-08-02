/* Joe Pullifrone 
   04/28/2017
   IQN-37523

*/

BEGIN

  EXECUTE IMMEDIATE 'DROP TABLE finance_revenue_stage PURGE';
     
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE GLOBAL TEMPORARY TABLE finance_revenue_stage (
    invoiceable_expenditure_txn_id NUMBER(38),
	trans_create_date              DATE, 
	trans_last_update_date         DATE, 
	buyer_org_id                   NUMBER(38), 
	supplier_org_id                NUMBER(38), 
	assignment_continuity_id       NUMBER(38), 
	expenditure_date               DATE, 
	week_ending_date               DATE,
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
	cac1_id                        NUMBER(38)
   ) ON COMMIT PRESERVE ROWS
/

ALTER TABLE finance_revenue_stage 
ADD CONSTRAINT finance_revenue_stage_pk PRIMARY KEY (invoiceable_expenditure_txn_id)
/
