CREATE TABLE DM_STD_OCCUPATION 
 (	STD_OCCUPATION_ID NUMBER NOT NULL, 
	STD_OCCUPATION_DESC VARCHAR2(255 BYTE)
 ) 
/
ALTER TABLE DM_STD_OCCUPATION ADD CONSTRAINT DM_STD_OCCUPATION_PK PRIMARY KEY (STD_OCCUPATION_ID)
/