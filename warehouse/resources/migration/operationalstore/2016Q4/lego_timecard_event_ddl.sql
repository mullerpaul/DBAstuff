BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE lego_timecard_event PURGE';
EXCEPTION  
  WHEN OTHERS THEN 
    NULL;
END;
/

CREATE TABLE lego_timecard_event (
buyer_enterprise_bus_org_id NUMBER(38) NOT NULL,
buyer_org_id                NUMBER(38) NOT NULL,
timecard_id                 NUMBER(38) NOT NULL,
event_id                    NUMBER(38) NOT NULL,
event_name_id               NUMBER(38) NOT NULL,
event_name                  VARCHAR2(256) NOT NULL,  
before_state_id             NUMBER(38) NOT NULL,
after_state_id              NUMBER(38) NOT NULL,
week_ending_date            DATE NOT NULL,
event_date                  DATE NOT NULL,
source_name                 VARCHAR2(6),
load_date                   DATE)
  PARTITION BY LIST (buyer_org_id)    
  SUBPARTITION BY RANGE (week_ending_date)
  SUBPARTITION TEMPLATE(
    SUBPARTITION P_LT_Q4_2005 VALUES LESS THAN (TO_DATE('10/01/2005','MM/DD/YYYY')),     
    SUBPARTITION P_Q4_2005 VALUES LESS THAN (TO_DATE('01/01/2006','MM/DD/YYYY')),  
    SUBPARTITION P_Q1_2006 VALUES LESS THAN (TO_DATE('04/01/2006','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2006 VALUES LESS THAN (TO_DATE('07/01/2006','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2006 VALUES LESS THAN (TO_DATE('10/01/2006','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2006 VALUES LESS THAN (TO_DATE('01/01/2007','MM/DD/YYYY')),    
    SUBPARTITION P_Q1_2007 VALUES LESS THAN (TO_DATE('04/01/2007','MM/DD/YYYY')),
    SUBPARTITION P_Q2_2007 VALUES LESS THAN (TO_DATE('07/01/2007','MM/DD/YYYY')),
    SUBPARTITION P_Q3_2007 VALUES LESS THAN (TO_DATE('10/01/2007','MM/DD/YYYY')),
    SUBPARTITION P_Q4_2007 VALUES LESS THAN (TO_DATE('01/01/2008','MM/DD/YYYY')),
    SUBPARTITION P_Q1_2008 VALUES LESS THAN (TO_DATE('04/01/2008','MM/DD/YYYY')),  
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