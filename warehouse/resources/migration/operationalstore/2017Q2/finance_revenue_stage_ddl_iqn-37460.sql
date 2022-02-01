/* Joe Pullifrone 
   04/20/2017
   IQN-37460

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
	buyer_enterprise_bus_org_id    NUMBER(38), 
	buyer_enterprise_name          VARCHAR2(100), 
	buyer_org_id                   NUMBER(38), 
	buyer_name                     VARCHAR2(100), 
	supplier_org_id                NUMBER(38), 
	supplier_name                  VARCHAR2(100), 
	assignment_continuity_id       NUMBER(38), 
	expenditure_date               DATE, 
	week_ending_date               DATE, 
	invoice_date                   DATE, 
	invoice_create_date            DATE, 
	invoice_appr_date              DATE, 
	invoice_number                 NUMBER(38), 
	spend                          NUMBER(38,2), 
	currency                       VARCHAR2(6), 
	expenditure_type               VARCHAR2(100), 
	iqn_management_fee             NUMBER(38,2), 
	expenditure_approval_date      DATE, 
	reg_bill_rate                  NUMBER(38,2), 
	reg_reimbursement_rate         NUMBER(38,2), 
	accounting_code                VARCHAR2(50), 
	project_agreement_id           NUMBER(38), 
	classification                 VARCHAR2(200), 
	conversion_rate                NUMBER(38,4), 
	exch_spend                     NUMBER(38,2), 
	exch_iqn_management_fee        NUMBER(38,2), 
	gl_period                      VARCHAR2(25)	
   ) ON COMMIT PRESERVE ROWS
/

ALTER TABLE finance_revenue_stage 
ADD CONSTRAINT finance_revenue_stage_pk PRIMARY KEY (invoiceable_expenditure_txn_id)
/