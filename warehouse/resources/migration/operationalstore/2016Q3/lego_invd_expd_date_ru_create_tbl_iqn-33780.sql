/* Joe Pullifrone 
   08/01/2016
   IQN-33780

This table represents the rollup that is used for Data Mart
Spend in Custom Reporting.  
   
All Custom Report queries use buyer_org_id and invoce_date
as filters. Partitioning in this way should improve partitioning
pruning significantly.

note: 5/2008 is the earliest month/year that has invoices in INVOICE table.

*/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE lego_invd_expd_date_ru PURGE';
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE lego_invd_expd_date_ru (
buyer_org_id                   NUMBER(38) NOT NULL,
buyer_name                     VARCHAR2(400) NOT NULL,
supplier_org_id                NUMBER(38) NOT NULL,
supplier_name                  VARCHAR2(400) NOT NULL,
invoice_id                     NUMBER(38) NOT NULL,
invoice_number_supplier        VARCHAR2(64),
invoice_date                   DATE NOT NULL,
expenditure_number             VARCHAR2(24) NOT NULL,
transaction_type               VARCHAR2(24),
expenditure_date               DATE NOT NULL,
week_ending_date               DATE NOT NULL,
work_order_id                  NUMBER(38),
work_order_type                VARCHAR2(5),
customer_supplier_internal_id  VARCHAR2(128),
accounting_code                VARCHAR2(500),
buyer_resource_id              VARCHAR2(64),
buyer_fee                      NUMBER(38,2), 
supplier_fee                   NUMBER(38,2),    
total_fee                      NUMBER(38,2),                 
cac1_segment1_value            VARCHAR2(254),
cac1_segment2_value            VARCHAR2(254),
cac1_segment3_value            VARCHAR2(254),
cac1_segment4_value            VARCHAR2(254),
cac1_segment5_value            VARCHAR2(254),
cac2_segment1_value            VARCHAR2(254),
cac2_segment2_value            VARCHAR2(254),
cac2_segment3_value            VARCHAR2(254),
cac2_segment4_value            VARCHAR2(254),
cac2_segment5_value            VARCHAR2(254),            
contractor_person_name         VARCHAR2(254),
contractor_person_id           NUMBER(38),
currency                       VARCHAR2(64),
hiring_mgr_name                VARCHAR2(254),
hiring_mgr_person_id           NUMBER(38),
spend_category                 VARCHAR2(24),
spend_type                     VARCHAR2(254),
buyer_adjusted_amount          NUMBER(38,2),
supplier_reimbursement_amount  NUMBER(38,2),
quantity                       NUMBER(38,2),
base_bill_rate                 NUMBER(38,2),
buyer_adjusted_bill_rate       NUMBER(38,2),
base_pay_rate                  NUMBER(38,2),
supplier_reimbursement_rate    NUMBER(38,2),
markup_pct                     NUMBER(38,2),
supplier_reference_num         VARCHAR2(254),
project_agreement_id           NUMBER(38),
project_agreement_name         VARCHAR2(512),
tax_type                       VARCHAR2(254),
invoice_creation_date          DATE,
assignment_start_date          DATE,
assignment_end_date            DATE,
job_id                         NUMBER(38),
job_title                      VARCHAR2(555),
job_category                   VARCHAR2(255),
job_level                      VARCHAR2(255),
sow_spend_category             VARCHAR2(64),
sow_spend_type                 VARCHAR2(64),
owning_buyer_org_id            NUMBER(38),
buyer_enterprise_bus_org_id    NUMBER(38),
source_name                    VARCHAR2(24),
load_date                      DATE
)         
  PARTITION BY LIST (buyer_org_id)    
  SUBPARTITION BY RANGE (invoice_date)
  SUBPARTITION TEMPLATE(
    SUBPARTITION P_LT_Q2_2008 VALUES LESS THAN (TO_DATE('04/01/2008','MM/DD/YYYY')),             
    SUBPARTITION P_Q2_2008 VALUES LESS THAN (TO_DATE('07/01/2008','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2008 VALUES LESS THAN (TO_DATE('10/01/2008','MM/DD/YYYY')),        
    SUBPARTITION P_Q4_2008 VALUES LESS THAN (TO_DATE('01/01/2009','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2009 VALUES LESS THAN (TO_DATE('04/01/2009','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2009 VALUES LESS THAN (TO_DATE('07/01/2009','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2009 VALUES LESS THAN (TO_DATE('10/01/2009','MM/DD/YYYY')),         
    SUBPARTITION P_Q4_2009 VALUES LESS THAN (TO_DATE('01/01/2010','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2010 VALUES LESS THAN (TO_DATE('04/01/2010','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2010 VALUES LESS THAN (TO_DATE('07/01/2010','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2010 VALUES LESS THAN (TO_DATE('10/01/2010','MM/DD/YYYY')),        
    SUBPARTITION P_Q4_2010 VALUES LESS THAN (TO_DATE('01/01/2011','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2011 VALUES LESS THAN (TO_DATE('04/01/2011','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2011 VALUES LESS THAN (TO_DATE('07/01/2011','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2011 VALUES LESS THAN (TO_DATE('10/01/2011','MM/DD/YYYY')),       
    SUBPARTITION P_Q4_2011 VALUES LESS THAN (TO_DATE('01/01/2012','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2012 VALUES LESS THAN (TO_DATE('04/01/2012','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2012 VALUES LESS THAN (TO_DATE('07/01/2012','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2012 VALUES LESS THAN (TO_DATE('10/01/2012','MM/DD/YYYY')),    
    SUBPARTITION P_Q4_2012 VALUES LESS THAN (TO_DATE('01/01/2013','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2013 VALUES LESS THAN (TO_DATE('04/01/2013','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2013 VALUES LESS THAN (TO_DATE('07/01/2013','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2013 VALUES LESS THAN (TO_DATE('10/01/2013','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2013 VALUES LESS THAN (TO_DATE('01/01/2014','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2014 VALUES LESS THAN (TO_DATE('04/01/2014','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2014 VALUES LESS THAN (TO_DATE('07/01/2014','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2014 VALUES LESS THAN (TO_DATE('10/01/2014','MM/DD/YYYY')),      
    SUBPARTITION P_Q4_2014 VALUES LESS THAN (TO_DATE('01/01/2015','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2015 VALUES LESS THAN (TO_DATE('04/01/2015','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2015 VALUES LESS THAN (TO_DATE('07/01/2015','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2015 VALUES LESS THAN (TO_DATE('10/01/2015','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2015 VALUES LESS THAN (TO_DATE('01/01/2016','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2016 VALUES LESS THAN (TO_DATE('04/01/2016','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2016 VALUES LESS THAN (TO_DATE('07/01/2016','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2016 VALUES LESS THAN (TO_DATE('10/01/2016','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2016 VALUES LESS THAN (TO_DATE('01/01/2017','MM/DD/YYYY')),    
    SUBPARTITION P_Q1_2017 VALUES LESS THAN (TO_DATE('04/01/2017','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2017 VALUES LESS THAN (TO_DATE('07/01/2017','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2017 VALUES LESS THAN (TO_DATE('10/01/2017','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2017 VALUES LESS THAN (TO_DATE('01/01/2018','MM/DD/YYYY')),   
    SUBPARTITION P_Q1_2018 VALUES LESS THAN (TO_DATE('04/01/2018','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2018 VALUES LESS THAN (TO_DATE('07/01/2018','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2018 VALUES LESS THAN (TO_DATE('10/01/2018','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2018 VALUES LESS THAN (TO_DATE('01/01/2019','MM/DD/YYYY')), 
    SUBPARTITION P_Q1_2019 VALUES LESS THAN (TO_DATE('04/01/2019','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2019 VALUES LESS THAN (TO_DATE('07/01/2019','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2019 VALUES LESS THAN (TO_DATE('10/01/2019','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2019 VALUES LESS THAN (TO_DATE('01/01/2020','MM/DD/YYYY')),    
    SUBPARTITION P_Q1_2020 VALUES LESS THAN (TO_DATE('04/01/2020','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2020 VALUES LESS THAN (TO_DATE('07/01/2020','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2020 VALUES LESS THAN (TO_DATE('10/01/2020','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2020 VALUES LESS THAN (TO_DATE('01/01/2021','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2021 VALUES LESS THAN (TO_DATE('04/01/2021','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2021 VALUES LESS THAN (TO_DATE('07/01/2021','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2021 VALUES LESS THAN (TO_DATE('10/01/2021','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2021 VALUES LESS THAN (TO_DATE('01/01/2022','MM/DD/YYYY')),    
    SUBPARTITION P_Q1_2022 VALUES LESS THAN (TO_DATE('04/01/2022','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2022 VALUES LESS THAN (TO_DATE('07/01/2022','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2022 VALUES LESS THAN (TO_DATE('10/01/2022','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2022 VALUES LESS THAN (TO_DATE('01/01/2023','MM/DD/YYYY')), 
    SUBPARTITION P_Q1_2023 VALUES LESS THAN (TO_DATE('04/01/2023','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2023 VALUES LESS THAN (TO_DATE('07/01/2023','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2023 VALUES LESS THAN (TO_DATE('10/01/2023','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2023 VALUES LESS THAN (TO_DATE('01/01/2024','MM/DD/YYYY')),       
    SUBPARTITION P_Q1_2024 VALUES LESS THAN (TO_DATE('04/01/2024','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2024 VALUES LESS THAN (TO_DATE('07/01/2024','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2024 VALUES LESS THAN (TO_DATE('10/01/2024','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2024 VALUES LESS THAN (TO_DATE('01/01/2025','MM/DD/YYYY')), 
    SUBPARTITION P_Q1_2025 VALUES LESS THAN (TO_DATE('04/01/2025','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2025 VALUES LESS THAN (TO_DATE('07/01/2025','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2025 VALUES LESS THAN (TO_DATE('10/01/2025','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2025 VALUES LESS THAN (TO_DATE('01/01/2026','MM/DD/YYYY')),         
    SUBPARTITION P_Q1_2026 VALUES LESS THAN (TO_DATE('04/01/2026','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2026 VALUES LESS THAN (TO_DATE('07/01/2026','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2026 VALUES LESS THAN (TO_DATE('10/01/2026','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2026 VALUES LESS THAN (TO_DATE('01/01/2027','MM/DD/YYYY'))           
    )
 (PARTITION P_NULL VALUES (NULL))
/
